# Import Magic design folder → GDS → .max (pure Tcl)
# File / Local menu: "Import Magic Design Folder..."
#
# Magic's native .mag reader (db_magic) was removed from this MAX package.
# This command walks a directory of .mag files, writes one GDSII library,
# then asks MAX to read that GDS and save .max cells.

if {[info exists _MAG_IMPORT_SOURCED]} { return }
set _MAG_IMPORT_SOURCED 1

if {[info commands setl] == ""} {
  proc setl {names vals} {
    set i 0
    foreach n $names {
      upvar 1 $n v
      set v [lindex $vals $i]
      incr i
    }
  }
}

set MAG_IMPORT(source)  "sample"
set MAG_IMPORT(dir)     ""
set MAG_IMPORT(top)     "auto"
set MAG_IMPORT(tech)    ""
set MAG_IMPORT(method)  "mag2gds"
set MAG_IMPORT(pid)     ""
set MAG_IMPORT(after)   ""
set MAG_IMPORT(cancel)  ""
set MAG_IMPORT(log)     ""
set MAG_IMPORT(work)    ""

# ── Magic paint name → GDS layer:datatype (sky130 / gf180 / ihp) ─────────────
# Direct paint dump (not Magic cifoutput boolean generation).

proc mag_gds_map_sky130 {layer} {
  set n [string tolower $layer]
  switch -exact -- $n {
    nwell { return {64 20} }
    pwell { return {64 13} }
    dnwell { return {64 18} }
    diff - ndiff - pdiff - mvndiff - mvpdiff - mvnmos - mvpmos -
    ndiode - pdiode { return {65 20} }
    tap - nsd - psd - mvpsubdiff - mvnsubdiff - psubdiff - mvnsd - mvpsd { return {65 44} }
    poly - xpolyres { return {66 20} }
    polyres - res0p69 { return {66 13} }
    licon1 - polycont - xpolycontact - mvndiffc - mvpdiffc -
    mvpsubdiffcont - mvnsubdiffcont - psubdiffcont { return {66 44} }
    li1 - locali - li { return {67 20} }
    mcon - viali - vial { return {67 44} }
    met1 - metal1 - m1 { return {68 20} }
    via - via1 { return {68 44} }
    met2 - metal2 - m2 { return {69 20} }
    via2 { return {69 44} }
    met3 - metal3 - m3 { return {70 20} }
    via3 { return {70 44} }
    met4 - metal4 - m4 { return {71 20} }
    via4 { return {71 44} }
    met5 - metal5 - m5 { return {72 20} }
    mimcap { return {89 44} }
    mimcapcontact - mimcc { return {70 44} }
    mimcap2 { return {97 44} }
    mimcap2contact { return {71 44} }
    nsdm { return {93 44} }
    psdm { return {94 20} }
    npc { return {95 20} }
    hvntm { return {125 20} }
    hvi { return {75 20} }
    bound - bbox - areaid_sl { return {235 4} }
    text { return {64 5} }
  }
  return {}
}

proc mag_gds_map_gf180 {layer} {
  set n [string tolower $layer]
  switch -exact -- $n {
    nwell { return {21 0} }
    dnwell { return {12 0} }
    comp - diff - ndiff - pdiff { return {22 0} }
    poly - poly2 { return {30 0} }
    nplus { return {32 0} }
    pplus { return {31 0} }
    contact - licon1 { return {33 0} }
    metal1 - met1 { return {34 0} }
    via1 - via { return {35 0} }
    metal2 - met2 { return {36 0} }
    via2 { return {38 0} }
    metal3 - met3 { return {42 0} }
    via3 { return {40 0} }
    metal4 - met4 { return {46 0} }
    via4 { return {41 0} }
    metal5 - met5 { return {81 0} }
    text { return {31 0} }
  }
  return {}
}

proc mag_gds_map_sg13g2 {layer} {
  set n [string tolower $layer]
  switch -exact -- $n {
    activ - diff { return {1 0} }
    gatpoly - poly { return {5 0} }
    nwell { return {31 0} }
    nsd { return {7 0} }
    psd { return {14 0} }
    cont - contact { return {6 0} }
    metal1 - met1 { return {8 0} }
    via1 { return {19 0} }
    metal2 - met2 { return {10 0} }
    via2 { return {29 0} }
    metal3 - met3 { return {30 0} }
    via3 { return {49 0} }
    metal4 - met4 { return {50 0} }
    via4 { return {66 0} }
    metal5 - met5 { return {67 0} }
    text { return {63 0} }
  }
  return {}
}

proc mag_gds_map {family layer} {
  global MAG_GDS_UNKNOWN
  set rec {}
  if {$family == "gf180mcu"} {
    set rec [mag_gds_map_gf180 $layer]
  } elseif {$family == "sg13g2"} {
    set rec [mag_gds_map_sg13g2 $layer]
  } else {
    set rec [mag_gds_map_sky130 $layer]
  }
  if {[llength $rec]} { return $rec }
  if {![info exists MAG_GDS_UNKNOWN($layer)]} {
    set MAG_GDS_UNKNOWN($layer) [expr {200 + [array size MAG_GDS_UNKNOWN]}]
    mag_log "Unmapped Magic layer '$layer' → GDS $MAG_GDS_UNKNOWN($layer)/0"
  }
  return [list $MAG_GDS_UNKNOWN($layer) 0]
}

proc mag_family_from_tech {tech} {
  set t [string tolower $tech]
  if {[string match *gf180* $t]} { return gf180mcu }
  if {[string match *sg13* $t] || [string match *ihp* $t]} { return sg13g2 }
  if {[string match *sky130* $t] || [string match *skywater* $t]} { return sky130A }
  return sky130A
}

