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

set RCSVERSION(feedback.tcl) { $Revision: 1.10 $ }

set MAX_STRUCT(feedback) "plus name count"

# Create namespaces
namespace eval _feedback_max {}
namespace eval _feedback_ext {}

# _FEEDBACK_MAX is for max error feedback.
# For external drc feedback, vars are:
# _FEEDBACK_LIST is an array whose indicies are
# the error messages and whose values are the lists of each kind of error.
# _FEEDBACK_LIST_AREA is the subset that is currently displayed.
# _FEEDBACK_INFO is an array containing data about the errors in _FEEDBACK_LIST.


proc _feedback_zoom {} -desc {
  Like :findbox zoom, but not so close in.
} {
  set MIN_SIZE 6  ;# Minimum size of view.
  set save_box [layt_box exact]
  struct rect b $save_box
  set xsize [expr ${b.x2}-${b.x1}]
  set ysize [expr ${b.y2}-${b.y1}]
  # Make sure view is at least MIN_SIZE in each direction.
  if { $xsize < $MIN_SIZE/2.0 } {
    set xsize [expr ($MIN_SIZE - $xsize)/2.0]
  }
  if { $ysize < $MIN_SIZE/2.0 } {
    set ysize [expr ($MIN_SIZE - $ysize)/2.0]
  }
  layt_box exact [expr ${b.x1} - $xsize/2.0] [expr ${b.y1} - $ysize/2.0] \
      [expr ${b.x2} + $xsize/2.0] [expr ${b.y2} + $ysize/2.0]
  :findbox zoom
  eval layt_box exact $save_box
}

proc _feedback_goto_error {x1 y1 x2 y2} {
  global _FEEDBACK
  layt_box mask $x1 $y1 $x2 $y2
  switch $_FEEDBACK(view_method) {
    "zoom" {
      _feedback_zoom
    }
    "center" {
      :findbox
    }
  }
}

proc _feedback_win_post {{msg ""}} -desc {
  Post msg in DRC window.  If none, just clear it.
} -doc {
  Return name of listbox window as a convenience.
} {
  global _FEEDBACK

  if { $msg != "" } {
    set info [string trim $msg \n]
    regsub -all "\n" $info "  " info_str
    mode_inform_msg $info_str
  }

  set plist $_FEEDBACK(win).items.list
  if {! [winfo exists $plist]} { return $plist }

  # clear old list, if any.
  if {[$plist size] > 0} {
      $plist delete 0 end
  }
  $plist selection clear 0 end

  if { $msg != "" } {
    foreach str [split $info \n] {
      $plist insert end $str
    }
  }

  return $plist
}

proc _feedback_max::reload {} -desc {
  Load errors from max.
} {
  global _FEEDBACK _FEEDBACK_MAX

  msg "Loading max drc errors into feedback window\n"

  if { $_FEEDBACK(area_method) == "cell" } {
    set area ""
  } else {
    set area "-area $_FEEDBACK(area)"
  }

  if { $_FEEDBACK(any_cell) } {
    set _FEEDBACK_MAX [eval db_search_l paint -any_cell $area -limit $_FEEDBACK(max_limit) error]
  } else {
    set _FEEDBACK_MAX [eval db_search_l paint $area -limit $_FEEDBACK(max_limit) error]
  }
}

proc _feedback_max::read_error { n } {
  global _FEEDBACK _FEEDBACK_MAX 
  set error_info [lindex $_FEEDBACK_MAX $n]
  if { $error_info == "" } {
    return ""
  }

  struct max_paint p $error_info
  layt_box exact ${p.x1} ${p.y1} ${p.x2} ${p.y2}
  msg_catch { :drc why } r info w
  if { [string match {*No errors*} $info] } {
    # The error has disappeared since we nabbed the error paint.
    return ""
  }
  return $info
}

proc _feedback_max::win_invoke {lx ly action} {
  # No op
}


proc _feedback_max::show {} -desc {
  Show feedback for max drc number at _FEEDBACK(max_index).
} {
  global _FEEDBACK _FEEDBACK_MAX

  set info [lindex $_FEEDBACK_MAX $_FEEDBACK(max_index)]
  if { $info == "" } {
    # What went wrong?
    return
  }
  struct max_paint r $info

  _feedback_goto_error ${r.x1} ${r.y1} ${r.x2} ${r.y2}
}


proc _feedback_max_no_errors_msg {} {
  global drc_busy drc_on
  if { $drc_busy } {
    # Its still looking
    _feedback_win_post "No Max DRC errors found yet.\nStill busy..."
  } elseif {$drc_on} {
    _feedback_win_post "No Max DRC errors found."
  } else {
    _feedback_win_post "Max DRC is off."
  }
}


