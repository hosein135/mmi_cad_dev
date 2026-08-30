
set DRC_INDEX 0

proc find_next_error {{type next}} -desc {
  find next feedback region and zoom to it
} -doc {
  If no feedback regions then find next drc error and zoom to it.
  Annotations can be DRC errors, mask layers, etc.

  WARNING: This function may leave the box on a grid smaller
  than the user grid.
} {

  global DRC_INDEX NEXT_ERROR

  if {![info exists NEXT_ERROR]} {
    set NEXT_ERROR ""
  }

  msg_catch ":feedback find" "" msg
  if {[layt_box dontcare] == ""} {
    # FIX: hack to put box back into window if feed find moved it
    eval layt_box exact [lay_bbox]
    msg "Skipping feedback in subcell\n"
    set NEXT_ERROR ""
  }

  # yes this is gross
  set msg_string "barfo"
  regexp {:(.*)$} $msg msg_string 

  if {[string trimright $msg] != "There are no feedback areas right now."} {
    if {$type == "kind"} {
      set last_count 0
      while {$msg_string == $NEXT_ERROR} {
        msg_catch ":feedback find" "" msg
	regexp {:(.*)$} $msg msg_string 
	if {![regexp {Feedback \#([0-9]+)\:} $msg bogus count]} {
	  # didn't find, assume starting over
	  break
	}
	if {$count < $last_count} {
	  # starting over
	  break
	}
	set last_count $count
      }
    }

    set NEXT_ERROR $msg_string

    setl {x1 y1 x2 y2} [layt_box exact]  ;# Save for later restore
    # should be a parameter
    set del 2
    layt_box exact [expr $x1 - $del] [expr $y1 - $del] \
	[expr $x2 + $del] [expr $y2 + $del]
    :findbox zoom
    layt_box exact $x1 $y1 $x2 $y2       ;# Restore old box

    # show the user feedback errors
    msg "$msg\n"
    
    return
  }

  set drc_errors [db_search_l paint -any_cell errors]
  if {[llength $drc_errors] == 0} {
    msg "no errors\n"
    set NEXT_ERROR ""
    return
  }

  set DRC_INDEX [expr $DRC_INDEX % [llength $drc_errors]]

  # show user the next drc error
  set error [lindex $drc_errors $DRC_INDEX]
  set last_coords [lrange $error 1 4]

  eval layt_box exact $last_coords
  msg_catch ":drc why" "" msg

  if {$type == "kind"} {
    while {$msg == $NEXT_ERROR} {
      incr DRC_INDEX
      set DRC_INDEX [expr $DRC_INDEX % [llength $drc_errors]]
      set error [lindex $drc_errors $DRC_INDEX]
      set coords [lrange $error 1 4]

      eval layt_box exact $coords
      msg_catch ":drc why" "" msg

      if {$coords == $last_coords || $coords == ""} {
	# been here
	break
      }
    }
  }

  setl {x1 y1 x2 y2} [layt_box exact]  ;# Save box for later restore
  # should be a parameter
  set del 2
  layt_box dontcare [expr $x1 - $del] [expr $y1 - $del] \
      [expr $x2 + $del] [expr $y2 + $del]
  :findbox zoom
  layt_box exact $x1 $y1 $x2 $y2       ;# Restore box

  :drc why

  set NEXT_ERROR $msg

  incr DRC_INDEX
}
