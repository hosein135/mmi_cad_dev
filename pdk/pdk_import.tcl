# PDK import for MAX (pure Tcl)
# File / Local menu: "Import PDK from URL..."
# Downloads a PDK, converts layers to a MAX .source file, runs make_tech.

global _PDK_IMPORT_SOURCED PDK_PRESET PDK_IMPORT
if {[info exists _PDK_IMPORT_SOURCED]} { return }
set _PDK_IMPORT_SOURCED 1

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

# ── Presets: download only when the user runs Import PDK in MAX ───────────────
# Compiled open_pdks trees (Magic tech + stdcells) from FOSSi ciel-releases.
# Not Nix flake inputs. GitHub archives of skywater-pdk / gf180mcu-pdk are
# skeletons (no submodules). fetch_pdk.sh is started from this dialog.
proc pdk_preset_init {} {
  global PDK_PRESET PDK_IMPORT
  set PDK_PRESET(sky130A,label)  "SKY130A - SkyWater 130nm (open_pdks)"
  set PDK_PRESET(sky130A,local)  "/mmi-pdks/sky130A"
  set PDK_PRESET(sky130A,fetch)  "sky130A"
  set PDK_PRESET(sky130A,tech)   "sky130A"

  set PDK_PRESET(gf180mcu,label) "GF180MCU - GlobalFoundries 180nm (open_pdks)"
  set PDK_PRESET(gf180mcu,local) "/mmi-pdks/gf180mcuD"
  set PDK_PRESET(gf180mcu,fetch)  "gf180mcu"
  set PDK_PRESET(gf180mcu,tech)  "gf180mcu"

  set PDK_PRESET(sg13g2,label)   "IHP SG13G2 - IHP 130nm SiGe (open_pdks)"
  set PDK_PRESET(sg13g2,local)   "/mmi-pdks/ihp-sg13g2"
  set PDK_PRESET(sg13g2,fetch)   "sg13g2"
  set PDK_PRESET(sg13g2,tech)    "sg13g2"

  if {![info exists PDK_IMPORT(pdk)]} { set PDK_IMPORT(pdk) "sky130A" }
  if {![info exists PDK_IMPORT(url)]} { set PDK_IMPORT(url) "" }
  if {![info exists PDK_IMPORT(tech)]} { set PDK_IMPORT(tech) "auto" }
  foreach k {after pid phase dest urls family work src log cancel status
              stat_status stat_msg stat_dest} {
    if {![info exists PDK_IMPORT($k)]} { set PDK_IMPORT($k) "" }
  }
  foreach k {total url_i stat_pct fetch_dead} {
    if {![info exists PDK_IMPORT($k)]} { set PDK_IMPORT($k) 0 }
  }
}
pdk_preset_init

# ── Layer maps (name gds txt type width space color) ─────────────────────────
proc pdk_layers_sky130A {} {
  return {
    {nwell 64:20 - - - - 0,160,0}
    {diff 65:20 - act - - 110,110,110}
    {tap 65:44 - act - - 180,180,180}
    {poly 66:20 - poly - - 236,67,0}
    {licon1 66:44 - via - - 80,80,80}
    {li1 67:20 - metal - - 8,139,255}
    {mcon 67:44 - via - - 90,90,90}
    {met1 68:20 - metal - - 182,134,222}
    {via 68:44 - via - - 100,100,100}
    {met2 69:20 - metal - - 255,160,65}
    {via2 69:44 - via - - 110,110,110}
    {met3 70:20 - metal - - 61,122,188}
    {via3 70:44 - via - - 120,120,120}
    {met4 71:20 - metal - - 200,80,80}
    {via4 71:44 - via - - 130,130,130}
    {met5 72:20 - metal - - gold}
    {pwell 64:13 - - - - 0,80,0}
    {dnwell 64:18 - - - - 0,100,0}
    {mimcap 89:44 - - - - 180,180,80}
    {mimcap2 97:44 - - - - 200,200,80}
    {hvi 75:20 - - - - 0,80,160}
    {nsdm 93:44 - - - - 0,200,200}
    {psdm 94:20 - - - - 200,0,200}
    {npc 95:20 - - - - 160,80,0}
    {hvntm 125:20 - - - - 0,80,160}
    {areaid_sl 81:4 - bbox - - -}
    {text - 64:5 text - - -}
  }
}

proc pdk_layers_gf180mcu {} {
  return {
    {nwell 21:0 - - - - 0,160,0}
    {dnwell 12:0 - - - - 0,100,0}
    {comp 22:0 - act - - 110,110,110}
    {poly2 30:0 - poly - - 236,67,0}
    {nplus 32:0 - - - - 0,200,200}
    {pplus 31:0 - - - - 200,0,200}
    {contact 33:0 - via - - 80,80,80}
    {metal1 34:0 - metal - - 8,139,255}
    {via1 35:0 - via - - 90,90,90}
    {metal2 36:0 - metal - - 182,134,222}
    {via2 38:0 - via - - 100,100,100}
    {metal3 42:0 - metal - - 255,160,65}
    {via3 40:0 - via - - 110,110,110}
    {metal4 46:0 - metal - - 61,122,188}
    {via4 41:0 - via - - 120,120,120}
    {metal5 81:0 - metal - - gold}
    {text - 31:0 text - - -}
  }
}