proc _feedback_max::win_update {{info ""}} -desc {
  Update listbox for max error specified by info.
} -doc {
  Special cases:
  If info is "", use the error at _FEEDBACK(max_index).
} {
  global _FEEDBACK _FEEDBACK_MAX

  # Clear message area, in case we return before doing anything.
  set plist [_feedback_win_post ""]

  # If we havent loaded any errors yet, it means we just
  # posted the window.  Dont know what the user wants to do yet.
  # Leave it blank.
  if {![info exists _FEEDBACK_MAX]} { return }

  set error_cnt 0
  if { [winfo exists $_FEEDBACK(win)] } {
    set error_cnt [llength $_FEEDBACK_MAX]
    $_FEEDBACK(win).top_label config -text \
	  "Max DRC Feedback - Total entries:\
	  [expr {$error_cnt >= $_FEEDBACK(max_limit) ? "> " : ""}]$error_cnt"
  }

  if { $_FEEDBACK(max_index) < 0 } {
    # User has not done a "next error" or "prev error" yet.
    if {$error_cnt == 0} {
      _feedback_max_no_errors_msg
    }
    return
  }

  # Users get to count the errors starting at 1.
  set drc_number "DRC #[expr $_FEEDBACK(max_index)+1]"

  if { $info == "" } {
    set info [_feedback_max::read_error $_FEEDBACK(max_index)]
  }

  if { $info == "" } {
    # Error not found.

    if { [llength $_FEEDBACK_MAX] == 0} {
      # No errors at all, yet, but drc might still be working.

      _feedback_max_no_errors_msg
    } else {
      # This error does not exist.  User may have asked for
      # error #n where n is beyond end of list.
      _feedback_win_post "$drc_number:\nNo such DRC error."
    }
    return 0

  } else {
    # Display this error.
    _feedback_win_post "$drc_number:\n$info"

    return 1
  }
}

proc _feedback_max::next_error_int {option} -desc {
  Return next/prev max drc error, or "".  Update _FEEDBACK(max_index)
} {
  global _FEEDBACK _FEEDBACK_MAX
  upvar wrap_flag wrap_flag
  if {[llength $_FEEDBACK_MAX] == 0} {
    _feedback_max::reload
  }
  switch $option {
    "next" {
      while {[llength $_FEEDBACK_MAX] > 0} {
	incr _FEEDBACK(max_index)
	if { $_FEEDBACK(max_index) >= [llength $_FEEDBACK_MAX] } {
	  set _FEEDBACK(max_index) 0
	  if { $wrap_flag == 1 } {
	    return ""
	  } else {
	    _feedback_max::reload
	    set wrap_flag 1
	  }
	}
	set info [_feedback_max::read_error $_FEEDBACK(max_index)]
	if { $info != "" } { return $info }
	# This error has disappeared.  Take it out of the feedback list.
	set _FEEDBACK_MAX [lreplace $_FEEDBACK_MAX $_FEEDBACK(max_index) $_FEEDBACK(max_index)]
	incr _FEEDBACK(max_index) -1
      }
    }
    "prev" {
      while {[llength $_FEEDBACK_MAX] > 0} {
	incr _FEEDBACK(max_index) -1
	if {$_FEEDBACK(max_index) < 0} {
	  set _FEEDBACK(max_index) [expr [llength $_FEEDBACK_MAX] - 1]
	  if { $wrap_flag == 1 } {
	    return ""
	  } else {
	    _feedback_max::reload
	    set wrap_flag 1
	  }
	}
	set info [_feedback_max::read_error $_FEEDBACK(max_index)]
	if { $info != "" } { return $info }
	# This error has disappeared.  Take it out of the feedback list.
	set _FEEDBACK_MAX [lreplace $_FEEDBACK_MAX $_FEEDBACK(max_index) $_FEEDBACK(max_index)]
      }
    }
    default {
      error "invalid option"
    }
  }
  return ""
}

proc _feedback_max::next_error {{option "next"}} -desc {
  Find next error from max built-in drc.
} -doc {
  The <option> can be:
  "kind" - find next kind of error (forward only)
  "next" - next error forward
  "prev" - next error backward
  number - goto specified error number (1 based), or next available.

  When we wrap around the end of the errors, we will reload them,
  to see if anything has changed.

  Note that the error feedback may be out of sync with the design,
  so the error may not actually exist when we go to it.
  In this case, remove it from the error array, and try again.
} {
  global _FEEDBACK _FEEDBACK_MAX

  if { ! [info exists _FEEDBACK_MAX] } {
    _feedback_max::reload
    set _FEEDBACK(max_index) -1
  }

  set llen [llength $_FEEDBACK_MAX]
  if { $llen == 0 } {
    # No errors yet.
    set _FEEDBACK(max_index) -1
    _feedback_max::win_update
  }

  # wrap_flag is a call by ref param to _feedback_max::next_error_int
  set wrap_flag 0 

  switch $option {
    "kind" {
      set orig $_FEEDBACK(max_index)
      set orig_box [layt_box exact]
      set last_info [_feedback_max::read_error $_FEEDBACK(max_index)]
      while {1} {
	set info [_feedback_max::next_error_int next]
	if { $info == "" } {
	  set _FEEDBACK(max_index) $orig
	  # No errors, or none found of a different kind. Just clear it.
	  global drc_busy
	  if { $drc_busy } {
	    _feedback_win_post "No other kind of error found.\nStill busy..."
	  } else {
	    _feedback_win_post "No other kind of error found."
	  }
	  eval layt_box exact $orig_box
	  return
	}
	if { $info != $last_info } {
	  _feedback_max::win_update $info
	  _feedback_max::show
	  return
	}
      }
    }
    "next" {
      set info [_feedback_max::next_error_int next]
      if { $info != "" } {
	_feedback_max::win_update $info
	_feedback_max::show
	return
      }
      # No error found.
    }
    "prev" {
      set info [_feedback_max::next_error_int prev]
      if { $info != "" } {
	_feedback_max::win_update $info
	_feedback_max::show
	return
      }
      # No error found.
    }
    default {
      # It better be a number from 1 to llength.
      set index [expr $option - 1]
      if {$index < 0 || $index >= [llength $_FEEDBACK_MAX]} {
	max_error "feedback error: invalid DRC number: $option"
	return
      }
      set info [_feedback_max::read_error $index]
      if { $info == "" } {
	# The DRC error disappeared when we werent looking.
	# Try one more time.
	_feedback_max::reload
	set info [_feedback_max::read_error $index]
	if { $info == "" } {
	  max_error "feedback error: invalid DRC number: $option"
	  return
	}
      }
      set _FEEDBACK(max_index) $index
      _feedback_max::win_update $info
      _feedback_max::show
      return
    }
  }

  _feedback_max::win_update ""
}

