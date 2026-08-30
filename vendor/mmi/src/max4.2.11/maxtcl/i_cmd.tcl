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

set RCSVERSION(i_cmd.tcl) { $Revision: 1.21 $ }

# Procedures for wrapping max "Interactive" commands, 
# for proper handling of undo, history, messages etc.
#
# Interactive commands are commands invoked directly by user (e.g. via menus,
# hotkeys or ":" command.  

# initialize global variables for this file
set i_cmd(num) 0      ;# current command number
set i_cmd(last) ""    ;# previous command for redo
set i_cmd(tmp_msg) 0  ;# command number that posted a temp message

# do normal between command processing for terminal input?
init_global i_cmd(wrap_terminal) \
    -type binary \
    -default 1 -desc {Binary value (0 or 1) that controls whether\
    commands input from the terminal window are wrapped by\
    i_cmd_eval.  This is turned off only for debugging.}

proc i_cmd_between {{add_undo_delim 1}} -desc {
collection of actions to take between interactive commands
} {
    global i_cmd

    # count - this is used in message.tcl to pretty print
    # a separator between messages for each command, and by
    # commands that need to make sure nothing happened since
    # the last time they were invoked.
    incr i_cmd(num)

    if { $add_undo_delim } {
      # undo in increments of top level commands
      undo_delim
    }

    i_cmd_between_undos
}

proc i_cmd_update {} -desc {
  update all screen things
} -doc {
  This can take up to 0.1 second, so we defer it until we are not busy.
} {
  global i_cmd

  if { [mode_current] == "main" } {
    # update window title
    win_title_update

    # update box msg
    box_msg_update

    # update list boxes
    list_box_update

    # update see_cif menu
    menu_see_cif_update
  } else {
    # Not safe to do it right now.
    # But its OK to just do nothing.
    # Since we are not in main mode, the mode_pop that returns
    # us to main mode will reschedule this proc then.
  }
}


proc i_cmd_between_undos {} -desc {
  actions to take between interactive commands and after undos
} {
    global i_cmd 

    # update mode message
    if { $i_cmd(num) > $i_cmd(tmp_msg)+1 && [dbt_cursor_in_frame] } {
      _mode_msg_restore
    }

    catch { after cancel $i_cmd(after_id) }

    set i_cmd(after_id) [after idle i_cmd_update]

    vcs_post_command_hook
    fplan_post_command_hook
}


proc i_cmd_error {code error error_info} {
  global errorInfo

    if { $error == {} } {
	set error "Error evaluating unknown command\n"
    }

    puts $error

    # Do this after above puts, because mode_abort may print
    # additional messages.
    mode_abort
    cursor_busy 0

    set list [split $error \n]
    if {[llength $list] > 10} {
      set error [join "[lrange $list 0 9]\n..." \n]
    }

    # The errorInfo is for the stack-trace button in bgerror popup.
    set errorInfo $error_info
    bgerror $error
    #return -code error -errorinfo $error_info $error
}


proc i_cmd_eval_nowrap {args} -desc {
  Eval a command that is "not wrapped".
} -doc {
  This is called to run any mode commands that are not evaled by
  i_cmd_eval or i_cmd_eval_common.  The evaled command is assumed
  to provide its own undo processing and display refresh.

  This exists solely to catch and report errors, and to reset to main mode
  if an error occurs.
} {
  global errorInfo
  set code [catch "uplevel #0 $args" result]
  set ei $errorInfo

  # report any warnings in dialog box
  msg_flush

  # report any errors in dialog box
  if { $code != 0 } {
    i_cmd_error $code $result $ei
  }
}


proc i_cmd_eval_common {args} -desc {
  Eval a common-mode command.
} -doc {
  This is called to run "common" mode commands, such as view or grid_toggle.
  These commands can be called from any other mode,
  so they must not fiddle with the undo, etc.
} {
  global errorInfo

  cursor_busy 1
  # See comments in i_cmd_eval.
  set code [catch "uplevel #0 $args" result]
  set ei $errorInfo
  cursor_busy 0

  # report any warnings in dialog box
  msg_flush

  # report any errors in dialog box
  if { $code != 0 } {
      set errors $result
      if { $errors == {} } {
	  set errors "Error evaluating command \"$args\"\n"
      }

      puts $errors
      mode_abort
      cursor_busy 0

      set list [split $errors \n]
      if {[llength $list] > 10} {
	set errors [join "[lrange $list 0 9]\n..." \n]
      }

      set errorInfo $ei
      bgerror $errors 
  }

  i_cmd_between 0
}

