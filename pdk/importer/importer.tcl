# importer — download a PDK and build the MAX technology and SUE library.
#   importer                 window
#   importer --list|--status|--install|--uninstall|--repair
#
# Tcl 8.6 / Tk. Not sourced by MAX.

set here [file dirname [info script]]
source [file join $here engine.tcl]

if {[llength $argv] && [string match --* [lindex $argv 0]]} {
  importer_cli $argv
  exit 0
}

package require Tk

set ::IMPORTER_ITEMS [importer_catalogue]
set ::IMPORTER_LIBS [importer_libraries]
set ::IMPORTER_SEL 0
set ::IMPORTER_ROOT [importer_pdk_root]
set ::IMPORTER_VIEW pdks
set ::IMPORTER_DO_TECH 1
set ::IMPORTER_DO_LIB 1
set ::IMPORTER_DO_EXTRA 0
set ::IMPORTER_EXTRA ""
set ::IMPORTER_TAG ""
set ::IMPORTER_LOCAL ""

proc importer_row {item} {
  set st [importer_state $item]
  set tech [importer_field $item max_tech]
  set lib [importer_field $item sue_lib]
  set maxc ""
  set suec ""
  if {$st != "missing" && $st != "resume"} {
    if {[importer_tech_ok $tech]} { set maxc yes } else { set maxc no }
    if {[importer_lib_ok $lib]} { set suec yes } else { set suec no }
  }
  return [format "%-10s %-14s %-24s %-8s %-4s %-4s" \
      $st [importer_field $item name] [importer_field $item process] \
      [importer_short_tag $item] $maxc $suec]
}

proc importer_refresh {} {
  importer_forget
  importer_adopt
  set ::IMPORTER_ITEMS [importer_catalogue]
  set ::IMPORTER_LIBS [importer_libraries]
  .tbl delete 0 end
  if {$::IMPORTER_VIEW == "libs"} {
    foreach lib $::IMPORTER_LIBS {
      set pdk [importer_field $lib pdk]
      set item [importer_by_name $pdk]
      set st missing
      if {$item != ""} { set st [importer_state $item] }
      .tbl insert end [format "%-10s %-14s pdk %-14s %s" \
          $st [importer_field $lib name] $pdk [importer_field $lib description]]
    }
  } else {
    foreach item $::IMPORTER_ITEMS {
      .tbl insert end [importer_row $item]
    }
  }
  importer_show_desc
}

proc importer_selected_item {} {
  set i [.tbl curselection]
  if {$i == ""} { set i 0 }
  if {$::IMPORTER_VIEW == "libs"} {
    set lib [lindex $::IMPORTER_LIBS $i]
    if {$lib == ""} { return "" }
    return [importer_by_name [importer_field $lib pdk]]
  }
  return [lindex $::IMPORTER_ITEMS $i]
}

proc importer_show_desc {} {
  set item [importer_selected_item]
  .desc delete 1.0 end
  if {$item == ""} { return }
  set tech [importer_field $item max_tech]
  set lib [importer_field $item sue_lib]
  .desc insert end "[importer_field $item description]\n\n"
  .desc insert end "Directory: [file join $::IMPORTER_ROOT [importer_field $item dir]]\n"
  .desc insert end "Version: [importer_short_tag $item]\n"
  .desc insert end "MAX:  max -tech $tech\n"
  .desc insert end "SUE:  sue -lib $lib\n"
  .desc insert end "State: [importer_state $item]\n"
}

proc importer_set_progress {pct msg} {
  if {![string is integer -strict $pct]} { set pct 0 }
  if {$pct < 0} { set pct 0 }
  if {$pct > 100} { set pct 100 }
  .bar coords fill 0 0 [expr {4 * $pct}] 18
  .pct configure -text "${pct}%  $msg"
  update idletasks
}

proc importer_log_window {msg} {
  if {![winfo exists .log]} { return }
  .log insert end "$msg\n"
  .log see end
}

proc importer_fail {msg} {
  importer_set_progress 0 $msg
  importer_log_window $msg
  tk_messageBox -icon error -title importer -message $msg
}

