# Resolve `sue -lib <name>` to a design-library directory.
# Sourced from the site .suerc, after the command line has filled LIB
# and before SUE consumes LIB. Tcl 8.0 safe.

if {![info exists SUE_LIB_NO_APPLY]} { set SUE_LIB_NO_APPLY 0 }

proc sue_lib_dirs {} {
  global env
  set out {}
  if {[info exists env(SUE_LIB_PATH)] && $env(SUE_LIB_PATH) != ""} {
    foreach d [split $env(SUE_LIB_PATH) :] {
      if {$d != ""} { lappend out $d }
    }
  }
  set root /mmi-pdks
  if {[info exists env(PDK_ROOT)] && $env(PDK_ROOT) != ""} {
    set root $env(PDK_ROOT)
  }
  lappend out [file join $root sue lib]
  if {[info exists env(HOME)] && $env(HOME) != ""} {
    lappend out [file join $env(HOME) mmi_private sue lib]
  }
  if {[info exists env(MMI_LOCAL)] && $env(MMI_LOCAL) != ""} {
    lappend out [file join $env(MMI_LOCAL) sue lib]
  }
  if {[info exists env(MMI_TOOLS)] && $env(MMI_TOOLS) != ""} {
    lappend out [file join $env(MMI_TOOLS) sue lib]
  }
  return $out
}

proc sue_lib_is_dir {token} {
  if {[string first / $token] >= 0} { return 1 }
  if {[file isdirectory $token]} { return 1 }
  return 0
}

proc sue_lib_find {name} {
  foreach base [sue_lib_dirs] {
    set d [file join $base $name]
    if {[file isdirectory $d] && [file readable [file join $d LIBRARY]]} {
      return $d
    }
  }
  return ""
}

proc sue_lib_known {} {
  set names {}
  foreach base [sue_lib_dirs] {
    foreach d [glob -nocomplain [file join $base *]] {
      if {[file readable [file join $d LIBRARY]]} {
        lappend names [file tail $d]
      }
    }
  }
  return $names
}

proc sue_lib_rewrite {varName} {
  upvar 1 $varName items
  if {![info exists items]} { return }
  set next {}
  foreach token $items {
    if {$token == ""} continue
    if {[sue_lib_is_dir $token]} {
      lappend next $token
      continue
    }
    set found [sue_lib_find $token]
    if {$found != ""} {
      puts "sue -lib $token -> $found"
      lappend next $found
    } else {
      puts "sue: design library '$token' is not installed."
      set known [sue_lib_known]
      if {$known != ""} {
        puts "sue: installed libraries: $known"
      }
      puts "sue: install one with:  ./run.sh importer"
    }
  }
  set items $next
}

proc sue_lib_apply {} {
  global LIB AUTOLIB env
  if {![info exists LIB]} { set LIB {} }
  if {![info exists AUTOLIB]} { set AUTOLIB {} }
  if {($LIB == "" || $LIB == 0) && [info exists env(SUE_DEFAULT_LIB)] && \
      $env(SUE_DEFAULT_LIB) != ""} {
    set LIB $env(SUE_DEFAULT_LIB)
  }
  sue_lib_rewrite LIB
  sue_lib_rewrite AUTOLIB
  foreach d $LIB {
    if {[lsearch -exact $AUTOLIB $d] < 0} {
      lappend AUTOLIB $d
    }
  }
}

if {!$SUE_LIB_NO_APPLY} {
  sue_lib_apply
}
