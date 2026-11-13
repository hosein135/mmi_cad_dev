# Import Magic design folder → GDS → .max (pure Tcl)
# File / Local menu: "Import Magic Design Folder..."
#
# Magic's native .mag reader (db_magic) was removed from this MAX package.
# Preferred path: mag2gds.sh runs nixpkgs magic-vlsi with the open_pdks tech
# so the GDS carries the real cifoutput geometry (implants, contact cuts, ...).
# Fallback path: this file parses the .mag files itself and writes a GDSII
# library from the paint (no boolean generation), then MAX reads the GDS
# with the imported PDK technology and saves .max cells.
# After a successful convert, open_mag.sh starts Magic GUI on the original
# .mag (same X display as MAX) so the two layouts can be compared.
# MAX then expands all instances (Magic's expanded view) so resistor
# subcells are paint, not empty bboxes with instance names.
# Download options:
#   full die GDS (caravel.gds) opened hierarchical
#   harness + example design Magic (caravel.mag + user_proj_example.mag)
#     converted .mag -> GDS -> MAX, with Magic opened on the .mag
#   local example_por sample
#
# MAX embeds Tcl 8.0: no [ \t] / \S regexp classes (a tab inside [] is a
# literal "t"), no wide(), no string repeat, no glob -directory, no lset.
# Everything below sticks to what 8.0 has.

# Sourced from maxrc via a proc; arrays must be global or they vanish.
global _MAG_IMPORT_SOURCED _MAG_IMPORT_REV_LOADED MAG_IMPORT
set _MAG_IMPORT_REV 16
if {[info exists _MAG_IMPORT_REV_LOADED]} {
  if {$_MAG_IMPORT_REV_LOADED >= $_MAG_IMPORT_REV} { return }
}
set _MAG_IMPORT_SOURCED 1
set _MAG_IMPORT_REV_LOADED $_MAG_IMPORT_REV

set _mag_exact_tcl [file join [file dirname [info script]] mag_exact.tcl]
if {![file readable $_mag_exact_tcl]} {
  foreach _mag_exact_tcl {
    /mmi-pdk-live/mag_exact.tcl
    /mmi-bundle/mag_exact.tcl
  } {
    if {[file readable $_mag_exact_tcl]} break
  }
}
if {[file readable $_mag_exact_tcl]} {
  source $_mag_exact_tcl
} else {
  error "mag_exact.tcl not found (expected next to mag_import.tcl)"
}

if {[info commands _mmi_file_normalize] == ""} {
  proc _mmi_file_normalize {path} {
    if {$path == ""} { return "" }
    if {![regexp {^/} $path]} {
      set path [file join [pwd] $path]
    }
    set parts {}
    foreach p [file split $path] {
      if {$p == "."} continue
      if {$p == ".."} {
        if {[llength $parts] > 1} {
          set parts [lreplace $parts end end]
        }
        continue
      }
      lappend parts $p
    }
    if {[llength $parts] == 0} { return "/" }
    return [eval file join $parts]
  }
}

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

set MAG_IMPORT(source)  "fetch"
set MAG_IMPORT(dir)     ""
set MAG_IMPORT(top)     "auto"
set MAG_IMPORT(tech)    ""
set MAG_IMPORT(method)  "mag2gds"
set MAG_IMPORT(pid)     ""
set MAG_IMPORT(after)   ""
set MAG_IMPORT(cancel)  ""
set MAG_IMPORT(log)     ""
set MAG_IMPORT(work)    ""
set MAG_IMPORT(status)  ""
set MAG_IMPORT(stat_status) ""
set MAG_IMPORT(stat_pct) 0
set MAG_IMPORT(stat_msg) ""
set MAG_IMPORT(stat_dest) ""
set MAG_IMPORT(fetch_dead) 0
set MAG_IMPORT(magic_polls) 0
if {![info exists MAG_IMPORT(open_magic)]} { set MAG_IMPORT(open_magic) 1 }
if {![info exists MAG_IMPORT(view)]} { set MAG_IMPORT(view) cell }

# ── Small Tcl 8.0-safe helpers ───────────────────────────────────────────────

# Whitespace-split without regexp character classes.
proc mag_words {line} {
  set out {}
  foreach w [split $line " \t"] {
    if {$w != ""} { lappend out $w }
  }
  return $out
}

proc mag_is_int {s} {
  if {$s == ""} { return 0 }
  set i 0
  if {[string index $s 0] == "-"} { set i 1 }
  set n [string length $s]
  if {$i >= $n} { return 0 }
  for {} {$i < $n} {incr i} {
    if {[string first [string index $s $i] 0123456789] < 0} { return 0 }
  }
  return 1
}

proc mag_all_int {items} {
  foreach x $items {
    if {![mag_is_int $x]} { return 0 }
  }
  return 1
}

# ── Magic paint name → GDS layers (fallback Tcl dump) ────────────────────────
# Each record is {layer datatype grow_nm}. Magic contact / transistor tiles
# stand for several masks (ndiffc = diff + licon + li + nsdm), and implant
# layers are generated around diffusion, so one paint may emit several GDS
# layers; grow_nm approximates the implant enclosure. This is NOT the
# foundry cifoutput — use the Magic mag2gds method for tapeout.

proc mag_gds_map_sky130 {layer} {
  set n [string tolower $layer]
  set diff {65 20 0}
  set tap {65 44 0}
  set nsdm {93 44 125}
  set psdm {94 20 125}
  set hvi {75 20 180}
  set poly {66 20 0}
  set licon {66 44 0}
  set npc {95 20 100}
  set li {67 20 0}
  set mcon {67 44 0}
  set m1 {68 20 0}
  set v1 {68 44 0}
  set m2 {69 20 0}
  set v2 {69 44 0}
  set m3 {70 20 0}
  set v3 {70 44 0}
  set m4 {71 20 0}
  set v4 {71 44 0}
  set m5 {72 20 0}
  set capm {89 44 0}
  set cap2m {97 44 0}
  switch -exact -- $n {
    nwell { return {{64 20 0}} }
    pwell { return {{64 13 0}} }
    dnwell { return {{64 18 0}} }
    ndiff - ndif - ndiode { return [list $diff $nsdm] }
    pdiff - pdif - pdiode { return [list $diff $psdm] }
    mvndiff - mvndif { return [list $diff $nsdm $hvi] }
    mvpdiff - mvpdif { return [list $diff $psdm $hvi] }
    nsubdiff - nsd - ntap - nsubdiffusion { return [list $tap $nsdm] }
    psubdiff - psd - ptap - psubdiffusion { return [list $tap $psdm] }
    mvnsubdiff - mvnsd { return [list $tap $nsdm $hvi] }
    mvpsubdiff - mvpsd { return [list $tap $psdm $hvi] }
    nmos - ntransistor - nfet - nnmos - nnfet - scnmos { return [list $poly $diff $nsdm] }
    pmos - ptransistor - pfet - scpmos { return [list $poly $diff $psdm] }
    nmoslvt - nfetlvt { return [list $poly $diff $nsdm {125 44 180}] }
    pmoshvt - pfethvt { return [list $poly $diff $psdm {78 44 180}] }
    mvnmos - mvnfet - mvnnmos { return [list $poly $diff $nsdm $hvi] }
    mvpmos - mvpfet { return [list $poly $diff $psdm $hvi] }
    poly - polysilicon - p { return [list $poly] }
    polyres - ppolyres - npolyres - mrp1 - res0p35 - res1p41 - res2p85 - res5p73 - rpoly {
      return [list $poly {66 13 0} {86 20 200} $psdm]
    }
    polyshort - rmp { return [list $poly {66 15 0}] }
    diffres { return [list {65 13 0}] }
    xpolyres - xpolyresistor - res0p69 { return [list $poly {66 13 0} {79 20 200} $psdm] }
    ndiffc - ndc - ndiffcont - ndiffcontact { return [list $diff $licon $li $nsdm] }
    pdiffc - pdc - pdiffcont - pdiffcontact { return [list $diff $licon $li $psdm] }
    mvndiffc - mvndc - mvndiffcont { return [list $diff $licon $li $nsdm $hvi] }
    mvpdiffc - mvpdc - mvpdiffcont { return [list $diff $licon $li $psdm $hvi] }
    nsubdiffcont - nsc - nsubdiffc - ntapc - nsubdiffcontact { return [list $tap $licon $li $nsdm] }
    psubdiffcont - psc - psubdiffc - ptapc - psubdiffcontact { return [list $tap $licon $li $psdm] }
    mvnsubdiffcont - mvnsc - mvnsubdiffc { return [list $tap $licon $li $nsdm $hvi] }
    mvpsubdiffcont - mvpsc - mvpsubdiffc { return [list $tap $licon $li $psdm $hvi] }
    polycont - pc - polycontact - xpolycontact - xpc { return [list $poly $licon $li $npc] }
    licon1 - licon { return [list $licon] }
    locali - li1 - li - l1 { return [list $li] }
    viali - mcon - vial - l1c { return [list $mcon $li $m1] }
    metal1 - met1 - m1 { return [list $m1] }
    via - via1 - v1 - m1c { return [list $v1 $m1 $m2] }
    metal2 - met2 - m2 { return [list $m2] }
    via2 - v2 - m2c { return [list $v2 $m2 $m3] }
    metal3 - met3 - m3 { return [list $m3] }
    via3 - v3 - m3c { return [list $v3 $m3 $m4] }
    metal4 - met4 - m4 { return [list $m4] }
    via4 - v4 - m4c { return [list $v4 $m4 $m5] }
    metal5 - met5 - m5 { return [list $m5] }
    mimcap { return [list $capm $m3] }
    mimcapcontact - mimcc { return [list $v3 $capm $m3 $m4] }
    mimcap2 { return [list $cap2m $m4] }
    mimcap2contact - mimcc2 { return [list $v4 $cap2m $m4 $m5] }
    nsdm { return [list {93 44 0}] }
    psdm { return [list {94 20 0}] }
    npc { return [list {95 20 0}] }
    hvi { return [list {75 20 0}] }
    hvntm { return {{125 20 0}} }
    lvtn { return {{125 44 0}} }
    hvtp { return {{78 44 0}} }
    tunm { return {{80 20 0}} }
    rpm { return {{86 20 0}} }
    urpm { return {{79 20 0}} }
    pad { return {{76 20 0}} }
    bound - bbox - prboundary - areaid_sl { return {{235 4 0}} }
    text - comment { return {{83 44 0}} }
  }
  return {}
}

proc mag_gds_map_gf180 {layer} {
  set n [string tolower $layer]
  set comp {22 0 0}
  set nplus {32 0 160}
  set pplus {31 0 160}
  set dg {55 0 240}
  set poly {30 0 0}
  set ct {33 0 0}
  set m1 {34 0 0}
  set v1 {35 0 0}
  set m2 {36 0 0}
  set v2 {38 0 0}
  set m3 {42 0 0}
  set v3 {40 0 0}
  set m4 {46 0 0}
  set v4 {41 0 0}
  set m5 {81 0 0}
  switch -exact -- $n {
    nwell { return {{21 0 0}} }
    dnwell { return {{12 0 0}} }
    pwell { return {} }
    comp - diff - ndiff - ndif { return [list $comp $nplus] }
    pdiff - pdif { return [list $comp $pplus] }
    nsd - ntap - nsubdiff { return [list $comp $nplus] }
    psd - ptap - psubdiff { return [list $comp $pplus] }
    mvndiff - mvnsd { return [list $comp $nplus $dg] }
    mvpdiff - mvpsd { return [list $comp $pplus $dg] }
    nmos - nfet - ntransistor { return [list $poly $comp $nplus] }
    pmos - pfet - ptransistor { return [list $poly $comp $pplus] }
    mvnmos - mvnfet { return [list $poly $comp $nplus $dg] }
    mvpmos - mvpfet { return [list $poly $comp $pplus $dg] }
    poly - poly2 - polysilicon { return [list $poly] }
    ndiffc - ndc - nsc - nsubc - nsubdiffcont { return [list $comp $ct $m1 $nplus] }
    pdiffc - pdc - psc - psubc - psubdiffcont { return [list $comp $ct $m1 $pplus] }
    mvndiffc - mvndc - mvnsc { return [list $comp $ct $m1 $nplus $dg] }
    mvpdiffc - mvpdc - mvpsc { return [list $comp $ct $m1 $pplus $dg] }
    polycont - pc - polycontact { return [list $poly $ct $m1] }
    contact - licon1 { return [list $ct] }
    metal1 - met1 - m1 { return [list $m1] }
    via1 - via - v1 { return [list $v1 $m1 $m2] }
    metal2 - met2 - m2 { return [list $m2] }
    via2 - v2 { return [list $v2 $m2 $m3] }
    metal3 - met3 - m3 { return [list $m3] }
    via3 - v3 { return [list $v3 $m3 $m4] }
    metal4 - met4 - m4 { return [list $m4] }
    via4 - v4 { return [list $v4 $m4 $m5] }
    metal5 - met5 - m5 - metaltop - mtop { return [list $m5] }
    nplus { return {{32 0 0}} }
    pplus { return {{31 0 0}} }
    dualgate - dg { return {{55 0 0}} }
    sab { return {{49 0 0}} }
    esd { return {{24 0 0}} }
    bound - bbox - pr_bndry - prboundary { return {{63 0 0}} }
  }
  return {}
}

proc mag_gds_map_sg13g2 {layer} {
  set n [string tolower $layer]
  set act {1 0 0}
  set psd {14 0 180}
  set poly {5 0 0}
  set ct {6 0 0}
  set m1 {8 0 0}
  set v1 {19 0 0}
  set m2 {10 0 0}
  set v2 {29 0 0}
  set m3 {30 0 0}
  set v3 {49 0 0}
  set m4 {50 0 0}
  set v4 {66 0 0}
  set m5 {67 0 0}
  set tv1 {125 0 0}
  set tm1 {126 0 0}
  set tv2 {133 0 0}
  set tm2 {134 0 0}
  switch -exact -- $n {
    activ - diff - ndiff - ndif - nsd - ntap { return [list $act] }
    pdiff - pdif - psd - ptap { return [list $act $psd] }
    nmos - nfet { return [list $poly $act] }
    pmos - pfet { return [list $poly $act $psd] }
    gatpoly - poly { return [list $poly] }
    nwell { return {{31 0 0}} }
    pwell { return {} }
    ndiffc - ndc - nsc { return [list $act $ct $m1] }
    pdiffc - pdc - psc { return [list $act $ct $m1 $psd] }
    polycont - pc { return [list $poly $ct $m1] }
    cont - contact { return [list $ct] }
    metal1 - met1 - m1 { return [list $m1] }
    via1 - v1 { return [list $v1 $m1 $m2] }
    metal2 - met2 - m2 { return [list $m2] }
    via2 - v2 { return [list $v2 $m2 $m3] }
    metal3 - met3 - m3 { return [list $m3] }
    via3 - v3 { return [list $v3 $m3 $m4] }
    metal4 - met4 - m4 { return [list $m4] }
    via4 - v4 { return [list $v4 $m4 $m5] }
    metal5 - met5 - m5 { return [list $m5] }
    topvia1 - tv1 { return [list $tv1 $m5 $tm1] }
    topmetal1 - tm1 - metal6 - m6 { return [list $tm1] }
    topvia2 - tv2 { return [list $tv2 $tm1 $tm2] }
    topmetal2 - tm2 - metal7 - m7 { return [list $tm2] }
    mim { return {{36 0 0}} }
    thickgateox - hvi { return {{44 0 0}} }
    salblock - sab { return {{28 0 0}} }
    bound - bbox - prboundary { return {{189 4 0}} }
    text - comment { return {{63 0 0}} }
  }
  return {}
}

