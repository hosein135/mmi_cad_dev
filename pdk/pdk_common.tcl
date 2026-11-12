# Shared PDK helpers for MAX add-ons (Magic import, image import).
# Tcl 8.0 safe. The download dialog lives in the importer application.
# Generator revision a usable .tech27 must carry (MMI_PDK_GEN).

set PDK_GEN_REQUIRED 7
set PDK_SOURCE_REV 5

proc pdk_source_rev {path} {
  if {![file readable $path]} { return 0 }
  if {[catch {set fh [open $path r]}]} { return 0 }
  set rev 0
  set n 0
  while {[gets $fh line] >= 0 && $n < 20} {
    incr n
    set toks {}
    foreach w [split [string trim $line] " \t"] {
      if {$w != ""} { lappend toks $w }
    }
    if {[lindex $toks 0] == "#" && [lindex $toks 1] == "source-rev"} {
      set rev [lindex $toks 2]
      break
    }
  }
  close $fh
  if {[catch {expr {int($rev)}} rev]} { return 0 }
  return $rev
}

proc pdk_sanitize {name} {
  regsub -all {[^A-Za-z0-9_]+} $name _ name
  regsub -all {_+} $name _ name
  set name [string trim $name _]
  if {$name == ""} { set name layer }
  if {[regexp {^[0-9]} $name]} { set name L$name }
  return $name
}

proc pdk_words {line} {
  set out {}
  foreach w [split $line " \t"] {
    if {$w != ""} { lappend out $w }
  }
  return $out
}

proc pdk_is_int {s} {
  if {$s == ""} { return 0 }
  set n [string length $s]
  for {set i 0} {$i < $n} {incr i} {
    if {[string first [string index $s $i] 0123456789] < 0} { return 0 }
  }
  return 1
}

proc pdk_prepend_tools_path {} {
  global env
  if {![info exists env(PATH)]} { set env(PATH) "" }
  if {[info exists env(MMI_TOOLS)] && $env(MMI_TOOLS) != ""} {
    set bin [file join $env(MMI_TOOLS) bin]
    if {$bin != "" && ![string match ${bin}:* $env(PATH)] && $env(PATH) != $bin} {
      set env(PATH) "${bin}:$env(PATH)"
    }
  }
}

proc pdk_which {names} {
  global env
  pdk_prepend_tools_path
  set path ""
  if {[info exists env(PATH)]} { set path $env(PATH) }
  foreach name $names {
    if {[file executable $name]} { return $name }
    foreach dir [split $path :] {
      if {$dir == ""} continue
      set cand [file join $dir $name]
      if {[file executable $cand]} { return $cand }
    }
  }
  return ""
}

proc pdk_sh_quote {s} {
  regsub -all {'} $s {'\''} s
  return "'$s'"
}

proc pdk_max_tech_dirs {tech} {
  global env
  set home /mmi-home
  if {[info exists env(HOME)] && $env(HOME) != ""} { set home $env(HOME) }
  set local [file join $home cad mmi_local]
  if {[info exists env(MMI_LOCAL)] && $env(MMI_LOCAL) != ""} {
    set local $env(MMI_LOCAL)
  }
  return [list \
      [file join $home mmi_private max tech $tech] \
      [file join $local max tech $tech] \
      [file join [pdk_root] max tech $tech]]
}

