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
set ::IMPORTER_ROOT [importer_pdk_root]
set ::IMPORTER_DO_TECH 1
set ::IMPORTER_DO_LIB 1
set ::IMPORTER_DO_EXTRA 0
set ::IMPORTER_BUSY 0

proc importer_ui_font {size {weight normal}} {
  foreach fam {"DejaVu Sans" "Liberation Sans" "Nimbus Sans" "Ubuntu" "Sans"} {
    if {[lsearch -exact [font families] $fam] >= 0} {
      if {$weight == "bold"} {
        return [list $fam $size bold]
      }
      return [list $fam $size]
    }
  }
  return TkDefaultFont
}

proc importer_mono_font {size} {
  foreach fam {"DejaVu Sans Mono" "Liberation Mono" "Ubuntu Mono" "Nimbus Mono L"} {
    if {[lsearch -exact [font families] $fam] >= 0} {
      return [list $fam $size]
    }
  }
  return TkFixedFont
}

set ::IMPORTER_UI [importer_ui_font 12]
set ::IMPORTER_UI_B [importer_ui_font 12 bold]
set ::IMPORTER_UI_SM [importer_ui_font 10]
set ::IMPORTER_MONO [importer_mono_font 11]

ttk::style theme use clam
ttk::style configure TFrame -background #f4f6f8
ttk::style configure TLabel -background #f4f6f8 -foreground #1a1d23 -font $::IMPORTER_UI
ttk::style configure Title.TLabel -font $::IMPORTER_UI_B -foreground #1a1d23
ttk::style configure Hint.TLabel -font $::IMPORTER_UI_SM -foreground #5c6570
ttk::style configure TButton -font $::IMPORTER_UI -padding {14 8}
ttk::style configure Accent.TButton -font $::IMPORTER_UI_B -padding {18 8} \
    -background #1f6feb -foreground #ffffff
