if {![info exists PDK_SOURCE_REV]} { set PDK_SOURCE_REV 5 }

# Layer tables and .source writer for the importer.
# Read by source_to_tech27.tcl via the .source file this writes.
# Tcl 8.0 safe so compile_tech.sh can run it under either tclsh.

proc pdk_layers_sky130A {} {
  return {
    {nwell 64:20 64:5,16 - 0.84 1.27 0,160,0}
    {pwell 64:13 64:59 - - - 210,130,110}
    {dnwell 64:18 - - 3.0 6.3 0,100,0}
    {diff 65:20 65:6,16 gdsonly 0.15 0.27 -}
    {tap 65:44 65:5,48 gdsonly 0.15 0.27 -}
    {diffres 65:13 - - - - 80,160,80}
    {ndiff derived - act 0.15 0.27 66,213,66}
    {pdiff derived - act 0.15 0.27 202,160,115}
    {ntap derived - act 0.15 0.27 120,200,120}
    {ptap derived - act 0.15 0.27 200,170,140}
    {nsdm 93:44 - - 0.38 0.38 0,200,200}
    {psdm 94:20 - - 0.38 0.38 200,0,200}
    {poly 66:20 66:5,16 poly 0.15 0.21 236,67,0}
    {polyres 66:13 - - 0.35 0.21 220,80,120}
    {polyshort 66:15 - - - - 200,100,70}
    {npc 95:20 - - 0.27 0.27 160,80,0}
    {licon1 66:44 - via 0.17 0.17 80,80,80}
    {li1 67:20 67:5,16 metal 0.17 0.17 8,139,255}
    {mcon 67:44 - via 0.17 0.19 90,90,90}
    {met1 68:20 68:5,16 metal 0.14 0.14 182,134,222}
    {via1 68:44 - via 0.15 0.17 100,100,100}
    {met2 69:20 69:5,16 metal 0.14 0.14 255,160,65}
    {via2 69:44 - via 0.2 0.2 110,110,110}
    {met3 70:20 70:5,16 metal 0.3 0.3 61,122,188}
    {via3 70:44 - via 0.2 0.2 120,120,120}
    {met4 71:20 71:5,16 metal 0.3 0.3 200,80,80}
    {via4 71:44 - via 0.8 0.8 130,130,130}
    {met5 72:20 72:5,16 metal 1.6 1.6 gold}
    {capm 89:44 - - 1.0 0.84 180,180,80}
    {cap2m 97:44 - - 1.0 0.84 200,200,80}
    {hvi 75:20 - - 0.6 0.7 0,80,160}
    {hvntm 125:20 - - 0.7 0.7 0,120,160}
    {lvtn 125:44 - - 0.38 0.38 120,120,200}
    {hvtp 78:44 - - 0.38 0.38 200,120,120}
    {tunm 80:20 - - - - 160,160,60}
    {rpm 86:20 - - - - 180,70,140}
    {urpm 79:20 - - - - 200,90,150}
    {pad 76:20 - - - - 200,200,200}
    {areaid_sl 81:4 - - - - 90,90,90}
    {prBoundary 235:4 - bbox - - -}
    {text - 83:44 text - - -}
  }
}

proc pdk_rules_sky130A {} {
  return {
    "device nfet from poly ndiff"
    "device pfet from poly pdiff"
    ""
    "connect licon1 poly,ndiff,pdiff,ntap,ptap,li1"
    "connect mcon li1,met1"
    "connect via1 met1,met2"
    "connect via2 met2,met3"
    "connect via3 met3,met4"
    "connect via4 met4,met5"
    ""
    "# GDS out: typed diffusion -> diff/tap; implants from diffusion (0.125 enclosure) or drawn"
    "derive diff from ndiff,pdiff"
    "derive tap from ntap,ptap"
    "derive nsdm from ndiff,ntap grow 0.125 or nsdm"
    "derive psdm from pdiff,ptap grow 0.125 or psdm"
    "# GDS in: diff/tap typed by the psdm implant (everything else is n-type)"
    "derive ndiff from diff and-not psdm"
    "derive pdiff from diff and psdm"
    "derive ntap from tap and-not psdm"
    "derive ptap from tap and psdm"
    ""
    "# pin datatypes (Magic/KLayout \"port\" texts) read as ports and written back as pins"
    "port inout 64:16"
    "port inout 65:16"
    "port inout 65:48"
    "port inout 66:16"
    "port inout 67:16"
    "port inout 68:16"
    "port inout 69:16"
    "port inout 70:16"
    "port inout 71:16"
    "port inout 72:16"
    ""
    "square_vias"
    "set GRID(resolution) 0.005"
    "set GRID(mask) 0.005"
    "set LAYER_NAME(ndiff) ndiff"
    "set LAYER_NAME(pdiff) pdiff"
    "set LAYER_NAME(nplus) nsdm"
    "set LAYER_NAME(pplus) psdm"
    "set LAYER_NAME(nwell) nwell"
    "set LAYER_NAME(poly) poly"
    "set LAYER_NAME(contact) licon1"
  }
}

