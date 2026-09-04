#!/usr/bin/env tclsh
# Build a loadable MAX .tech27 (+ companion .tcl) from a make_tech .source
# table. No make_tech, cpp, or m4 — those hang under nested MAX/Xvnc.
#
# Usage: source_to_tech27.tcl SOURCE TECH OUTDIR

if {[llength $argv] < 3} {
  puts stderr "usage: source_to_tech27.tcl SOURCE TECH OUTDIR"
  exit 1
}

set source_file [lindex $argv 0]
set tech [lindex $argv 1]
set outdir [lindex $argv 2]

if {![file readable $source_file]} {
  puts stderr "cannot read $source_file"
  exit 1
}

proc parse_gds_pair {s} {
  if {$s == "-" || $s == ""} { return "" }
  set parts [split $s :]
  set gds [lindex $parts 0]
  set dt [lindex $parts 1]
  if {$dt == ""} { set dt 0 }
  return [list $gds $dt]
}

# True only for a positive decimal (never "-" — Tcl expr treats "-" as unary minus).
proc is_pos_micron {v} {
  if {$v == "" || $v == "-"} { return 0 }
  if {![regexp {^[0-9]+(\.[0-9]+)?$} $v]} { return 0 }
  if {[catch {expr {$v > 0}} ok] || !$ok} { return 0 }
  return 1
}

# Map .source color field to "R G B" for pal_layer.
proc color_rgb {col fallback} {
  if {$col == "" || $col == "-"} { return $fallback }
  switch -exact -- [string tolower $col] {
    gold { return "255 215 0" }
    red { return "255 0 0" }
    green { return "0 200 0" }
    blue { return "0 0 255" }
    black { return "0 0 0" }
    white { return "255 255 255" }
  }
  if {[regexp {^([0-9]+),([0-9]+),([0-9]+)$} $col -> r g b]} {
    return "$r $g $b"
  }
  return $fallback
}

proc via_stipple {i} {
  set patterns {
    {00100000 00010000 00001000 00000100 00000010 00000001 10000000 01000000}
    {10101010 00000000 10101010 00000000 10101010 00000000 10101010 00000000}
    {01010101 00000000 01010101 00000000 01010101 00000000 01010101 00000000}
    {00000000 10101010 00000000 10101010 00000000 10101010 00000000 10101010}
    {00000000 01010101 00000000 01010101 00000000 01010101 00000000 01010101}
  }
  set n [llength $patterns]
  return [lindex $patterns [expr {$i % $n}]]
}

proc other_stipple {i} {
  set patterns {
    {01000000 10000000 00000001 00000010 00000100 00001000 00010000 00100000}
    {10001000 01000100 00100010 00010001 10001000 01000100 00100010 00010001}
    {00010001 00100010 01000100 10001000 00010001 00100010 01000100 10001000}
  }
  set n [llength $patterns]
  return [lindex $patterns [expr {$i % $n}]]
}

set layers {}
set connects {}
set devices {}
set text_layer ""
set bbox_layer ""
# Must be arrays (not scalars). "set gds_of {}" makes a string and breaks gds_of($name).
array set gds_of {}
array set txt_of {}
array set type_of {}
array set width_of {}
array set space_of {}
array set color_of {}

set fh [open $source_file r]
while {[gets $fh src_line] >= 0} {
  # Strip CR so Windows-synced checkouts still parse.
  set src_line [string trim [string trimright $src_line "\r"]]
  if {$src_line == ""} { continue }
  if {[string index $src_line 0] == "#"} { continue }

  set cmd [string tolower [lindex $src_line 0]]
  if {$cmd == "device"} {
    # device nfet from poly diff
    if {[llength $src_line] >= 5 && [string tolower [lindex $src_line 2]] == "from"} {
      lappend devices [list [lindex $src_line 1] [lindex $src_line 3] [lindex $src_line 4]]
    }
    continue
  }
  if {$cmd == "connect"} {
    lappend connects [list [lindex $src_line 1] [lindex $src_line 2]]
    continue
  }
  if {$cmd == "derive" || $cmd == "drc" || $cmd == "set" || \
      $cmd == "preserve_ports" || $cmd == "square_vias"} {
    continue
  }

  # layer gds txt type width space color
  set name [lindex $src_line 0]
  set gds [lindex $src_line 1]
  set txt [lindex $src_line 2]
  set typ [lindex $src_line 3]
  set wid [lindex $src_line 4]
  set spc [lindex $src_line 5]
  set col [lindex $src_line 6]
  if {$name == "" || $name == "-"} { continue }
  if {$gds == ""} { set gds "-" }
  if {$txt == ""} { set txt "-" }
  if {$typ == ""} { set typ "-" }
  if {$wid == ""} { set wid "-" }
  if {$spc == ""} { set spc "-" }
  if {$col == ""} { set col "-" }

  set typ_l [string tolower $typ]
  if {$typ_l == "text"} {
    set text_layer $name
    set gds_of($name) $gds
    set txt_of($name) $txt
    continue
  }
  if {$typ_l == "bbox"} {
    set bbox_layer $name
    set gds_of($name) $gds
    set txt_of($name) $txt
    continue
  }

  lappend layers $name
  set gds_of($name) $gds
  set txt_of($name) $txt
  set type_of($name) $typ_l
  set width_of($name) $wid
  set space_of($name) $spc
  set color_of($name) $col
}
close $fh

