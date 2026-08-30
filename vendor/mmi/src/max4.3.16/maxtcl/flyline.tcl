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

set RCSVERSION(flyline.tcl) { $Revision: 1.6 $ }


# These _mode_enter functions exist primarily just to provide a desc
# that is viewable from the menu_bar.
proc flyline_mode_enter {} -desc {
    Edit Flylines
} {
    mode_push flyline
}



proc _flyline_gate_keeper {event} -desc {
    called whenever flyline mode is entered/exited
} {
    global FLYLINE FLYLINE_LIST mode_abort

    if {$event == "PUSH_TO"} {
	set FLYLINE(selected) ""
	# Flyline state is: 0 init; 1 drawing flyline.
	set FLYLINE(state) 0
    } elseif {$event == "POP_FROM"} {

	# If in the middle of creating  a new flyline, kill it.
	if { $FLYLINE(state) == 1 } {
	    sel_labels -text $FLYLINE(label1)
	    :delete
	    sel_labels -text $FLYLINE(label2)
	    :delete
	    db_flyline -delete $FLYLINE(label1) $FLYLINE(label2)
	}

	if { $mode_abort } {
	    undo_to_delim
	    undo_flush_redo
	    msg "aborting flylines!\n"
	}
	lay_line -tag flyline_select -clear
	catch { unset FLYLINE }
	catch { unset FLYLINE_LIST }

	i_cmd_between
    }
}

proc _flyline_delete {lab1 lab2} -desc {
    Delete the flyline and associated labels.
} {
    db_flyline -delete $lab1 $lab2
    sel_labels -text $lab1
    :delete
    sel_labels -text $lab2
    :delete
}


proc _flyline_delete_selected {} -desc {
    delete selected flyline
} -doc {
    Delete currently highlighted flyline,
    which is in FLYLINE(selected).
} {
    global FLYLINE FLYLINE_LIST
    setl {lab1 x1 y1 lab2 x2 y2} $FLYLINE(selected)
    # If no flyline selected.
    if { $lab1 == "" } { return }
    db_flyline -delete $lab1 $lab2
    # Delete the labels only if they are hidden and only if they are
    # not used by any other flylines.
    foreach label [list $lab1 $lab2] {
	sel_labels -text $label
	struct max_label lab [sel_what labels]
	if { ${lab.kind} == "hidden" && 
	    ( ![info exists FLYLINE_LIST(count,$label)] ||
	    $FLYLINE_LIST(count,$label) == 1 ) } {
	    :delete
	    incr FLYLINE_LIST(count,${lab.text}) -1
	}
    }
    mode_pop
}


proc _flyline_mode_define {} {
  mode_def flyline _flyline_gate_keeper "BUT-1 creates; BUT-2 ends; BUT-3 deletes"

  mode_bind -cmd 0 flyline <Any-Button-1> _flyline_vertex
  mode_bind -cmd 0 flyline <Any-Motion> _flyline_motion
  mode_bind -cmd 0 flyline <Delete> _flyline_delete_selected
  mode_bind -cmd 0 flyline <Any-Button-2> mode_pop
  mode_bind -cmd 0 flyline <Any-Button-3> _flyline_delete_selected
}

proc _flyline_select_nearest {} -desc {
    Find and select nearest flyline.
} {
    global FLYLINE FLYLINE_LIST
    setl {x y} [layt_point exact]

    _flyline_make_list

    # Is the point near a flyline?
    set flyline ""
    foreach fly $FLYLINE_LIST(list) {
	setl {name1 a.x a.y name2 b.x b.y} $fly
	if {[nearby_line $x $y ${a.x} ${a.y} ${b.x} ${b.y}]} {
	    set flyline $fly
	    break
	}
    }
    if { $flyline == "" || $flyline != $FLYLINE(selected) } {
	# Clear old selection, if any.
	lay_line -clear -tag flyline_select
	set FLYLINE(selected) ""
    }
    if { $flyline != "" } {
	# Select the new flyline
	set FLYLINE(selected) $flyline
	layt_line_box flyline_select ${a.x} ${a.y} ${b.x} ${b.y} \
		0 [expr [nearby_dist] * 2]
    }
}

