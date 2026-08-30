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

set RCSVERSION(paint.tcl) { $Revision: 1.11 $ }


proc paint_add {} -desc {
  Paint cursor into box, bound to mouse button 3
} -doc {
  If the mouse is over any visible layers, then
  paint box with selectable layers (paint and labels) under the mouse,
  otherwise erase selectable layers (paint and labels) not under mouse.
  TODO: This does nothing to polygons.
} {
  setl {x y} [layt_point exact]

  # Only consider visible layers under the mouse click, when
  # deciding whether to add or remove paint.
  # When we go to actually add/remove the paint, though, we
  # will further restrict ourselves to selectable layers.
  set curs_layers ""
  set visible [dbt_visible_layers]
  foreach layer [db_search touchingtypes $x $y] {
    # Do not erase sub-cells with mouse button-3.
    if {[lsearch $visible $layer] != -1 && $layer != "subcell"} {
      lappend curs_layers $layer
    }
  }

  if { $curs_layers == "" } {
    # No visible layers were under the mouse cursor.
    # Erase any selectable layers under cursor

    # Selectable layers does not include any non-visible layers (except subcell)
    set selectable [lremove [dbt_selectable_layers] subcell]
    if { $selectable != "" } {
      # Erase paint and labels on selectable layers.
      :erase [join $selectable ","]
    }
    # Would like to erase space labels separately, but:
    # Layer "space" does not work in :erase if specified with anything else!!!!
    # Also, :erase space erases all layers under the box!
  } else {
    # Paint selectable layers under cursor.
    set selectable [lremove [dbt_selectable_layers] subcell]
    set paint_layers ""
    foreach layer $selectable {
      if { [lsearch $curs_layers $layer] != -1} {
	lappend paint_layers $layer
      }
    }
    # The paint_layers will be empty if nothing is selectable,
    # and :paint will croak.
    if { $paint_layers != "" } {
      # Note: this join is actually not necessary.
      # :paint allows space char to separate layer names.
      :paint [join $paint_layers ","]
    }
  }
}

proc paint_erase {{layer ""}} -desc {
  delete selectable layers (paint and labels) under the cursor from box
} -doc {
  If no <layer> specified, erase the selectable layers under the mouse.

  Clears the selection as a side effect.
} {

  if { $layer != "" } {
    set erase_layers $layer
  } else {
    setl {x y} [layt_point exact]
    set layers [db_search touchingtypes $x $y]
    set selectable [lremove [dbt_selectable_layers] subcell]

    # We erase labels on any selectable layer.
    # And always erase labels on "space".
    set erase_layers ""
    foreach layer $layers {
      # Do not erase sub-cells with mouse button-3.
      if {[lsearch $selectable $layer] != -1} {
	lappend erase_layers $layer
      }
    }
  }

  # Erase both from selected group and from group 0.
  # Layer "space" does not work in :erase if specified with anything else!!!!
  db_group selected
  :erase $erase_layers
  # 8/00: NO! DONT DO IT!  BAD BUG!
  # :erase space erases all layers under the box!
  #:erase space
  db_group 0
  :erase $erase_layers
  #:erase space
}


proc _rect_mode_define {} {
    mode_def rect _rect_gate_keeper "BUT-1 starts rectangle. CTRL-c aborts."

    mode_bind -cmd 0 -desc "drag out a rectangle" rect <Any-Button-1> _rect_start
    mode_bind -cmd 0 rect <Any-B1-Motion> _rect_drag
    mode_bind -cmd 0 rect <Any-B1-ButtonRelease> _rect_end
    mode_bind -cmd 0 rect <Button-2> _rect_move \
	-desc "move selected (if nothing selected move/resize box)"
}

proc _rect_move {} {
    if { [sel_what paint] != ""} {
	move_something_mode_enter
    }
}


proc _rect_start {} {
    global RECTMODE
    sel_clear
    setl {RECTMODE(x) RECTMODE(y)} [layt_point user]
}