ttk::style map Accent.TButton \
    -background {disabled #b9c7dc active #1a5fd0 pressed #184eab} \
    -foreground {disabled #f4f6f8}
ttk::style configure TEntry -font $::IMPORTER_UI -padding 6
ttk::style configure Treeview -font $::IMPORTER_UI -rowheight 32 \
    -background #ffffff -fieldbackground #ffffff -foreground #1a1d23
ttk::style configure Treeview.Heading -font $::IMPORTER_UI_B -padding 6
ttk::style map Treeview -background {selected #dbe7ff} -foreground {selected #1a1d23}
ttk::style configure TProgressbar -thickness 16 -background #1f6feb \
    -troughcolor #e2e6ec -bordercolor #e2e6ec

proc importer_selected_item {} {
  set sel [.tbl selection]
  if {$sel == ""} {
    return [lindex $::IMPORTER_ITEMS 0]
  }
  set i [.tbl index $sel]
  return [lindex $::IMPORTER_ITEMS $i]
}

proc importer_refresh {} {
  importer_forget
  importer_adopt
  set ::IMPORTER_ITEMS [importer_catalogue]
  set keep [.tbl selection]
  .tbl delete [.tbl children {}]
  set i 0
  foreach item $::IMPORTER_ITEMS {
    set st [importer_state $item]
    set tag ok
    if {$st == "missing" || $st == "broken"} { set tag bad }
    if {$st == "resume" || $st == "outdated" || $st == "convert"} { set tag mid }
    .tbl insert {} end -id p$i -tags $tag -values [list \
        [importer_field $item name] \
        [importer_field $item process] \
        [importer_short_tag $item] \
        $st]
    incr i
  }
  if {$keep != "" && [.tbl exists $keep]} {
    .tbl selection set $keep
    .tbl see $keep
  } elseif {$i > 0} {
    .tbl selection set p0
  }
  importer_show_desc
}

proc importer_show_desc {} {
  set item [importer_selected_item]
  .desc configure -state normal
  .desc delete 1.0 end
  if {$item == ""} {
    .desc configure -state disabled
    return
  }
  set tech [importer_field $item max_tech]
  set lib [importer_field $item sue_lib]
  .desc insert end "[importer_field $item description]\n\n" title
  .desc insert end "Installs into  " muted
  .desc insert end "[file join $::IMPORTER_ROOT [importer_field $item dir]]\n"
  .desc insert end "Version  " muted
  .desc insert end "[importer_short_tag $item]\n"
  .desc insert end "MAX  " muted
  .desc insert end "max -tech $tech\n"
  .desc insert end "SUE  " muted
  .desc insert end "sue -lib $lib\n"
  .desc insert end "State  " muted
  .desc insert end "[importer_state $item]\n"
  .desc configure -state disabled
}

proc importer_set_progress {pct msg} {
  if {![winfo exists .bar]} { return }
  if {![string is integer -strict $pct]} { set pct 0 }
  if {$pct < 0} { set pct 0 }
  if {$pct > 100} { set pct 100 }
  .bar configure -value $pct
  .pct configure -text "$pct%    $msg"
  update idletasks
}

proc importer_log_window {msg} {
  if {![winfo exists .log]} { return }
  .log configure -state normal
  .log insert end "$msg\n"
  .log see end
  .log configure -state disabled
}

proc importer_fail {msg} {
  importer_set_progress 0 $msg
  importer_log_window $msg
  tk_messageBox -icon error -title "PDK installer" -message $msg
}

proc importer_busy {on} {
  set ::IMPORTER_BUSY $on
  if {$on} {
    foreach w {.act.install .act.remove .act.repair .act.refresh} {
      if {[winfo exists $w]} { $w state disabled }
    }
    . configure -cursor watch
  } else {
    foreach w {.act.install .act.remove .act.repair .act.refresh} {
      if {[winfo exists $w]} { $w state !disabled }
    }
    . configure -cursor {}
  }
}

proc importer_apply_env {} {
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  catch {unset ::env(MMI_CIEL_TAG)}
  catch {unset ::env(MMI_PDK_LOCAL)}
  catch {unset ::env(MMI_PDK_LIBS)}
}

proc importer_do_install {} {
  if {$::IMPORTER_BUSY} { return }
  set item [importer_selected_item]
  if {$item == ""} { return }
  set ::IMPORTER_DO_TECH 1
  set ::IMPORTER_DO_LIB 1
  set ::IMPORTER_DO_EXTRA 0
  importer_apply_env
  set name [importer_field $item name]
  importer_busy 1
  importer_set_progress 1 "Installing $name"
  update
  set err [importer_install $name progress]
  importer_busy 0
  if {$err != ""} {
    importer_fail $err
    return
  }
  importer_set_progress 100 "Installed $name"
  importer_refresh
  set tech [importer_field $item max_tech]
  set lib [importer_field $item sue_lib]
  set go [tk_messageBox -icon info -type yesno -title "PDK installer" \
      -message "Installed $name.\n\nStart MAX with -tech $tech and SUE with -lib $lib now?"]
  if {$go == "yes"} {
    catch {exec max -tech $tech &}
    catch {exec sue -lib $lib &}
  }
}

proc importer_do_uninstall {} {
  if {$::IMPORTER_BUSY} { return }
  set item [importer_selected_item]
  if {$item == ""} { return }
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  set name [importer_field $item name]
  set go [tk_messageBox -icon warning -type yesno -title "PDK installer" \
      -message "Remove $name from $::IMPORTER_ROOT?"]
  if {$go != "yes"} { return }
  set err [importer_uninstall $name]
  if {$err != ""} { importer_fail $err; return }
  importer_set_progress 0 "Removed $name"
  importer_refresh
}

proc importer_do_repair {} {
  if {$::IMPORTER_BUSY} { return }
  importer_apply_env
  importer_busy 1
  importer_set_progress 5 "Repairing installed technologies"
  update
  set n [importer_repair]
  importer_busy 0
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

proc importer_open_dir {} {
  set item [importer_selected_item]
  if {$item == ""} { return }
  set dir [file join $::IMPORTER_ROOT [importer_field $item dir]]
  set opener xdg-open
  if {[auto_execok $opener] == ""} { set opener explorer }
  catch {exec $opener $dir &}
}

wm title . "PDK installer"
wm geometry . 920x640
wm minsize . 760 520
. configure -background #f4f6f8

ttk::frame .head
pack .head -fill x -padx 20 -pady {16 8}
ttk::label .head.title -style Title.TLabel -text "PDK installer"
ttk::label .head.hint -style Hint.TLabel \
    -text "Download a process kit, then build its MAX technology and SUE library."
pack .head.title -anchor w
pack .head.hint -anchor w -pady {2 0}

ttk::frame .path
pack .path -fill x -padx 20 -pady 4
ttk::label .path.l -text "Install into"
ttk::entry .path.e -textvariable ::IMPORTER_ROOT
ttk::button .path.b -text "Browse" -command importer_browse
pack .path.l -side left -padx {0 8}
pack .path.b -side right
pack .path.e -side left -fill x -expand 1

ttk::frame .list
pack .list -fill both -expand 1 -padx 20 -pady {10 4}
ttk::treeview .tbl -columns {name process version state} -show headings \
    -selectmode browse -height 6
.tbl heading name -text "Name" -anchor w
.tbl heading process -text "Process" -anchor w
.tbl heading version -text "Version" -anchor w
.tbl heading state -text "State" -anchor w
.tbl column name -width 140 -stretch 0
.tbl column process -width 280 -stretch 1
.tbl column version -width 120 -stretch 0
.tbl column state -width 110 -stretch 0
.tbl tag configure ok -foreground #1b7f3a
.tbl tag configure bad -foreground #8a9099
.tbl tag configure mid -foreground #9a6700
pack .tbl -in .list -fill both -expand 1

text .desc -height 7 -wrap word -bd 0 -highlightthickness 0 \
    -background #f4f6f8 -foreground #1a1d23 -font $::IMPORTER_UI -padx 2 -pady 6
.desc tag configure title -font $::IMPORTER_UI_B
.desc tag configure muted -foreground #5c6570
pack .desc -fill x -padx 20

ttk::progressbar .bar -orient horizontal -mode determinate -maximum 100
pack .bar -fill x -padx 20 -pady {8 2}
ttk::label .pct -style Hint.TLabel -text "Ready" -anchor w
pack .pct -fill x -padx 20

text .log -height 6 -wrap word -bd 0 -highlightthickness 1 \
    -highlightbackground #e2e6ec -background #ffffff -foreground #1a1d23 \
    -font $::IMPORTER_MONO -padx 8 -pady 6 -state disabled
pack .log -fill both -expand 1 -padx 20 -pady 6

ttk::frame .act
pack .act -fill x -padx 20 -pady {4 16}
ttk::button .act.install -style Accent.TButton -text "Install" -command importer_do_install
ttk::button .act.remove -text "Uninstall" -command importer_do_uninstall
ttk::button .act.repair -text "Repair" -command importer_do_repair
ttk::button .act.refresh -text "Refresh" -command importer_refresh
ttk::button .act.cancel -text "Cancel" -command importer_do_cancel
ttk::button .act.open -text "Open folder" -command importer_open_dir
ttk::button .act.quit -text "Close" -command exit
pack .act.install .act.remove .act.repair .act.refresh .act.cancel -side left -padx {0 8}
pack .act.quit .act.open -side right -padx {8 0}

bind .tbl <<TreeviewSelect>> importer_show_desc
bind .path.e <Return> {
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  importer_refresh
}

importer_refresh
focus .act.install
