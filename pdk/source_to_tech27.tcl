#!/usr/bin/env tclsh
# Build a loadable MAX .tech27 (+ companion .tcl and .palette) from a
# make_tech-style .source table.  No make_tech, cpp or m4 (those hang under
# nested MAX / Xvnc) and nothing newer than Tcl 8.0, so this runs under the
# system tclsh as well as MAX's own mmi_tclsh.
#
# Usage: source_to_tech27.tcl SOURCE TECH OUTDIR
#
# .source layer table:   name  gds:dt  txt:dt[,dt2..]  type  width  space  color
#   gds    L:D       GDS layer/datatype of the drawn paint
#          derived   paint type built from GDS layers on input; needs a
#                    "derive NAME from ..." whose operands carry GDS numbers
#          -         MAX-only paint type (never written to / read from GDS)
#   txt    L:D[,D2]  GDS text layer(s) whose labels attach to this paint.
#                    Output uses the first datatype, input accepts all.
#   type   act poly via metal - text bbox gdsonly
#          gdsonly = CIF layer only (no MAX paint type). Written from its
#          "derive NAME from paint,..." and read by derived paint types.
#   width/space   minimum width / spacing in microns, or -
#
# Statements:
#   device nfet from poly ndiff
#   connect licon1 poly,ndiff,li1           (electrical connectivity)
#   derive NAME from A[,B] [and|and-not|or X[,Y]] [grow d] [shrink d] ...
#       NAME derived paint   -> cifinput ops (GDS operands, boolean only)
#       NAME gdsonly or L:D  -> cifoutput ops (paint operands, microns)
#   square_vias           write via paint as "squares" (width/space needed)
#   port KIND L:D[,D2]    GDS texts on L:D are KIND labels (input output inout
#                         local global comment hidden); KIND labels are written
#                         back to L:D (sky130 pins = datatype 16)
#   set VAR value         copied verbatim into TECH.tcl (LAYER_NAME, GRID)
#   drc ... / preserve_ports / iname   accepted and ignored

# Bump when the emitted files change; pdk_import.tcl re-converts older techs.
set GEN_REV 6

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

set nwarn 0
proc warn {msg} {
  global nwarn
  incr nwarn
  puts stderr "source_to_tech27: warning: $msg"
}

# Tcl 8.0 regexp has no \d, \s or [ \t] classes: test characters directly.
proc is_digits {s} {
  if {$s == ""} { return 0 }
  set n [string length $s]
  for {set i 0} {$i < $n} {incr i} {
    if {[string first [string index $s $i] 0123456789] < 0} { return 0 }
  }
  return 1
}

# True only for a positive decimal such as 0.15 or 2 (never "-": Tcl expr
# would accept "- + 0", which is how "width foo -" once reached MAX).
proc is_pos_num {v} {
  if {$v == "" || $v == "-"} { return 0 }
  set parts [split $v .]
  if {[llength $parts] > 2} { return 0 }
  set ip [lindex $parts 0]
  set fp [lindex $parts 1]
  if {$ip == "" && $fp == ""} { return 0 }
  if {$ip != "" && ![is_digits $ip]} { return 0 }
  if {$fp != "" && ![is_digits $fp]} { return 0 }
  if {[catch {expr {double($v) > 0}} ok] || !$ok} { return 0 }
  return 1
}

# MAX reads dimensions without a '.' as database units; microns need one.
proc um {v} {
  if {[string first . $v] < 0} { return "$v.0" }
  if {[string index $v 0] == "."} { return "0$v" }
  return $v
}

proc split_ws {s} {
  set out {}
  foreach w [split $s " \t"] {
    if {$w != ""} { lappend out $w }
  }
  return $out
}

# "65:20" -> {65 20}; "65:5,16" -> {65 5,16}; "65" -> {65 0}; "-" -> ""
proc parse_gds_pair {s} {
  if {$s == "-" || $s == "" || $s == "derived"} { return "" }
  set parts [split $s :]
  if {[llength $parts] > 2} { return "" }
  set l [lindex $parts 0]
  set d [lindex $parts 1]
  if {$d == ""} { set d 0 }
  if {![is_digits $l]} { return "" }
  foreach x [split $d ,] {
    if {![is_digits $x]} { return "" }
  }
  return [list $l $d]
}

proc first_dt {dts} {
  return [lindex [split $dts ,] 0]
}