proc i_cmd_eval {args} -desc {
  Eval an Interactive command
} -doc {
  usage: i_cmd_eval arg1 arg2 ...
  As with eval, args are concated togther to form a script .

  Interactive commands are "top level" commands invoked directly by user,
  for example, via hot-keys, menu selections, or the ":" command.

  All Interactive commands should be passed through here.

  Handles command numbering, undo command delimeters, history, etc.

  Note:  i_cmd_between should be called at end of max_sys prior
  to first interactive command.
} {
    global errorInfo max_win

    # set busy cursor
    cursor_busy 1

    # eval command catching errors and warnings
    # 5/30/01: Do NOT use msg_catch here.  All interactive commands now
    # post warnings using msg -warn followed by msg_flush.
    # Msg_flush will not post the message inside a msg_catch.
    # Use msg_catch ONLY when you need to divert max warnings.
    # Note: it is ok to put the command in quotes, because args is already a list.
    set code [catch "uplevel #0 $args" result]
    set ei $errorInfo

    # clear busy cursor
    cursor_busy 0

    # report any warnings in dialog box
    msg_flush

    # report any errors in dialog box
    if { $code != 0 } {
      i_cmd_error $code $result $ei
    }


    # do between command processing
    global MODE
    if { [mode_current] != "main" } {
      # We have entered a mode.  The undo_delim should be placed
      # after the mode ends.
      set MODE(defer_undo) 1
      i_cmd_between_undos  ;# pat added 3-22-00
    } else {
      i_cmd_between
    }

    return $result
}

proc i_cmd_eval_set_last {cmd} -desc {
  Do interactive command, setting i_cmd(last) (for "." hotkey)
} -doc {
  Command saved in i_cmd(last).

  See "i_cmd_eval"
} {
    global i_cmd

    set result [i_cmd_eval $cmd]
    if {$cmd != "." } { set i_cmd(last) $cmd }
    
    return $result
}

proc i_cmd_eval_last {} -desc {
  redo last interactive command done with "i_cmd_eval_set_last"
} -doc {
  Implements "." hot-key.
} {
    global i_cmd

    i_cmd_eval $i_cmd(last)
}

proc i_cmd_eval_box {winMain} -desc {
  pop up window to take an interactive max command and eval it
} {
    global PROMPT

    # Init command.  It does not necessarily start with a colon.
    set i_cmd(command) ""

    # create prop menu
    set prop_list [list \
	[list "$PROMPT" i_cmd(command) -entry -width 30] \
	]
    set title "Command"
    set message "Enter Command:"
    set ret [prop_menu2 -message $message -title $title $prop_list]

    if {$ret == 0} {
      # user hit cancel
      return
    }

    # add command to history list
    history add $i_cmd(command)

    # eval it
    set cmd_name [lindex $i_cmd(command) 0]
    if {$cmd_name == [info commands $cmd_name]} {
	# EXACT COMMAND NAME
	# command found, execute (at toplevel)
	i_cmd_eval_set_last $i_cmd(command)
    } elseif { [lindex :$i_cmd(command) 0] == [info commands :$cmd_name] } {
	# Command name was entered without the colon.
	# This happens because you type the colon to enter
	# i_cmd_eval_box, so you dont think you need to enter another one.
	i_cmd_eval_set_last :$i_cmd(command)
    } else {
	# NOT EXACT COMMAND NAME
	# try unknown (maybe uniq abrev, or special history abrev)
	i_cmd_eval_set_last [concat unknown $i_cmd(command)]
    }

    return
}

proc i_cmd_eval_terminal args -desc {
process command from controling terminal
} {
    global i_cmd

    # filter null commands
    if {$args == {}} return

    # no wrap?
    if { ! $i_cmd(wrap_terminal) } {
	return [uplevel #0 $args]
    }

    # extract cmd_name
    set cmd_name [car $args]

    # add command to history list
    history add $args 

    # eval it
    set c [string compare $cmd_name [info commands $cmd_name]]
    # 6/6: i_cmd_eval will call unknown automatically.
    # The old code did not handle comments properly.
    if {1 || $c == 0} {
	# EXACT COMMAND NAME
	# command found, execute (at toplevel)
	i_cmd_eval_set_last $args
    } else {
	# NOT EXACT COMMAND NAME
	# try unknown (maybe uniq abrev, or special history abrev)
	i_cmd_eval_set_last [concat unknown $args]
    }  
}

proc i_cmd_bind {widget event script} -desc {
create max (interactive) command binding
} -doc {
Wraps command binding in call to i_cmd_eval, so undo, history, and
assorted between-command processing is handled correctly.

Note for regular layout bindings you probably want "mode_bind" instead.
} {
    catch [list bind $widget $event [list i_cmd_eval $script]]
}





