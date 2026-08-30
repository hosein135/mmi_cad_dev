## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
## DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
## ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
## JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
## DAMAGE.
## 
## JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
## INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
## UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************

set RCSVERSION(mode.tcl) { $Revision: 1.37 $ }

set MAX_STRUCT(mode_event) {event eval cmd}
set MAX_STRUCT(mode_info)  {cmd flags desc}

# Support for command modes (sets of bindings)

proc mode_init {} -desc {
  initialize modes (called once at startup)
} {
  global MODE mode_abort

  # set during POP_FROM call to gatekeeper during mode abort (Control-C)
  set mode_abort 0
  set MODE(next) ""

  _mode_main_define 
  _mode_max_internal_define  ;# must come after _mode_main_define
  _box_mode_define
  label_mode_define
  label_drag_mode_define
  _select_mode_define
  _duplicate_mode_define
  _clipboard_paste_mode_define
  _move_selected_mode_define
  _move_box_mode_define
  _move_again_mode_define
  _move_point_mode_define
  #_move_pasted_mode_define
  # Next edge mode put back 5/00 in at marshalls request.
  _next_mode_define
  _polygon_mode_define
  _polygon_drag_mode_define
  _polygon_edit_mode_define
  _circle_mode_define
  _circle_drag_mode_define
  _resize_box_mode_define
  _wire_draw_mode_define
  _wire_mode_define
#  _bus_draw_mode_define
#  _bus_mode_define
  _zoom_mode_define
  _zoom_drag_mode_define
  _ruler_mode_define
  _grid_move_define
  _edge_mode_define
  _edge_drag_mode_define
  _rect_mode_define
  _paint_edit_mode_define
  _gcell_stretch_mode_define
  _flyline_mode_define
  _rewire_mode_define
  _point_mode_define
  _sel_cell_mode_define
  _fplan_mode_define
}



proc _mode_max_internal_define {} -desc {
  set up mode internal default stuff.
} {
  # The common mode is special: it does not really exist as a separate
  # mode, but is a place holder for keys defined in all modes.
  # Init its data-base right here to avoid errors from mode_bind common.
  mode_def common "" ""

  # The MODE_DB data-base is built almost entirely when
  # modes are defined or when the menus are created.
  # Here we add in commands to the MODE_DB data-base that are not
  # included anywhere in the menus.

  # The MODE_DB has an entry for each command the user
  # may call.  The values can be:
  #	nowrap - comand does not need a command wrapper.
  #		If it doesnt have this flag, it DOES get a command wrapper.
  # point - command needs an interactive point but only
  #		when called from the menu.
  #	common - command can be called in common mode.
  #		Such commands must have no side-affects.


  # The MODE_DB data-base is mostly built from menu_bar.
  # These are a few extra commands in the MODE_DB data-base
  # that need special flags set.  This will allow people to map these
  # keys properly from a keymap file, regardless of whether
  # the commands are in a menu anywhere.

  # This is the list of additional commands that *must not* get a
  # command wrapper.  The command wrapper saves "undo", which
  # would clearly screw these up.
  mode_bind main "" :undo -cmd 0
  mode_bind main "" :redo -cmd 0

  # These are commands that can be "common" mode commands, ie, used in any mode.
  mode_bind common <Any-Control-c> mode_abort -cmd 0 -edit 0
  mode_bind common <Escape> mode_end -cmd 0 -edit 0
  mode_bind common "" :scroll -cmd 0
  mode_bind common "" :view -cmd 0
  mode_bind common "" :zoom -cmd 0
  mode_bind common "" :findbox -cmd 0
  mode_bind common "" :see -cmd 0
}


