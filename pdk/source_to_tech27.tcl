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

set layers {}
set gds_of {}
set txt_of {}
set type_of {}
set width_of {}
set space_of {}
set color_of {}
set connects {}
set devices {}
set text_layer ""
set bbox_layer ""

set fh [open $source_file r]
while {[gets $fh line] >= 0} {
  set line [string trim $line]
  if {$line == ""} continue
  if {[string index $line 0] == "#"} continue

  set cmd [string tolower [lindex $line 0]]
  if {$cmd == "device"} {
    # device nfet from poly diff
    if {[llength $line] >= 5 && [string tolower [lindex $line 2]] == "from"} {
      lappend devices [list [lindex $line 1] [lindex $line 3] [lindex $line 4]]
    }
    continue
  }
  if {$cmd == "connect"} {
    lappend connects [list [lindex $line 1] [lindex $line 2]]
    continue
  }
  if {$cmd == "derive" || $cmd == "drc" || $cmd == "set" || \
      $cmd == "preserve_ports" || $cmd == "square_vias"} {
    continue
  }

  # layer gds txt type width space color
  set name [lindex $line 0]
  set gds [lindex $line 1]
  set txt [lindex $line 2]
  set typ [lindex $line 3]
  set wid [lindex $line 4]
  set spc [lindex $line 5]
  set col [lindex $line 6]
  if {$name == "" || $name == "-"} continue
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
  # include composed devices that use this layer
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

if {$text_layer != ""} {
  set tsrc $txt_of($text_layer)
  if {$tsrc == "-" || $tsrc == ""} { set tsrc $gds_of($text_layer) }
  set tpr [parse_gds_pair $tsrc]
  if {$tpr != ""} {
    puts $fh "\tlayer TXT_$text_layer"
    puts $fh "\tlabels *"
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
puts $fh ""
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
    puts $fh "\tcalma TXT_$text_layer\t[lindex $tpr 0] *"
  }
}
puts $fh "end"
puts $fh ""

puts $fh "cifstyle $tech"
puts $fh ""

# Minimal DRC (width/space when provided)
puts $fh "drc"
foreach name $layers {
  set w $width_of($name)
  set s $space_of($name)
  if {[catch {expr $w + 0}]} { set w "" }
  if {[catch {expr $s + 0}]} { set s "" }
  if {$w != ""} {
    puts $fh "\twidth $name $w \\"
    puts $fh "\t\t\"$name minimum width = $w um.\""
    puts $fh ""
  }
  if {$s != ""} {
    puts $fh "\tspacing $name $name $s touching_ok \\"
    puts $fh "\t\t\"$name minimum spacing = $s um.\""
    puts $fh ""
  }
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
  set gate [lindex $d 1]
  set act [lindex $d 2]
  set bulk GND!
  if {[string match {p*} [string tolower $dname]]} { set bulk Vdd! }
  puts $fh "\tfet $dname $act 2 $dname $bulk 0 0"
}
puts $fh ""
puts $fh "end"

close $fh

# Companion .tcl
set tclf [file join $outdir ${tech}.tcl]
set fh [open $tclf w]
puts $fh "# $tech.tcl — generated by source_to_tech27.tcl"
puts $fh "set MAKE_TECH_VERSION 1"
puts $fh "set MN_TYPICAL_WIRE_WIDTH 0.3"
foreach name $metal_layers {
  puts $fh "set DRC_DATA(connect,$name) {}"
}
foreach c $connects {
  set a [lindex $c 0]
  set b [lindex $c 1]
  puts $fh "set DRC_DATA(connect,$a) [list $b]"
}
foreach d $devices {
  puts $fh "set DRC_DATA(device,fet,[lindex $d 0]) [list [lindex $d 1] [lindex $d 2]]"
}
close $fh

# Also leave a .tech (same content) for tooling that looks for it
catch {file copy -force $tech27 [file join $outdir ${tech}.tech]}

puts "wrote $tech27 ([file size $tech27] bytes) and $tclf"
exit 0