proc _flyline_make_list {} -desc {
    Create a list of all flyline points in FLYLINE(list)
} {
    global FLYLINE_LIST
    # If already made, dont need to redo it.
    # It is unset after adding each flyline.
    if { [info exists FLYLINE_LIST] } { return }
    set FLYLINE_LIST(list) ""
    set list [split [string trim [db_flyline] "\n"] "\n"]
    foreach fly $list {
	setl {junk name1 name2} $fly
	# TODO: This should db_search labels, but that doesnt work 
	# for hierarchical labels yet (8/18/99),
	# so use dbt_search_label, which does.
	set info1 [dbt_search_label $name1]
	set info2 [dbt_search_label $name2]
	if { $info1 == "" || $info2 == "" } {
	    # One of the labels is missing
	    msg "warning: label missing in flyline from $name1 to $name2\n"
	    continue
	}
	# Found both labels.  Remember this flyline.
	struct max_label lab1 $info1
	struct max_label lab2 $info2
	set lab1x [expr (${lab1.x1} + ${lab1.x2}) / 2.0]
	set lab1y [expr (${lab1.y1} + ${lab1.y2}) / 2.0]
	set lab2x [expr (${lab2.x1} + ${lab2.x2}) / 2.0]
	set lab2y [expr (${lab2.y1} + ${lab2.y2}) / 2.0]
	lappend FLYLINE_LIST(list) [list $name1 $lab1x $lab1y $name2 $lab2x $lab2y]
	foreach label [list ${lab1.text} ${lab2.text}] {
	    if {! [info exists FLYLINE_LIST(count,$label)]} {
		set FLYLINE_LIST(count,$label) 0
	    }
	    incr FLYLINE_LIST(count,$label)
	}
    }
}

proc _flyline_vertex {} -desc {
    function hooked to Button-1
} {
    global FLYLINE
    if { $FLYLINE(state) == 0 } {
	_flyline_start
	set FLYLINE(state) 1
    } else {
	if { [_flyline_end] } {
	    set FLYLINE(state) 0
	    mode_pop
	}
    }
}

proc _flyline_start {} {
    global FLYLINE
    set FLYLINE(point1) [layt_point user]
    setl {x y} $FLYLINE(point1)

    set FLYLINE(label1) [_wire_unique_label]
    set FLYLINE(label2) [_wire_unique_label]
    set layer [wire_choose_layer -return]
    if { $layer == "" } {
	warning "no routable layer under cursor"
	mode_pop	;# Get out of flyline mode.
	return
    }
    db_label -kind hidden $layer $FLYLINE(label1) $x $y $x $y
    db_label -kind hidden space $FLYLINE(label2) $x $y $x $y
    db_flyline $FLYLINE(label1) $FLYLINE(label2)
}

proc _flyline_drag {} {
    global FLYLINE
    # move the label
    sel_labels -text $FLYLINE(label2)
    :delete
    setl {x y} [layt_point exact]
    db_label -kind hidden space $FLYLINE(label2) $x $y $x $y
}

proc _flyline_motion {} -desc {
    function hooked to mouse motion.
} {
    global FLYLINE
    if { $FLYLINE(state) == 0 } {
	_flyline_select_nearest
    } else {
	_flyline_drag
    }
}


proc _flyline_end {} -desc {
    End current flyline.  Return 1 if ended, 0 to continue.
} {
    global FLYLINE
    if { [eval nearby [layt_point exact] $FLYLINE(point1)] } {
	# Didnt drag out a flyline, just delete it.
	_flyline_delete $FLYLINE(label1) $FLYLINE(label2)
	return 1  ;# Giving up, so all done.
    } else {
	set layer [wire_choose_layer -return]
	if { $layer == "" } {
	    set msg "no routable layer under cursor"
	    set button [tk_dialog .warning "max warning" $msg {} 0 OK Cancel]
	    if { $button == 1 } {
		# Cancel flyline
		_flyline_delete $FLYLINE(label1) $FLYLINE(label2)
		return 1 ;# Canceled. All done
	    } else {
		return 0 ;# Try again.
	    }
	}
	# Move label2 to layer.
	sel_labels -text $FLYLINE(label2)
	:delete
	setl {x y} [layt_point exact]
	db_label -kind hidden $layer $FLYLINE(label2) $x $y $x $y
	return 1  ;# All done
    }
}