proc mode_msg {text {option ""}} -desc {
  Put text in max message window
} -doc {
  If option is "tmp", then this is a temporary message that applies
  only to the widget the cursor is currently over.  The regular
  mode message will be restored when the cursor enters the
  layout window by mode_msg_restore.

  Note that {mode_msg "" tmp} clears the mode message temporarily.

  If option is "inform", this is a temporary message that should
  be posted until the next command is executed, or until reset
  by {mode_msg "" inform}, then go back to normal "main" mode_msg.
  This type is needed because if you
  use a "tmp" message in a command that is invoked from the menu,
  the "tmp" message goes away as soon as the menu is unposted,
  because an <Enter> event is generated for the layout widget.

  If option is "global", then this is a global message that overrides
  all other mode messages, until reset by {mode_msg "" global}
  This is used mostly when a secondary window, like a prop_menu,
  takes control.

  If option is unspecified or "", the message is the actual
  mode message that applies to the current max mode, eg, wire,
  box, move, etc.  The message is also saved in mode_msg($max_win,main) and
  is reposted by mode_msg_restore whenever the cursor re-enters
  the layout window.
} {
  global max_win mode_msg i_cmd

  # if no current window yet, just return
  if { ! [info exists max_win] } { return ""; }

  switch $option {
    "global" {
      set mode_msg($max_win,global) $text
      if { $text == "" } {
	# Restore mode mesg for wherever we are now.
	return [mode_msg [use_first mode_msg($max_win,main)]]
      } else {
	set mode_msg($max_win) $text
      }
    }
    "" {
      set mode_msg($max_win,main) $text
    }
    "inform" {
      set mode_msg($max_win,inform) $text
      set i_cmd(inform_msg) $i_cmd(num)
    }
    "tmp" -
    default {
      set mode_msg($max_win,tmp) $text
      set i_cmd(tmp_msg) $i_cmd(num)
      if {[use_first mode_msg($max_win,global)] == "" } {
	set mode_msg($max_win) $text
      }
      return
    }
  }

  _mode_msg_restore
  return

  if {[use_first mode_msg($max_win,global)] == "" } {
    if { $option == "tmp" || $text != "" } {
      set mode_msg($max_win) $text
    } else {
      _mode_msg_restore
    }
  }
}

proc mode_inform_msg {text} -desc {
  put an informational message into message window
} -doc {
  put a message in the mode msg area that will persist until
  the next command is executed.  The information message 
  over-rides the normal mode message when the cursor is in the layout window.
  Use {mode_inform_msg ""} to clear it, which causes the current
  mode message, whatever it is, to come back.
} {
  set text [string trim $text \n]
  if { $text != "" } { msg "$text\n" }
  mode_msg $text inform
}


proc mode_tmp_msg {text} -desc {
  put temporary message into message window
} -doc {
  The message will survive only until the user moves the cursor
  out of and back into the layout window, or until the
  next command that qualifies for i_cmd_between, which
  are most commands that change something.
  This is used when the cursor is used to change the mode msg
  instantaneously when the cursor is moved over various max widgets.
} {
  # Knock off any trailing newline
  set text [string trim $text \n]
  if { $text != "" } { msg "$text\n" }
  mode_msg $text tmp
}


proc _mode_msg_restore {} -desc {
  called to restore mode msg whenever cursor enters layout window
} {
  global mode_msg max_win i_cmd
  # if no current window yet, just return
  if { [info exists max_win] } {

    if {[use_first mode_msg($max_win,global)] != "" } {
      set mode_msg($max_win) $mode_msg($max_win,global)
    } elseif {[use_first mode_msg($max_win,inform)] != "" && \
        $i_cmd(num) <= $i_cmd(inform_msg)+1 } {
      set mode_msg($max_win) $mode_msg($max_win,inform)
    } elseif {[use_first mode_msg($max_win,main)] != "" } {
      set mode_msg($max_win) $mode_msg($max_win,main)
    } else {
      # Who cares
    }
  }
}


if {0} {
  proc mode_msg {text {tmp ""}} -desc {
  set mode message to text
  } -doc {
  temporary messages are tagged by "source", to avoid race when 
  restore issued when menu unposted.
  } {
    global max_win mode_msg 

    # if no current window yet, just return
    if { ! [info exists max_win] } { return ""; }

    if {$text == "__RESTORE__"} {
      # restore mode msg, if current tmp msg is from same source
	if {$mode_msg($max_win,tmp) == $tmp} {
	    set mode_msg($max_win) $mode_msg($max_win,save)
	    set mode_msg($max_win,tmp) ""
	}
	return ""
    }

    set old_msg ""
    catch {set old_msg $mode_msg($max_win)}
    set mode_msg($max_win) $text

    set mode_msg($max_win,tmp) $tmp  
    if {$tmp == ""} {
	set mode_msg($max_win,save) $text
    } 
    return $old_msg
  }
}

