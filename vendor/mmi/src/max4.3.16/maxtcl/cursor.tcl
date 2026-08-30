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

set RCSVERSION(cursor.tcl) { $Revision: 1.19 $ }

# code to set main window cursors to reflect current state, e.g.
# busy.

set CURSOR(busy_cursor) watch
set CURSOR(ready_cursor) top_left_arrow
#set CURSOR(ready_cursor) tcross
set CURSOR(wait_cursor) question_arrow
set CURSOR(redisplay_cursor) spraycan

# default sub-mode cursor:
set CURSOR(mode_cursor) hand2
# special sub-mode cursors:
set CURSOR(move_cursor) fleur
set CURSOR(movex_cursor) sb_h_double_arrow
set CURSOR(movey_cursor) sb_v_double_arrow
set CURSOR(llcorner_cursor) ll_angle
set CURSOR(lrcorner_cursor) lr_angle
set CURSOR(ulcorner_cursor) ul_angle
set CURSOR(urcorner_cursor) ur_angle
set CURSOR(wire_draw_cursor) pencil
set CURSOR(deselect_cursor) X_cursor
set CURSOR(select_cursor) top_left_arrow

# CURSOR(busy,main) is a boolean flag indicating that max main window
# is busy.  There is also a busy cursor flag for each toplevel
# window that is the subject of a cursor_wait call, CURSOR(busy,$win)
set CURSOR(busy,main) 1
set CURSOR(mode) 0
set CURSOR(wait) {}
set CURSOR(redisplay) 0
set CURSOR(override) {}
set CURSOR(redisplay_disable) 0

# Current cursor.
set CURSOR(cursor) {}
# Current main windows.
set CURSOR(mains) {}
# Stack of procs that called cursor_wait.
set CURSOR(stack) {}

