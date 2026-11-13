# importer — download a PDK and build the MAX technology and SUE library.
#   importer                 window
#   importer --list|--status|--install|--uninstall|--repair|--add-url <url>
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

proc importer_named_family {candidates} {
  set have [font families]
  foreach fam $candidates {
    if {[lsearch -exact $have $fam] >= 0} { return $fam }
  }
  return ""
}

# Pixel sizes. Point sizes stay tiny when this session has Xft turned off.
proc importer_ui_font {pixels {weight normal}} {
  set fam [importer_named_family {
    "DejaVu Sans" "Liberation Sans" "Ubuntu" "Nimbus Sans" "Helvetica" "helvetica"
  }]
  if {$fam == ""} { set fam Helvetica }
  set w normal
  if {$weight == "bold"} { set w bold }
  return [font create -family $fam -size -$pixels -weight $w]
}

proc importer_mono_font {pixels} {
  set fam [importer_named_family {
    "DejaVu Sans Mono" "Liberation Mono" "Ubuntu Mono" "Nimbus Mono L"
    "Courier" "courier" "fixed"
  }]
  if {$fam == ""} { set fam Courier }
  return [font create -family $fam -size -$pixels]
}

set ::IMPORTER_UI [importer_ui_font 18]
set ::IMPORTER_FAM [font actual $::IMPORTER_UI -family]
catch {font configure TkDefaultFont -family $::IMPORTER_FAM -size -18}
catch {font configure TkTextFont -family $::IMPORTER_FAM -size -18}
catch {font configure TkHeadingFont -family $::IMPORTER_FAM -size -18}
catch {font configure TkCaptionFont -family $::IMPORTER_FAM -size -18}
catch {font configure TkFixedFont -family $::IMPORTER_FAM -size -18}
catch {font configure TkMenuFont -family $::IMPORTER_FAM -size -18}
catch {font configure TkIconFont -family $::IMPORTER_FAM -size -18}
catch {font configure TkSmallCaptionFont -family $::IMPORTER_FAM -size -18}
catch {font configure TkTooltipFont -family $::IMPORTER_FAM -size -18}
option add *Font $::IMPORTER_UI
option add *font $::IMPORTER_UI
option add *Dialog.msg.font $::IMPORTER_UI
option add *Dialog.dtl.font $::IMPORTER_UI

ttk::style theme use clam
ttk::style configure TFrame -background #f4f6f8
ttk::style configure TLabel -background #f4f6f8 -foreground #1a1d23 -font $::IMPORTER_UI
ttk::style configure Title.TLabel -font $::IMPORTER_UI -foreground #1a1d23
ttk::style configure Hint.TLabel -font $::IMPORTER_UI -foreground #5c6570
ttk::style configure TButton -font $::IMPORTER_UI -padding {14 8}
ttk::style configure Accent.TButton -font $::IMPORTER_UI -padding {18 8} \
    -background #1f6feb -foreground #ffffff
