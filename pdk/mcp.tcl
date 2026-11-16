# mcp menu for MAX. Tcl 8.0: no dict, no string map, no eq.
# Two windows: API keys, and the question.
# Cursor is Grok 4.7, extra high, fast off.
# Drawing steps are nix packages. MAX paints each one before the next.

set MCP(root) [file dirname [info script]]
set MCP(running) 0
set MCP(step_busy) 0
set MCP(chan) ""
set MCP(poll) ""
set MCP(step_after) ""
set MCP(menus_done) 0
set MCP(log) ""
set MCP(errors) {}
set MCP(log_err) 0
set MCP(copy_text) ""
set MCP(show_keys) 0
set MCP(menu_tries) 0

proc mcp_confdir {} {
  global env
  set home /mmi-home
  if {[info exists env(HOME)] && $env(HOME) != ""} {
    set home $env(HOME)
  }
  return [file join $home .max-mcp]
}

proc mcp_keys_path {} {
  return [file join [mcp_confdir] keys]
}

proc mcp_jobdir {} {
  return [file join [mcp_confdir] job]
}

proc mcp_agent_table {} {
  return [list \
    [list cursor Cursor grok-4.7 xhigh 0] \
    [list openai OpenAI gpt-4.1 "" 0] \
    [list anthropic Anthropic claude-sonnet-4-5 "" 0] \
    [list google Google gemini-2.5-pro "" 0] \
    [list xai xAI grok-4.7 xhigh 0] \
    [list groq Groq llama-3.3-70b-versatile "" 0] \
    [list mistral Mistral mistral-large-latest "" 0] \
    [list openrouter OpenRouter openai/gpt-4.1 "" 0] \
    [list deepseek DeepSeek deepseek-chat "" 0] \
    [list together Together meta-llama/Llama-3.3-70B-Instruct-Turbo "" 0] \
    [list fireworks Fireworks accounts/fireworks/models/llama-v3p3-70b-instruct "" 0] \
    [list cohere Cohere command-r-plus "" 0] \
    [list perplexity Perplexity sonar "" 0]]
}

proc mcp_split_line {line} {
  set line [string trimright $line "\n\r"]
  set parts {}
  while {1} {
    set i [string first "\t" $line]
    if {$i < 0} {
      lappend parts $line
      break
    }
    lappend parts [string range $line 0 [expr {$i - 1}]]
    set line [string range $line [expr {$i + 1}] end]
  }
  return $parts
}

proc mcp_int {s} {
  if {![regexp {^-?[0-9]+$} $s]} { return "" }
  set sign ""
  if {[string index $s 0] == "-"} {
    set sign "-"
    set s [string range $s 1 end]
  }
  if {[string length $s] > 7 || $s == ""} { return "" }
  while {[string length $s] > 1 && [string index $s 0] == "0"} {
    set s [string range $s 1 end]
  }
  return "$sign$s"
}

proc mcp_name_ok {name} {
  if {$name == "" || [string length $name] > 64} { return 0 }
  return [regexp {^[A-Za-z0-9_+.-]+$} $name]
}

proc mcp_saved_lines {} {
  set path [mcp_keys_path]
  if {![file readable $path]} { return {} }
  set fh [open $path r]
  set lines {}
  while {[gets $fh line] >= 0} {
    lappend lines $line
  }
  close $fh
  return $lines
}

proc mcp_find_saved {id lines} {
  foreach line $lines {
    if {$line == "" || [string index $line 0] == "#"} continue
    set parts [mcp_split_line $line]
    if {[lindex $parts 0] == $id} { return $parts }
  }
  return {}
}

proc mcp_rows {} {
  set lines [mcp_saved_lines]
  set rows {}
  foreach spec [mcp_agent_table] {
    set id [lindex $spec 0]
    set saved [mcp_find_saved $id $lines]
    set key ""
    set model [lindex $spec 2]
    set effort [lindex $spec 3]
    set fast [lindex $spec 4]
    if {$saved != ""} {
      set key [lindex $saved 1]
      if {$id != "cursor"} {
        if {[lindex $saved 2] != ""} { set model [lindex $saved 2] }
        set effort [lindex $saved 3]
        if {[lindex $saved 4] != ""} { set fast [lindex $saved 4] }
      }
    }
    if {$id == "cursor"} {
      set model grok-4.7
      set effort xhigh
      set fast 0
    }
    lappend rows [list $id [lindex $spec 1] $key $model $effort $fast]
  }
  return $rows
}

