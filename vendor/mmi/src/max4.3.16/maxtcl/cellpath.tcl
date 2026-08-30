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

set RCSVERSION(cellpath.tcl) { $Revision: 1.68 $ }

# Routines to change the cell path.


proc cell_path_edit {} {
  global MN_PATH_CELL LISTBOX_FONT
  global _CELL_PATH_STUFF

  set _CELL_PATH_STUFF(path) $MN_PATH_CELL

  set prop_list ""

  # This is just a little tricky.  When the listbox is first mapped, the window
  # name is passed to _cell_lbox_fill as an argument.
  # Subsequent calls to _cell_lbox_fill use the same listbox window name,
  # as there can be only one at a time.
  set listbox_bindings [list \
    <Map> "_cell_path_cmd init %W" ]

  lappend prop_list [list "Directories:" "" -label]
  lappend prop_list [list "" "" -listbox -bind $listbox_bindings -font $LISTBOX_FONT]
  lappend prop_list [list "Delete Selected" "" -button "_cell_path_cmd delete"]
  lappend prop_list [list "Move to Front" "" -button "_cell_path_cmd move_to_front"]
  lappend prop_list [list "Move to End" "" -button "_cell_path_cmd move_to_end"]
  lappend prop_list [list "Add Directory" "" -button "_cell_path_cmd add"]
  lappend prop_list [list "" "" -help {When you click Done, all cells in any directories\
    that you have deleted will be removed from max memory.}]

  if {[prop_menu2 -title "Cell Path Editor" $prop_list]} {
    # Make an array whose indicies are the directories that were delete.
    foreach dir $MN_PATH_CELL {   ;# old path
      set delete_dirs($dir) 1
    }
    foreach dir $_CELL_PATH_STUFF(path) {  ;# new path
      catch {unset delete_dirs($dir)}
    }

    # Run through all cells and delete any in any delete directories.
    set delete_cells ""
    foreach list [split [db_cells] \n] {
      setl {cell flags filename} $list
      if {$filename != ""} {
	set dirname [file dirname $filename]
	if {[info exists delete_dirs($dirname)]} {
	  lappend delete_cells $cell
	}
      }
    }

    if {[llength $delete_cells] != 0} {
      # Give the user a last chance to abort.
      set msg "The following cells were loaded from directories\
	that you have removed from the cell path.\n\
	Do you want to delete these cells from memory?\n$delete_cells"

      set answer [prop_dialog -title "Change Cell Path" $msg -buttons {Yes No Cancel}]
      if {$answer == "Cancel"} {
	msg "Path change aborted\n"
	return
      }

      if {$answer == "Yes"} {
	foreach cell $delete_cells {
	  db_cell_delete $cell
	}
      }
    }

    # Success.  Update the cell path.
    set MN_PATH_CELL $_CELL_PATH_STUFF(path)

    msg "Path changed\n"
    # Update
  } else {
    msg "Path change aborted\n"
  }
}

proc _cell_path_cmd {cmd {win ""}} {
  global _CELL_PATH_STUFF
  if {$cmd == "init"} {set _CELL_PATH_STUFF(win) $win}

  set plist [use_first _CELL_PATH_STUFF(win)]
  # Save dirs currently selected in listbox.
  set selected ""
  foreach ind [$plist curselection] {
    lappend selected [$plist get $ind]
  }
  set path $_CELL_PATH_STUFF(path)

  switch $cmd {
    "init" {
      set _CELL_PATH_STUFF(win) $win
      set plist $_CELL_PATH_STUFF(win)
    }
    "move_to_front" {
      foreach dir [lreverse $selected] {
	set path [lremove $path $dir]
	set path [concat $dir $path]
      }
    }
    "move_to_end" {
      foreach dir $selected {
	set path [lremove $path $dir]
	set path [concat $path $dir]
      }
    }
    "delete" {
      foreach dir $selected {
	set path [lremove $path $dir]
      }
      set selected ""
    }
    "add" {
      # This doesnt work very well, because it is not really set up
      # to just find directories; if you select a directory and click OK,
      # then it just cds to that directory.
      #set new [fs_box -dironly -pattern * -message "Select Directory"]
      set prop_list ""
      set new ""
      lappend prop_list [list "New directory" new -entry -width 80]
      if {[prop_menu2 -title "Enter Directory" $prop_list]} {
	if {$new != ""} {
	  set path [concat [list $new] $path]
	}
	set selected [list $new]
      }
    }
    default {
      error "unrecognized _cell_path_cmd $cmd"
    }
  }
  set _CELL_PATH_STUFF(path) $path

  # Reload the listbox.

  $plist delete 0 end
  foreach dir $path {
    $plist insert end $dir
  }

  # Restore selection

  $plist selection clear 0 end
  for {set i 0} {$i < [$plist size]} {incr i} {
    set this_dir [$plist get $i]
    if {[lsearch -exact $selected $this_dir] >= 0} {
      $plist selection set $i
    }
  }
}
