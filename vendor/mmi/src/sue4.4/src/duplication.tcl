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


# duplicates selected objects.
# A special mode will duplicate text only, including what is in icons.

proc setup_duplicate_selected {{mode duplicate}} {

  global cur_c scale SNAP_XY SAVE

  modify_setup

  # check to see if anything is selected
  if {[$cur_c find withtag selected] == "" && $mode != "verilog"} {
    return
  }

  enter_mode duplication abort_duplication

  msg_window "Button moves duplicates, release Button ends, Ctrl-c aborts"   

  catch {unset SAVE}

  set SAVE(ids) [$cur_c find withtag selected]
  set SAVE(skip) 0

  set cursor [busy]

  integer_scale

  if {$mode == "text"} {
    set ids [duplicate_text]
  } elseif {$mode == "verilog"} {
    select_ids ""
    set ids [create_verilog_property]
  } else {
    set ids [duplicate_selected]
  }

  unscale

  ready $cursor

  # was anything duplicated, if not punt.
  if {[$cur_c find withtag selected] == "" || $ids == ""} {
    abort_duplication
    ready
    return
  }

  # remember undo stuff
  setup_undo $ids ""

  # offset it a little to show it was duplicated
  # later we can do the macdraw hack here
  $cur_c move selected [expr $scale * 2] [expr $scale * 2]

  # set this again since the selection resets it
  msg_window "Button moves duplicates, release Button ends, Ctrl-c aborts"   

  # create new bindings for canvas so that the user can place the items
  bind_add -mode duplication -hotkey Any-Button \
      -command "start_drag_duplication $SNAP_XY" \
      -help "Move duplicated (selected) items."

  bind_add -mode duplication -hotkey Control-c \
      -command "abort_duplication" \
      -help "Abort duplication, removing duplicates."

  bind_add -mode duplication -hotkey space -command "help_window %x %y" \
      -help "Display this window."
}


# duplicates all instances, wires, lines, arcs, and text

proc duplicate_selected {} {

  global cur_c scale COLORS PROC

  set PROC ""

  write_instances selected 1
  write_wires selected
  write_draw_items selected

  # remake each line in proc
  set ids ""
  foreach line $PROC {
    # add an element and save id
    lappend ids [eval $line]
  }

  unset PROC

  select_ids $ids

  return $ids
}


# duplicates all text that is selected, including turning text associated with
# an icon into regular text.  Changes all text to normal size with left anchor.

proc duplicate_text {} {

  global cur_c scale COLORS PROC ROTATE_TEXT

  set PROC ""

  foreach id [$cur_c find withtag selected] {
    if {[$cur_c type $id] == "text"} {
      set text [$cur_c itemcget $id -text]
      if {$text == ""} {
	# toss turds
	continue
      }
      set origin [round_list_scale [$cur_c coords $id] $scale]

      set origin_id [find_origin $id]
      if {[is_tagged $origin_id icon_input] || \
	      [is_tagged $origin_id icon_output]} {
	set opposite 1
      } else {
	set opposite ""
      }

      if {$ROTATE_TEXT && [$cur_c itemcget $id -rotate] == 1} {
	set rotate " -rotate 1"
      } else {
	set rotate ""
      }

      lappend PROC "  make_text -origin [list $origin] -text [list $text][text_anchor $id $opposite]$rotate"
    }
  }

  # remake each line in proc
  set ids ""
  foreach line $PROC {
    # add an element and save id
    lappend ids [eval $line]
  }

  unset PROC

  select_ids $ids

  return $ids
}


proc start_drag_duplication {x y} {

  global cur_c scale SAVE SNAP_XY

  msg_window "Drag selected, Shift Constrains to V or H, Release Button to end, Ctrl-c aborts"   

  set SAVE(x) $x
  set SAVE(y) $y

  # for constrained moves (remember actual start location)
  set SAVE(origx) [expr $x - 2 * $scale]
  set SAVE(origy) [expr $y - 2 * $scale]

  # create new bindings for canvas so that the user can place the items
  bind $cur_c <Any-Button> ""

  bind_add -mode duplication -hotkey Any-Motion \
      -command "drag_duplication $SNAP_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Move selected."

  bind_add -mode duplication -hotkey Any-Shift-Motion \
      -command "drag_duplication $SNAP_XY constrain; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Move selected, constrained to either horizontal or vertical."

  bind_add -mode duplication -hotkey Any-ButtonRelease \
      -command "end_duplication; set SCROLL(status) off" \
      -help "End moving selected."

  bind_add -mode duplication -hotkey Any-Control-c \
      -command "abort_duplication; set SCROLL(status) off" \
      -help "Abort mode"

  bind_add -mode duplication -hotkey z \
      -command "drag_dup_zoom $SNAP_XY 1.5" \
      -help "Zoom in on cursor."

  bind_add -mode duplication -hotkey Z \
      -command "drag_dup_zoom $SNAP_XY 0.7" \
      -help "Zoom out on cursor."
}


