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


# New File Selector Box.

# Top level procedure.  Takes keyworded arguments.
# set the default pattern in FSBOX(default,pattern)

proc fs_box {args} -desc {
  File selection box.  Returns a user-selected filename of "" if the user 
  cancelled it.  

  Takes keyworded arguments as shown with defaults:
      -message "Select file:"
      -pattern $FSBOX(default,pattern) or * if not defined
      -filename ""
      -pathname path of file if it exists or last path of pwd
      -geometry 450x500+50+50 (relative to root windows)
} {

  global FSBOX

  # get arguments
  call_by_keyword $args \
      {{message "Select file:"} {pattern ""} {filename ""} \
	   {pathname ""} {geometry ""} {dironly_ok 0}}

  # if no pattern given, use default pattern or *
  set FSBOX(pattern) \
      [use_first pattern FSBOX(default,pattern) FSBOX(pattern) '*]

  set FSBOX(message) $message
  set FSBOX(dironly_ok) $dironly_ok

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

  set FSBOX(scroll) $frame.files
  scrollbar $frame.scroll -command "$frame.files yview" -highlightthickness 0
  pack $frame.scroll -side right -fill y
  listbox $frame.files -yscrollcommand "$frame.scroll set" \
      -highlightthickness 0 -exportselection 1
  pack $frame.files -side left -fill both -expand 1
  set FSBOX(files) $frame.files

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

  bind $win <Control-c> _fsbox_cancel
  bind $win <Escape> _fsbox_cancel

  # warp cursor to appropriate spot
#  update
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

  # put in filename
  set FSBOX(filename) $selection
}


proc _fsbox_get_files {} -desc {
insert files into listbox
} {

  global FSBOX

  set win $FSBOX(files)

  # remove all entries
  $win delete 0 end

  set save_pwd [pwd]
  if {[catch {cd $FSBOX(pathname)}]} {
    tk_dialog .dialog "Error" "Can not change to directory: $FSBOX(pathname)" \
       {} 0 Ok
    set dirs ""
    set files ""
  } else {

    # get all directories 
    set dirs [glob -nocomplain */]

    if {$FSBOX(pattern) != "<dirs_only>"} {
      # get files, ignore links since we already got them
      set files [glob -nocomplain $FSBOX(pattern)]

    } else {
      # no files
      set files ""
    }
  }

  cd $save_pwd

  # remove any files that are really directories.  Happens mainly when
  # the selection pattern is *.
  foreach name $dirs {
    set save($name) 1
  }
  set all ""
  foreach name $files {
    if {![info exists save($name/)]} {
      lappend all $name
    }
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
    $FSBOX(scroll) yview moveto [lindex $FSBOX($key) 0]
  }
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
    set ext "*[file extension $filename]"
    set suffix($ext) 1
  }

  return [lsort [array names suffix]]
}


if {[info commands _fsbox_pathnames] == ""} {
  # Not defined by any other program.  Use a generic version

  proc _fsbox_pathnames {} {
    global FSBOX
    return [use_first FSBOX(save_paths)]
  }
}

# SPECIAL FOR SUE
# returns a list of pathnames in search path

proc _fsbox_pathnames {} {

  global FSBOX auto_path

  return [concat $auto_path [use_first FSBOX(save_paths)]]
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

  set win $FSBOX(files)

  # save away scroll position so if we come back we have the same position
  set FSBOX([list $FSBOX(pathname) $FSBOX(pattern)]) [$FSBOX(scroll) yview]

  if {$FSBOX(filename) == "../"} {
    set FSBOX(pathname) "[string trimright [file dirname $FSBOX(pathname)] /]/"
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


if {[info commands _fsbox_wait] == ""} {
  # Not defined by any other program.  Use a generic version

  proc _fsbox_wait {} {

    global FSBOX

    grab .fsbox
    focus .fsbox.fframe.filename

    tkwait window .fsbox

    return $FSBOX(filename)
  }
}


# SPECIAL FOR SUE
# wait for window to go away

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


# User hit the cancel key

proc _fsbox_cancel {} {

  global FSBOX

  set FSBOX(filename) ""
  catch {destroy .fsbox}
}