proc mag_nm_per_unit {family n d} {
  if {$d == 0} { set d 1 }
  # open_pdks sky130 cifoutput: scalefactor 10 nanometers at magscale 1 1
  set base 10.0
  if {$family == "gf180mcu"} { set base 5.0 }
  if {$family == "sg13g2"} { set base 1.0 }
  return [expr {$base * double($n) / double($d)}]
}

proc mag_log {msg} {
  global MAG_IMPORT
  catch {
    set fh [open $MAG_IMPORT(log) a]
    puts $fh $msg
    close $fh
  }
  catch {puts $msg}
}

proc mag_cancelled {} {
  global MAG_IMPORT
  return [expr {$MAG_IMPORT(cancel) != "" && [file exists $MAG_IMPORT(cancel)]}]
}

proc mag_pdk_magicrc_ok {} {
  set root /mmi-pdks
  if {[info commands pdk_root] != ""} { set root [pdk_root] }
  foreach rel {
    sky130A/libs.tech/magic/sky130A.magicrc
    gf180mcuD/libs.tech/magic/gf180mcuD.magicrc
    ihp-sg13g2/libs.tech/magic/ihp-sg13g2.magicrc
  } {
    if {[file exists [file join $root $rel]]} { return 1 }
  }
  return 0
}

proc mag_sample_dir {} {
  global env MMI_TOOLS
  set cands {}
  if {[info exists env(MMI_PDK_DIR)] && $env(MMI_PDK_DIR) != ""} {
    lappend cands [file join $env(MMI_PDK_DIR) samples caravel_analog_por]
  }
  if {[info exists MMI_TOOLS] && $MMI_TOOLS != ""} {
    lappend cands [file join $MMI_TOOLS ../mmi_local/max/pdk/samples/caravel_analog_por]
  }
  if {[info exists env(HOME)]} {
    lappend cands [file join $env(HOME) cad mmi_local max pdk samples caravel_analog_por]
  }
  lappend cands /mmi-bundle/samples/caravel_analog_por
  foreach d $cands {
    set d [file normalize $d]
    if {[file isdirectory $d] && [file exists [file join $d example_por.mag]]} {
      return $d
    }
  }
  return ""
}

proc mag_list_max_techs {} {
  global env MMI_TOOLS MMI_LOCAL MN_TECH
  set roots {}
  if {[info exists MMI_TOOLS] && $MMI_TOOLS != ""} {
    lappend roots [file join $MMI_TOOLS max tech]
  }
  if {[info exists MMI_LOCAL] && $MMI_LOCAL != ""} {
    lappend roots [file join $MMI_LOCAL max tech]
  } elseif {[info exists MMI_TOOLS] && $MMI_TOOLS != ""} {
    lappend roots [file join $MMI_TOOLS ../mmi_local/max/tech]
  }
  set home ""
  if {[info exists env(HOME)]} { set home $env(HOME) }
  if {$home != ""} {
    lappend roots [file join $home mmi_private max tech]
  }
  if {[info commands pdk_root] != ""} {
    lappend roots [file join [pdk_root] max tech]
  }
  set names {}
  foreach root $roots {
    if {![file isdirectory $root]} { continue }
    if {[catch {set kids [glob -nocomplain -directory $root -types d *]}]} continue
    foreach d $kids {
      set bn [file tail $d]
      if {$bn == "." || $bn == ".."} continue
      if {[lsearch -exact $names $bn] < 0} {
        lappend names $bn
      }
    }
  }
  if {[info exists MN_TECH] && $MN_TECH != "" && [lsearch -exact $names $MN_TECH] < 0} {
    lappend names $MN_TECH
  }
  return [lsort -dictionary $names]
}

proc mag_skip_layer {layer} {
  set n [string tolower $layer]
  switch -exact -- $n {
    labels - properties - end - error_p - error - checkpaint -
    comment - authors - plots - watch { return 1 }
  }
  return 0
}

# ── GDSII binary helpers (big-endian, even-length records) ───────────────────

proc mag_gds_i16 {n} {
  set n [expr {int($n)}]
  if {$n < 0} { set n [expr {$n + 65536}] }
  return [format %04x [expr {$n & 65535}]]
}

proc mag_gds_i32 {n} {
  set n [expr {int($n)}]
  set hex ""
  for {set sh 24} {$sh >= 0} {incr sh -8} {
    append hex [format %02x [expr {($n >> $sh) & 255}]]
  }
  return $hex
}

proc mag_gds_real8 {x} {
  set x [expr {double($x)}]
  if {$x == 0.0} { return 0000000000000000 }
  set sign 0
  if {$x < 0.0} {
    set sign 1
    set x [expr {0.0 - $x}]
  }
  set exp 0
  while {$x >= 1.0 && $exp < 63} {
    set x [expr {$x / 16.0}]
    incr exp
  }
  while {$x < 0.0625 && $exp > -64} {
    set x [expr {$x * 16.0}]
    incr exp -1
  }
  set mant [expr {wide($x * 72057594037927936.0 + 0.5)}]
  if {$mant < 0} { set mant 0 }
  set b0 [expr {($sign * 128) + (($exp + 64) & 127)}]
  set hex [format %02x $b0]
  for {set sh 48} {$sh >= 0} {incr sh -8} {
    append hex [format %02x [expr {(wide($mant) >> $sh) & 255}]]
  }
  return $hex
}

proc mag_gds_ascii {s} {
  set hex ""
  set n [string length $s]
  for {set i 0} {$i < $n} {incr i} {
    scan [string index $s $i] %c c
    append hex [format %02x $c]
  }
  if {[expr {$n % 2}] == 1} {
    append hex 00
  }
  return $hex
}

proc mag_gds_rec {fh type dtype hexdata} {
  set nbytes [expr {[string length $hexdata] / 2}]
  set tot [expr {4 + $nbytes}]
  if {[expr {$tot % 2}] == 1} {
    append hexdata 00
    incr tot
  }
  set hdr [mag_gds_i16 $tot]
  append hdr [format %02x $type]
  append hdr [format %02x $dtype]
  puts -nonewline $fh [binary format H* $hdr$hexdata]
}