proc pdk_layers_gf180mcu {} {
  return {
    {nwell 21:0 21:10 - 0.86 0.6 0,160,0}
    {dnwell 12:0 - - 1.7 2.5 0,100,0}
    {comp 22:0 22:10 gdsonly 0.3 0.28 -}
    {ndiff derived - act 0.3 0.28 66,213,66}
    {pdiff derived - act 0.3 0.28 202,160,115}
    {ntap derived - act 0.3 0.28 120,200,120}
    {ptap derived - act 0.3 0.28 200,170,140}
    {nplus 32:0 - - 0.4 0.4 0,200,200}
    {pplus 31:0 - - 0.4 0.4 200,0,200}
    {poly2 30:0 30:10 poly 0.18 0.24 236,67,0}
    {dualgate 55:0 - - 0.7 0.44 0,80,160}
    {sab 49:0 - - - - 160,60,160}
    {esd 24:0 - - - - 120,60,160}
    {contact 33:0 - via 0.22 0.25 80,80,80}
    {metal1 34:0 34:10 metal 0.23 0.23 8,139,255}
    {via1 35:0 - via 0.26 0.26 90,90,90}
    {metal2 36:0 36:10 metal 0.28 0.28 182,134,222}
    {via2 38:0 - via 0.26 0.26 100,100,100}
    {metal3 42:0 42:10 metal 0.28 0.28 255,160,65}
    {via3 40:0 - via 0.26 0.26 110,110,110}
    {metal4 46:0 46:10 metal 0.28 0.28 61,122,188}
    {via4 41:0 - via 0.26 0.26 120,120,120}
    {metal5 81:0 81:10 metal 0.44 0.46 gold}
    {pr_bndry 63:0 - bbox - - -}
  }
}

proc pdk_rules_gf180mcu {} {
  return {
    "device nfet from poly2 ndiff"
    "device pfet from poly2 pdiff"
    ""
    "connect contact poly2,ndiff,pdiff,ntap,ptap,metal1"
    "connect via1 metal1,metal2"
    "connect via2 metal2,metal3"
    "connect via3 metal3,metal4"
    "connect via4 metal4,metal5"
    ""
    "# GDS out: all typed diffusion on COMP; implants from diffusion (0.16 enclosure) or drawn"
    "derive comp from ndiff,pdiff,ntap,ptap"
    "derive nplus from ndiff,ntap grow 0.16 or nplus"
    "derive pplus from pdiff,ptap grow 0.16 or pplus"
    "# GDS in: COMP split by Pplus and Nwell (no separate tap layer in GF180)"
    "derive ndiff from comp and-not pplus and-not nwell"
    "derive pdiff from comp and pplus and nwell"
    "derive ntap from comp and-not pplus and nwell"
    "derive ptap from comp and pplus and-not nwell"
    ""
    "square_vias"
    "set GRID(resolution) 0.005"
    "set GRID(mask) 0.005"
    "set LAYER_NAME(ndiff) ndiff"
    "set LAYER_NAME(pdiff) pdiff"
    "set LAYER_NAME(nplus) nplus"
    "set LAYER_NAME(pplus) pplus"
    "set LAYER_NAME(nwell) nwell"
    "set LAYER_NAME(poly) poly2"
    "set LAYER_NAME(contact) contact"
  }
}