proc importer_apply_env {} {
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  if {$::IMPORTER_TAG != ""} {
    set ::env(MMI_CIEL_TAG) $::IMPORTER_TAG
  } else {
    catch {unset ::env(MMI_CIEL_TAG)}
  }
  if {$::IMPORTER_LOCAL != ""} {
    set ::env(MMI_PDK_LOCAL) $::IMPORTER_LOCAL
  } else {
    catch {unset ::env(MMI_PDK_LOCAL)}
  }
  if {$::IMPORTER_DO_EXTRA && $::IMPORTER_EXTRA != ""} {
    set ::env(MMI_PDK_LIBS) $::IMPORTER_EXTRA
  } else {
    catch {unset ::env(MMI_PDK_LIBS)}
  }
}

proc importer_do_install {} {
  set item [importer_selected_item]
  if {$item == ""} { return }
  importer_apply_env
  set name [importer_field $item name]
  importer_set_progress 1 "Installing $name ..."
  update
  set err [importer_install $name progress]
  if {$err != ""} {
    importer_fail $err
    return
  }
  importer_set_progress 100 "Installed $name"
  importer_refresh
  set tech [importer_field $item max_tech]
  set lib [importer_field $item sue_lib]
  set go [tk_messageBox -icon info -type yesno -title importer \
      -message "Installed $name.\n\nStart MAX with -tech $tech and SUE with -lib $lib now?"]
  if {$go == "yes"} {
    catch {exec max -tech $tech &}
    catch {exec sue -lib $lib &}
  }
}

proc importer_do_uninstall {} {
  set item [importer_selected_item]
  if {$item == ""} { return }
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  set name [importer_field $item name]
  set go [tk_messageBox -icon warning -type yesno -title importer \
      -message "Remove $name, its MAX technology, and its SUE library from $::IMPORTER_ROOT?"]
  if {$go != "yes"} { return }
  set err [importer_uninstall $name]
  if {$err != ""} { importer_fail $err; return }
  importer_refresh
}

proc importer_do_repair {} {
  importer_apply_env
  importer_set_progress 5 "Repairing installed technologies and libraries..."
  update
  set n [importer_repair]
  importer_set_progress 100 "Repair finished ($n updated)"
  importer_refresh
}

proc importer_do_cancel {} {
  if {[info exists ::IMPORTER_CANCEL] && $::IMPORTER_CANCEL != ""} {
    close [open $::IMPORTER_CANCEL w]
    importer_set_progress 0 "Cancel requested"
  }
}

proc importer_browse {} {
  set d [tk_chooseDirectory -initialdir $::IMPORTER_ROOT -title "PDK install location"]
  if {$d == ""} { return }
  set ::IMPORTER_ROOT $d
  set ::env(PDK_ROOT) $d
  importer_refresh
}

proc importer_browse_local {} {
  set d [tk_chooseDirectory -title "Compiled open_pdks tree"]
  if {$d == ""} { return }
  set ::IMPORTER_LOCAL $d
}

proc importer_open_dir {} {
  set item [importer_selected_item]
  if {$item == ""} { return }
  set dir [file join $::IMPORTER_ROOT [importer_field $item dir]]
  set opener xdg-open
  if {[auto_execok $opener] == ""} { set opener explorer }
  catch {exec $opener $dir &}
}

proc importer_copy_log {} {
  clipboard clear
  clipboard append [.log get 1.0 end]
}