if {![llength $layers]} {
  puts stderr "no layers in $source_file"
  exit 1
}

file mkdir $outdir

# Planes / types
set planes {}
set types {}
set act_layers {}
set poly_layers {}
set via_layers {}
set metal_layers {}
set other_layers {}
set has_active 0

foreach name $layers {
  set typ $type_of($name)
  if {$typ == "act" || $typ == "active" || $typ == "poly"} {
    if {!$has_active} {
      lappend planes active
      set has_active 1
    }
    lappend types [list active $name]
    if {$typ == "poly"} {
      lappend poly_layers $name
    } else {
      lappend act_layers $name
    }
  } elseif {$typ == "via" || $typ == "metal"} {
    lappend planes $name
    lappend types [list $name $name]
    if {$typ == "via"} {
      lappend via_layers $name
    } else {
      lappend metal_layers $name
    }
  } else {
    lappend planes $name
    lappend types [list $name $name]
    lappend other_layers $name
  }
}

foreach d $devices {
  set dname [lindex $d 0]
  # device paint types live on active plane
  if {!$has_active} {
    lappend planes active
    set has_active 1
  }
  set found 0
  foreach t $types {
    if {[lindex $t 1] == $dname} { set found 1; break }
  }
  if {!$found} {
    lappend types [list active $dname]
  }
}

set tech27 [file join $outdir ${tech}.tech27]
set fh [open $tech27 w]

puts $fh "tech"
puts $fh "\t$tech"
puts $fh "end"
puts $fh ""
puts $fh "version"
puts $fh "\tversion \"$tech (mmi-pdk)\""
puts $fh "\tdescription \"$tech\""
puts $fh "end"
puts $fh ""
puts $fh "planes"
foreach p $planes {
  puts $fh "\t$p"
}
puts $fh "end"
puts $fh ""
puts $fh "types"
foreach t $types {
  puts $fh "\t[lindex $t 0]\t[lindex $t 1]"
}
puts $fh "end"
puts $fh ""
puts $fh "contact"
puts $fh "end"
puts $fh ""
puts $fh "styles"
puts $fh "end"
puts $fh ""
puts $fh "compose"
foreach d $devices {
  puts $fh "\tcompose [lindex $d 0] [lindex $d 1] [lindex $d 2]"
}
puts $fh "end"
puts $fh ""
puts $fh "connect"
foreach c $connects {
  puts $fh "\t[lindex $c 0]\t[lindex $c 1]"
}
foreach d $devices {
  puts $fh "\t[lindex $d 0]\t[lindex $d 1]"
}
puts $fh "end"
puts $fh ""

# cifoutput
puts $fh "cifoutput"
puts $fh "style $tech"
puts $fh ""
puts $fh "\tunits .001 .001 .001 .001"
puts $fh "\tcharset unrestricted"
puts $fh ""
if {$bbox_layer != "" && [info exists gds_of($bbox_layer)]} {
  set pr [parse_gds_pair $gds_of($bbox_layer)]
  if {$pr != ""} {
    puts $fh "\tbbox [lindex $pr 0] [lindex $pr 1]"
  }
}
puts $fh ""