proc mode_msg_build {top} -desc {
return new mode message area widget under top (does not pack it)
} {
    global mode_msg max_win

    set main [winfo toplevel $top]

    #initial message
    mode_msg "Welcome to Max."

    #build message widget
    return [label $top.msg -relief sunken -bd 2 -anchor w \
	    -fg blue -textvariable mode_msg($max_win)]
}
    
proc mode_def {mode_name gate_keeper_proc mode_msg} -desc {
  Defines new mode.
} -doc {
  gate_keeper_proc (if not {}) is called on mode entries and exits with
  one arg indicating type of entry or exit:
   PUSH_TO 
   POP_TO
   PUSH_FROM
   POP_FROM 

  mode_msg (if not {}) is posted to the window message area whenever mode is
  entered.
} {
    global MODES
    set MODES($mode_name) [list $gate_keeper_proc $mode_msg]
}


proc mode_bind {args} -desc {
  define binding for mode

  USAGE:
    mode_bind [-cmd <bool>] [-edit <bool>] [-desc <desc>] [-doc <doc>] mode_name event script
} -doc {

  -cmd 1 (DEFAULT) = use interactive command wrapper
    (makes undo, history etc. work)
  -cmd 0 = no command wrapper
    Note: if the mode_bind is being used to define bindings for
    a mode with a gate_keeper, which is the usual case, the
    gate_keeper function usually handles command wrapping by
    calling i_cmd_between if the mode made any modifications
    to the data-base, or i_cmd_between_undos if it didnt.
    In either of these cases, all the mode_bind calls to define
    that mode should have -cmd 0.

  -desc <desc> = one line description
    (if {} then desc from first command in script used).
  -doc <doc> = additional doc. (not currently used)
    (if {} then doc from first command in script used).  
  -edit <bool> = whether binding can be edited in keymap.
  mode_name = name of mode to add binding to.
  event = optional event to bind to (e.g. single char for simple key binding,
    or <event>, see tcl/tk doc).
  script = tcl script to bind to event.

  Notes: the stuff in the MODE_DB data-base applies to the script
  command, not the event.  So, for example, there can be only
  one value for the -edit flag, regardless of how many event
  bindings it has.  Multiple calls to this function result
  in multiple entries in the MODE_DB list, but only the first
  one will be found when searched.
} {
  global MODES MODE_DB

  ### PARSE ARGS 
  set pos_args [call_with_keyword $args { {cmd ""} desc doc {point 0} {edit 1}}]
  set mode_name [lindex $pos_args 0]
  set event [lindex $pos_args 1]
  set script [lindex $pos_args 2]

  if {![info exists MODES($mode_name)]} {
    puts "warning: mode_bind $mode_name called before: mode_def $mode_name"
    set MODES($mode_name) ""
  }

  if { $script == {} } {
      # 7/00, pat: no longer allow this.  Its not used, and
      # would cause multiple entries in the MODE_DB data-base.
      error "no script arg to mode_bind"
      #catch "unset MODE|${mode_name}($event)"
      return
  }

  if {$cmd == ""} {
      global MAX_DEVELOPER
      if { $MAX_DEVELOPER } {
	puts "warning: mode_bind: No -cmd arg to: $script ($args)"
      }
      set cmd 1
  }

  # Note: the "common" flag is redundant, because it only appears
  # in the "common" mode bindings, but it makes the mode_info
  # code slightly simpler.
  set flags ""
  if { $mode_name == "common" } { lappend flags "common" }
  if { $cmd != 0 }   { lappend flags "wrap" }
  if { $edit != 0 }  { lappend flags "edit" }
  if { $point != 0 }  { lappend flags "point" }
  # We are putting the entire script in MODE_DB for command lookup.
  # Why?  Because a few commands (notably mode_push) may appear
  # in multiple modes, so the entire command must be in there.
  set c.cmd $script
  set c.flags $flags
  set c.desc $desc
  lappend MODE_DB($mode_name) [destruct mode_info c]

  # Each command must begin with some kind of "eval" command,
  # for consistency, to make it easy for the keymap code
  # to get the command from the MODE_EVENTS data-base.
  if { $mode_name == "common" } {
    set eval i_cmd_eval_common
  } elseif { [memq $flags "wrap"] } {
    set eval i_cmd_eval
  } else {
    set eval i_cmd_eval_nowrap
  }

  # Set up the factory keymap, and also save as current keymap.
  if { $event != "" } {
    global MODE_EVENTS|${mode_name} MODE_EVENTS|${mode_name},factory
    set MODE_EVENTS|${mode_name}($event) [list $event $eval $script]
    set MODE_EVENTS|${mode_name},factory($event) [list $event $eval $script]
  }
}