proc pdk_tech27_ok {f} {
  if {$f == "" || ![file readable $f]} { return 0 }
  if {[catch {set sz [file size $f]}] || $sz < 200} { return 0 }
  if {[catch {set fh [open $f r]}]} { return 0 }
  set has_drc 0
  set has_cifstyle_in_drc 0
  set in_drc 0
  set bad 0
  # Token checks, not regexp: MAX's Tcl 8.0 has no \S and treats the tab in
  # [ \t] as a literal "t".
  while {[gets $fh line] >= 0} {
    set toks [pdk_words $line]
    set kw [lindex $toks 0]
    # Older generator wrote invalid "labels *" (MAX needs "labels space").
    if {$kw == "labels" && [lindex $toks 1] == "*"} {
      set bad 1
      break
    }
    # "expr - + 0" accepted "-" as a dimension - MAX rejects it.
    if {($kw == "width" || $kw == "cifwidth") && [lindex $toks 2] == "-"} {
      set bad 1
      break
    }
    if {($kw == "spacing" || $kw == "cifspacing") && [lindex $toks 3] == "-"} {
      set bad 1
      break
    }
    # Wildcard datatypes smear sky130 layers sharing one GDS number.
    if {$kw == "calma" && [llength $toks] == 4 && [lindex $toks 3] == "*"} {
      set bad 1
      break
    }
    set t [string trim $line]
    if {$t == "drc"} {
      set in_drc 1
      set has_drc 1
      continue
    }
    if {$in_drc && $t == "end"} {
      set in_drc 0
      continue
    }
    if {$kw == "cifstyle"} {
      if {$in_drc} {
        set has_cifstyle_in_drc 1
      } else {
        # Top-level cifstyle (not inside drc) breaks the tech parser.
        set bad 1
        break
      }
    }
  }
  close $fh
  if {$bad} { return 0 }
  if {!$has_drc} { return 0 }
  if {!$has_cifstyle_in_drc} { return 0 }
  # Companion files MAX requires after tech27 loads
  set dir [file dirname $f]
  set tech [file rootname [file tail $f]]
  if {![file readable [file join $dir ${tech}.palette]]} { return 0 }
  if {![file readable [file join $dir ${tech}.tcl]]} { return 0 }
  # Broken: set DRC_DATA(...) a b  (missing braces → multi-word value)
  if {[catch {set tfh [open [file join $dir ${tech}.tcl] r]}]} { return 0 }
  set tcl_bad 0
  set gen 0
  while {[gets $tfh tline] >= 0} {
    if {[regexp {^set DRC_DATA\([^)]+\) (.*)$} $tline -> val]} {
      # Braced lists have llength 1; unbraced "poly diff" has llength 2.
      if {[catch {llength $val} n] || $n > 1} {
        set tcl_bad 1
        break
      }
    }
    set toks [pdk_words $tline]
    if {[lindex $toks 0] == "set" && [lindex $toks 1] == "MMI_PDK_GEN"} {
      set gen [lindex $toks 2]
      if {![pdk_is_int $gen]} { set gen 0 }
    }
  }
  close $tfh
  if {$tcl_bad} { return 0 }
  # Older generator output (wildcard datatypes, untyped diffusion): re-convert.
  global PDK_GEN_REQUIRED
  if {$gen < $PDK_GEN_REQUIRED} { return 0 }
  return 1
}

proc pdk_find_tech27 {tech} {
  foreach dir [pdk_max_tech_dirs $tech] {
    set f [file join $dir ${tech}.tech27]
    if {[pdk_tech27_ok $f]} { return $f }
  }
  return ""
}

proc pdk_find_tech27_any {tech} {
  foreach dir [pdk_max_tech_dirs $tech] {
    set f [file join $dir ${tech}.tech27]
    if {[file readable $f] && [file size $f] > 0} { return $f }
  }
  return ""
}

proc pdk_compile_script {} {
  global env
  set cands {}
  lappend cands /mmi-pdk-live/compile_tech.sh
  if {[info exists env(MMI_LOCAL)] && $env(MMI_LOCAL) != ""} {
    lappend cands [file join $env(MMI_LOCAL) max pdk compile_tech.sh]
  }
  if {[info exists env(MMI_PDK_DIR)] && $env(MMI_PDK_DIR) != ""} {
    lappend cands [file join $env(MMI_PDK_DIR) compile_tech.sh]
  }
  lappend cands /mmi-bundle/compile_tech.sh
  foreach f $cands {
    if {[file readable $f]} { return $f }
  }
  return ""
}

proc pdk_import_selection_get {offset maxBytes} {
  global _PDK_IMPORT_CLIP
  if {![info exists _PDK_IMPORT_CLIP]} { return "" }
  set end [expr {$offset + $maxBytes - 1}]
  return [string range $_PDK_IMPORT_CLIP $offset $end]
}

proc pdk_import_copy_text {msg} {
  global _PDK_IMPORT_CLIP
  set _PDK_IMPORT_CLIP $msg
  catch {clipboard clear}
  if {[catch {clipboard append -- $msg}]} {
    catch {clipboard append $msg}
  }
  # Also PRIMARY so middle-click paste works in terminals.
  catch {
    selection own .
    selection handle . pdk_import_selection_get
  }
}

proc pdk_root {} {
  global env
  if {[info exists env(PDK_ROOT)] && $env(PDK_ROOT) != ""} {
    return $env(PDK_ROOT)
  }
  return /mmi-pdks
}

proc pdk_tree_ready {dir} {
  if {$dir == "" || ![file isdirectory $dir]} { return 0 }
  set mag [file join $dir libs.tech magic]
  if {![file isdirectory $mag]} { return 0 }
  set rcs [glob -nocomplain [file join $mag *.magicrc]]
  if {![llength $rcs]} { return 0 }
  set ref [file join $dir libs.ref]
  if {![file isdirectory $ref]} { return 0 }
  set kids [glob -nocomplain [file join $ref *]]
  if {![llength $kids]} { return 0 }
  return 1
}