# drag_duplication moves the duplicate items

proc drag_duplication {x y {constrain ""}} {

  global cur_c SAVE

  if {$SAVE(skip)} {
    return
  }

  if {$constrain != ""} {
    # constrained
    if {[expr abs($x - $SAVE(origx))] > [expr abs($y - $SAVE(origy))]} {
      set y $SAVE(origy)
    } else {
      set x $SAVE(origx)
    }
  }

  # move the duplicate stuff
  $cur_c move selected [expr $x-$SAVE(x)] [expr $y-$SAVE(y)]

  set SAVE(x) $x
  set SAVE(y) $y
}


proc drag_dup_zoom {x y {zoom ""}} {

  global SAVE scale

  set save_scale $scale

  # turn off movement
  set SAVE(skip) 1

  eval zoom_on_cursor $x $y $zoom doit

  set mult [expr 1.0 * $scale / $save_scale]

  # fix up
  set SAVE(x) [scale_list $SAVE(x) $mult]
  set SAVE(y) [scale_list $SAVE(y) $mult]
  set SAVE(origx) [scale_list $SAVE(origx) $mult]
  set SAVE(origy) [scale_list $SAVE(origy) $mult]

  # turn back on
  set SAVE(skip) 0
}


# abort_duplication removes the new event bindings and returns the
# drawing state to general and destroys the duplication box

proc abort_duplication {} {

  global cur_c SAVE

  # delete the duplicate things
  $cur_c delete selected

  # select the previously selected ids again
  select_ids [use_first SAVE(ids)]

  leave_mode duplication
}


# ends duplication

proc end_duplication {} {

  global cur_s

  busy

  # show connection info on new icon unless we are in an icon
  if {![is_icon $cur_s] && ![is_placement $cur_s]} {
    integer_scale

    # shows connection info of newly created stuff
    show_connects selected

    unscale
  }

  # flag that this canvas has been modified
  is_modified

  leave_mode duplication
  ready
}


proc setup_paste_mode {} {

  global cur_c scale SNAP_XY SAVE CLIPBOARD_FILE

  modify_setup

  if {![file readable $CLIPBOARD_FILE] == ""} {
    puts "Nothing to paste."
    return
  }

  enter_mode duplication abort_duplication

  set cursor [busy]

  catch {unset SAVE}

  set all [$cur_c find all]

  set SAVE(ids) [$cur_c find withtag selected]
  set SAVE(skip) 0

  # deselect everything
  select_ids ""

  source $CLIPBOARD_FILE

  # move into center of screen

  # find center of paste stuff
  set bbox [$cur_c bbox selected]
  if {$bbox == ""} {
    # nothing pasted, punt
    abort_duplication
    ready
    return
  }

  set x [expr int(([lindex $bbox 2] + [lindex $bbox 0])/(2 * $scale)) * $scale]
  set y [expr int(([lindex $bbox 3] + [lindex $bbox 1])/(2 * $scale)) * $scale]

  # get the center of the visible screen
  setl {xcenter ycenter} [center_bbox [visible_bbox]]

  # now move it
  $cur_c move selected [expr $scale * int(($xcenter - $x) / $scale)] \
      [expr $scale * int(($ycenter - $y) / $scale)]

  # if the pasted object doesn't fit on the screen, zoom out to make it fit
  setl {x1 y1 x2 y2} [$cur_c bbox selected]
  setl {vx1 vy1 vx2 vy2} [visible_bbox]
  if {[expr $x2-$x1]>[expr $vx2-$vx1] || [expr $y2-$y1]>[expr $vy2-$vy1]} {
    zoom_to_bbox [$cur_c bbox selected]
    eval center_canvas [center_bbox [$cur_c bbox selected]]
  }

  ready $cursor

  if {$all == ""} {
    # empty schematic, user doesn't need to move pasted
    end_duplication
    return
  }

  # create new bindings for canvas so that the user can place the items
  bind_add -mode duplication -hotkey Any-Button \
      -command "start_drag_duplication $SNAP_XY" \
      -help "Move pasted (selected) items."

  bind_add -mode duplication -hotkey Control-c \
      -command "abort_duplication" \
      -help "Abort paste, removing pastes."

  bind_add -mode duplication -hotkey space -command "help_window %x %y" \
      -help "Display this window."


  # set this again since the selection resets it
  msg_window "Button moves pasted, release Button ends, Ctrl-c aborts"   
}


# Display paths in text fields either in an editor or a browser, depending
# on whether they are prefixed with either file: or html:.  Can use relative
# paths (it is advised that the user does).

