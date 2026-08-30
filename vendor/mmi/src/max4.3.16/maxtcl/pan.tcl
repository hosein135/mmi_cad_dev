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

set RCSVERSION(pan.tcl) { $Revision: 1.8 $ }

# implements auto panning

# percentage of distance cursor past edge to pan.
set PAN(factor) .5

# interval between auto pans in milliseconds
set PAN(interval) 100    

set PAN(scheduled) 0
set PAN(enabled) 0
set PAN(notify_script) ""
set PAN(notifying) 0

proc pan_reset {} -desc {
  reset pan module.
} {
  global PAN
  set PAN(enabled) 0
}

proc pan_enable {} -desc {
  enable auto pan
} -doc {
    usually called by gate-keepers when entering modes supporting auto panning.
} {
    global PAN
    incr PAN(enabled) 1
}

proc pan_disable {} -desc {
  disable auto pan
} -doc {
    usually called by gate-keepers when exiting modes supporting auto panning.
} {
    global PAN
    incr PAN(enabled) -1
}

proc pan_gate_keeper {event} -desc {
    simple gate keeper for modes that autopan 
} {
  global mode_abort 

    if {$event == "PUSH_TO"} {
	pan_enable
    } elseif {$event == "POP_FROM"} {
	pan_disable
    }
}

proc pan_auto {{notify ""}} -desc {
  if cursor is at or over edge of layout window, pan over.
} -doc {
    Notify evaled when ever we pan (needed since panning effectively causes
    cursor motion)

    Usually called the first time by event such as cursor motion,
    and then automatically schedules periodic repeats.

    Modes where auto panning is desired, should call pan_enable on
    entry and pan_disable on exit.

    CONFIGURATION
    -------------
    PAN(factor) = .5     #scroll over 50% of distance cursor past window boundary
    PAN(interval) = 100  #repeat every 100 milliseconds.
} {

    global max_win PAN CURSOR

    # update cursor position window
    cursor_msg_update

    if { $PAN(enabled) <= 0 || $PAN(notifying) } {
	return 
    }

    if { $notify != "-repeat" } {
	set PAN(notify_script) $notify
    }

    if { $PAN(scheduled) } {
	return;
    }

    ## compute percentange of screen height/width cursor is past boundary
    ## +dx is to the right, - dx is to the left, and similarly for dy.
    set panning 0
    set dx 0
    set dy 0

    # window frame and cursor in X coords
    set w $max_win.layout
    set x1 [winfo rootx $w]
    set y1 [winfo rooty $w]
    set width [winfo width $w]
    set height [winfo height $w]
    set x2 [expr $x1 + $width - 1]
    set y2 [expr $y1 + $height - 1]
    set cx [winfo pointerx $w]
    set cy [winfo pointery $w]

    #LEFT
    if { $cx <= $x1 } {
	set dx [expr ($cx - $x1 + 0.0) / $width]
	set panning 1
    } 

    #RIGHT
    if { $cx >= $x2 } {
	set dx [expr ($cx - $x2 + 0.0) / $width]
	set panning 1
    } 

    #UP (X coords inverted)
    if { $cy <= $y1 } {
	set dy [expr ($y1 - $cy + 0.0) / $height]
	set panning 1
    } 

    #DOWN (X coords inverted)
    if { $cy >= $y2 } {
	set dy [expr ($y2 - $cy + 0.0) / $height]
	set panning 1
    }

    if { [use_first CURSOR(wait)] != "" } {
      # The cursor module is notified whenever via tk_dialog whenever
      # an error message occurs, and sets CURSOR(wait) to something.
      # We want to disable pan under the same conditions.
      set panning 0
    }

    # do it
    if { $panning } {

	# frame in DB coords
	setl {x1 y1 x2 y2} [$max_win.layout frame]

	# convert deltas to DB coords
	set dx  [expr ($x2 - $x1) * $dx * $PAN(factor) ]
	set dy  [expr ($y2 - $y1) * $dy * $PAN(factor) ]

	# make sure we move at least one unit!
	set unit [res]
	if {$dx > 0 && $dx < $unit} { set dx $unit }
	if {$dx < 0 && $dx > -$unit} { set dx -$unit }
	if {$dy > 0 && $dy < $unit} { set dy $unit }
	if {$dy < 0 && $dy > -$unit} { set dy -$unit }

	# apply deltas to frame
	set x1 [expr $x1 + $dx]
	set x2 [expr $x2 + $dx]
	set y1 [expr $y1 + $dy]
	set y2 [expr $y2 + $dy]

	# reframe
	eval $max_win.layout frame [uusnap $x1 $y1 $x2 $y2]

	# notify of panning (guarding against reentry)
	set PAN(notifying) 1
	eval $PAN(notify_script)
	set PAN(notifying) 0 
    }
    
    # schedule repeat after an interval
    set PAN(scheduled) 1
    after $PAN(interval) {
	global PAN
	set PAN(scheduled) 0 
	pan_auto -repeat
    }
}