proc find_next_error {{type "next"}} -desc {
  Show next error.  Optional <type> is as for _feedback_max::next_error
} {
  global _FEEDBACK

  _feedback_init

  if { $_FEEDBACK(type) == "_feedback_max" } {
    _feedback_max::next_error $type
  } else {
    _feedback_ext::next_error $type
  }
}


proc _feedback_ext::list_update {} -desc {
  Return current list of errors.
} -doc {
  Input: _FEEDBACK_LIST
  Output: _FEEDBACK_LIST_AREA _FEEDBACK_INFO
} {
  global _FEEDBACK _FEEDBACK_LIST _FEEDBACK_LIST_AREA _FEEDBACK_INFO

  if {[info exists _FEEDBACK_LIST_AREA]} { return }

  catch { unset _FEEDBACK_LIST_AREA }
  # Update _FEEDBACK_LIST_AREA from current feedback and area options.
  foreach kind [array names _FEEDBACK_LIST] {
    # Init the _FEEDBACK_INFO array, too, in case any new kinds
    # of errors have appeared since the last update.
    set _FEEDBACK_INFO($kind,expand) \
      [use_first _FEEDBACK_INFO($kind,expand) '0]
    set errors $_FEEDBACK_LIST($kind)

    if { $_FEEDBACK(area_method) != "cell" } {
      # Limit error feedback to specified area.
      set new_errors ""
      setl {ax1 ay1 ax2 ay2} $_FEEDBACK(area)
      foreach error_info $errors {
	switch [lindex $error_info 0] {
	  "edge" -
	  "rect" {
	    setl {type x1 y1 x2 y2} $error_info
	    # Error rectangle can be enclosed or touching area.
	    if { $x2 >= $ax1 && $x1 <= $ax2 && $y2 >= $ay1 && $y1 <= $ay2 } {
	      lappend new_errors $error_info
	    }
	  }
	  "area" {
	    set points [lrange $error_info 1 end]
	    while {[llength $points] > 0} {
	      set x [lindex $points 0]
	      set y [lindex $points 1]
	      set points [lrange $points 2 end]
	      # Error rectangle can be enclosed or touching area.
	      if { $x >= $ax1 && $x <= $ax2 && $y >= $ay1 && $y <= $ay2 } {
		lappend new_errors $error_info
		break
	      }
	    }
	  }
	}
      }
      set errors $new_errors
    }
    set _FEEDBACK_LIST_AREA($kind) $errors
  }

  # Return value is _FEEDBACK_LIST_AREA, but we cant return arrays in tcl!
}


proc _feedback_ext::index2kind {index} -doc {
  Return a list of: error kind, sub_index in that error kind, total errors.
  corresponding to error index <ind>.
} {
  global _FEEDBACK_LIST_AREA
  _feedback_ext::list_update

  set error_kinds [lsort [array names _FEEDBACK_LIST_AREA]]

  set sub_index -1  ;# Index in this kind of error.
  set accum 0
  foreach kind $error_kinds {
    set llen [llength $_FEEDBACK_LIST_AREA($kind)]
    if { $index < $accum + $llen } {
      return [list $kind [expr $index - $accum]]
    }
    incr accum [llength $_FEEDBACK_LIST_AREA($kind)]
  }
  return [list "" -1]
}

proc _feedback_ext::list_total {} -desc {
  Total number of external feedback errors.
} {
  global _FEEDBACK_LIST_AREA
  set accum 0
  foreach error_kind [array names _FEEDBACK_LIST_AREA] {
    incr accum [llength $_FEEDBACK_LIST_AREA($error_kind)]
  }
  return $accum
}

proc _feedback_ext::next_error {{option "next"}} {
  global _FEEDBACK _FEEDBACK_LIST_AREA _FEEDBACK_INFO

  _feedback_ext::list_update

  if { ! [info exists _FEEDBACK_LIST_AREA] } {
    msg "No External DRC errors in feedback list\n"
    return
  }

  # Set index to next error to display.
  switch $option {
    "next" {
      # Next error.
      set index [expr $_FEEDBACK(list_index) + 1]
    }
    "prev" {
      set index [expr $_FEEDBACK(list_index) - 1]
      if { $index < 0 } {
	set index [expr [_feedback_ext::list_total] - 1]
      }
    }
    "kind" {
      # Find next kind of error.
      if { $_FEEDBACK(list_index) == -1 } {
	# Just starting; go to first error in list.
	set index 0
      } else {
	# Get kind of previous error.
	set index $_FEEDBACK(list_index)
	setl {kind sub_index} [_feedback_ext::index2kind $index]
	set llen [llength $_FEEDBACK_LIST_AREA($kind)]
	# Skip the rest of the errors of this kind.
	set index [expr $index - $sub_index + $llen]
      }
    }
    default {
      # It better be a number from 1 to llength.
      set index [expr $option - 1]
      if {$index < 0 || $index >= [_feedback_ext::list_total]} {
	max_error "feedback error: invalid DRC number: $option"
	return
      }
    }
  }

  setl {kind sub_index} [_feedback_ext::index2kind $index]

  if { $sub_index == -1 && ($option == "next" || $option == "kind")} {
    # Index was beyond end of error list.  Try wrapping around.
    set index 0
    setl {kind sub_index} [_feedback_ext::index2kind $index]
  }

  if { $sub_index == -1 } {
    # All error kinds are empty.
    set _FEEDBACK(list_index) -1
    msg "No External DRC errors in feedback list\n"
    return
  }

  # We have set: kind, index, and sub_index.

  if { ! $_FEEDBACK_INFO($kind,expand) } {
    # Unexpand other error kinds.
    foreach ind [array names _FEEDBACK_INFO] {
      set _FEEDBACK_INFO($ind) 0
    }
    # Expand this kind of error.
    set _FEEDBACK_INFO($kind,expand) 1
    _feedback_ext::win_update
  }

  set _FEEDBACK(list_index) $index
  _feedback_ext::show
  _feedback_ext::win_select
}

proc _feedback_ext::reload {} {
  global _FEEDBACK_LIST_AREA
  catch { unset _FEEDBACK_LIST_AREA }
  _feedback_ext::list_update
}

proc _feedback_ext::win_update {} {
  global _FEEDBACK _FEEDBACK_LIST _FEEDBACK_LIST_AREA _FEEDBACK_INFO

  _feedback_ext::list_update

  set win $_FEEDBACK(win)

  set _FEEDBACK(listbox_map) ""

  if { ! [winfo exists $win]} {
    # Window not up, dont bother about filling in the list box.
    return
  }

  set save_box [layt_box exact]

  # clear old list
  set plist [_feedback_win_post ""]

  set error_cnt 0

  foreach kind [lsort [array names _FEEDBACK_LIST_AREA]] {
    set errors $_FEEDBACK_LIST_AREA($kind)
    set llen [llength $errors]
    if { $llen == 0 } { continue }

    if { [use_first _FEEDBACK_INFO($kind,expand)] == 1 } {
      # This kind of error is expanded: include all individual error lines.
      $plist insert end "- $kind ($llen)"
      lappend _FEEDBACK(listbox_map) -1
      for {set i 0} {$i < $llen} {incr i} {
	set error_info [lindex $errors $i]
	$plist insert end "  $error_info"
	lappend _FEEDBACK(listbox_map) $error_cnt
	incr error_cnt
      }
    } else {
      # This kind of error is unexpanded: show only error title line.
      $plist insert end "+ $kind ($llen)"
      lappend _FEEDBACK(listbox_map) -1
      incr error_cnt $llen
    }
  }

  # Tell user how many total errors.
  $win.top_label config -text \
      "Ext. DRC Feedback - Total entries: $error_cnt"

  raise $win
  eval layt_box exact $save_box
}

proc _feedback_ext::win_invoke {lx ly action} -desc {
  Click item number at y window coord x,y in the feedback list.
} {
  global _FEEDBACK _FEEDBACK_INFO

  set win $_FEEDBACK(win)

  set plist $win.items.list
  set n [$plist index @$lx,$ly]
  set val [$plist get $n]
  $plist selection clear 0 end

  switch -- $action {
    "select" {
      set ch1 [string index $val 0]
      if { $ch1 == "+" } {
	# Remove leading +/-
	set text [string range $val 2 end]
	# Remove trailing count in parens
	regsub { \([0-9]*\)$} $text "" text
	# Tell feedback_win_update to expand this error message.
	set _FEEDBACK_INFO($text,expand) 1
	# Update the listbox contents.
	_feedback_ext::win_update
      } elseif { $ch1 == "-" } {
	set text [string range $val 2 end]
	regsub { \([0-9]*\)$} $text "" text
	set _FEEDBACK_INFO($text,expand) 0
	_feedback_ext::win_update
      } else {
	# It is a feedback entry.  Highlight it in the listbox.
	$plist selection set $n
	$plist see $n
	# Set index for "Find Next Error"
	set _FEEDBACK(list_index) [lindex $_FEEDBACK(listbox_map) $n]
	# Highlight the error in max.
	_feedback_ext::show
      }
    }
    default { assert { 0 } }
  }
}

proc _feedback_win_invoke {lx ly {action select}} -desc {
} {
  global _FEEDBACK
  eval $_FEEDBACK(type)::win_invoke $lx $ly $action
}


proc _feedback_win_update {{-repost} option} -desc {
  Update the feedback window.
} -doc { 
  <option> can be:
    "reload" to reload max drc information,
	  if _FEEDBACK(type) is _feedback_max.
    "reset" to reload and reset the current drc indicies.
  
  If -repost, repost the "DRC Feedback" menu to add/remove calibre buttons.
} {
  global _FEEDBACK _FEEDBACK_LIST_AREA

  if {$option == "reset"} {
    set _FEEDBACK(list_index) -1
    set _FEEDBACK(max_index) -1
    catch { unset _FEEDBACK_LIST_AREA }  ;# area may have changed
  }

  if {$repost} {
    if {[winfo exists $_FEEDBACK(win)]} {
      catch {destroy $_FEEDBACK(win)}
      feedback_window  ;# and repost it.
    }
  }

  # This is a good place to erase any drc message that was posted
  # when the user selected a feedback from the listbox.
  mode_inform_msg ""

  if { $option == "reload" || $option == "reset" } {
      $_FEEDBACK(type)::reload
  }
  if { ! [winfo exists $_FEEDBACK(win)]} {
      # Window not up, dont bother about filling in the list box.
      return
  }
  $_FEEDBACK(type)::win_update
}


proc _feedback_ext::win_select {} -desc {
  Set DRC feedback listbox selection based on _FEEDBACK(list_index)
} {
  global _FEEDBACK

  if {! [winfo exists $_FEEDBACK(win)]} { return }

  set index $_FEEDBACK(list_index)
  if { $index == -1 } {
    # No selection yet.  Probably just started.
    return
  }

  # update the selection in the listbox.
  set plist $_FEEDBACK(win).items.list
  $plist selection clear 0 end

  set n [lsearch -exact $_FEEDBACK(listbox_map) $index]
  if { $n >= 0 } {
    catch {
      $plist selection set $n
      $plist see $n
    }
    # This should be the same result as the feedback_ext::show
    # in find_next_error.
    #set val [$plist get $n]
    #_feedback_ext::show [string trim $val]
  }
}

proc _feedback_win_setup {} -desc {
  Post window for misc setup for feedback window.
} {
  global _FEEDBACK max_win

  # Remove this binding temporarily.  I did not notice the DRC window
  # fighting with the prop_menu for dominance, but lets be safe.
  bind $max_win <Expose> ""

  set prop_list ""
  lappend prop_list [list "View Feedback From:" _FEEDBACK(source) \
      -radio {Max_DRC Calibre_DRC Other_DRC} -values {max calibre other} -reload \
      -help {If Other_DRC, view feedback that was entered using the \
      max "feedback" command.}]

  lappend prop_list [list "" "" -separator]

  lappend prop_list [list "View Method:" _FEEDBACK(view_method) \
    -radio {"Zoom to error" "Center view on error" "Set box only"} \
    -values {zoom center 0}]
  
  lappend prop_list [list "DRC Feedback window always on top" _FEEDBACK(always_on_top) \
    -binary]

  lappend prop_list [list "Max number of errors to list" _FEEDBACK(max_limit) -number \
    -when {$_FEEDBACK(source) == "max"}]

  lappend prop_list [list "Clear External DRC Feedback Now" "" \
       -button "feedback clear_internal" \
       -help {External DRC Feedback is DRC error info that was entered with the :feedback\
       command.  You must clear that feedback before you can view max DRC feedback.}]

  lappend prop_list [list "Calibre Setup..." "" \
       -button "calibre_setup" -when {$_FEEDBACK(source) == "calibre"} ]

  lappend prop_list [list "Run Calibre Now" "" \
       -button "calibre_run" -when {$_FEEDBACK(source) == "calibre"} ]

  lappend prop_list [list "Load Feedback from previous Calibre Run Now" "" \
       -button "calibre_input" -when {$_FEEDBACK(source) == "calibre"} ]

  set title "Feedback Setup"
  set ret [prop_menu2 -title $title $prop_list]
  if { $ret == 0 } { return }

  set _FEEDBACK(type) [expr {$_FEEDBACK(source)=="max" ? "_feedback_max" : "_feedback_ext"}]

  # Load any new errors now.
  _feedback_win_update -repost reload

  if { $_FEEDBACK(always_on_top) } {
    bind $max_win <Expose> _feedback_win_raise
  } else {
    bind $max_win <Expose> ""
  }
}


proc _feedback_ext::load {} {
  global _FEEDBACK
    feedback clear
  puts "NOT IMPLEMENTED"
  _feedback_win_update reset
}


proc _feedback_win_set_area {} {
  global _FEEDBACK
  set _FEEDBACK(area_method) "box"
  set win $_FEEDBACK(win)
  set _FEEDBACK(area) [layt_box mask]
  $win.rr2 config -text "Area: $_FEEDBACK(area)"
  _feedback_win_update reset
}

proc _feedback_win_raise {} {
  global _FEEDBACK max_win
  if {$_FEEDBACK(always_on_top)} {
    if {[winfo exists $_FEEDBACK(win)]} {
      raise $_FEEDBACK(win) $max_win
    }
  }
}

proc _feedback_win_nth_error {} {
  set nth 1
  set prop_list [list [list "DRC Error Number:" nth -number]]
  set message "DRC Error Number to Display"
  set ret [prop_menu2 -atmouse -50 -title $message $prop_list]
  if { $ret == 0 } { return } ;# cancelled
  find_next_error $nth
}

proc _feedback_win_destroy {} {
  global _FEEDBACK max_win
  bind $max_win <Expose> ""
  catch {destroy $_FEEDBACK(win)};
}

proc _feedback_win_rerun {} -desc {
  invoked from DRC Feedback window button
} {
  global _FEEDBACK
  if {$_FEEDBACK(source) == "calibre"} {
    # Invoke calibre
    calibre_run
  }

  msg "Loading feedback into DRC Feedback window\n"
  $_FEEDBACK(type)::reload
  _feedback_win_update reset

  if {$_FEEDBACK(source) == "max"} {
    # The error does not actually post in the window until
    # we do this:
    find_next_error
  }
}


proc feedback_window {} -desc {
  Create and post the DRC feedback window.
} {
  global _FEEDBACK LISTBOX_FONT

  _feedback_init

  # This is really wierd.  The drc feedback 
  if {[lay_editcell] != [lay_rootcell]} {
    warning "You are currently sub-editing cell [lay_editcell]\n\
    Setting DRC Feedback area to extent of that cell."

    # Prune drc results to the current edit cell.
    set _FEEDBACK(area_method) "box"
    set _FEEDBACK(area) [db_bbox]
  }

  set win $_FEEDBACK(win)

  util_win_create $win "DRC Feedback"

  set font $LISTBOX_FONT; # Just a shorter name for the font

  bind $win <Any-Control-c> "_feedback_win_destroy; break"
  bind $win <Escape> "_feedback_win_destroy; break"
  bind $win <N> "find_next_error"

  label $win.top_label -text "DRC Feedback"
  pack $win.top_label -side top -fill x


  # Create a frame for the errors.
  frame $win.items

  scrollbar $win.items.vscroll \
	  -relief raised \
	  -command "$win.items.list yview"

  listbox $win.items.list \
	  -font $font \
	  -exportselection false \
	  -selectmode single \
	  -relief raised -height 8 \
	  -yscrollcommand "$win.items.vscroll set"

  # The break is necessary to keep the listbox from processing
  # the mouse buttons after we are done with them.
  bind $win.items.list <Button-1> {_feedback_win_invoke %x %y;break}
  #bind $win.items.list <Double-Button-1> { \
	  _feedback_win_invoke %x %y 2; break }
  #bind $win.items.list <Button-2> { \
	  _feedback_win_invoke %x %y 2; break }

  # pack the list and scrollbars
  pack $win.items.list -side left -fill both -expand 1
  pack $win.items.vscroll -side right -fill y
  pack $win.items -fill both -expand 1

  frame $win.f4 -relief sunken -bd 1
  frame $win.f5  ;# Frame for "Set" button next to radiobutton.
  radiobutton $win.rr1 -text "Entire Cell" \
    -variable _FEEDBACK(area_method) -value "cell" -anchor w \
    -command "_feedback_win_update reset"
  radiobutton $win.rr2 -text "Area: $_FEEDBACK(area)" \
    -variable _FEEDBACK(area_method) -value "box" -anchor w \
    -command "_feedback_win_update reset"
  button $win.set_area -text "Set Area" \
    -command "box_mode_enter -cmd _feedback_win_set_area" \
    -padx 3 -pady 1
  
  pack $win.rr1 -in $win.f4 -side top -anchor w -fill x
  pack $win.rr2 -in $win.f5 -side left -anchor w -fill x
  pack $win.set_area -in $win.f5 -side left
  pack $win.f5 -in $win.f4 -side top -anchor w -fill x
  pack $win.f4 -side top -fill x

  frame $win.f10
  button $win.setup -text "Setup..." -command _feedback_win_setup \
    -padx 3 -pady 3
  pack $win.setup -in $win.f10  -side left -fill x -expand 1
  pack $win.f10 -fill x

  frame $win.f20
  frame $win.f11
  frame $win.f12

  button $win.prev -text "< Prev Error" -command "find_next_error prev" \
    -padx 3 -pady 3
  pack $win.prev -in $win.f11 -side top -fill x

  button $win.next -text "Next Error >" -command find_next_error \
    -padx 3 -pady 3
  pack $win.next -in $win.f12 -side top -fill x

  button $win.nextkind -text "Next Kind" -command "find_next_error kind" \
    -padx 3 -pady 3
  pack $win.nextkind -in $win.f11 -side top -fill x

  button $win.nth -text "Nth Error" -command _feedback_win_nth_error \
    -padx 3 -pady 3
  pack $win.nth -in $win.f12 -side top -fill x

  pack $win.f11 -in $win.f20 -side left -fill x -expand 1
  pack $win.f12 -in $win.f20 -side left -fill x -expand 1
  pack $win.f20 -fill x

  set helpmsg {\
    The DRC Feedback window feeds back errors from the a Design Rule Checker.\
    Use "Setup..." to specify the source for feedback, which can be the\
    Max built-in DRC, or an external DRC. \
    Select "Entire Cell" to show all errors\
    in the cell, or select "Area" to show errors only within the specified\
    area.  Use the "Set Area" button to set the area to show errors. \

    Max errors are displayed one by one.  Use the "Next Error" and "Prev Error"\
    to scan through the errors.  The "Next Kind" button skips forward\
    until a different kind of error is found. \

    Feedback from an external DRC is shown in the listbox, sorted by\
    kind of error.  The error kinds are preceded by "+" (unexpanded)\
    or "-" (expanded.)  Click on an unexpanded error kind to expand it,\
    showing all the individual errors.  You can click on any error\
    to immediately view the feedback for that error.  You can also\
    use the "Next Error", "Prev Error", "Next Kind" or "Nth Error" buttons.\
  }

  switch -- $_FEEDBACK(source) {
    "max" {
      set but_text "Refresh Max DRC Results Now"
    }
    "calibre" {
      set but_text "Run Calibre DRC Now"
    }
    "other" {
      set but_text "Refresh Feedback Now"
    }
  }
  button $win.runcal -text $but_text -command _feedback_win_rerun \
      -padx 3 -pady 3
  pack $win.runcal -fill x -expand 1

  # bottom Buttons
  frame $win.buttons

  button $win.done -text "Close" -padx 1 -pady 2 -default normal\
    -command "_feedback_win_destroy"
  button $win.help -text "Help" -padx 1 -pady 2 -default normal\
    -command [list prop_dialog -title {Selection Probe Help} $helpmsg]

  pack $win.done $win.help -side left \
    -in $win.buttons -padx 1m -ipadx 1m -pady 1m -expand 1
  pack $win.buttons -side bottom

  util_win_finish $win -place right

  # Fill it with the current goob.
  _feedback_win_update reload
  # If the user is reopening the window, attempt to reposition
  # the selection to the previous location.
  # Dont know if this is right thing, since the box may not
  # be over this error any more.

  if { $_FEEDBACK(type) != "_feedback_max" } {
    eval $_FEEDBACK(type)::win_select
  }
}


