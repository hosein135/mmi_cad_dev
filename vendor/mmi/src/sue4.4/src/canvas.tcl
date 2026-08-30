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


# Global variables associated with all canvases:
#
# cur_s		name of the current schematic.  For icons it's ICON_<name>
# cur_c 	name of the current canvas: .$WIN.c_$cur_c
# scale		current canvas scale which is also the grid step


# Make a new canvas for a schematic or icon

proc make_canvas {win schematic type} {

  global cur_c cur_s scale COLORS MODIFY_ICON MODIFY_ICON_LEVEL 
  global CURRENT_BINDINGS READ_ONLY

  # default drawing is 10 points for minimum size
  set scale 10

  set cur_s $schematic

  # .c_ insures lowercase first letter
  set cur_c $win.c_$cur_s

  upvar #0 SUE_$cur_s data

  set data(canvas) $cur_c
  set data(scale) $scale
  set data(type) $type

  set data(modified) ""
  set data(modify_icon) ""

  # Set to modified so generate term names runs the first time
  set data(modified_term_names) M

  set data(zoom_to_fit) 0

  set data(locked) ""
  set data(written) ""
  set data(read_only) $READ_ONLY

  set data(bindings) [use_first CURRENT_BINDINGS '0]

  set data(generator) [is_generator $schematic]

  # all icons are up to date as of now
  set data(icon_index) $MODIFY_ICON(_index)
  set data(netlist_icon_index) $MODIFY_ICON(_index)
  set data(netlist_level_index) $MODIFY_ICON_LEVEL(_index)

  # Create the canvas for this schematic
  canvas $cur_c -scrollregion {-1000000 -1000000 1000000 1000000} \
      -width 15c -height 10c -highlightthickness 0 \
      -closeenough 4 -background $COLORS(background) \
      -xscrollincrement -10 -yscrollincrement -10 \
      -confine false

  add_schematic_to_listbox $schematic
}


# pack the current canvas into the given window

proc pack_canvas {{force ""}} {

  global cur_c cur_s CURRENT_BINDINGS WIN __LAUNCH__

  if {$__LAUNCH__ > 0 && $force == ""} {
    # do it later
    return
  }

  upvar #0 SUE_$cur_s data

  pack $cur_c -expand yes -fill both

  possibly_resize

  display_title $WIN

  display_selection

  # check that the bindings are current
  if {$data(bindings) < [use_first CURRENT_BINDINGS '-1]} {
    # get newest bindings
    clear_bindings
    restore_bindings newest

    set data(bindings) $CURRENT_BINDINGS
  }

  update idletasks
  set_scrollbars
}


# unpack the current canvas from the given window

proc unpack_canvas {{force ""}} {
  
  global cur_c cur_s WIN WIN_DATA __LAUNCH__
  upvar #0 SUE_$cur_s data

  # If there is a cancellation command, execute it now
  eval $WIN_DATA($WIN,abort_cmd)
  set WIN_DATA($WIN,abort_cmd) ""

  remember_modified

  leave_canvas

  if {$__LAUNCH__ > 0 && $force == ""} {
    # do it later
    return
  }

  # sometimes things get messed up so we have to insure that
  # we are unpacking something that's packed.  Otherwise, we
  # get two canvases on the screen - not good.
  set slaves [pack slaves $WIN]
  if {[lsearch $slaves $cur_c] != -1} {
    pack forget $cur_c
  } else {
    # problem.  find the slave that is a canvas and unpack it.
    set index [lsearch $slaves $WIN.c_*]
    if {$index != -1} {
      pack forget [lindex $slaves $index]
    }
  }
}


# called whenever a new canvas is packed or if the screen size is changed
# Should eventually size differently depending on whether the top or
# bottom of the window was dragged.

proc possibly_resize {} {

  global cur_c cur_s CANVAS_SIZE WIN

  if {[lsearch [pack slaves $WIN] $cur_c] == -1} {
    # don't bother since not packed
    return
  }

  # special case, never been packed before
  upvar #0 SUE_$cur_s data
  if {$data(zoom_to_fit)} {
    set data(zoom_to_fit) 0
    zoom_to_fit

    return
  }

  if {[bind $cur_c <Configure>] == ""} {
    bind $cur_c <Configure> possibly_resize
    return
  }

  if {[use_first CANVAS_SIZE(processing)] != ""} {
    # already doing this
    return
  }
  set CANVAS_SIZE(processing) 1

  if {[info exists CANVAS_SIZE($cur_c)]} {
    setl {old_width old_height old_rootx old_rooty} $CANVAS_SIZE($cur_c)

#    update

    set width [winfo width $cur_c]
    set height [winfo height $cur_c]

    if {$width != $old_width || $height != $old_height} {
      # the window has been resized
      setl {x1 y1 x2 y2} [visible_bbox]
      set x2 [expr ($x2-$x1) * (1.0*$old_width/$width) + $x1]
      set y2 [expr ($y2-$y1) * (1.0*$old_height/$height) + $y1]

      # zoom the canvas appropriately
      $cur_c create rect $x1 $y1 $x2 $y2 -tags zoom_box

      zoom_to_bbox "$x1 $y1 $x2 $y2" -3
      eval center_canvas [center_bbox [$cur_c bbox zoom_box]]

      # get rid of zoom box tag
      $cur_c delete zoom_box 

      update
      set CANVAS_SIZE($cur_c) [list $width $height]
    }

  } else {
    set CANVAS_SIZE($cur_c) [list [winfo width $cur_c] [winfo height $cur_c] \
				 [winfo rootx $cur_c] [winfo rooty $cur_c]]
  }

  unset CANVAS_SIZE(processing)
}


# if icon has been edited, remember that it has so we can propagate
# into schematics that contains an instance of this icon

proc remember_modified {} {
  
  global cur_c cur_s MODIFY_ICON _MAKE_
  upvar #0 SUE_$cur_s data

  if {$data(type) == "I"} {
    if {$data(modify_icon) == "M"} {
      set schematic [get_rootname $cur_s]

      # remakes procedure for this icon
      write_icon
      # get rid of old compiled versions
      catch {unset _MAKE_($schematic)}
      catch {rename _MAKE_$schematic ""}
      catch {rename _MAKE90_$schematic ""}

      # now make the new icon to recompile and setup data structures
      set bogus_id [make $schematic]
      # delete bogus icon and data structures
      $cur_c delete inst$bogus_id
      upvar #0 ${cur_s}_inst$bogus_id i_data
      catch {unset i_data}

      # store this icon so it will propagate 
      set MODIFY_ICON([incr MODIFY_ICON(_index)]) $schematic

      # unmodify this icon - for this task only
      set data(modify_icon) ""
    }
  }
}


# when entering a canvas set up the current canvas, schematic, scale
# global variables and set the focus to it.

proc enter_canvas {schematic} {

  global cur_c cur_s scale SCROLL
  upvar #0 SUE_$schematic data

  # make sure the auto scrolling is off
  set SCROLL(status) off

  set cur_c $data(canvas)
  set cur_s $schematic
  set scale $data(scale)

  # we are going into this canvas, need to propagate and modified icons now.
  propagate_modified_icons

  update_canvas_state

  focus $cur_c
}


# check to see if we need to propagate any modified icons into the canvas
# of this schematic and if needed, do so.

proc propagate_modified_icons {} {

  global cur_s cur_c MODIFY_ICON ICON_ERROR
  upvar #0 SUE_$cur_s data

  set modified 0
  set updated(_dummy) ""
  if {$MODIFY_ICON(_index) > $data(icon_index)} {
    # propagate through all icons in MODIFY_ICON array
    integer_scale

    for {set i $data(icon_index)} {$i < $MODIFY_ICON(_index)} {} {
      set icon $MODIFY_ICON([incr i])

      if {[info exists updated($icon)]} {
	# already propagated
	continue
      }
	  
      # remember so we don't have to repropagate
      set updated($icon) 1
    
      # don't propagate back into icon
      if {$cur_s == "ICON_$icon"} {
	continue
      }

      set ICON_ERROR ""
      foreach id [$cur_c find withtag icon_$icon] {
	set ICON_ERROR ""
	set id_new [remake $id $id dont_modify no_scale]
	id_undo $id $id_new
	set modified 1
      }

      if {$ICON_ERROR != ""} {
	# error in icon property
	sue_error "SUE ERROR in icon \"$icon\".  Icon not updated.\n\t[join $ICON_ERROR \n\t]"
      }
    }
    
    unscale

    if {$modified} {
      # need to invalidate the TERM_CACHE for dpc
      global TERM_CACHE
      set TERM_CACHE($cur_s,terms) ""
    }

    # update this canvas to know which icons have been propagated
    set data(icon_index) $MODIFY_ICON(_index)
  }

  sue_error flush
}


# updates flags in canvas on entry

proc update_canvas_state {} {

  global cur_c cur_s UPDATE_FLAGS NETLIST_TYPE HIERARCHY


  if {[is_icon $cur_s]} {
    return
  }

  upvar #0 TERMS_$cur_s TERMS
  if {![info exists TERMS]} {
    # not netlisted yet
    return
  }

  if {[use_first UPDATE_FLAGS(__off__)] != "" || \
	  ![info exists UPDATE_FLAGS(__index__)] || \
	  $UPDATE_FLAGS(__index__) == 0} {
    # not active
    return
  }

  if {[info exists UPDATE_FLAGS($cur_c)] && \
	  $UPDATE_FLAGS($cur_c) >= $UPDATE_FLAGS(__index__) && \
	  $UPDATE_FLAGS($cur_c,hierarchy) == $HIERARCHY} {
    # already up-to-date
    return
  }

  # waste any old values
  $cur_c delete tmp

  # update the flags in this canvas
  catch ${NETLIST_TYPE}_update_flags
  if {![info exists UPDATE_FLAGS(__index__)] || $UPDATE_FLAGS(__index__) == 0} {
    # not active
    return
  }

  set UPDATE_FLAGS($cur_c) $UPDATE_FLAGS(__index__)
  set UPDATE_FLAGS($cur_c,hierarchy) $HIERARCHY
}


# when leaving a canvas that contains a modified icon, we need to update
# the world

proc leave_canvas {} {

  global cur_c cur_s

  # unhilites item
  item_leave
}


# called every time you enter a mode like text mode or duplication mode

proc enter_mode {mode {abort_cmd ""}} {

  global cur_c WIN WIN_DATA DISABLE_CANVAS_EVENT

  # If there is a cancellation command, execute it
  eval $WIN_DATA($WIN,abort_cmd)

  # NOTE, NOT CORRECT, zoom is also a mode and some aren't.
  # if this is a read only schematic, don't let user do anything
#  global cur_s
#  upvar #0 icon_$cur_s g_data
#  if {[is_generator $cur_s]} {
#    # read only
#    puts "Aborting, can't modify read-only cell."
#    return 0
#  }

  # stop general canvas binding events
  set DISABLE_CANVAS_EVENT 1

  # set up the abort command for this mode
  set WIN_DATA($WIN,abort_cmd) $abort_cmd

  # save the mode
  set WIN_DATA($WIN,mode) $mode

  # cleans up the screen
  item_leave

  # Save and clear out all default canvas bindings
  save_bindings
  clear_bindings

  # change the cursor to a hand
  ready hand2

  return 1
}


# called every time you leave a mode

proc leave_mode {{mode ""}} {

  global WIN WIN_DATA DISABLE_CANVAS_EVENT

  # since we are leaving normally we can cancel the abort_cmd
  set WIN_DATA($WIN,abort_cmd) ""

  # unsave the mode
  set WIN_DATA($WIN,mode) ""

  # reset the display message
  msg_window ""

  # restore the default canvas bindings
  clear_bindings
  restore_bindings

  # enable general canvas events
  set DISABLE_CANVAS_EVENT 0

  # get rid of this
  catch "unset WIN_DATA($WIN,save_msg)"

  display_selection

  # restore cursor to arrow
  ready
}


# lower selected in display list

proc lower_selected {} {

  global cur_c

  modify_setup

  $cur_c lower selected
  is_modified
}


# returns state of particular canvas
# called by modify_setup (c command)

proc is_read_only {} {

  global cur_s
  upvar #0 SUE_$cur_s data

  return $data(read_only)
}


# This used to be one line but since the color of an ARC is now changed 
# with -outline instead of -fill, it has to be more complicated.

proc show_color {tag color} {

  global cur_c HIDDEN_PROPS

#  $cur_c addtag _fill_ withtag $tag
#  foreach prop $HIDDEN_PROPS {
#    $cur_c dtag prop_$prop _fill_
#  }

#  $cur_c itemconfigure _fill_ -fill $color
  $cur_c itemconfigure $tag -fill $color

  if {[catch "expr $tag"]} {
    $cur_c itemconfigure $tag&arc -outline $color
  } else {
    # tag is an id
    if {[is_tagged $tag arc]} {
      $cur_c itemconfigure $tag -outline $color
    }
  }

#  $cur_c dtag _fill_
}


# highlites what's under the cursor.
# We (used to) use only objects which highlite the same way

proc item_enter {} {

  global cur_c COLORS

  set id [$cur_c find withtag current]
  set tag [find_origin_tag $id]

  if {[is_tagged $id selected]} {
    show_color $tag $COLORS(selected,active)

  } else {
    show_color $tag $COLORS(active)
  } 
}


# unhighlites what was under cursor

proc item_leave {} {

  global cur_c COLORS

  set id [$cur_c find withtag current]
  set tag [find_origin_tag $id]

  if {[is_tagged $id grid] || [is_tagged $id tmp] || [is_tagged $id tmp_all]} {
    if {![is_tagged $id edit_marker]} {
      return
    }
  }

  if {[is_tagged $id selected]} {
    show_color $tag $COLORS(selected)

  } else {
    show_color $tag $COLORS(fore)
  }
}


# unhighlites selected stuff unless it's current

proc unhighlite_selected {} {

  global cur_c COLORS

  set current_id [$cur_c find withtag current]
  set tag [find_origin_tag $current_id]

  show_color selected $COLORS(selected)

  intersect_tag tmp3 $tag selected
  show_color tmp3 $COLORS(selected,active)
  $cur_c dtag tmp3
}


# saves out the mouse and keyboard bindings for the current canvas so
# that a new set of temporary bindings can be entered.  used in conjunction
# with restore_bindings

proc save_bindings {{type save}} {

  global cur_c WIN TAGS_TO_SAVE

  upvar #0 ${WIN}_${type}_bindings bindings

  catch {unset bindings}

  # first save general canvas bindings
  set bind_list [bind $cur_c]
  foreach binding $bind_list {
    set bindings($binding) [bind $cur_c $binding]
  }

  # now save away tag specific bindings
  foreach tag $TAGS_TO_SAVE {

    # save away all canvas bindings for this tag
    set bind_list [$cur_c bind $tag]
    foreach binding $bind_list {
      set bindings($tag,$binding) [$cur_c bind $tag $binding]
    }
  }
}


# restores the default mouse and keyboard bindings
# for the current canvas, which were saved by save_bindings

proc restore_bindings {{type save}} {

  global cur_c WIN TAGS_TO_SAVE

  upvar #0 ${WIN}_${type}_bindings bindings

  # restore everything in the bindings array
  foreach binding [array names bindings] {
    set binding [split $binding ,]

    if {[llength $binding] == 1} {
      # a generic binding
      regsub -all {\{|\}} $binding "" binding
      bind $cur_c $binding $bindings($binding)

    } else {
      # a tag specific bindings
      set tag [lindex $binding 0]
      set bind [lindex $binding 1]
      $cur_c bind $tag $bind $bindings($tag,$bind)
    }
  }
}


# removes all of the bindings associated with the canvas

proc clear_bindings {} {

  global cur_c TAGS_TO_SAVE

  # first clear general canvas bindings
  set bind_list [bind $cur_c]
  foreach binding $bind_list {
    bind $cur_c $binding ""
  }

  # now clear tag specific bindings
  foreach tag $TAGS_TO_SAVE {
    # save away all canvas bindings for this tag
    set bind_list [$cur_c bind $tag]
    foreach binding $bind_list {
      $cur_c bind $tag $binding ""
    }
  }
}


# lists the bindings which are currently saved, cleared, or restored.
# used only for debugging.

proc info_bindings {} {

  global cur_c WIN TAGS_TO_SAVE

  # first general canvas bindings
  set bind_list [bind $cur_c]
  foreach binding $bind_list {
    puts "$WIN $binding bound to: [bind $cur_c $binding]"
  }

  # now restore tag specific bindings
  foreach tag $TAGS_TO_SAVE {
    # save away all canvas bindings for this tag
    set bind_list [$cur_c bind $tag]
    foreach binding $bind_list {
      puts "$WIN $tag $binding bound to: [$cur_c bind $tag $binding]"
    }
  }
}


# changes the state of the current canvas (either schematic of icon) 
# to modified.

proc is_modified {{ignore_gen 0}} {

  global cur_s NETLIST_CACHE AUTO_SAVE TERM_CACHE

  upvar #0 SUE_$cur_s data

  if {$data(generator)} {
    # can't modify generators
    if {!$ignore_gen} {
      warning "Warning, this is a generator: modifications ignored."
    }
    return
  }

  set last $data(modified)

  set data(modified) M
  set data(ever_modified) M
  set data(modify_icon) M
  set data(modified_term_names) M

  if {[is_icon $cur_s]} {
#    set data(netlist_modify_icon) M
  } else {
    # forget cached netlist information if any of schematics
    set NETLIST_CACHE($cur_s) ""
    set TERM_CACHE($cur_s,terms) ""
  }

  # auto-save
  if {[use_first AUTO_SAVE(interval) `0] != 0} {
    # auto-save enabled
    if {[auto_save_data $cur_s schedule] == "schedule"} {
      # already scheduled, do nothing
    } else {
      # schedule
      after [expr int(60000 * $AUTO_SAVE(interval))] "auto_save_write_file $cur_s"
    }
  }

  if {$last != "M"} {
    change_listbox_prefix $cur_s "M "
    display_title
  }
}


# returns the state of the auto save for this schematic/icon.  If
# action is schedule, changes to scheduled but returns previous state.

proc auto_save_data {schematic {action ""}} {

  upvar #0 SUE_$schematic data
  set cell [corresponding_cell $schematic]
  upvar #0 SUE_$cell other_data

  if {$action == "reset"} {
    # unschedule
    catch {unset data(auto_save)}
    catch {unset other_data(auto_save)}
    return
  }

  set result ""
  if {[info exists data(scale)]} {
    # there is a canvas for this
    if {[set result [use_first data(auto_save)]] == "" && \
	    [info exists other_data(scale)]} {
      set result [use_first other_data(auto_save)]
      if {$action != ""} {
	set other_data(auto_save) $action
      }
    } else {
      if {$action != ""} {
	set data(auto_save) $action
      }
    }
  } else {
    # check the other view if there is one
    if {[info exists other_data(scale)]} {
      set result [use_first other_data(auto_save)]
      if {$action != ""} {
	set other_data(auto_save) $action
      }
    }
  }

  return $result
}


# this procedure will reset the modification of either a schematic or an icon

proc not_modified {name} {

  global SUE_$name

  change_listbox_prefix $name "  "

  set SUE_${name}(modified) ""

  display_title
}


# tries to undo the last command to the current schematic

proc undo_last {{mode ""}} {

  global cur_s MODIFY

  modify_setup

  if {[info exists MODIFY($cur_s)] == 1 && $MODIFY($cur_s) != ""} {
    busy

    if {$mode != "quiet"} {
      puts "Undoing ..."
    }

    set unmodify [lindex $MODIFY($cur_s) 0] 
    set MODIFY($cur_s) [lrange $MODIFY($cur_s) 1 end]

#    puts [info body $unmodify]

    # do the undo by executing this procedure
    $unmodify

    # now undefine the procedure
    rename $unmodify ""

    # undoing modifies the cell, too
    is_modified

    ready

  } else {
    warning "Nothing to undo in this cell."
  }
}


# renames the command called undo that was just created to undo the last
# modification and then remembers it for undo_last.
# Only remembers up to UNDO_LEVEL things per schematic.

proc save_undo {} {

  global cur_s MODIFY undo_index UNDO_LEVEL

  if {[info exists undo_index] != 1} {
    set undo_index 0
  }

  set new_undo_name SUE_UNDO_[incr undo_index]
  rename undo $new_undo_name

  if {[info exists MODIFY($cur_s)]} {
    set MODIFY($cur_s) "$new_undo_name $MODIFY($cur_s)"
  } else {
    set MODIFY($cur_s) $new_undo_name
  }

  if {[llength $MODIFY($cur_s)] > $UNDO_LEVEL} {
    # undefine the oldest undo proc and remove from undo list
    rename [lindex $MODIFY($cur_s) $UNDO_LEVEL] ""
    set MODIFY($cur_s) [lrange $MODIFY($cur_s) 0 [expr $UNDO_LEVEL - 1]]
  }
}


# make a property hidden from display
# NOT USED

proc hidden_prop_popup {} {
  
  global HIDDEN_PROPS _PROP_TYPES_

  set message "Toggle Hidden Properties: "
  set title "Visible Properties:"

  set prop_list ""

  foreach prop [array names _PROP_TYPES_] {
    set value_$prop [expr [lsearch $HIDDEN_PROPS $prop] == -1]
    set save_$prop [set value_$prop]
    lappend prop_list [list $prop value_$prop binary] \
  }

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  foreach prop [array names _PROP_TYPES_] {
    if {[set value_$prop] != [set save_$prop]} {
      # first remove from list if there
      set index [lsearch $HIDDEN_PROPS $prop]
      if {$index != -1} {
	set HIDDEN_PROPS [lreplace $HIDDEN_PROPS $index $index]
      }

      # changed
      if {[set value_$prop] == 0} {
	lappend HIDDEN_PROPS $prop
	toggle_hidden_prop $prop hidden
	puts "Property \"$prop\" changed to hidden."

      } else {
	toggle_hidden_prop $prop visible
	puts "Property \"$prop\" changed to visible."
      }
    }
  }
}


proc toggle_hidden_prop {prop {what hidden}} {

  global cur_c scale COLORS FONT

  if {$what == "hidden"} {
    # make hidden
    $cur_c itemconfigure prop_$prop -fill ""
#    $cur_c itemconfigure prop_$prop -font $FONT(small,0)

  } else {
    # make visible
    show_color icon $COLORS(fore)
    show_color icon&selected $COLORS(selected)

#    set fscale [expr int(ceil($scale))]
#    $cur_c itemconfigure size_small&prop_$prop -font $FONT(small,$fscale)
#    $cur_c itemconfigure size_standard&prop_$prop -font $FONT(standard,$fscale)
#    $cur_c itemconfigure size_large&prop_$prop -font $FONT(large,$fscale)

    # TODO: will turn on a prop if both visible and hidden -- inconsistent
  }
}