proc pdk_layers_sg13g2 {} {
  return {
    {Activ 1:0 - act - - 110,110,110}
    {GatPoly 5:0 - poly - - 236,67,0}
    {NWell 31:0 - - - - 0,160,0}
    {nSD 7:0 - - - - 0,200,200}
    {pSD 14:0 - - - - 200,0,200}
    {Cont 6:0 - via - - 80,80,80}
    {Metal1 8:0 - metal - - 8,139,255}
    {Via1 19:0 - via - - 90,90,90}
    {Metal2 10:0 - metal - - 182,134,222}
    {Via2 29:0 - via - - 100,100,100}
    {Metal3 30:0 - metal - - 255,160,65}
    {Via3 49:0 - via - - 110,110,110}
    {Metal4 50:0 - metal - - 61,122,188}
    {Via4 66:0 - via - - 120,120,120}
    {Metal5 67:0 - metal - - gold}
    {TEXT - 63:0 text - - -}
  }
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
  set n [string tolower $name]
  if {[regexp {text|label} $n]} { return text }
  if {[regexp {bbox|prb|boundary|areaid} $n]} { return bbox }
  if {[regexp {via|licon|mcon|ncon|pcon|cont|^ct} $n]} { return via }
  if {[regexp {poly|gate|gpoly|gatpoly} $n]} { return poly }
  if {[regexp {diff|active|activ|comp|^od} $n]} { return act }
  if {[regexp {metal|^met[0-9]|^m[0-9]|^li[0-9]} $n]} { return metal }
  return "-"
}

proc pdk_sanitize {name} {
  regsub -all {[^A-Za-z0-9_]+} $name _ name
  regsub -all {_+} $name _ name
  set name [string trim $name _]
  if {$name == ""} { set name layer }
  if {[regexp {^[0-9]} $name]} { set name L$name }
  return $name
}

proc pdk_log {msg} {
  global PDK_IMPORT
  catch {
    set fh [open $PDK_IMPORT(log) a]
    puts $fh $msg
    close $fh
  }
  catch {puts $msg}
}

proc pdk_cancelled {} {
  global PDK_IMPORT
  return [expr {$PDK_IMPORT(cancel) != "" && [file exists $PDK_IMPORT(cancel)]}]
}

proc pdk_find_files {root patterns} {
  set out {}
  set dirs [list $root]
  set n 0
  while {[llength $dirs] && $n < 8000} {
    set dir [lindex $dirs 0]
    set dirs [lrange $dirs 1 end]
    if {[catch {set names [glob -nocomplain -directory $dir *]}]} {
      continue
    }
    foreach f $names {
      incr n
      if {[file isdirectory $f]} {
        set bn [file tail $f]
        if {$bn == ".git" || $bn == "__pycache__"} continue
        lappend dirs $f
      } else {
        set low [string tolower [file tail $f]]
        foreach pat $patterns {
          if {[string match $pat $low]} {
            lappend out $f
            break
          }
        }
      }
    }
  }
  return $out
}

proc pdk_parse_magic_tech {path} {
  set rows {}
  if {[catch {set fh [open $path r]}]} { return $rows }
  set current ""
  while {[gets $fh line] >= 0} {
    set line [string trim $line]
    if {[regexp {^layer[ \t]+([^ \t]+)} $line -> current]} continue
    if {$current != "" && [regexp {^calma[ \t]+([0-9]+)[ \t]+([0-9]+)} $line -> l d]} {
      lappend rows [list $current "$l:$d" - [pdk_guess_type $current] - - -]
      set current ""
    }
  }
  close $fh
  return $rows
}

proc pdk_which {names} {
  global env
  set path ""
  if {[info exists env(PATH)]} { set path $env(PATH) }
  foreach name $names {
    if {[file executable $name]} { return $name }
    foreach dir [split $path :] {
      set cand [file join $dir $name]
      if {[file executable $cand]} { return $cand }
    }
  }
  return ""
}

# make_tech writes .tech then runs mmi_cpp | mmi_m4 to produce .tech27.
proc pdk_compile_tech27 {techdir tech} {
  set src [file join $techdir ${tech}.tech]
  set dst [file join $techdir ${tech}.tech27]
  if {![file readable $src]} { return 0 }
  set cpp [pdk_which {mmi_cpp cpp}]
  set m4 [pdk_which {mmi_m4 m4}]
  if {$cpp == "" || $m4 == ""} {
    pdk_log "Need cpp (mmi_cpp) and m4 (mmi_m4) to compile $src"
    return 0
  }
  set save [pwd]
  if {[catch {cd $techdir}]} { return 0 }
  set tmp ${tech}.tech27.tmp
  set ok 0
  foreach trad {-traditional-cpp -traditional} {
    catch {file delete $tmp}
    if {[catch {exec $cpp -P $trad ${tech}.tech | $m4 > $tmp} err]} {
      pdk_log "cpp $trad | m4: $err"
      continue
    }
    if {[file exists $tmp] && [file size $tmp] > 0} {
      catch {file delete $dst}
      catch {file rename $tmp $dst}
      set ok 1
      break
    }
  }
  catch {file delete $tmp}
  catch {cd $save}
  if {$ok} { pdk_log "Compiled $dst" }
  return $ok
}