proc uniq_join {items} {
  set out {}
  foreach x $items {
    if {$x == ""} continue
    if {[lsearch -exact $out $x] < 0} { lappend out $x }
  }
  return [join $out ,]
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
  set parts [split $col ,]
  if {[llength $parts] == 3 && [is_digits [lindex $parts 0]] && \
      [is_digits [lindex $parts 1]] && [is_digits [lindex $parts 2]]} {
    return [join $parts " "]
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
    {10000001 01000010 00100100 00011000 00011000 00100100 01000010 10000001}
    {00011000 00100100 00100100 00011000 00000000 00000000 00000000 00000000}
    {11111111 00000000 11111111 00000000 11111111 00000000 11111111 00000000}
    {11001100 11001100 00110011 00110011 11001100 11001100 00110011 00110011}
    {10101010 01010101 10101010 01010101 10101010 01010101 10101010 01010101}
  }
  set n [llength $patterns]
  return [lindex $patterns [expr {$i % $n}]]
}

# Write one pal_layer. MAX allows 10 "solid" paints (colors.tcl); extra
# metals / taps must be stippled or MAX aborts during pal_build.
proc pal_put {fh name rgb solid} {
  global oi
  if {$solid} {
    puts $fh "pal_layer $name {$rgb} solid"
    return
  }
  set pat [other_stipple $oi]
  incr oi
  puts $fh "pal_layer $name {$rgb} {stipple"
  foreach row $pat {
    puts $fh "\t$row"
  }
  puts $fh "}"
}

# ── Read the .source ─────────────────────────────────────────────────────────
set layers {}          ;# MAX paint types, .source order
set gdsonly {}         ;# CIF-only layers, .source order
set order {}           ;# {paint|gdsonly name} in .source order (GDS emit order)
set connects {}
set devices {}
set derives {}
set setlines {}
set square_vias 0
set port_rules {}      ;# {kind gdslayer datatypes} from "port" statements
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
set lines {}
set pending ""
while {[gets $fh raw] >= 0} {
  # Strip CR so Windows-synced checkouts still parse.
  set t [string trim [string trimright $raw "\r"]]
  if {$pending != ""} {
    set t "$pending $t"
    set pending ""
  }
  if {$t == ""} continue
  if {[string index $t 0] == "#"} continue
  set last [expr {[string length $t] - 1}]
  if {[string index $t $last] == "\\"} {
    set pending [string trimright [string range $t 0 [expr {$last - 1}]]]
    continue
  }
  lappend lines $t
}
if {$pending != ""} { lappend lines $pending }
close $fh

# Layer rows are "name gds:dt txt type width space color". A Magic .tech can
# name a layer "device" / "connect" / "set"; those still have a GDS field.
proc is_layer_row {toks} {
  if {[llength $toks] < 6} { return 0 }
  set gds [lindex $toks 1]
  if {$gds == "-" || $gds == "derived"} { return 1 }
  if {[parse_gds_pair $gds] != ""} { return 1 }
  return 0
}