# List of {layer datatype grow_nm}; unknown paint gets a private layer ≥ 200.
proc mag_gds_map {family layer} {
  global MAG_GDS_UNKNOWN
  set recs {}
  if {$family == "gf180mcu"} {
    set recs [mag_gds_map_gf180 $layer]
  } elseif {$family == "sg13g2"} {
    set recs [mag_gds_map_sg13g2 $layer]
  } else {
    set recs [mag_gds_map_sky130 $layer]
  }
  if {[llength $recs]} { return $recs }
  if {![info exists MAG_GDS_UNKNOWN($layer)]} {
    set MAG_GDS_UNKNOWN($layer) [expr {200 + [array size MAG_GDS_UNKNOWN]}]
    mag_log "Unmapped Magic layer '$layer' -> GDS $MAG_GDS_UNKNOWN($layer)/0"
  }
  return [list [list $MAG_GDS_UNKNOWN($layer) 0 0]]
}

# GDS text datatype used for labels on a paint layer (same layer number).
proc mag_text_dt {family} {
  if {$family == "gf180mcu"} { return 10 }
  if {$family == "sg13g2"} { return 25 }
  return 5
}

proc mag_family_from_tech {tech} {
  set t [string tolower $tech]
  if {[string match *gf180* $t]} { return gf180mcu }
  if {[string match *sg13* $t] || [string match *ihp* $t]} { return sg13g2 }
  if {[string match *sky130* $t] || [string match *skywater* $t]} { return sky130A }
  return sky130A
}

proc mag_pdk_dir {family} {
  set root /mmi-pdks
  if {[info commands pdk_root] != ""} { set root [pdk_root] }
  set names sky130A
  if {$family == "gf180mcu"} { set names {gf180mcuD gf180mcuC gf180mcu} }
  if {$family == "sg13g2"} { set names {ihp-sg13g2 sg13g2} }
  foreach n $names {
    if {[file isdirectory [file join $root $n libs.tech magic]]} {
      return [file join $root $n]
    }
  }
  return ""
}

# Half-nanometres per Magic lambda. Defaults match open_pdks
# (sky130 and IHP 10 nm, gf180mcu 50 nm). A "scalefactor" line in the
# installed Magic tech replaces the default. The result is an integer;
# a scalefactor that is not a whole number of half-nanometres is ignored.
proc mag_lambda_hnm {family} {
  global MAG_IMPORT
  if {[info exists MAG_IMPORT(lambda_hnm,$family)]} {
    return $MAG_IMPORT(lambda_hnm,$family)
  }
  set hnm 20
  if {$family == "gf180mcu"} { set hnm 100 }
  set pdk [mag_pdk_dir $family]
  if {$pdk != ""} {
    set techs {}
    catch {set techs [lsort [glob -nocomplain [file join $pdk libs.tech magic *.tech]]]}
    foreach t $techs {
      if {![file isfile $t]} continue
      if {[catch {set fh [open $t r]}]} continue
      set in_out 0
      set found ""
      while {[gets $fh line] >= 0} {
        set toks [mag_words $line]
        set c [lindex $toks 0]
        if {$c == "cifoutput"} { set in_out 1; continue }
        if {$in_out && ($c == "cifinput" || $c == "drc" || $c == "extract")} break
        if {$in_out && $c == "scalefactor" && [llength $toks] >= 2} {
          set raw [lindex $toks 1]
          set unit [string tolower [lindex $toks 2]]
          if {[string match nano* $unit]} {
            set found [mag_exact_nm_hnm $raw]
          } elseif {$unit == "" || [string match centi* $unit]} {
            # Centimicrons: 1 centimicron = 10 nm = 20 hnm.
            set found [mag_exact_dec_hnm $raw 20]
          } elseif {[string match ang* $unit]} {
            # 1 angstrom = 0.1 nm = 0.2 hnm. Only exact values are kept.
            set found [mag_exact_dec_hnm $raw 1]
            if {$found != "" && [expr {$found % 5}] != 0} { set found "" }
            if {$found != ""} { set found [expr {$found / 5}] }
          }
          break
        }
      }
      close $fh
      if {$found != "" && $found > 0} {
        set hnm $found
        break
      }
    }
  }
  set MAG_IMPORT(lambda_hnm,$family) $hnm
  set MAG_IMPORT(scale,$family) [expr {double($hnm) / 2.0}]
  return $hnm
}

# Nanometers per Magic lambda. Kept for log lines; the converter itself
# uses mag_lambda_hnm and integer arithmetic.
proc mag_scalefactor_nm {family} {
  return [expr {double([mag_lambda_hnm $family]) / 2.0}]
}

# Nanometers per .mag file unit: lambda * magscale n/d.
proc mag_nm_per_unit {family n d} {
  if {$d == 0} { set d 1 }
  return [expr {[mag_scalefactor_nm $family] * double($n) / double($d)}]
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
  if {[info commands pdk_root] != ""} {
    lappend cands [file join [pdk_root] samples caravel_analog_por]
  }
  lappend cands /mmi-pdks/samples/caravel_analog_por
  if {[info exists env(MMI_PDK_DIR)] && $env(MMI_PDK_DIR) != ""} {
    lappend cands [file join $env(MMI_PDK_DIR) samples caravel_analog_por]
  }
  if {[info exists env(MMI_LOCAL)] && $env(MMI_LOCAL) != ""} {
    lappend cands [file join $env(MMI_LOCAL) max pdk samples caravel_analog_por]
  }
  if {[info exists MMI_TOOLS] && $MMI_TOOLS != ""} {
    lappend cands [file join $MMI_TOOLS ../mmi_local/max/pdk/samples/caravel_analog_por]
  }
  lappend cands /mmi-home/cad/mmi_local/max/pdk/samples/caravel_analog_por
  lappend cands /mmi-pdk-live/samples/caravel_analog_por
  lappend cands /mmi-bundle/samples/caravel_analog_por
  foreach d $cands {
    set d [_mmi_file_normalize $d]
    if {[file isdirectory $d] && \
        ([file exists [file join $d example_por.mag]] || \
         [file exists [file join $d simple_por.mag]])} {
      return $d
    }
  }
  return ""
}

proc mag_sample_dest {} {
  # Writable place for a downloaded Caravel Mag sample.
  set cands {}
  if {[info commands pdk_root] != ""} {
    lappend cands [file join [pdk_root] samples caravel_analog_por]
  }
  lappend cands /mmi-pdks/samples/caravel_analog_por
  lappend cands /mmi-home/cad/mmi_local/max/pdk/samples/caravel_analog_por
  foreach d $cands {
    catch {file mkdir $d}
    if {[file isdirectory $d] && [file writable $d]} { return $d }
  }
  return [lindex $cands end]
}

# Writable place for the downloaded Caravel harness GDS (not the POR sample).
proc mag_die_dest {} {
  set cands {}
  if {[info commands pdk_root] != ""} {
    lappend cands [file join [pdk_root] samples caravel_die]
  }
  lappend cands /mmi-pdks/samples/caravel_die
  lappend cands /mmi-home/cad/mmi_local/max/pdk/samples/caravel_die
  foreach d $cands {
    catch {file mkdir $d}
    if {[file isdirectory $d] && [file writable $d]} { return $d }
  }
  return [lindex $cands end]
}

# Writable place for harness .mag + the example user design.
proc mag_harness_dest {} {
  set cands {}
  if {[info commands pdk_root] != ""} {
    lappend cands [file join [pdk_root] samples caravel_harness_mag]
  }
  lappend cands /mmi-pdks/samples/caravel_harness_mag
  lappend cands /mmi-home/cad/mmi_local/max/pdk/samples/caravel_harness_mag
  foreach d $cands {
    catch {file mkdir $d}
    if {[file isdirectory $d] && [file writable $d]} { return $d }
  }
  return [lindex $cands end]
}

proc mag_import_is_chip {} {
  global MAG_IMPORT
  if {![info exists MAG_IMPORT(view)]} { return 0 }
  if {$MAG_IMPORT(view) == "chip"} { return 1 }
  return 0
}

# A fresh directory for this conversion. Reusing one folder overwrote the
# previous .max. Prefer a folder next to the Magic design, then writable
# fallbacks. Bundled samples live on read-only mounts.
proc mag_output_dir {dir top} {
  set leaf $top
  if {$leaf == "" || $leaf == "auto"} { set leaf [file tail $dir] }
  if {$leaf == ""} { set leaf design }
  set stamp [clock seconds]
  catch {set stamp [clock format [clock seconds] -format {%Y%m%d-%H%M%S}]}
  set name "$leaf-$stamp"
  set parents {}
  lappend parents [file join $dir max_out]
  set base [file tail $dir]
  if {$base == ""} { set base design }
  if {[info commands pdk_root] != ""} {
    lappend parents [file join [pdk_root] mag_import $base]
  }
  lappend parents [file join /mmi-pdks mag_import $base]
  lappend parents [file join /mmi-home/cad/mmi_local/max/mag_import $base]
  lappend parents [file join /tmp mag_import_out $base]
  foreach parent $parents {
    set d [file join $parent $name]
    catch {file mkdir $d}
    if {![file isdirectory $d] || ![file writable $d]} continue
    set probe [file join $d .mag_import_write_test]
    if {[catch {
      set fh [open $probe w]
      puts $fh ok
      close $fh
      file delete $probe
    }]} continue
    return $d
  }
  set d [file join /tmp mag_import_out $name]
  catch {file mkdir $d}
  return $d
}

# Two hvi rectangles that should be one mask often land a few database
# units apart (the example_por errors are 0.005 um and 0.12 um). A gap
# smaller than the spacing rule is painted shut so spacing is not flagged.
proc mag_heal_spacing {layer gap} {
  if {$gap <= 0} { return 0 }
  if {[catch {set boxes [db_search_l paint $layer]}]} { return 0 }
  set n [llength $boxes]
  if {$n < 2} { return 0 }
  set bridged 0
  set i 0
  foreach a $boxes {
    incr i
    if {[catch {
      struct max_paint pa $a
      set ax1 ${pa.x1}
      set ay1 ${pa.y1}
      set ax2 ${pa.x2}
      set ay2 ${pa.y2}
    }]} continue
    set j 0
    foreach b $boxes {
      incr j
      if {$j <= $i} continue
      if {[catch {
        struct max_paint pb $b
        set bx1 ${pb.x1}
        set by1 ${pb.y1}
        set bx2 ${pb.x2}
        set by2 ${pb.y2}
      }]} continue
      set oy1 $ay1
      if {$by1 > $oy1} { set oy1 $by1 }
      set oy2 $ay2
      if {$by2 < $oy2} { set oy2 $by2 }
      if {$oy2 > $oy1} {
        if {$ax2 < $bx1} {
          set g [expr {$bx1 - $ax2}]
          if {$g > 0 && $g < $gap} {
            lay_box $ax2 $oy1 $bx1 $oy2
            :paint $layer
            incr bridged
          }
        } elseif {$bx2 < $ax1} {
          set g [expr {$ax1 - $bx2}]
          if {$g > 0 && $g < $gap} {
            lay_box $bx2 $oy1 $ax1 $oy2
            :paint $layer
            incr bridged
          }
        }
      }
      set ox1 $ax1
      if {$bx1 > $ox1} { set ox1 $bx1 }
      set ox2 $ax2
      if {$bx2 < $ox2} { set ox2 $bx2 }
      if {$ox2 > $ox1} {
        if {$ay2 < $by1} {
          set g [expr {$by1 - $ay2}]
          if {$g > 0 && $g < $gap} {
            lay_box $ox1 $ay2 $ox2 $by1
            :paint $layer
            incr bridged
          }
        } elseif {$by2 < $ay1} {
          set g [expr {$ay1 - $by2}]
          if {$g > 0 && $g < $gap} {
            lay_box $ox1 $by2 $ox2 $ay1
            :paint $layer
            incr bridged
          }
        }
      }
    }
  }
  if {$bridged > 0} {
    catch {:drc catchup}
  }
  return $bridged
}

# MAX paints a spacing error on the hvi that is too close, not in the
# opening. example_por's 0.12 um and 0.005 um marks sit on the upper
# implant; the opening is the space below them, between hvi in the
# pfet cells and hvi in the nfet cells. Paint that opening in the
# parent so the flattened check sees one shape.
proc mag_heal_hvi_flat {{gap 0.7}} {
  set cell ""
  catch {set cell [lay_editcell]}
  if {$cell == ""} { return 0 }
  set boxes ""
  if {[catch {set boxes [db_search_l paint -cell $cell -any_cell hvi]} err]} {
    mag_log "hvi heal: flattened search failed: $err"
    return 0
  }
  set rects {}
  foreach e $boxes {
    set x1 [lindex $e 1]
    set y1 [lindex $e 2]
    set x2 [lindex $e 3]
    set y2 [lindex $e 4]
    if {$x1 == "" || $y1 == "" || $x2 == "" || $y2 == ""} continue
    if {$x1 > $x2} { set t $x1; set x1 $x2; set x2 $t }
    if {$y1 > $y2} { set t $y1; set y1 $y2; set y2 $t }
    lappend rects [list $x1 $y1 $x2 $y2]
  }
  set nrect [llength $rects]
  if {$nrect > 6000} {
    mag_log "hvi heal: $nrect flattened rectangles, skipped (too many to pair)"
    return 0
  }
  set bridged 0
  set pass 0
  while {$pass < 4} {
    incr pass
    set extra {}
    set n [llength $rects]
    for {set i 0} {$i < $n} {incr i} {
      set a [lindex $rects $i]
      set ax1 [lindex $a 0]
      set ay1 [lindex $a 1]
      set ax2 [lindex $a 2]
      set ay2 [lindex $a 3]
      for {set j [expr {$i + 1}]} {$j < $n} {incr j} {
        set b [lindex $rects $j]
        set bx1 [lindex $b 0]
        set by1 [lindex $b 1]
        set bx2 [lindex $b 2]
        set by2 [lindex $b 3]
        if {[expr {$ax2 + $gap}] <= $bx1} continue
        if {[expr {$bx2 + $gap}] <= $ax1} continue
        if {[expr {$ay2 + $gap}] <= $by1} continue
        if {[expr {$by2 + $gap}] <= $ay1} continue
        set oy1 $ay1
        if {$by1 > $oy1} { set oy1 $by1 }
        set oy2 $ay2
        if {$by2 < $oy2} { set oy2 $by2 }
        if {$oy2 > $oy1} {
          if {$ax2 < $bx1} {
            set g [expr {$bx1 - $ax2}]
            if {$g > 0.00025 && $g < $gap} {
              mag_exact_note_bridge extra $rects $ax2 $oy1 $bx1 $oy2
            }
          } elseif {$bx2 < $ax1} {
            set g [expr {$ax1 - $bx2}]
            if {$g > 0.00025 && $g < $gap} {
              mag_exact_note_bridge extra $rects $bx2 $oy1 $ax1 $oy2
            }
          }
        }
        set ox1 $ax1
        if {$bx1 > $ox1} { set ox1 $bx1 }
        set ox2 $ax2
        if {$bx2 < $ox2} { set ox2 $bx2 }
        if {$ox2 > $ox1} {
          if {$ay2 < $by1} {
            set g [expr {$by1 - $ay2}]
            if {$g > 0.00025 && $g < $gap} {
              mag_exact_note_bridge extra $rects $ox1 $ay2 $ox2 $by1
            }
          } elseif {$by2 < $ay1} {
            set g [expr {$ay1 - $by2}]
            if {$g > 0.00025 && $g < $gap} {
              mag_exact_note_bridge extra $rects $ox1 $by2 $ox2 $ay1
            }
          }
        }
      }
    }
    if {[llength $extra] == 0} break
    foreach r $extra {
      set x1 [lindex $r 0]
      set y1 [lindex $r 1]
      set x2 [lindex $r 2]
      set y2 [lindex $r 3]
      if {[info commands db_paint] != ""} {
        db_paint -no_notify -cell $cell hvi $x1 $y1 $x2 $y2
      } else {
        lay_box $x1 $y1 $x2 $y2
        :paint hvi
      }
      lappend rects $r
      incr bridged
    }
  }
  mag_log "hvi heal: $nrect flattened rectangles, joined $bridged gaps under $gap um"
  return $bridged
}