proc _feedback_init {} {
  global _FEEDBACK
  set _FEEDBACK(win) .feedback  ;# Communicate win name to other procs.
  use_init _FEEDBACK(any_cell) 1
  use_init _FEEDBACK(view_method) zoom
  use_init _FEEDBACK(area_method) cell
  use_init _FEEDBACK(always_on_top) 0
  use_init _FEEDBACK(max_limit) 10000 ;# Max number of errors displayed.

  if {![info exists _FEEDBACK(area)]} {
    set _FEEDBACK(area) [layt_box mask]
  }
  if { $_FEEDBACK(area) == "" } {
    # Happens sometimes if box not defined yet.
    set _FEEDBACK(area) "0 0 0 0"
  }

  use_init _FEEDBACK(max_index) -1
  use_init _FEEDBACK(list_index) -1

  # Maps listbox entry to error index.
  use_init _FEEDBACK(listbox_map) ""

  # This is set to the feedback source.
  # It can be "max", "calibre", or "other".
  use_init _FEEDBACK(source) max

  # This is set to the tcl namespace of the drc we are using.
  # It must be either _feedback_max or _feedback_ext
  # If "max", then _FEEDBACK(type) == "_feedback_max",
  # for any other drc, the feedback is entered with the feedback
  # command and _FEEDBACK(type) == "_feedback_ext"
  set _FEEDBACK(type) [expr {$_FEEDBACK(source)=="max" ? "_feedback_max" : "_feedback_ext"}]
}