proc pdk_find_tech27 {tech} {
  global env
  set home /mmi-home
  if {[info exists env(HOME)] && $env(HOME) != ""} { set home $env(HOME) }
  set cands [list \
      [file join [pdk_root] max tech $tech ${tech}.tech27] \
      [file join $home mmi_private max tech $tech ${tech}.tech27] \
      [file join $home cad mmi_local max tech $tech ${tech}.tech27]]
  foreach f $cands {
    if {[file readable $f] && [file size $f] > 0} { return $f }
  }
  return ""
}

# Downloaded open_pdks tree plus MAX .tech27 (usable in max -tech).
proc pdk_preset_ready {choice} {
  global PDK_PRESET
  if {![info exists PDK_PRESET($choice,local)]} { return 0 }
  if {![pdk_tree_ready $PDK_PRESET($choice,local)]} { return 0 }
  if {[pdk_find_tech27 $PDK_PRESET($choice,tech)] == ""} { return 0 }
  return 1
}

proc pdk_preset_radio_labels {} {
  global PDK_PRESET
  set out {}
  foreach c {sky130A gf180mcu sg13g2} {
    set lab $PDK_PRESET($c,label)
    if {[pdk_preset_ready $c]} {
      append lab " (already imported)"
    }
    lappend out $lab
  }
  lappend out "Custom URL..."
  return $out
}

# Shared PDK folder used by Magic (native open_pdks tree) and MAX
# (compiled .source / make_tech output under max/tech/). Default /mmi-pdks
# (host data/pdks inside the Nix FHS env).
proc pdk_root {} {
  global env
  if {[info exists env(PDK_ROOT)] && $env(PDK_ROOT) != ""} {
    return $env(PDK_ROOT)
  }
  return /mmi-pdks
}

# True when dir is a compiled open_pdks tree (Magic rc + at least one library).
proc pdk_tree_ready {dir} {
  if {$dir == "" || ![file isdirectory $dir]} { return 0 }
  set mag [file join $dir libs.tech magic]
  if {![file isdirectory $mag]} { return 0 }
  set rcs [glob -nocomplain [file join $mag *.magicrc]]
  if {![llength $rcs]} { return 0 }
  set ref [file join $dir libs.ref]
  if {![file isdirectory $ref]} { return 0 }
  set kids [glob -nocomplain [file join $ref *]]
  if {![llength $kids]} { return 0 }
  return 1
}

proc pdk_fetch_script {} {
  global env
  set cands {}
  if {[info exists env(MMI_PDK_DIR)] && $env(MMI_PDK_DIR) != ""} {
    lappend cands [file join $env(MMI_PDK_DIR) fetch_pdk.sh]
  }
  if {[info exists env(MMI_LOCAL)] && $env(MMI_LOCAL) != ""} {
    lappend cands [file join $env(MMI_LOCAL) max pdk fetch_pdk.sh]
  }
  lappend cands /mmi-bundle/fetch_pdk.sh
  foreach f $cands {
    if {[file readable $f]} { return $f }
  }
  return ""
}

proc pdk_shared_max_techdir {tech} {
  set d [file join [pdk_root] max tech $tech]
  catch {file mkdir $d}
  return $d
}

proc pdk_link_max_private {tech shared} {
  global env
  set home ""
  if {[info exists env(HOME)]} { set home $env(HOME) }
  if {$home == ""} { set home /mmi-home }
  set priv [file join $home mmi_private max tech]
  catch {file mkdir $priv}
  set link [file join $priv $tech]
  if {[file exists $link] && ![file exists [file join $shared ${tech}.source]]} {
    return
  }
  if {[file exists $link] && ![file isdirectory $link]} {
    return
  }
  if {[file exists $link]} {
    catch {
      if {[file type $link] == "link"} {
        file delete $link
      } elseif {[_mmi_file_normalize $link] != [_mmi_file_normalize $shared]} {
        # Keep existing private dir; also keep shared copy.
        return
      }
    }
  }
  if {![file exists $link]} {
    catch {exec ln -s $shared $link}
  }
}

# Copy/move an unpacked PDK into $PDK_ROOT/<name>/ so Magic and MAX share it.
proc pdk_install_into_root {src family tech} {
  set root [pdk_root]
  catch {file mkdir $root}
  if {![file isdirectory $root]} {
    pdk_log "PDK_ROOT $root is not writable; skipping shared install"
    return ""
  }

  set name $tech
  if {$family == "sky130A"} { set name sky130A }
  if {$family == "gf180mcu"} { set name gf180mcuD }
  if {$family == "sg13g2"} { set name ihp-sg13g2 }

  set dest [file join $root $name]
  set srcn [_mmi_file_normalize $src]
  set rootn [_mmi_file_normalize $root]

  # Prefer an open_pdks tree (…/sky130A/libs.tech/magic/*.magicrc)
  set rcs [pdk_find_files $src {*.magicrc}]
  set from ""
  foreach rc $rcs {
    set magicdir [file dirname $rc]
    if {[file tail $magicdir] != "magic"} continue
    set techdir [file dirname [file dirname $magicdir]]
    if {[file tail [file dirname $magicdir]] == "libs.tech"} {
      set from $techdir
      set name [file tail $techdir]
      set dest [file join $root $name]
      break
    }
  }

  if {$from == ""} {
    set from $srcn
  } else {
    set from [_mmi_file_normalize $from]
  }

  if {[string match ${rootn}* $from]} {
    pdk_log "PDK already under PDK_ROOT: $from"
    return $from
  }

  if {[file isdirectory [file join $dest libs.ref]] && \
      [llength [glob -nocomplain [file join $dest libs.ref *]]] && \
      [file isdirectory [file join $dest libs.tech magic]]} {
    pdk_log "Shared PDK already present: $dest"
    return $dest
  }

  pdk_log "Installing PDK into shared $dest"
  catch {file mkdir [file dirname $dest]}
  if {[catch {exec cp -a $from $dest} err]} {
    pdk_log "cp into PDK_ROOT failed: $err"
    return ""
  }
  return $dest
}