proc cursor_update {{options ""}} -desc {
Sets cursors in toplevel windows to reflect current mode.
} -doc {
  if option is -no_wait, don't wait  (used during redisplay)
  Note: this routine is called alot!  Several times during
  each command to implement cursor_busy.
} {
    global CURSOR

    set mains [winfo children .]

    # figure out appropriate new cursor
    set new $CURSOR(ready_cursor)
    if { $CURSOR(mode) != "0" } { set new $CURSOR(mode) }
    if { $CURSOR(busy,main) != 0 } { set new $CURSOR(busy_cursor) }
    if { $CURSOR(redisplay) != 0 && ! $CURSOR(redisplay_disable) } {
	set new $CURSOR(redisplay_cursor)
    }
    if { $CURSOR(override) != "" } { set new $CURSOR(override) }
    if { $CURSOR(wait) != {} } { set new $CURSOR(wait_cursor) }

    # optimize: if same cursor and same mains as last time, and there is no
    # CURSOR(wait) window that might have died without us looking, just return
    if { $new == $CURSOR(cursor) && $mains == $CURSOR(mains) && \
	$CURSOR(wait) == "" } {return}

    # set new cursor for each toplevel window
    foreach w  $mains {
      $w configure -cursor $new
    }

    # 7/13: COMMENT OBSOLETE, REMOVE WHEN TESTED:
    # If waiting on a window, use ready cursor in that window! 
    # The busy flag is used outside of cursor_wait, ie, the sequence is:
    #    cursor_busy 1
    #    prop_menu...
    #        cursor_wait blah 1
    #        cursor_wait blah 0
    #    cursor_busy 0
    # So the CURSOR(busy,$win) flag is ignored when CURSOR(wait) is set,
    # but busy cursor will pop back on when CURSOR(wait) is cleared.
    # As a corollary, you shouldnt call cursor_busy inside a cursor_wait.


    if { $CURSOR(wait) != {} } {
      # Max is waiting on a toplevel window (like prop_menu),
      # which signaled that fact by calling cursor_wait 1.
      if { ! [winfo exists $CURSOR(wait)] } {
	# The window died without calling cursor_wait 0.
	# We can fix that!  The cursor_wait proc will notice
	# that the window has died, pop the CURSOR(stack),
	# and set CURSOR(wait) to next win down on stack.
	# Then, call ourselves recursively to attempt
	# cursor set up for that window.
	cursor_wait $CURSOR(wait) 0
	# Try again...
	return [cursor_update $options]
      }
      # If the wait window is busy, use the busy cursor.
      if {[use_first CURSOR(busy,$CURSOR(wait)) '0]} {
	set topcursor $CURSOR(busy_cursor)
      } else {
	set topcursor $CURSOR(ready_cursor)
      }
      [winfo toplevel $CURSOR(wait)] configure -cursor $topcursor
    }

    # actually update cursors NOW
    if {$options == {}} {update idletasks}

    # remember cursor!
    set CURSOR(cursor) $new
    set CURSOR(mains) $mains
}

proc cursor_busy {bool} -desc {
Notify cursor module that max is busy (bool=1) or not (bool=0) 
} {
  global CURSOR
  if { $CURSOR(wait) == "" } {
    set win main
  } else {
    set win $CURSOR(wait)
  }
  set old $CURSOR(busy,$win)
  set CURSOR(busy,$win) $bool
  cursor_update
  return $old
}

# Sue-compatible procs that set busy/not-busy cursors.
#proc busy {} { cursor_busy 1 }
#proc ready {} { cursor_busy 0 }

proc cursor_mode {submode {redisplay_disable 0}} -desc {
  Notify cursor module that max is/is not in a submode.
} -doc {
  submode argument can be:
  0: not in a sub-mode;
  1: in a sub-mode, use default cursor;
  special: in a sub-mode, use special cursor, where special
  can be: move, movex, movey, llcorner, lrcorner,
  ulcorner, urcorner.
  If redisplay_disable is 1, disable redisplay cursor.
  This is a hack to prevent the cursor from jumping rapidly
  between redisplay and mode cursors in modes that know
  that the redisplay will not be a problem.
} {
    global CURSOR
    if { $submode == "0" } {
	set CURSOR(mode) 0
    } elseif { $submode == "1" } {
	set CURSOR(mode) $CURSOR(mode_cursor)
    } else {
	set CURSOR(mode) $CURSOR(${submode}_cursor)
    }
    set CURSOR(redisplay_disable) $redisplay_disable
    cursor_update
}

proc cursor_override {cursor} {
    global CURSOR
    if { $cursor != "" } {
	set CURSOR(override) $CURSOR(${cursor}_cursor)
    } else {
	set CURSOR(override) ""
    }
    cursor_update -no_wait
}

proc cursor_wait {window bool {msg {}}} -desc {
    Notify cursor that max is waiting for a user response in window 
} -doc {
    Called by toplevel windows to change cursors and user mode message
    while waiting for a dialog menu or box to complete.
    Window must be specified, and is the window corresponding
    to the dialog box;
    Bool is 1 to wait on this window, or 0 if done waiting on the window,
    in which case the previous user message is restored.
    msg = optional message posted to mode message area as '? msg'
} {
    global CURSOR OPTIONS max_periodic
    if { $window == {} } {
	puts "ERROR: old syntax used in call to cursor_wait"
	return
    }
    if { $bool != 0 } {
	# Wait on the specified window
	set CURSOR(wait) $window

	# The max_periodic update interferes with double-button-1.
	# Evidently it steals so many cycles that the second click
	# may not happen in time to register to tcl.
	set max_periodic(enabled) 0

	# Init the busy cursor to not busy.
	# This is necessary in case the window previously died,
	# the busy cursor could still be set from last time.
	set CURSOR(busy,$window) 0
	push CURSOR(stack) [list $window $msg]
	mode_msg "?: $msg" global
	if { [use_first OPTIONS(auto_raise_window)] == 1 && \
	    $window != "." && [winfo exists $window] } {
	    # This allows the user to click anywhere in the window
	    # whenever they see a question mark cursor to raise the
	    # current dialog window to visibility.
	    # The dialog boxes usually do a grab, so all mouse clicks
	    # go only to that window.
	    bind $window <Any-ButtonPress> "cursor_raise_that_window $window"

	    # This bind fixes the cursor instantly if the window
	    # gets destroyed without having called cursor_wait $window 0.
	    # This can happen if the user uses the X "Quit" to exit
	    # a prop_menu, or if the code executes an "error" function.
	    # Cursor_update notices that the window is destroyed.
	    # Without this, the next cursor_update usually doesnt
	    # happen until the next i_cmd, eg, user has to click the mouse.
	    # Unfortunately, it generates a race condition to see
	    # who can call cursor_wait 0 first, so fix it with
	    # this kludgy after 1000.
	    # NO LONGER HERE: Each window that uses tkwait now sets its
	    # own Destroy binding.
	    #bind $window <Destroy> "after 1000 cursor_update"
	}
    } else {
	set max_periodic(enabled) 1
	# Done waiting on this window:
	# Pop stack until we find an extant window, and reset
	# cursor, mode msg for that window.
	# This allows intermediate windows to be destroyed, and code
	# will stillwork.
	while {1} {
	  pop CURSOR(stack)
	  setl {old_window old_msg} [lindex $CURSOR(stack) 0]
	  if { $old_window != ""} {
	    if {! [winfo exists $old_window] } {
	      # Window is gone.  This happens if the window is
	      # destroyed without calling cursor_wait 0
	      # Pop the stack down to the next window.
	      continue
	    }
	    # Previous window on stack still around, so wait on it.
	    set CURSOR(wait) $old_window
	    mode_msg $old_msg global
	  } else {
	    # Stack is empty.  And now we return to our main programming...
	    # Clear the global mode message.
	    mode_msg "" global
	    set CURSOR(wait) ""
	  }
	  break
	}
    }
    cursor_update
}

proc cursor_raise_that_window {win} {

    # If the mouse click was in the window we are interested in,
    # then curwin will be a subwindow of win.  In this case we do NOT
    # want to raise win, because it would obscure curwin, which
    # might be a popup, for example.  Otherwise, raise it.
    # I tried using %W in the bind, but it returns $win whenever
    # the mouse is outside the window, which is pretty useless.

    global CURSOR
    if { $CURSOR(wait) != $win } {
      # The window has not been destroyed yet, but cursor_wait 0
      # has been called to release the wait from this window.
      return
    }
    if {[winfo exists $win]} {
      # Originally, this crashed on Lee's machine with an X error.
      # Although it was cured by putting in an update?
      # When the crash occurred, it was still using a bind on "all",
      # and it wasnt checking to make sure the window still existed.
      # Hopefully one of these two will fix the problem.
      set curwin [winfo containing [winfo pointerx .] [winfo pointery .]]
      if {[string first $win $curwin] != 0} {
	  bell
	  catch { raise $win }
	  # If the window comes up under the mouse, X can lose
	  # the focus.  This fixes it:
	  catch { focus -force [focus -lastfor $win] }
      }
    }
}


proc cursor_redisplay {bool} -desc {
Notify cursor module that max is busy redisplaying (bool=1) or not (bool=0) 
} {
    global CURSOR
    set CURSOR(redisplay) $bool
    cursor_update -no_wait
}