proc feedback_set_source {source} -desc {
  Set the feedback source to max, calibre, or other.
} {
  global _FEEDBACK
  set _FEEDBACK(source) $source
  set _FEEDBACK(type) [expr {$_FEEDBACK(source)=="max" ? "_feedback_max" : "_feedback_ext"}]
}


proc feedback {args} -desc {
  Replaces :feedback
} -doc {
USAGE:
  feedback [-text <text>] action [args ...]
  <action> may be:
  "clear" clear all feedback
  "rect" x1 y1 x2 y2  - add specified rectangle, coords are opposite corners.
  "edge" x1 y1 x2 y2  - add specified edge
  "poly" x y [x y ...] - add specified polygon, coords are vertices.
  "add" text [type]
    - backward compatible: add current box location as a
    feedback rectangle with specified text 
  <args> may also contain:
  -text <text> - text of feedback, default "unspecified".
} {
  global _FEEDBACK _FEEDBACK_LIST _FEEDBACK_LIST_AREA
  _feedback_init
  set args [call_keyword $args {{text unspecified}}]
  set action [lindex $args 0]
  set args [lrange $args 1 end]

  # Invalidate the area cache, which must be recomputed now.
  catch { unset _FEEDBACK_LIST_AREA }

  switch $action {
    "clear_internal" {
      # Like clear, but don't reset the selection index.
      catch { unset _FEEDBACK_LIST }
      catch { unset _FEEDBACK_MAX }  ;# Force update of max error info, too.
      _feedback_win_update 0  ;# Updates the listbox.
      :feedback clear
      lay_line -tag drc -clear
      return
    }
    "clear" {
      set _FEEDBACK(type) "_feedback_max"
      set _FEEDBACK(area_method) "cell"
      feedback clear_internal
      set _FEEDBACK(list_index) -1
      set _FEEDBACK(max_index) -1
      return
    }
    "add" {
      # This is for backward compatibility with :feedback.
      # Add the current box position as a feedback rectangle.
      setl {text type} $args
      # Ignore the type.
      lappend _FEEDBACK_LIST($text) "rect [layt_box exact]"
      # Add something to see.
      :feedback add ""
    }
    "rect" {
      if {[llength $args] != 4} {
	error "feedback rect syntax"
      }
      lappend _FEEDBACK_LIST($text) "rect $args"
      eval layt_box exact $args
      # Add something to see.
      :feedback add ""
    }
    "edge" {
      if {[llength $args] != 4} {
	error "feedback edge syntax"
      }
      lappend _FEEDBACK_LIST($text) "edge $args"
      eval _feedback_boxify $args
    }
    "poly" {
      # Dont show user "poly" - it is too confusing with polysilicon
      lappend _FEEDBACK_LIST($text) "area $args"
      # Connect the dots...
      setl {x y} $args
      set args [lrange $args 2 end]
      set first_x $x; set first_y $y
      while {$args != ""} {
        set prev_x $x; set prev_y $y
	setl {x y} $args
	set args [lrange $args 2 end]
	_feedback_boxify $x $y $prev_x $prev_y
      }
      _feedback_boxify $first_x $first_y $x $y
    }
    "count" {
      return [llength [use_first _FEEDBACK_LIST]]
    }
    default {
      error "feedback syntax: unrecognized: $action"
    }
  }

  # For above options that did not return:
  # User has added some external feedback; switch feedback to show it.
  set _FEEDBACK(type) "_feedback_ext"
  set _FEEDBACK(area_method) "cell"
}