# ── Dialog ───────────────────────────────────────────────────────────────────
proc pdk_import_dialog {} -desc {
  Download a preset PDK or a custom URL and install it as a MAX technology.
} {
  global PDK_IMPORT PDK_PRESET
  pdk_preset_init

  set prop_list ""
  lappend prop_list [list "PDK:" PDK_IMPORT(pdk) \
      -radio [pdk_preset_radio_labels] \
      -values {sky130A gf180mcu sg13g2 custom} \
      -help {Choose a foundry PDK. Names marked (already imported) will not be downloaded again. Custom URL is used only when that row is selected.}]

  lappend prop_list [list "Custom URL:" PDK_IMPORT(url) -entry -width 56 \
      -help {Used only if Custom URL is selected. GitHub repo, tar.gz/zip, or a directory on disk.}]

  lappend prop_list [list "MAX technology name (auto = from PDK):" \
      PDK_IMPORT(tech) -entry -width 24]

  if {![prop_menu2 -title "Import PDK" $prop_list]} {
    return
  }

  set choice $PDK_IMPORT(pdk)
  if {$choice == "custom"} {
    set url [string trim $PDK_IMPORT(url)]
    set family ""
    set tech $PDK_IMPORT(tech)
    if {$url == ""} {
      max_error "PDK URL is empty."
      return
    }
    pdk_import_start [list $url] $tech $family
    return
  }

  set family $choice
  set tech $PDK_PRESET($choice,tech)
  if {$PDK_IMPORT(tech) != "auto" && $PDK_IMPORT(tech) != ""} {
    set tech $PDK_IMPORT(tech)
  }
  set local $PDK_PRESET($choice,local)

  set tech27 [pdk_find_tech27 $tech]
  if {[pdk_tree_ready $local] && $tech27 != ""} {
    set msg "PDK '$choice' is already imported and ready for MAX.\n\n\
open_pdks tree:\n  $local\n\
MAX technology:\n  $tech27\n\n\
Start MAX with:\n  max -tech $tech\n\n\
Nothing was downloaded."
    if {[catch {warning $msg}]} { puts $msg }
    return
  }

  if {[pdk_tree_ready $local]} {
    pdk_import_start [list $local] $tech $family
    return
  }
  pdk_import_fetch $PDK_PRESET($choice,fetch) $tech $family
}

# ── Engine ───────────────────────────────────────────────────────────────────
proc pdk_import_prepare_work {tech family} {
  global PDK_IMPORT
  set stamp [clock seconds]
  set work [file join /tmp pdk_import_$stamp]
  file mkdir $work
  set PDK_IMPORT(work) $work
  set PDK_IMPORT(src) [file join $work src]
  file mkdir $PDK_IMPORT(src)
  set PDK_IMPORT(log) [file join $work convert.log]
  set PDK_IMPORT(cancel) [file join $work CANCEL]
  set PDK_IMPORT(status) [file join $work status]
  set PDK_IMPORT(dest) [file join $work pdk_download.bin]
  set PDK_IMPORT(urls) ""
  set PDK_IMPORT(url_i) 0
  set PDK_IMPORT(tech) [pdk_sanitize $tech]
  set PDK_IMPORT(family) $family
  set PDK_IMPORT(pid) ""
  set PDK_IMPORT(total) 0
  set PDK_IMPORT(stat_status) ""
  set PDK_IMPORT(stat_pct) 0
  set PDK_IMPORT(stat_msg) ""
  set PDK_IMPORT(stat_dest) ""
  set PDK_IMPORT(fetch_dead) 0
  catch {file delete $PDK_IMPORT(cancel)}
  catch {file delete $PDK_IMPORT(log)}
  catch {file delete $PDK_IMPORT(status)}
  pdk_log "PDK import workdir $work"
}

proc pdk_import_read_status {} {
  global PDK_IMPORT
  set PDK_IMPORT(stat_status) running
  set PDK_IMPORT(stat_pct) 0
  set PDK_IMPORT(stat_msg) ""
  if {![file exists $PDK_IMPORT(status)]} { return }
  if {[catch {set fh [open $PDK_IMPORT(status) r]}]} { return }
  while {[gets $fh line] >= 0} {
    if {[regexp {^STATUS=(.*)$} $line -> v]} {
      set PDK_IMPORT(stat_status) $v
    } elseif {[regexp {^PCT=(.*)$} $line -> v]} {
      set PDK_IMPORT(stat_pct) $v
    } elseif {[regexp {^MSG=(.*)$} $line -> v]} {
      set PDK_IMPORT(stat_msg) $v
    } elseif {[regexp {^DEST=(.*)$} $line -> v]} {
      set PDK_IMPORT(stat_dest) $v
    }
  }
  close $fh
}

