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

set RCSVERSION(vcs.tcl) { $Revision: 1.4 $ }

# TODO:
# "Save and Descendents" menu option should have hotkey Ctrl-W.
# Had note about "Cell in archive" from talk with lee.  What was that about?
# File New - needs to check for an archive file.

# TODO:
# - get_archive_exists can be faster.
# - to speed up diff: could save the file mod time as a prop?
# - should do a test suite.
# - implement co_on_open, ci_on_save.
# - run diff output through grep -v ^vc_
#   maybe do diff directly instead of using rcsdiff?  Why?
# - revert to .BAK files? (mha requested)
# - When user locks file, ask for comment, put in .lock file.

# VC Commands are: Commit (check-in), Update (check-out modified files),
# Lock and Unlock.  CVS does not support locking, so we have to
# do it ourselves.  The "File Open" command does automatic check-out
# and optional locking.
#
# Possible VC conflicts:
# check out:
#	no archive exists.
#	file locked by another - dont need warning until file modified;
#	working file exists and is read-write, or is read-only and option set:
#		see if file differs.  If so,
#		query user whether to over-write
#		should check for differences; if none, over-write.		
# check in:
#	file locked by another;
#	working version < archive version:
#		should check for differences;
#		it would be nice to give the user a chance to see the
#		differences, but I think max reverses stuff each time
#		it writes it, so there are always a zillion differences.
# Lock:
#	file locked by another;
# 

# This is what it should be:	-default {CVS RCS SCCS SHARE} 
init_global VC_DIRS \
	-type STRING \
	-default RCS \
	-desc {List of sub-directory names allowed for Version Control.}

init_global VC_OPEN_FILES \
	-type STRING \
	-default "" \
	-desc { Set by max :load command via cell_load_hook }
  
# This variable holds the version after a check-in.
global _VC_WORK_VER

# User preference options.
set VC_OPTIONS(permit_break_lock) 1
set VC_OPTIONS(ignore_readonly_file) 1
set VC_OPTIONS(use_mmi_lock) 1
set VC_OPTIONS(lock_on_modify) "no" ;# Can be yes, no, or ask_me
set VC_OPTIONS(ci_on_save) "no" ;# Can be yes, no, or ask_me
set VC_OPTIONS(co_on_open) "no" ;# Can be yes, no, or ask_me
set VC_OPTIONS(state_list) "Exp Stable Release Verified" ;# RCS state.
set VC_OPTIONS(vcs_default) "RCS"
set VC_OPTIONS(unmod_file_mode) "rw" ;# can be r or rw.

# Persistent prop_menu data.
set VC_PERSIST(keep_lock) 0
set VC_PERSIST(force) 0
set VC_PERSIST(description) ""
set VC_PERSIST(state) ""  ;# RCS state.  Commented out as confusing.

proc vcs_setup_menu {} {
  global VC_OPTIONS VC_DIRS
  set prop_list ""

  lappend prop_list [list "Auto-lock cell on first modification" \
	VC_OPTIONS(lock_on_modify) -choice "yes no ask_me" \
	-help {When a cell is first modified, if auto-lock is "yes" then \
	the cell is automatically locked.  If auto-lock is "ask_me" then \
	the user is prompted whether to lock the cell.  If auto-lock \
	is "no", then the cell is not automatically locked, and you must \
	use the VC lock/VC unlock options manually.}]
  lappend prop_list [list "Auto-update when cell is opened" \
	VC_OPTIONS(co_on_open) -choice "yes no ask_me"]
  lappend prop_list [list "Auto-commit when cell is saved" \
	VC_OPTIONS(ci_on_save) -choice "yes no ask_me"]

  lappend prop_list [list "Permit break lock" \
	VC_OPTIONS(permit_break_lock) -enum "no yes" \
	-help {If no, then if another user has a cell locked, you can\
	not use max to commit (check-in) the file until the other user\
	unlocks it.\
	You can still break the lock outside of max using UNIX commands.}]
  lappend prop_list [list "Unmodified file mode" \
	VC_OPTIONS(unmod_file_mode) -choice "r rw" \
	-help {Unmodified unlocked local files can be created with a\
	read-only file mode, which makes them\
	easier to identify, or read-write file mode.}]
  lappend prop_list [list "Default Version Control System:" \
	VC_OPTIONS(vcs_default) -choice $VC_DIRS \
	-help {RCS - Revision Control System; \
	SCCS - Source Code Control System; \
	CVS - GNU Concurrent Versions System; \
	SHARE - Default built-in method, which shares files by saving them\
	in the SHARE sub-directory. \
	Note: all choices support multi-user access management using \
	the VC lock/VC unlock commands in the File menu.}]
  #lappend prop_list [list "RCS State List:" VC_OPTIONS(state_list) -entry]
  prop_menu2 -title "VC Setup" $prop_list
}