proc pdk_layers_sg13g2 {} {
  return {
    {Activ 1:0 1:25 gdsonly 0.15 0.21 -}
    {ndiff derived - act 0.15 0.21 66,213,66}
    {pdiff derived - act 0.15 0.21 202,160,115}
    {ntap derived - act 0.15 0.21 120,200,120}
    {ptap derived - act 0.15 0.21 200,170,140}
    {GatPoly 5:0 5:25 poly 0.13 0.18 236,67,0}
    {NWell 31:0 31:25 - 0.62 0.62 0,160,0}
    {nSD 7:0 - - 0.31 0.31 0,200,200}
    {pSD 14:0 - - 0.31 0.31 200,0,200}
    {ThickGateOx 44:0 - - - - 0,80,160}
    {SalBlock 28:0 - - - - 160,60,160}
    {Cont 6:0 - via 0.16 0.18 80,80,80}
    {Metal1 8:0 8:25,2 metal 0.16 0.18 8,139,255}
    {Via1 19:0 - via 0.19 0.22 90,90,90}
    {Metal2 10:0 10:25,2 metal 0.2 0.21 182,134,222}
    {Via2 29:0 - via 0.19 0.22 100,100,100}
    {Metal3 30:0 30:25,2 metal 0.2 0.21 255,160,65}
    {Via3 49:0 - via 0.19 0.22 110,110,110}
    {Metal4 50:0 50:25,2 metal 0.2 0.21 61,122,188}
    {Via4 66:0 - via 0.19 0.22 120,120,120}
    {Metal5 67:0 67:25,2 metal 0.2 0.21 100,180,220}
    {TopVia1 125:0 - via 0.42 0.42 130,130,130}
    {TopMetal1 126:0 126:25,2 metal 1.64 1.64 gold}
    {TopVia2 133:0 - via 0.9 1.06 140,140,140}
    {TopMetal2 134:0 134:25,2 metal 2.0 2.0 220,180,60}
    {MIM 36:0 - - - - 180,180,80}
    {Passiv 9:0 - - - - 200,200,200}
    {prBoundary 189:4 - bbox - - -}
    {TEXT - 63:0 text - - -}
  }
}

proc pdk_rules_sg13g2 {} {
  return {
    "device nfet from GatPoly ndiff"
    "device pfet from GatPoly pdiff"
    ""
    "connect Cont GatPoly,ndiff,pdiff,ntap,ptap,Metal1"
    "connect Via1 Metal1,Metal2"
    "connect Via2 Metal2,Metal3"
    "connect Via3 Metal3,Metal4"
    "connect Via4 Metal4,Metal5"
    "connect TopVia1 Metal5,TopMetal1"
    "connect TopVia2 TopMetal1,TopMetal2"
    ""
    "# GDS out: all typed diffusion on Activ; pSD from p-type diffusion (0.18 enclosure) or drawn"
    "derive Activ from ndiff,pdiff,ntap,ptap"
    "derive pSD from pdiff,ptap grow 0.18 or pSD"
    "# GDS in: Activ is n-type unless covered by pSD; NWell picks tap vs. diffusion"
    "derive ndiff from Activ and-not pSD and-not NWell"
    "derive pdiff from Activ and pSD and NWell"
    "derive ntap from Activ and-not pSD and NWell"
    "derive ptap from Activ and pSD and-not NWell"
    ""
    "# .pin texts (datatype 2) are ports; .text (25) stay plain labels"
    "port inout 8:2"
    "port inout 10:2"
    "port inout 30:2"
    "port inout 50:2"
    "port inout 67:2"
    "port inout 126:2"
    "port inout 134:2"
    ""
    "square_vias"
    "set GRID(resolution) 0.005"
    "set GRID(mask) 0.005"
    "set LAYER_NAME(ndiff) ndiff"
    "set LAYER_NAME(pdiff) pdiff"
    "set LAYER_NAME(pplus) pSD"
    "set LAYER_NAME(nwell) NWell"
    "set LAYER_NAME(poly) GatPoly"
    "set LAYER_NAME(contact) Cont"
  }
}

proc pdk_family_layers {family} {
  switch -exact -- $family {
    sky130A { return [pdk_layers_sky130A] }
    gf180mcu { return [pdk_layers_gf180mcu] }
    sg13g2 { return [pdk_layers_sg13g2] }
  }
  return {}
}

proc pdk_family_rules {family} {
  switch -exact -- $family {
    sky130A { return [pdk_rules_sky130A] }
    gf180mcu { return [pdk_rules_gf180mcu] }
    sg13g2 { return [pdk_rules_sg13g2] }
  }
  return {}
}