foreach t $lines {
  set toks [split_ws $t]
  set cmd [string tolower [lindex $toks 0]]
  set handled 1
  if {[is_layer_row $toks]} {
    set handled 0
  } else {
  switch -exact -- $cmd {
    device {
      # device nfet from poly ndiff
      if {[llength $toks] >= 5 && [string tolower [lindex $toks 2]] == "from"} {
        lappend devices [list [lindex $toks 1] [lindex $toks 3] [lindex $toks 4]]
      } else {
        warn "bad device statement: $t"
      }
    }
    connect {
      # connect via a,b[,c]   (extra words are joined into the list)
      if {[llength $toks] >= 3} {
        lappend connects [list [lindex $toks 1] [join [lrange $toks 2 end] ,]]
      } else {
        warn "bad connect statement: $t"
      }
    }
    derive {
      # derive name from a,b op x op y ...
      if {[llength $toks] >= 4 && [string tolower [lindex $toks 2]] == "from"} {
        lappend derives [list [lindex $toks 1] [lrange $toks 3 end]]
      } else {
        warn "bad derive statement: $t"
      }
    }
    set {
      lappend setlines $t
    }
    square_vias {
      set square_vias 1
    }
    port {
      # port KIND L:D[,D2]   KIND = input output inout local global comment hidden
      set pk [string tolower [lindex $toks 1]]
      set ppr ""
      if {[llength $toks] >= 3} { set ppr [parse_gds_pair [lindex $toks 2]] }
      if {$ppr == "" || [lsearch -exact {input output inout local global comment hidden} $pk] < 0} {
        warn "bad port statement: $t"
      } else {
        lappend port_rules [list $pk [lindex $ppr 0] [lindex $ppr 1]]
      }
    }
    drc - preserve_ports - iname {
    }
    default {
      set handled 0
    }
  }
  }
  if {$handled} continue

  # layer gds txt type width space color
  set name [lindex $toks 0]
  set gds [lindex $toks 1]
  set txt [lindex $toks 2]
  set typ [lindex $toks 3]
  set wid [lindex $toks 4]
  set spc [lindex $toks 5]
  set col [lindex $toks 6]
  if {$name == "" || $name == "-"} { continue }
  if {$gds == ""} { set gds "-" }
  if {$txt == ""} { set txt "-" }
  if {$typ == ""} { set typ "-" }
  if {$wid == ""} { set wid "-" }
  if {$spc == ""} { set spc "-" }
  if {$col == ""} { set col "-" }
  if {[is_digits $gds]} { set gds "$gds:0" }
  if {$txt != "-" && [is_digits $txt]} { set txt "$txt:0" }

  set typ_l [string tolower $typ]
  if {$typ_l == "active"} { set typ_l act }
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
  if {[lsearch -exact $layers $name] >= 0 || [lsearch -exact $gdsonly $name] >= 0} {
    warn "duplicate layer '$name' ignored"
    continue
  }
  if {$typ_l == "gdsonly"} {
    if {[parse_gds_pair $gds] == ""} {
      warn "gdsonly layer '$name' needs gds:dt; ignored"
      continue
    }
    lappend gdsonly $name
    lappend order [list gdsonly $name]
    set gds_of($name) $gds
    set txt_of($name) $txt
    set type_of($name) gdsonly
    set width_of($name) $wid
    set space_of($name) $spc
    set color_of($name) $col
    continue
  }
  if {$gds != "-" && $gds != "derived" && [parse_gds_pair $gds] == ""} {
    warn "layer '$name': bad gds field '$gds' (want L:D, derived or -); treated as -"
    set gds "-"
  }
  if {$txt != "-" && [parse_gds_pair $txt] == ""} {
    warn "layer '$name': bad txt field '$txt'; ignored"
    set txt "-"
  }

  lappend layers $name
  lappend order [list paint $name]
  set gds_of($name) $gds
  set txt_of($name) $txt
  set type_of($name) $typ_l
  set width_of($name) $wid
  set space_of($name) $spc
  set color_of($name) $col
}

if {![llength $layers]} {
  puts stderr "no layers in $source_file"
  exit 1
}

# ── Validate devices / connects ──────────────────────────────────────────────
set device_names {}
set ok_devices {}
foreach d $devices {
  set dn [lindex $d 0]
  set g [lindex $d 1]
  set a [lindex $d 2]
  if {[lsearch -exact $layers $g] < 0 || [lsearch -exact $layers $a] < 0} {
    warn "device $dn: '$g' or '$a' is not a paint layer; ignored"
    continue
  }
  if {[lsearch -exact $layers $dn] >= 0 || [lsearch -exact $device_names $dn] >= 0} {
    warn "device $dn: name already used; ignored"
    continue
  }
  lappend ok_devices $d
  lappend device_names $dn
}
set devices $ok_devices

proc is_paint {name} {
  global layers device_names
  if {[lsearch -exact $layers $name] >= 0} { return 1 }
  if {[lsearch -exact $device_names $name] >= 0} { return 1 }
  return 0
}

# Paint list for a layer: itself plus the device types composed from it.
proc paint_expand {name} {
  global devices
  set out [list $name]
  foreach d $devices {
    if {[lindex $d 1] == $name || [lindex $d 2] == $name} {
      lappend out [lindex $d 0]
    }
  }
  return $out
}

# "ndiff,pdiff" -> "ndiff,nfet,pdiff,pfet"
proc expand_csv {csv} {
  set out {}
  foreach n [split $csv ,] {
    if {$n == ""} continue
    foreach x [paint_expand $n] { lappend out $x }
  }
  return [uniq_join $out]
}

proc valid_paint_csv {csv} {
  foreach n [split $csv ,] {
    if {$n == ""} continue
    if {![is_paint $n]} { return 0 }
  }
  return 1
}