proc mcp_write_keys {rows} {
  set dir [mcp_confdir]
  file mkdir $dir
  set path [mcp_keys_path]
  set fh [open $path w]
  puts $fh "# mcp keys: id, key, model, effort, fast. Cursor stays grok-4.7, xhigh, fast 0."
  foreach row $rows {
    set id [lindex $row 0]
    set key [lindex $row 2]
    set model [lindex $row 3]
    set effort [lindex $row 4]
    set fast [lindex $row 5]
    if {$id == "cursor"} {
      set model grok-4.7
      set effort xhigh
      set fast 0
    }
    puts $fh "$id\t$key\t$model\t$effort\t$fast"
  }
  close $fh
  catch {exec chmod 700 $dir}
  catch {exec chmod 600 $path}
}

proc mcp_keep_error {text forced} {
  if {$forced} { return 1 }
  if {[string match "error:*" $text]} { return 1 }
  if {[string match "Error:*" $text]} { return 1 }
  return 0
}

proc mcp_error_blob {} {
  global MCP
  if {![info exists MCP(errors)]} { return "" }
  set text ""
  foreach line $MCP(errors) {
    if {$text != ""} { append text "\n" }
    append text $line
  }
  return $text
}

proc mcp_log {text} {
  global MCP
  if {![info exists MCP(errors)]} { set MCP(errors) {} }
  set forced 0
  if {[info exists MCP(log_err)] && $MCP(log_err)} { set forced 1 }
  if {[mcp_keep_error $text $forced]} {
    lappend MCP(errors) $text
  }
  if {[info commands winfo] == "" || ![info exists MCP(log)] || $MCP(log) == ""} {
    puts $text
    return
  }
  if {![winfo exists $MCP(log)]} {
    puts $text
    return
  }
  $MCP(log) configure -state normal
  $MCP(log) insert end "$text\n"
  $MCP(log) see end
  $MCP(log) configure -state disabled
  update idletasks
}

proc mcp_log_err {text} {
  global MCP
  set MCP(log_err) 1
  mcp_log $text
  set MCP(log_err) 0
}

proc mcp_sel_handle {offset maxBytes} {
  global MCP
  if {![info exists MCP(copy_text)]} { return "" }
  return [string range $MCP(copy_text) $offset [expr {$offset + $maxBytes - 1}]]
}

proc mcp_copy_errors {} {
  global MCP
  if {[info commands winfo] == "" || ![winfo exists .mcpask.logtop.copy]} { return }
  set text [mcp_error_blob]
  if {$text == ""} {
    .mcpask.logtop.note configure -text "No errors to copy"
    return
  }
  set MCP(copy_text) $text
  # Tk 8.0 drops a clipboard set owned by a disabled text widget.
  selection handle -selection CLIPBOARD .mcpask.logtop.copy mcp_sel_handle
  selection own -selection CLIPBOARD -command {} .mcpask.logtop.copy
  selection handle -selection PRIMARY .mcpask.logtop.copy mcp_sel_handle
  catch {selection own -selection PRIMARY -command {} .mcpask.logtop.copy}
  catch {
    clipboard clear -displayof .mcpask.logtop.copy
    clipboard append -displayof .mcpask.logtop.copy $text
  }
  .mcpask.logtop.note configure -text "Copied"
}

proc mcp_key_status {text} {
  if {[info commands winfo] != "" && [winfo exists .mcpkeys.status]} {
    .mcpkeys.status configure -text $text
  }
}

proc mcp_keys_toggle {} {
  global MCP
  set show "*"
  if {$MCP(show_keys)} { set show "" }
  foreach w $MCP(key_entries) {
    if {[winfo exists $w]} {
      $w configure -show $show
    }
  }
}

proc mcp_collect {} {
  set rows {}
  set r 0
  foreach spec [mcp_agent_table] {
    set id [lindex $spec 0]
    set key [string trim [.mcpkeys.r$r.key get]]
    if {[string first "\t" $key] >= 0 || [string first "\n" $key] >= 0} {
      error "The $id key cannot contain a tab or a newline."
    }
    if {$id == "cursor"} {
      set model grok-4.7
      set effort xhigh
      set fast 0
    } else {
      set model [string trim [.mcpkeys.r$r.model get]]
      set effort [string trim [.mcpkeys.r$r.effort get]]
      set fast [string trim [.mcpkeys.r$r.fast get]]
      if {$fast != "0" && $fast != "1"} { set fast 0 }
    }
    lappend rows [list $id [lindex $spec 1] $key $model $effort $fast]
    incr r
  }
  return $rows
}

