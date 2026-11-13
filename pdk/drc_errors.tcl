# Tool / Misc menu: list every DRC error and copy the text.
# Tcl 8.0 / Tk 8.0. Sourced from maxrc.

proc mmi_drc_text {} {
  set save ""
  catch {set save [layt_box exact]}
  catch {:drc catchup}
  set errs ""
  if {[catch {set errs [db_search_l paint error]} err]} {
    if {$save != ""} { catch {eval layt_box exact $save} }
    return "Could not list DRC errors:\n$err"
  }
  set n [llength $errs]
  if {$n == 0} {
    if {$save != ""} { catch {eval layt_box exact $save} }
    set cell ""
    catch {set cell [lay_editcell]}
    return "No DRC errors in $cell."
  }
  set cell ""
  catch {set cell [lay_editcell]}
  set out "DRC errors in $cell: $n\n\n"
  set i 0
  foreach e $errs {
    incr i
    set x1 ""
    set y1 ""
    set x2 ""
    set y2 ""
    if {[catch {
      struct max_paint p $e
      set x1 ${p.x1}
      set y1 ${p.y1}
      set x2 ${p.x2}
      set y2 ${p.y2}
    }]} {
      set x1 [lindex $e 0]
      set y1 [lindex $e 1]
      set x2 [lindex $e 2]
      set y2 [lindex $e 3]
    }
    set why ""
    catch {
      layt_box exact $x1 $y1 $x2 $y2
      msg_catch {:drc why} r why w
    }
    set why [string trim $why \n]
    if {$why == ""} { set why "(no explanation)" }
    append out "$i. $x1 $y1  $x2 $y2\n$why\n\n"
  }
  if {$save != ""} { catch {eval layt_box exact $save} }
  return $out
}

proc mmi_drc_copy {} {
  if {![winfo exists .mmi_drc.t]} { return }
  set t [.mmi_drc.t get 1.0 end]
  clipboard clear
  clipboard append $t
  if {[winfo exists .mmi_drc.top.note]} {
    .mmi_drc.top.note configure -text "Copied"
  }
}

proc mmi_drc_fill {} {
  if {![winfo exists .mmi_drc.t]} { return }
  if {[winfo exists .mmi_drc.top.note]} {
    .mmi_drc.top.note configure -text "Reading errors..."
  }
  update
  set text [mmi_drc_text]
  .mmi_drc.t configure -state normal
  .mmi_drc.t delete 1.0 end
  .mmi_drc.t insert end $text
  .mmi_drc.t configure -state disabled
  if {[winfo exists .mmi_drc.top.note]} {
    .mmi_drc.top.note configure -text ""
  }
}

proc mmi_drc_window {} {
  if {[winfo exists .mmi_drc]} {
    raise .mmi_drc
    mmi_drc_fill
    return
  }
  toplevel .mmi_drc
  wm title .mmi_drc "DRC errors"
  wm geometry .mmi_drc 760x520
  frame .mmi_drc.top
  pack .mmi_drc.top -fill x -padx 8 -pady 8
  label .mmi_drc.top.l -text "DRC errors" -anchor w \
      -font {-adobe-helvetica-bold-r-normal--14-140-75-75-p-82-iso8859-1}
  button .mmi_drc.top.copy -text "Copy all" -command mmi_drc_copy \
      -font {-adobe-helvetica-medium-r-normal--14-140-75-75-p-77-iso8859-1}
  button .mmi_drc.top.ref -text "Refresh" -command mmi_drc_fill \
      -font {-adobe-helvetica-medium-r-normal--14-140-75-75-p-77-iso8859-1}
  label .mmi_drc.top.note -text "" -anchor e \
      -font {-adobe-helvetica-medium-r-normal--12-120-75-75-p-67-iso8859-1}
  pack .mmi_drc.top.l -side left
  pack .mmi_drc.top.copy -side right -padx 4
  pack .mmi_drc.top.ref -side right -padx 4
  pack .mmi_drc.top.note -side right -padx 8
  frame .mmi_drc.mid
  pack .mmi_drc.mid -fill both -expand 1 -padx 8 -pady 8
  text .mmi_drc.t -wrap word -yscrollcommand {.mmi_drc.sb set} \
      -font fixed -state disabled
  scrollbar .mmi_drc.sb -command {.mmi_drc.t yview}
  pack .mmi_drc.sb -in .mmi_drc.mid -side right -fill y
  pack .mmi_drc.t -in .mmi_drc.mid -side left -fill both -expand 1
  if {[catch {mmi_drc_fill} err]} {
    .mmi_drc.t configure -state normal
    .mmi_drc.t insert end "Could not list DRC errors:\n$err"
    .mmi_drc.t configure -state disabled
  }
}

proc _mmi_drc_install_menu {} {
  if {[info commands menu_tool_cmd] != ""} {
    catch {
      menu_tool_cmd "DRC Errors..." mmi_drc_window \
          "List every DRC error and copy them"
    }
  }
  if {![catch {_menu_get_widget Misc} menu]} {
    catch {
      menu_add_cmd $menu "All DRC Errors..." mmi_drc_window \
          -desc "List every DRC error and copy them"
    }
  }
}

_mmi_drc_install_menu