set ok_connects {}
foreach c $connects {
  set via [lindex $c 0]
  set csv [lindex $c 1]
  if {![is_paint $via] || ![valid_paint_csv $csv]} {
    warn "connect $via $csv: unknown layer; ignored"
    continue
  }
  lappend ok_connects [list $via $csv]
}
set connects $ok_connects

# ── Classify derives ─────────────────────────────────────────────────────────
# in_derive(name)  : derived paint  -> cifinput ops on GDS_ layers
# out_derive(name) : gdsonly / GDS paint -> cifoutput ops on paint types
array set in_derive {}
array set out_derive {}

proc has_gds {name} {
  global gds_of
  if {![info exists gds_of($name)]} { return 0 }
  return [expr {[parse_gds_pair $gds_of($name)] != ""}]
}

# Split derive tokens into {first_csv {op arg} {op arg} ...}; "" on error.
proc derive_ops {toks} {
  set ops [list [lindex $toks 0]]
  set i 1
  set n [llength $toks]
  while {$i < $n} {
    set op [string tolower [lindex $toks $i]]
    set arg [lindex $toks [expr {$i + 1}]]
    if {$arg == ""} { return "" }
    switch -exact -- $op {
      and - and-not - or - grow - shrink { lappend ops [list $op $arg] }
      default { return "" }
    }
    incr i 2
  }
  return $ops
}

foreach d $derives {
  set nm [lindex $d 0]
  set toks [lindex $d 1]
  set ops [derive_ops $toks]
  if {$ops == ""} {
    warn "derive $nm: cannot parse '[join $toks]'; ignored"
    continue
  }
  if {[lsearch -exact $layers $nm] >= 0 && $gds_of($nm) == "derived"} {
    # Input derive: every operand must carry GDS numbers, boolean ops only.
    set good 1
    foreach n [split [lindex $ops 0] ,] {
      if {![has_gds $n]} { set good 0 }
    }
    foreach o [lrange $ops 1 end] {
      set op [lindex $o 0]
      if {$op == "grow" || $op == "shrink"} {
        warn "derive $nm: $op is not supported on input derives; op dropped"
        continue
      }
      foreach n [split [lindex $o 1] ,] {
        if {![has_gds $n]} { set good 0 }
      }
    }
    if {!$good} {
      warn "derive $nm: an operand has no GDS layer; ignored"
      continue
    }
    set in_derive($nm) $ops
  } elseif {[lsearch -exact $gdsonly $nm] >= 0 || \
      ([lsearch -exact $layers $nm] >= 0 && [has_gds $nm])} {
    # Output derive: operands are paint types, distances in microns.
    set good 1
    if {![valid_paint_csv [lindex $ops 0]]} { set good 0 }
    foreach o [lrange $ops 1 end] {
      set op [lindex $o 0]
      if {$op == "grow" || $op == "shrink"} {
        if {![is_pos_num [lindex $o 1]]} { set good 0 }
      } elseif {![valid_paint_csv [lindex $o 1]]} {
        set good 0
      }
    }
    if {!$good} {
      warn "derive $nm: unknown paint layer or bad distance; ignored"
      continue
    }
    set out_derive($nm) $ops
  } else {
    warn "derive $nm: not a derived/gdsonly/GDS layer (DRC temp layers are not supported); ignored"
  }
}

# Paint types written on an output-derived CIF layer (first list + or's).
proc out_paints {name} {
  global out_derive
  set out {}
  foreach x [split [expand_csv [lindex $out_derive($name) 0]] ,] { lappend out $x }
  foreach o [lrange $out_derive($name) 1 end] {
    if {[lindex $o 0] == "or"} {
      foreach x [split [expand_csv [lindex $o 1]] ,] { lappend out $x }
    }
  }
  return [uniq_join $out]
}

foreach name $layers {
  if {$gds_of($name) == "derived" && ![info exists in_derive($name)]} {
    warn "layer '$name' is derived but has no usable 'derive $name from ...'; it stays MAX-only"
    set gds_of($name) "-"
  }
}
foreach name $gdsonly {
  if {![info exists out_derive($name)]} {
    warn "gdsonly layer '$name' has no 'derive $name from ...'; it is only read"
  }
}

file mkdir $outdir

# ── Planes / types ───────────────────────────────────────────────────────────
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
  if {$typ == "act" || $typ == "poly"} {
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
  # device paint types live on the active plane
  if {!$has_active} {
    lappend planes active
    set has_active 1
  }
  lappend types [list active [lindex $d 0]]
}

