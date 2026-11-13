# Importer engine. Sourced by importer.tcl. Tcl 8.5+ (the CAD wish/tclsh).
# Drives fetch_pdk.sh, compile_tech.sh, and gen_sue_lib.tcl.
# MAX does not source this file.

set IMPORTER_SUE_REV 1
set IMPORTER_CACHE ""

proc importer_dir {} {
  return [file dirname [info script]]
}

proc importer_bundle {} {
  global env
  set here [importer_dir]
  if {[file readable [file join $here registry.json]]} { return $here }
  foreach d {/mmi-pdk-live/importer /mmi-bundle/importer} {
    if {[file readable [file join $d registry.json]]} { return $d }
  }
  return $here
}

proc importer_source_libs {} {
  set b [importer_bundle]
  set parent [file dirname $b]
  set common ""
  foreach f [list \
      [file join $parent pdk_common.tcl] \
      /mmi-pdk-live/pdk_common.tcl \
      /mmi-bundle/pdk_common.tcl] {
    if {[file readable $f]} { set common $f; break }
  }
  if {$common != ""} { uplevel #0 [list source $common] }
  set tables [file join $b pdk_tables.tcl]
  if {[file readable $tables]} { uplevel #0 [list source $tables] }
}
importer_source_libs

proc importer_pdk_root {} {
  global env
  if {[info exists env(PDK_ROOT)] && $env(PDK_ROOT) != ""} {
    return $env(PDK_ROOT)
  }
  if {[info commands pdk_root] != ""} { return [pdk_root] }
  return /mmi-pdks
}

proc importer_read_json {path} {
  set py [auto_execok python3]
  if {$py == ""} { set py [auto_execok python] }
  if {$py == ""} { return "" }
  if {[catch {exec $py -c {
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
def emit(prefix, obj):
    if isinstance(obj, dict):
        for k, v in obj.items():
            emit(prefix + "." + k, v)
    elif isinstance(obj, list):
        if obj and isinstance(obj[0], dict):
            for i, item in enumerate(obj):
                emit(prefix + "[" + str(i) + "]", item)
        else:
            print(prefix + "=" + " ".join(str(x) for x in obj))
    else:
        print(prefix + "=" + str(obj))
emit("root", data)
} $path} out]} {
    return ""
  }
  return $out
}

proc importer_registry_text {} {
  set path [file join [importer_bundle] registry.json]
  set text [importer_read_json $path]
  set url ""
  regexp {root\.registry_url=([^\n]*)} $text -> url
  set url [string trim $url]
  if {$url != "" && $url != "null"} {
    set cache [file join [importer_pdk_root] registry catalogue.json]
    file mkdir [file dirname $cache]
    set curl [auto_execok curl]
    if {$curl != "" && ![catch {exec $curl -fsSL --max-time 20 -o $cache $url}]} {
      set alt [importer_read_json $cache]
      if {$alt != ""} { return $alt }
    }
  }
  return $text
}

proc importer_parse_groups {text} {
  set cur ""
  set kind ""
  set item {}
  set items {}
  foreach line [split $text \n] {
    if {![regexp {^root\.([a-z]+)\[(\d+)\]\.([A-Za-z0-9_]+)=(.*)$} $line -> grp idx key val]} {
      continue
    }
    if {$cur != "$grp $idx"} {
      if {$item != ""} { lappend items [list $kind $item] }
      set cur "$grp $idx"
      set kind $grp
      set item {}
    }
    lappend item $key $val
  }
  if {$item != ""} { lappend items [list $kind $item] }
  return $items
}

proc importer_builtin_items {} {
  return [list \
      [list pdks [list name sky130A process "SkyWater 130nm" dir sky130A \
          family sky130A max_tech sky130A sue_lib sky130A license Apache-2.0 \
          tag sky130-e8daeda73ca8f5814dbc0b11d1d05802251a3750 \
          description "open_pdks sky130A"]] \
      [list pdks [list name gf180mcuD process "GlobalFoundries 180nm MCU" \
          dir gf180mcuD family gf180mcu max_tech gf180mcu sue_lib gf180mcu \
          license Apache-2.0 tag gf180mcu-0fe599b2afb6708d281543108caf8310912f54af \
          description "open_pdks gf180mcuD"]] \
      [list pdks [list name ihp-sg13g2 process "IHP 130nm SiGe" dir ihp-sg13g2 \
          family sg13g2 max_tech sg13g2 sue_lib sg13g2 license Apache-2.0 \
          tag ihp-sg13g2-ddb601a4a4473163e1ed6df416b885df18b4ac03 \
          description "IHP SG13G2"]]]
}

# Extra rows replace a built-in with the same name, then new names are appended.
proc importer_merge_extra {items extra} {
  set out {}
  foreach pair $items {
    set kind [lindex $pair 0]
    set item [lindex $pair 1]
    if {$kind != "pdks"} {
      lappend out $pair
      continue
    }
    set name [importer_field $item name]
    set repl ""
    foreach e $extra {
      if {[importer_field $e name] == $name} { set repl $e }
    }
    if {$repl != ""} {
      lappend out [list pdks $repl]
    } else {
      lappend out $pair
    }
  }
  foreach e $extra {
    set name [importer_field $e name]
    set seen 0
    foreach pair $out {
      if {[lindex $pair 0] == "pdks" && [importer_field [lindex $pair 1] name] == $name} {
        set seen 1
      }
    }
    if {!$seen} { lappend out [list pdks $e] }
  }
  return $out
}

proc importer_load {} {
  global IMPORTER_CACHE
  if {$IMPORTER_CACHE != ""} { return $IMPORTER_CACHE }
  set text [importer_registry_text]
  if {$text == ""} {
    set items [importer_builtin_items]
  } else {
    set items [importer_parse_groups $text]
  }
  set IMPORTER_CACHE [importer_merge_extra $items [importer_extra_items]]
  return $IMPORTER_CACHE
}

proc importer_forget {} {
  global IMPORTER_CACHE
  set IMPORTER_CACHE ""
}

proc importer_catalogue {} {
  set out {}
  foreach pair [importer_load] {
    if {[lindex $pair 0] == "pdks"} { lappend out [lindex $pair 1] }
  }
  return $out
}

proc importer_libraries {} {
  set out {}
  foreach pair [importer_load] {
    if {[lindex $pair 0] == "libraries"} { lappend out [lindex $pair 1] }
  }
  return $out
}

proc importer_field {item key} {
  set i [lsearch -exact $item $key]
  if {$i < 0} { return "" }
  return [lindex $item [expr {$i + 1}]]
}

proc importer_by_name {name} {
  foreach item [importer_catalogue] {
    set n [importer_field $item name]
    set fam [importer_field $item family]
    set tech [importer_field $item max_tech]
    set lib [importer_field $item sue_lib]
    if {$name == $n || $name == $fam || $name == $tech || $name == $lib} {
      return $item
    }
  }
  return ""
}

proc importer_short_tag {item} {
  set tag [importer_field $item tag]
  set dash [string last - $tag]
  if {$dash >= 0} { set tag [string range $tag [expr {$dash + 1}] end] }
  if {[string length $tag] > 7} { set tag [string range $tag 0 6] }
  return $tag
}

proc importer_tech_file {tech} {
  return [file join [importer_pdk_root] max tech $tech ${tech}.tech27]
}

proc importer_tech_ok {tech} {
  if {[info commands pdk_find_tech27] != ""} {
    return [expr {[pdk_find_tech27 $tech] != ""}]
  }
  return [file readable [importer_tech_file $tech]]
}

proc importer_lib_file {lib} {
  return [file join [importer_pdk_root] sue lib $lib LIBRARY]
}

proc importer_lib_ok {lib} {
  set f [importer_lib_file $lib]
  if {![file readable $f]} { return 0 }
  set fh [open $f r]
  set rev 0
  while {[gets $fh line] >= 0} {
    if {[regexp {^revision ([0-9]+)} $line -> rev]} break
  }
  close $fh
  global IMPORTER_SUE_REV
  return [expr {$rev >= $IMPORTER_SUE_REV}]
}

proc importer_tree_ok {dir} {
  if {[info commands pdk_tree_ready] != ""} { return [pdk_tree_ready $dir] }
  if {![file isdirectory [file join $dir libs.tech magic]]} { return 0 }
  if {![file isdirectory [file join $dir libs.ref]]} { return 0 }
  return 1
}

proc importer_state {item} {
  set dir [file join [importer_pdk_root] [importer_field $item dir]]
  set tech [importer_field $item max_tech]
  set lib [importer_field $item sue_lib]
  set tree [importer_tree_ok $dir]
  set tech_file [file readable [importer_tech_file $tech]]
  set techok [importer_tech_ok $tech]
  set lib_file [file readable [importer_lib_file $lib]]
  set libok [importer_lib_ok $lib]
  if {$tree && $techok && $libok} { return installed }
  if {$tree && $tech_file && !$techok} { return broken }
  if {$tree && (!$techok || !$libok)} {
    if {$tech_file || $lib_file} { return outdated }
    return convert
  }
  set fam [importer_field $item family]
  set cache [file join [importer_pdk_root] .fetch-$fam dl]
  if {[llength [glob -nocomplain [file join $cache *.tar.zst]]]} { return resume }
  if {[file exists $dir]} { return broken }
  return missing
}

proc importer_log {msg} {
  global IMPORTER_LOG
  puts $msg
  if {[info exists IMPORTER_LOG] && $IMPORTER_LOG != ""} {
    catch {
      set fh [open $IMPORTER_LOG a]
      puts $fh $msg
      close $fh
    }
  }
  if {[info commands importer_log_window] != ""} {
    catch {importer_log_window $msg}
  }
}

proc importer_apply_status {path} {
  if {![file readable $path]} { return }
  if {[catch {set fh [open $path r]}]} { return }
  set text [read $fh]
  close $fh
  set pct 0
  set msg ""
  regexp {PCT=([0-9]+)} $text -> pct
  regexp {MSG=([^\n]*)} $text -> msg
  if {[info commands importer_set_progress] != ""} {
    importer_set_progress $pct $msg
  }
}

proc importer_run {args} {
  set status ""
  if {[lindex $args 0] == "-status"} {
    set status [lindex $args 1]
    set args [lrange $args 2 end]
  }
  importer_log "run: $args"
  if {[catch {set pipe [open |$args r]} err]} {
    importer_log $err
    return 0
  }
  fconfigure $pipe -blocking 0
  while {1} {
    if {[catch {set chunk [read $pipe]}]} { set chunk "" }
    if {$chunk != ""} { importer_log [string trimright $chunk] }
    if {$status != ""} { importer_apply_status $status }
    if {[eof $pipe]} break
    after 200
  }
  set rc [catch {close $pipe} err]
  if {$rc} {
    importer_log $err
    return 0
  }
  return 1
}

proc importer_flag {name default} {
  if {![info exists ::$name]} { return $default }
  return [set ::$name]
}

proc importer_magic_tech_file {item} {
  set dir [file join [importer_pdk_root] [importer_field $item dir] libs.tech magic]
  set prefer [importer_field $item dir]
  set best ""
  foreach f [glob -nocomplain [file join $dir *.tech]] {
    if {[string match *$prefer* [file tail $f]]} { return $f }
    if {$best == ""} { set best $f }
  }
  return $best
}

proc importer_write_source {item} {
  set tech [importer_field $item max_tech]
  set fam [importer_field $item family]
  set dest [file join [importer_pdk_root] max tech $tech]
  file mkdir $dest
  set source [file join $dest ${tech}.source]
  if {[info commands pdk_write_source] == ""} {
    return "pdk_write_source is not loaded"
  }
  set n [pdk_write_source $fam $tech $source]
  if {$n == 0 || ![file readable $source]} {
    set rows {}
    set techfile [importer_magic_tech_file $item]
    if {$techfile != "" && [info commands pdk_parse_magic_tech] != ""} {
      set rows [pdk_parse_magic_tech $techfile]
    }
    if {![llength $rows]} {
      return "No layer table for $fam, and the Magic tech has no cifoutput layers."
    }
    importer_log "MAX technology from [file tail $techfile] ([llength $rows] layers)"
    if {![pdk_write_source $fam $tech $source $rows]} {
      return "Could not write $source"
    }
  }
  return $source
}

proc importer_compile {source tech} {
  set dest [file dirname $source]
  set sh ""
  foreach c [list \
      [file join [file dirname [importer_bundle]] compile_tech.sh] \
      /mmi-pdk-live/compile_tech.sh \
      /mmi-bundle/compile_tech.sh] {
    if {[file readable $c]} { set sh $c; break }
  }
  if {$sh == ""} { return "compile_tech.sh not found" }
  set status [file join $dest compile.status]
  set log [file join $dest compile.log]
  if {![importer_run -status $status bash $sh $source $tech $dest $status "" $log]} {
    return "compile_tech.sh failed (see $log)"
  }
  return ""
}

proc importer_sue_lib {item} {
  set pdkdir [file join [importer_pdk_root] [importer_field $item dir]]
  set lib [importer_field $item sue_lib]
  set tech [importer_field $item max_tech]
  set dest [file join [importer_pdk_root] sue lib $lib]
  set gen ""
  foreach c [list \
      [file join [file dirname [importer_bundle]] sue gen_sue_lib.tcl] \
      /mmi-pdk-live/sue/gen_sue_lib.tcl \
      /mmi-bundle/sue/gen_sue_lib.tcl] {
    if {[file readable $c]} { set gen $c; break }
  }
  if {$gen == ""} { return "gen_sue_lib.tcl not found" }
  set tcl [auto_execok tclsh]
  if {$tcl == ""} { set tcl [auto_execok tclsh8.6] }
  if {$tcl == ""} { return "tclsh not found" }
  set tag [importer_field $item tag]
  if {![importer_run $tcl $gen $pdkdir $dest $lib $tech $tag]} {
    return "SUE library generation failed"
  }
  return ""
}

proc importer_json_escape {s} {
  regsub -all {\\} $s {\\\\} s
  regsub -all {"} $s {\\"} s
  return $s
}

proc importer_installed_path {} {
  return [file join [importer_pdk_root] registry installed.json]
}

proc importer_load_records {} {
  set path [importer_installed_path]
  if {![file readable $path]} { return {} }
  if {[catch {set fh [open $path r]}]} { return {} }
  set text [read $fh]
  close $fh
  set recs {}
  foreach block [regexp -all -inline {\{[^{}]*\}} $text] {
    set rec {}
    set pairs [regexp -all -inline {"([A-Za-z0-9_]+)":"((?:\\.|[^"\\])*)"} $block]
    foreach {all k v} $pairs {
      regsub -all {\\"} $v "\"" v
      regsub -all {\\\\} $v "\\" v
      lappend rec $k $v
    }
    if {$rec != ""} { lappend recs $rec }
  }
  return $recs
}

proc importer_save_records {recs} {
  set path [importer_installed_path]
  file mkdir [file dirname $path]
  set fh [open $path w]
  puts $fh "\["
  set n [llength $recs]
  set i 0
  foreach rec $recs {
    set parts {}
    foreach {k v} $rec {
      lappend parts "\"$k\":\"[importer_json_escape $v]\""
    }
    incr i
    set comma ","
    if {$i == $n} { set comma "" }
    puts $fh "  {[join $parts ,]}$comma"
  }
  puts $fh "\]"
  close $fh
}

proc importer_now {} {
  return [clock format [clock seconds] -gmt 1 -format {%Y-%m-%dT%H:%M:%SZ}]
}

proc importer_make_rec {name kind version gen path} {
  return [list name $name kind $kind version $version gen $gen path $path time [importer_now]]
}

proc importer_record {item} {
  global PDK_GEN_REQUIRED IMPORTER_SUE_REV
  set root [importer_pdk_root]
  set name [importer_field $item name]
  set ver [importer_short_tag $item]
  if {![info exists PDK_GEN_REQUIRED]} { set PDK_GEN_REQUIRED 8 }
  set recs {}
  foreach rec [importer_load_records] {
    if {[importer_field $rec name] == $name} continue
    lappend recs $rec
  }
  lappend recs [importer_make_rec $name pdk $ver 0 \
      [file join $root [importer_field $item dir]]]
  lappend recs [importer_make_rec $name max_tech $ver $PDK_GEN_REQUIRED \
      [file join $root max tech [importer_field $item max_tech]]]
  lappend recs [importer_make_rec $name sue_lib $ver $IMPORTER_SUE_REV \
      [file join $root sue lib [importer_field $item sue_lib]]]
  importer_save_records $recs
}

proc importer_adopt {} {
  set recs [importer_load_records]
  set changed 0
  foreach item [importer_catalogue] {
    set name [importer_field $item name]
    set dir [file join [importer_pdk_root] [importer_field $item dir]]
    if {![importer_tree_ok $dir]} continue
    set have 0
    foreach rec $recs {
      if {[importer_field $rec name] == $name && [importer_field $rec kind] == "pdk"} {
        set have 1
      }
    }
    if {$have} continue
    importer_record $item
    set changed 1
    set recs [importer_load_records]
  }
  return $changed
}

proc importer_under_root {root path} {
  set root [string trimright $root /]
  set path [string trimright $path /]
  if {$path == "" || $path == $root} { return 0 }
  if {[string match $root/* $path]} { return 1 }
  return 0
}

proc importer_delete_path {root path} {
  if {![importer_under_root $root $path]} {
    return "Refusing to remove $path (outside $root)"
  }
  if {![file exists $path] && ![file readable $path]} {
    if {[catch {file type $path} kind]} { return "" }
  }
  if {[catch {set kind [file type $path]}]} { return "" }
  if {$kind == "link"} {
    file delete $path
  } else {
    file delete -force $path
  }
  return ""
}

proc importer_install {name {progress ""}} {
  global env
  set item [importer_by_name $name]
  if {$item == ""} { return "Unknown PDK or library '$name'. Run: importer --list" }
  set root [importer_pdk_root]
  file mkdir $root
  set fam [importer_field $item family]
  set dir [file join $root [importer_field $item dir]]
  set do_tech [importer_flag IMPORTER_DO_TECH 1]
  set do_lib [importer_flag IMPORTER_DO_LIB 1]
  if {![importer_flag IMPORTER_DO_EXTRA 0]} {
    catch {unset env(MMI_PDK_LIBS)}
  }
  if {[info exists env(MMI_PDK_LOCAL)] && $env(MMI_PDK_LOCAL) == ""} {
    unset env(MMI_PDK_LOCAL)
  }
  foreach key {MMI_CIEL_TAG MMI_PDK_ASSETS MMI_PDK_BASE MMI_PDK_ARCHIVE_URL MMI_PDK_VARIANT} {
    catch {unset env($key)}
  }
  set tag [importer_field $item tag]
  set assets [importer_field $item assets]
  set base [importer_field $item base]
  set archive [importer_field $item archive]
  set variant [importer_field $item dir]
  if {$tag != "" && $tag != "local-archive"} { set env(MMI_CIEL_TAG) $tag }
  if {$assets != ""} { set env(MMI_PDK_ASSETS) $assets }
  if {$base != ""} { set env(MMI_PDK_BASE) $base }
  if {$archive != ""} { set env(MMI_PDK_ARCHIVE_URL) $archive }
  if {$variant != ""} { set env(MMI_PDK_VARIANT) $variant }
  if {![importer_tree_ok $dir]} {
    set sh ""
    foreach c [list \
        [file join [file dirname [importer_bundle]] fetch_pdk.sh] \
        /mmi-pdk-live/fetch_pdk.sh \
        /mmi-bundle/fetch_pdk.sh] {
      if {[file readable $c]} { set sh $c; break }
    }
    if {$sh == ""} { return "fetch_pdk.sh not found" }
    set work [file join $root .importer-$fam]
    file mkdir $work
    set status [file join $work status]
    set cancel [file join $work CANCEL]
    set ::IMPORTER_CANCEL $cancel
    file delete -force $cancel
    set watch ""
    if {$progress != ""} { set watch $status }
    if {![importer_run -status $watch bash $sh $fam $status $cancel]} {
      return "Download failed. See the log next to $status"
    }
  }
  if {![importer_tree_ok $dir]} {
    return "open_pdks tree is not complete at $dir"
  }
  if {$do_tech} {
    set source [importer_write_source $item]
    if {![file readable $source]} { return $source }
    set err [importer_compile $source [importer_field $item max_tech]]
    if {$err != ""} { return $err }
  }
  if {$do_lib} {
    set err [importer_sue_lib $item]
    if {$err != ""} { return $err }
  }
  importer_record $item
  return ""
}

proc importer_uninstall {name} {
  set item [importer_by_name $name]
  if {$item == ""} { return "Unknown '$name'" }
  set root [importer_pdk_root]
  set root [string trimright $root /]
  set paths {}
  set kept {}
  set found 0
  foreach rec [importer_load_records] {
    if {[importer_field $rec name] != $name && \
        [importer_field $rec name] != [importer_field $item name]} {
      lappend kept $rec
      continue
    }
    set found 1
    set p [importer_field $rec path]
    if {$p != ""} { lappend paths $p }
  }
  if {!$found} {
    lappend paths [file join $root [importer_field $item dir]]
    lappend paths [file join $root max tech [importer_field $item max_tech]]
    lappend paths [file join $root sue lib [importer_field $item sue_lib]]
  }
  foreach path $paths {
    set err [importer_delete_path $root $path]
    if {$err != ""} { return $err }
  }
  importer_save_records $kept
  return ""
}

proc importer_repair {} {
  set n 0
  foreach item [importer_catalogue] {
    set dir [file join [importer_pdk_root] [importer_field $item dir]]
    if {![importer_tree_ok $dir]} continue
    set st [importer_state $item]
    if {$st == "installed"} continue
    importer_log "repair $st [importer_field $item name]"
    set err [importer_install [importer_field $item name]]
    if {$err != ""} {
      importer_log "repair failed: $err"
    } else {
      incr n
    }
  }
  return $n
}

proc importer_extra_path {} {
  return [file join [importer_pdk_root] registry extra.json]
}

proc importer_extra_items {} {
  set path [importer_extra_path]
  if {![file readable $path]} { return {} }
  set text [importer_read_json $path]
  if {$text == ""} { return {} }
  set out {}
  foreach pair [importer_parse_groups $text] {
    if {[lindex $pair 0] == "pdks"} { lappend out [lindex $pair 1] }
  }
  return $out
}

proc importer_write_extra {items} {
  set path [importer_extra_path]
  if {[catch {file mkdir [file dirname $path]} err]} { return $err }
  if {[catch {set fh [open $path w]} err]} { return $err }
  puts $fh "\{"
  puts $fh "  \"pdks\": \["
  set n [llength $items]
  set i 0
  foreach item $items {
    incr i
    puts $fh "    \{"
    set keys {name process dir family tag assets max_tech sue_lib license description base archive}
    set ki 0
    set kn [llength $keys]
    foreach k $keys {
      incr ki
      set v [importer_field $item $k]
      set comma ","
      if {$ki == $kn} { set comma "" }
      if {$k == "assets"} {
        set arr {}
        foreach a $v {
          lappend arr "\"[importer_json_escape $a]\""
        }
        puts $fh "      \"assets\": \[[join $arr ,]\]$comma"
      } else {
        puts $fh "      \"$k\": \"[importer_json_escape $v]\"$comma"
      }
    }
    set comma ","
    if {$i == $n} { set comma "" }
    puts $fh "    \}$comma"
  }
  puts $fh "  \]"
  puts $fh "\}"
  close $fh
  return ""
}

proc importer_remember_pdk {item} {
  set name [importer_field $item name]
  if {$name == ""} { return "PDK entry has no name." }
  set items [importer_extra_items]
  set out {}
  set replaced 0
  foreach e $items {
    if {[importer_field $e name] == $name} {
      lappend out $item
      set replaced 1
    } else {
      lappend out $e
    }
  }
  if {!$replaced} { lappend out $item }
  set err [importer_write_extra $out]
  if {$err != ""} { return $err }
  importer_forget
  if {$replaced} { return "updated $name" }
  return "added $name"
}

proc importer_is_url {url} {
  if {[string length $url] < 12 || [string length $url] > 2000} { return 0 }
  if {[string first " " $url] >= 0} { return 0 }
  if {[string first \n $url] >= 0 || [string first \r $url] >= 0} { return 0 }
  if {[string match https://* $url] || [string match http://* $url]} { return 1 }
  return 0
}

proc importer_http_get {url dest} {
  set curl [auto_execok curl]
  if {$curl == ""} { return "curl is not on PATH" }
  if {[catch {file mkdir [file dirname $dest]} err]} { return $err }
  if {[catch {exec $curl -fsSL --max-time 90 -A mmi-cad-importer -o $dest $url} err]} {
    return $err
  }
  if {![file readable $dest] || [file size $dest] < 2} {
    return "Empty response from $url"
  }
  return ""
}

proc importer_release_from_url {url} {
  set u [lindex [split $url ?] 0]
  set u [string trimright $u /]
  if {![regexp {^https?://github\.com/([^/]+)/([^/]+)/releases/(?:tag|download)/([^/]+)} $u -> owner repo tag]} {
    return ""
  }
  if {$owner == "" || $repo == "" || $tag == ""} { return "" }
  return [list $owner $repo $tag]
}

proc importer_release_assets {text} {
  set names {}
  foreach line [split $text \n] {
    if {[regexp {^root\.assets\[[0-9]+\]\.name=(.+)$} $line -> name]} {
      set name [string trim $name]
      if {$name != ""} { lappend names $name }
    }
  }
  return $names
}

proc importer_asset_id {filename} {
  if {[string match *.tar.zst $filename]} {
    return [string range $filename 0 end-8]
  }
  return $filename
}

proc importer_default_asset_ids {ids} {
  set out {}
  foreach n $ids {
    if {$n == "common"} { lappend out $n }
  }
  foreach n $ids {
    if {[string match *_pr $n] || [string match *_fd_pr $n] || \
        [string match *primitives* $n]} {
      if {[lsearch -exact $out $n] < 0} { lappend out $n }
    }
  }
  foreach n $ids {
    if {[string match *_io $n] || [string match *_fd_io $n]} {
      if {[lsearch -exact $out $n] < 0} { lappend out $n }
    }
  }
  set std ""
  foreach n $ids {
    if {[string match *_sc_hd $n] || [string match *stdcell* $n] || \
        [string match *_sc_mcu* $n]} {
      set std $n
      break
    }
  }
  if {$std == ""} {
    foreach n $ids {
      if {[string match *_sc_* $n]} { set std $n; break }
    }
  }
  if {$std != "" && [lsearch -exact $out $std] < 0} { lappend out $std }
  if {![llength $out]} { return $ids }
  return $out
}

proc importer_identity_from_tag {tag} {
  set stem $tag
  regexp {^(.*)-([0-9a-fA-F]{7,})$} $tag -> stem
  set low [string tolower $stem]
  if {[string match sky130* $low]} {
    return [list sky130A sky130A sky130A sky130A "SkyWater 130nm"]
  }
  if {[string match gf180* $low]} {
    return [list gf180mcuD gf180mcu gf180mcuD gf180mcu "GlobalFoundries 180nm MCU"]
  }
  if {[string match *sg13g2* $low] || [string match ihp* $low]} {
    return [list ihp-sg13g2 sg13g2 ihp-sg13g2 sg13g2 "IHP 130nm SiGe"]
  }
  set n $stem
  if {[info commands pdk_sanitize] != ""} { set n [pdk_sanitize $stem] }
  if {$n == ""} { set n pdk }
  return [list $n $n $n $n "Added from URL"]
}

proc importer_item_from_release {url owner repo tag asset_ids} {
  set id [importer_identity_from_tag $tag]
  set name [lindex $id 0]
  set family [lindex $id 1]
  set dir [lindex $id 2]
  set tech [lindex $id 3]
  set process [lindex $id 4]
  set base "https://github.com/$owner/$repo/releases/download"
  set desc "Added from $url. Libraries: [join $asset_ids {, }]."
  return [list name $name process $process dir $dir family $family \
      tag $tag assets [join $asset_ids " "] max_tech $tech sue_lib $tech \
      license "" description $desc base $base archive ""]
}

proc importer_item_from_archive {url} {
  set pathpart [lindex [split $url ?] 0]
  set bits [split $pathpart /]
  set base [lindex $bits end]
  foreach suf {.tar.zst .tar.gz .tgz .tar.xz .tar} {
    set n [string length $suf]
    set m [string length $base]
    if {$m > $n && [string range [string tolower $base] [expr {$m - $n}] end] == $suf} {
      set base [string range $base 0 [expr {$m - $n - 1}]]
      break
    }
  }
  if {[info commands pdk_sanitize] != ""} { set base [pdk_sanitize $base] }
  if {$base == ""} { set base pdk }
  set desc "Added from archive $url"
  return [list name $base process "Added from URL" dir $base family $base \
      tag local-archive assets "" max_tech $base sue_lib $base \
      license "" description $desc base "" archive $url]
}

# Returns {error msg}, {release owner repo tag ids}, {archive url},
# or {catalogue item item ...}. A release is not saved yet: the caller
# chooses which libraries to download.
proc importer_inspect_url {url} {
  if {![importer_is_url $url]} {
    return [list error "Enter an http or https URL."]
  }
  set rel [importer_release_from_url $url]
  if {$rel != ""} {
    set owner [lindex $rel 0]
    set repo [lindex $rel 1]
    set tag [lindex $rel 2]
    set api "https://api.github.com/repos/$owner/$repo/releases/tags/$tag"
    set tmp [file join [importer_pdk_root] registry url-inspect.json]
    set err [importer_http_get $api $tmp]
    if {$err != ""} {
      return [list error "Could not read that GitHub release.\n$err"]
    }
    set files [importer_release_assets [importer_read_json $tmp]]
    if {![llength $files]} {
      return [list error "That release has no downloadable files."]
    }
    set ids {}
    foreach f $files { lappend ids [importer_asset_id $f] }
    return [list release $owner $repo $tag $ids]
  }
  set pathpart [string tolower [lindex [split $url ?] 0]]
  if {[string match *.tar.zst $pathpart] || [string match *.tar.gz $pathpart] || \
      [string match *.tgz $pathpart] || [string match *.tar.xz $pathpart] || \
      [string match *.tar $pathpart]} {
    return [list archive $url]
  }
  set tmp [file join [importer_pdk_root] registry url-inspect.json]
  set err [importer_http_get $url $tmp]
  if {$err != ""} {
    return [list error "Could not download that URL.\n$err"]
  }
  set pdks {}
  foreach pair [importer_parse_groups [importer_read_json $tmp]] {
    if {[lindex $pair 0] == "pdks" && [importer_field [lindex $pair 1] name] != ""} {
      lappend pdks [lindex $pair 1]
    }
  }
  if {![llength $pdks]} {
    return [list error "That URL is not a GitHub release, a PDK archive (.tar.zst, .tar.gz, .tgz, .tar.xz), or a catalogue JSON with a pdks list."]
  }
  set result [list catalogue]
  foreach p $pdks { lappend result $p }
  return $result
}

proc importer_add_url_cli {url} {
  set got [importer_inspect_url $url]
  set kind [lindex $got 0]
  if {$kind == "error"} { return [lindex $got 1] }
  if {$kind == "catalogue"} {
    foreach item [lrange $got 1 end] {
      set msg [importer_remember_pdk $item]
      if {[string match "PDK*" $msg] || [string match "Could*" $msg]} { return $msg }
      puts $msg
    }
    return ""
  }
  if {$kind == "archive"} {
    set msg [importer_remember_pdk [importer_item_from_archive [lindex $got 1]]]
    puts $msg
    if {[string match added* $msg] || [string match updated* $msg]} { return "" }
    return $msg
  }
  if {$kind == "release"} {
    set ids [lindex $got 4]
    set use [importer_default_asset_ids $ids]
    set item [importer_item_from_release $url \
        [lindex $got 1] [lindex $got 2] [lindex $got 3] $use]
    set msg [importer_remember_pdk $item]
    puts $msg
    puts "libraries: [join $use {, }]"
    if {[string match added* $msg] || [string match updated* $msg]} { return "" }
    return $msg
  }
  return "Could not use that URL."
}

proc importer_cli {argv} {
  if {[llength $argv] == 0} { return 0 }
  set cmd [lindex $argv 0]
  set arg [lindex $argv 1]
  switch -exact -- $cmd {
    --list {
      foreach item [importer_catalogue] {
        puts "[importer_field $item name]\t[importer_field $item process]\t[importer_state $item]"
      }
      return 1
    }
    --status {
      importer_adopt
      set name $arg
      if {$name == ""} {
        foreach item [importer_catalogue] {
          puts "[importer_field $item name] [importer_state $item]"
        }
      } else {
        set item [importer_by_name $name]
        if {$item == ""} { puts "unknown $name"; exit 1 }
        puts "[importer_field $item name] [importer_state $item]"
      }
      return 1
    }
    --install {
      if {$arg == ""} { puts "usage: importer --install <name>"; exit 2 }
      set err [importer_install $arg]
      if {$err != ""} { puts "install failed: $err"; exit 1 }
      puts "installed $arg"
      puts "  max -tech [importer_field [importer_by_name $arg] max_tech]"
      puts "  sue -lib [importer_field [importer_by_name $arg] sue_lib]"
      return 1
    }
    --uninstall {
      if {$arg == ""} { puts "usage: importer --uninstall <name>"; exit 2 }
      set err [importer_uninstall $arg]
      if {$err != ""} { puts $err; exit 1 }
      puts "removed $arg"
      return 1
    }
    --repair {
      set n [importer_repair]
      puts "repair touched $n PDK(s)"
      return 1
    }
    --add-url {
      if {$arg == ""} {
        puts "usage: importer --add-url <url>"
        exit 2
      }
      set err [importer_add_url_cli $arg]
      if {$err != ""} { puts "add-url failed: $err"; exit 1 }
      return 1
    }
    default { return 0 }
  }
}
