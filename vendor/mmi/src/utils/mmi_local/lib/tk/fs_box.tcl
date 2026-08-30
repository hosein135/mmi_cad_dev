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

set RCSVERSION(fs_box.tcl) { $Revision: 1.7 $ }

# New File Selector Box.

# Top level procedure.  Takes keyworded arguments.
# set the default pattern in FSBOX(default,pattern)

proc fs_box {args} -desc {
  File selection box.
} -doc {
  Returns a user-selected filename of "" if the user 
  cancelled it.  

  Takes keyworded arguments as shown with defaults:
      -message   "Select file:"
      -pattern   $FSBOX(default,pattern) or * if not defined
	  The pattern can be a list of acceptable patterns, all
	  matching filenames will show up in the listbox.
      -filename  ""
      -pathname  path of file if it exists or last path of pwd
      -geometry  450x500+50+50 (relative to root windows)
      -dironly
} {

  global FSBOX

  # get arguments
  set junk [call_keyword $args \
      {{message "Select file:"} {pattern ""} {filename ""} \
	   {pathname ""} {geometry ""} {dironly} {dironly_ok 0}}]
  if { $junk != "" } {
    puts "Warning: unrecognized args to fs_box: $junk"
    # Keep going.  Maybe a the syntax has changed and a newer
    # call called an older fs_box definition.
  }

  # if no pattern given, use default pattern or *
  set FSBOX(pattern) \
      [use_first pattern FSBOX(default,pattern) FSBOX(pattern) '*]

  set FSBOX(message) $message
  set FSBOX(dironly_ok) $dironly

  # NOTE TO LEE: Can remove this -dironly_ok if sue doesnt need it.
  if { $dironly_ok } {
    set FSBOX(dironly_ok) 1
  }

  # make this relative to the root window (generic)
  set win .
  if {[winfo geometry $win] == "1x1+0+0"} {
    # never mapped, try children
    set win [lindex [winfo children $win] 0]
    set win [use_first win '.]
  }
  set winx [expr [winfo rootx $win] + 50]
  set winy [expr [winfo rooty $win] + 50]
  set default_geometry "450x500+$winx+$winy"
  set FSBOX(geometry) [use_first geometry default_geometry]

  set FSBOX(filename) [file tail $filename]

  set this_path [file dirname $filename]
  if {$this_path == "."} {
    set this_path ""
  }

  set pwd [pwd]
  set FSBOX(pathname) [use_first pathname this_path FSBOX(pathname) pwd]

  # always try to put a / at end of pathname
  set FSBOX(pathname) "[string trimright $FSBOX(pathname) /]/"

  # make the toplevel window
  _fsbox_make_window

  # fill'r up
  _fsbox_get_files

  # grab the grab and wait
  _fsbox_wait
}


proc _fsbox_make_window {} {

  global FSBOX

  set win .fsbox

  # toast existing
  catch {destroy $win}

  toplevel $win 

  wm geometry $win $FSBOX(geometry)
  wm title $win "File select box"
  wm minsize $win 200 300
    
  label $win.note -text $FSBOX(message)
  pack $win.note -side top

  # frame for listbox and scrollbar
  set frame $win.frame
  frame $frame -relief sunken -bd 2
  pack $frame -side top -fill both -expand 1

  scrollbar $frame.scroll -command "$frame.files yview" -highlightthickness 0
  pack $frame.scroll -side right -fill y
  listbox $frame.files -yscrollcommand "$frame.scroll set" \
      -highlightthickness 0 -exportselection 1
  pack $frame.files -side left -fill both -expand 1
  set FSBOX(win_files) $frame.files

  # frame for pathname
  set frame $win.pframe
  frame $frame -bd 1
  pack $frame -side top -fill x

  menubutton $frame.button -text "Pathname:" -menu $frame.button.menu \
      -padx 0 -pady 2 -relief raised
  pack $frame.button -side left
  menu $frame.button.menu -tearoff 0
  set FSBOX(pathname_menu) $frame.button.menu

  entry $frame.pathname -textvariable FSBOX(pathname) -relief sunken \
      -bd 2 -highlightthickness 1
  pack $frame.pathname -side left -fill x -expand 1 
  bind $frame.pathname <Return> _fsbox_get_files
  set FSBOX(win_pathname) $frame.pathname

  # frame for filename
  set frame $win.fframe
  frame $frame -bd 0
  pack $frame -side top -fill x

  label $frame.label -text "Filename:" -padx 0 -pady 0  
  pack $frame.label -side left

  entry $frame.filename -textvariable FSBOX(filename) -relief sunken \
      -bd 2 -highlightthickness 1
  pack $frame.filename -side left -fill x -expand 1
  bind $frame.filename <Return> _fsbox_goto
  set FSBOX(win_filename) $frame.filename

  # frame for selection pattern
  set frame $win.sframe
  frame $frame -bd 0
  pack $frame -side top -fill x

  menubutton $frame.button -text "Selection Pattern:" -menu $frame.button.menu \
      -padx 0 -pady 2 -relief raised
  pack $frame.button -side left
  menu $frame.button.menu -tearoff 0
  set FSBOX(pattern_menu) $frame.button.menu

  entry $frame.pattern -textvariable FSBOX(pattern) -relief sunken \
      -bd 2 -highlightthickness 1
  pack $frame.pattern -side left -fill x -expand 1
  bind $frame.pattern <Return> _fsbox_get_files

  # frame for buttons
  set frame $win.bframe
  frame $frame -bd 0
  pack $frame -side top -fill x

  button $frame.ok -text "  OK  " -command _fsbox_goto \
      -padx 0 -pady 0 -relief raised
  pack $frame.ok -side left -fill x -expand 1

  button $frame.rescan -text "Rescan" -command _fsbox_get_files \
      -padx 0 -pady 0 -relief raised
  pack $frame.rescan -side left -fill x -expand 1

  button $frame.cancel -text "Cancel" -command _fsbox_cancel \
      -padx 0 -pady 0 -relief raised
  pack $frame.cancel -side left -fill x -expand 1

  # single click selects
  bind $win.frame.files <Button-1> {_fsbox_select %W %y}

  # double click is like ok
  bind $win.frame.files <Double-Button-1> _fsbox_goto

  # double click is too hard, so allow button-2/3 as well.
  # Note: If you just bind ButtonPress, it gets an error inside the tk
  # library; using ButtonRelease makes it work ok.
  bind $win.frame.files <Button-2> {_fsbox_select %W %y}
  bind $win.frame.files <Button-3> {_fsbox_select %W %y}
  bind $win.frame.files <ButtonRelease-2> {_fsbox_goto}
  bind $win.frame.files <ButtonRelease-3> {_fsbox_goto}

  bind $win <Any-Control-c> _fsbox_cancel
  bind $win <Escape> _fsbox_cancel

  # warp cursor to appropriate spot
  # note by pat: Do NOT do an update here.
  # If cursor_warp is on, then the _warp_cursor_window proc does the update.
  # If cursor_warp is off, the update may cause the menu to post
  # under the mouse cursor, stimulating the X bug whereby if the
  # mouse parachutes into a window, the focus is lost.
  # If this update is not here (and if cursor_warp is off), then the
  # grab and focus are performed before the update, and everything is peechy.
  # This bug only showed up for me when fs_box was called when
  # there was another toplevel active (ie a prop_menu).
  # update
  _warp_cursor_window $win.fframe.filename
}


proc _fsbox_select {win y} -desc {
select closest and place into filename entry
} {

  global FSBOX

  # clear selection
  $win selection clear 0 end

  set index [$win nearest $y]
  if {$index == ""} {
    return
  }

  # select
  $win selection set $index

  set selection [$win get $index]
  if {$selection == ""} {
    # nothing selected
    return
  }
  # Take out the link, if any.
  regsub { -> .*} $selection "" selection

  # put in filename
  set FSBOX(filename) $selection
  $FSBOX(win_filename) icursor end
}


proc _fsbox_get_files {} -desc {
insert files into listbox
} {

  global FSBOX

  set win $FSBOX(win_files)

  # remove all entries
  $win delete 0 end

  set save_pwd [pwd]
  if {[catch {cd $FSBOX(pathname)}]} {
    tk_dialog .dialog_fsbox "Error" "Can not change to directory: $FSBOX(pathname)" \
       {} 0 Ok
    set dirs ""
    set files ""
  } else {

    # get all directories 
    set dirs [glob -nocomplain */]
    foreach name $dirs {
      # Note: the name includes a trailing slash.
      set dirhash($name) 1
    }

    set files ""
    if {$FSBOX(pattern) != "<dirs_only>"} {
      foreach pat $FSBOX(pattern) {
	# get files, ignore links since we already got them
	foreach f [glob -nocomplain $pat] {
	  # remove any files that are really directories.  Happens mainly when
	  # the selection pattern is * or */.
	  if {[info exists dirhash($f)] || [info exists dirhash($f/)]} {continue}

	  # Show links as "link -> filename"
	  set link ""
	  catch {set link [file readlink $f]}
	  if {$link != ""} {
	    lappend files "$f -> $link"
	  } else {
	    lappend files $f
	  }
	}
      }
    }
  }

  cd $save_pwd

  set all ""
  foreach name $dirs {
    lappend all $name
  }
  foreach name $files {
    lappend all $name
  }

  $win insert end "../"
  foreach file [lsort "$dirs $files"] {
    if {$file != "./" && $file != "../"} {
      $win insert end $file
    }
  }

  # now add to pathname and select pattern menus
  if {[info commands _fsbox_pathnames] != ""} {
    # only do if this is defined by another program
    _fsbox_add_to_menu $FSBOX(pathname_menu) pathname [_fsbox_pathnames]
  }

  _fsbox_add_to_menu $FSBOX(pattern_menu) pattern [_fsbox_patterns]

  set key [list $FSBOX(pathname) $FSBOX(pattern)]
  if {[info exists FSBOX($key)]} {
    # been here before, set scroll bar back
    $FSBOX(win_files) yview moveto [lindex $FSBOX($key) 0]
  }

  # We just stuffed the .pathname window with a new pathname.
  # If the cursor is in that window, put it at the end of the name.
  $FSBOX(win_pathname) icursor end
}


# remove and then fill the menu

proc _fsbox_add_to_menu {win type list} {

  # first lose the old patterns
  $win delete 0 end

  foreach element $list {
    if {[info exists save($element)]} {
      # ignore duplicates
      continue
    }
    set save($element) 1

    $win add command -label $element \
	-command "set FSBOX($type) $element ; _fsbox_get_files"
  }
}


proc _fsbox_patterns {} {

  global FSBOX

  set suffix(*) 1
  set suffix(<dirs_only>) 1

  foreach filename [glob -nocomplain "$FSBOX(pathname)/*"] {
    if {[file isfile $filename]} {
      set ext "*[file extension $filename]"
      set suffix($ext) 1
    }
  }

  return [lsort [array names suffix]]
}


if {0} {
  if {[info commands _fsbox_pathnames] == ""} {
    # Not defined by any other program.  Use a generic version

    proc _fsbox_pathnames {} {
      global FSBOX
      return [use_first FSBOX(save_paths)]
    }
  }
}

# returns a list of pathnames in search path
proc _fsbox_pathnames {} {

  global FSBOX
  global auto_path      ;# Special for SUE
  global MN_PATH_CELL   ;# Special for MAX

  if { [info exists MN_PATH_CELL] } {
    # Special for MAX
    set list ""
    foreach path $MN_PATH_CELL {
      if {![regexp {^(tk)|(tcl)[0-9]+\.[0-9]+} [file tail $path]]} {
	lappend list [string trimright $path {/@}]
      }
    }
    return [concat $list [use_first FSBOX(save_paths)]]
  } elseif { [info exists auto_path] } {
    # Special for SUE
    return [concat $auto_path [use_first FSBOX(save_paths)]]
  } else {
    # Generic
    return [use_first FSBOX(save_paths)]
  }
}


proc _fsbox_goto {} -desc {
  sets up the file name based on the pathname and filename and ends.
} {

  global FSBOX

  if {$FSBOX(filename) == ""} {

    if {$FSBOX(dironly_ok)} {
      # special case of directory only
      set FSBOX(filename) $FSBOX(pathname)

      # save this path if not already known
      set path [file dirname $FSBOX(pathname)]
      if {[lsearch [_fsbox_pathnames] $path] == -1} {
	lappend FSBOX(save_paths) $path
      }

      catch {destroy .fsbox}
      return
    }

    # no filename, ignore
    return
  }

  # save away scroll position so if we come back we have the same position
  set FSBOX([list $FSBOX(pathname) $FSBOX(pattern)]) [$FSBOX(win_files) yview]

  if {$FSBOX(filename) == "../" || $FSBOX(filename) == ".."} {
    set parent_dir [file tail $FSBOX(pathname)]
    if { $parent_dir == "" } {
      # We are already in the root directory.
      # Cant cd to ..  Just do nothing.
    } elseif { $parent_dir == "." || $parent_dir == ".." } {
      # Path already ends with . or .., which is complicated.
      # Fix it by converting the whole thing to an absolute path.
      set tmp "[string trimright $FSBOX(pathname) /]/.."
      set FSBOX(pathname) [absolute_path $tmp]
    } else {
      # This one is easy enough, even we can do it!
      # Strip off the last directory, and that is our new path!
      set FSBOX(pathname) "[string trimright [file dirname $FSBOX(pathname)] /]/"
    }
    set FSBOX(filename) ""
    _fsbox_get_files

  } else {
    if {[lsearch "~ /" [string index $FSBOX(filename) 0]] != -1} {
      # absolute path, ignore pathname
      set file $FSBOX(filename)
    } else {
      # relative path, use pathname
      set file "[string trimright $FSBOX(pathname) /]/$FSBOX(filename)"
    }

    if {[file isdir $file]} {
      # change to this directory
      set FSBOX(pathname) "[string trimright $file /]/"
      set FSBOX(filename) ""
      _fsbox_get_files
    
    } else {
      # got a filename
      set FSBOX(filename) $file

      # save this path if not already known
      set path [file dirname $file]
      if {[lsearch [_fsbox_pathnames] $path] == -1} {
	lappend FSBOX(save_paths) $path
      }

      catch {destroy .fsbox}
    }
  }
}


# wait for window to go away

proc _fsbox_wait {} {

  global FSBOX

  # If the window springs into existence under the mouse, you might
  # stimulate the X bug whereby the focus is lost.
  # If the window has not yet done a full "update" (only update idletasks)
  # before now, then the grab and focus are performed before the update,
  # and X does not become confused.  Another way to fix it
  # is to use focus -force, but that might be kind of rude?
  update idletasks
  catch { focus .fsbox.fframe.filename }

  if {[catch "grab set .fsbox" msg]} {
      # grab failed.  This is what other tcl examples do,
      # but I wonder if it is correct.
      # If the problem is that some other app got the grab,
      # we may get it back when the user moves the mouse into
      # our window, so maybe we should bring up the meny anyway.
      # But I cant test this, because I dont know how to stimulate this case.
      # (pat)
      puts $msg
  } else {

    catch {cursor_wait .fsbox 1 "$FSBOX(message)" }
    tkwait window .fsbox
    # restore
    catch {cursor_wait .fsbox 0 "" }
  }

  return $FSBOX(filename)
}

if {0} {
  proc _fsbox_wait {} {

    global FSBOX

    global WIN WIN_DATA
    set cursor [lindex [$WIN configure -cursor] 4]
    $WIN configure -cursor question_arrow
    set WIN_DATA($WIN,display_msg) "?:  $FSBOX(message)"

    grab .fsbox
    focus .fsbox.fframe.filename

    tkwait window .fsbox

    # restore
    set WIN_DATA($WIN,display_msg) ""
    $WIN configure -cursor $cursor

    return $FSBOX(filename)
  }
}


# User hit the cancel key

proc _fsbox_cancel {} {

  global FSBOX

  set FSBOX(filename) ""
  catch {destroy .fsbox}
}