proc mcp_save_keys {} {
  if {[catch {set rows [mcp_collect]} err]} {
    mcp_key_status $err
    mcp_log_err $err
    return 0
  }
  if {[catch {mcp_write_keys $rows} err]} {
    mcp_key_status $err
    return 0
  }
  mcp_key_status "Saved in your home directory, not in the project."
  mcp_show_agent
  return 1
}

proc mcp_selected {} {
  global MCP
  if {[info commands winfo] == "" || ![winfo exists .mcpask.agents]} {
    return cursor
  }
  set sel [.mcpask.agents curselection]
  if {$sel == ""} { return cursor }
  return [lindex $MCP(agent_ids) [lindex $sel 0]]
}

proc mcp_show_agent {} {
  if {[info commands winfo] == "" || ![winfo exists .mcpask.settings]} { return }
  set id [mcp_selected]
  set note ""
  foreach row [mcp_rows] {
    if {[lindex $row 0] != $id} continue
    if {$id == "cursor"} {
      set note "Cursor uses Grok 4.7, extra high, fast off."
      if {[lindex $row 2] == ""} {
        append note " Paste the Cursor API key in the API Keys window."
      } else {
        append note " A key is saved."
      }
    } else {
      set note "$id  model [lindex $row 3]"
      if {[lindex $row 4] != ""} { append note "  effort [lindex $row 4]" }
      if {[lindex $row 5] == "1"} {
        append note "  fast on"
      } else {
        append note "  fast off"
      }
      if {[lindex $row 2] == ""} {
        append note ". No key saved. Open API Keys to paste one."
      }
    }
  }
  .mcpask.settings configure -text $note
}

proc mcp_build_keys {} {
  global MCP
  toplevel .mcpkeys
  wm title .mcpkeys "mcp API keys"
  label .mcpkeys.intro -wraplength 720 -justify left -anchor w -text \
      "Paste each API key here. Keys stay in your home directory, not in the project. Cursor is Grok 4.7, extra high, and not fast. The other agents use the model you type. Fast is 0 or 1 for agents that have a fast mode."
  pack .mcpkeys.intro -fill x -padx 8 -pady 4

  set show "*"
  if {$MCP(show_keys)} { set show "" }
  set MCP(key_entries) {}
  set r 0
  foreach row [mcp_rows] {
    set id [lindex $row 0]
    frame .mcpkeys.r$r
    pack .mcpkeys.r$r -fill x -padx 6 -pady 1
    label .mcpkeys.r$r.name -text [lindex $row 1] -width 12 -anchor w
    entry .mcpkeys.r$r.key -width 34 -show $show
    .mcpkeys.r$r.key insert 0 [lindex $row 2]
    lappend MCP(key_entries) .mcpkeys.r$r.key
    if {$id == "cursor"} {
      label .mcpkeys.r$r.model -text "grok-4.7   extra high   fast off" -anchor w
      pack .mcpkeys.r$r.name .mcpkeys.r$r.key .mcpkeys.r$r.model -side left -padx 2
    } else {
      entry .mcpkeys.r$r.model -width 42
      .mcpkeys.r$r.model insert 0 [lindex $row 3]
      entry .mcpkeys.r$r.effort -width 8
      .mcpkeys.r$r.effort insert 0 [lindex $row 4]
      entry .mcpkeys.r$r.fast -width 3
      .mcpkeys.r$r.fast insert 0 [lindex $row 5]
      pack .mcpkeys.r$r.name .mcpkeys.r$r.key .mcpkeys.r$r.model \
          .mcpkeys.r$r.effort .mcpkeys.r$r.fast -side left -padx 2
    }
    incr r
  }
  frame .mcpkeys.btns
  pack .mcpkeys.btns -fill x -padx 6 -pady 2
  button .mcpkeys.btns.save -text "Save keys" -command mcp_save_keys
  checkbutton .mcpkeys.btns.show -text "Show keys" -variable MCP(show_keys) \
      -command mcp_keys_toggle
  label .mcpkeys.status -anchor w -text ""
  pack .mcpkeys.btns.save .mcpkeys.btns.show -side left -padx 4
  pack .mcpkeys.status -fill x -padx 8 -pady 4
}