# Fetch a compiled open_pdks tree (ciel-releases) into PDK_ROOT, then convert.
proc pdk_import_fetch {fetch_family tech family} {
  global PDK_IMPORT env

  pdk_import_prepare_work $tech $family

  set script [pdk_fetch_script]
  if {$script == ""} {
    pdk_import_fail "fetch_pdk.sh not found (expected in /mmi-bundle)."
    return
  }
  set bash [pdk_which {bash /bin/bash /usr/bin/bash}]
  if {$bash == ""} {
    pdk_import_fail "bash is not installed."
    return
  }

  catch {set env(MMI_PDK_FETCH_LOG) $PDK_IMPORT(log)}
  catch {set env(PDK_ROOT) [pdk_root]}

  _pdk_import_progress_open
  _pdk_import_progress_update 1 "Downloading compiled open_pdks ($fetch_family)..."
  pdk_log "fetch_pdk.sh $fetch_family"

  if {[catch {set PDK_IMPORT(pid) [exec $bash $script $fetch_family \
      $PDK_IMPORT(status) $PDK_IMPORT(cancel) &]} err]} {
    pdk_import_fail "Could not start fetch_pdk.sh:\n$err"
    return
  }
  set PDK_IMPORT(phase) fetch
  set PDK_IMPORT(after) [after 400 pdk_import_poll_fetch]
}

proc pdk_import_poll_fetch {} {
  global PDK_IMPORT
  set PDK_IMPORT(after) ""

  pdk_import_read_status
  set st $PDK_IMPORT(stat_status)
  set pct $PDK_IMPORT(stat_pct)
  set msg $PDK_IMPORT(stat_msg)
  if {$msg == ""} { set msg "Downloading compiled open_pdks..." }
  if {![regexp {^[0-9]+$} $pct]} { set pct 0 }
  _pdk_import_progress_update $pct $msg

  if {$st == "ok"} {
    set dest $PDK_IMPORT(stat_dest)
    if {$dest == "" || ![pdk_tree_ready $dest]} {
      pdk_import_fail "fetch_pdk.sh finished but no open_pdks tree was found.\nLog: $PDK_IMPORT(log)"
      return
    }
    set PDK_IMPORT(src) $dest
    _pdk_import_progress_update 85 "Converting to MAX technology..."
    pdk_import_convert
    return
  }
  if {$st == "fail"} {
    pdk_import_fail $msg
    return
  }
  if {$st == "cancelled"} {
    pdk_import_fail "Cancelled."
    return
  }

  set alive 1
  if {$PDK_IMPORT(pid) != ""} {
    if {[catch {exec kill -0 $PDK_IMPORT(pid)}]} {
      set alive 0
    }
  }
  if {!$alive && $st != "ok"} {
    incr PDK_IMPORT(fetch_dead)
    if {$PDK_IMPORT(fetch_dead) < 8} {
      set PDK_IMPORT(after) [after 400 pdk_import_poll_fetch]
      return
    }
    pdk_import_fail "PDK fetch exited early.\n$msg\nLog: $PDK_IMPORT(log)"
    return
  }

  set PDK_IMPORT(after) [after 400 pdk_import_poll_fetch]
}

proc pdk_import_start {urls tech family} {
  global PDK_IMPORT env

  pdk_import_prepare_work $tech $family
  set PDK_IMPORT(urls) $urls
  set PDK_IMPORT(url_i) 0
  set PDK_IMPORT(dest) [file join $PDK_IMPORT(work) pdk_download.bin]

  _pdk_import_progress_open

  set first [lindex $urls 0]
  if {[file isdirectory $first]} {
    set PDK_IMPORT(src) $first
    _pdk_import_progress_update 80 "Local PDK directory — converting..."
    pdk_import_convert
    return
  }
  if {[file isfile $first]} {
    set PDK_IMPORT(dest) $first
    _pdk_import_progress_update 70 "Local archive — unpacking..."
    pdk_import_unpack
    return
  }

  pdk_import_download_next
}

proc pdk_import_download_next {} {
  global PDK_IMPORT

  if {[pdk_cancelled]} {
    pdk_import_fail "Cancelled."
    return
  }

  if {$PDK_IMPORT(url_i) >= [llength $PDK_IMPORT(urls)]} {
    pdk_import_fail "Could not download PDK from any of:\n[join $PDK_IMPORT(urls) \n]"
    return
  }

  set url [lindex $PDK_IMPORT(urls) $PDK_IMPORT(url_i)]
  incr PDK_IMPORT(url_i)
  pdk_log "Downloading $url"
  _pdk_import_progress_update 1 "Downloading... 0%"

  set curl [pdk_which {curl /usr/bin/curl}]
  set wget [pdk_which {wget /usr/bin/wget}]
  catch {file delete $PDK_IMPORT(dest)}
  set PDK_IMPORT(total) 0

  if {$curl != ""} {
    catch {
      set hdr [exec $curl -sI -L --max-redirs 8 $url]
      foreach line [split $hdr "\n"] {
        if {[regexp -nocase {^Content-Length:[ \t]*([0-9]+)} $line -> n]} {
          set PDK_IMPORT(total) $n
        }
      }
    }
    if {[catch {set PDK_IMPORT(pid) [exec $curl -L --fail --retry 2 \
        -o $PDK_IMPORT(dest) $url &]} err]} {
      pdk_log "curl failed to start: $err"
      pdk_import_download_next
      return
    }
  } elseif {$wget != ""} {
    if {[catch {set PDK_IMPORT(pid) [exec $wget -O $PDK_IMPORT(dest) $url &]} err]} {
      pdk_log "wget failed to start: $err"
      pdk_import_download_next
      return
    }
  } else {
    pdk_import_fail "Neither curl nor wget is installed in this environment."
    return
  }

  set PDK_IMPORT(phase) download
  set PDK_IMPORT(after) [after 400 pdk_import_poll_download]
}