proc mag_gds_header {fh libname} {
  mag_gds_rec $fh 0 2 [mag_gds_i16 600]
  set now [clock seconds]
  set y [clock format $now -format %Y]
  set mo [clock format $now -format %m]
  set d [clock format $now -format %d]
  set h [clock format $now -format %H]
  set mi [clock format $now -format %M]
  set s [clock format $now -format %S]
  set dates ""
  foreach _ {1 2} {
    append dates [mag_gds_i16 $y][mag_gds_i16 $mo][mag_gds_i16 $d]
    append dates [mag_gds_i16 $h][mag_gds_i16 $mi][mag_gds_i16 $s]
  }
  mag_gds_rec $fh 1 2 $dates
  mag_gds_rec $fh 2 6 [mag_gds_ascii $libname]
  mag_gds_rec $fh 3 5 [mag_gds_real8 0.001][mag_gds_real8 1.0e-9]
}

proc mag_gds_endlib {fh} {
  mag_gds_rec $fh 4 0 ""
}

proc mag_gds_bgnstr {fh name} {
  mag_gds_rec $fh 5 2 [string repeat [mag_gds_i16 0] 12]
  mag_gds_rec $fh 6 6 [mag_gds_ascii $name]
}

proc mag_gds_endstr {fh} {
  mag_gds_rec $fh 7 0 ""
}

proc mag_gds_xy {coords} {
  set hex ""
  foreach n $coords {
    append hex [mag_gds_i32 $n]
  }
  return $hex
}

proc mag_gds_boundary {fh lay dt xy} {
  mag_gds_rec $fh 8 0 ""
  mag_gds_rec $fh 13 2 [mag_gds_i16 $lay]
  mag_gds_rec $fh 14 2 [mag_gds_i16 $dt]
  mag_gds_rec $fh 16 3 [mag_gds_xy $xy]
  mag_gds_rec $fh 17 0 ""
}

proc mag_gds_sref {fh cell refl ang x y} {
  mag_gds_rec $fh 10 0 ""
  mag_gds_rec $fh 18 6 [mag_gds_ascii $cell]
  set flags 0
  if {$refl} { set flags 32768 }
  mag_gds_rec $fh 26 1 [mag_gds_i16 $flags]
  mag_gds_rec $fh 28 5 [mag_gds_real8 $ang]
  mag_gds_rec $fh 16 3 [mag_gds_xy [list $x $y]]
  mag_gds_rec $fh 17 0 ""
}

proc mag_gds_aref {fh cell refl ang cols rows ox oy cx cy rx ry} {
  mag_gds_rec $fh 11 0 ""
  mag_gds_rec $fh 18 6 [mag_gds_ascii $cell]
  set flags 0
  if {$refl} { set flags 32768 }
  mag_gds_rec $fh 26 1 [mag_gds_i16 $flags]
  mag_gds_rec $fh 28 5 [mag_gds_real8 $ang]
  mag_gds_rec $fh 19 2 [mag_gds_i16 $cols][mag_gds_i16 $rows]
  mag_gds_rec $fh 16 3 [mag_gds_xy [list $ox $oy $cx $cy $rx $ry]]
  mag_gds_rec $fh 17 0 ""
}

proc mag_gds_text {fh lay dt x y str} {
  mag_gds_rec $fh 12 0 ""
  mag_gds_rec $fh 13 2 [mag_gds_i16 $lay]
  mag_gds_rec $fh 22 2 [mag_gds_i16 $dt]
  mag_gds_rec $fh 16 3 [mag_gds_xy [list $x $y]]
  mag_gds_rec $fh 25 6 [mag_gds_ascii $str]
  mag_gds_rec $fh 17 0 ""
}

# Magic manhattan transform → (reflect, angle_deg)
proc mag_sref_orient {a b d e} {
  set a [expr {int($a)}]
  set b [expr {int($b)}]
  set d [expr {int($d)}]
  set e [expr {int($e)}]
  if {$a == 1 && $b == 0 && $d == 0 && $e == 1} { return {0 0} }
  if {$a == 0 && $b == -1 && $d == 1 && $e == 0} { return {0 90} }
  if {$a == -1 && $b == 0 && $d == 0 && $e == -1} { return {0 180} }
  if {$a == 0 && $b == 1 && $d == -1 && $e == 0} { return {0 270} }
  if {$a == 1 && $b == 0 && $d == 0 && $e == -1} { return {1 0} }
  if {$a == 0 && $b == 1 && $d == 1 && $e == 0} { return {1 90} }
  if {$a == -1 && $b == 0 && $d == 0 && $e == 1} { return {1 180} }
  if {$a == 0 && $b == -1 && $d == -1 && $e == 0} { return {1 270} }
  set ang [expr {atan2(double($d), double($a)) * 180.0 / 3.141592653589793}]
  return [list 0 $ang]
}

proc mag_scale_xy {x y scale} {
  set gx [expr {round(double($x) * $scale)}]
  set gy [expr {round(double($y) * $scale)}]
  return [list $gx $gy]
}

# ── .mag parser ──────────────────────────────────────────────────────────────

proc mag_gets {fh} {
  upvar 1 lookahead lookahead
  if {$lookahead != ""} {
    set line $lookahead
    set lookahead ""
    return $line
  }
  if {[gets $fh line] < 0} { return "" }
  return $line
}