proc mcp_build_ask {} {
  global MCP
  toplevel .mcpask
  wm title .mcpask "mcp Ask"
  set MCP(errors) {}
  set MCP(copy_text) ""
  label .mcpask.intro -wraplength 720 -justify left -anchor w -text \
      "Pick an agent and ask a question. API keys are entered in the API Keys window."
  pack .mcpask.intro -fill x -padx 8 -pady 4

  frame .mcpask.pick
  pack .mcpask.pick -fill x -padx 8
  listbox .mcpask.agents -height 6 -width 18 -exportselection 0 \
      -yscrollcommand {.mcpask.pick.scroll set}
  scrollbar .mcpask.pick.scroll -command {.mcpask.agents yview}
  pack .mcpask.pick.scroll -side right -fill y
  pack .mcpask.agents -side left -fill y
  set MCP(agent_ids) {}
  set cursor_i 0
  set i 0
  foreach row [mcp_rows] {
    lappend MCP(agent_ids) [lindex $row 0]
    .mcpask.agents insert end [lindex $row 1]
    if {[lindex $row 0] == "cursor"} { set cursor_i $i }
    incr i
  }
  .mcpask.agents selection set $cursor_i
  .mcpask.agents see $cursor_i
  bind .mcpask.agents <<ListboxSelect>> mcp_show_agent

  label .mcpask.settings -anchor w -wraplength 720 -justify left
  pack .mcpask.settings -fill x -padx 8 -pady 2
  text .mcpask.q -height 5 -width 88 -wrap word
  pack .mcpask.q -fill x -padx 8
  frame .mcpask.btns
  pack .mcpask.btns -fill x -padx 6 -pady 4
  button .mcpask.btns.ask -text "Ask" -command mcp_ask_start
  button .mcpask.btns.draw -text "Draw a simple inverter" -command mcp_draw_inverter
  button .mcpask.btns.stop -text "Stop" -command mcp_ask_stop
  pack .mcpask.btns.ask .mcpask.btns.draw .mcpask.btns.stop -side left -padx 4
  label .mcpask.hint -anchor w -wraplength 720 -justify left -text \
      "Draw a simple inverter asks for a CMOS inverter, one rectangle at a time. Each step is a nix package (mcp-paint, mcp-cell, mcp-label, mcp-zoom, mcp-layers, or mcp-nix). The layout window updates before the next step."
  pack .mcpask.hint -fill x -padx 8
  frame .mcpask.logtop
  pack .mcpask.logtop -fill x -padx 8 -pady 2
  label .mcpask.logtop.l -text "Result" -anchor w
  button .mcpask.logtop.copy -text "Copy errors" -command mcp_copy_errors
  label .mcpask.logtop.note -text "" -anchor e
  pack .mcpask.logtop.l -side left
  pack .mcpask.logtop.copy -side right -padx 4
  pack .mcpask.logtop.note -side right -padx 8
  frame .mcpask.logf
  pack .mcpask.logf -fill both -expand 1 -padx 8 -pady 4
  text .mcpask.log -height 14 -width 88 -wrap word -state disabled \
      -yscrollcommand {.mcpask.logf.scroll set}
  scrollbar .mcpask.logf.scroll -command {.mcpask.log yview}
  pack .mcpask.logf.scroll -side right -fill y
  pack .mcpask.log -side left -fill both -expand 1
  set MCP(log) .mcpask.log
  bind .mcpask <Destroy> {
    if {"%W" == ".mcpask"} { mcp_ask_stop }
  }
  mcp_show_agent
}

proc mcp_open {which} {
  if {[info commands winfo] == ""} { return }
  if {$which == "keys"} {
    if {![winfo exists .mcpkeys]} {
      mcp_build_keys
    }
    raise .mcpkeys
    if {[winfo exists .mcpkeys.r0.key]} {
      focus .mcpkeys.r0.key
    }
    return
  }
  if {![winfo exists .mcpask]} {
    mcp_build_ask
  }
  raise .mcpask
  focus .mcpask.q
}

proc mcp_layer_names {} {
  set skip {annotation background bbox box drc feedback flyline grid label selection subcell}
  set out {}
  if {[info commands dbt_layers] != ""} {
    foreach L [dbt_layers] {
      set bad 0
      foreach s $skip {
        if {$L == $s} { set bad 1 }
      }
      if {!$bad && [mcp_name_ok $L]} { lappend out $L }
    }
  }
  return $out
}

proc mcp_tech_name {} {
  global MN_TECH
  if {[info exists MN_TECH] && $MN_TECH != ""} { return $MN_TECH }
  return ""
}

proc mcp_reset_spool {} {
  set dir [mcp_jobdir]
  file mkdir $dir
  foreach pat {pending.* reply.* busy.* tmp.*} {
    foreach f [glob -nocomplain [file join $dir $pat]] {
      catch {file delete $f}
    }
  }
  catch {file delete [file join $dir cancel]}
}