proc mode_rebind {mode event cmd} -desc {
  Bind the key to the event, using pre-existing MODE_DB data-base.
} -doc {
  This is called from keymap to code to change keymaps.
  The information about how the command should be wrapped is
  assumed to already exist in the MODE_DB data-base, probably
  as a result of a previous mode_bind when the factory
  modes were created.
} {
  if {$mode == "default"} {
    # Put it in either main or common mode, depending on the command.
    struct mode_info c [mode_info $cmd]
    if { [memq ${c.flags} "common"] } {
      set mode_name common
    } else {
      set mode_name main
    }
    # Delete old binding, if any.
    global MODE_EVENTS|main MODE_EVENTS|common
    catch {unset MODE_EVENTS|main($event)}
    catch {unset MODE_EVENTS|common($event)}
  } else {
    set mode_name $mode
    global MODE_EVENTS|$mode_name
    struct mode_info c [mode_info $cmd]
    # Delete old binding, if any.
    catch {unset MODE_EVENTS|${mode_name}($event)}
  }

  if { $mode_name == "common" } {
    set eval i_cmd_eval_common
  } elseif { [memq ${c.flags} "wrap"] } {
    set eval i_cmd_eval
  } else {
    set eval eval
  }

  if { $event != "" } {
    set MODE_EVENTS|${mode_name}($event) [list $event $eval $cmd]
  }
}

proc mode_copy {in_mode out_mode} -desc {
  Copy bindings from in_mode to out_mode.
} -doc {
  This is done by the keymap code prepatory to remapping bindings.
  The <action> may be:
    basic, copy only non-editable bindings;
    all, copy all bindings.
} {
  global MODE_EVENTS|$in_mode MODE_EVENTS|$out_mode

  catch {unset MODE_EVENTS|$out_mode}

  foreach event [array names MODE_EVENTS|$in_mode] {
    set MODE_EVENTS|${out_mode}($event) [set MODE_EVENTS|${in_mode}($event)]
  }
}

proc mode_factory_reset {} -desc {
  Reset all modes to factory defaults.
} {
  global MODES
  foreach modename [array names MODES] {
    mode_copy ${modename},factory ${modename}
  }
}

proc mode_current {} -desc {
    Returns name of current command mode.
} {
    global MODE max_win
    set name [lindex $MODE($max_win) 0]
    if { $name == {} } {set name main}
    return $name
}

proc mode_info {command args} -desc {
  return list: mode_info struct for specified command.
} -doc {
  USAGE:
    mode_info command [-mode modename]

  If mode is "default" or unspecified, look in "main" and "common" mode.
  flags include:
    common  - command is allowed in "common" mode.
    edit    - command is to be editable in keymap popup window.
    wrap    - command requires command wrapper for undo support.
} {
  global MODE_DB
  set retval ""
  # First see if the entire command is in the data-base.
  # If that is not found, see if just the first word of the command
  # is in the data-base.
  call_keyword $args  {{mode default}}
  foreach cmd [list $command [lindex $command 0]] {
    if { $mode == "default" } {
      # Search both main and common mode.
      set mode_stuff [lsearch2 -index 0 -value $MODE_DB(main) $command]
      set common_stuff [lsearch2 -index 0 -value $MODE_DB(common) $command]
      set retval [use_first mode_stuff common_stuff]
    } else {
      set retval [lsearch2 -index 0 -value [use_first MODE_DB($mode)] $command]
    }
    if { $retval != "" } {
      break
    }
  }

  # Unrecognized command.
  # If it is in main mode, assume it requires wrapping.
  if { $retval == "" && ($mode == "main" || $mode == "default") } {
    set s.cmd ""
    set s.desc ""
    set s.flags "wrap"
    set retval [destruct mode_info s]
  }

  return $retval
}