# Join hvi that is closer than 0.7 um across the hierarchy, then save.
proc mag_close_hvi_gaps {} {
  set n 0
  if {[catch {set n [mag_heal_hvi_flat 0.7]} err]} {
    mag_log "hvi heal failed: $err"
    set n 0
  }
  if {$n > 0} {
    catch {:drc catchup}
    catch {cell_save}
  }
  return $n
}

# Reread every saved cell. cell_load leaves a cell that is already in
# memory untouched, so a later cell_save would put the old labels back.
proc mag_flush_tree {dir top} {
  set files {}
  catch {set files [glob -nocomplain [file join $dir *.max]]}
  foreach f $files {
    set name [file rootname [file tail $f]]
    if {$name == $top} continue
    catch {:flush $name}
  }
  if {$top != ""} {
    catch {:flush $top}
  }
}

# Save the converted cell as outdir/top.max and make that the open cell.
proc mag_save_open {outdir top} {
  if {$top == "" || $outdir == ""} { return }
  catch {file mkdir $outdir}
  catch {cell_path_add $outdir}
  catch {cd $outdir}
  set dest [file join $outdir ${top}.max]
  if {[info commands cell_in_memory] != "" && [cell_in_memory $top]} {
    catch {db_cell_rename $top $top $dest}
  }
  catch {mag_heal_spacing hvi 0.7}
  catch {cell_save_tree 0}
  catch {cell_save}
  catch {cell_load $top $outdir}
  catch {view_cell}
}