proc pdk_import_poll_download {} {
  global PDK_IMPORT
  set PDK_IMPORT(after) ""

  if {[pdk_cancelled]} {
    catch {exec kill $PDK_IMPORT(pid)}
    pdk_import_fail "Cancelled."
    return
  }

  set got 0
  if {[file exists $PDK_IMPORT(dest)]} {
    catch {set got [file size $PDK_IMPORT(dest)]}
  }
  set mb [expr {$got / 1048576.0}]
  if {$PDK_IMPORT(total) > 0} {
    set pct [expr {int($got * 70.0 / $PDK_IMPORT(total))}]
    if {$pct > 70} { set pct 70 }
    set totmb [expr {$PDK_IMPORT(total) / 1048576.0}]
    _pdk_import_progress_update $pct \
        [format "Downloading... %d%%  (%.1f / %.1f MB)" $pct $mb $totmb]
  } else {
    set pct [expr {int(5 + $mb)}]
    if {$pct > 65} { set pct 65 }
    _pdk_import_progress_update $pct [format "Downloading... %.1f MB" $mb]
  }

  set alive 1
  if {$PDK_IMPORT(pid) != ""} {
    if {[catch {exec kill -0 $PDK_IMPORT(pid)}]} {
      set alive 0
    }
  }

  if {$alive} {
    set PDK_IMPORT(after) [after 400 pdk_import_poll_download]
    return
  }

  # curl/wget finished
  if {![file exists $PDK_IMPORT(dest)] || $got < 100} {
    pdk_log "Download empty or tiny ($got bytes), trying next URL"
    pdk_import_download_next
    return
  }
  if {![catch {set fh [open $PDK_IMPORT(dest) r]}]} {
    set head [read $fh 64]
    close $fh
    if {[regexp -nocase {^<!DOCTYPE|^<html} $head]} {
      pdk_log "Download looks like HTML (404?), trying next URL"
      pdk_import_download_next
      return
    }
  }
  _pdk_import_progress_update 70 "Download complete — unpacking..."
  pdk_import_unpack
}

proc pdk_import_unpack {} {
  global PDK_IMPORT

  if {[pdk_cancelled]} {
    pdk_import_fail "Cancelled."
    return
  }

  set dest $PDK_IMPORT(dest)
  set src $PDK_IMPORT(src)
  set tar [pdk_which {tar /bin/tar /usr/bin/tar}]
  set unzip [pdk_which {unzip /usr/bin/unzip}]
  set filebin [pdk_which {file /usr/bin/file}]

  set cmd ""
  set magic ""
  if {$filebin != ""} {
    if {[catch {set magic [exec $filebin -b $dest]}]} {
      set magic ""
    }
  }
  pdk_log "Archive type: $magic"

  if {[string match *gzip* [string tolower $magic]] || \
      [string match *.tar.gz [string tolower $dest]] || \
      [string match *.tgz [string tolower $dest]]} {
    set cmd [list $tar -xzf $dest -C $src]
  } elseif {[string match *tar* [string tolower $magic]] || \
            [string match *.tar [string tolower $dest]]} {
    set cmd [list $tar -xf $dest -C $src]
  } elseif {[string match *zip* [string tolower $magic]] || \
            [string match *.zip [string tolower $dest]]} {
    if {$unzip == ""} {
      pdk_import_fail "unzip is not installed; cannot extract ZIP."
      return
    }
    set cmd [list $unzip -q -o $dest -d $src]
  } else {
    # Try tar anyway (GitHub often serves gzip without a useful file(1) string)
    set cmd [list $tar -xzf $dest -C $src]
  }

  if {[lindex $cmd 0] == ""} {
    pdk_import_fail "tar is not installed."
    return
  }

  pdk_log "Unpack: $cmd"
  if {[catch {set PDK_IMPORT(pid) [eval exec $cmd &]} err]} {
    pdk_import_fail "Unpack failed to start:\n$err"
    return
  }
  set PDK_IMPORT(phase) unpack
  set PDK_IMPORT(after) [after 400 pdk_import_poll_unpack]
}

proc pdk_import_poll_unpack {} {
  global PDK_IMPORT
  set PDK_IMPORT(after) ""

  if {[pdk_cancelled]} {
    catch {exec kill $PDK_IMPORT(pid)}
    pdk_import_fail "Cancelled."
    return
  }

  _pdk_import_progress_update 78 "Unpacking archive..."

  set alive 1
  if {$PDK_IMPORT(pid) != ""} {
    if {[catch {exec kill -0 $PDK_IMPORT(pid)}]} {
      set alive 0
    }
  }
  if {$alive} {
    set PDK_IMPORT(after) [after 400 pdk_import_poll_unpack]
    return
  }

  _pdk_import_progress_update 85 "Converting to MAX technology..."
  pdk_import_convert
}