# ── .tech27 ──────────────────────────────────────────────────────────────────
set tech27 [file join $outdir ${tech}.tech27]
set fh [open $tech27 w]

puts $fh "tech"
puts $fh "\t$tech"
puts $fh "end"
puts $fh ""
puts $fh "version"
puts $fh "\tversion \"$tech (mmi-pdk gen $GEN_REV)\""
puts $fh "\tdescription \"$tech generated from [file tail $source_file]\""
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

# cifoutput ------------------------------------------------------------------
puts $fh "cifoutput"
puts $fh "style $tech"
puts $fh ""
puts $fh "\tunits .001 .001 .001 .001"
puts $fh "\tcharset unrestricted"
puts $fh ""
if {$bbox_layer != "" && [info exists gds_of($bbox_layer)]} {
  set pr [parse_gds_pair $gds_of($bbox_layer)]
  if {$pr != ""} {
    puts $fh "\tbbox [lindex $pr 0] [first_dt [lindex $pr 1]]"
  }
}
puts $fh ""

proc emit_out_ops {fh ops} {
  foreach o [lrange $ops 1 end] {
    set op [lindex $o 0]
    set arg [lindex $o 1]
    if {$op == "grow" || $op == "shrink"} {
      puts $fh "\t\t$op [um $arg]"
    } else {
      puts $fh "\t\t$op [expand_csv $arg]"
    }
  }
}

# cifoutput "port L D KIND": labels of KIND on this text layer go to L:D
# (e.g. sky130 pins on datatype 16) instead of the layer's plain calma type.
proc emit_out_ports {fh gnum dts} {
  global port_rules
  set have [split $dts ,]
  foreach pr $port_rules {
    if {[lindex $pr 1] != $gnum} continue
    set pdt [first_dt [lindex $pr 2]]
    # only pins listed among this text layer's datatypes (65:16 is diff, 65:48 tap)
    if {[lsearch -exact $have $pdt] < 0} continue
    puts $fh "\tport $gnum $pdt [lindex $pr 0]"
  }
}

foreach ent $order {
  set kind [lindex $ent 0]
  set name [lindex $ent 1]
  set gds $gds_of($name)
  if {$gds == "-" || $gds == "derived"} continue
  set pr [parse_gds_pair $gds]
  if {$pr == ""} continue
  set gnum [lindex $pr 0]
  set gdt [first_dt [lindex $pr 1]]

  if {$kind == "gdsonly"} {
    if {![info exists out_derive($name)]} continue
    set ops $out_derive($name)
    set paint [out_paints $name]
    puts $fh "\tlayer GDS_$name [expand_csv [lindex $ops 0]]"
    emit_out_ops $fh $ops
    puts $fh "\tpolygons $paint"
  } elseif {[info exists out_derive($name)]} {
    set ops $out_derive($name)
    set paint [expand_csv $name]
    puts $fh "\tlayer GDS_$name [expand_csv [lindex $ops 0]]"
    emit_out_ops $fh $ops
    puts $fh "\tpolygons $paint"
  } else {
    set paint [expand_csv $name]
    puts $fh "\tlayer GDS_$name $paint"
    if {$square_vias && $type_of($name) == "via" && \
        [is_pos_num $width_of($name)] && [is_pos_num $space_of($name)]} {
      puts $fh "\t\tsquares 0 [um $width_of($name)] [um $space_of($name)] align"
    }
    puts $fh "\tpolygons $paint"
  }

  set tpr ""
  if {$txt_of($name) != "-"} { set tpr [parse_gds_pair $txt_of($name)] }
  if {$tpr != ""} {
    puts $fh "\tcalma $gnum $gdt"
    puts $fh ""
    puts $fh "\tlayer TXT_$name"
    puts $fh "\tlabels $paint"
    puts $fh "\tcalma [lindex $tpr 0] [first_dt [lindex $tpr 1]]"
    emit_out_ports $fh [lindex $tpr 0] [lindex $tpr 1]
  } else {
    puts $fh "\tlabels $paint"
    puts $fh "\tcalma $gnum $gdt"
  }
  puts $fh ""
}

# Text labels use the MAX "space" plane — never "labels *".
if {$text_layer != ""} {
  set tsrc $txt_of($text_layer)
  if {$tsrc == "-" || $tsrc == ""} { set tsrc $gds_of($text_layer) }
  set tpr [parse_gds_pair $tsrc]
  if {$tpr != ""} {
    puts $fh "\tlayer TXT_$text_layer"
    puts $fh "\tlabels space"
    puts $fh "\tcalma [lindex $tpr 0] [first_dt [lindex $tpr 1]]"
    puts $fh ""
  }
}
puts $fh "end"
puts $fh ""

