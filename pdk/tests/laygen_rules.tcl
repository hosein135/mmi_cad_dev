# The schematic-to-layout generator reads DRC_DATA through techinfo.
# A sky130 tech that omits those keys places every contact at zero
# enclosure, then fails DRC and LVS. This checks the generated companion
# tcl, including a .source written before the rules existed.
#
#   tclsh pdk/tests/laygen_rules.tcl
set here [file dirname [info script]]
set root [file join $here ..]
source [file join $root importer pdk_tables.tcl]

set failed 0
proc bad {msg} {
  global failed
  puts "FAIL $msg"
  incr failed
}

proc tcl_get {text key} {
  set n [string length $key]
  foreach line [split $text \n] {
    if {[string range $line 0 [expr {$n + 3}]] != "set $key"} continue
    set rest [string range $line [expr {$n + 4}] end]
    set rest [string trim $rest]
    if {[string index $rest 0] == "\{"} {
      return [string range $rest 1 [expr {[string length $rest] - 2}]]
    }
    return $rest
  }
  return ""
}

proc idx {order name} {
  set i 0
  foreach w $order {
    if {$w == $name} { return $i }
    incr i
  }
  return -1
}

# techinfo below: connected layers that sit later in layer_order.
proc below_of {order conn via} {
  set pos [idx $order $via]
  if {$pos < 0} { return "" }
  set out {}
  foreach layer $conn {
    set pos2 [idx $order $layer]
    if {$pos2 > $pos} { lappend out $layer }
  }
  return $out
}

proc above_of {order conn via} {
  set pos [idx $order $via]
  if {$pos < 0} { return "" }
  set out {}
  foreach layer $conn {
    set pos2 [idx $order $layer]
    if {$pos2 >= 0 && $pos2 < $pos} { lappend out $layer }
  }
  return $out
}

set outdir [file join $root tests _laygen_out]
catch {file delete -force $outdir}
file mkdir $outdir

set gen [file join $root source_to_tech27.tcl]
set tclsh [info nameofexecutable]

proc build {family} {
  global outdir root gen tclsh
  set src [file join $outdir $family.source]
  set dest [file join $outdir $family]
  file mkdir $dest
  pdk_write_source $family $family $src
  if {[catch {exec $tclsh $gen $src $family $dest} err]} {
    return $err
  }
  set fh [open [file join $dest $family.tcl] r]
  set text [read $fh]
  close $fh
  return $text
}

puts "laygen rules: sky130A from a source that does not mention them"
set sky [build sky130A]
if {[string first "set MMI_PDK_GEN" $sky] < 0} {
  bad "sky130A generate: $sky"
  set sky ""
}

if {$sky != ""} {
  set order [tcl_get $sky "DRC_DATA(layer_order)"]
  if {[lindex $order 0] != "met5"} {
    bad "layer_order starts with [lindex $order 0], want met5 (top of the stack)"
  }
  if {[idx $order licon1] < [idx $order li1]} {
    bad "licon1 is above li1; below/above will point the wrong way"
  }
  set mcon_c [tcl_get $sky "DRC_DATA(connect,mcon)"]
  set below [below_of $order $mcon_c mcon]
  if {[lsearch -exact $below li1] < 0} {
    bad "techinfo below mcon is {$below}, want li1"
  }
  set lic_c [tcl_get $sky "DRC_DATA(connect,licon1)"]
  set above [above_of $order $lic_c licon1]
  if {$above != "li1"} {
    bad "techinfo above licon1 is {$above}, want li1 (generator metal m1)"
  }
  set vias [tcl_get $sky "DRC_DATA(vias)"]
  if {[lindex $vias 0] != "licon1"} {
    bad "v0 is [lindex $vias 0], want licon1"
  }
  foreach key {
    DRC_DATA(enclose,li1,licon1)
    DRC_DATA(enclose,pdiff,licon1)
    DRC_DATA(enclose,ndiff,licon1)
    DRC_DATA(enclose,poly,licon1)
    DRC_DATA(enclose,nwc,licon1)
    DRC_DATA(enclose,pwc,licon1)
    DRC_DATA(enclose,nsdm,ndiff)
    DRC_DATA(enclose,psdm,pdiff)
    DRC_DATA(enclose,nwell,nwc)
    DRC_DATA(enclose,nwell,pdiff)
    DRC_DATA(extend,poly,nfet)
    DRC_DATA(extend,poly,pfet)
    DRC_DATA(extend,ndiff,nfet)
    DRC_DATA(extend,pdiff,pfet)
    DRC_DATA(space_to,poly,pdiff)
    DRC_DATA(space_to,poly,ndiff)
    DRC_DATA(space_to,poly,nwc)
    DRC_DATA(space_to,licon1,pfet)
    DRC_DATA(space_to,licon1,nfet)
    DRC_DATA(space_to,psdm,nsdm)
    DRC_DATA(area,li1)
    DRC_DATA(width,nwc)
    LAYINFO(stdcell:cell_height)
    LAYINFO(stdcell:dpc_router_pitch)
    LAYINFO(stdcell:power_strap_width)
  } {
    if {[tcl_get $sky $key] == ""} {
      bad "missing $key"
    }
  }
  if {[tcl_get $sky "DRC_DATA(enclose,li1,licon1)"] != "0.08"} {
    bad "li enclosure of licon is [tcl_get $sky DRC_DATA(enclose,li1,licon1)], want 0.08"
  }
  if {[tcl_get $sky "LAYINFO(stdcell:cell_height)"] != "10.12"} {
    bad "cell height [tcl_get $sky LAYINFO(stdcell:cell_height)], want 10.12"
  }
  if {[string first "nwc" [tcl_get $sky "DRC_DATA(connect,licon1)"]] < 0} {
    bad "licon1 does not connect to the nwc tie"
  }
}

puts "laygen rules: a .source enclose line is kept"
set src [file join $outdir override.source]
set dest [file join $outdir override]
file mkdir $dest
pdk_write_source sky130A sky130A $src
set fh [open $src a]
puts $fh "enclose li1 licon1 0.09"
close $fh
if {[catch {exec $tclsh $gen $src sky130A $dest} err]} {
  bad "override generate: $err"
} else {
  set fh [open [file join $dest sky130A.tcl] r]
  set text [read $fh]
  close $fh
  if {[tcl_get $text "DRC_DATA(enclose,li1,licon1)"] != "0.09"} {
    bad "source enclose was replaced: [tcl_get $text DRC_DATA(enclose,li1,licon1)]"
  }
}

puts "laygen rules: gf180 and sg13 stacks still have a layer under every via"
foreach family {gf180mcu sg13g2} {
  set text [build $family]
  if {[string first "set DRC_DATA(vias)" $text] < 0} {
    bad "$family did not generate"
    continue
  }
  set order [tcl_get $text "DRC_DATA(layer_order)"]
  set vias [tcl_get $text "DRC_DATA(vias)"]
  foreach via $vias {
    set conn [tcl_get $text "DRC_DATA(connect,$via)"]
    set below [below_of $order $conn $via]
    if {$below == ""} {
      bad "$family techinfo below $via is empty (connect: $conn)"
    }
  }
  if {[tcl_get $text "DRC_DATA(enclose,li1,licon1)"] != ""} {
    bad "$family picked up a sky130 li rule"
  }
}

if {$failed} {
  puts "$failed failure(s)"
  exit 1
}
puts "laygen rules passed"
exit 0