proc _feedback_ext::show {} -desc {
  Show feedback for error number at _FEEDBACK(list_index).
} -doc {
  First word in error_info is the type, eg, "rect".
  Rest is data depending on type.
} {
  global _FEEDBACK _FEEDBACK_LIST_AREA

  set index $_FEEDBACK(list_index)

  setl {kind sub_index} [_feedback_ext::index2kind $index]
  if { $kind == "" || $sub_index == -1} {
    msg "_feedback_ext::show internal error\n"
    return
  }

  # For the user, make drc error numbers start at one.
  mode_inform_msg "DRC #[expr $index + 1]: $kind"

  set error_info [lindex $_FEEDBACK_LIST_AREA($kind) $sub_index]

  set type [lindex $error_info 0]
  switch $type {
    "edge" -
    "rect" {
      setl {type x1 y1 x2 y2} $error_info
    }
    "area" {
      set points [lrange $error_info 1 end]
      # Find min and max of all points.
      setl {x y} $points
      set points [lrange $points 2 end]
      set x1 $x; set x2 $x
      set y1 $y; set y2 $y
      while { [llength $points] > 0 } {
	setl {x y} $points
	set points [lrange $points 2 end]
	set x1 [min $x1 $x]
	set x2 [max $x2 $x]
	set y1 [min $y1 $y]
	set y2 [max $y2 $y]
      }
    }
    default {
      error "error type $type not implemented"
    }
  }
  _feedback_goto_error $x1 $y1 $x2 $y2
}