proc mcp_write_job {question} {
  if {[info commands winfo] != "" && [winfo exists .mcpkeys]} {
    if {![mcp_save_keys]} {
      error "The keys were not saved."
    }
  }
  mcp_reset_spool
  set dir [mcp_jobdir]
  set fh [open [file join $dir question.txt] w]
  puts -nonewline $fh $question
  close $fh
  set id [mcp_selected]
  set model ""
  set effort ""
  set fast 0
  foreach row [mcp_rows] {
    if {[lindex $row 0] == $id} {
      set model [lindex $row 3]
      set effort [lindex $row 4]
      set fast [lindex $row 5]
    }
  }
  set fh [open [file join $dir meta] w]
  puts $fh "agent $id"
  puts $fh "model $model"
  puts $fh "effort $effort"
  puts $fh "fast $fast"
  set tech [mcp_tech_name]
  if {$tech != ""} { puts $fh "tech $tech" }
  close $fh
  set fh [open [file join $dir layers.txt] w]
  foreach L [mcp_layer_names] {
    puts $fh $L
  }
  close $fh
}

proc mcp_tools_dir {} {
  global MCP
  foreach d [list [file join $MCP(root) mcp-tools] /mmi-pdk-live/mcp-tools /mmi-bundle/mcp-tools] {
    if {[file exists [file join $d mcp-paint]]} { return $d }
  }
  return ""
}

proc mcp_ask_start {} {
  global MCP env
  if {$MCP(running)} {
    mcp_log "An answer is already running."
    return
  }
  if {![winfo exists .mcpask.q]} { return }
  set q [string trim [.mcpask.q get 1.0 end]]
  if {$q == ""} {
    mcp_log "Type a question first."
    return
  }
  if {[catch {mcp_write_job $q} err]} {
    mcp_log_err $err
    return
  }
  set script [file join $MCP(root) mcp_ask.py]
  if {![file readable $script]} {
    set script /mmi-bundle/mcp_ask.py
  }
  if {![file readable $script]} {
    mcp_log_err "mcp_ask.py was not found."
    return
  }
  set tools [mcp_tools_dir]
  if {![info exists MCP(path)]} {
    set MCP(path) $env(PATH)
  }
  set env(PATH) $MCP(path)
  set env(MAX_MCP_DIR) [mcp_jobdir]
  set env(MAX_MCP_HOME) [mcp_confdir]
  set env(PYTHONUNBUFFERED) 1
  if {$tools != ""} {
    set env(MAX_MCP_TOOLS) $tools
    set env(PATH) "$tools:$MCP(path)"
  }
  set MCP(running) 1
  # Tcl 8.0 reads 2>@1 as a channel named "1", which does not exist.
  # |& joins python's stderr onto the pipe this window reads.
  set args [list python3 -u $script [mcp_jobdir] |& cat -u]
  if {[catch {set MCP(chan) [open |$args r]} err]} {
    set MCP(running) 0
    mcp_log_err "Could not start python3: $err"
    if {[string match "*couldn't execute*" $err] && [string match *python3* $err]} {
      mcp_log_err "python3 is a nix package in the CAD environment."
    }
    return
  }
  fconfigure $MCP(chan) -blocking 0 -buffering line
  fileevent $MCP(chan) readable mcp_ask_readable
  mcp_log "Asking [mcp_selected]. Layout steps will show up in this window and in the layout."
  set MCP(poll) [after 80 mcp_spool_poll]
}

proc mcp_draw_inverter {} {
  if {[info commands winfo] == "" || ![winfo exists .mcpask.q]} { return }
  .mcpask.q delete 1.0 end
  .mcpask.q insert 1.0 "Draw the layout of a very simple CMOS inverter, one rectangle at a time, so I can watch each step. Label the input, the output, and the supplies."
  mcp_ask_start
}

proc mcp_on_line {line} {
  if {[string match "LOG *" $line]} {
    mcp_log [string range $line 4 end]
    return
  }
  if {[string match "ERR *" $line]} {
    mcp_log_err [string range $line 4 end]
    return
  }
  if {$line == "DONE"} {
    mcp_log "Finished."
    return
  }
  if {$line != ""} { mcp_log $line }
}

proc mcp_ask_readable {} {
  global MCP
  if {$MCP(chan) == ""} { return }
  if {[eof $MCP(chan)]} {
    set chan $MCP(chan)
    set MCP(chan) ""
    catch {fileevent $chan readable {}}
    if {[catch {close $chan} err] && $err != ""} {
      mcp_log_err $err
    }
    set MCP(running) 0
    return
  }
  if {[gets $MCP(chan) line] < 0} { return }
  mcp_on_line $line
}