proc vcs_sub_menu {topmenu cmd} -desc {
  Build sub-menu for VC command: cmd to post from main menu.
} {
  set submenu $topmenu.$cmd
  switch $cmd {
    "commit" { set desc "save and commit" }
    "update" { set desc "update local copies of cell(s) from VC archive;" }
    default { set desc $cmd }
  }
  menu $submenu -tearoff 0
  menu_add_cmd_fast $submenu "$cmd edit cell..." \
    "vcs_menu_command $cmd edit" \
    "Version control: $desc edit cell"
  menu_add_cmd_fast $submenu "$cmd edit cell and descendents..." \
    "vcs_menu_command $cmd hier" \
    "Version control: $desc edit cell and all its descendents"
  menu_add_cmd_fast $submenu "$cmd all loaded cells..." \
    "vcs_menu_command $cmd all" \
    "Version control: $desc all currently loaded cells"
  menu_add_cmd_fast $submenu "$cmd all max files in directory..." \
    "vcs_menu_command $cmd dir" \
    "Version control: $desc all the max files in a specified directory"
  return $submenu
}

# This is a string whose magic property is that any version control
# system will change it when they check out a file.
# We have to break it up so it is not modified when THIS source file is
# checked in and out.
global VC_MODIFY_STRING
set Dollar {$}
set VC_MODIFY_STRING "${Dollar}Revision${Dollar} %R%"