proc _rect_gate_keeper {event} -desc {
    called whenever rect mode is entered/exited
} -doc {
    The variable TOOL_BAR(persistent), if set, causes us to stay
    in rect mode forever, until someone else does a mode_pop, 
    (by selecting a different mode from the tool_bar) or types Ctrl-C.
    Why?  So we can keep the current rectangle in a separate group,
    so the user can draw a rectangle and then move it without
    blowing away existing paint.
} {
    global PAL RECTMODE mode_abort

    # We need all four events defined because we mode_push move.
    if {$event == "PUSH_TO" || $event == "POP_TO" } {
        set PAL(button2) "tool_bar_set_layer rect"
        set PAL(button3) "tool_bar_set_layer rect"

    } elseif {$event == "POP_FROM" || $event == "PUSH_FROM" } {
	# Dont want to transfer to group 0 if we are PUSHING_FROM to move mode.
	catch { unset PAL(button2) }
	catch { unset PAL(button3) }
    }
    if { $event == "POP_FROM" } {
	if { $mode_abort } {
	    undo_to_delim
	    undo_flush_redo
	    msg "aborting rectangle!\n"
	} else {
	    # Transfer the rect to group 0
	    #sel_group_transfer 0
	    # Deselect it.  Why?  Because if the user stayed in rect
	    # mode he could move the rect without affecting other paint.
	    # Now that we are leaving rect mode, it is just paint again.
	    # I want the user to have to reselect it (which may change
	    # the box size, too, to incorporate paint all around)
	    # so the user will realize its a different mode, and moving
	    # it again will affect previously existing underlying paint.
	    #select_q clear
	}
	db_group 0
	i_cmd_between
    }
}

proc _rect_drag {} -desc {
  drags out a rectangle interactively
} {
    global RECTMODE
    pan_auto _rect_drag
      
    setl {x y} [layt_point user]
    if {$x == "" || $y == ""} {
	# off screen
	return
    }
    layt_box user $RECTMODE(x) $RECTMODE(y) $x $y
    box_msg_update
}


proc _rect_end {} -desc {
  finishes draging out a rectangle and paints it
} {
    global RECTMODE TOOL_BAR

    setl {x2 y2} [layt_point user]

    layt_box user $RECTMODE(x) $RECTMODE(y) $x2 $y2
    if { [set layer $TOOL_BAR(layer)] == "auto" } {
	# Prefer a wiring layer.  If none, use any visible layer.
	set layer [wire_default_layer]
	if { $layer == "" } {
	    set layer [lindex [dbt_visible_layers] 0]
	}
    }
    global MAX_NEW_SELECT
    if { [use_first MAX_NEW_SELECT] == 1} {
	db_group selected
    }
    :paint $layer
    # Paint is not selected when it is painted!  So select it.
    sel_area -no_poly -no_wp -group -layers $layer \
	$RECTMODE(x) $RECTMODE(y) $x2 $y2
    # TODO: THIS CRASHES!!!!
    #select_q -g -editOnly area $layer
    #:select -g -editOnly area $layer
    db_group 0

    if { ! $TOOL_BAR(persistent) } {
        mode_pop
    }
}

proc _paint_dots {{options ""}} -desc {
  put mouse grab dots around the box.
} {
    lay_dot -tag rect_mode -clear
    if { $options == "-clear" } { return }

    setl {x1 y1 x2 y2} [layt_box exact]
    # Corners
    lay_dot -diameter 8 -tag rect_mode $x1 $y1
    lay_dot -diameter 8 -tag rect_mode $x1 $y2
    lay_dot -diameter 8 -tag rect_mode $x2 $y1
    lay_dot -diameter 8 -tag rect_mode $x2 $y2

    # Center of edges
    set cx [uusnap [expr ($x1 + $x2) / 2.0]]
    set cy [uusnap [expr ($y1 + $y2) / 2.0]]
    lay_dot -diameter 8 -tag rect_mode $x1 $cy
    lay_dot -diameter 8 -tag rect_mode $x2 $cy
    lay_dot -diameter 8 -tag rect_mode $cx $y1
    lay_dot -diameter 8 -tag rect_mode $cx $y2
}


proc paint_edit_mode_enter {} -desc {
  edit the selected paint: set up and enter paint_edit mode.
} {
    global PAINT_EDIT

    # NOT IMPLEMENTED YET!
    # There was something wrong with undo, instead of debug,
    # I hacked it out for the 3.0 release.
    global MAX_EDIT_PAINT
    if { [use_first MAX_EDIT_PAINT] != 1} {
	warning "can not edit paint this way"
	return
    }

    set paintballs [sel_what paint]

    if { $paintballs == "" } {
	max_error "paint_edit_mode_enter: error: no paint selected to edit"
	return
    }

    # for now, just pick the first one...
    struct max_paint p [lindex [split $paintballs "\n"] 0]

    set PAINT_EDIT(layer) ${p.layer}

    # Put the box around it and draw circles for the grab points.
    layt_box exact ${p.x1} ${p.y1} ${p.x2} ${p.y2}
    _paint_dots

    mode_push paint_edit
}