proc mcp_ask_stop {} {
  global MCP
  set dir [mcp_jobdir]
  catch {file mkdir $dir}
  catch {
    set fh [open [file join $dir cancel] w]
    puts $fh cancel
    close $fh
  }
  if {[info exists MCP(chan)] && $MCP(chan) != ""} {
    foreach p [pid $MCP(chan)] {
      catch {exec kill $p}
    }
    set chan $MCP(chan)
    set MCP(chan) ""
    catch {fileevent $chan readable {}}
    catch {close $chan}
  }
  set MCP(running) 0
}

proc mcp_work_dir {} {
  if {[file isdirectory /mmi-home/work]} { return /mmi-home/work }
  return [pwd]
}

proc mcp_clear_box {} {
  global MCP
  catch {unset MCP(bbx0)}
  catch {unset MCP(bby0)}
  catch {unset MCP(bbx1)}
  catch {unset MCP(bby1)}
}

proc mcp_note_box {x1 y1 x2 y2} {
  global MCP
  if {![info exists MCP(bbx0)]} {
    set MCP(bbx0) $x1
    set MCP(bby0) $y1
    set MCP(bbx1) $x2
    set MCP(bby1) $y2
    return
  }
  if {$x1 < $MCP(bbx0)} { set MCP(bbx0) $x1 }
  if {$y1 < $MCP(bby0)} { set MCP(bby0) $y1 }
  if {$x2 > $MCP(bbx1)} { set MCP(bbx1) $x2 }
  if {$y2 > $MCP(bby1)} { set MCP(bby1) $y2 }
}

proc mcp_zoom_box {x0 y0 x1 y1} {
  if {[info commands lay_box] != ""} {
    catch {lay_box $x0 $y0 $x1 $y1}
  }
  if {[info commands :findbox] != ""} {
    catch {:findbox zoom}
  }
}

proc mcp_zoom_union {} {
  global MCP
  if {![info exists MCP(bbx0)]} { return }
  mcp_zoom_box [expr {$MCP(bbx0) - 8}] [expr {$MCP(bby0) - 8}] \
      [expr {$MCP(bbx1) + 8}] [expr {$MCP(bby1) + 8}]
}

proc mcp_need_edit {} {
  if {[info commands lay_editcell] != "" && [lay_editcell] == ""} {
    return "error: no edit cell; call mcp-cell first"
  }
  if {[info commands db_cell_read_only] != "" && [db_cell_read_only]} {
    return "error: the edit cell is read-only"
  }
  return ""
}

proc mcp_known_layer {layer} {
  if {![mcp_name_ok $layer]} { return 0 }
  set names [mcp_layer_names]
  if {[llength $names] == 0} { return 0 }
  foreach L $names {
    if {$L == $layer} { return 1 }
  }
  return 0
}

proc mcp_do_layers {} {
  set names [mcp_layer_names]
  if {[llength $names] == 0} {
    return "error: no technology layers"
  }
  mcp_log "layers [join $names { }]"
  return [join $names " "]
}

proc mcp_do_cell {name} {
  if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $name] || [string length $name] > 40} {
    return "error: cell name must be letters, digits, and underscores"
  }
  if {[info commands lay_editcell] != "" && [lay_editcell] == $name} {
    mcp_clear_box
    mcp_log "editing $name"
    return "editing $name"
  }
  if {[info commands cell_in_memory] != "" && [cell_in_memory $name]} {
    if {[catch {cell_load $name} err]} { return "error: $err" }
    mcp_clear_box
    mcp_log "editing $name"
    update
    return "editing $name"
  }
  set dir [mcp_work_dir]
  global CELL
  set suffix .max
  if {[info exists CELL(default_suffix)] && $CELL(default_suffix) != ""} {
    set suffix $CELL(default_suffix)
  }
  set path [file join $dir "$name$suffix"]
  if {![file exists $path]} {
    if {[info commands db_cell_new] == ""} {
      return "error: db_cell_new is not available"
    }
    if {[catch {db_cell_new $name $path} err]} { return "error: $err" }
  }
  if {[info commands cell_load] == ""} {
    return "error: cell_load is not available"
  }
  if {[catch {cell_load $name $dir} err]} { return "error: $err" }
  mcp_clear_box
  mcp_log "editing $name"
  update
  return "editing $name"
}

