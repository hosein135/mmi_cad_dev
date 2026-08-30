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


# Pops up a window to edit properies of an instance and then deletes
# the old instance and calls a new one.

# bind it to double-click button-1 in make_schematic.tcl
# bind $cur_c <Double-Button-1> {prop_edit_menu %x %y}

# Input x and y should NOT go through canvasx,canvasy commands

proc prop_edit_menu {{x ""} {y ""}} {

  global cur_c cur_s scale DISABLE_CANVAS_EVENT SUE PROC
  global DEFAULT_PROP_MENU_TYPE

  modify_setup

  if {$y == ""} {
    # called from menu
    set menu 1

    set id [find_origin [lindex [$cur_c find withtag selected] 0]]
    if {$id == ""} {
      warning "Aborting, must select something first."
      return
    }

    if {![is_tagged $id draw_item] && ![is_tagged $id origin]} {
      warning "Aborting, must select either an icon or a draw_item (i.e. line, arc, or text)."
      return
    }

    # make this the only selected
    select_id $id

    # get x, y position and convert to screen coords
    setl {x y} [round_list [$cur_c coords $id]]

    setl {x1 y1 x2 y2} [visible_bbox]
    if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
      # off screen, zoom to selected
      zoom_to_selected
      setl {x y} [round_list [$cur_c coords $id]]
    }

    set x [expr 2 * $x - round([$cur_c canvasx $x])]
    set y [expr 2 * $y - round([$cur_c canvasy $y])]

    if {[is_tagged $id draw_item]} {
      # warp cursor to approppriate spot
      warp_cursor [expr [winfo rootx $cur_c] + $x] \
	  [expr [winfo rooty $cur_c] + $y]

      edit_draw_item $x $y $id 1

      set DISABLE_CANVAS_EVENT 0
      return
    }
	
  } else {
    # called from double click
    set menu 0

    set current_id [$cur_c find withtag current]
    set id [find_origin $current_id]

    if {![is_tagged $id origin]} {
      # not an icon
      return
    }
  }

  # stop general canvas binding events
  set DISABLE_CANVAS_EVENT 1

  # make sure it is selected
  if {![is_tagged $id selected]} {
    select_id $id
  }

  # instance-specific data (like W=1.2u) are here
  upvar #0 ${cur_s}_inst$id i_data

  if {![info exists i_data(orient)]} {
    # must be a toasted icon.  Better clean it up
    $cur_c delete inst$id
    catch {i_data}
    return
  }

  set type $i_data(type)
  # instance-generic data (like default L=0.6u) are here
  upvar #0 icon_$type g_data

  set prop_list ""
  foreach name $g_data(prop_names) {
    if {$name == "_BREAK_"} {
      # special case to add a new column into the menu
      lappend prop_list "_BREAK_ {} -break"
      continue
    }

    set choices $g_data(_$name,choices)
    if {$choices != ""} {
      if {[lsearch "popup binary radio choice" [lindex $choices 0]] != -1} {
	# special type
	lappend prop_list [list $name $i_data(_$name) [lindex $choices 0] [lrange $choices 1 end]]
      } else {
	# use the default type
	lappend prop_list [list $name $i_data(_$name) $DEFAULT_PROP_MENU_TYPE $choices]
      }

    } else {
      # no choices
      lappend prop_list [list $name $i_data(_$name)]
    }
  }

  if {$prop_list == ""} {
    if {$menu} {
      # enable general canvas binding events
      set DISABLE_CANVAS_EVENT 0
    }

    return
  }

  set winy [expr [winfo rooty $cur_c] + $y + 50]
  set winx [expr [winfo rootx $cur_c] + $x + 50]
  set message $type
  set title "Edit properties:" 

  # create the menu
  set new_prop_list [prop_menu $winx $winy $message $title $prop_list]
  if {$new_prop_list == "" || $new_prop_list == $prop_list} {
    # empty list means the user hit cancel or nothing changed

    if {$menu} {
      # enable general canvas binding events
      set DISABLE_CANVAS_EVENT 0
    }

    return
  }

  upvar #0 icon_$type g_data
  if {[use_first g_data(_primitive)] != ""} {
    # can't have special characters in terminal names which mostly
    # happen in primitives.
    set name [get_assoc name $new_prop_list]
    if {[regexp {\{|\}} $name]} {
      sue_error "Aborting, can't use curly brackets in name property of \"$type\"."
      sue_error flush
      return
    }
    if {[string index $name [expr [string length $name] -1]] == "\\"} {
      sue_error "Aborting, can't end name property in \"$type\" with a \\."
      sue_error flush
      return
    }
  }

  integer_scale

  # for undo
  set PROC ""
  write_instances inst$id 1 undo
  set proc $PROC

  # store the new values in the data structure
  foreach pair $new_prop_list {
    set name [lindex $pair 0]
    set value [lindex $pair 1]

    set old_name $i_data(_$name)
    set i_data(_$name) $value
  }

  # now remake the icon (this will flag modified)
  set new_id [remake $id $id "" no_scale]
  setup_undo $new_id $proc

  unscale

  # for IOs, update the corresponding icon or schematic if there is one
  # use launch so doesn't flash screen
  launch "reconcile_ios \{$new_id\} \{$old_name\}"

  # flag that this canvas has been modified
  is_modified

  # otherwise, reset by something else???
  if {$menu} {
    # enable general canvas binding events
    set DISABLE_CANVAS_EVENT 0
  }
}