proc pdk_import_convert {} {
  global PDK_IMPORT env

  if {[pdk_cancelled]} {
    pdk_import_fail "Cancelled."
    return
  }

  set family $PDK_IMPORT(family)
  set blob [string tolower "$family $PDK_IMPORT(src) [join $PDK_IMPORT(urls)]"]
  if {$family == ""} {
    if {[string match *sky130* $blob] || [string match *skywater* $blob]} {
      set family sky130A
    } elseif {[string match *gf180* $blob]} {
      set family gf180mcu
    } elseif {[string match *sg13g2* $blob] || [string match *ihp* $blob]} {
      set family sg13g2
    }
    set PDK_IMPORT(family) $family
  }

  set rows {}
  if {$family == "sky130A"} {
    set rows [pdk_layers_sky130A]
  } elseif {$family == "gf180mcu"} {
    set rows [pdk_layers_gf180mcu]
  } elseif {$family == "sg13g2"} {
    set rows [pdk_layers_sg13g2]
  }

  if {![llength $rows]} {
    set techs [pdk_find_files $PDK_IMPORT(src) {*.tech}]
    foreach t $techs {
      if {[string match *.tech27 $t]} continue
      set rows [pdk_parse_magic_tech $t]
      if {[llength $rows]} {
        pdk_log "Parsed Magic tech $t ([llength $rows] layers)"
        break
      }
    }
  }

  if {![llength $rows]} {
    pdk_import_fail "No layers found. Use a SKY130A / GF180MCU / IHP SG13G2 preset, or a PDK with a Magic .tech file."
    return
  }

  set tech $PDK_IMPORT(tech)
  if {$tech == "" || $tech == "auto"} {
    if {$family != ""} {
      set tech [pdk_sanitize $family]
    } else {
      set tech pdk
    }
    set PDK_IMPORT(tech) $tech
  }

  set home ""
  if {[info exists env(HOME)]} { set home $env(HOME) }
  if {$home == ""} { set home /mmi-home }
  set techdir [pdk_shared_max_techdir $tech]
  if {![file isdirectory $techdir]} {
    set techdir [file join $home mmi_private max tech $tech]
    file mkdir $techdir
  }
  pdk_link_max_private $tech $techdir
  set source [file join $techdir ${tech}.source]

  _pdk_import_progress_update 90 "Writing $source"
  if {[catch {
    set fh [open $source w]
    puts $fh "# MAX technology source generated by pdk_import.tcl"
    puts $fh "# family $family"
    puts $fh ""
    puts $fh "# layer\tgds:dt\ttxt:dt\ttype\twidth\tspace\tcolor"
    puts $fh "#======\t======\t======\t====\t=====\t=====\t====="
    foreach rec $rows {
      puts $fh [join $rec "\t"]
    }
    puts $fh ""
    foreach line [pdk_connect_lines $rows] {
      puts $fh $line
    }
    close $fh
  } err]} {
    pdk_import_fail "Could not write $source:\n$err"
    return
  }
  pdk_log "Wrote $source ([llength $rows] layers)"

  _pdk_import_progress_update 94 "Running make_tech..."
  set make [pdk_which {make_tech}]
  if {$make == "" && [info exists env(MMI_TOOLS)]} {
    foreach cand [list [file join $env(MMI_TOOLS) bin make_tech]] {
      if {[file executable $cand]} { set make $cand; break }
    }
  }

  set home ""
  if {[info exists env(HOME)]} { set home $env(HOME) }
  if {$home == ""} { set home /mmi-home }
  set privdir [file join $home mmi_private max tech $tech]

  set mtok failed
  if {$make != ""} {
    pdk_log "make_tech -r -file $source -tech $tech"
    if {[catch {set out [exec $make -r -file $source -tech $tech]} err]} {
      pdk_log "make_tech: $err"
    } else {
      pdk_log $out
    }
  } else {
    pdk_log "make_tech not found"
  }

  if {[pdk_find_tech27 $tech] == ""} {
    foreach dir [list $techdir $privdir] {
      if {[pdk_compile_tech27 $dir $tech]} { break }
    }
  }
  if {[pdk_find_tech27 $tech] != ""} {
    set mtok ok
    pdk_log "MAX tech27 [pdk_find_tech27 $tech]"
  } else {
    pdk_log "No ${tech}.tech27 after make_tech (need mmi_cpp + mmi_m4 on PATH)"
  }

  set gds ""
  set libpaths {}
  set ref [file join $PDK_IMPORT(src) libs.ref]
  if {[file isdirectory $ref]} {
    foreach lib [glob -nocomplain [file join $ref *]] {
      if {![file isdirectory $lib]} continue
      foreach sub {gds mag maglef lef} {
        set p [file join $lib $sub]
        if {[file isdirectory $p]} {
          lappend libpaths $p
        }
      }
    }
  } else {
    set gds_files [pdk_find_files $PDK_IMPORT(src) {*.gds *.gds.gz *.strm}]
    if {[llength $gds_files]} {
      set gds [lindex $gds_files 0]
    }
    foreach f [pdk_find_files $PDK_IMPORT(src) {*.gds *.lef *.max}] {
      set d [file dirname $f]
      set dl [string tolower $d]
      if {[string match *gds* $dl] || [string match *lef* $dl] || \
          [string match *libs.ref* $dl] || [string match *library* $dl]} {
        if {[lsearch -exact $libpaths $d] < 0} {
          lappend libpaths $d
        }
      }
      if {[llength $libpaths] >= 12} break
    }
  }

  _pdk_import_progress_update 88 "Installing into shared PDK_ROOT [pdk_root]..."
  set shared [pdk_install_into_root $PDK_IMPORT(src) $family $tech]
  if {$shared != ""} {
    pdk_log "Shared PDK at $shared"
    set sref [file join $shared libs.ref]
    if {[file isdirectory $sref]} {
      foreach lib [glob -nocomplain [file join $sref *]] {
        if {![file isdirectory $lib]} continue
        foreach sub {gds mag maglef lef} {
          set p [file join $lib $sub]
          if {[file isdirectory $p] && [lsearch -exact $libpaths $p] < 0} {
            lappend libpaths $p
          }
        }
      }
    }
  }

  _pdk_import_progress_update 100 "PDK ready as MAX technology '$tech'"
  pdk_import_succeed $tech $family [llength $rows] $mtok $gds $libpaths $source $shared
}