proc importer_advanced {} {
  if {[winfo exists .adv]} { raise .adv; return }
  toplevel .adv
  wm title .adv "importer — Advanced"
  label .adv.l1 -text "Local open_pdks directory (skips the download):"
  entry .adv.local -width 64 -textvariable ::IMPORTER_LOCAL
  button .adv.bl -text "Browse..." -command importer_browse_local
  label .adv.l2 -text "Ciel tag override (empty uses the catalogue pin):"
  entry .adv.tag -width 64 -textvariable ::IMPORTER_TAG
  label .adv.l3 -text "Extra ciel libraries (MMI_PDK_LIBS), used when that box is checked:"
  entry .adv.extra -width 64 -textvariable ::IMPORTER_EXTRA
  button .adv.ok -text "Close" -command { destroy .adv }
  grid .adv.l1 -row 0 -column 0 -columnspan 2 -sticky w -padx 8 -pady 4
  grid .adv.local -row 1 -column 0 -sticky we -padx 8
  grid .adv.bl -row 1 -column 1 -padx 8
  grid .adv.l2 -row 2 -column 0 -columnspan 2 -sticky w -padx 8 -pady 4
  grid .adv.tag -row 3 -column 0 -columnspan 2 -sticky we -padx 8
  grid .adv.l3 -row 4 -column 0 -columnspan 2 -sticky w -padx 8 -pady 4
  grid .adv.extra -row 5 -column 0 -columnspan 2 -sticky we -padx 8
  grid .adv.ok -row 6 -column 1 -sticky e -padx 8 -pady 8
}

proc importer_show_pdks {} {
  set ::IMPORTER_VIEW pdks
  importer_refresh
}

proc importer_show_libs {} {
  set ::IMPORTER_VIEW libs
  importer_refresh
}

wm title . "importer"
wm geometry . 980x560

frame .top
pack .top -fill x -padx 8 -pady 6
label .top.l -text "Install into:"
entry .root -width 70 -textvariable ::IMPORTER_ROOT
button .top.b -text "Browse..." -command importer_browse
pack .top.l -side left
pack .root -side left -fill x -expand 1 -padx 6
pack .top.b -side left

frame .tabs
pack .tabs -fill x -padx 8
button .tabs.p -text "PDKs" -command importer_show_pdks
button .tabs.l -text "Design libraries" -command importer_show_libs
label .tabs.h -text "Installed   Name            Process                  Version  MAX  SUE" -anchor w
pack .tabs.p .tabs.l -side left -padx 2
pack .tabs.h -side left -padx 12

frame .mid
pack .mid -fill both -expand 1 -padx 8 -pady 4
listbox .tbl -width 78 -height 8 -exportselection 0 -font TkFixedFont
pack .tbl -in .mid -side left -fill both -expand 1
text .desc -width 36 -height 8 -wrap word
pack .desc -in .mid -side left -fill both -padx 8

frame .opts
pack .opts -fill x -padx 8
checkbutton .opts.tech -text "MAX technology" -variable ::IMPORTER_DO_TECH
checkbutton .opts.lib -text "SUE design library" -variable ::IMPORTER_DO_LIB
checkbutton .opts.extra -text "extra ciel libraries" -variable ::IMPORTER_DO_EXTRA
button .opts.adv -text "Advanced..." -command importer_advanced
pack .opts.tech .opts.lib .opts.extra -side left -padx 6
pack .opts.adv -side right

canvas .bar -width 400 -height 18 -bd 1 -relief sunken -highlightthickness 0
pack .bar -fill x -padx 8 -pady 4
.bar create rectangle 0 0 0 18 -fill #2a7ab0 -outline {} -tags fill
label .pct -text "0%" -anchor w
pack .pct -fill x -padx 8

text .log -height 5 -wrap word
pack .log -fill both -expand 1 -padx 8 -pady 4

frame .btns
pack .btns -fill x -padx 8 -pady 8
button .btns.inst -text "Download / Install" -command importer_do_install
button .btns.un -text "Uninstall" -command importer_do_uninstall
button .btns.rep -text "Repair" -command importer_do_repair
button .btns.ref -text "Refresh" -command importer_refresh
button .btns.can -text "Cancel" -command importer_do_cancel
button .btns.copy -text "Copy" -command importer_copy_log
button .btns.open -text "Open dir" -command importer_open_dir
button .btns.quit -text "Close" -command exit
pack .btns.inst .btns.un .btns.rep .btns.ref .btns.can -side left -padx 4
pack .btns.quit .btns.open .btns.copy -side right -padx 4

bind .tbl <<ListboxSelect>> importer_show_desc
bind .root <Return> {
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  importer_refresh
}

importer_refresh
if {[llength $::IMPORTER_ITEMS]} { .tbl selection set 0 }