proc generator_edit_menu {{x ""} {y ""}} {

  global cur_c cur_s DISABLE_CANVAS_EVENT SUE_DIR DEFAULT_PROP_MENU_TYPE PROC
  global auto_index

  modify_setup

  if {$y == ""} {
    # called from menu
    set menu 1

    set id [find_origin [lindex [$cur_c find withtag selected] 0]]
    if {$id == "" || ![is_tagged $id origin]} {
      warning "Aborting, must select an icon first."
      return
    }

    # make this the only selected
    select_id $id

    # get x, y position and convert to screen coords
    setl {x y} [round_list [$cur_c coords $id]]

    setl {x1 y1 x2 y2} [visible_bbox]
    if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
      # off screen, zoom to selected
      zoom_to_selected
      setl {x y} [round_list [$cur_c coords $id]]
    }

    set x [expr 2 * $x - round([$cur_c canvasx $x])]
    set y [expr 2 * $y - round([$cur_c canvasy $y])]

  } else {
    # from button
    set menu 0

    set current_id [$cur_c find withtag current]
    set id [find_origin $current_id]

    if {[is_tagged $id origin] != 1} {
      # not an icon
      return
    }
  }

  # stop general canvas binding events
  set DISABLE_CANVAS_EVENT 1

  # instance-specific data (like W=1.2u) are here
  upvar #0 ${cur_s}_inst$id i_data

  set type $i_data(type)
  # instance-generic data (like default L=0.6u) are here
  upvar #0 icon_$type g_data

  # if this isn't a generator, just edit properties
  if {[info exists g_data(generator)] != 1} {
    if {$menu} {
      prop_edit_menu
    } else {
      prop_edit_menu $x $y
    }

    return
  }

  # make sure it and only it is selected
  select_id $id

  # put together the prop list for the prop menu with name at the front.
  set prop_list ""
  foreach pair $g_data(gdefaults) {
    setl {var value choices} $pair
    if {[set pos [lsearch $g_data(gargs) -$var]] != -1} {
      # not defaulted
      set value [lindex $g_data(gargs) [incr pos]]
    }

    if {$choices != ""} {
      if {[lsearch "popup binary radio choice" [lindex $choices 0]] != -1} {
	# special type
	lappend prop_list [list $var $value \
			       [lindex $choices 0] [lrange $choices 1 end]]
      } else {
	# use the default type
	lappend prop_list [list $var $value \
			       $DEFAULT_PROP_MENU_TYPE $choices]
      }
    } else {
      # no choices
      lappend prop_list [list $var $value]
    }
  }

  if {$prop_list == ""} {
    # this should never happen
    if {$menu} {
      # enable general canvas binding events
      set DISABLE_CANVAS_EVENT 0
    }

    return
  }

  set winy [expr [winfo rooty $cur_c] + $y + 50]
  set winx [expr [winfo rootx $cur_c] + $x + 50]
  set title $g_data(generator)
  set message "Edit Generator:" 

  # create the menu
  set new_prop_list [prop_menu $winx $winy $message $title $prop_list]
  if {$new_prop_list == "" || $new_prop_list == $prop_list} {
    # empty list means the user hit cancel or nothing changed

    if {$menu} {
      # enable general canvas binding events
      set DISABLE_CANVAS_EVENT 0
    }

    return
  }

  # save the nondefaulted args
  set gargs ""
  foreach prop $new_prop_list {
    setl {prop_name prop_value} $prop
    # only add to gargs if not defaulted
    if {$prop_value != [get_assoc $prop_name $g_data(gdefaults)]} {
      lappend gargs -$prop_name $prop_value
    }
  }

  # compute the name for this generator with these arguments.
  # first see if the generator has a procedure of the form
  #   NAME_<generator>
  # to execute which returns a name, if so use it, if not
  # concatentate the arguments together to make a unique name.

  set name $g_data(generator)

  # get the default name for this
  if {[use_first auto_index(ICON_$name)] == [use_first auto_index(NAME_$name)] \
	  && ![catch "NAME_$name" msg] && $msg != ""} {
    # worked, got a non-nil name.  This is the default
    set default $msg

  } else {
    set default $g_data(generator)
  }

  # Check that this is the correct NAME proc first
  if {[use_first auto_index(ICON_$name)] == [use_first auto_index(NAME_$name)] \
	  && ![catch "NAME_$name $gargs" msg] && $msg != ""} {
    # worked, got a non-nil name.  Hope it is unique
    set name $msg

  } else {
    # compute
    # root of the new name is the generator name stripped (if possible)
    # by the first argument.
    set first_argument [lindex [lindex $g_data(gdefaults) 0] 1]
    if {[set pos [string last $first_argument $name]] != -1} {
      # make sure this is at the end of the string
      if {[expr $pos + [string length $first_argument]] == \
	      [string length $name]} {
	set name [string range $name 0 [expr $pos - 1]]
      }
    }

    set separator ""
    set stuff ""

    foreach prop $new_prop_list {
      setl {prop_name prop_value} $prop

      # the name is the concatenation of the non-blank or non-zero arguments
      # separated by underscores.
      if {$prop_value != "" && $prop_value != 0} {
	# can't allow weird characters in the name, like spaces or braces
	regsub -all {\{|\}|\ } $prop_value _ string

	if {$string == "_"} {
	  # special case
	  set separator ""
	}

	set name "$name$stuff$separator$string"
	set separator _
	set stuff ""

      } else {
	lappend stuff _
      }
    }

    # special case of demorgan
    if {$prop_value == 1} {
      regsub {_1$} $name _ name
    }
  }

  if {$name == $default && $gargs != ""} {
    # user is trying to change default args without changing generator name
    # which is not allowed
    warning "Aborting, can`t change the default arguments of a generator without changing the name."

    return
  }

  if {$name == $i_data(type)} {
    set button [tk_dialog .generator "Generator Warning" \
		    "Warning, by proceeding you are redefining all occurrences of the icon $name which were made from the generator $g_data(generator)." \
		    @$SUE_DIR/sue_icon.xbm 0 {ok} {cancel}]

    if {$button == 1} {
      # user hit the cancel key
      return
    }
  }

  upvar #0 icon_$name g_data2
  if {[info exists g_data2(gargs)] && $g_data2(gargs) == $gargs} {
    # Hey, this exists already.  Just put the new one in
  } else {
    # generate the new generator
    if {[eval regenerate $g_data(generator) $name $gargs] == 0} {
      # generator errored out
      return
    }  
  }

  # now make the new icon to replace
  set bogus_id [make $name]

  upvar #0 ${cur_s}_inst$bogus_id bogus_i_data

  # get the name and other save properties out of the old_icon
  # and put these properties temporarily into the bogus_id
  foreach prop $g_data(prop_names) {
    if {[info exists i_data(_$prop)]} {
      set bogus_i_data(_$prop) $i_data(_$prop)
    }
  }

  integer_scale

  # for undo
  set PROC ""
  write_instances inst$id 1 undo
  set proc $PROC

  # now replace the current icon (this will flag modified)
  set new_id [remake $id $bogus_id "" no_scale]
  setup_undo $new_id $proc

  unscale

  # very special case.  icon has been modified but doesn't need
  # to be propagated into this canvas
  upvar #0 SUE_$cur_s data
  incr data(icon_index)

  # delete bogus icon and data structures
  $cur_c delete inst$bogus_id
  upvar #0 ${cur_s}_inst$bogus_id i_data
  unset i_data

  # select it
  select_id $new_id
#  unhighlite_selected

  # otherwise, reset by something else???
  if {$menu} {
    # enable general canvas binding events
    set DISABLE_CANVAS_EVENT 0
  }
}