proc mcp_order_box {x1 y1 x2 y2} {
  upvar 1 $x1 X1 $y1 Y1 $x2 X2 $y2 Y2
  set X1 [mcp_int $X1]
  set Y1 [mcp_int $Y1]
  set X2 [mcp_int $X2]
  set Y2 [mcp_int $Y2]
  if {$X1 == "" || $Y1 == "" || $X2 == "" || $Y2 == ""} { return 0 }
  if {$X2 < $X1} {
    set t $X1
    set X1 $X2
    set X2 $t
  }
  if {$Y2 < $Y1} {
    set t $Y1
    set Y1 $Y2
    set Y2 $t
  }
  return 1
}

proc mcp_do_paint {layer x1 y1 x2 y2 note} {
  if {![mcp_known_layer $layer]} {
    return "error: layer $layer is not in this technology"
  }
  if {![mcp_order_box x1 y1 x2 y2]} {
    return "error: coordinates must be integers"
  }
  if {$x1 == $x2 || $y1 == $y2} {
    return "error: the rectangle is empty"
  }
  set why [mcp_need_edit]
  if {$why != ""} { return $why }
  if {[info commands db_paint] == ""} {
    return "error: db_paint is not available"
  }
  if {[catch {db_paint $layer $x1 $y1 $x2 $y2} err]} {
    return "error: $err"
  }
  mcp_note_box $x1 $y1 $x2 $y2
  mcp_zoom_union
  set msg "paint $layer $x1 $y1 $x2 $y2"
  if {$note != ""} { append msg " ($note)" }
  mcp_log $msg
  update
  return "painted $layer $x1 $y1 $x2 $y2"
}

proc mcp_do_label {layer text x y} {
  if {![mcp_known_layer $layer]} {
    return "error: layer $layer is not in this technology"
  }
  set x [mcp_int $x]
  set y [mcp_int $y]
  if {$x == "" || $y == ""} { return "error: coordinates must be integers" }
  if {$text == ""} { return "error: empty label" }
  if {[string length $text] > 64} {
    set text [string range $text 0 63]
  }
  set why [mcp_need_edit]
  if {$why != ""} { return $why }
  if {[info commands db_label] == ""} {
    return "error: db_label is not available"
  }
  set x2 [expr {$x + 8}]
  set y2 [expr {$y + 4}]
  set cmd [list db_label -kind local -pos c $layer $text $x $y $x2 $y2]
  if {[catch {eval $cmd} err]} {
    set cmd [list db_label -kind text -pos center $layer $text $x $y $x2 $y2]
    if {[catch {eval $cmd} err2]} {
      return "error: $err2"
    }
  }
  mcp_note_box $x $y $x2 $y2
  mcp_zoom_union
  mcp_log "label $layer $text"
  update
  return "labeled $layer $text"
}

proc mcp_do_zoom {x1 y1 x2 y2} {
  if {![mcp_order_box x1 y1 x2 y2]} {
    return "error: coordinates must be integers"
  }
  mcp_zoom_box $x1 $y1 $x2 $y2
  mcp_log "zoom $x1 $y1 $x2 $y2"
  update
  return "zoomed $x1 $y1 $x2 $y2"
}

proc mcp_apply {line} {
  set p [mcp_split_line $line]
  set op [lindex $p 0]
  if {$op == "layers"} { return [mcp_do_layers] }
  if {$op == "cell"} { return [mcp_do_cell [lindex $p 1]] }
  if {$op == "paint"} {
    return [mcp_do_paint [lindex $p 1] [lindex $p 2] [lindex $p 3] \
        [lindex $p 4] [lindex $p 5] [lindex $p 6]]
  }
  if {$op == "label"} {
    return [mcp_do_label [lindex $p 1] [lindex $p 2] [lindex $p 3] [lindex $p 4]]
  }
  if {$op == "zoom"} {
    return [mcp_do_zoom [lindex $p 1] [lindex $p 2] [lindex $p 3] [lindex $p 4]]
  }
  return "error: unknown tool $op"
}

proc mcp_pending_id {path} {
  set tail [file tail $path]
  return [string range $tail 8 end]
}

proc mcp_step_done {id reply} {
  global MCP
  set dir [mcp_jobdir]
  set tmp [file join $dir reply.$id.in]
  set dst [file join $dir reply.$id]
  set fh [open $tmp w]
  puts $fh $reply
  close $fh
  catch {file delete $dst}
  catch {file rename $tmp $dst}
  catch {file delete [file join $dir busy.$id]}
  set MCP(step_busy) 0
  set MCP(step_after) ""
  mcp_spool_poll
}