ttk::style map Accent.TButton \
    -background {disabled #b9c7dc active #1a5fd0 pressed #184eab} \
    -foreground {disabled #f4f6f8}
ttk::style configure TEntry -font $::IMPORTER_UI -padding 6
ttk::style configure Treeview -font $::IMPORTER_UI -rowheight 40 \
    -background #ffffff -fieldbackground #ffffff -foreground #1a1d23
ttk::style configure Treeview.Heading -font $::IMPORTER_UI -padding 6
ttk::style map Treeview -background {selected #dbe7ff} -foreground {selected #1a1d23}
ttk::style configure TProgressbar -thickness 22 -background #1f6feb \
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
  set picked 0
  if {[info exists ::IMPORTER_SELECT_NAME] && $::IMPORTER_SELECT_NAME != ""} {
    set want $::IMPORTER_SELECT_NAME
    set ::IMPORTER_SELECT_NAME ""
    set j 0
    foreach item $::IMPORTER_ITEMS {
      if {[importer_field $item name] == $want} {
        .tbl selection set p$j
        .tbl see p$j
        set picked 1
        break
      }
      incr j
    }
  }
  if {!$picked} {
    if {$keep != "" && [.tbl exists $keep]} {
      .tbl selection set $keep
      .tbl see $keep
    } elseif {$i > 0} {
      .tbl selection set p0
    }
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
  .desc insert end "[importer_field $item description]\n\n"
  .desc insert end "Installs into  " muted
  .desc insert end "[file join $::IMPORTER_ROOT [importer_field $item dir]]\n"
  .desc insert end "Version  " muted
  .desc insert end "[importer_short_tag $item]\n"
  .desc insert end "MAX technology  " muted
  .desc insert end "$tech\n"
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
    foreach w {.act.install .act.url .act.remove .act.repair .act.refresh} {
      if {[winfo exists $w]} { $w configure -state disabled }
    }
    . configure -cursor watch
  } else {
    foreach w {.act.install .act.url .act.remove .act.repair .act.refresh} {
      if {[winfo exists $w]} { $w configure -state normal }
    }
    . configure -cursor {}
  }
}

proc importer_apply_env {} {
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  catch {unset ::env(MMI_CIEL_TAG)}
  catch {unset ::env(MMI_PDK_LOCAL)}
  catch {unset ::env(MMI_PDK_LIBS)}
  catch {unset ::env(MMI_PDK_ASSETS)}
  catch {unset ::env(MMI_PDK_BASE)}
  catch {unset ::env(MMI_PDK_ARCHIVE_URL)}
  catch {unset ::env(MMI_PDK_VARIANT)}
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
  set go [tk_messageBox -icon info -type yesno -title "PDK installer" \
      -message "Installed $name.\n\nStart MAX with technology $tech now?"]
  if {$go == "yes"} {
    catch {exec max -tech $tech &}
  }
}

proc importer_do_uninstall {} {
  if {$::IMPORTER_BUSY} { return }
  set item [importer_selected_item]
  if {$item == ""} { return }
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  set name [importer_field $item name]
  set go [tk_messageBox -icon warning -type yesno -title "PDK installer" \
      -message "Remove PDK $name from $::IMPORTER_ROOT?"]
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

proc importer_pick_assets {ids pre} {
  set w .assets
  catch {destroy $w}
  toplevel $w
  wm title $w "PDK libraries"
  wm transient $w .
  wm minsize $w 420 360
  set ::IMPORTER_ASSET_PICK ""
  ttk::label $w.hint -wraplength 460 -justify left \
      -text "Choose which libraries to download. common, primitives, IO, and one standard-cell library are already selected. Extra standard-cell and SRAM archives are often several gigabytes."
  pack $w.hint -side top -fill x -padx 12 -pady 8
  frame $w.box
  listbox $w.box.lb -selectmode extended -height 12 -exportselection 0 \
      -font $::IMPORTER_UI -activestyle dotbox
  scrollbar $w.box.sb -command [list $w.box.lb yview]
  $w.box.lb configure -yscrollcommand [list $w.box.sb set]
  pack $w.box.sb -side right -fill y
  pack $w.box.lb -side left -fill both -expand 1
  pack $w.box -side top -fill both -expand 1 -padx 12
  foreach n $ids { $w.box.lb insert end $n }
  set i 0
  foreach n $ids {
    if {[lsearch -exact $pre $n] >= 0} { $w.box.lb selection set $i }
    incr i
  }
  frame $w.act
  button $w.act.all -text "Select all" -font $::IMPORTER_UI \
      -command [list $w.box.lb selection set 0 end]
  button $w.act.ok -text "Add these" -font $::IMPORTER_UI \
      -bg #1f6feb -fg #ffffff -activebackground #1a5fd0 -activeforeground #ffffff \
      -command [list importer_pick_assets_ok $w]
  button $w.act.cancel -text "Cancel" -font $::IMPORTER_UI \
      -command [list importer_pick_assets_cancel $w]
  pack $w.act.cancel -side right -padx 6 -pady 8
  pack $w.act.ok -side right -padx 6 -pady 8
  pack $w.act.all -side left -padx 6 -pady 8
  pack $w.act -side bottom -fill x
  tkwait window $w
  return $::IMPORTER_ASSET_PICK
}

proc importer_pick_assets_ok {w} {
  set got {}
  foreach i [$w.box.lb curselection] {
    lappend got [$w.box.lb get $i]
  }
  if {![llength $got]} {
    tk_messageBox -icon warning -title "PDK libraries" -parent $w \
        -message "Select at least one library."
    return
  }
  set ::IMPORTER_ASSET_PICK $got
  destroy $w
}

proc importer_pick_assets_cancel {w} {
  set ::IMPORTER_ASSET_PICK ""
  destroy $w
}

proc importer_save_added {item} {
  set name [importer_field $item name]
  set had [expr {[importer_by_name $name] != ""}]
  set msg [importer_remember_pdk $item]
  if {![string match added* $msg] && ![string match updated* $msg]} {
    return $msg
  }
  set ::IMPORTER_SELECT_NAME $name
  importer_refresh
  set what "Added $name to the list."
  if {$had} {
    set what "$name was already listed. Its download URL is now this one."
  }
  set go [tk_messageBox -icon info -type yesno -title "PDK installer" \
      -message "$what\n\nInstall it now?"]
  if {$go == "yes"} { importer_do_install }
  return ""
}

proc importer_add_url_go {w} {
  set url [string trim $::IMPORTER_ADD_URL]
  if {$w != "" && [winfo exists $w]} { destroy $w }
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  importer_busy 1
  importer_set_progress 2 "Reading $url"
  update
  set got [importer_inspect_url $url]
  importer_busy 0
  importer_set_progress 0 "Download progress: ready"
  set kind [lindex $got 0]
  if {$kind == "error"} {
    importer_fail [lindex $got 1]
    return
  }
  if {$kind == "catalogue"} {
    set names {}
    foreach item [lrange $got 1 end] {
      set msg [importer_remember_pdk $item]
      if {![string match added* $msg] && ![string match updated* $msg]} {
        importer_fail $msg
        importer_refresh
        return
      }
      lappend names [importer_field $item name]
    }
    if {[llength $names]} { set ::IMPORTER_SELECT_NAME [lindex $names 0] }
    importer_refresh
    tk_messageBox -icon info -title "PDK installer" \
        -message "Added [join $names {, }].\n\nSelect one and press Install."
    return
  }
  if {$kind == "archive"} {
    set err [importer_save_added [importer_item_from_archive [lindex $got 1]]]
    if {$err != ""} { importer_fail $err }
    return
  }
  if {$kind == "release"} {
    set ids [lindex $got 4]
    set pre [importer_default_asset_ids $ids]
    set use $pre
    if {[llength $ids] > 1} {
      set use [importer_pick_assets $ids $pre]
      if {![llength $use]} { return }
    }
    set item [importer_item_from_release $url \
        [lindex $got 1] [lindex $got 2] [lindex $got 3] $use]
    set err [importer_save_added $item]
    if {$err != ""} { importer_fail $err }
    return
  }
  importer_fail "Could not use that URL."
}

proc importer_add_url_dialog {} {
  if {$::IMPORTER_BUSY} { return }
  set w .addurl
  catch {destroy $w}
  toplevel $w
  wm title $w "Add PDK URL"
  wm transient $w .
  wm resizable $w 1 0
  set ::IMPORTER_ADD_URL ""
  ttk::label $w.hint -wraplength 560 -justify left -text "Paste a URL for a PDK that is not in the list.

A GitHub release (ciel or another open_pdks build):
  https://github.com/fossi-foundation/ciel-releases/releases/tag/<tag>

A catalogue JSON file with a \"pdks\" list.

Or one compiled open_pdks archive:
  https://example.com/my_pdk.tar.zst"
  ttk::entry $w.url -textvariable ::IMPORTER_ADD_URL -width 72
  frame $w.act -bg #f4f6f8
  button $w.act.ok -text "Add" -font $::IMPORTER_UI \
      -bg #1f6feb -fg #ffffff -activebackground #1a5fd0 -activeforeground #ffffff \
      -command [list importer_add_url_go $w]
  button $w.act.cancel -text "Cancel" -font $::IMPORTER_UI \
      -command [list destroy $w]
  pack $w.hint -side top -fill x -padx 12 -pady 10
  pack $w.url -side top -fill x -padx 12 -pady 4
  pack $w.act.cancel -side right -padx 6 -pady 10
  pack $w.act.ok -side right -padx 6 -pady 10
  pack $w.act -side top -fill x
  bind $w.url <Return> [list importer_add_url_go $w]
  focus $w.url
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
wm geometry . 980x720
wm minsize . 860 640
. configure -background #f4f6f8

# Classic Tk buttons, packed first at the top. ttk styling was hiding
# the label, and a bottom row was pushed off the window.
frame .act -bg #e7ebf0 -bd 0
button .act.install -text "Install" -command importer_do_install \
    -font $::IMPORTER_UI -bg #1f6feb -fg #ffffff \
    -activebackground #1a5fd0 -activeforeground #ffffff \
    -padx 16 -pady 6 -relief raised -bd 2 -highlightthickness 0
button .act.remove -text "Delete PDK" -command importer_do_uninstall \
    -font $::IMPORTER_UI -bg #ffffff -fg #1a1d23 \
    -activebackground #f3d6d6 -activeforeground #1a1d23 \
    -padx 16 -pady 6 -relief raised -bd 2 -highlightthickness 0
button .act.repair -text "Repair" -command importer_do_repair \
    -font $::IMPORTER_UI -bg #ffffff -fg #1a1d23 \
    -padx 16 -pady 6 -relief raised -bd 2 -highlightthickness 0
button .act.url -text "Add URL" -command importer_add_url_dialog \
    -font $::IMPORTER_UI -bg #ffffff -fg #1a1d23 \
    -padx 16 -pady 6 -relief raised -bd 2 -highlightthickness 0
button .act.refresh -text "Refresh" -command importer_refresh \
    -font $::IMPORTER_UI -bg #ffffff -fg #1a1d23 \
    -padx 16 -pady 6 -relief raised -bd 2 -highlightthickness 0
button .act.cancel -text "Cancel" -command importer_do_cancel \
    -font $::IMPORTER_UI -bg #ffffff -fg #1a1d23 \
    -padx 16 -pady 6 -relief raised -bd 2 -highlightthickness 0
button .act.open -text "Open folder" -command importer_open_dir \
    -font $::IMPORTER_UI -bg #ffffff -fg #1a1d23 \
    -padx 16 -pady 6 -relief raised -bd 2 -highlightthickness 0
button .act.quit -text "Close" -command exit \
    -font $::IMPORTER_UI -bg #ffffff -fg #1a1d23 \
    -padx 16 -pady 6 -relief raised -bd 2 -highlightthickness 0
pack .act.install -side left -padx 6 -pady 8
pack .act.url -side left -padx 6 -pady 8
pack .act.remove -side left -padx 6 -pady 8
pack .act.repair -side left -padx 6 -pady 8
pack .act.refresh -side left -padx 6 -pady 8
pack .act.cancel -side left -padx 6 -pady 8
pack .act.quit -side right -padx 6 -pady 8
pack .act.open -side right -padx 6 -pady 8
pack .act -side top -fill x

ttk::label .pct -style Hint.TLabel -text "Download progress: ready" -anchor w
ttk::progressbar .bar -orient horizontal -mode determinate -maximum 100
pack .pct -side top -fill x -padx 16 -pady 4
pack .bar -side top -fill x -padx 16 -pady 4

ttk::frame .head
ttk::label .head.title -style Title.TLabel -text "PDK installer"
ttk::label .head.hint -style Hint.TLabel \
    -text "Download a process kit and build its MAX technology."
pack .head.title -anchor w
pack .head.hint -anchor w -pady 2
pack .head -side top -fill x -padx 16 -pady 8

ttk::frame .path
ttk::label .path.l -text "Install into"
ttk::entry .path.e -textvariable ::IMPORTER_ROOT
ttk::button .path.b -text "Browse" -command importer_browse
pack .path.l -side left -padx 8
pack .path.b -side right
pack .path.e -side left -fill x -expand 1
pack .path -side top -fill x -padx 16 -pady 4

text .desc -height 3 -wrap word -bd 0 -highlightthickness 0 \
    -background #f4f6f8 -foreground #1a1d23 -font $::IMPORTER_UI -padx 2 -pady 4
.desc tag configure muted -foreground #5c6570 -font $::IMPORTER_UI
pack .desc -side top -fill x -padx 16

ttk::frame .list
ttk::treeview .tbl -columns {name process version state} -show headings \
    -selectmode browse -height 6
.tbl heading name -text "Name" -anchor w
.tbl heading process -text "Process" -anchor w
.tbl heading version -text "Version" -anchor w
.tbl heading state -text "State" -anchor w
.tbl column name -width 160 -stretch 0
.tbl column process -width 320 -stretch 1
.tbl column version -width 140 -stretch 0
.tbl column state -width 120 -stretch 0
.tbl tag configure ok -foreground #1b7f3a
.tbl tag configure bad -foreground #8a9099
.tbl tag configure mid -foreground #9a6700
pack .tbl -in .list -fill both -expand 1
pack .list -side top -fill both -expand 1 -padx 16 -pady 8

text .log -height 5 -wrap word -bd 0 -highlightthickness 1 \
    -highlightbackground #e2e6ec -background #ffffff -foreground #1a1d23 \
    -font $::IMPORTER_UI -padx 8 -pady 6 -state disabled
pack .log -side top -fill both -expand 1 -padx 16 -pady 8

bind .tbl <<TreeviewSelect>> importer_show_desc
bind .path.e <Return> {
  set ::env(PDK_ROOT) $::IMPORTER_ROOT
  importer_refresh
}

importer_refresh
focus .act.install