proc mag_parse_file {path} {
  global MAGDB
  set name [file rootname [file tail $path]]
  if {[catch {set fh [open $path r]} err]} {
    mag_log "Cannot read $path: $err"
    return ""
  }
  set MAGDB($name,n) 1
  set MAGDB($name,d) 1
  set MAGDB($name,layers) {}
  set MAGDB($name,uses) {}
  set MAGDB($name,labels) {}
  set MAGDB($name,bbox) ""
  set MAGDB($name,file) $path
  set layer ""
  set section paint
  set lookahead ""
  while {1} {
    set raw [mag_gets $fh]
    if {$raw == "" && $lookahead == "" && [eof $fh]} { break }
    set line [string trim $raw]
    if {$line == "" || [string match #* $line]} continue
    if {[regexp {^<<[ \t]*([^>]+)[ \t]*>>} $line -> sec]} {
      set sec [string trim $sec]
      set layer $sec
      set sl [string tolower $sec]
      if {$sl == "labels"} {
        set section labels
      } elseif {$sl == "properties"} {
        set section props
      } elseif {$sl == "end"} {
        break
      } else {
        set section paint
        if {![mag_skip_layer $layer] && [lsearch -exact $MAGDB($name,layers) $layer] < 0} {
          lappend MAGDB($name,layers) $layer
        }
      }
      continue
    }
    if {$section == "props"} continue
    if {$section == "labels"} {
      if {[regexp {^(rlabel|flabel)[ \t]+([^ \t]+)[ \t]+[^ \t]+[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(.*)$} $line -> kind lname x1 y1 x2 y2 rest]} {
        set rest [string trim $rest]
        if {$kind == "flabel"} {
          set toks [split $rest]
          if {[llength $toks] > 6} {
            set text [join [lrange $toks 6 end] " "]
          } else {
            set text [lindex $toks end]
          }
        } else {
          set text $rest
        }
        set text [string trim $text]
        lappend MAGDB($name,labels) [list $lname $x1 $y1 $x2 $y2 $text]
      }
      continue
    }
    if {[regexp {^tech[ \t]+} $line]} continue
    if {[regexp {^timestamp[ \t]+} $line]} continue
    if {[regexp {^magic$} $line]} continue
    if {[regexp {^magscale[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)} $line -> n d]} {
      set MAGDB($name,n) $n
      set MAGDB($name,d) $d
      continue
    }
    if {[regexp {^rect[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)} $line -> x1 y1 x2 y2]} {
      if {$layer != "" && ![mag_skip_layer $layer]} {
        lappend MAGDB($name,$layer) [list rect $x1 $y1 $x2 $y2]
      }
      continue
    }
    if {[regexp {^tri[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)} $line -> x1 y1 x2 y2 x3 y3]} {
      if {$layer != "" && ![mag_skip_layer $layer]} {
        lappend MAGDB($name,$layer) [list tri $x1 $y1 $x2 $y2 $x3 $y3]
      }
      continue
    }
    if {[regexp {^use[ \t]+([^ \t]+)[ \t]+([^ \t]+)} $line -> cell inst]} {
      set a 1; set b 0; set c 0; set d 0; set e 1; set f 0
      set arr ""
      set box ""
      while {1} {
        set raw [mag_gets $fh]
        if {$raw == "" && [eof $fh]} { break }
        set peek [string trim $raw]
        if {$peek == "" || [string match #* $peek]} continue
        if {[regexp {^timestamp[ \t]+} $peek]} continue
        if {[regexp {^transform[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)} $peek -> a b c d e f]} continue
        if {[regexp {^array[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)} $peek -> xlo xhi xsep ylo yhi ysep]} {
          set arr [list $xlo $xhi $xsep $ylo $yhi $ysep]
          continue
        }
        if {[regexp {^box[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)[ \t]+(-?[0-9]+)} $peek -> bx1 by1 bx2 by2]} {
          set box [list $bx1 $by1 $bx2 $by2]
          continue
        }
        set lookahead $raw
        break
      }
      lappend MAGDB($name,uses) [list $cell $inst $a $b $c $d $e $f $arr $box]
      continue
    }
  }
  close $fh
  if {[lsearch -exact $MAGDB(cells) $name] < 0} {
    lappend MAGDB(cells) $name
  }
  return $name
}

proc mag_collect_mags {root} {
  set out {}
  set dirs [list $root]
  set n 0
  while {[llength $dirs] && $n < 8000} {
    set dir [lindex $dirs 0]
    set dirs [lrange $dirs 1 end]
    if {[catch {set names [glob -nocomplain -directory $dir *]}]} continue
    foreach f $names {
      incr n
      set bn [file tail $f]
      if {[file isdirectory $f]} {
        set low [string tolower $bn]
        if {$bn == ".git" || $low == "maglef"} continue
        lappend dirs $f
      } else {
        if {[string match *.mag $bn] && ![string match *.maglef $bn]} {
          lappend out $f
        }
      }
    }
  }
  return $out
}

proc mag_pick_top {hint} {
  global MAGDB
  if {$hint != "" && $hint != "auto" && [info exists MAGDB($hint,n)]} {
    return $hint
  }
  set used {}
  foreach name $MAGDB(cells) {
    foreach u $MAGDB($name,uses) {
      set child [lindex $u 0]
      set used($child) 1
    }
  }
  set roots {}
  foreach name $MAGDB(cells) {
    if {![info exists used($name)]} {
      lappend roots $name
    }
  }
  foreach prefer {example_por user_analog_proj_example} {
    if {[lsearch -exact $roots $prefer] >= 0} { return $prefer }
    if {[info exists MAGDB($prefer,n)]} { return $prefer }
  }
  if {[llength $roots]} { return [lindex $roots 0] }
  if {[llength $MAGDB(cells)]} { return [lindex $MAGDB(cells) 0] }
  return ""
}

proc mag_topo_order {} {
  global MAGDB
  set pending $MAGDB(cells)
  # include stub children
  foreach name $MAGDB(cells) {
    foreach u $MAGDB($name,uses) {
      set child [lindex $u 0]
      if {[lsearch -exact $pending $child] < 0} {
        lappend pending $child
      }
    }
  }
  set done {}
  set guard 0
  while {[llength $pending] && $guard < 20000} {
    incr guard
    set next {}
    set progressed 0
    foreach name $pending {
      set ready 1
      if {[info exists MAGDB($name,uses)]} {
        foreach u $MAGDB($name,uses) {
          set child [lindex $u 0]
          if {$child != $name && [lsearch -exact $done $child] < 0} {
            set ready 0
            break
          }
        }
      }
      if {$ready} {
        lappend done $name
        set progressed 1
      } else {
        lappend next $name
      }
    }
    if {!$progressed} {
      set done [concat $done $next]
      break
    }
    set pending $next
  }
  return $done
}

proc mag_write_cell {fh name family} {
  global MAGDB
  mag_gds_bgnstr $fh $name
  set n 1
  set d 1
  if {[info exists MAGDB($name,n)]} { set n $MAGDB($name,n) }
  if {[info exists MAGDB($name,d)]} { set d $MAGDB($name,d) }
  set scale [mag_nm_per_unit $family $n $d]

  if {[info exists MAGDB($name,layers)]} {
    foreach layer $MAGDB($name,layers) {
      if {![info exists MAGDB($name,$layer)]} continue
      setl {lay dt} [mag_gds_map $family $layer]
      foreach geom $MAGDB($name,$layer) {
        set kind [lindex $geom 0]
        if {$kind == "rect"} {
          setl {x1 y1 x2 y2} [lrange $geom 1 4]
          setl {gx1 gy1} [mag_scale_xy $x1 $y1 $scale]
          setl {gx2 gy2} [mag_scale_xy $x2 $y2 $scale]
          mag_gds_boundary $fh $lay $dt \
              [list $gx1 $gy1 $gx2 $gy1 $gx2 $gy2 $gx1 $gy2 $gx1 $gy1]
        } elseif {$kind == "tri"} {
          setl {x1 y1 x2 y2 x3 y3} [lrange $geom 1 6]
          setl {gx1 gy1} [mag_scale_xy $x1 $y1 $scale]
          setl {gx2 gy2} [mag_scale_xy $x2 $y2 $scale]
          setl {gx3 gy3} [mag_scale_xy $x3 $y3 $scale]
          mag_gds_boundary $fh $lay $dt \
              [list $gx1 $gy1 $gx2 $gy2 $gx3 $gy3 $gx1 $gy1]
        }
      }
    }
  }

  if {[info exists MAGDB($name,labels)]} {
    foreach lab $MAGDB($name,labels) {
      setl {lname x1 y1 x2 y2 text} $lab
      if {$text == ""} continue
      setl {lay dt} [mag_gds_map $family $lname]
      set mx [expr {($x1 + $x2) / 2.0}]
      set my [expr {($y1 + $y2) / 2.0}]
      setl {gx gy} [mag_scale_xy $mx $my $scale]
      mag_gds_text $fh $lay 5 $gx $gy $text
    }
  }

  if {[info exists MAGDB($name,uses)]} {
    foreach u $MAGDB($name,uses) {
      set cell [lindex $u 0]
      set a [lindex $u 2]
      set b [lindex $u 3]
      set c [lindex $u 4]
      set d [lindex $u 5]
      set e [lindex $u 6]
      set f [lindex $u 7]
      set arr [lindex $u 8]
      setl {refl ang} [mag_sref_orient $a $b $d $e]
      setl {gx gy} [mag_scale_xy $c $f $scale]
      if {$arr != ""} {
        setl {xlo xhi xsep ylo yhi ysep} $arr
        set cols [expr {$xhi - $xlo + 1}]
        set rows [expr {$yhi - $ylo + 1}]
        if {$cols < 1} { set cols 1 }
        if {$rows < 1} { set rows 1 }
        set ox [expr {$c + $xlo * $xsep}]
        set oy [expr {$f + $ylo * $ysep}]
        setl {gox goy} [mag_scale_xy $ox $oy $scale]
        setl {gcx gcy} [mag_scale_xy [expr {$ox + $cols * $xsep}] $oy $scale]
        setl {grx gry} [mag_scale_xy $ox [expr {$oy + $rows * $ysep}] $scale]
        mag_gds_aref $fh $cell $refl $ang $cols $rows $gox $goy $gcx $gcy $grx $gry
      } else {
        mag_gds_sref $fh $cell $refl $ang $gx $gy
      }
    }
  }

  # Empty placeholder (missing stdcell): draw the instance box if we stored one
  if {![info exists MAGDB($name,layers)] || ![llength $MAGDB($name,layers)]} {
    if {[info exists MAGDB($name,stubbox)] && $MAGDB($name,stubbox) != ""} {
      setl {x1 y1 x2 y2} $MAGDB($name,stubbox)
      setl {gx1 gy1} [mag_scale_xy $x1 $y1 $scale]
      setl {gx2 gy2} [mag_scale_xy $x2 $y2 $scale]
      mag_gds_boundary $fh 235 4 \
          [list $gx1 $gy1 $gx2 $gy1 $gx2 $gy2 $gx1 $gy2 $gx1 $gy1]
    }
  }

  mag_gds_endstr $fh
}

proc mag_write_gds {gdsfile family} {
  global MAGDB
  if {[catch {set fh [open $gdsfile w]} err]} {
    return "Cannot write $gdsfile: $err"
  }
  fconfigure $fh -translation binary
  mag_gds_header $fh magimport
  foreach name [mag_topo_order] {
    mag_write_cell $fh $name $family
  }
  mag_gds_endlib $fh
  close $fh
  return ""
}

# ── Dialog + engine ──────────────────────────────────────────────────────────

proc mag_import_dialog {} -desc {
  Convert a Magic design folder (.mag) to GDS, then to MAX .max and open it.
} {
  global MAG_IMPORT MN_TECH

  set sample [mag_sample_dir]
  if {![mag_pdk_magicrc_ok]} {
    set MAG_IMPORT(method) tcl
  }
  set techs [mag_list_max_techs]
  if {![llength $techs]} {
    set techs {mmi18 mmi25}
  }

  set labels {}
  set values {}
  foreach t $techs {
    lappend labels $t
    lappend values $t
  }

  if {$MAG_IMPORT(tech) == ""} {
    if {[lsearch -exact $techs sky130A] >= 0} {
      set MAG_IMPORT(tech) sky130A
    } elseif {[info exists MN_TECH] && [lsearch -exact $techs $MN_TECH] >= 0} {
      set MAG_IMPORT(tech) $MN_TECH
    } else {
      set MAG_IMPORT(tech) [lindex $techs 0]
    }
  }

  set src_labels {"Caravel analog sample (example_por, sky130A)" "Choose Magic design folder..."}
  set src_values {sample custom}
  if {$sample == ""} {
    set src_labels {"Choose Magic design folder..."}
    set src_values {custom}
    set MAG_IMPORT(source) custom
  }

  set prop_list ""
  lappend prop_list [list "Magic source:" MAG_IMPORT(source) \
      -radio $src_labels -values $src_values -reload \
      -help {The bundled sample is Efabless caravel_user_project_analog/mag example_por (power-on-reset).}]

  lappend prop_list [list "Magic design folder:" MAG_IMPORT(dir) \
      -filename [list -message {Magic design directory} -dironly -pattern *.mag] \
      -width 56 -when {$MAG_IMPORT(source) == "custom"}]

  lappend prop_list [list "Top cell (auto = hierarchy root):" MAG_IMPORT(top) -entry -width 40]

  lappend prop_list [list "GDS conversion method:" MAG_IMPORT(method) \
      -radio [list \
          "Magic mag2gds — tapeout-quality (needs Magic + shared PDK)" \
          "Tcl paint dump — fast, no Magic (NOT tapeout-quality)"] \
      -values {mag2gds tcl} \
      -help {Magic mag2gds: real Magic VLSI writes GDS using the PDK cifoutput rules (contacts, derived layers, correct units). Requires \$PDK_ROOT/<pdk>/libs.tech/magic/*.magicrc (shared folder ./pdks → /mmi-pdks). Tcl dump: MAX Tcl copies paint rectangles to GDS layers; no Magic binary; missing stdcells become empty boxes.}]

  lappend prop_list [list "Destination MAX PDK / technology:" MAG_IMPORT(tech) \
      -radio $labels -values $values \
      -help {Must match the process of the .mag files (sky130A for the Caravel sample). Import a PDK first if the list is only mmi18/mmi25. MAX tech files live under \$PDK_ROOT/max/tech/ (same shared folder Magic uses).}]

  if {![prop_menu2 -title "Import Magic Design Folder" $prop_list]} {
    return
  }

  if {$MAG_IMPORT(source) == "sample"} {
    set tl [string tolower $MAG_IMPORT(tech)]
    if {![string match *sky130* $tl]} {
      set w 0
      catch {
        set w [tk_dialog .magwarn "PDK mismatch?" \
            "The Caravel analog sample (example_por) is a sky130A Magic design.\nDestination technology is '$MAG_IMPORT(tech)'.\n\nImport SKY130A first unless you know this tech maps those GDS layers.\nContinue anyway?" \
            {} 0 Continue Cancel]
      }
      if {$w != 0} { return }
    }
  }

  set dir ""
  if {$MAG_IMPORT(source) == "sample"} {
    set dir $sample
    if {$MAG_IMPORT(top) == "auto" || $MAG_IMPORT(top) == ""} {
      set MAG_IMPORT(top) example_por
    }
  } else {
    set dir [string trim $MAG_IMPORT(dir)]
  }
  if {$dir != "" && [file isfile $dir]} {
    set dir [file dirname $dir]
  }
  if {$dir == "" || ![file isdirectory $dir]} {
    max_error "Select a Magic design directory (folder that contains .mag files)."
    return
  }
  if {$MAG_IMPORT(tech) == ""} {
    max_error "Select a destination MAX technology (Import PDK from URL if none are listed)."
    return
  }
  mag_import_run $dir $MAG_IMPORT(top) $MAG_IMPORT(tech) $MAG_IMPORT(method)
}

proc mag_import_run {dir top tech {method mag2gds}} {
  global MAG_IMPORT MAGDB MAG_GDS_UNKNOWN env MN_TECH

  catch {unset MAGDB}
  catch {unset MAG_GDS_UNKNOWN}
  set MAGDB(cells) {}
  set MAG_IMPORT(method) $method
  set MAG_IMPORT(pid) ""

  set stamp [clock seconds]
  set work [file join /tmp mag_import_$stamp]
  catch {file mkdir $work}
  set MAG_IMPORT(work) $work
  set MAG_IMPORT(log) [file join $work convert.log]
  set MAG_IMPORT(cancel) [file join $work CANCEL]
  catch {file delete $MAG_IMPORT(cancel)}
  mag_log "Magic import dir=$dir tech=$tech top=$top method=$method"

  mag_progress_open $method
  mag_progress_update 5 "Scanning .mag files..."

  set files [mag_collect_mags $dir]
  if {![llength $files]} {
    mag_import_fail "No .mag files in:\n$dir"
    return
  }
  mag_log "[llength $files] mag files"

  mag_progress_update 12 "Parsing Magic cells (top-cell / hierarchy)..."
  set i 0
  set nfiles [llength $files]
  foreach f $files {
    if {[mag_cancelled]} {
      mag_import_fail "Cancelled."
      return
    }
    incr i
    set pct [expr {12 + int(18.0 * $i / $nfiles)}]
    mag_progress_update $pct "Parsing [file tail $f] ($i / $nfiles)"
    mag_parse_file $f
  }

  foreach name $MAGDB(cells) {
    foreach u $MAGDB($name,uses) {
      set child [lindex $u 0]
      set box [lindex $u 9]
      if {![info exists MAGDB($child,n)]} {
        set MAGDB($child,n) $MAGDB($name,n)
        set MAGDB($child,d) $MAGDB($name,d)
        set MAGDB($child,layers) {}
        set MAGDB($child,uses) {}
        set MAGDB($child,labels) {}
        set MAGDB($child,stubbox) $box
        lappend MAGDB(cells) $child
        mag_log "Placeholder cell $child (no .mag in folder)"
      }
    }
  }

  set topcell [mag_pick_top $top]
  if {$topcell == ""} {
    mag_import_fail "Could not determine a top cell."
    return
  }
  mag_log "Top cell $topcell"

  set family [mag_family_from_tech $tech]
  set outdir [file join $dir max_import]
  catch {file mkdir $outdir}
  set gds [file join $outdir ${topcell}.gds]

  if {$method == "mag2gds"} {
    mag_import_run_magic $dir $topcell $gds $family $tech $outdir
    return
  }

  mag_progress_update 70 "Tcl paint dump → $gds (not tapeout-quality)"
  set err [mag_write_gds $gds $family]
  if {$err != ""} {
    mag_import_fail $err
    return
  }
  if {![file exists $gds] || [file size $gds] < 64} {
    mag_import_fail "GDS write produced an empty file:\n$gds"
    return
  }
  mag_log "Wrote $gds ([file size $gds] bytes) via Tcl dump"
  mag_progress_update 85 "Importing GDS into MAX as .max..."
  mag_import_open_max $gds $topcell $tech $outdir
}

proc mag_magic2gds_script {} {
  global MMI_TOOLS env
  set cands {}
  if {[info exists env(MMI_PDK_DIR)] && $env(MMI_PDK_DIR) != ""} {
    lappend cands [file join $env(MMI_PDK_DIR) mag2gds.sh]
  }
  lappend cands /mmi-bundle/mag2gds.sh
  if {[info exists MMI_TOOLS] && $MMI_TOOLS != ""} {
    lappend cands [file join $MMI_TOOLS ../mmi_local/max/pdk/mag2gds.sh]
  }
  if {[info exists env(HOME)]} {
    lappend cands [file join $env(HOME) cad mmi_local max pdk mag2gds.sh]
  }
  foreach s $cands {
    set s [file normalize $s]
    if {[file executable $s] || [file readable $s]} { return $s }
  }
  return ""
}

proc mag_import_run_magic {dir topcell gds family tech outdir} {
  global MAG_IMPORT

  set sh [mag_magic2gds_script]
  if {$sh == ""} {
    mag_import_fail "mag2gds.sh not found. Re-run ./run.sh, or use the Tcl paint-dump converter."
    return
  }

  set magicbin ""
  if {[info commands pdk_which] != ""} {
    set magicbin [pdk_which {magic /mmi-magic/bin/magic}]
  }
  if {$magicbin == "" && [file executable /mmi-magic/bin/magic]} {
    set magicbin /mmi-magic/bin/magic
  }
  if {$magicbin == ""} {
    mag_import_fail "Magic VLSI is not installed in this Nix env.\nUse the Tcl paint-dump converter, or re-run ./run.sh so magic is on PATH."
    return
  }

  mag_progress_update 40 "Running Magic mag2gds (PDK cifoutput)..."
  mag_log "mag2gds: $sh $dir $topcell $gds $family"
  catch {file delete $gds}
  set logfile $MAG_IMPORT(log)
  if {[catch {set MAG_IMPORT(pid) [exec /bin/bash $sh $dir $topcell $gds $family >>& $logfile &]} err]} {
    mag_import_fail "Could not start Magic mag2gds:\n$err"
    return
  }
  set MAG_IMPORT(phase) mag2gds
  set MAG_IMPORT(gds) $gds
  set MAG_IMPORT(topcell) $topcell
  set MAG_IMPORT(tech) $tech
  set MAG_IMPORT(outdir) $outdir
  set MAG_IMPORT(after) [after 500 mag_import_poll_magic]
}

proc mag_import_poll_magic {} {
  global MAG_IMPORT
  set MAG_IMPORT(after) ""

  if {[mag_cancelled]} {
    catch {exec kill $MAG_IMPORT(pid)}
    mag_import_fail "Cancelled."
    return
  }

  mag_progress_update 55 "Magic mag2gds running..."

  set alive 1
  if {$MAG_IMPORT(pid) != ""} {
    if {[catch {exec kill -0 $MAG_IMPORT(pid)}]} {
      set alive 0
    }
  }
  if {$alive} {
    set MAG_IMPORT(after) [after 500 mag_import_poll_magic]
    return
  }

  set gds $MAG_IMPORT(gds)
  if {![file exists $gds] || [file size $gds] < 64} {
    mag_import_fail "Magic mag2gds failed (no GDS).\nNeed \$PDK_ROOT/<pdk>/libs.tech/magic/<pdk>.magicrc\nin the shared folder (host ./pdks → /mmi-pdks).\nLog: $MAG_IMPORT(log)"
    return
  }
  mag_log "Wrote $gds ([file size $gds] bytes) via Magic mag2gds"
  mag_progress_update 85 "Importing GDS into MAX as .max..."
  mag_import_open_max $gds $MAG_IMPORT(topcell) $MAG_IMPORT(tech) $MAG_IMPORT(outdir)
}

proc mag_import_open_max {gds top tech outdir} {
  global MAG_IMPORT MN_TECH GDS_READ_PARTIAL

  set here [pwd]
  set same 0
  if {[info exists MN_TECH] && $MN_TECH == $tech} { set same 1 }

  if {$same} {
    mag_progress_update 90 "Reading GDS in this MAX session..."
    catch {cell_path_add $outdir}
    if {[catch {cd $outdir} err]} {
      mag_import_fail "Cannot cd to $outdir:\n$err"
      return
    }
    set oldp 0
    if {[info exists GDS_READ_PARTIAL]} {
      set oldp $GDS_READ_PARTIAL
      set GDS_READ_PARTIAL 0
    }
    set topCell ""
    if {[catch {set topCell [gds_read $gds]} err]} {
      if {[info exists GDS_READ_PARTIAL]} { set GDS_READ_PARTIAL $oldp }
      catch {cd $here}
      mag_import_fail "gds_read failed:\n$err\nGDS is at:\n$gds"
      return
    }
    if {[info exists GDS_READ_PARTIAL]} { set GDS_READ_PARTIAL $oldp }
    if {$topCell == ""} { set topCell $top }
    catch {cell_load $topCell}
    catch {cell_save_tree 0}
    catch {cd $here}
    mag_progress_close
    set msg "Magic design converted.\n\n\
Top cell: $topCell\n\
MAX technology: $tech\n\
GDS method: $MAG_IMPORT(method)\n\
GDS: $gds\n\
.max files: $outdir\n\
Log: $MAG_IMPORT(log)"
    if {[catch {warning $msg}]} { puts $msg }
    return
  }

  mag_progress_update 92 "Starting MAX -tech $tech..."
  set maxbin max
  if {[info commands pdk_which] != ""} {
    set m [pdk_which {max}]
    if {$m != ""} { set maxbin $m }
  }
  # Launch from $outdir so GDS→.max files are written next to the GDS.
  set script [file join $MAG_IMPORT(work) launch_max.sh]
  set fh [open $script w]
  puts $fh "#!/bin/sh"
  puts $fh "cd \"$outdir\" || exit 1"
  puts $fh "exec \"$maxbin\" -tech \"$tech\" -command 'cell_save_tree 0' \"$gds\""
  close $fh
  catch {exec chmod +x $script}
  if {[catch {exec /bin/sh $script &} err]} {
    mag_progress_close
    mag_import_fail "Could not launch MAX:\n$err\nGDS is at:\n$gds"
    return
  }
  mag_progress_close
  set msg "Magic design converted.\n\n\
Top cell: $top\n\
Opened a new MAX with technology '$tech'.\n\
GDS: $gds\n\
.max files: $outdir\n\
Log: $MAG_IMPORT(log)\n\n\
If the current MAX was started with a different PDK, that is expected:\n\
GDS→.max must use the destination technology."
  if {[catch {warning $msg}]} { puts $msg }
}

proc mag_import_fail {msg} {
  global MAG_IMPORT
  mag_progress_close
  mag_log "ERROR: $msg"
  max_error "Magic import failed.\n$msg\nLog: $MAG_IMPORT(log)"
}

proc mag_progress_open {{method mag2gds}} {
  catch {destroy .magprog}
  toplevel .magprog
  wm title .magprog "Import Magic Design"
  wm geometry .magprog +80+80
  catch {wm transient .magprog .}
  set f .magprog.f
  frame $f -bd 8
  pack $f -fill both -expand 1
  set title "Magic .mag  →  GDS  →  MAX .max"
  if {$method == "mag2gds"} {
    set title "Magic mag2gds (tapeout)  →  MAX .max"
  } else {
    set title "Tcl paint dump (not tapeout)  →  MAX .max"
  }
  label $f.title -text $title -font {Helvetica 12 bold}
  pack $f.title -anchor w -pady {0 6}
  label $f.stage -text "Starting..." -anchor w -width 64
  pack $f.stage -anchor w -fill x
  canvas $f.bar -width 420 -height 22 -bd 1 -relief sunken -highlightthickness 0
  pack $f.bar -fill x -pady 8
  $f.bar create rectangle 0 0 0 22 -fill #2a7ab0 -outline {} -tags fill
  $f.bar create text 210 11 -text "0%" -tags pct -fill white
  label $f.pctlab -text "0%" -anchor e
  pack $f.pctlab -anchor e
  frame $f.btns
  pack $f.btns -fill x -pady {8 0}
  button $f.btns.cancel -text "Cancel" -command mag_import_cancel
  pack $f.btns.cancel -side right
  update idletasks
}

proc mag_progress_close {} {
  global MAG_IMPORT
  if {$MAG_IMPORT(after) != ""} {
    catch {after cancel $MAG_IMPORT(after)}
    set MAG_IMPORT(after) ""
  }
  catch {destroy .magprog}
}

proc mag_progress_update {percent message} {
  if {![winfo exists .magprog.f.bar]} { return }
  if {![string is integer -strict $percent]} { set percent 0 }
  if {$percent < 0} { set percent 0 }
  if {$percent > 100} { set percent 100 }
  set w [winfo width .magprog.f.bar]
  if {$w < 10} { set w 420 }
  set x [expr {int($w * $percent / 100.0)}]
  .magprog.f.bar coords fill 0 0 $x 22
  .magprog.f.bar itemconfigure pct -text "${percent}%"
  .magprog.f.stage configure -text $message
  .magprog.f.pctlab configure -text "${percent}%"
  update idletasks
}

proc mag_import_cancel {} {
  global MAG_IMPORT
  if {$MAG_IMPORT(cancel) != ""} {
    catch {
      set fh [open $MAG_IMPORT(cancel) w]
      puts $fh cancel
      close $fh
    }
  }
  if {$MAG_IMPORT(pid) != ""} {
    catch {exec kill $MAG_IMPORT(pid)}
  }
  mag_progress_update 0 "Cancelling..."
}

proc _mag_import_install_menus {} {
  catch {
    menu_local_cmd "Import Magic Design Folder..." mag_import_dialog \
        "Mag→GDS via Magic mag2gds (tapeout) or Tcl dump, then .max"
  }
  if {![catch {_menu_get_widget File}]} {
    catch {
      menu_add_cmd [_menu_get_widget File] "Import Magic Design Folder..." \
          mag_import_dialog \
          -desc "Convert Magic .mag to GDS (Magic mag2gds or Tcl dump), then MAX .max"
    }
  }
}

_mag_import_install_menus