foreach name $layers {
  set gds $gds_of($name)
  if {$gds == "-" || $gds == "derived"} continue
  set pr [parse_gds_pair $gds]
  if {$pr == ""} continue
  set gnum [lindex $pr 0]
  set gdt [lindex $pr 1]
  set paint $name
  foreach d $devices {
    if {[lindex $d 1] == $name || [lindex $d 2] == $name} {
      append paint ",[lindex $d 0]"
    }
  }
  puts $fh "\tlayer GDS_$name $paint"
  puts $fh "\tpolygons $paint"
  set txt $txt_of($name)
  if {$txt != "-" && $txt != ""} {
    puts $fh "\tcalma $gnum $gdt"
    puts $fh ""
    set tpr [parse_gds_pair $txt]
    if {$tpr != ""} {
      puts $fh "\tlayer TXT_$name"
      puts $fh "\tlabels $paint"
      puts $fh "\tcalma [lindex $tpr 0] [lindex $tpr 1]"
    }
  } else {
    puts $fh "\tlabels $paint"
    puts $fh "\tcalma $gnum $gdt"
  }
  puts $fh ""
}

# Text labels use Magic/MAX "space" plane — never "labels *"
if {$text_layer != ""} {
  set tsrc $txt_of($text_layer)
  if {$tsrc == "-" || $tsrc == ""} { set tsrc $gds_of($text_layer) }
  set tpr [parse_gds_pair $tsrc]
  if {$tpr != ""} {
    puts $fh "\tlayer TXT_$text_layer"
    puts $fh "\tlabels space"
    puts $fh "\tcalma [lindex $tpr 0] [lindex $tpr 1]"
    puts $fh ""
  }
}
puts $fh "end"
puts $fh ""

# cifinput
puts $fh "cifinput"
puts $fh "style\t$tech"
puts $fh ""
if {$bbox_layer != "" && [info exists gds_of($bbox_layer)]} {
  set pr [parse_gds_pair $gds_of($bbox_layer)]
  if {$pr != ""} {
    puts $fh "\tbbox [lindex $pr 0] [lindex $pr 1]"
  }
}
puts $fh ""
foreach name $layers {
  set gds $gds_of($name)
  if {$gds == "-" || $gds == "derived"} continue
  puts $fh "\tlayer $name GDS_$name"
  set txt $txt_of($name)
  if {$txt != "-" && $txt != ""} {
    puts $fh "\tlabels TXT_$name"
  } else {
    puts $fh "\tlabels GDS_$name"
  }
  puts $fh ""
}
foreach name $layers {
  set gds $gds_of($name)
  if {$gds == "-" || $gds == "derived"} continue
  set pr [parse_gds_pair $gds]
  if {$pr == ""} continue
  puts $fh "\tcalma GDS_$name\t[lindex $pr 0] *"
  set txt $txt_of($name)
  if {$txt != "-" && $txt != ""} {
    set tpr [parse_gds_pair $txt]
    if {$tpr != ""} {
      puts $fh "\tcalma TXT_$name\t[lindex $tpr 0] *"
    }
  }
}
if {$text_layer != ""} {
  set tsrc $txt_of($text_layer)
  if {$tsrc == "-" || $tsrc == ""} { set tsrc $gds_of($text_layer) }
  set tpr [parse_gds_pair $tsrc]
  if {$tpr != ""} {
    puts $fh "\tlayer space"
    puts $fh "\tlabels TXT_$text_layer"
    puts $fh "\tcalma TXT_$text_layer\t[lindex $tpr 0] *"
  }
}
puts $fh "end"
puts $fh ""

puts $fh "mzrouter"
puts $fh "end"
puts $fh ""

# cifstyle belongs inside drc (not a top-level section)
puts $fh "drc"
puts $fh "cifstyle $tech"
puts $fh ""
foreach name $layers {
  set w $width_of($name)
  set s $space_of($name)
  # Do NOT use expr to validate: "expr - + 0" succeeds, so "-" was emitted.
  if {[is_pos_micron $w]} {
    puts $fh "\twidth $name $w \\"
    puts $fh "\t\t\"$name minimum width = $w um.\""
    puts $fh ""
  }
  if {[is_pos_micron $s]} {
    puts $fh "\tspacing $name $name $s touching_ok \\"
    puts $fh "\t\t\"$name minimum spacing = $s um.\""
    puts $fh ""
  }
}
if {[llength $devices]} {
  set dnames {}
  foreach d $devices { lappend dnames [lindex $d 0] }
  puts $fh "\tno_overlap\t[join $dnames ,]\t[join $dnames ,]"
  puts $fh ""
}
if {[llength $via_layers]} {
  puts $fh "\texact_overlap\t[join $via_layers ,]"
  puts $fh ""
}
puts $fh "end"
puts $fh ""