proc paint_edit_props {} {
    global GRID
    set paintballs [sel_what_l paint]
    if { [llength $paintballs] == 0 } {
	max_error "paint_edit_props: error: no paint selected to edit"
	return
    }

    # for now, just pick the first one...
    struct max_paint p [lindex $paintballs 0]

    set oldrect [list ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
    # Select it both to show it and to get the attached labels for later.
    eval sel_area -no_tiles -no_poly -layers ${p.layer} $oldrect
    eval layt_box exact $oldrect

    setl {xbot ybot xtop ytop} $oldrect
    set width [expr $xtop - $xbot]
    set height [expr $ytop - $ybot]
    set layer [dbt_short_name ${p.layer}]

    set pos_props "-number 0 100000 -incr [res -mask] \
	    -width 10 -validate"
    set num_props "-number -100000 100000 -incr [res -mask] \
	    -width 10 -validate"

    set prop_list  ""
    lappend prop_list "x_lower_left xbot $num_props -snap [res -userx]"
    lappend prop_list "y_lower_left ybot $num_props -snap [res -usery]"
    lappend prop_list "width  width  $pos_props -snap [res -userx]"
    lappend prop_list "height height $pos_props -snap [res -usery]" 
    lappend prop_list "layer layer -popup {[pal_layers]}"

  # popup window
  set title "Rectangle Properties"
  set message "Edit the rectangle properties:" 
  set ret [prop_menu2 -message $message -title $title $prop_list]

  if {$ret == 0} {
    # user hit cancel
    return
  }

  # Oldrect is the old paint blob location.
  # Newrect is the new paint blob location.
  set newrect [list $xbot $ybot [expr $xbot+$width] [expr $ybot+$height]]

  _paint_change ${p.layer} $oldrect $layer $newrect
}


proc _paint_change {oldlayer oldrect newlayer newrect} -desc {
  Change paint location and/or layer, preserving labels.
} -doc {
  Also select the new paint location, and move box.
  Caller is responsible for making newrect divisible by grid.
} {

  # Erase old.  selection and box hasnt moved
  eval sel_area -no_wp -no_poly -layers $oldlayer $oldrect
  set labels [sel_what_l labels]
  # This erases labels, too.
  eval layt_box exact $oldrect
  :erase $oldlayer

  # Paint new.
  eval layt_box exact $newrect
  :paint $newlayer

  # Restore labels that were toasted; put them on new layer
  # if inside it.
  foreach label $labels {
    struct max_label l $label
    # If label is inside new paint area, just change its layer.
    if {[rect_inside_rect [list ${l.x1} ${l.y1} ${l.x2} ${l.y2}] $newrect]} {
      # Change label layer
      db_label -kind ${l.kind} -pos ${l.pos} \
	$newlayer ${l.text} ${l.x1} ${l.y1} ${l.x2} ${l.y2}
    } else {
      # Label is not covered by new paint.  Try to find a new location for it.
      # If paint blob was moved, try to preserve relative location.
      struct rect nr $newrect
      struct rect or $oldrect
      set offsetx [expr ${nr.x1} - ${or.x1}]
      set offsety [expr ${nr.y1} - ${or.y1}]
      set x1 [expr ${l.x1} + $offsetx]
      set y1 [expr ${l.y1} + $offsety]
      set x2 [expr ${l.x2} + $offsetx]
      set y2 [expr ${l.y2} + $offsety]
      if {[rect_inside_rect [list $x1 $y1 $x2 $y2] $newrect]} {
	db_label -kind ${l.kind} -pos ${l.pos} \
	  $newlayer ${l.text} $x1 $y1 $x2 $y2
      } elseif {[approx ${l.x1} == ${l.x2}] && [approx ${l.y1} == ${l.y2}]} {
	# It is a point label (not a box):
	# Put it in the center of the new paint.
	setl {x y} [eval center_coords $newrect]
	db_label -kind ${l.kind} -pos ${l.pos} $newlayer ${l.text} $x $y
      } else {
	# Its a box label, what to do?  Give up.
	db_label -kind ${l.kind} -pos ${l.pos} \
	  $newlayer ${l.text} ${l.x1} ${l.y1} ${l.x2} ${l.y2}
	msg "Warning: label ${l.text} no longer entirely covered by paint\n"
      }
    }
  }

  # And re-select it
  eval sel_area -layer $newlayer $newrect
  eval layt_box exact $newrect
}


proc _paint_edit_start {} {
  global PAINT_EDIT

  if { $PAINT_EDIT(state) == 0 } {
    setl {x y} [layt_point exact]
    if {$x == "" || $y == ""} {
	# off screen
	return
    }
    set transform [box_get_nearest_side $x $y [layt_box exact] 1 1]
    # If not near a border, punt.
    if { $transform == "0 0 0 0" } { return }

    set PAINT_EDIT(transform) $transform

    # Change the cursor.
    set PAINT_EDIT(state) 1
    box_set_move_cursor $PAINT_EDIT(transform)
  }
}

proc _paint_edit_move {} {
  global PAINT_EDIT
  _paint_dots -clear
  move_something_mode_enter
}

# This is called only from within paint_edit mode.
# To edit properties from elsewhere, use paint_edit_props.
proc _paint_edit_edit_props {} -desc {
    Edit rectangle properties
} {
  mode_pop
  paint_edit_props
  paint_edit_mode_enter
}


proc _paint_edit_mode_define {} {
  mode_def paint_edit _paint_edit_gate_keeper \
      "BUT-1 starts rectangle. CTRL-c aborts."

  mode_bind -cmd 0 paint_edit <Any-Button-1> _paint_edit_start
  mode_bind -cmd 0 paint_edit <Any-B1-Motion> _paint_edit_drag
  mode_bind -cmd 0 paint_edit <Any-Button-2> _paint_edit_move
  mode_bind -cmd 0 paint_edit p _paint_edit_edit_props
  mode_bind -cmd 0 paint_edit <Any-B1-ButtonRelease> _paint_edit_end
  mode_bind -cmd 0 paint_edit <Any-Button-3> mode_pop
}

proc _paint_edit_drag {} {
  global PAINT_EDIT

  if { $PAINT_EDIT(state) == 0 } {
      # Not dragging the box
      return
  }

  pan_auto _paint_edit_drag

  setl {x y} [layt_point user]
  if {$x == "" || $y == ""} {
      # off screen
      return
  }

  # get the old box
  setl {x1 y1 x2 y2} [layt_box exact]

  # compute the new box: nx1 ny1 nx2 ny2
  # Dont let any dimension become smaller than res.
  setl {nx1 ny1 nx2 ny2} [layt_box user]
  setl {tx1 ty1 tx2 ty2} $PAINT_EDIT(transform)
  if { $tx1 } { set nx1 [min $x [expr $x2-[res -userx]]] }
  if { $tx2 } { set nx2 [max $x [expr $x1+[res -userx]]] }
  if { $ty1 } { set ny1 [min $y [expr $y2-[res -usery]]] }
  if { $ty2 } { set ny2 [max $y [expr $y1+[res -usery]]] }

  #set nx1 [expr $x1 + $tx1*($x-$x1)]
  #set ny1 [expr $y1 + $ty1*($x-$x2)]
  #set nx2 [expr $x2 + $tx2*($y-$y1)]
  #set ny2 [expr $y2 + $ty2*($y-$y2)]

  # Erase paint in old box.  Also reselects it and moves box.
  _paint_change $PAINT_EDIT(layer) [list $x1 $y1 $x2 $y2] \
      $PAINT_EDIT(layer) [list $nx1 $ny1 $nx2 $ny2]

  # Update box status window
  box_msg_update

  # Put dots around it.
  _paint_dots
}

proc _paint_edit_end {} {
  global PAINT_EDIT
  set PAINT_EDIT(state) 0
  # Switch back to mode cursor.
  cursor_mode 1
}

proc _paint_change_layer {newlayer} {
  global PAINT_EDIT
  set box [layt_box exact]
  _paint_change $PAINT_EDIT(layer) $box $newlayer $box
  set PAINT_EDIT(layer) $newlayer
  eval sel_area -layer $PAINT_EDIT(layer) [layt_box exact]
}


proc _paint_edit_gate_keeper {event} {
  global mode_abort PAINT_EDIT PAL

  if {$event == "PUSH_TO"} {
      # pan screws up picking layer from palette.
      #pan_enable
      set PAINT_EDIT(state) 0
      set PAL(button3) "_paint_change_layer paint_edit"

  } elseif {$event == "POP_FROM"} {
      #pan_disable
      _paint_dots -clear
      catch {unset PAL(button3)}

      if { $mode_abort } {
	  undo_to_delim
	  undo_flush_redo
	  msg "aborting edit paint!\n"
      }
      i_cmd_between
  } elseif {$event == "POP_TO" } {
      # Returning from move mode.
      _paint_dots
  }
}