# cifinput -------------------------------------------------------------------
# Every CIF name used in a "calma" line must already have appeared in a
# layer/labels/ignore line, so names are collected while the layers are written.
puts $fh "cifinput"
puts $fh "style\t$tech"
puts $fh ""
if {$bbox_layer != "" && [info exists gds_of($bbox_layer)]} {
  set pr [parse_gds_pair $gds_of($bbox_layer)]
  if {$pr != ""} {
    puts $fh "\tbbox [lindex $pr 0] [first_dt [lindex $pr 1]]"
  }
}
puts $fh ""

set cif_declared {}
proc cif_note {names} {
  global cif_declared
  foreach n [split $names ,] {
    if {$n == ""} continue
    if {[lsearch -exact $cif_declared $n] < 0} { lappend cif_declared $n }
  }
}
proc gds_csv {csv} {
  set out {}
  foreach n [split $csv ,] {
    if {$n == ""} continue
    lappend out GDS_$n
  }
  return [join $out ,]
}

# Labels on a gdsonly layer attach to the first paint type derived from it.
array set label_owner {}
foreach name $layers {
  if {![info exists in_derive($name)]} continue
  foreach n [split [lindex $in_derive($name) 0] ,] {
    if {[lsearch -exact $gdsonly $n] >= 0 && ![info exists label_owner($n)]} {
      set label_owner($n) $name
    }
  }
}

foreach name $layers {
  set gds $gds_of($name)
  if {$gds == "-"} continue
  if {$gds == "derived"} {
    set ops $in_derive($name)
    set src [gds_csv [lindex $ops 0]]
    puts $fh "\tlayer $name $src"
    cif_note $src
    foreach o [lrange $ops 1 end] {
      set op [lindex $o 0]
      if {$op == "grow" || $op == "shrink"} continue
      set arg [gds_csv [lindex $o 1]]
      puts $fh "\t\t$op $arg"
      cif_note $arg
    }
    set labs {}
    foreach n [split [lindex $ops 0] ,] {
      if {[info exists label_owner($n)] && $label_owner($n) == $name} {
        lappend labs GDS_$n
        if {$txt_of($n) != "-" && [parse_gds_pair $txt_of($n)] != ""} {
          lappend labs TXT_$n
        }
      }
    }
    if {[llength $labs]} {
      puts $fh "\tlabels [join $labs ,]"
      cif_note [join $labs ,]
    }
    puts $fh ""
    continue
  }
  puts $fh "\tlayer $name GDS_$name"
  cif_note GDS_$name
  if {$txt_of($name) != "-" && [parse_gds_pair $txt_of($name)] != ""} {
    puts $fh "\tlabels GDS_$name,TXT_$name"
    cif_note "GDS_$name,TXT_$name"
  } else {
    puts $fh "\tlabels GDS_$name"
  }
  puts $fh ""
}

# gdsonly layers nobody derives from: register them so their calma line parses.
foreach name $gdsonly {
  if {[lsearch -exact $cif_declared GDS_$name] < 0} {
    puts $fh "\tignore GDS_$name"
    cif_note GDS_$name
  }
  if {$txt_of($name) != "-" && [parse_gds_pair $txt_of($name)] != "" && \
      [lsearch -exact $cif_declared TXT_$name] < 0} {
    puts $fh "\tignore TXT_$name"
    cif_note TXT_$name
  }
}

if {$text_layer != ""} {
  set tsrc $txt_of($text_layer)
  if {$tsrc == "-" || $tsrc == ""} { set tsrc $gds_of($text_layer) }
  if {[parse_gds_pair $tsrc] != ""} {
    puts $fh "\tlayer space"
    puts $fh "\tlabels TXT_$text_layer"
    cif_note TXT_$text_layer
  }
}
puts $fh ""