proc mode_stack {} -desc {
    Returns mode stack (null if not in submode)
} {
    global MODE max_win
    return $MODE($max_win)
}

proc _mode_special_layout_bindings {layout_widget} -desc {
  create  bindings for <Enter>, and <Leave> events
} -doc {
  These bindings are common to all modes.
  Not displayed by mode_box
} {
    set w $layout_widget

    # Cause keyboard events to be sent to layout window when cursor is inside it.
    # Needed so point can be set for Mgc commands.
    bind $w <Enter> "focus $w;_mode_msg_restore"
    #bind $w <Leave> "focus ."

    # Note: <Motion> and <Any-Motion> are equivalent,
    # so to make sure this binding occurs even if the mode itself
    # bind Motion, prepend the "+".  If a mode does not want
    # the cursor message, it should use status_enable.
    bind $w <Any-Motion> +cursor_msg_update
}

proc _mode_setup {main_win mode_name {pop ""}} -desc {
  Actually setup mode bindings and post message.
} -doc {
  Common code used by mode_push and mode_pop to change modes.
  The script is always sent through some kind of eval.
  The keymap code blindly strips off the first word,
  assuming it is an eval.
} {
    global MODES
    set w $main_win.layout 

    # clear old bindings
    foreach seq [bind $w] {
	bind $w $seq {}
    }

    foreach mode "common $mode_name" {
      global MODE_EVENTS|$mode
      foreach entry [array names MODE_EVENTS|$mode] {
	struct mode_event e [set MODE_EVENTS|${mode}($entry)]
	bind $w ${e.event} [list ${e.eval} ${e.cmd}]
	# Map all Alt- bindings to the Meta- key as well.
	# This is done because some window managers (eg: openwindows)
	# pre-empt the Alt key for their own use.  Mapping Meta-
	# allows user to use Meta-key instead of Alt-key in max.
	if {[regsub {Alt-} ${e.event} "Meta-" meta_event]} {
	  bind $w $meta_event [list ${e.eval} ${e.cmd}]
	}
      }
    }

    # restore special bindings (not displayed by mode_box)
    _mode_special_layout_bindings $w

    # recreate common bindings
#   global MODE|common
#    foreach seq [array names MODE|common] {
#	setl {script cmd desc doc} [set MODE|common($seq)]
#	# must NOT wrap common mode commands, they can be called anytime!
#	assert { $cmd == 0 || $cmd == {} }
#	bind $w $seq [list i_cmd_eval_common $script]
#    }

#    # create mode specific bindings
#    global MODE|$mode_name
#    foreach seq [array names MODE|$mode_name] {
#	setl {script cmd desc doc} [set MODE|${mode_name}($seq)]
#	if { $cmd == 0 || $cmd == {} } {
#	  # no cmd wrap.  Add an eval for consistency.
#	  bind $w $seq [list eval $script]
#	} else {
#	  # cmd wrap
#	  # WHY ARE THERE catch HERE? (pat)
#	  catch [list bind $w $seq [list i_cmd_eval_set_last $script]]
#	}
#    }

    # post mode message
    # If there was a temporary message, let it survive a mode_pop
    global mode_msg max_win
    set old_msg $mode_msg($max_win)
    mode_msg "$mode_name mode.  [lindex $MODES($mode_name) 1]"
    if { $pop == "pop" && $old_msg == [use_first mode_msg($max_win,tmp)] } {
      # Restore temporary message.
      set mode_msg($max_win) $old_msg
    }

    # cursor different for submodes
    if { $mode_name == "main" } {
	cursor_mode 0
	# Make sure pan mode is reset, in case we error out of a mode
	# that enabled it.
	pan_reset
    } else {
	cursor_mode 1
    }
}