proc pdk_write_source {family tech path {rows {}} {rules {}}} {
  global PDK_SOURCE_REV
  if {![llength $rows]} { set rows [pdk_family_layers $family] }
  if {![llength $rows]} { return 0 }
  if {![llength $rules]} { set rules [pdk_family_rules $family] }
  if {![llength $rules]} { set rules [pdk_connect_lines $rows] }
  catch {file mkdir [file dirname $path]}
  set fh [open $path w]
  puts $fh "# MAX technology source generated by the importer"
  puts $fh "# family $family"
  puts $fh "# source-rev $PDK_SOURCE_REV"
  puts $fh ""
  puts $fh "# layer\tgds:dt\ttxt:dt\ttype\twidth\tspace\tcolor"
  puts $fh "#======\t======\t======\t====\t=====\t=====\t====="
  foreach rec $rows {
    puts $fh [join $rec "\t"]
  }
  puts $fh ""
  foreach line $rules {
    puts $fh $line
  }
  close $fh
  return [llength $rows]
}

proc pdk_connect_lines {rows} {
  set metals {}
  set vias {}
  set poly {}
  set acts {}
  foreach rec $rows {
    set name [lindex $rec 0]
    set typ [lindex $rec 3]
    if {$typ == "metal"} {
      lappend metals $name
    } elseif {$typ == "via"} {
      lappend vias $name
    } elseif {$typ == "poly"} {
      lappend poly $name
    } elseif {$typ == "act"} {
      lappend acts $name
    }
  }
  set lines {}
  if {[llength $poly] && [llength $acts]} {
    lappend lines "device nfet from [lindex $poly 0] [lindex $acts 0]"
    if {[llength $acts] > 1} {
      lappend lines "device pfet from [lindex $poly 0] [lindex $acts 1]"
    } else {
      lappend lines "device pfet from [lindex $poly 0] [lindex $acts 0]"
    }
  }
  set stack {}
  if {[llength $poly]} {
    lappend stack [lindex $poly 0]
  } elseif {[llength $acts]} {
    lappend stack [lindex $acts 0]
  }
  set stack [concat $stack $metals]
  set vi 0
  for {set i 0} {$i < [expr {[llength $stack] - 1}]} {incr i} {
    if {$vi < [llength $vias]} {
      lappend lines "connect [lindex $vias $vi] [lindex $stack $i],[lindex $stack [expr {$i + 1}]]"
      incr vi
    }
  }
  return $lines
}

proc pdk_guess_type {name} {
  # Whole-name globs only: "MET1PIN" / "DIFFMASK" must not become metal/act.
  set n [string tolower $name]
  switch -glob -- $n {
    text - comment { return text }
    bbox - prb - prboundary - pr_bndry - areaid* { return bbox }
    via - via[0-9] - via[0-9][0-9] - cont - contact - ct - \
    licon - licon[0-9] - mcon - ncon - pcon - topvia* { return via }
    poly - poly[0-9] - poly2 - gatpoly - gpoly - gate { return poly }
    diff - ndiff - pdiff - ndif - pdif - activ - active - \
    nsd - psd - ntap - ptap - comp - od { return act }
    metal[0-9] - metal[0-9][0-9] - met[0-9] - met[0-9][0-9] - \
    m[0-9] - m[0-9][0-9] - li[0-9] - li1 - locali - topmetal* { return metal }
  }
  return "-"
}

proc pdk_parse_magic_tech {path} {
  set rows {}
  set seen {}
  if {[catch {set fh [open $path r]}]} { return $rows }
  set current ""
  set section ""
  while {[gets $fh line] >= 0} {
    set toks [pdk_words $line]
    set cmd [lindex $toks 0]
    if {$cmd == "cifoutput" || $cmd == "cifinput" || $cmd == "drc" || \
        $cmd == "extract" || $cmd == "end"} {
      if {$cmd != "end"} { set section $cmd }
      set current ""
      continue
    }
    if {$section != "cifoutput"} continue
    if {$cmd == "layer" && [llength $toks] >= 2} {
      set current [lindex $toks 1]
      continue
    }
    if {$current != "" && $cmd == "calma" && [llength $toks] >= 3} {
      set l [lindex $toks 1]
      set d [lindex $toks 2]
      if {[pdk_is_int $l] && [pdk_is_int $d]} {
        set name [pdk_sanitize $current]
        set low [string tolower $name]
        # Drawing layers only. PIN/TXT/MASK/FILL overlays blow MAX's 127-type cap.
        set skip 0
        foreach suf {pin txt mask fill block norcx} {
          set n [string length $low]
          set s [string length $suf]
          if {$n > $s && [string range $low [expr {$n - $s}] end] == $suf} {
            set skip 1
            break
          }
        }
        if {!$skip && [lsearch -exact $seen $name] < 0} {
          lappend seen $name
          lappend rows [list $name "$l:$d" - [pdk_guess_type $name] - - -]
        }
      }
      set current ""
    }
  }
  close $fh
  return $rows
}