# calma lines: exact layer/datatype pairs (PDKs like sky130 put several
# layers on one GDS number; a "*" datatype smears them together).
foreach ent $order {
  set name [lindex $ent 1]
  set gds $gds_of($name)
  if {$gds == "-" || $gds == "derived"} continue
  set pr [parse_gds_pair $gds]
  if {$pr == ""} continue
  if {[lsearch -exact $cif_declared GDS_$name] >= 0} {
    puts $fh "\tcalma GDS_$name\t[lindex $pr 0] [lindex $pr 1]"
  }
  if {[lsearch -exact $cif_declared TXT_$name] >= 0} {
    set tpr [parse_gds_pair $txt_of($name)]
    if {$tpr != ""} {
      puts $fh "\tcalma TXT_$name\t[lindex $tpr 0] [lindex $tpr 1]"
    }
  }
}
if {$text_layer != "" && [lsearch -exact $cif_declared TXT_$text_layer] >= 0} {
  set tsrc $txt_of($text_layer)
  if {$tsrc == "-" || $tsrc == ""} { set tsrc $gds_of($text_layer) }
  set tpr [parse_gds_pair $tsrc]
  if {$tpr != ""} {
    puts $fh "\tcalma TXT_$text_layer\t[lindex $tpr 0] [lindex $tpr 1]"
  }
}
# cifinput "port KIND L D[,D2]": texts on these GDS types become KIND labels
# (ports) instead of plain local labels (gdsReadPaint.c defaults to LAB_LOCAL).
foreach pr $port_rules {
  puts $fh "\tport [lindex $pr 0] [lindex $pr 1] [lindex $pr 2]"
}
puts $fh "end"
puts $fh ""

puts $fh "mzrouter"
puts $fh "end"
puts $fh ""