# Got this from lee.
proc _feedback_boxify {x1 y1 x2 y2 {scale 1}} -desc {
  make an annotated box around the line given by the coords
} {

  # just a line
#  lay_line [expr $x1 / $scale] [expr $y1 / $scale] \
      [expr $x2 / $scale] [expr $y2 / $scale]


  # rect (assumes x1 < x2, y1 < y2)
  set d [expr 2 * [res] * $scale]

  lay_line -tag drc [expr ($x1 - 0) / $scale] [expr ($y1 - 0) / $scale] \
      [expr ($x2 - 0) / $scale] [expr ($y2 + 0)/ $scale]
  lay_line -tag drc [expr ($x1 + 0) / $scale] [expr ($y1 - 0) / $scale] \
      [expr ($x2 + 0) / $scale] [expr ($y2 + 0)/ $scale]

  lay_line -tag drc [expr ($x1 - $d) / $scale] [expr ($y1 - 0) / $scale] \
      [expr ($x2 - $d) / $scale] [expr ($y2 + 0)/ $scale]
  lay_line -tag drc [expr ($x1 + $d) / $scale] [expr ($y1 - 0) / $scale] \
      [expr ($x2 + $d) / $scale] [expr ($y2 + 0)/ $scale]

  lay_line -tag drc [expr ($x1 - 0) / $scale] [expr ($y1 - $d) / $scale] \
      [expr ($x2 + 0) / $scale] [expr ($y2 - $d)/ $scale]
  lay_line -tag drc [expr ($x1 - 0) / $scale] [expr ($y1 + $d) / $scale] \
      [expr ($x2 + 0) / $scale] [expr ($y2 + $d)/ $scale]
}
