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

# Tell MAX which schematic netlist to turn into a layout. Written before
# Max Cross Probe Init starts MAX. MAX reads this file from its own startup.
proc _mmi_note_autolayout {} {
  global cur_s env SUFFIX
  if {![info exists cur_s] || $cur_s == ""} { return }
  upvar #0 SUE_$cur_s data
  if {![info exists data(dir)]} { return }
  set dir [string trimright $data(dir) /]
  set suf .sim
  if {[info exists SUFFIX(sim)] && $SUFFIX(sim) != ""} {
    set suf $SUFFIX(sim)
  }
  set home /mmi-home
  if {[info exists env(HOME)] && $env(HOME) != ""} {
    set home $env(HOME)
  }
  if {[catch {
    set fh [open [file join $home .mmi-autolayout] w]
    puts $fh $dir/$cur_s$suf
    puts $fh $dir
    puts $fh $cur_s
    close $fh
  } err]} {
    puts "sue: could not record layout request: $err"
  }
}

proc _mmi_autoload_cross_probe {} {
  global auto_index _mmi_cross_probe_autoload
  if {[info exists auto_index(max_cross_probe_init)]} {
    unset auto_index(max_cross_probe_init)
  }
  eval $_mmi_cross_probe_autoload
  if {[info commands max_cross_probe_init] == ""} { return }
  rename max_cross_probe_init _mmi_max_cross_probe_init_real
  proc max_cross_probe_init {args} {
    _mmi_note_autolayout
    eval _mmi_max_cross_probe_init_real $args
  }
}

proc _mmi_install_autolayout_hook {} {
  global auto_index _mmi_autolayout_hook_installed _mmi_autolayout_hook_tries
  global _mmi_cross_probe_autoload
  if {[info exists _mmi_autolayout_hook_installed]} { return }
  if {![info exists _mmi_autolayout_hook_tries]} {
    set _mmi_autolayout_hook_tries 0
  }
  incr _mmi_autolayout_hook_tries
  if {$_mmi_autolayout_hook_tries > 40} {
    puts "sue: layout hook was not installed"
    return
  }
  if {[info commands use_first] == ""} {
    after 500 _mmi_install_autolayout_hook
    return
  }
  if {[info commands _mmi_max_cross_probe_init_real] != ""} {
    set _mmi_autolayout_hook_installed 1
    return
  }
  if {[info commands max_cross_probe_init] != ""} {
    rename max_cross_probe_init _mmi_max_cross_probe_init_real
    proc max_cross_probe_init {args} {
      _mmi_note_autolayout
      eval _mmi_max_cross_probe_init_real $args
    }
    set _mmi_autolayout_hook_installed 1
    return
  }
  if {![info exists auto_index(max_cross_probe_init)]} {
    after 500 _mmi_install_autolayout_hook
    return
  }
  set _mmi_cross_probe_autoload $auto_index(max_cross_probe_init)
  set auto_index(max_cross_probe_init) _mmi_autoload_cross_probe
  set _mmi_autolayout_hook_installed 1
}

after 500 _mmi_install_autolayout_hook

# The MAX window SUE starts is an xterm titled "Max Terminal".
# Give it a readable bitmap font, a dark ground, and a usable size.
proc _mmi_style_max_terminal {} {
  global env
  set home /tmp
  if {[info exists env(HOME)] && $env(HOME) != ""} {
    set home $env(HOME)
  }
  set font "-misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1"
  set big "-misc-fixed-medium-r-normal--18-120-100-100-c-90-iso8859-1"
  if {![catch {exec xlsfonts -fn $big}]} {
    set font $big
  }
  set path [file join $home .mmi-xterm.res]
  if {[catch {set fh [open $path w]}]} { return }
  puts $fh "XTerm*font: $font"
  puts $fh "XTerm*boldFont: $font"
  puts $fh "XTerm*background: #1b1e24"
  puts $fh "XTerm*foreground: #e8eaed"
  puts $fh "XTerm*cursorColor: #8ab4f8"
  puts $fh "XTerm*scrollBar: true"
  puts $fh "XTerm*rightScrollBar: true"
  puts $fh "XTerm*saveLines: 2000"
  puts $fh "XTerm*VT100.geometry: 110x36"
  close $fh
  catch {exec xrdb -merge $path}
}
_mmi_style_max_terminal

proc _mmi_sue_lib_label {} {
  global LIB
  if {![info exists LIB] || $LIB == "" || $LIB == 0} { return "" }
  set names ""
  foreach d $LIB {
    set tail [file tail $d]
    if {$tail == ""} continue
    if {$names != ""} { append names "," }
    append names $tail
  }
  return $names
}

proc _mmi_wrap_sue_title {} {
  if {[info commands _mmi_display_title_real] != ""} { return }
  if {[info commands display_title] == ""} {
    after 500 _mmi_wrap_sue_title
    return
  }
  rename display_title _mmi_display_title_real
  proc display_title {args} {
    eval _mmi_display_title_real $args
    set lib [_mmi_sue_lib_label]
    if {$lib == ""} { return }
    set w .
    if {[llength $args] > 0 && [lindex $args 0] != ""} {
      set w [lindex $args 0]
    }
    if {![winfo exists $w]} { return }
    set t [wm title $w]
    if {[string first " lib $lib" $t] >= 0} { return }
    set t "$t  lib $lib"
    wm title $w $t
    wm iconname $w $t
  }
  catch {display_title}
}
after 800 _mmi_wrap_sue_title
