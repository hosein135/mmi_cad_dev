#!/usr/bin/env tclsh
# Generate a SUE design library from an installed open_pdks tree.
#   gen_sue_lib.tcl PDK_DIR DEST_LIB_DIR LIB_NAME MAX_TECH [PDK_TAG]
# Tcl 8.5+. Not sourced by SUE or MAX.

set SUE_LIB_REV 1

if {[llength $argv] < 4} {
  puts stderr "usage: gen_sue_lib.tcl PDK_DIR DEST LIB_NAME MAX_TECH [PDK_TAG]"
  exit 2
}
set pdk [lindex $argv 0]
set dest [lindex $argv 1]
set libname [lindex $argv 2]
set maxtech [lindex $argv 3]
set pdktag [lindex $argv 4]

proc walk_syms {dir} {
  set out {}
  set stack [list $dir]
  while {[llength $stack]} {
    set d [lindex $stack 0]
    set stack [lrange $stack 1 end]
    foreach f [glob -nocomplain -directory $d *] {
      if {[file isdirectory $f]} {
        set base [string tolower [file tail $f]]
        if {$base == "tests" || $base == "mips_cpu" || \
            [string match *stdcell* $base] || \
            [string match *simulation* $base]} continue
        lappend stack $f
      } elseif {[string match *.sym $f]} {
        set low [string tolower $f]
        if {[string match */symbols/* $low] || \
            [string match *_pr/* $low] || \
            [string match */primitives/* $low]} {
          lappend out $f
        }
      }
    }
  }
  return $out
}

proc sym_kblock {text} {
  set lines [split $text \n]
  set n [llength $lines]
  for {set i 0} {$i < $n} {incr i} {
    if {![regexp {^K \{(.*)$} [lindex $lines $i] -> rest]} continue
    set acc {}
    if {$rest != "" && $rest != "\}"} { lappend acc $rest }
    incr i
    while {$i < $n} {
      set line [lindex $lines $i]
      if {$line == "\}"} break
      lappend acc $line
      incr i
    }
    return [join $acc \n]
  }
  return ""
}

proc sym_quoted {block key} {
  set id [string first "$key=\"" $block]
  if {$id < 0} { return "" }
  set i [expr {$id + [string length $key] + 2}]
  set n [string length $block]
  set out ""
  while {$i < $n} {
    set c [string index $block $i]
    if {$c == "\\"} {
      set c2 [string index $block [expr {$i + 1}]]
      set c3 [string index $block [expr {$i + 2}]]
      # xschem writes a quote inside a quoted value as two backslashes
      # and a quote. A single backslash still escapes the next character.
      if {$c2 == "\\" && $c3 == "\""} {
        append out "\""
        incr i 3
        continue
      }
      if {$c2 == "\\" || $c2 == "\""} {
        append out $c2
        incr i 2
        continue
      }
      incr i
      if {$i < $n} { append out $c2 }
      incr i
      continue
    }
    if {$c == "\""} break
    append out $c
    incr i
  }
  return $out
}

proc sym_token {text key} {
  set re "$key=(\[^\n\r \t\"\]+)"
  if {[regexp $re $text -> v]} { return $v }
  return ""
}

proc sym_template {block} {
  set tmpl [sym_quoted $block template]
  set map {}
  foreach line [split $tmpl \n] {
    set line [string trim $line]
    if {![regexp {^([A-Za-z0-9_]+)=(.*)$} $line -> k v]} continue
    set v [string trim $v]
    if {![regexp {^[A-Za-z0-9_.]+$} $v]} continue
    lappend map $k $v
  }
  return $map
}

proc sym_pins {text} {
  set pins {}
  foreach line [split $text \n] {
    if {![string match "B *" $line]} continue
    if {![regexp {name=([^ \}]+) dir=([^ \}]+)} $line -> name dir]} continue
    set name [string tolower $name]
    if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $name]} continue
    lappend pins [list $name $dir]
  }
  return $pins
}

proc sue_dir_of {dir} {
  switch -exact -- $dir {
    in - input { return input }
    out - output { return output }
    default { return inout }
  }
}

proc map_get {map key} {
  set i [lsearch -exact $map $key]
  if {$i < 0} { return "" }
  return [lindex $map [expr {$i + 1}]]
}

proc spice_add {namesVar token} {
  upvar $namesVar names
  set token [string tolower [string trim $token]]
  if {$token == ""} { return }
  lappend names $token
}

proc spice_stem {path} {
  set stem [file tail $path]
  regsub -all -nocase {\.(spice|lib|mod|inc)$} $stem "" stem
  regsub -nocase {\.(model|pm3)$} $stem "" stem
  regsub -nocase {__(ff|fs|sf|ss|tt|leak|mismatch|wafer|tt_leak).*$} $stem "" stem
  return [string tolower $stem]
}

proc spice_names {pdk} {
  set names {}
  set dirs {}
  set ng [file join $pdk libs.tech ngspice]
  if {[file isdirectory $ng]} { lappend dirs $ng }
  set ref [file join $pdk libs.ref]
  foreach d [glob -nocomplain -directory $ref *] {
    if {![file isdirectory $d]} continue
    set base [string tolower [file tail $d]]
    if {![string match *_pr $base] && ![string match *primitives* $base]} continue
    set spice [file join $d spice]
    if {[file isdirectory $spice]} { lappend dirs $spice }
  }
  set stack $dirs
  set seen 0
  while {[llength $stack] && $seen < 2500} {
    set d [lindex $stack 0]
    set stack [lrange $stack 1 end]
    foreach f [glob -nocomplain -directory $d *] {
      incr seen
      if {[file isdirectory $f]} {
        if {[llength $stack] < 80} { lappend stack $f }
        continue
      }
      set low [string tolower $f]
      if {![string match *.spice $low] && ![string match *.lib $low] && \
          ![string match *.mod $low]} continue
      spice_add names [spice_stem $f]
      if {[catch {set fh [open $f r]}]} continue
      if {[file size $f] > 2000000} {
        close $fh
        continue
      }
      while {[gets $fh line] >= 0} {
        if {[regexp -nocase {^\.(model|subckt)[ \t]+([^ \t(]+)} $line -> kind name]} {
          spice_add names $name
        }
      }
      close $fh
    }
  }
  return $names
}

proc spice_has {names model} {
  if {[llength $names] == 0} { return 1 }
  set want [string tolower $model]
  if {[lsearch -exact $names $want] >= 0} { return 1 }
  return 0
}

proc write_icon {path cell type pins model spice_model params prefix} {
  set fh [open $path w]
  puts $fh "# mmi-sue-lib generated"
  puts $fh "# SUE version MMI_SUE4.4"
  puts $fh ""
  set props [list {origin {0 0}} {orient R0} {name {}} {M {}}]
  foreach pair $params {
    lappend props [list [lindex $pair 0] [lindex $pair 1]]
  }
  puts $fh "proc ICON_$cell args \{"
  puts $fh "  icon_setup \$args \{$props\}"
  set y -40
  foreach pin $pins {
    set pname [lindex $pin 0]
    set pdir [sue_dir_of [lindex $pin 1]]
    if {$pname == "g" || $pname == "b"} {
      puts $fh "  icon_term -type $pdir -origin {-60 $y} -name $pname"
    } elseif {$pname == "d"} {
      puts $fh "  icon_term -type $pdir -origin {0 40} -name $pname"
    } elseif {$pname == "s"} {
      puts $fh "  icon_term -type $pdir -origin {0 -40} -name $pname"
    } else {
      puts $fh "  icon_term -type $pdir -origin {40 $y} -name $pname"
      incr y 20
    }
  }
  if {$type == "nmos" || $type == "pmos"} {
    puts $fh "  icon_line -60 0 -30 0 -30 -20 -30 20"
    puts $fh "  icon_line 0 40 0 20 -20 20 -20 -20 0 -20 0 -40"
  } else {
    puts $fh "  icon_line -20 -20 20 -20 20 20 -20 20 -20 -20"
  }
  puts $fh "  icon_property -origin {-70 80} -type user -name name"
  puts $fh "  icon_property -origin {-70 100} -type user -name M"
  set py 120
  foreach pair $params {
    set k [lindex $pair 0]
    set v [lindex $pair 1]
    puts $fh "  icon_property -origin {-70 $py} -type user -name $k -default $v"
    incr py 20
  }
  set nodes {}
  set has_b 0
  foreach pin $pins {
    set pname [lindex $pin 0]
    if {$pname == "b"} { set has_b 1 }
    lappend nodes "\$[lindex $pin 0]"
  }
  if {!$has_b && $type == "nmos"} { lappend nodes gnd }
  if {!$has_b && $type == "pmos"} { lappend nodes vdd }
  set tail ""
  foreach pair $params {
    set k [lindex $pair 0]
    if {$k == "W" || $k == "L" || $k == "nf" || $k == "mult"} {
      append tail " $k=\$$k"
    }
  }
  set nodetext [join $nodes " "]
  puts $fh "  icon_property -origin {-190 230} -type fixed -name spice -text \{\[unique_name $prefix \$name\] $nodetext $spice_model$tail\}"
  if {$type == "nmos"} {
    puts $fh "  icon_property -origin {-190 270} -type fixed -name sim -text \{n \$g \$s \$d \[sim_size \$L\] \[sim_size \[expr \$W * 1.0e-6\]\]\}"
  } elseif {$type == "pmos"} {
    puts $fh "  icon_property -origin {-190 270} -type fixed -name sim -text \{p \$g \$s \$d \[sim_size \$L\] \[sim_size \[expr \$W * 1.0e-6\]\]\}"
  }
  puts $fh "  icon_property -origin {10 -10} -label {\$W/\$L}"
  puts $fh "\}"
  close $fh
}

proc sane_icon {path} {
  if {[catch {set fh [open $path r]}]} { return 0 }
  set text [read $fh]
  close $fh
  if {![info complete $text]} { return 0 }
  if {[string first \nspiceprefix $text] >= 0} { return 0 }
  return 1
}

set xroot [file join $pdk libs.tech xschem]
set syms {}
if {[file isdirectory $xroot]} { set syms [walk_syms $xroot] }
set spice_dir [file join $pdk libs.tech ngspice]
set spice_index [spice_names $pdk]

set devdir [file join $dest devices]
file mkdir $devdir
set nmos_cell ""
set pmos_cell ""
set written 0
set skipped 0
set skip_names {}
set index_lines {}
set mtimes {}
set seen {}
set ln_min ""
set lp_min ""

foreach sym $syms {
  set fh [open $sym r]
  set text [read $fh]
  close $fh
  set pins [sym_pins $text]
  set block [sym_kblock $text]
  set type [string tolower [sym_token $block type]]
  set tmap [sym_template $block]
  set model [map_get $tmap model]
  set base [file rootname [file tail $sym]]
  if {$model == ""} { set model $base }
  if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $model]} {
    incr skipped
    lappend skip_names $base
    continue
  }
  if {[llength $pins] < 2} {
    incr skipped
    lappend skip_names $base
    continue
  }
  set folder [file tail [file dirname $sym]]
  set spice_model $model
  if {$folder != "symbols" && $folder != "xschem" && [string match *_pr $folder]} {
    set prefixed ${folder}__$model
    if {[spice_has $spice_index $prefixed]} {
      set spice_model $prefixed
    }
  }
  if {$base == $model} {
    if {$spice_model != $model} {
      set cell $spice_model
    } else {
      set cell $model
    }
  } else {
    if {[string match *_pr $folder]} {
      set cell ${folder}__$base
    } else {
      set cell $base
    }
  }
  regsub -all {[^A-Za-z0-9_]} $cell _ cell
  if {[lsearch -exact $seen $cell] >= 0} {
    incr skipped
    lappend skip_names $cell
    continue
  }
  if {![spice_has $spice_index $spice_model]} {
    incr skipped
    lappend skip_names "$base (no model $spice_model)"
    continue
  }
  set params {}
  foreach key {W L nf mult model} {
    set v [map_get $tmap $key]
    if {$v == ""} {
      if {$key == "model"} { set v $model }
      if {$key == "W"} { set v 1 }
      if {$key == "L"} { set v 0.15 }
    }
    if {$key != "model" && $key != "W" && $key != "L" && $v == ""} continue
    lappend params [list $key $v]
  }
  set prefix X
  set spx [map_get $tmap spiceprefix]
  if {$spx == "M" || $spx == "X" || $spx == "m" || $spx == "x"} {
    set prefix [string toupper $spx]
  } elseif {$type == "nmos" || $type == "pmos"} {
    if {$spx == ""} { set prefix M }
  }
  set out [file join $devdir ${cell}.sue]
  if {[file exists $out]} {
    set head [read [open $out r] 80]
    if {![string match "*mmi-sue-lib generated*" $head]} {
      incr skipped
      lappend skip_names "$cell (user file)"
      continue
    }
  }
  write_icon $out $cell $type $pins $model $spice_model $params $prefix
  if {![sane_icon $out]} {
    file delete -force $out
    incr skipped
    lappend skip_names "$cell (icon did not parse)"
    continue
  }
  lappend seen $cell
  incr written
  lappend index_lines "set auto_index(ICON_$cell) \[list source \[file join \$dir ${cell}.sue\]\]"
  lappend mtimes "${cell}.sue 0"
  set lval [map_get $tmap L]
  if {$type == "nmos" && [regexp {^[0-9.]+$} $lval]} {
    if {$ln_min == "" || $lval < $ln_min} { set ln_min $lval }
    if {[string match *__nfet_01v8 $cell] || [string match *__nfet_03v3 $cell] || $nmos_cell == ""} {
      if {$nmos_cell == "" || ![string match *__nfet_01v8 $nmos_cell]} {
        set nmos_cell $cell
      }
    }
  }
  if {$type == "pmos" && [regexp {^[0-9.]+$} $lval]} {
    if {$lp_min == "" || $lval < $lp_min} { set lp_min $lval }
    if {[string match *__pfet_01v8 $cell] || [string match *__pfet_03v3 $cell] || $pmos_cell == ""} {
      if {$pmos_cell == "" || ![string match *__pfet_01v8 $pmos_cell]} {
        set pmos_cell $cell
      }
    }
  }
}

if {$written == 0} {
  write_icon [file join $devdir nmos.sue] nmos nmos {{d inout} {s inout} {g input}} nmos nmos {{W 1} {L 0.15} {model nmos}} M
  write_icon [file join $devdir pmos.sue] pmos pmos {{d inout} {s inout} {g input}} pmos pmos {{W 1} {L 0.15} {model pmos}} M
  write_icon [file join $devdir resistor.sue] resistor resistor {{t1 inout} {t2 inout}} polyres polyres {{model polyres}} X
  set nmos_cell nmos
  set pmos_cell pmos
  set written 3
  set index_lines {
    {set auto_index(ICON_nmos) [list source [file join $dir nmos.sue]]}
    {set auto_index(ICON_pmos) [list source [file join $dir pmos.sue]]}
    {set auto_index(ICON_resistor) [list source [file join $dir resistor.sue]]}
  }
  set mtimes {nmos.sue 0 pmos.sue 0 resistor.sue 0}
  set seen {nmos pmos resistor}
}

set ih [open [file join $devdir tclIndex] w]
puts $ih "# Tcl autoload index file, version 2.0"
puts $ih "# mmi-sue-lib generated"
foreach line $index_lines { puts $ih $line }
puts $ih "set mtimes {$mtimes}"
close $ih

set spice_file ""
foreach pat {sky130.lib.spice *.lib.spice *.lib all.spice} {
  set hits [glob -nocomplain -directory $spice_dir $pat]
  if {[llength $hits]} { set spice_file [lindex $hits 0]; break }
}
if {$ln_min == ""} { set ln_min 0.15 }
if {$lp_min == ""} { set lp_min 0.15 }

set hh [open [file join $dest spice_header.h] w]
puts $hh "* mmi-sue-lib generated — $libname"
puts $hh ".OPTIONS post ACCT"
if {$spice_file != ""} {
  puts $hh ".lib '$spice_file' TT"
}
puts $hh ".param ln_min = ${ln_min}u"
puts $hh ".param lp_min = ${lp_min}u"
puts $hh ".param arean(w,sdd) = '(w*sdd*1p)'"
puts $hh ".param areap(w,sdd) = '(w*sdd*1p)'"
puts $hh ".param perin(w,sdd) = '(2u*(w+sdd))'"
puts $hh ".param perip(w,sdd) = '(2u*(w+sdd))'"
puts $hh ".param sdd = 0.29"
close $hh

set sh [open [file join $dest lib.suerc] w]
puts $sh "# mmi-sue-lib generated"
puts $sh "set DEFAULT_SPICE_HEADER \[file join [list $dest] spice_header.h\]"
puts $sh "set MAX_EXEC {max -tech $maxtech}"
close $sh

if {$nmos_cell != "" && $pmos_cell != ""} {
  file mkdir [file join $dest examples]
  set eh [open [file join $dest examples inverter.sue] w]
  puts $eh "# mmi-sue-lib generated"
  puts $eh "proc SCHEMATIC_inverter args \{"
  puts $eh "  call_use_keyword \$args {{name inverter} {demorgan 0}}"
  puts $eh "  make global -name gnd -origin {550 400}"
  puts $eh "  make global -orient RY -name vdd -origin {550 160}"
  puts $eh "  make $nmos_cell -W WN -L LN -origin {550 360}"
  puts $eh "  make $pmos_cell -W WP -L LP -origin {550 200}"
  puts $eh "  make input -name in -origin {450 280}"
  puts $eh "  make output -name out -origin {570 280}"
  puts $eh "\}"
  close $eh
  set eh [open [file join $dest examples tclIndex] w]
  puts $eh "set auto_index(SCHEMATIC_inverter) \[list source \[file join \$dir inverter.sue\]\]"
  puts $eh "set mtimes {{inverter.sue 0}}"
  close $eh
}

if {$pdktag == ""} { set pdktag unknown }
set stamp [clock format [clock seconds] -gmt 1 -format {%Y-%m-%dT%H:%M:%SZ}]
set shown [lrange $skip_names 0 39]
set lh [open [file join $dest LIBRARY] w]
puts $lh "name $libname"
puts $lh "pdk $pdk"
puts $lh "tag $pdktag"
puts $lh "time $stamp"
puts $lh "max_tech $maxtech"
puts $lh "revision $SUE_LIB_REV"
puts $lh "icons $written"
puts $lh "skipped $skipped"
puts $lh "skipped_names [join $shown {, }]"
puts $lh "stdcells later"
puts $lh "generated mmi-sue-lib"
close $lh

puts "sue library $libname: $written icons, $skipped skipped, -> $dest"
if {[llength $skip_names]} {
  puts "skipped: [join [lrange $skip_names 0 14] {, }]"
}
exit 0