# Map FHS bind paths to the host/VM folder (MMI_CAD_ROOT/data/...).
proc mag_host_path {path} {
  global env
  set path [_mmi_file_normalize $path]
  set root ""
  if {[info exists env(MMI_CAD_ROOT)] && $env(MMI_CAD_ROOT) != ""} {
    set root $env(MMI_CAD_ROOT)
  }
  if {$root == ""} { return $path }
  foreach map {
    {/mmi-pdks data/pdks}
    {/mmi-home data/home}
    {/mmi-pdk-live pdk}
  } {
    set pre [lindex $map 0]
    set sub [lindex $map 1]
    set n [string length $pre]
    if {[string range $path 0 [expr {$n - 1}]] != $pre} continue
    set rest [string range $path $n end]
    if {[string match /* $rest]} {
      set rest [string range $rest 1 end]
    }
    if {$rest == ""} {
      return [file join $root $sub]
    }
    return [file join $root $sub $rest]
  }
  return $path
}

proc mag_list_max_files {dir} {
  set files {}
  catch {set files [glob -nocomplain [file join $dir *.max]]}
  set names {}
  foreach f $files {
    lappend names [file tail $f]
  }
  return [lsort $names]
}

proc mag_storage_report {outdir top} {
  set outdir [_mmi_file_normalize $outdir]
  set host [mag_host_path $outdir]
  set names [mag_list_max_files $outdir]
  set n [llength $names]
  set lines {}
  lappend lines "File storage (converted .max files):"
  lappend lines "  $outdir"
  if {$host != $outdir} {
    lappend lines "On the VM / host disk:"
    lappend lines "  $host"
  }
  lappend lines ""
  lappend lines "Top cell .max:"
  lappend lines "  [file join $outdir ${top}.max]"
  if {[file exists [file join $outdir ${top}.gds]]} {
    lappend lines "GDS:"
    lappend lines "  [file join $outdir ${top}.gds]"
  }
  if {$n > 0} {
    lappend lines ""
    lappend lines ".max files in that folder ($n):"
    set i 0
    foreach nm $names {
      incr i
      if {$i > 16} {
        lappend lines "  ... and [expr {$n - 16}] more"
        break
      }
      lappend lines "  $nm"
    }
  } else {
    lappend lines ""
    lappend lines "(MAX is still writing .max into that folder.)"
  }
  lappend lines ""
  lappend lines "A WHERE.txt file in that folder repeats these paths."
  lappend lines "Click Show to open the folder in the file manager."
  return [join $lines \n]
}

proc mag_write_where {outdir top} {
  set outdir [_mmi_file_normalize $outdir]
  set host [mag_host_path $outdir]
  set f [file join $outdir WHERE.txt]
  if {[catch {set fh [open $f w]}]} { return }
  puts $fh "MAX conversion output"
  puts $fh "CAD folder:  $outdir"
  if {$host != $outdir} {
    puts $fh "Host folder: $host"
  }
  puts $fh "Top cell:    ${top}.max"
  puts $fh "GDS:         ${top}.gds"
  puts $fh ""
  set names [mag_list_max_files $outdir]
  if {[llength $names]} {
    puts $fh ".max files:"
    foreach nm $names {
      puts $fh "  $nm"
    }
  }
  close $fh
}

proc mag_open_storage_folder {{dir ""}} {
  global MAG_IMPORT
  if {$dir == ""} {
    if {[info exists MAG_IMPORT(outdir)]} { set dir $MAG_IMPORT(outdir) }
  }
  if {$dir == "" || ![file isdirectory $dir]} { return }
  set dir [_mmi_file_normalize $dir]
  # A folder is not a document. xdg-open, with no file manager installed,
  # walks every web browser and prints a page of "command not found".
  if {[info commands auto_execok] == ""} { return }
  foreach bin {nautilus thunar pcmanfm nemo caja explorer.exe} {
    if {[auto_execok $bin] == ""} continue
    if {![catch {exec $bin $dir &}]} { return }
  }
}

proc mag_finish_storage {outdir top} {
  global MAG_IMPORT
  set MAG_IMPORT(outdir) $outdir
  mag_write_where $outdir $top
  mag_open_storage_folder $outdir
  return [mag_storage_report $outdir $top]
}

proc mag_fetch_script {} {
  global env
  set cands {}
  lappend cands /mmi-pdk-live/fetch_caravel_mag.sh
  if {[info exists env(MMI_LOCAL)] && $env(MMI_LOCAL) != ""} {
    lappend cands [file join $env(MMI_LOCAL) max pdk fetch_caravel_mag.sh]
  }
  if {[info exists env(MMI_PDK_DIR)] && $env(MMI_PDK_DIR) != ""} {
    lappend cands [file join $env(MMI_PDK_DIR) fetch_caravel_mag.sh]
  }
  lappend cands /mmi-bundle/fetch_caravel_mag.sh
  foreach f $cands {
    if {[file readable $f]} { return $f }
  }
  return ""
}

proc mag_which {names} {
  global env
  set path ""
  if {[info exists env(PATH)]} { set path $env(PATH) }
  if {[info exists env(MMI_TOOLS)] && $env(MMI_TOOLS) != ""} {
    set path "[file join $env(MMI_TOOLS) bin]:$path"
  }
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

proc mag_import_tell {msg {opt ""}} {
  set title "Import Magic Design"
  set x 80
  set y 80
  catch {set x [winfo pointerx .]}
  catch {set y [winfo pointery .]}
  set buttons OK
  if {$opt == "-copy" || $opt == "copy"} {
    set buttons {OK Copy Show}
  }
  while {1} {
    set ret OK
    if {[catch {set ret [prop_dialog -title $title -buttons $buttons \
        -width 78 -height 22 -x $x -y $y $msg]}]} {
      if {[catch {set ret [tk_dialog .magmsg $title $msg {} 0 OK Copy Show]}]} {
        catch {puts $msg}
        return
      }
      if {$ret == 1} {
        set ret Copy
      } elseif {$ret == 2} {
        set ret Show
      } else {
        set ret OK
      }
    }
    if {$ret == "Copy"} {
      if {[info commands pdk_import_copy_text] != ""} {
        pdk_import_copy_text $msg
      } else {
        catch {clipboard clear}
        catch {clipboard append -- $msg}
      }
      continue
    }
    if {$ret == "Show"} {
      mag_open_storage_folder
      continue
    }
    return
  }
}

proc mag_list_max_techs {} {
  global env MMI_TOOLS MMI_LOCAL MN_TECH PDK_PRESET
  set roots {}
  # Prefer shared PDK_ROOT and private/local overlays (imported PDKs).
  if {[info commands pdk_root] != ""} {
    lappend roots [file join [pdk_root] max tech]
  }
  lappend roots /mmi-pdks/max/tech
  set home ""
  if {[info exists env(HOME)] && $env(HOME) != ""} { set home $env(HOME) }
  if {$home == ""} { set home /mmi-home }
  lappend roots [file join $home mmi_private max tech]
  if {[info exists env(MMI_LOCAL)] && $env(MMI_LOCAL) != ""} {
    lappend roots [file join $env(MMI_LOCAL) max tech]
  } elseif {[info exists MMI_LOCAL] && $MMI_LOCAL != ""} {
    lappend roots [file join $MMI_LOCAL max tech]
  } else {
    lappend roots [file join $home cad mmi_local max tech]
  }
  if {[info exists MMI_TOOLS] && $MMI_TOOLS != ""} {
    lappend roots [file join $MMI_TOOLS max tech]
  }
  lappend roots /mmi-vendor/mmi/max/tech

  set names {}
  foreach root $roots {
    if {![file isdirectory $root]} { continue }
    # Tcl 8.0 has no glob -directory / -types — use a path pattern.
    set kids {}
    catch {set kids [glob -nocomplain [file join $root *]]}
    foreach d $kids {
      if {![file isdirectory $d]} continue
      set bn [file tail $d]
      if {$bn == "." || $bn == ".." || $bn == "tech_target" || \
          $bn == "template"} continue
      # Only list techs MAX can actually load (valid .tech27).
      set ok 0
      set t27 [file join $d ${bn}.tech27]
      if {[info commands pdk_tech27_ok] != ""} {
        if {[pdk_tech27_ok $t27]} { set ok 1 }
      } elseif {[file readable $t27] && [file size $t27] > 0} {
        set ok 1
      } elseif {[file readable [file join $d ${bn}.tech]] && \
          [file size [file join $d ${bn}.tech]] > 0} {
        set ok 1
      }
      if {!$ok} continue
      if {[lsearch -exact $names $bn] < 0} {
        lappend names $bn
      }
    }
  }

  # Also pick up imported presets via pdk_find_tech27 when available.
  if {[info commands pdk_find_tech27] != ""} {
    foreach c {sky130A gf180mcu sg13g2} {
      set t $c
      if {[info exists PDK_PRESET($c,tech)]} {
        set t $PDK_PRESET($c,tech)
      }
      if {$t == ""} continue
      if {[pdk_find_tech27 $t] != "" && [lsearch -exact $names $t] < 0} {
        lappend names $t
      }
    }
  }

  if {[info exists MN_TECH] && $MN_TECH != "" && [lsearch -exact $names $MN_TECH] < 0} {
    lappend names $MN_TECH
  }

  # Built-in vendor techs as last resort so the radio is never empty.
  if {![llength $names]} {
    set names {mmi18 mmi25}
  }
  # Tcl 8.0 has no lsort -dictionary.
  return [lsort $names]
}

proc mag_skip_layer {layer} {
  set n [string tolower $layer]
  switch -exact -- $n {
    labels - properties - end - error_p - error - checkpaint -
    comment - authors - plots - watch - space { return 1 }
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

# 8-byte GDS real: sign, 7-bit excess-64 base-16 exponent, 56-bit mantissa.
# Mantissa bytes are peeled off one at a time (Tcl 8.0 has no wide()).
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
  set b0 [expr {($sign * 128) + (($exp + 64) & 127)}]
  set hex [format %02x $b0]
  # 56-bit mantissa as 24 + 24 + 8 bit chunks: each fits a 32-bit int and the
  # float error stays below one unit of the last byte (peeling single bytes
  # multiplies the error by 256 per step and drifts).
  set v [expr {$x * 16777216.0}]
  set hi [expr {int($v)}]
  if {$hi > 16777215} { set hi 16777215 }
  set v [expr {($v - $hi) * 16777216.0}]
  set mid [expr {int($v)}]
  if {$mid > 16777215} { set mid 16777215 }
  if {$mid < 0} { set mid 0 }
  set v [expr {($v - $mid) * 256.0}]
  set lo [expr {int($v)}]
  if {$lo > 255} { set lo 255 }
  if {$lo < 0} { set lo 0 }
  append hex [format %06x $hi] [format %06x $mid] [format %02x $lo]
  return $hex
}

proc mag_gds_ascii {s} {
  set hex ""
  set n [string length $s]
  for {set i 0} {$i < $n} {incr i} {
    scan [string index $s $i] %c c
    append hex [format %02x [expr {$c & 255}]]
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

proc mag_gds_dates {} {
  set now [clock seconds]
  set y [clock format $now -format %Y]
  set mo [clock format $now -format %m]
  set d [clock format $now -format %d]
  set h [clock format $now -format %H]
  set mi [clock format $now -format %M]
  set s [clock format $now -format %S]
  # %m etc. are zero padded; "08" would be an octal error in expr.
  set vals {}
  foreach v [list $y $mo $d $h $mi $s] {
    set v [string trimleft $v 0]
    if {$v == ""} { set v 0 }
    lappend vals $v
  }
  set out ""
  foreach _ {1 2} {
    foreach v $vals { append out [mag_gds_i16 $v] }
  }
  return $out
}

proc mag_gds_header {fh libname} {
  mag_gds_rec $fh 0 2 [mag_gds_i16 600]
  mag_gds_rec $fh 1 2 [mag_gds_dates]
  mag_gds_rec $fh 2 6 [mag_gds_ascii $libname]
  # 1 database unit = 0.001 user units (um) = 1e-9 m
  mag_gds_rec $fh 3 5 [mag_gds_real8 0.001][mag_gds_real8 1.0e-9]
}

proc mag_gds_endlib {fh} {
  mag_gds_rec $fh 4 0 ""
}

proc mag_gds_bgnstr {fh name} {
  mag_gds_rec $fh 5 2 [mag_gds_dates]
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

# Magic manhattan transform (a b c d e f): x' = a x + b y + c, y' = d x + e y + f
# → GDS (reflect-about-x-first, angle_deg)
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
  global MAG_IMPORT
  set src 0
  set dst 0
  if {[info exists MAG_IMPORT(file_hnm)]} { set src $MAG_IMPORT(file_hnm) }
  if {[info exists MAG_IMPORT(out_hnm)]} { set dst $MAG_IMPORT(out_hnm) }
  if {$src > 0 && $dst > 0} {
    set gx [mag_exact_coord $x $src $dst]
    set gy [mag_exact_coord $y $src $dst]
    if {$gx == "" || $gy == ""} {
      error "coordinate $x $y is not a whole number of [mag_exact_hnm_text $dst] (file unit [mag_exact_hnm_text $src])"
    }
    return [list $gx $gy]
  }
  set gx [expr {round(double($x) * $scale)}]
  set gy [expr {round(double($y) * $scale)}]
  return [list $gx $gy]
}

# True when a GDS file holds at least one structure (BGNSTR record).
proc mag_gds_has_structs {path} {
  if {![file exists $path]} { return 0 }
  if {[file size $path] < 100} { return 0 }
  # Walk the record chain with binary scan (NUL-safe in Tcl 8.0); the first
  # BGNSTR follows the header within a few records, so 64 KiB is plenty.
  set found 0
  set rc [catch {
    set fh [open $path r]
    fconfigure $fh -translation binary
    set data [read $fh 65536]
    close $fh
    set n [string length $data]
    set off 0
    set guard 0
    while {$off + 4 <= $n && $guard < 20000} {
      incr guard
      if {[binary scan $data "@${off}Scc" len type dt] != 3} break
      if {$len < 4} break
      if {$type == 5} { set found 1; break }
      set off [expr {$off + $len}]
    }
  }]
  if {$rc} { return 1 }   ;# could not inspect: do not block the import
  return $found
}

# ── .mag parser ──────────────────────────────────────────────────────────────
#
# magic / tech T / magscale n d / timestamp
# << layer >> then rect x1 y1 x2 y2 | tri x1 y1 x2 y2 dir(nw|ne|sw|se)
# << labels >> rlabel LAYER [s] x1 y1 x2 y2 pos TEXT
#              flabel LAYER [s] x1 y1 x2 y2 pos FONT SIZE ROT DX DY TEXT
#              port N dirs ...
# use CELL [INST [PATH]] / timestamp / transform a b c d e f
#     array xlo xhi xsep ylo yhi ysep / box x1 y1 x2 y2
# << end >>

proc mag_parse_file {path} {
  global MAGDB
  set name [file rootname [file tail $path]]
  if {[catch {set fh [open $path r]} err]} {
    mag_log "Cannot read $path: $err"
    return ""
  }
  set MAGDB($name,n) 1
  set MAGDB($name,d) 1
  set MAGDB($name,tech) ""
  set MAGDB($name,layers) {}
  set MAGDB($name,uses) {}
  set MAGDB($name,labels) {}
  set MAGDB($name,bbox) ""
  set MAGDB($name,file) $path
  set layer ""
  set section paint
  set use ""
  while {[gets $fh raw] >= 0} {
    set line [string trim $raw]
    if {$line == "" || [string index $line 0] == "#"} continue

    if {[string range $line 0 1] == "<<"} {
      # flush a pending use
      if {$use != ""} {
        lappend MAGDB($name,uses) $use
        set use ""
      }
      set close [string first ">>" $line]
      if {$close < 0} { set close [string length $line] }
      set sec [string trim [string range $line 2 [expr {$close - 1}]]]
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

    set toks [mag_words $line]
    set kw [lindex $toks 0]

    if {$section == "props"} {
      if {$kw == "string" && [lindex $toks 1] == "FIXED_BBOX" && \
          [llength $toks] >= 6 && [mag_all_int [lrange $toks 2 5]]} {
        set MAGDB($name,bbox) [lrange $toks 2 5]
      }
      continue
    }

    if {$section == "labels"} {
      if {$kw == "rlabel" || $kw == "flabel"} {
        set lname [lindex $toks 1]
        set i 2
        if {[lindex $toks $i] == "s"} { incr i }
        set coords [lrange $toks $i [expr {$i + 3}]]
        if {[llength $coords] < 4 || ![mag_all_int $coords]} continue
        set i [expr {$i + 5}]     ;# skip x1 y1 x2 y2 pos
        if {$kw == "flabel"} {
          set i [expr {$i + 5}]   ;# font size rotation offx offy
        }
        set text [string trim [join [lrange $toks $i end] " "]]
        if {$text == ""} continue
        setl {x1 y1 x2 y2} $coords
        lappend MAGDB($name,labels) [list $lname $x1 $y1 $x2 $y2 $text]
      }
      continue
    }

    switch -exact -- $kw {
      magic - timestamp {
        continue
      }
      tech {
        set MAGDB($name,tech) [lindex $toks 1]
        continue
      }
      magscale {
        if {[llength $toks] >= 3 && [mag_all_int [lrange $toks 1 2]]} {
          set MAGDB($name,n) [lindex $toks 1]
          set MAGDB($name,d) [lindex $toks 2]
        }
        continue
      }
      rect {
        if {[llength $toks] >= 5 && [mag_all_int [lrange $toks 1 4]]} {
          if {$layer != "" && ![mag_skip_layer $layer]} {
            lappend MAGDB($name,$layer) [concat rect [lrange $toks 1 4]]
          }
        }
        continue
      }
      tri {
        # tri x1 y1 x2 y2 dir — dir is the corner holding the right angle
        if {[llength $toks] >= 6 && [mag_all_int [lrange $toks 1 4]]} {
          if {$layer != "" && ![mag_skip_layer $layer]} {
            lappend MAGDB($name,$layer) [concat tri [lrange $toks 1 4] [list [string tolower [lindex $toks 5]]]]
          }
        }
        continue
      }
      use {
        if {$use != ""} { lappend MAGDB($name,uses) $use }
        set cell [lindex $toks 1]
        set inst [lindex $toks 2]
        if {$inst == ""} { set inst $cell }
        # {cell inst a b c d e f array box}
        set use [list $cell $inst 1 0 0 0 1 0 "" ""]
        continue
      }
      transform {
        if {$use != "" && [llength $toks] >= 7 && [mag_all_int [lrange $toks 1 6]]} {
          set use [concat [lrange $use 0 1] [lrange $toks 1 6] [lrange $use 8 9]]
        }
        continue
      }
      array {
        if {$use != "" && [llength $toks] >= 7 && [mag_all_int [lrange $toks 1 6]]} {
          set use [lreplace $use 8 8 [lrange $toks 1 6]]
        }
        continue
      }
      box {
        if {$use != "" && [llength $toks] >= 5 && [mag_all_int [lrange $toks 1 4]]} {
          set use [lreplace $use 9 9 [lrange $toks 1 4]]
        }
        continue
      }
    }
  }
  if {$use != ""} { lappend MAGDB($name,uses) $use }
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
    # Tcl 8.0: no glob -directory
    set names {}
    if {[catch {set names [glob -nocomplain [file join $dir *]]}]} {
      continue
    }
    foreach f $names {
      incr n
      set bn [file tail $f]
      if {[file isdirectory $f]} {
        set low [string tolower $bn]
        if {$bn == ".git" || $low == "maglef" || $low == "max_import"} continue
        lappend dirs $f
      } else {
        if {[string match *.mag $bn]} {
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
  catch {unset used}
  set used(__none__) 1
  foreach name $MAGDB(cells) {
    if {![info exists MAGDB($name,uses)]} continue
    foreach u $MAGDB($name,uses) {
      set child [lindex $u 0]
      set used($child) 1
    }
  }
  set roots {}
  foreach name $MAGDB(cells) {
    if {![info exists used($name)] && [info exists MAGDB($name,file)]} {
      lappend roots $name
    }
  }
  foreach prefer {example_por user_analog_proj_example} {
    if {[lsearch -exact $roots $prefer] >= 0} { return $prefer }
  }
  foreach prefer {example_por user_analog_proj_example} {
    if {[info exists MAGDB($prefer,n)]} { return $prefer }
  }
  if {[llength $roots] == 1} { return [lindex $roots 0] }
  if {[llength $roots] > 1} {
    # Several roots: take the one with the most instances (the assembly).
    set best [lindex $roots 0]
    set bestn -1
    foreach r $roots {
      set c [llength $MAGDB($r,uses)]
      if {$c > $bestn} {
        set best $r
        set bestn $c
      }
    }
    return $best
  }
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

# Rectangle grown by g (file units, may be fractional) → 5-point GDS polygon.
proc mag_rect_xy {x1 y1 x2 y2 g scale} {
  if {$x1 > $x2} { set t $x1; set x1 $x2; set x2 $t }
  if {$y1 > $y2} { set t $y1; set y1 $y2; set y2 $t }
  set x1 [expr {$x1 - $g}]
  set y1 [expr {$y1 - $g}]
  set x2 [expr {$x2 + $g}]
  set y2 [expr {$y2 + $g}]
  setl {gx1 gy1} [mag_scale_xy $x1 $y1 $scale]
  setl {gx2 gy2} [mag_scale_xy $x2 $y2 $scale]
  return [list $gx1 $gy1 $gx2 $gy1 $gx2 $gy2 $gx1 $gy2 $gx1 $gy1]
}

# Magic split tile: bbox plus the corner that holds the right angle.
proc mag_tri_xy {x1 y1 x2 y2 dir scale} {
  if {$x1 > $x2} { set t $x1; set x1 $x2; set x2 $t }
  if {$y1 > $y2} { set t $y1; set y1 $y2; set y2 $t }
  switch -exact -- $dir {
    ne { set pts [list $x2 $y2 $x1 $y2 $x2 $y1] }
    nw { set pts [list $x1 $y2 $x1 $y1 $x2 $y2] }
    sw { set pts [list $x1 $y1 $x2 $y1 $x1 $y2] }
    default { set pts [list $x2 $y1 $x2 $y2 $x1 $y1] }
  }
  set out {}
  for {set i 0} {$i < 6} {incr i 2} {
    setl {gx gy} [mag_scale_xy [lindex $pts $i] [lindex $pts [expr {$i + 1}]] $scale]
    lappend out $gx $gy
  }
  lappend out [lindex $out 0] [lindex $out 1]
  return $out
}

proc mag_write_cell {fh name family} {
  global MAGDB MAG_IMPORT
  mag_gds_bgnstr $fh $name
  set n 1
  set d 1
  if {[info exists MAGDB($name,n)]} { set n $MAGDB($name,n) }
  if {[info exists MAGDB($name,d)]} { set d $MAGDB($name,d) }
  set file_h 0
  set out_h 0
  if {[info exists MAG_IMPORT(lambda_hnm)]} {
    set file_h [mag_exact_file_hnm $MAG_IMPORT(lambda_hnm) $n $d]
  }
  if {[info exists MAG_IMPORT(gds_hnm)]} { set out_h $MAG_IMPORT(gds_hnm) }
  if {$file_h == "" || $file_h <= 0 || $out_h <= 0} {
    error "no exact scale for cell $name (magscale $n $d)"
  }
  set MAG_IMPORT(file_hnm) $file_h
  set MAG_IMPORT(out_hnm) $out_h
  set scale 1.0
  set text_dt [mag_text_dt $family]

  if {[info exists MAGDB($name,layers)]} {
    foreach layer $MAGDB($name,layers) {
      if {![info exists MAGDB($name,$layer)]} continue
      set recs [mag_gds_map $family $layer]
      foreach geom $MAGDB($name,$layer) {
        set kind [lindex $geom 0]
        foreach rec $recs {
          setl {lay dt grow_nm} $rec
          set g 0
          if {$grow_nm != "" && $grow_nm > 0} {
            set grow_h [mag_exact_nm_hnm $grow_nm]
            if {$grow_h == ""} {
              error "implant grow $grow_nm nm on $layer is not a whole number of half-nanometres"
            }
            set g [mag_exact_grow_file $grow_h $file_h]
            set used [expr {$g * $file_h}]
            if {$used != $grow_h} {
              mag_log "grow $layer $grow_nm nm expanded to [mag_exact_hnm_text $used] so it stays on the file grid"
            }
          }
          if {$kind == "rect"} {
            setl {x1 y1 x2 y2} [lrange $geom 1 4]
            mag_gds_boundary $fh $lay $dt [mag_rect_xy $x1 $y1 $x2 $y2 $g $scale]
          } elseif {$kind == "tri"} {
            setl {x1 y1 x2 y2 dir} [lrange $geom 1 5]
            if {$g > 0} {
              mag_gds_boundary $fh $lay $dt [mag_rect_xy $x1 $y1 $x2 $y2 $g $scale]
            } else {
              mag_gds_boundary $fh $lay $dt [mag_tri_xy $x1 $y1 $x2 $y2 $dir $scale]
            }
          }
        }
      }
    }
  }

  if {[info exists MAGDB($name,labels)]} {
    foreach lab $MAGDB($name,labels) {
      setl {lname x1 y1 x2 y2 text} $lab
      if {$text == ""} continue
      set lay 999
      set dt $text_dt
      if {![mag_skip_layer $lname]} {
        set recs [mag_gds_map $family $lname]
        set lay [lindex [lindex $recs 0] 0]
      }
      if {$lay >= 200} {
        # label on space / unknown paint → the PDK text layer if there is one
        set trec [mag_gds_map $family text]
        set lay [lindex [lindex $trec 0] 0]
        set dt [lindex [lindex $trec 0] 1]
        if {$lay >= 200} continue
      }
      set anchor [mag_exact_label_anchor $x1 $y1 $x2 $y2]
      set mx [lindex $anchor 0]
      set my [lindex $anchor 1]
      setl {gx gy} [mag_scale_xy $mx $my $scale]
      mag_gds_text $fh $lay $dt $gx $gy $text
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
        # Magic (DBcellsrch.c): element (i,j) is at T(xsep*(i-xlo), ysep*(j-ylo)),
        # i.e. element xlo,ylo sits at the transform origin and the steps are
        # taken in the child frame (rotated by T); xsep flips when xlo > xhi.
        set cols [expr {$xhi - $xlo}]
        set rows [expr {$yhi - $ylo}]
        if {$cols < 0} { set cols [expr {0 - $cols}]; set xsep [expr {0 - $xsep}] }
        if {$rows < 0} { set rows [expr {0 - $rows}]; set ysep [expr {0 - $ysep}] }
        incr cols
        incr rows
        set cxv [expr {$a * $cols * $xsep}]
        set cyv [expr {$d * $cols * $xsep}]
        set rxv [expr {$b * $rows * $ysep}]
        set ryv [expr {$e * $rows * $ysep}]
        setl {gcx gcy} [mag_scale_xy [expr {$c + $cxv}] [expr {$f + $cyv}] $scale]
        setl {grx gry} [mag_scale_xy [expr {$c + $rxv}] [expr {$f + $ryv}] $scale]
        mag_gds_aref $fh $cell $refl $ang $cols $rows $gx $gy $gcx $gcy $grx $gry
      } else {
        mag_gds_sref $fh $cell $refl $ang $gx $gy
      }
    }
  }

  # Empty placeholder (missing stdcell): draw the instance box if we stored one
  if {![info exists MAGDB($name,layers)] || ![llength $MAGDB($name,layers)]} {
    if {[info exists MAGDB($name,stubbox)] && $MAGDB($name,stubbox) != ""} {
      setl {x1 y1 x2 y2} $MAGDB($name,stubbox)
      set brec [mag_gds_map $family bbox]
      mag_gds_boundary $fh [lindex [lindex $brec 0] 0] [lindex [lindex $brec 0] 1] \
          [mag_rect_xy $x1 $y1 $x2 $y2 0 $scale]
    }
  }

  mag_gds_endstr $fh
}

proc mag_exact_header {path} {
  set n 1
  set d 1
  if {[catch {set fh [open $path r]}]} { return [list 1 1] }
  while {[gets $fh line] >= 0} {
    set toks [mag_words $line]
    if {[lindex $toks 0] == "magscale" && [llength $toks] >= 3 && \
        [mag_all_int [lrange $toks 1 2]]} {
      set n [lindex $toks 1]
      set d [lindex $toks 2]
      break
    }
    if {[string match "<<*" [string trim $line]]} break
  }
  close $fh
  return [list $n $d]
}

proc mag_exact_dest_db_hnm {tech} {
  set f ""
  if {[info commands pdk_find_tech27] != ""} {
    catch {set f [pdk_find_tech27 $tech]}
  }
  if {$f == ""} {
    foreach dir [list \
        [file join /mmi-pdks max tech $tech] \
        [file join /mmi-home mmi_private max tech $tech] \
        [file join /mmi-home cad mmi_local max tech $tech]] {
      set c [file join $dir ${tech}.tech27]
      if {[file readable $c]} { set f $c; break }
    }
  }
  if {$f == ""} {
    mag_log "No ${tech}.tech27 yet; exactness is checked against 1 nm database units"
    return 2
  }
  set h [mag_exact_tech27_db_hnm $f]
  if {$h == "" || $h <= 0} {
    mag_log "Could not read the units line of $f; checking against 1 nm"
    return 2
  }
  mag_log "Destination database unit [mag_exact_hnm_text $h] ($f)"
  return $h
}

proc mag_exact_mask_hnm {family} {
  if {$family == "gf180mcu"} { return 100 }
  return 10
}

# Reject the conversion when a file-unit corner is not a whole number of
# GDS units (1 nm) or of the destination database unit. Does not round.
proc mag_exact_prepare {family dir top} {
  global MAG_IMPORT
  set lambda [mag_lambda_hnm $family]
  set MAG_IMPORT(lambda_hnm) $lambda
  set n 1
  set d 1
  if {$top != "" && $top != "auto"} {
    set mag [file join $dir ${top}.mag]
    if {[file readable $mag]} {
      set hd [mag_exact_header $mag]
      set n [lindex $hd 0]
      set d [lindex $hd 1]
    }
  }
  set file_h [mag_exact_file_hnm $lambda $n $d]
  if {$file_h == ""} {
    return "magscale $n $d does not divide lambda [mag_exact_hnm_text $lambda]. Refusing to round."
  }
  set MAG_IMPORT(file_hnm) $file_h
  set MAG_IMPORT(gds_hnm) 2
  set MAG_IMPORT(out_hnm) 2
  set db_h [mag_exact_dest_db_hnm $MAG_IMPORT(tech)]
  set MAG_IMPORT(db_hnm) $db_h
  mag_log "Exact scale: file unit [mag_exact_hnm_text $file_h], GDS unit 1 nm, database unit [mag_exact_hnm_text $db_h]"
  if {[expr {$file_h % 2}] != 0} {
    return "File unit [mag_exact_hnm_text $file_h] is not a whole number of 1 nm GDS units. Refusing to round."
  }
  if {[expr {$file_h % $db_h}] != 0} {
    return "File unit [mag_exact_hnm_text $file_h] is not a whole number of database units ([mag_exact_hnm_text $db_h]). Refusing to round."
  }
  return ""
}

proc mag_exact_scan_max {path mask_hnm} {
  if {![file readable $path]} { return "" }
  if {[catch {set fh [open $path r]}]} { return "" }
  set db_h ""
  set section ""
  set bad ""
  set lineno 0
  while {[gets $fh line] >= 0} {
    incr lineno
    if {$lineno > 2000000} break
    set t [string trim $line]
    set toks [mag_words $t]
    if {[lindex $toks 0] == "resolution" && [llength $toks] >= 2} {
      set db_h [mag_exact_um_hnm [lindex $toks 1]]
      continue
    }
    if {[lindex $toks 0] == "SECTION" && [llength $toks] >= 2} {
      set section [lindex $toks 1]
      continue
    }
    if {[string match "\}*" $t]} { set section ""; continue }
    if {$db_h == "" || $db_h <= 0} continue
    set coords {}
    if {$section == "RECTS" || $section == "PAINT"} {
      if {[llength $toks] >= 4 && [mag_all_int [lrange $toks 0 3]]} {
        set coords [lrange $toks 0 3]
      } elseif {[lindex $toks 0] == "rect" && [llength $toks] >= 5 && \
          [mag_all_int [lrange $toks 1 4]]} {
        set coords [lrange $toks 1 4]
      }
    } elseif {$section == "LABELS"} {
      if {([lindex $toks 0] == "lab" || [lindex $toks 0] == "t") && \
          [llength $toks] >= 6 && [mag_all_int [lrange $toks 2 5]]} {
        set coords [lrange $toks 2 5]
      }
    }
    foreach c $coords {
      set num [expr {$c * $db_h}]
      if {[string first . $num] >= 0 || [expr {$num % $mask_hnm}] != 0} {
        set bad "off mask grid at line $lineno ($t)"
        break
      }
    }
    if {$bad != ""} break
  }
  close $fh
  return $bad
}

# Nearest file-unit coordinate whose half-nanometre position is on the mask.
proc mag_exact_snap_coord {c db_h mask_hnm} {
  if {![mag_exact_is_int $c] || $db_h <= 0 || $mask_hnm <= 0} { return $c }
  set hnm [expr {$c * $db_h}]
  set neg 0
  if {$hnm < 0} {
    set neg 1
    set hnm [expr {0 - $hnm}]
  }
  set q [expr {$hnm / $mask_hnm}]
  set r [expr {$hnm % $mask_hnm}]
  if {[expr {$r * 2}] >= $mask_hnm} { incr q }
  set snapped [expr {$q * $mask_hnm}]
  if {[expr {$snapped % $db_h}] != 0} { return $c }
  set out [expr {$snapped / $db_h}]
  if {$neg} { set out [expr {0 - $out}] }
  return $out
}

# Label anchors from GDS text can sit off the 5 nm mask (VNB at y=116).
# Rectangles are left alone. Snapping the point does not move paint.
proc mag_exact_snap_labels {path family} {
  if {![file readable $path]} { return 0 }
  if {[catch {set fh [open $path r]}]} { return 0 }
  set mask [mag_exact_mask_hnm $family]
  set db_h ""
  set section ""
  set changed 0
  set out {}
  while {[gets $fh line] >= 0} {
    set t [string trim $line]
    set toks [mag_words $t]
    if {[lindex $toks 0] == "resolution" && [llength $toks] >= 2} {
      set db_h [mag_exact_um_hnm [lindex $toks 1]]
    }
    if {[lindex $toks 0] == "SECTION" && [llength $toks] >= 2} {
      set section [lindex $toks 1]
    }
    if {[string match "\}*" $t]} { set section "" }
    if {$section == "LABELS" && $db_h != "" && $db_h > 0 && \
        ([lindex $toks 0] == "lab" || [lindex $toks 0] == "t") && \
        [llength $toks] >= 6 && [mag_all_int [lrange $toks 2 5]]} {
      set moved 0
      set i 2
      while {$i <= 5} {
        set c [lindex $toks $i]
        set s [mag_exact_snap_coord $c $db_h $mask]
        if {$s != $c} {
          set toks [lreplace $toks $i $i $s]
          set moved 1
        }
        incr i
      }
      if {$moved} {
        set indent ""
        if {[string match "\t*" $line]} { set indent "\t" }
        set line "$indent[join $toks " "]"
        set changed 1
      }
    }
    lappend out $line
  }
  close $fh
  if {!$changed} { return 0 }
  if {[catch {set fh [open $path w]}]} { return 0 }
  puts $fh [join $out \n]
  close $fh
  return 1
}

proc mag_exact_snap_labels_tree {dir family} {
  set files {}
  catch {set files [glob -nocomplain [file join $dir *.max]]}
  set n 0
  foreach f $files {
    if {[mag_exact_snap_labels $f $family]} { incr n }
  }
  if {$n > 0} {
    mag_log "Snapped off-grid labels onto the mask in $n .max file(s)"
  }
  return $n
}

proc mag_exact_norm_rect {x1 y1 x2 y2} {
  if {$x1 > $x2} { set t $x1; set x1 $x2; set x2 $t }
  if {$y1 > $y2} { set t $y1; set y1 $y2; set y2 $t }
  return [list $x1 $y1 $x2 $y2]
}

proc mag_exact_rect_covered {rects x1 y1 x2 y2} {
  foreach r $rects {
    if {[lindex $r 0] <= $x1 && [lindex $r 2] >= $x2 && \
        [lindex $r 1] <= $y1 && [lindex $r 3] >= $y2} {
      return 1
    }
  }
  return 0
}

proc mag_exact_note_bridge {extraVar rects x1 y1 x2 y2} {
  upvar $extraVar extra
  if {$x1 >= $x2 || $y1 >= $y2} { return }
  if {[mag_exact_rect_covered $rects $x1 $y1 $x2 $y2]} { return }
  if {[mag_exact_rect_covered $extra $x1 $y1 $x2 $y2]} { return }
  lappend extra [list $x1 $y1 $x2 $y2]
}

# Add a rectangle that fills a gap smaller than the spacing rule.
# limit is in the same integer file units as the rects.
proc mag_exact_bridge_rects {rects limit} {
  set extra {}
  set n [llength $rects]
  for {set i 0} {$i < $n} {incr i} {
    set a [lindex $rects $i]
    set ax1 [lindex $a 0]
    set ay1 [lindex $a 1]
    set ax2 [lindex $a 2]
    set ay2 [lindex $a 3]
    for {set j [expr {$i + 1}]} {$j < $n} {incr j} {
      set b [lindex $rects $j]
      set bx1 [lindex $b 0]
      set by1 [lindex $b 1]
      set bx2 [lindex $b 2]
      set by2 [lindex $b 3]
      set oy1 $ay1
      if {$by1 > $oy1} { set oy1 $by1 }
      set oy2 $ay2
      if {$by2 < $oy2} { set oy2 $by2 }
      if {$oy2 > $oy1} {
        if {$ax2 < $bx1} {
          set g [expr {$bx1 - $ax2}]
          if {$g > 0 && $g < $limit} {
            mag_exact_note_bridge extra $rects $ax2 $oy1 $bx1 $oy2
          }
        } elseif {$bx2 < $ax1} {
          set g [expr {$ax1 - $bx2}]
          if {$g > 0 && $g < $limit} {
            mag_exact_note_bridge extra $rects $bx2 $oy1 $ax1 $oy2
          }
        }
      }
      set ox1 $ax1
      if {$bx1 > $ox1} { set ox1 $bx1 }
      set ox2 $ax2
      if {$bx2 < $ox2} { set ox2 $bx2 }
      if {$ox2 > $ox1} {
        if {$ay2 < $by1} {
          set g [expr {$by1 - $ay2}]
          if {$g > 0 && $g < $limit} {
            mag_exact_note_bridge extra $rects $ox1 $ay2 $ox2 $by1
          }
        } elseif {$by2 < $ay1} {
          set g [expr {$ay1 - $by2}]
          if {$g > 0 && $g < $limit} {
            mag_exact_note_bridge extra $rects $ox1 $by2 $ox2 $ay1
          }
        }
      }
    }
  }
  return $extra
}

proc mag_exact_hvi_rect {toks} {
  set key [lindex $toks 0]
  if {$key == "rect" && [llength $toks] >= 5 && \
      [mag_all_int [lrange $toks 1 4]]} {
    return [mag_exact_norm_rect [lindex $toks 1] [lindex $toks 2] \
        [lindex $toks 3] [lindex $toks 4]]
  }
  if {[llength $toks] >= 4 && [mag_all_int [lrange $toks 0 3]]} {
    return [mag_exact_norm_rect [lindex $toks 0] [lindex $toks 1] \
        [lindex $toks 2] [lindex $toks 3]]
  }
  return ""
}

proc mag_exact_flush_hvi {outVar hviVar changedVar limit} {
  upvar $outVar out
  upvar $hviVar hvi
  upvar $changedVar changed
  if {[llength $hvi] == 0} { return }
  set extra [mag_exact_bridge_rects $hvi $limit]
  if {[llength $extra] > 0} {
    set changed 1
    foreach r $extra {
      lappend out "[lindex $r 0] [lindex $r 1] [lindex $r 2] [lindex $r 3]"
    }
  }
  set hvi {}
}

# .max paint is "SECTION RECTS { layer hvi / x1 y1 x2 y2 }", not
# "type hvi" and "rect". Bridges are appended; existing lines stay.
proc mag_exact_merge_hvi {path} {
  if {![file readable $path]} { return 0 }
  if {[catch {set fh [open $path r]}]} { return 0 }
  set data [read $fh]
  close $fh
  set lines [split $data \n]
  set res ""
  foreach line $lines {
    set toks [mag_words [string trim $line]]
    if {[lindex $toks 0] == "resolution" && [llength $toks] >= 2} {
      set res [lindex $toks 1]
      break
    }
  }
  set db_h [mag_exact_um_hnm $res]
  set space_h [mag_exact_um_hnm 0.7]
  if {$db_h == "" || $db_h <= 0 || $space_h == "" || $space_h <= 0} { return 0 }
  if {[expr {$space_h % $db_h}] != 0} { return 0 }
  set limit [expr {$space_h / $db_h}]

  set out {}
  set section ""
  set layer ""
  set hvi {}
  set changed 0
  foreach line $lines {
    set t [string trim $line]
    set toks [mag_words $t]
    set key [lindex $toks 0]
    if {$key == "SECTION" && [llength $toks] >= 2} {
      if {$layer == "hvi"} {
        mag_exact_flush_hvi out hvi changed $limit
      }
      set section [lindex $toks 1]
      set layer ""
      lappend out $line
      continue
    }
    if {[string match "\}*" $t]} {
      if {$layer == "hvi"} {
        mag_exact_flush_hvi out hvi changed $limit
      }
      set section ""
      set layer ""
      lappend out $line
      continue
    }
    if {$section == "RECTS" || $section == "PAINT"} {
      if {($key == "layer" || $key == "type") && [llength $toks] >= 2} {
        if {$layer == "hvi"} {
          mag_exact_flush_hvi out hvi changed $limit
        }
        set layer [string tolower [lindex $toks 1]]
        lappend out $line
        continue
      }
      if {$layer == "hvi"} {
        set r [mag_exact_hvi_rect $toks]
        if {$r != ""} {
          lappend hvi $r
          lappend out $line
          continue
        }
      }
    }
    lappend out $line
  }
  if {$layer == "hvi"} {
    mag_exact_flush_hvi out hvi changed $limit
  }
  if {!$changed} { return 0 }
  if {[catch {set fh [open $path w]}]} { return 0 }
  puts $fh [join $out \n]
  close $fh
  return 1
}

proc mag_exact_merge_hvi_tree {dir} {
  set files {}
  catch {set files [glob -nocomplain [file join $dir *.max]]}
  set n 0
  foreach f $files {
    if {[mag_exact_merge_hvi $f]} { incr n }
  }
  if {$n > 0} {
    mag_log "Joined hvi gaps under 0.7 um in $n .max file(s)"
  }
  return $n
}

proc mag_exact_scan_tree {dir family} {
  mag_exact_merge_hvi_tree $dir
  mag_exact_snap_labels_tree $dir $family
  set mask [mag_exact_mask_hnm $family]
  set files {}
  catch {set files [glob -nocomplain [file join $dir *.max]]}
  set msgs {}
  foreach f $files {
    set err [mag_exact_scan_max $f $mask]
    if {$err != ""} {
      lappend msgs "[file tail $f]: $err"
    }
  }
  return [join $msgs \n]
}

# Mark a Tcl-dump result so a later open can tell it from a Magic GDS import.
proc mag_stamp_preview {path} {
  if {![file readable $path]} { return }
  if {[catch {set fh [open $path r]}]} { return }
  set data [read $fh]
  close $fh
  if {[string first "mmi_convert" $data] >= 0} { return }
  if {[regsub {SECTION PROPERTIES \{\n} $data "SECTION PROPERTIES \{\n\tmmi_convert preview\n" data]} {
  } elseif {[regsub {SECTION } $data "SECTION PROPERTIES \{\n\tmmi_convert preview\n\} SECTION PROPERTIES\n\nSECTION " data]} {
  } else {
    return
  }
  if {[catch {set fh [open $path w]}]} { return }
  puts -nonewline $fh $data
  close $fh
}

proc mag_stamp_preview_tree {dir} {
  set files {}
  catch {set files [glob -nocomplain [file join $dir *.max]]}
  foreach f $files { mag_stamp_preview $f }
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

  if {$MAG_IMPORT(tech) == "" || [lsearch -exact $techs $MAG_IMPORT(tech)] < 0} {
    if {[lsearch -exact $techs sky130A] >= 0} {
      set MAG_IMPORT(tech) sky130A
    } elseif {[info exists MN_TECH] && [lsearch -exact $techs $MN_TECH] >= 0} {
      set MAG_IMPORT(tech) $MN_TECH
    } else {
      set MAG_IMPORT(tech) [lindex $techs 0]
    }
  }

  set src_labels {}
  set src_values {}
  lappend src_labels "Download full Caravel die from GitHub (sky130A GDS)"
  lappend src_values fetch
  lappend src_labels "Download Caravel harness + example design (Magic → MAX)"
  lappend src_values harness
  if {$sample != ""} {
    lappend src_labels "Local Caravel sample (example_por, already on disk)"
    lappend src_values sample
  }
  lappend src_labels "Choose Magic design folder..."
  lappend src_values custom
  if {$MAG_IMPORT(source) == "sample" && $sample == ""} {
    set MAG_IMPORT(source) fetch
  }

  set prop_list ""
  # No -reload: rebuilding the prop_menu jumps the window.
  lappend prop_list [list "Magic source:" MAG_IMPORT(source) \
      -radio $src_labels -values $src_values \
      -help {GDS download opens chipfoundry/caravel caravel.gds (pad ring, management core, empty user wrapper). Magic download converts efabless/caravel mag (harness) plus caravel_user_project user_proj_example (the counter) from .mag to GDS to MAX, and opens the original Magic layout. Both need sky130A. Local sample is example_por only.}]

  lappend prop_list [list "Magic design folder:" MAG_IMPORT(dir) \
      -filename [list -message {Magic design directory} -dironly -pattern *.mag] \
      -width 56 \
      -help {Used when "Choose Magic design folder" is selected.}]

  lappend prop_list [list "Top cell (auto = hierarchy root):" MAG_IMPORT(top) -entry -width 40]

  lappend prop_list [list "GDS conversion method:" MAG_IMPORT(method) \
      -radio [list \
          "Magic mag2gds — tapeout-quality (needs Magic + shared PDK)" \
          "Tcl paint dump — preview only, not for DRC"] \
      -values {mag2gds tcl} \
      -help {Magic mag2gds writes GDS with the PDK cifoutput rules. Import a PDK with ./run.sh importer first. The Tcl dump copies paint rectangles and is stamped mmi_convert preview. It is not checked against the foundry rules.}]

  lappend prop_list [list "Destination MAX PDK / technology:" MAG_IMPORT(tech) \
      -radio $labels -values $values \
      -help {Converted .max files are written to <design>/max_import (opened in the file manager when import finishes). Caravel Mag sample requires sky130A. Import a PDK first if the list is only mmi18/mmi25.}]

  lappend prop_list [list "Also open original Mag in Magic VLSI (compare with MAX):" \
      MAG_IMPORT(open_magic) -binary \
      -help {Starts nixpkgs magic-vlsi on the same top cell so you can compare the Mag layout with the converted MAX view.}]

  if {![prop_menu2 -title "Import Magic Design Folder" $prop_list]} {
    return
  }

  # Defer so progress/dialogs map after the menu returns.
  after idle mag_import_after_dialog
}

proc mag_import_after_dialog {} {
  if {[catch {mag_import_go} err]} {
    catch {mag_progress_close}
    mag_import_tell "Magic import failed:\n$err" -copy
  }
}

proc mag_import_go {} {
  global MAG_IMPORT

  set src $MAG_IMPORT(source)
  if {$src == "fetch" || $src == "sample" || $src == "harness"} {
    # Caravel layouts are sky130A — force destination tech when available.
    set techs [mag_list_max_techs]
    if {[lsearch -exact $techs sky130A] >= 0} {
      set MAG_IMPORT(tech) sky130A
    }
    set tl [string tolower $MAG_IMPORT(tech)]
    if {![string match *sky130* $tl]} {
      set w 0
      set what "The Caravel layout is sky130A."
      if {$src == "fetch"} {
        set what "The Caravel die is a sky130A GDS."
      } elseif {$src == "harness"} {
        set what "The Caravel harness Magic files are sky130A."
      }
      catch {
        set w [tk_dialog .magwarn "PDK mismatch?" \
            "$what\nDestination technology is '$MAG_IMPORT(tech)'.\n\nInstall sky130A first (./run.sh importer), then retry.\nContinue anyway with '$MAG_IMPORT(tech)'?" \
            {} 0 Continue Cancel]
      }
      if {$w != 0} { return }
    }
  }
  set MAG_IMPORT(keep_hier) 0
  set MAG_IMPORT(skip_parse) 0
  set MAG_IMPORT(fetch_kind) die
  if {$src == "fetch"} {
    if {$MAG_IMPORT(top) == "auto" || $MAG_IMPORT(top) == "" || \
        $MAG_IMPORT(top) == "example_por" || $MAG_IMPORT(top) == "simple_por"} {
      set MAG_IMPORT(top) caravel
    }
    set MAG_IMPORT(view) chip
  } elseif {$src == "harness"} {
    if {$MAG_IMPORT(top) == "auto" || $MAG_IMPORT(top) == "" || \
        $MAG_IMPORT(top) == "example_por" || $MAG_IMPORT(top) == "simple_por"} {
      set MAG_IMPORT(top) caravel
    }
    set MAG_IMPORT(view) chip
    set MAG_IMPORT(keep_hier) 1
    set MAG_IMPORT(skip_parse) 1
    set MAG_IMPORT(fetch_kind) harness
    set MAG_IMPORT(method) mag2gds
  } elseif {$src == "sample"} {
    set MAG_IMPORT(view) cell
    if {$MAG_IMPORT(top) == "auto" || $MAG_IMPORT(top) == "" || \
        $MAG_IMPORT(top) == "caravel"} {
      set MAG_IMPORT(top) example_por
    }
  } else {
    set MAG_IMPORT(view) cell
  }

  if {$MAG_IMPORT(tech) == ""} {
    mag_import_tell "Select a destination MAX technology (./run.sh importer if none are listed)." -copy
    return
  }

  if {$src == "fetch" || $src == "harness"} {
    mag_import_fetch_start
    return
  }

  set dir ""
  if {$src == "sample"} {
    set dir [mag_sample_dir]
  } else {
    set dir [string trim $MAG_IMPORT(dir)]
  }
  if {$dir != "" && [file isfile $dir]} {
    set dir [file dirname $dir]
  }
  if {$dir == "" || ![file isdirectory $dir]} {
    mag_import_tell "Select a Magic design directory (folder that contains .mag files)." -copy
    return
  }
  mag_import_run $dir $MAG_IMPORT(top) $MAG_IMPORT(tech) $MAG_IMPORT(method)
}

proc mag_import_read_status {} {
  global MAG_IMPORT
  set MAG_IMPORT(stat_status) running
  set MAG_IMPORT(stat_pct) 0
  set MAG_IMPORT(stat_msg) ""
  set MAG_IMPORT(stat_dest) ""
  if {![file exists $MAG_IMPORT(status)]} { return }
  if {[catch {set fh [open $MAG_IMPORT(status) r]}]} { return }
  while {[gets $fh line] >= 0} {
    set eq [string first = $line]
    if {$eq < 1} continue
    set key [string range $line 0 [expr {$eq - 1}]]
    set val [string range $line [expr {$eq + 1}] end]
    switch -exact -- $key {
      STATUS { set MAG_IMPORT(stat_status) $val }
      PCT { set MAG_IMPORT(stat_pct) $val }
      MSG { set MAG_IMPORT(stat_msg) $val }
      DEST { set MAG_IMPORT(stat_dest) $val }
    }
  }
  close $fh
}

proc mag_import_fetch_start {} {
  global MAG_IMPORT

  set kind die
  if {[info exists MAG_IMPORT(fetch_kind)] && $MAG_IMPORT(fetch_kind) != ""} {
    set kind $MAG_IMPORT(fetch_kind)
  }
  if {$kind == "harness"} {
    set dest [mag_harness_dest]
    set script_name fetch_caravel_harness_mag.sh
    set prog harness
    set startmsg "Downloading Caravel harness Magic (about 160 MB)..."
  } else {
    set dest [mag_die_dest]
    set script_name fetch_caravel_die.sh
    set prog die
    set startmsg "Downloading Caravel die from GitHub..."
  }
  set stamp [clock seconds]
  set work [file join /tmp mag_fetch_$stamp]
  catch {file mkdir $work}
  set MAG_IMPORT(work) $work
  set MAG_IMPORT(log) [file join $work fetch.log]
  set MAG_IMPORT(cancel) [file join $work CANCEL]
  set MAG_IMPORT(status) [file join $work status]
  set MAG_IMPORT(pid) ""
  set MAG_IMPORT(fetch_dead) 0
  catch {file delete $MAG_IMPORT(cancel)}
  catch {file delete $MAG_IMPORT(status)}

  set sh [mag_pdk_script $script_name]
  if {$sh == ""} {
    mag_import_tell "$script_name not found.\nRe-run ./run.sh so pdk scripts are installed." -copy
    return
  }
  set bash [mag_which {bash /bin/bash /usr/bin/bash}]
  if {$bash == ""} {
    mag_import_tell "bash is not installed." -copy
    return
  }

  mag_progress_open $prog
  mag_progress_update 1 $startmsg
  mag_log "$script_name -> $dest"

  if {[catch {set MAG_IMPORT(pid) [exec $bash $sh $dest \
      $MAG_IMPORT(status) $MAG_IMPORT(cancel) $MAG_IMPORT(log) &]} err]} {
    mag_import_fail "Could not start ${script_name}:\n$err"
    return
  }
  set MAG_IMPORT(phase) fetch
  set MAG_IMPORT(after) [after 400 mag_import_poll_fetch]
}

proc mag_import_poll_fetch {} {
  global MAG_IMPORT
  set MAG_IMPORT(after) ""

  if {[mag_cancelled]} {
    catch {exec kill $MAG_IMPORT(pid)}
    mag_import_fail "Cancelled."
    return
  }

  mag_import_read_status
  set st $MAG_IMPORT(stat_status)
  set pct $MAG_IMPORT(stat_pct)
  set msg $MAG_IMPORT(stat_msg)
  if {$msg == ""} {
    if {[info exists MAG_IMPORT(fetch_kind)] && $MAG_IMPORT(fetch_kind) == "harness"} {
      set msg "Downloading Caravel harness Magic..."
    } else {
      set msg "Downloading Caravel die..."
    }
  }
  if {![mag_is_int $pct]} { set pct 1 }
  mag_progress_update $pct $msg

  if {$st == "ok"} {
    set kind die
    if {[info exists MAG_IMPORT(fetch_kind)]} { set kind $MAG_IMPORT(fetch_kind) }
    if {$kind == "harness"} {
      set dest $MAG_IMPORT(stat_dest)
      if {$dest == ""} { set dest [mag_harness_dest] }
      if {![file exists [file join $dest caravel.mag]] || \
          ![file exists [file join $dest user_proj_example.mag]] || \
          ![file exists [file join $dest caravel_core.mag]]} {
        mag_import_fail "Caravel harness Magic tree is incomplete in:\n$dest\nLog: $MAG_IMPORT(log)"
        return
      }
      set MAG_IMPORT(view) chip
      set MAG_IMPORT(keep_hier) 1
      set MAG_IMPORT(skip_parse) 1
      set MAG_IMPORT(top) caravel
      mag_progress_update 80 "Converting Caravel Magic → GDS → MAX (sky130A)..."
      mag_import_run $dest caravel $MAG_IMPORT(tech) mag2gds
      return
    }
    set dest $MAG_IMPORT(stat_dest)
    if {$dest == ""} { set dest [mag_die_dest] }
    set gds [file join $dest caravel.gds]
    if {![file exists $gds] || [file size $gds] < 20000000} {
      mag_import_fail "caravel.gds missing or too small in:\n$dest\nLog: $MAG_IMPORT(log)"
      return
    }
    mag_progress_update 80 "Opening Caravel die in MAX (sky130A)..."
    mag_import_open_die $gds $MAG_IMPORT(top) $MAG_IMPORT(tech)
    return
  }
  if {$st == "fail"} {
    set msg $MAG_IMPORT(stat_msg)
    if {$msg == ""} { set msg "Caravel download failed." }
    mag_import_fail "$msg\nLog: $MAG_IMPORT(log)"
    return
  }

  set alive 1
  if {$MAG_IMPORT(pid) != ""} {
    if {[catch {exec kill -0 $MAG_IMPORT(pid)}]} {
      set alive 0
    }
  }
  if {!$alive && $st != "ok"} {
    incr MAG_IMPORT(fetch_dead)
    if {$MAG_IMPORT(fetch_dead) < 8} {
      set MAG_IMPORT(after) [after 400 mag_import_poll_fetch]
      return
    }
    mag_import_fail "Caravel download exited early.\nLog: $MAG_IMPORT(log)"
    return
  }

  set MAG_IMPORT(after) [after 400 mag_import_poll_fetch]
}

proc mag_import_run {dir top tech {method mag2gds}} {
  global MAG_IMPORT MAGDB MAG_GDS_UNKNOWN env MN_TECH

  catch {unset MAGDB}
  catch {unset MAG_GDS_UNKNOWN}
  set MAGDB(cells) {}
  set MAG_IMPORT(method) $method
  set MAG_IMPORT(pid) ""
  set dir [_mmi_file_normalize $dir]

  set stamp [clock seconds]
  set work [file join /tmp mag_import_$stamp]
  catch {file mkdir $work}
  set MAG_IMPORT(work) $work
  set MAG_IMPORT(log) [file join $work convert.log]
  set MAG_IMPORT(cancel) [file join $work CANCEL]
  catch {file delete $MAG_IMPORT(cancel)}
  global _MAG_IMPORT_REV
  mag_log "Magic import dir=$dir tech=$tech top=$top method=$method (mag_import rev $_MAG_IMPORT_REV)"
  set MAG_IMPORT(magdir) $dir

  mag_progress_open $method
  mag_progress_update 5 "Scanning .mag files..."

  set files [mag_collect_mags $dir]
  if {![llength $files]} {
    mag_import_fail "No .mag files in:\n$dir"
    return
  }
  mag_log "[llength $files] mag files"

  set skip 0
  if {[info exists MAG_IMPORT(skip_parse)] && $MAG_IMPORT(skip_parse) == 1} {
    set skip 1
  }
  if {$skip && $top != "" && $top != "auto" && \
      [file exists [file join $dir ${top}.mag]]} {
    mag_log "Skipping rectangle parse; Magic mag2gds loads $top"
    set topcell $top
    set family [mag_family_from_tech $tech]
    set outdir [mag_output_dir $dir $topcell]
    set gds [file join $outdir ${topcell}.gds]
    if {$method != "mag2gds"} {
      mag_import_fail "Large Caravel Magic tree requires Magic mag2gds."
      return
    }
    mag_import_run_magic $dir $topcell $gds $family $tech $outdir
    return
  }

  mag_progress_update 12 "Parsing Magic cells (top-cell / hierarchy)..."
  set i 0
  set nfiles [llength $files]
  set mag_techs {}
  foreach f $files {
    if {[mag_cancelled]} {
      mag_import_fail "Cancelled."
      return
    }
    incr i
    set pct [expr {12 + int(18.0 * $i / $nfiles)}]
    mag_progress_update $pct "Parsing [file tail $f] ($i / $nfiles)"
    set cname [mag_parse_file $f]
    if {$cname != "" && [info exists MAGDB($cname,tech)]} {
      set mt $MAGDB($cname,tech)
      if {$mt != "" && [lsearch -exact $mag_techs $mt] < 0} { lappend mag_techs $mt }
    }
  }
  if {[llength $mag_techs]} {
    mag_log "Magic tech line(s): [join $mag_techs {, }] (\$PDK = env PDK when set)"
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
        mag_log "Placeholder cell $child (no .mag in folder; Magic mag2gds resolves it from the PDK libs.ref mag views)"
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
  set outdir [mag_output_dir $dir $topcell]
  if {[_mmi_file_normalize $outdir] != [_mmi_file_normalize [file join $dir max_import]]} {
    mag_log "Design folder is not writable; output goes to $outdir"
  }
  set gds [file join $outdir ${topcell}.gds]

  if {$method == "mag2gds"} {
    mag_import_run_magic $dir $topcell $gds $family $tech $outdir
    return
  }

  mag_progress_update 70 "Tcl paint dump → $gds (preview, not for DRC)"
  set perr [mag_exact_prepare $family $dir $topcell]
  if {$perr != ""} {
    mag_import_fail $perr
    return
  }
  set MAG_IMPORT(preview) 1
  mag_log "Tcl dump scale: [mag_scalefactor_nm $family] nm per lambda"
  set err [mag_write_gds $gds $family]
  if {$err != ""} {
    mag_import_fail $err
    return
  }
  if {![mag_gds_has_structs $gds]} {
    mag_import_fail "GDS write produced an empty library:\n$gds"
    return
  }
  mag_log "Wrote $gds ([file size $gds] bytes) via Tcl dump"
  mag_progress_update 85 "Importing GDS into MAX as .max..."
  mag_import_open_max $gds $topcell $tech $outdir
}

proc mag_pdk_script {basename} {
  global MMI_TOOLS env
  set cands {}
  lappend cands /mmi-pdk-live/$basename
  if {[info exists env(MMI_LOCAL)] && $env(MMI_LOCAL) != ""} {
    lappend cands [file join $env(MMI_LOCAL) max pdk $basename]
  }
  if {[info exists env(MMI_PDK_DIR)] && $env(MMI_PDK_DIR) != ""} {
    lappend cands [file join $env(MMI_PDK_DIR) $basename]
  }
  lappend cands /mmi-bundle/$basename
  if {[info exists MMI_TOOLS] && $MMI_TOOLS != ""} {
    lappend cands [file join $MMI_TOOLS ../mmi_local/max/pdk $basename]
  }
  lappend cands /mmi-home/cad/mmi_local/max/pdk/$basename
  foreach s $cands {
    set s [_mmi_file_normalize $s]
    if {[file executable $s] || [file readable $s]} { return $s }
  }
  return ""
}

proc mag_magic2gds_script {} {
  return [mag_pdk_script mag2gds.sh]
}

proc mag_find_bin {} {
  if {[info commands pdk_which] != ""} {
    set b [pdk_which {magic /mmi-magic/bin/magic /usr/bin/magic}]
    if {$b != ""} { return $b }
  }
  return [mag_which {magic /mmi-magic/bin/magic /usr/bin/magic}]
}

proc mag_want_gui {} {
  global MAG_IMPORT
  if {![info exists MAG_IMPORT(open_magic)]} { return 1 }
  set v $MAG_IMPORT(open_magic)
  if {$v == "" || $v == "0" || $v == "no" || $v == "false"} { return 0 }
  return 1
}

# Match Magic's expanded view: show subcell paint (the xhigh poly resistors,
# HVL stdcells, ...) instead of empty instance bboxes + giant cell names.
proc mag_max_show_converted {} {
  catch {
    set bb [db_bbox]
    if {[llength $bb] == 4} {
      eval lay_box $bb
      catch {lay_internals -area}
    }
  }
  catch {:expand}
  catch {expand}
  catch {:see no instanceNames}
  catch {:see no instancePorts}
  catch {view_cell}
}

proc mag_import_drc_count {} {
  if {[info commands msg_catch] == ""} { return "" }
  if {[catch {msg_catch ":drc count" err msg}]} { return "" }
  return [lindex $msg 3]
}

proc mag_max_after_gds_script {path {family sky130A} {outdir .} {top ""}} {
  set fh [open $path w]
  set report [file join $outdir mmi_convert_report.txt]
  puts $fh "# Expand Mag to MAX, save, then record DRC and the mask-grid scan."
  puts $fh "after idle {"
  puts $fh "  catch {"
  puts $fh "    set bb \[db_bbox\]"
  puts $fh "    if {\[llength \$bb\] == 4} {"
  puts $fh "      eval lay_box \$bb"
  puts $fh "      catch {lay_internals -area}"
  puts $fh "    }"
  puts $fh "  }"
  puts $fh "  catch {:expand}"
  puts $fh "  catch {expand}"
  puts $fh "  catch {:see no instanceNames}"
  puts $fh "  catch {:see no instancePorts}"
  puts $fh "  catch {view_cell}"
  puts $fh "  catch {cell_path_add [list $outdir]}"
  if {$top != ""} {
    puts $fh "  catch {db_cell_rename [list $top] [list $top] [list [file join $outdir ${top}.max]]}"
  }
  puts $fh "  catch {mag_heal_spacing hvi 0.7}"
  puts $fh "  catch {cell_save_tree 0}"
  if {$top != ""} {
    puts $fh "  catch {cell_load [list $top] [list $outdir]}"
    puts $fh "  catch {view_cell}"
  }
  puts $fh "  set _mmi_drc {}"
  puts $fh "  if {\[info commands msg_catch\] != {}} {"
  puts $fh "    catch {"
  puts $fh "      msg_catch {:drc count} _mmi_err _mmi_msg"
  puts $fh "      set _mmi_drc \[lindex \$_mmi_msg 3\]"
  puts $fh "    }"
  puts $fh "  }"
  puts $fh "  set _mmi_scan {}"
  puts $fh "  if {\[info commands mag_exact_scan_tree\] != {}} {"
  puts $fh "    catch {set _mmi_scan \[mag_exact_scan_tree [list $outdir] [list $family]\]}"
  puts $fh "  }"
  puts $fh "  set _mmi_bb {}"
  puts $fh "  catch {set _mmi_bb \[db_bbox\]}"
  puts $fh "  if {\[catch {set _mmi_fh \[open [list $report] w\]}\] == 0} {"
  puts $fh "    puts \$_mmi_fh \"drc_count \$_mmi_drc\""
  puts $fh "    puts \$_mmi_fh \"bbox \$_mmi_bb\""
  puts $fh "    puts \$_mmi_fh \"scan \$_mmi_scan\""
  puts $fh "    close \$_mmi_fh"
  puts $fh "  }"
  puts $fh "  if {\$_mmi_scan != {}} {"
  puts $fh "    puts stderr \"mmi convert: saved .max is off the mask grid: \$_mmi_scan\""
  puts $fh "  }"
  if {$top != ""} {
    puts $fh "  catch {cell_load [list $top] [list $outdir]}"
    puts $fh "  catch {view_cell}"
    puts $fh "  catch {mag_close_hvi_gaps}"
    puts $fh "  catch {mag_exact_snap_labels_tree [list $outdir] [list $family]}"
    puts $fh "  catch {mag_flush_tree [list $outdir] [list $top]}"
    puts $fh "  catch {view_cell}"
    puts $fh "  catch {:drc catchup}"
    puts $fh "  if {\[info commands msg_catch\] != {}} {"
    puts $fh "    catch {"
    puts $fh "      msg_catch {:drc count} _mmi_err _mmi_msg"
    puts $fh "      set _mmi_drc \[lindex \$_mmi_msg 3\]"
    puts $fh "    }"
    puts $fh "  }"
  }
  puts $fh "  puts stderr \"mmi convert: DRC errors \$_mmi_drc\""
  puts $fh "}"
  close $fh
}

# Draw the harness without flattening every standard cell into the top
# and without writing one .max per cell (that tree is the whole SoC).
proc mag_max_show_chip {} {
  catch {:see no instanceNames}
  catch {:see no instancePorts}
  catch {
    set bb [db_bbox]
    if {[llength $bb] == 4} {
      eval lay_box $bb
      catch {lay_internals -area}
    }
  }
  catch {view_cell}
}

proc mag_max_after_chip_script {path top} {
  if {$top == ""} { set top caravel }
  set fh [open $path w]
  puts $fh "# Show the Caravel die hierarchical. Do not expand or save the tree."
  puts $fh "after idle {"
  puts $fh "  catch {cell_load $top}"
  puts $fh "  catch {:see no instanceNames}"
  puts $fh "  catch {:see no instancePorts}"
  puts $fh "  catch {"
  puts $fh "    set bb \[db_bbox\]"
  puts $fh "    if {\[llength \$bb\] == 4} {"
  puts $fh "      eval lay_box \$bb"
  puts $fh "      catch {lay_internals -area}"
  puts $fh "    }"
  puts $fh "  }"
  puts $fh "  catch {view_cell}"
  puts $fh "}"
  close $fh
}

proc mag_finish_die {outdir top gds} {
  global MAG_IMPORT
  set MAG_IMPORT(outdir) $outdir
  set outdir [_mmi_file_normalize $outdir]
  set gds [_mmi_file_normalize $gds]
  set host [mag_host_path $outdir]
  set f [file join $outdir WHERE.txt]
  if {![catch {set fh [open $f w]}]} {
    puts $fh "Caravel die GDS opened in MAX."
    puts $fh "Cells are not flattened and are not written out as one .max per cell."
    puts $fh "CAD folder:  $outdir"
    if {$host != $outdir} {
      puts $fh "Host folder: $host"
    }
    puts $fh "Top cell:    $top"
    puts $fh "GDS:         $gds"
    close $fh
  }
  mag_open_storage_folder $outdir
  set lines {}
  lappend lines "GDS (reopen this file):"
  lappend lines "  $gds"
  set hostgds [mag_host_path $gds]
  if {$hostgds != $gds} {
    lappend lines "On the VM / host disk:"
    lappend lines "  $hostgds"
  }
  lappend lines ""
  lappend lines "A WHERE.txt file in that folder repeats these paths."
  lappend lines "Click Show to open the folder in the file manager."
  return [join $lines \n]
}

proc mag_die_done_msg {top tech gds store} {
  global MAG_IMPORT
  set log ""
  if {[info exists MAG_IMPORT(log)]} { set log $MAG_IMPORT(log) }
  return "Caravel die opened in MAX.\n\n\
Top cell: $top\n\
MAX technology: $tech\n\
Log: $log\n\n\
This is the published ChipFoundry harness: pad ring, management core, and an empty user-project wrapper. It is not example_por. A filled user project (the numbered macros) is not in this GDS.\n\n\
Internals are drawn, but the chip is not flattened and cells are not saved one-by-one. Expanding every instance can exhaust memory.\n\n\
$store"
}

proc mag_finish_harness {outdir top gds magdir} {
  global MAG_IMPORT
  set MAG_IMPORT(outdir) $outdir
  set outdir [_mmi_file_normalize $outdir]
  set gds [_mmi_file_normalize $gds]
  set magdir [_mmi_file_normalize $magdir]
  set f [file join $outdir WHERE.txt]
  if {![catch {set fh [open $f w]}]} {
    puts $fh "Caravel harness Magic converted to hierarchical GDS, opened in MAX."
    puts $fh "Magic folder: $magdir"
    puts $fh "Top cell:    $top"
    puts $fh "GDS:         $gds"
    puts $fh "CAD folder:  $outdir"
    set host [mag_host_path $outdir]
    if {$host != $outdir} {
      puts $fh "Host folder: $host"
    }
    close $fh
  }
  mag_open_storage_folder $outdir
  set lines {}
  lappend lines "Magic source:"
  lappend lines "  $magdir"
  lappend lines "GDS written by Magic:"
  lappend lines "  $gds"
  set hostgds [mag_host_path $gds]
  if {$hostgds != $gds} {
    lappend lines "On the VM / host disk:"
    lappend lines "  $hostgds"
  }
  lappend lines ""
  lappend lines "Click Show to open the GDS folder in the file manager."
  return [join $lines \n]
}

proc mag_harness_done_msg {top tech gds store} {
  global MAG_IMPORT
  set log ""
  if {[info exists MAG_IMPORT(log)]} { set log $MAG_IMPORT(log) }
  set msg "Caravel harness converted from Magic to MAX.\n\n\
Top cell: $top\n\
MAX technology: $tech\n\
Log: $log\n\n\
Source is efabless/caravel mag (padframe, management core, top caravel) plus the example design user_proj_example from efabless/caravel_user_project, placed by user_project_wrapper.\n\n\
Magic writes a hierarchical GDS. MAX draws that GDS without flattening every standard cell.\n\n\
Stdcells and IO pads come from the sky130A PDK. RAM128 is not published as a Magic layout, so each of the three management SRAMs is the placement rectangle from caravel_core (about 404 um by 438 um), not the memory array.\n\n\
$store"
  if {[mag_want_gui]} {
    set msg "$msg\n\nMagic VLSI is also opening the original .mag so you can compare it with MAX. Drawing the full chip can take several minutes."
  }
  return $msg
}

proc mag_import_finish_chip {top tech gds outdir magdir family} {
  set harness 0
  if {$magdir != "" && [file exists [file join $magdir caravel.mag]] && \
      [file exists [file join $magdir user_proj_example.mag]]} {
    set harness 1
  }
  if {$harness} {
    mag_open_in_magic $magdir $top $family
  }
  mag_progress_close
  if {$harness} {
    set store [mag_finish_harness $outdir $top $gds $magdir]
    mag_import_tell [mag_harness_done_msg $top $tech $gds $store] -copy
  } else {
    set store [mag_finish_die $outdir $top $gds]
    mag_import_tell [mag_die_done_msg $top $tech $gds $store] -copy
  }
}

proc mag_import_open_die {gds top tech} {
  global MAG_IMPORT
  set MAG_IMPORT(gds) $gds
  set MAG_IMPORT(view) chip
  set MAG_IMPORT(method) gds
  set MAG_IMPORT(magdir) ""
  if {$top == "" || $top == "auto"} { set top caravel }
  set outdir [file dirname $gds]
  if {![info exists MAG_IMPORT(work)] || $MAG_IMPORT(work) == ""} {
    set MAG_IMPORT(work) [file join /tmp mag_die_[clock seconds]]
    catch {file mkdir $MAG_IMPORT(work)}
  }
  mag_import_open_max $gds $top $tech $outdir
}

proc mag_open_in_magic {dir top family} {
  global MAG_IMPORT
  if {![mag_want_gui]} { return }
  if {$dir == "" || $top == ""} { return }
  set sh [mag_pdk_script open_mag.sh]
  if {$sh == ""} {
    mag_log "open_mag.sh not found; skip Magic GUI compare"
    return
  }
  if {[mag_find_bin] == ""} {
    mag_log "magic-vlsi not on PATH (/mmi-magic); skip Magic GUI compare"
    return
  }
  mag_log "Opening Magic VLSI GUI: $sh $dir $top $family"
  if {[catch {exec /bin/bash $sh $dir $top $family &} err]} {
    mag_log "Could not start Magic GUI: $err"
  }
}

proc mag_import_run_magic {dir topcell gds family tech outdir} {
  global MAG_IMPORT env

  set sh [mag_magic2gds_script]
  if {$sh == ""} {
    mag_import_fail "mag2gds.sh not found. Re-run ./run.sh, or use the Tcl paint-dump converter."
    return
  }

  set magicbin [mag_find_bin]
  if {$magicbin == ""} {
    mag_import_fail "Magic VLSI (nixpkgs magic-vlsi) is not installed in this Nix env.\nUse the Tcl paint-dump converter, or re-run ./run.sh so /mmi-magic is bound."
    return
  }
  if {[mag_pdk_dir $family] == ""} {
    set root /mmi-pdks
    if {[info commands pdk_root] != ""} { catch {set root [pdk_root]} }
    mag_import_fail "No open_pdks tree for $family under $root\n(Magic needs <pdk>/libs.tech/magic/<pdk>.tech).\nRun ./run.sh importer first, or use the Tcl paint-dump preview."
    return
  }

  mag_progress_update 40 "Running Magic mag2gds (PDK cifoutput)..."
  set perr [mag_exact_prepare $family $dir $topcell]
  if {$perr != ""} {
    mag_import_fail $perr
    return
  }
  set MAG_IMPORT(preview) 0
  mag_log "mag2gds: $sh $dir $topcell $gds $family"
  catch {file delete $gds}
  set logfile $MAG_IMPORT(log)
  if {[info exists MAG_IMPORT(keep_hier)] && $MAG_IMPORT(keep_hier) == 1} {
    set env(MAG2GDS_KEEP_HIER) 1
    mag_log "mag2gds hierarchical (MAG2GDS_KEEP_HIER=1)"
  } else {
    catch {unset env(MAG2GDS_KEEP_HIER)}
  }
  if {[catch {set MAG_IMPORT(pid) [exec /bin/bash $sh $dir $topcell $gds $family >>& $logfile &]} err]} {
    mag_import_fail "Could not start Magic mag2gds:\n$err"
    return
  }
  set MAG_IMPORT(phase) mag2gds
  set MAG_IMPORT(gds) $gds
  set MAG_IMPORT(topcell) $topcell
  set MAG_IMPORT(tech) $tech
  set MAG_IMPORT(outdir) $outdir
  set MAG_IMPORT(magic_polls) 0
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

  incr MAG_IMPORT(magic_polls)
  set pct [expr {45 + ($MAG_IMPORT(magic_polls) % 30)}]
  mag_progress_update $pct "Magic mag2gds running ([expr {$MAG_IMPORT(magic_polls) / 2}] s)..."

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
    set why "Magic mag2gds failed (no GDS was written)."
    set tail [mag_log_tail 40]
    if {[string match {*magicrc*} $tail] || [string match {*No Magic*} $tail]} {
      set why "$why\nInstall sky130A first (./run.sh importer) so this file exists:\n  /mmi-pdks/sky130A/libs.tech/magic/sky130A.magicrc"
    }
    mag_import_fail "$why\nLog: $MAG_IMPORT(log)"
    return
  }
  if {![mag_gds_has_structs $gds]} {
    mag_import_fail "Magic wrote an empty GDS library (top cell not loaded).\nCheck the tech line of the .mag files against the PDK and the log:\n$MAG_IMPORT(log)"
    return
  }
  mag_log "Wrote $gds ([file size $gds] bytes) via Magic mag2gds"
  mag_progress_update 85 "Importing GDS into MAX as .max..."
  mag_import_open_max $gds $MAG_IMPORT(topcell) $MAG_IMPORT(tech) $MAG_IMPORT(outdir)
}

proc mag_gds_read_exact {gds} {
  global GDS_READ_NO_DRC GDS_READ_SNAP_TO GDS_READ_REPORT_ROUNDING_ERRORS
  global GDS_READ_PARTIAL
  set prev_drc 1
  set prev_snap 0
  set prev_rep 1
  set prev_part 0
  if {[info exists GDS_READ_NO_DRC]} { set prev_drc $GDS_READ_NO_DRC }
  if {[info exists GDS_READ_SNAP_TO]} { set prev_snap $GDS_READ_SNAP_TO }
  if {[info exists GDS_READ_REPORT_ROUNDING_ERRORS]} {
    set prev_rep $GDS_READ_REPORT_ROUNDING_ERRORS
  }
  if {[info exists GDS_READ_PARTIAL]} { set prev_part $GDS_READ_PARTIAL }
  # Default GDS_READ_NO_DRC is 1, which hides every violation until the
  # .max is opened again. This import checks DRC now, and does not snap.
  set GDS_READ_NO_DRC 0
  set GDS_READ_SNAP_TO 0
  set GDS_READ_REPORT_ROUNDING_ERRORS 1
  set GDS_READ_PARTIAL 0
  set rc [catch {set top [gds_read $gds]} err]
  set GDS_READ_NO_DRC $prev_drc
  set GDS_READ_SNAP_TO $prev_snap
  set GDS_READ_REPORT_ROUNDING_ERRORS $prev_rep
  set GDS_READ_PARTIAL $prev_part
  if {$rc} { error $err }
  return $top
}

proc mag_import_open_max {gds top tech outdir} {
  global MAG_IMPORT MN_TECH GDS_READ_PARTIAL

  set MAG_IMPORT(topcell) $top
  set MAG_IMPORT(tech) $tech
  set MAG_IMPORT(outdir) $outdir
  set family [mag_family_from_tech $tech]
  set magdir ""
  if {[info exists MAG_IMPORT(magdir)]} { set magdir $MAG_IMPORT(magdir) }

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
    if {[catch {set topCell [mag_gds_read_exact $gds]} err]} {
      if {[info exists GDS_READ_PARTIAL]} { set GDS_READ_PARTIAL $oldp }
      catch {cd $here}
      mag_import_fail "gds_read failed:\n$err\nGDS is at:\n$gds"
      return
    }
    if {[info exists GDS_READ_PARTIAL]} { set GDS_READ_PARTIAL $oldp }
    if {$topCell == ""} { set topCell $top }
    catch {cell_load $topCell}
    if {[mag_import_is_chip]} {
      mag_progress_update 95 "Drawing Caravel layout (this can take several minutes)..."
      mag_max_show_chip
      catch {cd $here}
      mag_import_finish_chip $topCell $tech $gds $outdir $magdir $family
      return
    }
    mag_max_show_converted
    mag_save_open $outdir $topCell
    if {[info exists MAG_IMPORT(preview)] && $MAG_IMPORT(preview)} {
      mag_stamp_preview_tree $outdir
    }
    set scan [mag_exact_scan_tree $outdir $family]
    if {$scan != ""} {
      catch {cd $here}
      mag_import_fail "Saved .max is not on the mask grid:\n$scan"
      return
    }
    catch {cell_load $topCell $outdir}
    catch {view_cell}
    catch {mag_close_hvi_gaps}
    # cell_load does not reread a cell already in memory, so cell_save
    # wrote the original label anchors back over the snapped file.
    mag_exact_snap_labels_tree $outdir $family
    set scan2 [mag_exact_scan_max [file join $outdir ${topCell}.max] \
        [mag_exact_mask_hnm $family]]
    if {$scan2 != ""} {
      catch {cd $here}
      mag_import_fail "Saved .max is not on the mask grid:\n$scan2"
      return
    }
    mag_flush_tree $outdir $topCell
    catch {view_cell}
    catch {:drc catchup}
    set drc_n [mag_import_drc_count]
    catch {cd $here}
    mag_open_in_magic $magdir $topCell $family
    mag_progress_close
    set store [mag_finish_storage $outdir $topCell]
    set msg "Magic design converted.\n\n\
Top cell: $topCell\n\
MAX technology: $tech\n\
GDS method: $MAG_IMPORT(method)\n\
Log: $MAG_IMPORT(log)\n\n\
$store"
    if {$drc_n != ""} {
      set msg "$msg\n\nDRC errors in this session: $drc_n"
    }
    if {[mag_want_gui]} {
      set msg "$msg\n\nMagic VLSI is also opening the original .mag for comparison."
    }
    set msg "$msg\n\nMAX instances are expanded (like Magic) so resistor and stdcell paint is visible."
    mag_import_tell $msg -copy
    return
  }

  mag_progress_update 92 "Starting MAX -tech $tech..."
  set maxbin max
  if {[info commands pdk_which] != ""} {
    set m [pdk_which {max}]
    if {$m != ""} { set maxbin $m }
  } else {
    set m [mag_which {max}]
    if {$m != ""} { set maxbin $m }
  }
  set script [file join $MAG_IMPORT(work) launch_max.sh]
  set aftertcl [file join $MAG_IMPORT(work) after_gds.tcl]
  if {[mag_import_is_chip]} {
    mag_max_after_chip_script $aftertcl $top
  } else {
    mag_max_after_gds_script $aftertcl $family $outdir $top
  }
  set fh [open $script w]
  puts $fh "#!/bin/sh"
  puts $fh "cd \"$outdir\" || exit 1"
  puts $fh "exec \"$maxbin\" -tech \"$tech\" -set GDS_READ_NO_DRC=0 -set GDS_READ_SNAP_TO=0 -set GDS_READ_REPORT_ROUNDING_ERRORS=1 -command \"source {$aftertcl}\" \"$gds\""
  close $fh
  catch {exec chmod +x $script}
  if {[catch {exec /bin/sh $script &} err]} {
    mag_progress_close
    mag_import_fail "Could not launch MAX:\n$err\nGDS is at:\n$gds"
    return
  }
  if {[mag_import_is_chip]} {
    mag_import_finish_chip $top $tech $gds $outdir $magdir $family
    return
  }
  mag_open_in_magic $magdir $top $family
  mag_progress_close
  set store [mag_finish_storage $outdir $top]
  set msg "Magic design converted.\n\n\
Top cell: $top\n\
Opened a new MAX with technology '$tech'.\n\
Log: $MAG_IMPORT(log)\n\n\
$store\n\n\
If the current MAX was started with a different PDK, that is expected:\n\
GDS→.max must use the destination technology."
  if {[mag_want_gui]} {
    set msg "$msg\n\nMagic VLSI is also opening the original .mag for comparison."
  }
  set msg "$msg\n\nMAX instances are expanded (like Magic) so resistor and stdcell paint is visible."
  mag_import_tell $msg -copy
}

proc mag_log_tail {{n 40}} {
  global MAG_IMPORT
  if {![info exists MAG_IMPORT(log)] || ![file readable $MAG_IMPORT(log)]} {
    return ""
  }
  if {[catch {set fh [open $MAG_IMPORT(log) r]}]} { return "" }
  set lines {}
  while {[gets $fh line] >= 0} {
    lappend lines $line
  }
  close $fh
  set start [expr {[llength $lines] - $n}]
  if {$start < 0} { set start 0 }
  return [join [lrange $lines $start end] \n]
}

proc mag_import_fail {msg} {
  global MAG_IMPORT
  mag_progress_close
  set tail [mag_log_tail 40]
  mag_log "ERROR: $msg"
  if {$tail != ""} {
    append msg "\n\nLast log lines:\n$tail"
  }
  mag_import_tell "Magic import failed.\n$msg" -copy
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
  if {$method == "die"} {
    set title "Caravel die GDS  →  MAX"
  } elseif {$method == "harness"} {
    set title "Caravel Magic harness  →  GDS  →  MAX"
  } elseif {$method == "mag2gds"} {
    set title "Magic mag2gds (tapeout)  →  MAX .max"
  } else {
    set title "Tcl paint dump (not tapeout)  →  MAX .max"
  }
  label $f.title -text $title
  pack $f.title -anchor w -pady 6
  label $f.stage -text "Starting..." -anchor w -width 64
  pack $f.stage -anchor w -fill x
  canvas $f.bar -width 420 -height 22 -bd 1 -relief sunken -highlightthickness 0
  pack $f.bar -fill x -pady 8
  $f.bar create rectangle 0 0 0 22 -fill #2a7ab0 -outline {} -tags fill
  $f.bar create text 210 11 -text "0%" -tags pct -fill white
  label $f.pctlab -text "0%" -anchor e
  pack $f.pctlab -anchor e
  frame $f.btns
  pack $f.btns -fill x -pady 8
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
  if {![mag_is_int $percent]} { set percent 0 }
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