# drc --------------------------------------------------------------------------
# cifstyle belongs inside drc (not a top-level section) and must come before
# any micron dimension.
puts $fh "drc"
puts $fh "cifstyle $tech"
puts $fh ""
foreach ent $order {
  set kind [lindex $ent 0]
  set name [lindex $ent 1]
  set w $width_of($name)
  set s $space_of($name)
  # Do NOT use expr to validate: "expr - + 0" succeeds, so "-" was emitted.
  set hw [is_pos_num $w]
  set hs [is_pos_num $s]
  if {!$hw && !$hs} continue
  if {$kind == "gdsonly" || [info exists out_derive($name)]} {
    # Rule on the generated GDS layer (mmi18 does this for nw/nplus).
    if {$hw} {
      puts $fh "\tcifwidth GDS_$name [um $w] \\"
      puts $fh "\t\t\"$name minimum width = [um $w] um.\""
      puts $fh ""
    }
    if {$hs} {
      puts $fh "\tcifspacing GDS_$name GDS_$name [um $s] touching_ok \\"
      puts $fh "\t\t\"$name minimum spacing = [um $s] um.\""
      puts $fh ""
    }
    continue
  }
  set paint [expand_csv $name]
  if {$hw} {
    puts $fh "\twidth $paint [um $w] \\"
    puts $fh "\t\t\"$name minimum width = [um $w] um.\""
    puts $fh ""
  }
  if {$hs} {
    puts $fh "\tspacing $paint $paint [um $s] touching_ok \\"
    puts $fh "\t\t\"$name minimum spacing = [um $s] um.\""
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

# extract --------------------------------------------------------------------
puts $fh "extract"
puts $fh "style\t$tech"
puts $fh "\tnoplaneordering"
puts $fh ""
puts $fh "\tcscale\t1"
puts $fh "\tlambda\t1"
puts $fh "\tstep\t1000"
puts $fh "\tsidehalo\t0"
puts $fh ""
foreach name [concat $poly_layers $metal_layers] {
  puts $fh "\tresist $name 115"
  puts $fh "\tareacap $name 0.0001"
  if {$type_of($name) == "poly"} {
    puts $fh "\tperimc $name space/active 0.1"
  } else {
    puts $fh "\tperimc $name space/$name 0.1"
  }
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

# ── Companion .tcl ───────────────────────────────────────────────────────────
# Brace list values; [list a b] inside "" drops braces and MAX then sees
# a multi-word set.
set tclf [file join $outdir ${tech}.tcl]
set fh [open $tclf w]
puts $fh "# $tech.tcl - generated by source_to_tech27.tcl (gen $GEN_REV)"
puts $fh "set MAKE_TECH_VERSION 1"
puts $fh "set MMI_PDK_GEN $GEN_REV"
set wire 0.3
foreach name $metal_layers {
  if {[is_pos_num $width_of($name)]} {
    set wire $width_of($name)
    break
  }
}
puts $fh "set MN_TYPICAL_WIRE_WIDTH $wire"
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
# connect,X: every layer electrically joined to X through a connect statement
array set conn {}
foreach name $layers { set conn($name) {} }
foreach c $connects {
  set via [lindex $c 0]
  foreach other [split [lindex $c 1] ,] {
    if {$other == "" || $other == $via} continue
    if {[lsearch -exact $conn($via) $other] < 0} { lappend conn($via) $other }
    if {![info exists conn($other)]} { set conn($other) {} }
    if {[lsearch -exact $conn($other) $via] < 0} { lappend conn($other) $via }
  }
}
foreach name $layers {
  if {[llength $conn($name)]} {
    puts $fh "set DRC_DATA(connect,$name) {$conn($name)}"
  }
}
foreach d $devices {
  set dn [lindex $d 0]
  set g [lindex $d 1]
  set a [lindex $d 2]
  puts $fh "set DRC_DATA(device,fet,$dn) {$g $a}"
}
foreach name [concat $layers $gdsonly] {
  if {[is_pos_num $width_of($name)]} {
    puts $fh "set DRC_DATA(width,$name) $width_of($name)"
  }
  if {[is_pos_num $space_of($name)]} {
    puts $fh "set DRC_DATA(spacing,$name) $space_of($name)"
  }
}
foreach d $devices {
  set dn [lindex $d 0]
  set a [lindex $d 2]
  if {[is_pos_num $space_of($a)]} {
    puts $fh "set DRC_DATA(spacing,$dn) $space_of($a)"
  }
}
if {[llength $setlines]} {
  puts $fh ""
  puts $fh "# set statements copied from [file tail $source_file]"
  foreach t $setlines {
    puts $fh $t
  }
}
close $fh

# ── Palette — MAX aborts without ${tech}.palette ─────────────────────────────
# colors.tcl: "can really only have 10 solid layers (5 transparent, 5 faked)".
# An 11th pal_layer ... solid is skipped, then pal_write_int dies on an empty
# style name. Reserve poly + two diffusion types, then top metals, then taps.
array set is_solid {}
set nsolid 0
proc take_solid {name} {
  global nsolid is_solid
  if {$name == ""} { return }
  if {[info exists is_solid($name)]} { return }
  if {$nsolid >= 10} { return }
  set is_solid($name) 1
  incr nsolid
}
foreach name $poly_layers { take_solid $name }
set ai 0
foreach name $act_layers {
  if {$ai >= 2} break
  take_solid $name
  incr ai
}
set nmet [llength $metal_layers]
for {set i [expr {$nmet - 1}]} {$i >= 0} {incr i -1} {
  take_solid [lindex $metal_layers $i]
}
foreach name $act_layers { take_solid $name }

set palf [file join $outdir ${tech}.palette]
set fh [open $palf w]
puts $fh "# Palette for $tech - generated by source_to_tech27.tcl (gen $GEN_REV)"
puts $fh "# At most 10 pal_layer ... solid (MAX colormap limit)."
puts $fh ""
set vi 0
set oi 0
if {[llength $metal_layers] || [llength $via_layers]} {
  puts $fh "pal_add_group metal"
  set emit {}
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
      set solid 0
      if {[info exists is_solid($name)]} { set solid 1 }
      pal_put $fh $name $rgb $solid
    }
  }
  puts $fh ""
}
if {[llength $poly_layers] || [llength $act_layers] || [llength $devices]} {
  puts $fh "pal_add_group active"
  foreach name $poly_layers {
    set rgb [color_rgb $color_of($name) "236 67 0"]
    set solid 0
    if {[info exists is_solid($name)]} { set solid 1 }
    pal_put $fh $name $rgb $solid
  }
  foreach d $devices {
    puts $fh "pal_compose [lindex $d 0] [lindex $d 1] [lindex $d 2]"
  }
  foreach name $act_layers {
    set rgb [color_rgb $color_of($name) "110 110 110"]
    set solid 0
    if {[info exists is_solid($name)]} { set solid 1 }
    pal_put $fh $name $rgb $solid
  }
  puts $fh ""
}
if {[llength $other_layers]} {
  puts $fh "pal_add_group other"
  foreach name $other_layers {
    set rgb [color_rgb $color_of($name) "100 100 100"]
    pal_put $fh $name $rgb 0
  }
  puts $fh ""
}
close $fh

# Also leave a .tech (same content) for tooling that looks for it
catch {file copy -force $tech27 [file join $outdir ${tech}.tech]}

puts "wrote $tech27 ([file size $tech27] bytes), $tclf, $palf (gen $GEN_REV, [llength $layers] types, $nwarn warnings)"
exit 0