proc mcp_take_pending {path} {
  global MCP
  set id [mcp_pending_id $path]
  set dir [mcp_jobdir]
  set busy [file join $dir busy.$id]
  if {[catch {file rename $path $busy} err]} {
    set MCP(poll) [after 100 mcp_spool_poll]
    return
  }
  set MCP(step_busy) 1
  set fh [open $busy r]
  gets $fh line
  close $fh
  if {[catch {set reply [mcp_apply $line]} err]} {
    set reply "error: $err"
  }
  set wait 120
  set op [lindex [mcp_split_line $line] 0]
  if {$op == "paint" || $op == "label"} {
    set wait 450
  }
  set MCP(step_after) [after $wait [list mcp_step_done $id $reply]]
}

proc mcp_spool_poll {} {
  global MCP
  set MCP(poll) ""
  if {$MCP(step_busy)} {
    set MCP(poll) [after 100 mcp_spool_poll]
    return
  }
  set dir [mcp_jobdir]
  set files [lsort [glob -nocomplain [file join $dir pending.*]]]
  if {[llength $files] > 0} {
    mcp_take_pending [lindex $files 0]
    return
  }
  if {$MCP(running)} {
    set MCP(poll) [after 100 mcp_spool_poll]
  }
}

proc mcp_install_menus {} {
  global MCP
  if {$MCP(menus_done)} { return }
  incr MCP(menu_tries)
  if {$MCP(menu_tries) > 30} { return }
  if {[info commands menu_add] == ""} {
    if {[info commands after] != ""} {
      after 500 mcp_install_menus
    }
    return
  }
  if {[catch {
    menu_add -menu mcp -label "API Keys..." -command {mcp_open keys} \
        -help "Save API keys for Cursor and other agents"
  } err]} {
    if {[info commands after] != ""} {
      after 500 mcp_install_menus
    }
    return
  }
  catch {
    menu_add -menu mcp -label "Ask..." -command {mcp_open ask} \
        -help "Ask an agent. A layout is drawn one nix-tool step at a time."
  }
  set MCP(menus_done) 1
}

proc mcp_selftest {} {
  set failed 0
  set row [lindex [mcp_agent_table] 0]
  if {[lindex $row 0] != "cursor"} {
    puts "FAIL cursor id"
    incr failed
  }
  if {[lindex $row 2] != "grok-4.7" || [lindex $row 3] != "xhigh" || [lindex $row 4] != "0"} {
    puts "FAIL cursor model settings"
    incr failed
  }
  set parts [mcp_split_line "paint\tpoly\t0\t0\t8\t40\tgate"]
  if {[llength $parts] != 7 || [lindex $parts 1] != "poly" || [lindex $parts 6] != "gate"} {
    puts "FAIL split"
    incr failed
  }
  if {[mcp_int 08] != "8" || [mcp_int -4] != "-4" || [mcp_int 1.5] != "" || [mcp_int 12345678] != ""} {
    puts "FAIL int"
    incr failed
  }
  set x1 08
  set y1 2
  set x2 1
  set y2 9
  if {![mcp_order_box x1 y1 x2 y2] || $x1 != 1 || $y1 != 2 || $x2 != 8 || $y2 != 9} {
    puts "FAIL order"
    incr failed
  }
  if {![mcp_name_ok poly] || [mcp_name_ok "poly m1"]} {
    puts "FAIL name"
    incr failed
  }
  if {![mcp_keep_error "error: layer poly" 0] || [mcp_keep_error "paint poly" 0]} {
    puts "FAIL keep error"
    incr failed
  }
  if {![mcp_keep_error "Type a question first." 1]} {
    puts "FAIL keep forced"
    incr failed
  }
  global MCP
  set MCP(errors) {}
  lappend MCP(errors) "Could not start python3: missing"
  lappend MCP(errors) "error: layer poly is not in this technology"
  if {[mcp_error_blob] != "Could not start python3: missing\nerror: layer poly is not in this technology"} {
    puts "FAIL error blob"
    incr failed
  }
  foreach t {mcp-io mcp-layers mcp-cell mcp-paint mcp-label mcp-zoom mcp-nix} {
    if {![file exists [file join $MCP(root) mcp-tools $t]]} {
      puts "FAIL missing $t"
      incr failed
    }
  }
  if {![file exists [file join $MCP(root) mcp_ask.py]]} {
    puts "FAIL missing mcp_ask.py"
    incr failed
  }
  if {$failed} {
    error "$failed mcp checks failed"
  }
  puts "mcp_selftest ok"
}

mcp_install_menus
