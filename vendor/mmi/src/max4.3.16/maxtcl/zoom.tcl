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

set RCSVERSION(zoom.tcl) { $Revision: 1.16 $ }

# Implements a zoom drag box for zooming that doesn't disturb the box

proc zoom_mode_enter {} -desc {
drag box zoom
} -doc {
leaves box and cursor undisturbed
} {
  mode_push zoom
}

proc _zoom_mode_define {} -desc {
    drag box zoom (leaves box and point undisturbed)
} {
    mode_def zoom _zoom_gate_keeper "BUT-1 drags zoom box"

    mode_bind -cmd 0 -desc "drag box to zoom into" \
	    zoom <Any-Button-1> _zoom_button1
}

proc _zoom_gate_keeper {event} -desc {
    called whenever zoom mode is entered/exited
} -doc {
    saves box on entry, restores on exit.
} {
    global ZOOM mode_abort

    if {$event == "PUSH_TO"} {
	# save the box and point so we can restore it on exit
	set ZOOM(point) [layt_point exact]  ;# Remember where this was.
	set ZOOM(box) [layt_box exact]      ;# Save box location

	# Set these now, in case user is really fast on the draw
	# and presses the mouse before max is ready.
	setl {ZOOM(x1) ZOOM(y1)} [layt_point exact]
	setl {ZOOM(x2) ZOOM(y2)} [layt_point exact]

    } elseif {$event == "POP_FROM"} {
	# restore the old box and point
	eval layt_box exact $ZOOM(box)             ;# Restore saved box

	if { $mode_abort } {
	    # If user presses control-C, moving the cursor back
	    # to the starting point is a good way to alert them
	    # that the mode was aborted.  Currently, if zoom is
	    # called from some other sub-mode, its hard to tell what
	    # mode you are in, because cursors are the same.
	    eval layt_point -warp exact $ZOOM(point)
	}

	# If a Control-Z is pushed to abort a zoom, we want to
	# abort only the zoom, not the mode that called it, if any.
	set mode_abort 0

	# This is not needed for zoom: there is nothing to undo!
	#if { $mode_abort } {
	#    :undo
	#    undo_flush_redo
	#    msg "aborting zoom!\n"
	#} 

	# Clear any lines we used for user feedback.
#	lay_line -tag zoom -clear

	# Update screen, just in case there is some message some where
	# that changes with zoom, but do not put in an undo delimiter.
	i_cmd_between_undos
    }
}

proc _zoom_button1 {} {
  global ZOOM

  setl {ZOOM(x1) ZOOM(y1)} [layt_point exact]

  mode_push zoom_drag
}

proc _zoom_drag_mode_define {} -desc {
    zoom_drag mode is active during actual zoom (after button depressed)
} {
    mode_def zoom_drag pan_gate_keeper {}

    mode_bind -cmd 0 -desc "drag out zoom area" \
	    zoom_drag <Any-B1-Motion> _zoom_drag
    mode_bind -cmd 0 -desc "(zoom takes effect on button release)" \
	    zoom_drag <Any-B1-ButtonRelease> _zoom_drag_end
}

proc _zoom_drag {} {
  global ZOOM

  pan_auto _zoom_drag
    
  setl {ZOOM(x2) ZOOM(y2)} [layt_point exact]
  if {$ZOOM(x2) == "" || $ZOOM(y2) == ""} {
    # off screen
    return
  }
  # Draw a box to let user see what is happening.
  # LEE removed lay_line code, flickers screen
#  lay_line -tag zoom -clear
#  lay_line -tag zoom $ZOOM(x1) $ZOOM(y1) $ZOOM(x1) $ZOOM(y2)
#  lay_line -tag zoom $ZOOM(x1) $ZOOM(y2) $ZOOM(x2) $ZOOM(y2)
#  lay_line -tag zoom $ZOOM(x2) $ZOOM(y2) $ZOOM(x2) $ZOOM(y1)
#  lay_line -tag zoom $ZOOM(x2) $ZOOM(y1) $ZOOM(x1) $ZOOM(y1)

  layt_box exact $ZOOM(x1) $ZOOM(y1) $ZOOM(x2) $ZOOM(y2)
}

proc _zoom_drag_end {} -desc {
    called when button released at end of zoom drag.
} {
  global ZOOM

#  lay_line -tag zoom -clear

  # Do the zoom based on the box
  # We dont want max to display this box after the findbox command,
  # because it flashes on, then off, annoyingly.
  # So we are restoring the old box immediately rather than waiting
  # for the mode_pop to do it.
  layt_box exact $ZOOM(x1) $ZOOM(y1) $ZOOM(x2) $ZOOM(y2)
  :findbox zoom
  eval layt_box exact $ZOOM(box)             ;# Restore saved box

  # pop out of zoom_drag, then zoom mode.
  # Note: box will be restored on mode_pop.
  mode_pop 
  mode_pop
}


proc zoom_to_selected {{coords ""}} -desc {
  zooms to show selected centered on the screen
} {

  if {! [dbt_any_selection]} {
    # nothing selected
    msg "zoom aborting, nothing selected to zoom to.\n"
    return
  }

  set save_box [layt_box exact]

  # do it
  setl {x1 y1 x2 y2} [db_bbox -user -cell __SELECT__]
  layt_box exact $x1 $y1 $x2 $y2
  
  # do the zoom based on the box  
  :findbox zoom

  setl {x1 y1 x2 y2} [dbt_frame]
  if {[expr $x2 - $x1] < 1} {
    # zoom out a bunch
    :zoom 1.5
  } elseif {[expr $x2 - $x1] < 10} {
    # zoom out some
    :zoom 1.3
  } elseif {[expr $x2 - $x1] < 100} {
    # zoom out a little
    :zoom 1.1
  }

  # restore box
  eval layt_box exact $save_box
}