puts $fh "extract"
puts $fh "style\t$tech"
puts $fh "\tnoplaneordering"
puts $fh ""
puts $fh "\tcscale\t1"
puts $fh "\tlambda\t1"
puts $fh "\tstep\t1000"
puts $fh "\tsidehalo\t0"
puts $fh ""
foreach name $metal_layers {
  puts $fh "\tresist $name 115"
  puts $fh "\tareacap $name 0.0001"
  puts $fh "\tperimc $name space/$name 0.1"
  puts $fh ""
}
foreach d $devices {
  set dname [lindex $d 0]
  set act [lindex $d 2]
  set bulk GND!
  if {[string match {p*} [string tolower $dname]]} { set bulk Vdd! }
  puts $fh "\tfet $dname $act 2 $dname $bulk 0 0"
}
puts $fh ""
puts $fh "end"

close $fh

# Companion .tcl — brace list values; [list a b] inside "" drops braces.
set tclf [file join $outdir ${tech}.tcl]
set fh [open $tclf w]
puts $fh "# $tech.tcl — generated by source_to_tech27.tcl"
puts $fh "set MAKE_TECH_VERSION 1"
puts $fh "set MN_TYPICAL_WIRE_WIDTH 0.3"
set layer_order {}
foreach name [concat $metal_layers $via_layers $poly_layers $act_layers $other_layers] {
  lappend layer_order $name
}
foreach d $devices {
  lappend layer_order [lindex $d 0]
}
puts $fh "set DRC_DATA(layer_order) {$layer_order}"
if {[llength $via_layers]} {
  puts $fh "set DRC_DATA(vias) {$via_layers}"
}
foreach name $metal_layers {
  puts $fh "set DRC_DATA(connect,$name) {}"
}
foreach c $connects {
  set a [lindex $c 0]
  set b [lindex $c 1]
  puts $fh "set DRC_DATA(connect,$a) {$b}"
}
foreach d $devices {
  set dn [lindex $d 0]
  set g [lindex $d 1]
  set a [lindex $d 2]
  puts $fh "set DRC_DATA(device,fet,$dn) {$g $a}"
}
close $fh

# Palette — MAX aborts without ${tech}.palette
set palf [file join $outdir ${tech}.palette]
set fh [open $palf w]
puts $fh "# Palette for $tech — generated by source_to_tech27.tcl"
puts $fh ""
set vi 0
set oi 0
if {[llength $metal_layers] || [llength $via_layers]} {
  puts $fh "pal_add_group metal"
  # Top-down: vias then metals (display order similar to make_tech)
  set emit {}
  set nmet [llength $metal_layers]
  set nvia [llength $via_layers]
  for {set i [expr {$nvia - 1}]} {$i >= 0} {incr i -1} {
    lappend emit [lindex $via_layers $i]
  }
  for {set i [expr {$nmet - 1}]} {$i >= 0} {incr i -1} {
    lappend emit [lindex $metal_layers $i]
  }
  foreach name $emit {
    set typ $type_of($name)
    set rgb [color_rgb $color_of($name) "128 128 128"]
    if {$typ == "via"} {
      set pat [via_stipple $vi]
      incr vi
      puts $fh "pal_layer $name {$rgb} {stipple outline"
      foreach row $pat {
        puts $fh "\t$row"
      }
      puts $fh "}"
    } else {
      puts $fh "pal_layer $name {$rgb} solid"
    }
  }
  puts $fh ""
}
if {[llength $poly_layers] || [llength $act_layers] || [llength $devices]} {
  puts $fh "pal_add_group active"
  foreach name $poly_layers {
    set rgb [color_rgb $color_of($name) "236 67 0"]
    puts $fh "pal_layer $name {$rgb} solid"
  }
  foreach d $devices {
    puts $fh "pal_compose [lindex $d 0] [lindex $d 1] [lindex $d 2]"
  }
  foreach name $act_layers {
    set rgb [color_rgb $color_of($name) "110 110 110"]
    puts $fh "pal_layer $name {$rgb} solid"
  }
  puts $fh ""
}
if {[llength $other_layers]} {
  puts $fh "pal_add_group other"
  foreach name $other_layers {
    set rgb [color_rgb $color_of($name) "100 100 100"]
    set pat [other_stipple $oi]
    incr oi
    puts $fh "pal_layer $name {$rgb} {stipple"
    foreach row $pat {
      puts $fh "\t$row"
    }
    puts $fh "}"
  }
  puts $fh ""
}
close $fh

# Also leave a .tech (same content) for tooling that looks for it
catch {file copy -force $tech27 [file join $outdir ${tech}.tech]}

puts "wrote $tech27 ([file size $tech27] bytes), $tclf, $palf"
exit 0
