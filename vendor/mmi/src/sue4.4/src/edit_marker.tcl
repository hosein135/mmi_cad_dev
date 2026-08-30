## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
## LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
## CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
## DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
## INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
## 
## JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
## DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
## PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************


# Edit markers are rectangles that are drawn during the editing of
# the draw_items lines and arcs.  Inside these edit_markers are procs
# which tell how to resize the draw_items.

proc edit_draw_item {x y {id ""} {menu 0}} {

  global cur_c DISABLE_CANVAS_EVENT TEXT_CHIT

  modify_setup

  # stop general canvas binding events
  set DISABLE_CANVAS_EVENT 1

  if {$id == ""} {
    set id [$cur_c find withtag current]
  }

  switch [$cur_c type $id] {

    "text" {
      # if it's text send if off
      if {![is_tagged $id selected]} {
	select_id $id
      }

      $cur_c icursor $id @[$cur_c canvasx $x],[$cur_c canvasy $y]
      setup_modify_text_mode $id
      
      if {!$menu} {
	set TEXT_CHIT 1
      }

      return
    }

    "line" {
      create_line_edit_markers $id
    }

    "arc" {
      create_arc_edit_markers $id
    }

    default {
      puts "Unknown type [$cur_c type $id]"
    }
  }
}


# These move procedures copy pretty directly from the icon routines

# Sets up a move for a drawing item edit marker

proc marker_press {x y} {

  global cur_c DISABLE_CANVAS_EVENT SAVE PROC

  # stop general canvas binding events
  set DISABLE_CANVAS_EVENT 1
 
  set SAVE(x) $x
  set SAVE(y) $y

  set SAVE(undo,x) $x
  set SAVE(undo,y) $y
 
  # save undo info
  set SAVE(id) [get_intersect_tag selected draw_item]
  set PROC ""
  write_draw_items selected icon_undo
  set SAVE(proc) $PROC

  # Tag the edit marker so that we can easily find it later
  $cur_c addtag selected_marker withtag current
}
 

# Handles mouse drag on a drawing item edit marker

proc marker_drag {x y {shift ""}} {

  global cur_c SAVE
 
  set SAVE(shift) $shift

  $cur_c move selected_marker [expr $x - $SAVE(x)] [expr $y - $SAVE(y)]

  # get the procedure out of the edit_marker tags
  set tags [$cur_c gettags selected_marker]
  set proc [lrange [lindex $tags [lsearch $tags proc*]] 1 end]

  # execute it
  eval $proc

  set SAVE(x) $x
  set SAVE(y) $y
}
 

# Handles button 1 release on a drawing item edit marker

proc marker_release {} {

  global cur_c SAVE

  # unselect the edit marker
  $cur_c dtag selected_marker

  if {[nearby $SAVE(x) $SAVE(y) $SAVE(undo,x) $SAVE(undo,y)]} {
    # nothing happened
    return
  }

  # save undo information
  setup_undo $SAVE(id) $SAVE(proc) "" \
      "\{edit_draw_item 0 0 \[xform_ids $SAVE(id)\]\}"

  # flag that this canvas has been modified
  is_modified
}


proc create_edit_mark {x y} {

  global cur_c scale COLORS

  set del [expr $scale/3.0]
  $cur_c create rectangle [expr $x - $del] [expr $y - $del] \
      [expr $x + $del] [expr $y + $del] \
      -tags "edit_marker tmp selected" -outline "" -fill $COLORS(selected)
}