proc display_file {} {

  global cur_c cur_s DEFAULT_EDITOR env SUFFIX SUE_DIR auto_index

  busy

  set file_paths ""
  set html_paths ""

  global SUE_$cur_s
  set name [get_rootname $cur_s]

  if {[is_generator $name]} {
    # special case for generator, use the generator path
    upvar #0 icon_$name g_data
    set name [use_first g_data(generator) name]
    set dir [file dirname [lindex [use_first auto_index(ICON_$name)] 1]]

    set file [clean_dir $name$SUFFIX(cell_doc_html) $dir]
    if {[file exists $file]} {
      set html_paths $file
    } else {
      set file [clean_dir $name$SUFFIX(cell_doc_text) $dir]
      if {[file exists $file]} {
	set file_paths $file
      }
    }

  } else {
    # first look for default paths
    set dir [string trimright [set SUE_${cur_s}(dir)] /]

    set file [clean_dir $name$SUFFIX(cell_doc_html) $dir]
    if {[file exists $file]} {
      set html_paths $file
    } else {
      set file [clean_dir $name$SUFFIX(cell_doc_text) $dir]
      if {[file exists $file]} {
	set file_paths $file
      }
    }
  }

  # search for text that might contain paths
  foreach id [get_intersect_tag draw_item scaletext] {
    set text [$cur_c itemcget $id -text]

    set index [string first "file:" $text]
    if {$index != -1} {
      set path [lindex [split [string range $text [expr $index + 5] \
					     end] " )\}\]"] 0]
      lappend file_paths [clean_dir $path $dir]
    }
    set index [string first "html:" $text]
    if {$index != -1} {
      set path [lindex [split [string range $text [expr $index + 5] \
					     end] " )\}\]"] 0]
      lappend html_paths [clean_dir $path $dir]
    }
  }

  if {$file_paths == "" && $html_paths == ""} {
    # create a doc file
    set winy [expr [winfo rooty $cur_c] + 50]
    set winx [expr [winfo rootx $cur_c] + 50]
    set title "Can't find doc file"
    set message "Create new doc file for \"$name\" using"
    set prop_list [list [list path $file]]

    # create the menu
    set new_prop_list [prop_menu $winx $winy $message $title $prop_list]
    if {$new_prop_list == ""} {
      # empty list means the user hit cancel
      ready
      return
    }

    set path [lindex [lindex $new_prop_list 0] 1]

    if {[file exists $path]} {
      # Uh Oh, this file already esists, query user.
      set button [tk_dialog .edit_doc "Edit documentation" \
		      "File $path already exists." \
		      @$SUE_DIR/sue_icon.xbm 0 {Use} {overwrite} {cancel}]
      
      if {$button == 2} {
	# user hit the cancel key
	ready
	return
      }
      if {$button == 0} {
	# use the existing file
	set editor [use_first env(EDITOR) DEFAULT_EDITOR]

	# special case for vi, need to put into a window
	if {[regexp -nocase {([a-z/._-]*vi[a-z/._-]*)} $editor match]} {
	  set editor "xterm -e $match"
	}

	puts "running \"$editor\" with $path ..."
	eval exec $editor $path &
	ready
	return
      }
    }

    if {[file extension $path] == $SUFFIX(cell_doc_html)} {
      # for html, simple stuff to get you going
      set header "Documentation for $name\n\n"
#      set header "<title> Documentation $name \</title\>\\\n\\\n\<h2\>Add Heading Here \</h2\>\\\n\<pre\>\\\nadd text here\\\n\</pre\>"
    } else {
      set header "Documentation for $name\n\n"
    }

    # create the file
    if {[catch "exec echo \"$header\" > $path" msg] != 0} {
      # error, probably can't write to directory
      sue_error "Aborting. $msg"
      sue_error flush
      ready
      return
    }

    set file_paths $path
  }

  if {$file_paths != ""} {
    set editor [use_first env(EDITOR) DEFAULT_EDITOR]

    # special case for vi, need to put into a window
    if {[regexp -nocase {([a-z/._-]*vi[a-z/._-]*)} $editor match]} {
      set editor "xterm -e $match"
    }
    
    puts "running \"$editor\" with $file_paths ..."

    eval exec $editor $file_paths &
  }

  if {$html_paths != ""} {
    foreach file [lreverse $html_paths] {
      if {[string range $file 0 0] == "~"} {
        # netscape doesn't seem to understand ~user, replace 
        # with /home/user.  This is a hack.
        set list [split $file /]
        set user [string range [lindex $list 0] 1 end]
        set file [join "/home $user [lrange $list 1 end]" /]
      }

    # call the browser on this file	
    help $file
    }
  }

  ready
}

