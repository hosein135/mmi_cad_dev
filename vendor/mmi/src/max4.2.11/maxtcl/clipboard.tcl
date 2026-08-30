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

set RCSVERSION(clipboard.tcl) { $Revision: 1.30 $ }


proc _clipboard_filename {} -desc {
  Return the clipboard file name.
} -doc {
  It is not relevant whether the file CLIPBOARD.max exists,
  only whether the directory exists.
  This proc returns the name that should be used
  for the clipboard file, whether it has been created yet, or not.

  If directory does not exist and cannot be created,
  it pops up a message and returns ""
} {
  global CLIPBOARD_FILE  ;# Allows user to over-ride clipboard file location.

  if {! [info exists CLIPBOARD_FILE] } {
    
    # The clipboard file must be private to each user,
    # or multiple users could stomp on each other.
    set dir [max_private_dir]

    # Create the dir if needed.
    if { ! [file isdir $dir] } {
      foreach string [split $dir /] {
	if {$string == ""} {
	  continue
	}
	append makedir /$string
	
	if {![file isdir $makedir]} {
	  # make this directory
	  catch "exec mkdir $makedir"
	}
      }
    }

    if { ! [file isdir $dir] } {
      max_error "error: Can not find or create directory $dir for clipboard file!"
      return ""
    }
    set CLIPBOARD_FILE "$dir/CLIPBOARD.max"
  }
  return $CLIPBOARD_FILE
}

proc clipboard_copy {} -desc {
  Copies the selected items into the clipboard cell
} {

  set filename [_clipboard_filename]
  # The _clipboard_filename proc already printed an error.
  if { $filename == "" } { return }
  # Delete in memory copy, if any, or sel_save will barf
  setl {cdir cell cext} [split_file_name $filename]
  msg_catch "db_cell_delete $cell"

  # BUG FIX: sel_save appends ".max", so we must take it off filename.
  set basename [file rootname $filename]
  if { $basename == "" } { return }

    # Hidden labels must NOT be copied
    # When the clipboard is pasted, it screws up flylines -
    # they dont know whether they should connect to the original
    # or the duplicate.
    # However, this is a potentially expensive operation, so only
    # do it if there are flylines extant.
    if {[string trim [db_flyline]] != ""} {
      sel_labels -less -kind hidden
    }

  if {[msg_catch "sel_save $basename" unused1 unused2]} {
    msg "Can not write clipboard file: $filename\n\
	Clipboard not copied\n"
    return
  }

  # give user the warm and fuzzys	
  msg "Copied selected to Clipboard: $filename\n"
}

proc clipboard_cut {} -desc {
  Copies selected items into the clipboard and then deletes them
} {

  clipboard_copy
  delete 
}


