# Turn an ngspice ASCII raw file into the text NST reads.
# NST treats a file as ASCII when the first 19 bytes contain "ascii".
# Column 0 is the sweep (time, frequency, or a DC sweep). A voltage
# vector v(net) is stored as net, which is the name SUE probes. A
# current vector i(name) is stored as i(name without the closing
# parenthesis, which is the form spice_net returns. AC points keep
# the real part. The last plot in the file is the one that is written.
# Tcl 8.0.

proc ngspice_column_name {raw} {
  set name [string tolower $raw]
  if {[regexp {^v\((.*)\)$} $name -> inner]} {
    set name $inner
  } elseif {[regexp {^i\((.*)\)$} $name -> inner]} {
    set name "i($inner"
  }
  regsub -all "\[ \t\]+" $name _ name
  return $name
}

proc ngspice_take_real {token varName} {
  upvar 1 $varName out
  set token [string trim $token]
  set comma [string first , $token]
  if {$comma >= 0} {
    set token [string range $token 0 [expr {$comma - 1}]]
  }
  if {[scan $token "%f" out] != 1} {
    return 0
  }
  return 1
}

proc ngspice_finish_plot {names nums} {
  set n [llength $names]
  if {$n < 1} {
    return ""
  }
  set count [llength $nums]
  if {$count < $n} {
    return ""
  }
  set rows [expr {$count / $n}]
  set keep [expr {$rows * $n}]
  return [list $names [lrange $nums 0 [expr {$keep - 1}]] $rows]
}

proc ngspice_plot_text {plot} {
  set names [lindex $plot 0]
  set nums [lindex $plot 1]
  set rows [lindex $plot 2]
  set n [llength $names]
  set cols {}
  set i 0
  foreach raw $names {
    set col [ngspice_column_name $raw]
    if {$col == ""} {
      set col "n$i"
    }
    set base $col
    set k 2
    while {[info exists used($col)]} {
      set col "${base}_$k"
      incr k
    }
    set used($col) 1
    lappend cols $col
    incr i
  }

  # "ascii" must sit inside the first 19 bytes. NST decides the file
  # type from that prefix before it reads the rest of the title.
  set out "ascii ngspice\n"
  append out "[join $cols { }]\n"
  for {set r 0} {$r < $rows} {incr r} {
    set parts {}
    for {set c 0} {$c < $n} {incr c} {
      set v [lindex $nums [expr {$r * $n + $c}]]
      lappend parts [format %.8e $v]
    }
    append out "[join $parts { }]\n"
  }
  return $out
}

proc ngspice_header_line {trim} {
  if {[string match "Title:*" $trim]} { return 1 }
  if {[string match "Date:*" $trim]} { return 1 }
  if {[string match "Plotname:*" $trim]} { return 1 }
  if {[string match "Flags:*" $trim]} { return 1 }
  if {[string match "No.*" $trim]} { return 1 }
  if {[string match "Variables:*" $trim]} { return 1 }
  return 0
}

# Returns the NST text, or "" when the raw file has no complete plot.
proc ngspice_raw_to_nst {text} {
  set plots {}
  set names {}
  set nums {}
  set mode ""

  foreach line [split $text \n] {
    set trim [string trim $line]
    if {$trim == ""} {
      continue
    }

    if {[string match "Variables:*" $trim]} {
      set saved [ngspice_finish_plot $names $nums]
      if {$saved != ""} {
        lappend plots $saved
      }
      set names {}
      set nums {}
      set mode vars
      continue
    }

    if {$mode == "vars"} {
      if {[string match "Values:*" $trim]} {
        set mode values
        continue
      }
      if {[ngspice_header_line $trim]} {
        continue
      }
      set name [lindex $trim 1]
      if {$name == ""} {
        set name [lindex $trim 0]
      }
      lappend names $name
      continue
    }

    if {$mode == "values"} {
      if {[ngspice_header_line $trim]} {
        set saved [ngspice_finish_plot $names $nums]
        if {$saved != ""} {
          lappend plots $saved
        }
        set names {}
        set nums {}
        set mode ""
        if {[string match "Variables:*" $trim]} {
          set mode vars
        }
        continue
      }
      if {[regexp {^[0-9]+$} $trim]} {
        continue
      }
      if {[regexp {^[0-9]+[ \t]+(.*)$} $trim -> rest]} {
        set trim [string trim $rest]
      }
      foreach tok $trim {
        set val 0
        if {![ngspice_take_real $tok val]} {
          continue
        }
        lappend nums $val
      }
    }
  }

  set saved [ngspice_finish_plot $names $nums]
  if {$saved != ""} {
    lappend plots $saved
  }
  if {[llength $plots] < 1} {
    return ""
  }
  return [ngspice_plot_text [lindex $plots end]]
}