proc pdk_import_fail {msg} {
  global PDK_IMPORT
  _pdk_import_progress_close
  pdk_log "ERROR: $msg"
  max_error "PDK import failed.\n$msg\nLog: $PDK_IMPORT(log)"
}

proc pdk_import_succeed {tech family layers mtok gds libpaths source {shared ""}} {
  global PDK_IMPORT
  _pdk_import_progress_close

  foreach d $libpaths {
    if {$d != "" && [file isdirectory $d]} {
      catch {cell_path_add $d}
    }
  }

  set note ""
  if {$mtok != "ok"} {
    set note "\n\nmake_tech did not compile the tech. Source is still at:\n  $source\nRun:  make_tech -r -file $source -tech $tech"
  }

  set magicrc_note "Magic mag2gds looks for:\n  [pdk_root]/<pdk>/libs.tech/magic/<pdk>.magicrc\nUse File → Import PDK (not a skywater-pdk GitHub zip) so stdcells and Magic tech are present."
  if {$shared != "" && [pdk_tree_ready $shared]} {
    set magicrc_note "Magic-compiled open_pdks tree at:\n  $shared\nlibs.tech/magic + libs.ref (stdcells) are in place for mag2gds."
  } elseif {$shared != ""} {
    set magicrc_note "Copied into shared PDK_ROOT:\n  $shared\nlibs.tech/magic/*.magicrc or libs.ref is still missing."
  }

  set summary "PDK converted and installed (shared folder, no extra copy for MAX tech).\n\n\
Technology: $tech\n\
Family: $family\n\
Layers: $layers\n\
MAX tech: [file dirname $source]\n\
PDK_ROOT: [pdk_root]\n\
\n$magicrc_note\n\
\nStart MAX with:\n  max -tech $tech\n$note"

  if {$gds != "" && [file exists $gds]} {
    append summary "\n\nSample GDS:\n  $gds"
  }
  if {[catch {warning $summary}]} {
    puts $summary
  }

  if {$mtok != "ok"} {
    return
  }
  if {$gds != "" && [file exists $gds]} {
    catch {exec max -tech $tech $gds &}
  } else {
    catch {exec max -tech $tech &}
  }
}

# ── Progress UI ──────────────────────────────────────────────────────────────
proc _pdk_import_progress_open {} {
  catch {destroy .pdkprog}
  toplevel .pdkprog
  wm title .pdkprog "Import PDK"
  wm geometry .pdkprog +80+80
  catch {wm transient .pdkprog .}

  set f .pdkprog.f
  frame $f -bd 8
  pack $f -fill both -expand 1

  label $f.title -text "Fitting PDK into MAX"
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
  button $f.btns.cancel -text "Cancel" -command pdk_import_cancel
  pack $f.btns.cancel -side right
  update idletasks
}

proc _pdk_import_progress_close {} {
  global PDK_IMPORT
  if {$PDK_IMPORT(after) != ""} {
    catch {after cancel $PDK_IMPORT(after)}
    set PDK_IMPORT(after) ""
  }
  catch {destroy .pdkprog}
}

proc _pdk_import_progress_update {percent message} {
  if {![winfo exists .pdkprog.f.bar]} { return }
  if {![regexp {^[0-9]+$} $percent]} { set percent 0 }
  if {$percent < 0} { set percent 0 }
  if {$percent > 100} { set percent 100 }
  set w [winfo width .pdkprog.f.bar]
  if {$w < 10} { set w 420 }
  set x [expr {int($w * $percent / 100.0)}]
  .pdkprog.f.bar coords fill 0 0 $x 22
  .pdkprog.f.bar itemconfigure pct -text "${percent}%"
  .pdkprog.f.stage configure -text $message
  .pdkprog.f.pctlab configure -text "${percent}%"
  update idletasks
}

proc pdk_import_cancel {} {
  global PDK_IMPORT
  if {$PDK_IMPORT(cancel) != ""} {
    catch {
      set fh [open $PDK_IMPORT(cancel) w]
      puts $fh cancel
      close $fh
    }
  }
  if {$PDK_IMPORT(pid) != ""} {
    catch {exec kill $PDK_IMPORT(pid)}
  }
  _pdk_import_progress_update 0 "Cancelling..."
}

proc _pdk_import_install_menus {} {
  catch {
    menu_local_cmd "Import PDK..." pdk_import_dialog \
        "Download a compiled open_pdks tree (SKY130A, GF180MCU, IHP) after MAX starts"
  }
  if {![catch {_menu_get_widget File}]} {
    catch {
      menu_add_cmd [_menu_get_widget File] "Import PDK..." \
          pdk_import_dialog \
          -desc "Download a PDK into /mmi-pdks when you choose to (not via Nix)"
    }
  }
}

_pdk_import_install_menus