proc clipboard_paste {{mode paste} {bbox ""}} -desc {
  Pastes the contents of the clipboard into the edit cell
} -doc {
  If mode is "paste", paste contents of clipboard cell into
  current cell, then enter move mode.
  If mode is "drop", a cell is already selected.  Center it,
  then enter move mode.
} {
  global MN_PATH_CELL

  if {$bbox == ""} {
    setl {x1 y1 x2 y2} [lay_bbox]
  } else {
    setl {x1 y1 x2 y2} $bbox
  }
  if {$y2 == "" || [expr ($x2 - $x1 + $y2 - $y1) * 0.4] < [res]} {
    # this cell is empty
    set empty 1
  } else {
    set empty 0
  }

  # Default paste location.
  setl {x y} [layt_point user]

  # TODO: There is still a bug in the above.  When you pick a command
  # from the menu, the cursor is teleported into the max window,
  # and lay_point does not return the correct cursor location;
  # it seems to return the location of the Menu Command in the Menu Bar.
  # It does not update until the next time the mouse is moved.
  # Neither update nor after could fix it.

  if {$mode == "paste"} {

    # dump clipboard into group selected
    sel_clear

    # If cursor is off screen (which sometimes happens when you use paste
    # from the menu) or the cell is empty, warp to center.
    setl {fx1 fy1 fx2 fy2} [dbt_frame]
    setl {px py} [lay_point]
    if { $empty || ! [dbt_cursor_in_frame]} {
      layt_point -warp user [expr ($fx1 + $fx2) / 2] [expr ($fy1 + $fy2) / 2]
    }
    setl {x y} [layt_point user]

    set filename [_clipboard_filename]
    if { $filename == "" } { return }

    ####
    #### Read the clipboard file $filename into memory:
    ####

    setl {cdir cname cext} [split_file_name $filename]

    # This delete should not be necessary, because we delete
    # afterwards, but be safe:
    msg_catch "db_cell_delete $cname"
  
    # Add cdir to front of MN_PATH_CELL
    set MN_PATH_CELL [linsert $MN_PATH_CELL 0 $cdir]

    db_cell_new -not_available -internal -no_undo $cname

    # Dump clipboard file into group selected.
    if {!$empty} { db_group selected }

    set ret [msg_catch [list :dump -dup_ok $cname parent $x $y] msg]

    set MN_PATH_CELL [lrange $MN_PATH_CELL 2 end]

    # Delete in memory copy, if any, so we get what another max may have saved.
    # Since we load the cell name in by specifying the path,
    # the actual cell name is the full path, but I suspect this is a bug
    # and will change, so try to delete any cell that has the
    # same full path name, or that is just called "CLIPBOARD"
    # Unfortunately, this blows away the undo stack.
    # At this time (8/00) there is no way to avoid it.
    # We need a -no_undo option to :dump.
    msg_catch {db_cell_delete $cname}

    if { $ret != 0 } {
      # didn't work
      msg "Aborting, $msg\n"
      db_group 0
      return 0
    }

    eval layt_box user $x $y $x $y

    # if nothing selected, just return
    if {! [dbt_any_selection]} {
      db_group 0
      return 0
    }
  }

  # zoom out if this thing is larger than current zoom
  setl {fx1 fy1 fx2 fy2} [dbt_frame]
  setl {xx1 yy1 xx2 yy2} [db_bbox -cell __SELECT__]

  # make sure entire selection is on screen.
  if { $fx1 > $xx1 || $fy1 > $yy1 || $fx2 < $xx2 || $fy2 < $yy2} {
    # Zoom out until it all fits.
    set save_box [layt_box exact]
    layt_box exact [min $fx1 $xx1] [min $fy1 $yy1] \
	[max $fx2 $xx2] [max $fy2 $yy2]

    # do the zoom based on the box  
    :findbox zoom

    eval layt_box exact $save_box
    layt_point -warp user $x $y
  }

  if {$empty} {
    # don't let the user move it around.  It is not necessary and
    # confuses the user
    i_cmd_between
    return
  }

  if { $mode == "drop" } {
    # warp the cursor to the selected cell
    setl {tmp1 tmp2 x y} [sel_what cells]
    if {$y != ""} {
      layt_point -warp dontcare $x $y
    }
  }

  # 8/00: Make this work inconsistently like Sue:
  # If we are dropping from the list-box, fly immediately.
  # If we are dropping from the clipboard, wait for a mouse press
  # before flying.
  if { $mode == "drop" } {
    move_something_mode_enter paste
  } else {
    mode_push clipboard_paste
  }
}

proc _clipboard_paste_mode_define {} -desc {
  move pasted clipboard.
} {
  mode_def clipboard_paste _clipboard_paste_gate_keeper \
	"BUT-1/2 moves clipboard duplicate, CTRL-C aborts"

  mode_bind -cmd 0 clipboard_paste <Any-Button-1> \
	"move_something_mode_enter paste"
  mode_bind -cmd 0 clipboard_paste <Any-Button-2> \
	"move_something_mode_enter paste"
}

proc _clipboard_paste_gate_keeper {event} {
  global mode_abort
  if { $event == "PUSH_TO" } {
    cursor_mode move
  } elseif { $event == "POP_FROM" } {
    if { $mode_abort } {
      # We aborted without ever getting into move_something mode.
      # Delete the duplicate we created.
      undo_to_delim
      undo_flush_redo
      msg "aborting duplicate!\n"
    } else {
      db_group selected
      sel_group_transfer 0
    }
  }
}