proc vc_cell_save_hook {} -desc {
  Called by cell_save right before :save
} -doc {
  Used to add the version control properties.
} {
  global VC_MODIFY_STRING

  global VERSION_CONTROL_ENABLE
  if {[use_first VERSION_CONTROL_ENABLE '0] == 0} {return}

  # Turn off undo when setting these version props, because we do
  # NOT want to be able to undo them.  But, maybe it doesnt matter
  # because we only do this right before we write the file, so if it is undone,
  # it would still happen again next time the file is written.
  undo_disable
  if {[db_prop vc_rcs_version] == ""} {
    # Break up this string so that it is not modified when THIS file is checked in/out.
    set Dollar {$}
    db_prop vc_rcs_version "${Dollar}Revision${Dollar}"
  }
  if {[db_prop vc_sccs_version] == ""} {
    db_prop vc_sccs_version {%I%}
  }
  # This property is used to tell if the most recent write was done
  # by max or the version control system, to avoid unnecessary
  # diffs to determine if the file has been changed.  
  # By setting the prop to a value that is always changed by the
  # version control system, we know who wrote the file last.
  # We dont use the value substituted by the version control system,
  # just the fact it has been changed from its original value.
  db_prop vc_modify_string $VC_MODIFY_STRING
  undo_enable

  # We do not unlock the file when it is saved to disk;
  # we wait until it is committed to archive.
}

proc vc_sema_file {action args} -desc {
  Interface to sema_file semaphores.
} {
  if {[catch {util_load_pkg mmi_sema_package.so}]} {
    msg "Error: Can not load mmi_sema_package.so needed for file locking\n"
    return ""
  }
  # TODO: When max is recompiled, take this out.
  # Temporarily, the version of sema_file compiled into max is out of date.
  return [eval sema_file $action $args]
}

proc vc_who_am_i {} -desc {
  Return user name
} {
  global env
  return [use_first env(USER) env(LOGNAME) env(HOME) 'unknown]
}


proc vcs_post_command_hook {} -desc {
  Called after each interactive command to do VC stuff.
} -doc {
  It checks for modified files, and optionally locks them.
  Prints warnings if a newly edited file is already being edited.
  Updates the listbox flags.
} {
  global CELL VC_OPTIONS _VC_LOCK_WARN_FILES VC_OPEN_FILES

  global VERSION_CONTROL_ENABLE
  if {[use_first VERSION_CONTROL_ENABLE '0] == 0} {return}

  if { $VC_OPTIONS(lock_on_modify) == "no" } { return }

  set cell [lay_editcell]
  # We do not want to auto-lock (UNNAMED)
  if { $cell == "$CELL(UNNAMED)" } { return }

  # If the edit cell was modified, maybe other cells were too, so make a list.
  set modified_cell_list ""
  if {[memq [cell_flags $cell] "modified"]} {
    foreach file [split [string trim [db_cells] \n] \n] {
      setl {name flags file} [db_cells $cell]
      if {[memq $flags "modified"]} {
	lappend modified_cell_list $name
      }
    }
  }

  # Make a list of files that have been opened since the last call.
  # The VC_OPEN_FILES is a list of files loaded by max, either by :load
  # or internally by max, eg, auto-loaded for DRC.
  # We dont want to process them at that time, so save the names in VC_OPEN_FILES,
  # and process them now, when it is safe to do so.
  # Subtract out files already in in our modified cell list.
  set opened_cell_list ""
  foreach f $VC_OPEN_FILES {
    if {[lsearch -exact $modified_cell_list $f] == -1} {
      lappend opened_cell_list $f
    }
  }
  set VC_OPEN_FILES ""


  # Make some tests:
  # A. Is someone else already editing the file in this directory?
  # B. Does someone else have the file locked (irrespective of modifications)?
  # C. Has the archive version been updated since we checked it out?
  # If !A, mark that we editing the file.
  # If A||B||C print a warning (only print one).
  # If C&&!(A||B), volunteer to check out the latest version of the file.
  # If !(A||B||C), then optionally lock the file.

  foreach cell $modified_cell_list {

    # If we already warned, skip it.
    # Create an array element in _VC_LOCK_WARN_FILES for each cell
    # when it is first modified, so we dont warn twice for the same cell.
    if {[use_first _VC_LOCK_WARN_FILES($cell)] == 1} { continue }
    set _VC_LOCK_WARN_FILES($cell) 1

    set vcs_type [vcs_get_type -create $cell]

    # Mark that this file is being edited by me.
    # Set user_info if it is already being edited by someone else.
    set me [vc_who_am_i]
    set user_info [vc_sema_file lock -file $cell -user $me]
    if {$user_info != ""} {
      # Shoot, someone else is modifying it too.
      set msg "Warning: user [lindex $user_info 0] is already modifying cell $cell in this directory."
      tk_dialog .dialog "Cell $cell" $msg {} 0 Ok
    }

    # See if any file has an archive version that is newer
    # than the local disk version.
    set vcs_type [vcs_get_type $cell]
    set tip [${vcs_type}::vcs_op get_tip_ver $cell]
    set work [${vcs_type}::vcs_op get_work_ver $cell]

    if {$tip > $work} {
      append warnings "Cell $cell has newer archive version; probably committed by another user."
    }

    if {$VC_OPTIONS(lock_on_modify) == "ask_me"} {
	set msg "Cell $cell modified.  Do you want to lock it?"
	set choice [tk_dialog .dialog "Cell $cell" $msg {} 0 \
	  Yes "Yes to all" No "No to all"]
	if { $choice == 2 } { ;# no
	  continue
	}
	if { $choice == 3 } { ;# no to all
	  set VC_OPTIONS(lock_on_modify) no
	  return
	}
	if { $choice == 1 } { ;# yes to all
	  set VC_OPTIONS(lock_on_modify) yes
	}
    }

    ${vcs_type}::vcs_operation lock $cell
  }

  set warnings ""

  # Process files that were opened since the last command.
  foreach cell $VC_OPEN_FILES {
    set vcs_type [vcs_get_type $cell]

    # See if anyone else has this file locked already.
    set locker [vcs_mmi_lock owner $vcs_type $cell]
    if {$locker != ""} {
      append warnings "Cell $cell is locked by user $locker.  "
    }

    # See if any file has an archive version that is newer
    # than the local disk version.
    set tip [${vcs_type}::vcs_op get_tip_ver $cell]
    set work [${vcs_type}::vcs_op get_work_ver $cell]
    if {$tip > $work} {
      append warnings "Cell $cell has newer archive version; probably committed by another user."
    }

    # See if someone else is already editing this cell.
    # If we already printed a message about the file being locked, dont bother
    if {$locker == ""} {
      set user_info [vc_sema_file query -file $cell]
      if { $user_info != "" } {
	append warnings "Cell $cell is being edited by user [lindex $user_info 0].  "
      }
    }
  }

  if { $warnings != "" } {
    set ret [list tk_dialog .warning "max warning" $warnings {} 0 ok]
  }
}

proc vcs_menu {} -desc {
  Top level vcs menu invoked from max menu bar.
} {
  set vcsop lock
  set who edit

  set prop_list ""
  lappend prop_list [list Operation: vcsop -radio {lock unlock update commit}]
  lappend prop_list [list "On Cells:" who -radio { \
    "edit cell"  "edit cell and descendents" "all currently loaded cells" \
    "all cells in specified directory..."} \
    -values {edit hier all dir}]

  set title "Version Control"
  if {[prop_menu2 -title $title $prop_list] == 0} {
    msg "cancelled...\n"
    return
  }

  vcs_menu_command $vcsop $who
}

proc vcs_menu_command {what who} -desc {
  Entry point for VC commands from the menu.
} -doc {
  <what> can be: commit, update, lock, unlock.
  <who> can be: edit (edit-cell only), hier (edit cell and hierchy),
    all (all open files), dir (specified directory).
} {
  global CELL _VC_ACCUMULATE_LIST _VC_ACCUMULATE_CANCEL

  # Accumulate the list of files to process in _VC_ACCUMULATE_LIST.
  # We will also save any files, if necessary, at this time.
  if { $what == "commit" } {
    msg "Saving files to disk...\n"
  }

  set _VC_ACCUMULATE_LIST ""
  set _VC_ACCUMULATE_CANCEL 0
  switch $who {
    edit {
      vcs_accumulate $what
    }
    hier {
      cell_process_tree "vcs_accumulate $what" 0
    }
    all {
      cell_process_all "vcs_accumulate $what" 0
    }
    dir {
      # TODO
      error "VC directory operations unimplemented"
    }
    default { assert 0 }
  }

  # If user cancelled renaming (UNNAMED)
  if { $_VC_ACCUMULATE_CANCEL } {
    if { $_VC_ACCUMULATE_LIST == "" } {
      # User was processing only (UNNAMED), so the cancel pressed
      # on the rename (UNNAMED) box means to cancel the
      # entire VC op quietly.
      msg "VC $what cancelled\n"
    } else {
      # User processing multiple files, but cancelled renaming (UNNAMED).
      # We will ask if they want to do the VC op on all files
      # except (UNNAMED).
      set msg "Do you want to VC $what all cells except $CELL(UNNAMED)?"
      set ret [list tk_dialog .warning "max warning" $msg {} 0 yes cancel]
      if {$ret == 1} {
	msg "VC $what cancelled\n"
	return
      }
    }
  }

  # Different files in different directories may use different VC methods.
  # So segregate them.
  if { $_VC_ACCUMULATE_LIST == "" } {
    msg "Version Control $what cancelled\n"
    return
  } else {
    msg "Invoking Version Control $what...\n"
  }

  foreach cell $_VC_ACCUMULATE_LIST {
    set vcs_type [vcs_get_type -create $cell]
    if { $vcs_type == "" } {
      msg "VC $what Cancelled\n"
      return
    }
    lappend vcs_cells($vcs_type) $cell
  }

  # Now do it.  Invoke one vcs_operation for each type of VC in use.
  foreach type [array names vcs_cells] {
    #eval "$type::vcs_operation $what $vcs_cells($type)"
    ${type}::vcs_operation $what $vcs_cells($type)
  }
}


proc vcs_revert {{version ""}} -desc {
  Revert edit cell to specified version.
} -doc {
  If version is "", query user for revision.
  Otherwise, revert to specified version without issuing a warning.
} {

  set cell [lay_editcell]
  set vcs_type [vcs_get_type $cell]
  if { $vcs_type == "" } {
    # The VC directory does not exist.
    msg -warn "No VC archive directory found for $cell\n"
    return
  }

  #set tip [eval "$vcs_type::vcs_op get_tip_ver $cell"]
  set tip [${vcs_type}::vcs_op get_tip_ver $cell]
  if { $tip == "" } {
    # No archive file created for this file yet.
    msg -warn "No $vcs_type archive file found for $cell\n"
    return
  }

  if { $version == "" } {
    set version $tip
    set prop_list ""
    lappend prop_list [list "Archive Version number:" version -entry]
    set title "Revert cell: $cell"
    set message "Replace cell with version from archive?"
    if {![prop_menu2 -message $message -title $title $prop_list]} {
      # cancelled
      return
    }
  }

  sel_clear

  # Check out the specified archive version to disk, then
  # have max flush the in-memory version.
  #set code [namespace eval $vcs_type "vcs_op update -version $version $cell"]
  set code [${vcs_type}::vcs_op update -version $version $cell]
  if { $code == 0 } {
    msg -warn "Revert operation cancelled\n"
  }

  # Flush prints an inapplicable message, to catch it.
  if {[msg_catch :flush result info warn]} {
    msg -warn "$result\n"
  }
  cell_load_finish
}

proc vcs_get_type {args} -desc {
  Return name of VC to use for cell.
} -doc {
  USAGE:
  vcs_get_type [-create] cell
} {
  global VC_OPTIONS VC_DIRS _VC_TYPE_CACHE

  set cell [call_keyword $args [list {create}]]
  set filename [cell_file $cell]

  set dir [file dirname $filename]
  if {[info exists _VC_TYPE_CACHE($dir)]} {
    return $_VC_TYPE_CACHE($dir)
  }

  foreach type $VC_DIRS {
    if {[file isdirectory $dir/$type]} {
      return [set _VC_TYPE_CACHE($dir) $type]
    }
  }

  # No VC dir exists.  Prompt user to create one.
  if { $create == 0 } { return "" }

  set vcs_type $VC_OPTIONS(vcs_default)
  set prop_list ""
  set title "No VC directory found"
  set message "No VC sub-directory found in directory $dir."

  lappend prop_list [list "Create a new Version Control sub-directory?" "" -label]
  lappend prop_list [list "Type" vcs_type -radio $VC_DIRS]
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled - inform caller to abort.
    return ""
  }

  # Create the directory.
  file mkdir $dir/$vcs_type

  return $vcs_type
}

proc vcs_accumulate {what} -desc {
  Called from menu commands to accumulate cell names to process with VC commands.
} -doc {
  It is faster to process all the files with one VC command
  than to do each file separately.
  On entry, cell is the current cell.
} {
  global CELL _VC_ACCUMULATE_LIST _VC_ACCUMULATE_CANCEL

  set cell [lay_editcell]
  # Always rename and save (UNNAMED) first.
  # If user hits cancel, the VC operation will be aborted.
  if { $cell == "$CELL(UNNAMED)" } {
    if {[memq [cell_flags $cell] "modified"]} {
      if {[cell_save] == 0} {
	# User cancelled rename (UNNAMED)
	set _VC_ACCUMULATE_CANCEL 1
	return
      }
    } else {
      # If (UNNAMED) not modified, just ignore it.
      msg "Ignoring cell: $CELL(UNNAMED)\n"
      return
    }
  }

  # If doing a commit, save the contents of the cell now,
  # to avoid another :load later.
  if { $what == "commit" && [memq [cell_flags $cell] "modified"]} {
    cell_save
  }

  set cell [lay_editcell]  ;# May be new name after cell_save
  if { $cell != "$CELL(UNNAMED)" } {
    lappend _VC_ACCUMULATE_LIST $cell
  }
}


proc vcs_mmi_lock {option vcs_type cells} -desc {
  Create or remove VC lock file.
} -doc {
  <option> is "lock" or "unlock" or "exists"
  <vcs_type> is RCS, CVS, etc.
  <cells> is a list of cells
  If option is "exists" or "locker", only one cell may be specified.
  If option is "owner", return name of first locker found, or "".
  If option is lock or unlock, return 1 on success, 0 on failure.
  If option is "exists", return 1 if locked, 0 otherwise.
} {

  switch $option {
    "owner" -
    "exists" -
    "lock" -
    "unlock" {}
    default { error "unknown option to vcs_mmi_lock: $option" }
  }

  foreach cell $cells {
    set filename [cell_file $cell]

    set path [file dirname $filename]
    set tail [file tail $filename]
    set lockfile $path/$vcs_type/$tail.lock

    # Owner of lockfile is the current lock owner.
    if {[catch {set locker [file attributes $lockfile -owner]}]} {
      set locker ""
    }

    if {$option == "exists"} {
      return [expr {$locker == "" ? 0 : 1}]
    }
    if {$option == "owner"} {
      return $locker
    }

    #set user [namespace eval $vcs_type "vcs_op get_user"]
    set user [${vcs_type}::vcs_op get_user]

    if { $locker == $user } {
      if { $option == "lock" } {
	# File already locked by this user.
      } else {
	# Unlock by removing the lockfile.
	file delete -force $lockfile
      }
      msg "VC $option $cell.max\n"
      continue
    }

    if { $locker != "" } {
      # File is locked by another user.

      if { ! $VC_OPTIONS(permit_break_lock) } {
	msg -warn "File $filename is locked by $locker\n"
	return 0
      }
      set message "File $filename is locked by $locker.  Do you want to over-ride the lock?"
      set choice [tk_dialog .dialog "File is locked" $message {} 1 Yes Cancel]
      if { $choice == 1 } {
	# Cancelled
	return 0
      }
      file delete -force $lockfile
    }

    if { $option == "lock" } {
      # Create lockfile.

      catch {close [open $lockfile "w"]}

      # Check for error.
      if {[catch {set locker [file attributes $lockfile -owner]} result]} {
	msg -warn "File $filename could not acquire lock: $result\n"
	return 0
      }
      # There is a race condition with other users.
      # See if another user managed to lock the file before us.
      if { $locker != $user } {
	msg -warn "File $filename already locked by $locker\n"
	return 0
      }
    }

    # Print diagnostic
    msg "VC $option $cell.max\n"
  }

  # Success on all filenames.
  return 1
}

# Create the RCS namespace.  This must be done before using it.
# Note: the semantics:
# 	namespace eval RCS { proc foo ... }
# does not work because proc is redefined by MMI.
# Instead, use semantics:
# 	proc RCS::foo ...
# Update 5/01: The namespace now works ok, but I am leaving this
# alone because it works too.

namespace eval RCS {}

proc RCS::vcs_operation {what args} -desc {
  Main entry point for user level RCS commands.
} -doc {
  <what> may be commit, update, lock, unlock.
} {
  global VC_OPTIONS VC_PERSIST

  set cells [call_keyword $args [list {force 0} {version ""}]]
  if { $cells == "" } {
    error "No cells specified"
  }

  switch $what {
    "commit" {
      # Figure out which cells already have associated archive files.
      set old_cells ""
      foreach cell $cells {
	if {[RCS::vcs_op archive_exists $cell]} {
	  lappend old_cells $cell
	}
      }

      # RCS has a built-in locking mechanism.  We make it a user
      # defined option whether to use it or not.
      if { $VC_OPTIONS(use_mmi_lock) } {
	vcs_mmi_lock lock RCS $old_cells
      } else {
	# RCS will query user if files are already locked.
	# The end result is 0 only if all files were successfully locked.
	# If it fails, some files may be locked and some not,
	# which is a mess that we are not dealing with.
	set result [catch {eval exec xterm -e rcs -l [cell_file $old_cells]}]
	if { $result == 1 } {
	  # User cancelled locking one or more files.
	  msg -warn "VC Commit cancelled...\n"
	  return
	}
      }

      # This var lets the user use the same description for all files.
      set use_for_all 0
      set yes_to_all 0
      set VC_PERSIST(state) [use_first VC_PERSIST(state) \
	'[lindex $VC_OPTIONS(state_list) 0]]
      foreach cell $cells {

	if { ! $use_for_all } {

	  set prop_list ""
	  lappend prop_list [list "Keep File Locked" \
	      VC_PERSIST(keep_lock) -binary]
	  lappend prop_list [list "Force check-in even if not different" \
	      VC_PERSIST(force) -binary]
	  lappend prop_list [list "Revision Description:" \
	      VC_PERSIST(description) -entry -width 30]
	  #lappend prop_list [list "Revision State:" \
	      VC_PERSIST(state) -choice $VC_OPTIONS(state_list)]
	  lappend prop_list [list "Use these options for all files committed now:" \
		use_for_all -binary]
	  set title "VC commit cell $cell"
	  if {![prop_menu2 -title $title $prop_list]} {
	    # cancelled - inform caller to abort.
	    return
	  }
	}


	set archive_exists [memq $old_cells $cell]

	if { $archive_exists } {
	  set archive_version [RCS::vcs_op get_tip_ver $cell]
	  set working_version [RCS::vcs_op get_work_ver $cell]
	  if { $archive_version != "" && $working_version != "" } {
	    if { $working_version < $archive_version } {
	      if { $yes_to_all } {
		msg "Cell $cell archive newer than working version; committed anyway.\n"
	      } else {
		set title "File is out of date"
		set message "Cell $cell archive newer than working version. \
		  Do you want to commit the file anyway,\
		  and possibly cover someone else's changes?"
		set choice [tk_dialog .dialog $title $message {} 0 Yes "Yes to All" Cancel]
		if { $choice == 2 } {
		  # Cancelled
		  return
		}
		if { $choice == 1 } {
		  set yes_to_all 1
		}
	      }
	    }
	  }
	}

	RCS::vcs_op commit -text $VC_PERSIST(description) \
	  -force $VC_PERSIST(force) \
	  -state $VC_PERSIST(state) \
	  -lock $VC_PERSIST(keep_lock) $cell
      }
      return
    }

    "update" {
      if { $force } {
	error "what are we doing here"
	return [RCS::vcs_op update \
	  -force $force -version $version $cells]
      }

      # Figure out which cells already have associated archive files.
      set old_cells ""
      set yes_to_alla 0
      foreach cell $cells {
	if {[RCS::vcs_op archive_exists $cell]} {
	  lappend old_cells $cell
	} else {
	  set title "Cell $cell"
	  set msg "Warning: no archive exists for cell $cell. \
	  This cell will not be updated."
	  if { ! $yes_to_alla } {
	    set choice [tk_dialog .dialog $title $msg {} 0 \
	    	Ok "Ok to All" Cancel]
	    if { $choice == 1 } { set yes_to_alla 1 }
	    if { $choice == 2 } {
	      # Cancelled
	      msg "VC update cancelled\n"
	      return 0
	    }
	  }
	}
      }

      # Ignore (do not update) cells that have no archive.
      set cells $old_cells
      if { $cells == "" } {
	msg "No cells to update\n"
	return 1
      }

      # Diff files to warn when overwriting a local file.
      set yes_to_allb 0
      set co_list ""	;# Cells that need to be checked out.
      set mod_list ""	;# modified cells, just need in memory version flushed.
      foreach cell $cells {
	set diff_status [RCS::vcs_op get_diff_status $cell]
	set mod_status [memq [cell_flags $cell] "modified"]
	if {$mod_status || $diff_status != 0 } {
	  if { ! $yes_to_allb } {
	    set msg "Local copy of cell $cell is modified.  Overwrite?"
	    set title "Cell $cell"
	    set choice [tk_dialog .dialog $title $msg {} 0 \
		  Yes "Yes to All" Cancel]
	    if { $choice == 1 } { set yes_to_allb 1 }
	    if { $choice == 2 } {
	      # Cancelled
	      msg "VC update cancelled\n"
	      return 0
	    }
	  }
	}
	if {$diff_status != 0} {
	  lappend co_list $cell
	} elseif {$mod_status} {
	  lappend mod_list $cell
	} else {
	  msg "Cell $cell not modified; not updated.\n"
	}
      }

      # Check out all files in one swell foop.
      if { $co_list != "" } {
	RCS::vcs_op update -version "$version" $co_list
      }

      # Flush in memory copies of all modified cells.
      # This also updates the vc_rcs_version prop to the
      # actual checked out version.
      foreach cell [concat $co_list $mod_list] {
	:load $cell
	msg "Updating cell $cell\n"
	if {[msg_catch :flush result info warn]} {
	  msg -warn "$result\n"
	}
      }
      return
    }

    "lock" {
      if { $VC_OPTIONS(use_mmi_lock) } {
	vcs_mmi_lock lock RCS $cells
      } else {
	RCS::vcs_op lock $cells
      }
    }

    "unlock" {
      if { ! $VC_OPTIONS(permit_break_lock) } {
	msg -warn "File is locked by $locker.  Contact that user to unlock the file.\n"
	return 0
      }
      if { $VC_OPTIONS(use_mmi_lock) } {
	vcs_mmi_lock unlock RCS $cells
      } else {
	RCS::vcs_op unlock $cells
      }
    }

    default {
      msg "warning: Unrecognized RCS request: vcs_operation $what\n"
    }
  }
}


proc RCS::vcs_op {what args} -desc {
  Low level direct RCS operations.
} -doc {
  <what> can be:
  commit - check in cells
  update - check out cells
  lock - lock cells
  unlock - unlock cells
  get_user - return current user as known by RCS
  get_tip_ver - return version number of tip, or "" if none.
  get_work_ver - return version number of local working file, or "" if unknown.
  get_locker - return locker of specified version, or tip if -version not
    specified, or "" if none.
} {
  global VC_OPTIONS

  set cells [call_keyword $args \
	[list {text ""} {lock 0} {force 0} {version ""} {state ""}]]

  # RCS rlog totally barfs if there is a quote in the description or state.
  if {[string first {"} $text] != -1} {
    error {Description can not contain the quote character (")}
  }
  if {[string first {"} $state] != -1} {
    error {State can not contain the quote character (")}
  }

  switch $what {
    "commit" {
      if {$cells == ""} {error "No cells given to vcs_op commit"}
      if { $text == "" } { set text "empty" }
      set cmd [list ci -t- -m$text]
      if {$lock} {lappend cmd "-l"} else {lappend cmd "-u"}
      if {$force} {lappend cmd "-f"}
      if {$state != ""} {lappend cmd -s$state}
      eval lappend cmd [cell_file $cells]

      # We still need to lock the files using the rcs locking
      # mechanism, so that we can check them in.
      # Files that do not exist will generate errors, but it
      # still goes ahead and locks the files that exist,
      # so just totally ignore the return stat.
      catch {eval exec rcs -q -l [cell_file $cells]}

      # ci writes stuff to stderr (unless -q specified), which causes
      # the tcl exec command to return an error.  So redirect stderr.
      lappend cmd "2>@stdout"
      if {[catch {eval exec $cmd} result]} {
	msg -warn "RCS ci $cells failed:\n$result\n"
	return 0
      }
      msg "RCS ci $cells: $result\n"

      # Note: RCS creates unlocked files read-only by default.
      if { $lock == 0 && $VC_OPTIONS(unmod_file_mode) == "rw" } {
	if {[catch {eval exec chmod 0666 [cell_file $cells]} result]} {
	  msg "chmod failed: $result\n"
	}
      }

      # We need to know the version we just checked in.
      # We could :flush to update the vc_rcs_version prop
      # from what was actually checked out.  But instead,
      # save the newly checked in version, which may be faster.
      # We could also get the version by parsing the ci output,
      # or by grepping through the max file.  This also could be delayed
      # until we call vcs_op get_work_ver.
      global _VC_WORK_VER
      foreach cell $cells {
	set tmp [expr {$version != "" ? $version : [RCS::vcs_op get_tip_ver $cell]}]
	set _VC_WORK_VER($cell) $tmp
      }

      return 1
    }
    "update" {
      if {$cells == ""} {error "No cells given to vcs_op update"}
      # The -f flag is needed so co will over-write files that
      # have read-write permissions without trying to ask about it.
      set cmd [list co -f]
      if {$version != ""} {
	lappend cmd -r$version
      }
      if {$state != ""} {
	lappend cmd -s$state
      }
      eval lappend cmd [cell_file $cells]
      lappend cmd "2>@stdout"


      if {[catch {eval exec $cmd} result]} {
	msg -warn "RCS co $cells failed:\n$result\n"
	return 0
      }

      msg "RCS co $cells: $result\n"

      # Note: RCS creates files read-only by default, unless the co -l
      # option is specified.  The files are created read-only even if
      # we own the lock!!!   All that matters is if -l appeared
      # on the co command line.
      if { $VC_OPTIONS(unmod_file_mode) == "rw" } {
	if {[catch {eval exec chmod 0666 [cell_file $cells]} result]} {
	  msg "chmod failed: $result\n"
	}
      }
      return 1
    }
    "lock" {
      if {$cells == ""} {error "No cells given to vcs_op lock"}
      if {[catch {eval exec xterm -e rcs -l [cell_file $cells] 2>&stdout} result]} {
	msg -warn "RCS lock $cells failed:\n$result\n"
	return 0
      }
      msg "RCS lock: $result\n"
      return 1
    }
    "unlock" {
      if {$cells == ""} {error "No cells given to vcs_op unlock"}
      if {[catch {eval exec xterm -e rcs -u [cell_file $cells] 2>&stdout} result]} {
	msg -warn "RCS unlock $cells failed:\n$result\n"
	return 0
      }
      msg "RCS unlock: $result\n"
      return 1
    }

    "get_user" {
      global env
      return [use_first env(USER)]
    }

    "get_tip_ver" {
      if {[llength $cells] != 1 } {error "vcs_op get_tip_ver requires one cell"}
      set filename [cell_file $cells]
      if {[catch {set rlog [exec rlog -h $filename]}]} {
	return ""
      }
      return [RCS::extract_from_log "head" $rlog]
    }

    "get_work_ver" {
      if {[llength $cells] != 1} {error "vcs_op get_locker requires one cell"}
      # If the file was checked in during the current max session,
      # then the current version is in _VC_WORK_VER.
      # If the file was checked out before this session started,
      # or as the result of an update operation, use the vc_rcs_version prop.
      if {[info exists _VC_WORK_VER($cells)]} {
	return $_VC_WORK_VER($cells)
      } else {
	set prop [db_prop -def $cells vc_rcs_version]
	# This file is not archived, so forget it.
	if {$prop == ""} { return "" }
	set Dollar {$}
	regsub "^\\${Dollar}Revision: " $prop "" prop
	regsub {\$$} $prop "" prop
	return $prop
      }
    }

    "get_locker" {
      if {[llength $cells] != 1 } {error "vcs_op get_locker requires one cell"}
      set filename [cell_file $cells]
      if {[catch {set rlog [exec rlog -h $filename]}]} {
	# No such file.
	return ""
      }

      if { $version == "" } {
	# Check for lock on tip revision.
	# Find tip revision first.
	set version [RCS::extract_from_log "head" $rlog]
      }

      # The tip revision is on a separate line similar to: "head: 2.19"
      regsub "^.*\nlocks:\[ \t\]*\n" $rlog "" tmp
      foreach thingy [split $tmp \n] {
	# Lock lines start with whitespace.
	if {[regexp {^[a-zA-Z]} $thingy]} { break }
	setl {lock_name lock_version} [string trim $thingy]
	if { $lock_version == $version } { return [string trimright $lock_name :] }
      }

      # No lock found for version.
      return ""
    }

    "archive_exists" {
      # Return 1/0 if archive exists or not.
      # We could do an rlog, but its faster just to look and see if
      # the file exists.
      if {[llength $cells] != 1 } { error "vcs_op archive_exists requires one cell" }
      set filename [cell_file $cells]
      set path [file dirname $filename]
      if { $path == "" } { set path "." }
      set tail [file tail $filename]
      return [file exists $path/RCS/${tail},v]
    }

    "get_diff_status" {
TODO: Must grep -v ^vc_
      # rcsdiff returns status indicating if file is modified w.r.t. archive.
      if {[llength $cells] != 1 } { error "vcs_op get_diff_status requires one cell" }
      set filename [cell_file $cells]
      return [catch {exec rcsdiff $filename >&/dev/null}]
    }

    default {
      error "Unrecognized RCS request: vcs_op $what\n"
    }
  }
}

proc RCS::extract_from_log {keyword string} -desc {
  Get the "keyword" string from the RCS log output.
} {
  # The tip revision is on a separate line similar to: "head: 2.19"
  regexp "$keyword:\[^\n\]*" $string tmp
  regsub "$keyword *: *" $tmp "" result
  return [string trim $result]
}



#proc RCS::vcs_archive_exists {cell} {
  #return [expr {[RCS::vcs_op get_tip_ver $cell] != ""}]
#}


proc RCS::UNUSED_vcs_get_diff {cell} -desc {
  Return true if filename is different from archive tip revision.
} {
  # rcsdiff returns status indicating if file is modified w.r.t. archive.
  set filename [cell_file $cell]
  set result [catch {exec rcsdiff $filename >&/dev/null}]

  if { $result == 0 } {
    # File identical to archive.
    return 0
  } else {
    # File modified, or something wrong.
    return 1
  }

  # The following not needed, because we are not using keywords in max/sue
  # files.

  # A file that differs only in the RCS keywords is not really different at all.
  set exp {\$(Author|Date|Header|Id|Locker|Log|RCSfile|Revision|Source|State):[^$]*\$}
  # Remove RCS keywords.
  regsub $result $exp "" result

  # Remove the separators added by rcsdiff
  #regsub {<<<<<<<\n} $result "" result
  #regsub {>>>>>>>\n} $result "" result
  #regsub {=======\n} $result "" result

  set result [string trim $result]
  if { $result == "" } {
    return 1
  } else {
    return 0
  }
}