proc mode_push {mode_name {persistent 0}} -desc {
    Enter a command mode.
} -doc {
    If the persistent parameter is non-zero, the mode will be continually
    entered until either mode_abort or mode_end is called.
} {
    global MODE MODES max_win

    # check that we are not doing a mode_push inside a command
    # usually wrong, since command terminated prior to processing events for
    # new mode.
    # 5-99: pat removed.  If you execute a command interactively,
    # i_cmd_eval always sets CURSOR(busy) and you get this message incorrectly.
    # Nested mode_push are legal, so you cant check mode_current either.
    # global CURSOR
    #if { $CURSOR(busy) } {
    #   puts "INTERNAL ERROR:  mode_push from inside mode: [mode_current]"
    #}

    # notify old mode gate-keeper
    set old_mode [mode_current]
    set old_gate [lindex $MODES($old_mode) 0] 
    if { $old_gate != {} } {$old_gate PUSH_FROM}
 
    # push
    push MODE($max_win) $mode_name
    _mode_setup $max_win $mode_name

    # notify new mode gate-keeper
    set new_gate [lindex $MODES($mode_name) 0]
    if { $new_gate != {} } {$new_gate PUSH_TO}

    if { $persistent } { set MODE(next) $mode_name }
}

proc mode_pop {} -desc {
    Exit a command mode.
} {
    global MODE MODES max_win

    # notify old mode gate-keeper
    set old_mode [mode_current]
    set old_gate [lindex $MODES($old_mode) 0] 
    if { $old_gate != {} } {
	# catch errors so we can exit from broken modes!
	if { [catch "$old_gate POP_FROM" msg] != 0 } {
	    bgerror "Error in $old_gate:  $msg"
	}
    }

    # pop
    pop MODE($max_win)
    set mode_name [mode_current]
    _mode_setup $max_win $mode_name pop

    # notify new mode gate-keeper
    set new_gate [lindex $MODES($mode_name) 0] 
    if { $new_gate != {} } {$new_gate POP_TO}

    if { $mode_name == "main" } {
	# This is the end of a main mode.
	if { [use_first MODE(defer_undo) '0] } {
	  # If undo was deferred because we were in a mode, do it now
	  # that the mode is finished.
	  i_cmd_between
	  set MODE(defer_undo) 0
	} else {
	  # Just update the screen.
	  i_cmd_between_undos
	}

	if { $MODE(next) == "" } {
	    # Leaving the persistent mode.
	    _tool_bar_reset
	} else {
	    # Re-enter the current persistent mode.
	    mode_push $MODE(next)
	}
    }
}

proc mode_change {args} -desc {
    like a mode_pop followed by a mode_push (but skips intermediate mode)
} -doc {
  USAGE: mode_change [-force] mode_name

  If -enter, do not call the gate-keeper of the mode we are leaving.
  If -force, do not call the gate-keepers of either the mode we are
  leaving or the mode we are entering, just enter the new mode instantly.
  This may be useful to change the bindings when both modes use the
  same gate-keeper.
} {
    global MODE MODES max_win

    # Parse args
    set force 0
    set enter 0
    switch -- [lindex $args 0] {
      "-force" {
	set force 1
	set args [lrange $args 1 end]
      }
      "-enter" {
	set enter 1
	set args [lrange $args 1 end]
      }
    }
    set mode_name $args

    if {! $force && ! $enter} {

      # notify old mode gate-keeper
      set old_mode [mode_current]
      set old_gate [lindex $MODES($old_mode) 0] 
      if { $old_gate != {} } {$old_gate POP_FROM}
    }

    # pop/push
    pop MODE($max_win)
    push MODE($max_win) $mode_name
    _mode_setup $max_win $mode_name
    
    if {! $force} {
      # notify new mode gate-keeper
      set new_gate [lindex $MODES($mode_name) 0] 
      if { $new_gate != {} } {$new_gate PUSH_TO}
    }
}

proc mode_end {} -desc {
    Exit command submode, all the way up to main mode.
} {
    global MODE
    set MODE(next) ""
    while { [mode_current] != "main" } {
	mode_pop
    }
}

proc mode_abort {} -desc {
    Abort command submode, all the way up to main mode.
} -doc {
    Commands are normally undone as they are aborted.
    If a submode sets mode_abort to 0, then we dont abort
    any nested submodes above that.  For example, zoom submode
    does this so you can abort a zoom without aborting
    the submode that it was called from.
} {
    global MODE mode_abort

    set mode_abort 1
    _tool_bar_reset
    set MODE(next) ""  ;# Redundant with _tool_bar_reset
    while { [mode_current] != "main" && $mode_abort } {
	mode_pop
    }
    set mode_abort 0
}

proc mode_win_init {main_win} -desc {
    Called when creating new main window to initialize mode stuff.
} {
    global MODE 

    # initial mode stack
    set MODE($main_win) {}

    _mode_setup $main_win main
}

proc _mode_main_define {} -desc {
define bindings for main mode
} {
    mode_def main {} {BUT-1 selects, BUT-2 moves selection, BUT-3 paints, CTRL-BUT-3 erases}
       
    # Note: We could add i_cmd_eval_common before these commands,
    # which would increment i_cmd(num) and update the screen.
    # Currently, screen update (i_cmd_between_undos)
    # is done during mode_pop, so its redundant.

    set mode main

    ### MOUSE
    mode_bind $mode -cmd 0 -edit 0 -desc "select (point or drag box)" \
	    <Button-1> \
	    select_mode_enter
    mode_bind $mode -cmd 0 -edit 0 -desc "select more (point or drag box)" \
	    <Shift-Button-1> \
	    "select_mode_enter add"
    mode_bind $mode -cmd 0 -edit 0 -desc "select less (point or drag box)" \
	    <Alt-Button-1> \
	    "select_mode_enter sub"
    
    if { 0 } {
	# Change cursor immediately when user presses a shift/alt/meta key.
	# This needs more work: the deselect cursor would need
	# to be used any time the tool_bar is in sub mode.
	# And you cant really debug this until sel_area -less is working.
	mode_bind $mode -cmd 0 -edit 0 <Alt-Motion> { cursor_mode deselect ; cursor_msg_update}
	mode_bind $mode -cmd 0 -edit 0 <Motion> { cursor_mode select ; cursor_msg_update}
    }

    # NOTE: this binding is also in _sel_cell_mode_define
    mode_bind $mode -cmd 0 -edit 0 \
	-desc "move selected (if nothing selected move/resize box)" \
	<Button-2> \
	move_something

    mode_bind $mode -cmd 0 -desc "move selected horizontally or vertically" \
	<Shift-Button-2> -edit 0 \
	move_something

    mode_bind $mode -cmd 0 -edit 0 \
	-desc "stretch selected horizontally or vertically" \
	<Control-Button-2> \
	"move_something stretch"

    # mode_bind $mode -cmd 0 -edit 0 \
	-desc "stretch wire horizontally or vertically" \
	<Alt-Button-2> \
	_rewire_select

    # 2/14: modified binding to operate only on selectable layers.
    # The old binding was: ":paint -button" 
    # note that :paint -button is undocumented!

    mode_bind $mode -cmd 1 -edit 0 \
	-desc "paint layers under cursor into box" \
	<Button-3> paint_add
    mode_bind $mode -cmd 1 -edit 0 \
	-desc "erase layers under cursor from box" \
	<Control-Button-3> paint_erase
}

# initial values

proc mode_box {} -desc {
    popup hot key list
} {
  global mode_box mode_msg max_win

  ### BUILD WIDGET

  set w .mode_box
  set oldFocus [focus]

  # The space key toggles visibility of the mode box.
  # This check is in case the cursor is over the max window,
  # not over the mode box, when user presses space.

  if {[winfo exists $w]} {
    catch {destroy $w}
    return
  }

  toplevel $w -borderwidth 0

  wm geometry $w "750x500[_relative_origin]"
  wm title $w "max hot keys ([mode_current] mode)"
  wm maxsize $w 1000 1000
  wm minsize $w 100 100
  # end build of toplevel

  # MESSAGE AT TOP

  frame $w.frame1 \
    -borderwidth 0 \
    -relief raised

  # CLOSE BUTTON
  button $w.frame1.close \
	  -text "Close (or hit space key again)" \
	  -command "catch {destroy $w}"
  pack $w.frame1.close -side left -fill both -expand 1
  if { [mode_current] == "main" } {
    # Must be in main mode to edit the keymaps.
    # And only the main/common mode keymaps can be edited, anyway.
    button $w.frame1.edit \
	  -text "Edit Keymap..." \
	  -command "catch {destroy $w};keymap_edit"
    pack $w.frame1.edit -side right
  }
  button $w.frame1.save \
	  -text "Save to File..." \
	  -command "doc_save_to_file $w.bindings.list"
  pack $w.frame1.save -side right
  
  # BINDINGS
  frame $w.bindings \
	  -borderwidth 0 \
	  -relief raised
  
  scrollbar $w.bindings.vscroll \
	  -relief raised \
      -highlightthickness 0 \
	  -command "$w.bindings.list yview"
  
  text $w.bindings.list -relief raised -bd 2 \
      -yscrollcommand "$w.bindings.vscroll set" \
      -font *-courier-bold-r-normal--*-120-*-*-*-*-*-*

  bind $w <Any-space> [list catch "focus $oldFocus;destroy $w"]
  bind $w <Any-Control-c> [list catch "focus $oldFocus;destroy $w"]
  bind $w <Escape> [list catch "focus $oldFocus;destroy $w"]

  bind $w <Down> "$w.bindings.list yview scroll 1 units"
  bind $w <Up> "$w.bindings.list yview scroll -1 units"

  # same bindings for pageup and pagedown
  bind $w <Next> "$w.bindings.list yview scroll 1 pages"
  bind $w <Prior> "$w.bindings.list yview scroll -1 pages"


  # packing
  pack append $w.bindings \
	  $w.bindings.list {left fill expand} \
	  $w.bindings.vscroll {left filly}
  pack append $w \
	  $w.frame1 {bottom fill} \
	  $w.bindings {left fill expand}

  # generate content
  $w.bindings.list insert end [use_first mode_msg($max_win)]
  $w.bindings.list insert end "\n"

  _mode_box_update_mode $w common
  _mode_box_update_mode $w [mode_current]

  $w.bindings.list configure -state disabled
  update idletasks
  focus $w
}


proc _mode_box_update_mode {w mode_name} -desc {
    add list box entries for named mode.
} {
  global MODE_DB

  # mode heading
  $w.bindings.list insert end "\n"
  $w.bindings.list insert end "$mode_name mode:\n"

  # Generate a list where the first element is the sort key.
  set list ""
  foreach thing [mode_events $mode_name] {
    struct mode_event e $thing
    lappend list [list [seq_sort_key ${e.event}] ${e.event} ${e.cmd}]
  }

  foreach thing [lsort -index 0 $list] {
    setl {junk seq command} $thing
    struct mode_info c [mode_info $command -mode $mode_name]

    # if no explicit description for binding, take desc from first command
    if {${c.desc} == {}} {
	set arg0 [lindex $command 0] 
	set c.desc [doc_at $arg0 cmd_desc] 
    }

    # if still no description, use script as description.
    if {${c.desc} == {}} {
	set c.desc $command
    }

    set entry [format "%14s - %s\n" [seq_pp $seq] ${c.desc}]
    $w.bindings.list insert end $entry
  }
}

proc mode_lookup_hot_key {cmd} -desc {
    returns hotkey associated with cmd string, if any.
} -doc {
Searches common and main mode bindings.
For a match cmd and the binding script must be identical.
} {
    error "code not used, no longer working"
    global MODE|common MODE|main

    # search common bindings
    foreach seq [array names MODE|common] {
	setl {script cmdwrap desc doc} [set MODE|common($seq)]
	if { $cmd == $script } {
	    return $seq
	}
    }

    # search main mode bindings
    foreach seq [array names MODE|main] {
	setl {script cmdwrap desc doc} [set MODE|main($seq)]
	if { $cmd == $script } {
	    return $seq
	}
    }

    # no match 
    return {}
}


proc mode_events {mode {event ""}} -desc {
  Return mode_event struct for specified event, or if none, all events.
} -doc {
  Each event in the list is a structure of type mode_event
} {
  global MODE_EVENTS|$mode

  if { $event == "" } {
    set events ""

    foreach entry [array names MODE_EVENTS|$mode] {
      lappend events [set MODE_EVENTS|${mode}($entry)]
    }
    return $events
  } else {
    return [use_first MODE_EVENTS|${mode}($event)]
  }
}
