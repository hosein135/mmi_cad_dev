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

set RCSVERSION(cell.tcl) { $Revision: 1.68 $ }

# Routines for loading/saving cells

global CELL

# Note: This is changing from (UNNAMED) to UNNAMED.
set CELL(UNNAMED) UNNAMED   ;# Name of the default max cell.

init_global CELL(default_suffix) -default ".max" -desc {
  suffix for max files
} -type STRING -flags READONLY

init_global CELL(backup_suffix) -default ".BAK" -desc {
  suffix for max backup files
} -type STRING -flags READONLY

init_global CELL(gcell_suffix) -default ".maxg" -desc {
  suffix for max generator cell (gcell) files
} -type STRING -flags READONLY

init_global CELL(gds_suffix) -default ".gds" -desc {
  default output suffix for gds files
} -doc {
  sets the search pattern in the file selector box
} -type STRING

init_global CELL(gds_suffixes) -default ".gds .strm .gdsii" -desc {
  list of suffixes for input gds files
} -doc {
  sets the search pattern in the file selector box
} -type STRING

# If the file is smaller than the cell_BACKUP_PERCENTAGE times the backup
# file then the the backup won't be overwritten.  Prevents accidental
# loss of data.
set cell_BACKUP_PERCENTAGE 0.2

proc cell_init {} -desc {
    Initialize cell module (called once at startup)
} {
    global MN_PATH_CELL MN_PATH_SYS_LIB MN_TECH
    set MN_PATH_CELL ""
  
    # New method to search for gcells (or other cells):
    # Look for "cells" sub-directory in technology directory first,
    # then in sub-directory max/cells in each dir on normal sys path.
    # Cell_path_add adds dir to front, so add dirs in reverse order:

    foreach path [lreverse $MN_PATH_SYS_LIB] {
      if {[file isdirectory $path/cells]} {
	cell_path_add $path/cells
      }
    }

    set name1 tech/${MN_TECH}/cells
    set path_name [mn_sys_find $name1]
    if { $path_name != "" && [file isdirectory $path_name]} {
      cell_path_add $path_name
    }

    # "." is already in the path, but move it to the front:
    cell_path_add "."
}

proc cell_path_add args -desc {
  add arbitrary number of directories to cell search path.
} -doc {

  Usage: [-optional] cell_path_add [dir1 ...]

  Returns current cell_path if no directories are specified.

  Expands args to absolute paths.
  Moves args to beginning of path, adding if not already present.

  The specified directories are not displayed in the list-boxes
  unless a cell is loaded from the directory.

} {
    global MN_PATH_CELL _CELL_GCELL_STARTUP_

    if {[lindex $args 0] == "-optional"} {
      set optional 1
      set args [lrange $args 1 end]
    } else {
      set optional 0
    }

    foreach dir [lreverse $args] {
      # make absolute path
      set dir [absolute_path $dir]
      if { ! [file isdirectory $dir] } {
	if { ! $optional } {
	  puts "warning: cell_path_add directory not found, ignored: $dir"
	}
	continue
      }
      set MN_PATH_CELL "$dir [l_remove_name $MN_PATH_CELL $dir]"

      if {[use_first _CELL_GCELL_STARTUP_] == "0"} {
	# load gcells
	_load_gcells $dir
      }

      # make sure this directory is visible
      _list_box_fill_dir $dir
    }
    
    if {[llength $args]} {
      # Make sure future cell loads will try again
      # to search the path on disk.
      catch {db_read_retry}
    }
    return $MN_PATH_CELL
}

proc cell_path_find {{-report_dups} {-exts ""} cell} -desc {
  Find the cell on the cell path.  Return all matching files.
} -doc {
  -report_dups prints a warning message if the file is found multiple
    places in the path.
  -exts specifes a list of file extensions to try; default .max
} {
  global MN_PATH_CELL CELL
  set locations ""

  if {$exts == ""} {
    set exts $CELL(default_suffix)
  }

  foreach dir $MN_PATH_CELL {
    foreach ext $exts {
      set filename [file join $dir $cell$ext]
      if {[file exists $filename]} {
	lappend locations $filename
      }
    }
  }

  if {$report_dups && [llength [_cell_rm_loc_dups $locations]] >= 2} {
    msg "Warning: $cell is found in multiple locations (using first): $locations\n"
  }

  return $locations
}


proc _cells_modified {} -desc {
  lists names of buffers that have changes that will be lost if not saved.
} {
  set list {}
  foreach cell [split [db_cells] \n] {
      setl {name flags file} { "" "" "" }
      setl {name flags file} $cell 
      set internal [expr [memq $flags internal] || [memq $flags generated]]
      set modified [memq $flags modified]
      if { !$internal && $modified } {
	  lappend list $name 
      }
  }
  return [lsort $list]
} 

proc cell_info {cellname} -desc {
  Returns info on cell.
} -doc {
    Returns a two element list for the Max file associated with cell,
    in the form: "flags file".
    This command is a combination of the cell_file and cell_flags commands.

    Returns __NO_SUCH_BUFFER__ if the cell is not in memory.

    NOTE: If the filename contains a slash, the actual filename saved
    to disk will have slashes replaced with "{FS}".

    See also: db_cells
} {
  setl {name flags file} [db_cells $cellname]
  if {$name == ""} {
    return {__NO_SUCH_BUFFER__}
  } else {
    return [list $flags $file]
  }
}

# TODO: This is now broken!
proc _UNUSED_cell_cellname {filename} -desc {
  return the max cellname corresponding to filename
} -doc {
  strips the path prefix and .max suffix.
} {
  global CELL
  if { [string match "*$CELL(default_suffix)" $filename] } {
      set filename [file rootname $filename]
  }
  return [file tail $filename]
}

proc cell_in_memory {cellName} -desc {
    returns 1 if buffer exists and is "available", otherwise returns 0
} -doc {
  If there is an instance of a cell that had not been read in, there will be an
  entry in db_cells, but it will not be marked "available".
} {
  setl {name flags file} [db_cells $cellName]
  return [memq $flags "available"]
} 

proc cell_empty {cellName} -desc {
    returns 1 if cell is "unavailable" (ie, has not been read in),
    or has no file attached and is not modified.  otherwise 0
} -doc {
  This does not do what you think.  It does not actually
  look at the contents of the cell.  So if a cell was created
  and has not been written to disk, it is considered non-empty,
  regardless of its contents.  Observe:
    db_cell_new foo
    cell_empty foo
    -> returns 1 (empty)
    db_cell_new bar dir/bar.max
    cell_empty foo
    -> returns 0 (not empty)

  Also, if the cell as not been loaded, this returns empty.
  You need to do lay_interals -area or cell_load_cell -opt to make sure the
  cell is loaded, if it exists, before calling this.
} {
    setl {flags file} [cell_info $cellName]

    if {![memq $flags "available"]} {
	return 1
    }

    if {![memq $flags "modified"] && $file=={}} {
	return 1
    }

    return 0
}

proc cell_file {cellNames} -desc {
  Returns the path Max file associated with cell(s).
} -doc {
  Example:
	cell_file bit_cell
  would return /home/demo/example/bit_cell.max.

  Returns __NO_SUCH_BUFFER__ if cell not in memory.
} {
  if {[string first " " $cellNames] == -1} {
    set info [cell_info $cellNames]
    if { $info == "__NO_SUCH_BUFFER__" } { return $info }
    setl {flags file} $info
    return $file
  } else {
    set result ""
    foreach cell $cellNames {
      lappend result [cell_file $cell]
    }
    return $result
  }
  return $result
}

proc cell_flags {cellName} -desc {
  return flags associated with cell.
} -doc {
  It returns __NO_SUCH_BUFFER__ if the cell is not in memory,
  and it has never existed.  If the cell previously existed
  and has been deleted, max may keep a copy of the cell in memory
  but unset the "available" flag to indicate that it doesnt really exist.
  To tell for sure that a cell does not exist, as max thinks
  of such things, you have to check for the "available" flag.
  Try using cell_in_memory instead.

  The typical flags for a cell are: modified, available (in memory),
  readOnly, and drcPending.
} {
    set info [cell_info $cellName]
    if { $info == "__NO_SUCH_BUFFER__" } { return $info }
    setl {flags file} $info
    # The flags is a space if it is empty.  Return a real empty instead.
    return [string trim $flags]
}


proc _cell_file_box {heading args} -desc {
  open a file box to let user select a filename
} -doc {
  returns filename, including absolute path;
  returns {} if user cancels.		

  USAGE:
    _cell_file_box heading [-ext extension_with_dot] [-file filename] \
      [-path dirname] [-optext extension_with_dot]

  If -ext specified, popup error message and return "" if
  extension does not match.
  If -optext specified, it is the suggested extension in the
  popup file box, but return whatever the user entered.
  If -file or -path, show those in the popup file box.
  Example:
    setl {dir cell ext} [_cell_file_box "Enter filename" -ext .max]
} {
    global CELL 

    set options [list {ext ""} {optext ""} {file ""} {path ""}]
    call_keyword $args $options

    if { $ext != "" } {
      set pattern *$ext
    } elseif { $optext != "" } {
      set pattern *$optext
    } else {
	set pattern *$CELL(default_suffix)
    }

    set cmd [list fs_box -message $heading -pattern $pattern]
    if { $file != "" } {
      lappend cmd -filename
      lappend cmd $file
    }
    if { $path != "" } {
      lappend cmd -pathname
      lappend cmd $path
    }
    set filename [eval $cmd]
    update idletasks

    # if nil, file selector box cancelled - just return {}
    if {$filename == ""} {
        return {}
    }

    setl {retdir retcell retext} [split_file_name $filename]
    if { $ext != "" } {
      if { $retext != "" && $retext != $ext } {
	error "'$retdir/$retcell$retext' invalid file extension,\
	    should be '$ext'"
	return ""
      }
      set retext $ext
    }

    return [list $retdir $retcell $retext]
}


proc max_gcell_init {} -desc {
  insure that gcells are properly loaded
} -doc {
  During max start up, any gcells in directories
  specified in cell_path_add commands are ignored,
  because it is not safe to load them yet.
  This proc is called when it is safe to process the gcells.
  After this, gcells will be loaded as soon as cell_path_add is issued.
} {

  global _CELL_GCELL_STARTUP_

  if {[use_first _CELL_GCELL_STARTUP_] != 0} {

    # insure that the current directory is first
    cell_path_add .
    # load any gcells from the autopath
    foreach dir [cell_path_add] {
      # load gcells
      _load_gcells $dir
    }
    set _CELL_GCELL_STARTUP_ 0
  }
}


proc cell_load_finish {{-edit}} -desc {
  Perform any house keeping required after loading a new root cell.
} -doc {
  This should really be part of the :load command.
  If -edit, clean up after a :edit command, which is slightly different
  because the rootcell has not changed, only the edit cell.
} {
  # remove feedback and other annotations
  if {!$edit} {
    clear_annotations
    feedback clear
  }
  sel_clear
  _label_lbox_fill	;# If listbox visible, update with ports in new cell.

  # Make sure the box is defined.
  if { [layt_box dontcare] == "" } {
    setl {x1 y1 x2 y2} [lay_bbox]
    if { $x2 - $x1 <= [res] } {
      # Empty cell, probly
      # Instead of making box a point, put it at one micron.
      layt_box user 0 0 1 1
    } else {
      eval layt_box exact [lay_bbox]
    }
  }
}


proc _cell_rm_loc_dups {files} -desc {
  Remove duplicate filenames from files.  Chase down symlinks and compare real filenames.
} {
  set new_list ""
  set id_list ""
  foreach file $files {
    file stat $file statbuf
    # If the inode is the same, the files are very probably the same file.
    # Should check the machine, too, but that is quite a long shot.
    set ino [use_first statbuf(ino)]
    if {[lsearch -exact $id_list $ino] == -1} {
      lappend new_list $file
      lappend id_list $ino
    }
  }
  return $new_list

  # This did not work because one of the directories in the path
  # could be a link, too:
  set real_list ""
  foreach file $files {
    # get the "real" file name
    set real $file
    while {[file type $real] == "link"} {
      set real [file readlink $real]
    }
    set real [absolute_path $real]

    # If we havent seen this "real" filename, add it to the list of files.
    if {[lsearch -exact $real_list $real] == -1} {
      lappend new_list $file
      lappend real_list $real
    }
  }

  return $new_list
}


proc cell_load_cell {{-opt} cell} -desc {
  Replaces :load.  Load the specified cell, which must not be a path or include the .max suffix.
} -doc {
  If -opt and file is not found, it does NOT create an empty cell or complain.
  If multiple files found on the cell path (MN_PATH_CELL) that are really
  different files and not just links to each other or different
  paths that lead to the same file, a warning is printed.
} {
  if {[cell_in_memory $cell]} {
    # Just load it into the current window
    :load $cell
    return
  }

  set locations [cell_path_find -report_dups $cell]

  if {[llength $locations] == 0} {
    if {$opt} {return}
    # File does not exist on disk.  Create it if necessary.
    :load $cell
    return
  }

  cell_load_file [lindex $locations 0]
}


proc cell_load_file {filename} -desc {
  Load the specified filename as a max cell.  Filename is like: dir/cell.max
} -doc {
  Notes:
  :load REQUIRES just a cell name, with no path and no .max extension.
} {
  global CELL MN_PATH_CELL
  set dir [file dirname $filename]
  set cell [file tail $filename]
  if {[file extension $filename] == $CELL(default_suffix)} {
    set cell [file rootname $cell]
  }

  # OK, now we are ready.
  set save_path $MN_PATH_CELL
  set MN_PATH_CELL $dir
  unwind_catch {
    :load $cell
    # If the cell did not exist, the :load will error, so this will not be called.
    # We do this NOW, in case a tcl program calls cell_load followed
    # by a verilog operation.  Eg, this happens when sue does a cross-probe:
    # it loads the cell and then immediately does a fplan_sel_net,
    # which needs verilog loaded.
    # We ALSO check for newly loaded cells after every interactive commands,
    # to catch cases where cells were loaded without tcl knowing,
    # for example, from lay_internals, or DRC.
    if {![nl2_loaded -cell $cell]} {
      fplan_verilog_auto_load -maxfile $filename
    }
  } always {
    set MN_PATH_CELL $save_path
  }
}


proc cell_load {{-search} {cell ""} {dir ""} } -desc {
  load cell into current window and clear edit stack!
} -doc {
  If a directory is specified, attempt to load the given cell into current window,
  and adds dir to the cell search path.
  If buffer already exists for cell with different "dir", an error results.

  If -search, directory must *not* be specified.  Search for the
  cell on the current cell path (MN_PATH_CELL).  Return TRUE
  if cell was successfully loaded, or was already loaded.

  If neither -search nor directory is specified, either in dir or in cell,
  cell must already be in memory.  Use cell_load ./cell to load
  cell in current directory.

  2/12/02: Formerly, this function allowed the cell to be a unix
  pathname, but not that cell names may contain a slash, this 
  is no longer supported.
} {
    global CELL MN_PATH_CELL MN_TECH

    if {$cell == ""} { return }

    # insure gcells are loaded
    max_gcell_init

    # 2/12/02: Now that cell names may contain slash, the cell name may
    # not include a directory.

    if {0} {
      # See if cell name includes a directory.  If so, put it in dir,
      # and set cell to just the cell name.
      if { [string first "/" $cell] >= 0 } {
	  if {$dir != {}} {
	      error "invalid dir argument to cell_load: $cell $dir"
	  }
	  set dir [file dirname $cell]
	  set cell [file tail $cell]
      }
    }

    # Remove any ".max" suffix.
    # This fails if someone has something goofy like foo.max.gds
    # or foo.max.max
    if { [string match "*$CELL(default_suffix)" $cell] } {
	set cell [file rootname $cell]
    }

    # cell already in memory case
    if { [cell_in_memory $cell] } {

	set file_name [cell_file $cell]
	# check dir
	if {$file_name == {}} {
	    if {$dir != {}} {
		error "Cannot load '$dir/$cell':  cell buffer exists, and is not attached to that file.\n"
	    }
	} else {
	    setl { dir1 cell1 ext1 } [split_file_name $file_name]

	    if {$dir != "" && $dir != $dir1} {
		error "Cannot load '$dir/$cell':   '$dir1/$cell1' already loaded!\n"
	    }
	    set dir $dir1
	}

    # cell not in memory case	
    } else {
	if {$dir == ""} {
	    if {$search} {
	      set location [lindex [cell_path_find $cell] 0]
	      if {$location == ""} {
		error "Cell '$cell' not found on path: $MN_PATH_CELL"
	      }
	      setl { dir cell2 ext2 } [split_file_name $location]
	    } else {
	      # Old message:
	      #error "Cell buffer '$cell' not found!\n"
	      error "cell_load: Cell buffer '$cell' not in memory!\n"
	    }
	}

	set file $dir/$cell$CELL(default_suffix)

	# check that file is readable
	if { ![file readable $file] } {
	    error "Can't read '$file'\n"
	}

	#check file technology
	set tech [db_cell_file_tech $file]
	if { $tech != $MN_TECH}  { 
	    error  "File '$file' has wrong technology ($tech instead of $MN_TECH)\n" 
	}
    }

    # add dir to path and load cell
    # Note that cell_path_add moves directory to beginning of dir search list.
    cell_path_add $dir
    cell_load_cell $cell
    
    # This should be part of :load, but it is in tcl:
    cell_load_finish

    edit_stack_clear

    view_cell
}


proc cell_load_files {names} -desc {
  Load list of cells and gds files.
} -doc {
  Used to load filenames given on command line.
  All cells in list are read into memory, and the first cell is loaded
  into the current layout window.

  Any such names with an extension other than .max are assumed
  to be gds files and loaded as such.

  The directories containing the cells are added to the cell path.
} {
    global CELL
    set first_good_cell ""
    set first_good_dir ""

    cursor_busy 1

    foreach fname $names {

      set tmp [string trimright [absolute_path $fname]]

      setl {dir cell ext} [split_file_name $tmp]

	if {$ext == "" || $ext == $CELL(default_suffix) || \
		$ext == "."} {
	    #MAX FILE
	    
	    #attempt to load cell
	    # TODO: Fix this msg_catch!!!
	    # Note: this msg_catch may catch messages from gcell_load
	    # that are called as a result of reading this file.
	    # We dont want gcell_load to popup a menu, because
	    # it is called from inside max, so defer the popup
	    # until now.
	    set code [msg_catch [list cell_load $cell $dir] result]
	    
	    if { $code != 0 } {
		# FAILURE
		if { $result == {} } { set result "Could not load '$fname'\n" }
		msg -warn $result
	    } else {
		# SUCCESS
		if { $first_good_cell == "" } { 
		    set first_good_cell $cell
		    set first_good_dir $dir
		}
	    }
	} elseif {1 || $ext == $CELL(gds_suffix)} {
	    # assume everything else is a gds file (what else could it be?)

	    #GDS FILE

	    #attempt to read gds file
	    set return [cell_load_gds $fname 1]
	    if { $return == "" } {
		# FAILURE
		set result "Could not read GDS-II file '$fname'\n"
#		msg -warn $result
	    } else {
		# SUCCESS
		if { $first_good_cell == "" } { 
		    set first_good_cell $return
		    set first_good_dir ""
		}
	    }
	} else { 

	    #BAD FILE EXTENSION
	    msg -warn "'$dir/$cell$ext' not loaded:  unrecognized file extension'\n"
	    continue
	}
    
	
	# load first good cell into current layout window
	if { $first_good_cell != ""} { 
	    cell_load $first_good_cell $first_good_dir 
	}
    }
    cursor_busy 0
}

proc cell_new {} -desc {
  prompt user for new cell name, create cell and load into current window
} {
  global CELL

  setl {dir cell ext} [_cell_file_box "New File:" -ext $CELL(default_suffix)]

  # if nil, file selector box cancelled -- do nothing
  if {$cell == ""} { 
    return 
  }

  # make sure we don't "shadow" an existing file
  if { [file exists $dir/$cell$CELL(default_suffix)] } {
	error "file $dir/$cell$CELL(default_suffix) already exists!"	
  }

  set flags [cell_flags $cell]
  if { $flags == "__NO_SUCH_BUFFER__" } {
      # create the new cell
      db_cell_new $cell $dir/$cell$CELL(default_suffix)
  } elseif { ! [memq $flags "available"] } {
      # place holder buffer already exists - rename it"
      msg_catch [list :load $cell] ret info war
      sel_cell .
      :edit
      sel_clear
      db_cell_rename $cell $cell $dir/$cell$CELL(default_suffix)
  } else {
      error "cell $cell already exists!"	
  }

  # and load into current window
  cell_load $cell $dir
}

proc cell_open {} -desc {
prompt user for cell name and load into current window
} {
  global CELL list_box max_win

  setl {dir cell ext} [_cell_file_box "Load File:" -ext $CELL(default_suffix)]

  # if nil, file selector box cancelled -- do nothing
  if {$cell == ""} { 
    return 
  }

  cell_load $cell $dir

  # make sure this directory is visible
  _list_box_fill_dir $dir
}

# 5/00, pat: modified the "Copy Cell" and "Save As" commands as per
# Max/Sue meetings (more accurately, fights) held in April 2000.
# The issues are:
# 1.  Should you permit the cell name to be the same?
# 2.  After Save As, should you edit the newly created cell?
# 3.  Should in-memory references to the cell be changed?
# 4.  Should the old cell be deleted from memory?
# The decisions were: 1 NO, 2 YES, 3 NO, 4 not discussed.
# The first decision was made to prevent the user from accidently
# modifying the design hierarchy in the event the new cell is also
# on the path.
# I am putting in my two cents here in the comments:
# In general, when there are two reasonable behaviors for a command,
# and its not obvious which behavior is going to happen,
# then you should do a popup to ask which behavior is desired,
# unless the command is used so often that a popup would be objectionable.
# There are legitimate reasons for desiring either behavior.
# If all you want to do is make an archival backup of the current cell,
# then it makes sense to me to allow the user to "Save As" a copy
# of the cell in some directory that is not on the path.
# Especially in this particular case, you can detect when a conflict occurs
# and only do the popup then, so there is no reason not to.
#
# TODO:
# The solution is to put two radiobutton choices on the fs_box menu
# when "Save As" is invoked:
#   "o  Save cell with new name and edit new copy of cell"
#   "o  Make Backup Copy of cell"
# If making a backup copy, they do NOT want to edit the new
# copy or cell_path_add the cell.
# OTHER TODO:
# If saving with new name, we should check for path conflicts immediately,

proc cell_copy {{save_as 0}} -desc {
  prompt user for new buffer name (and directory), then copy edit cell into it 
} -doc {
  If save_as is 1, do "Save As" instead of "Copy Cell".
  Note that there are several ways to hurt yourself with this routine:
  If you change the cell name and other cells refer to this cell,
  those references will not be changed, they will continue to
  refer to the original cell.
  If you change the path of an existing cell, and the original cell
  has already been written, and both directories are in the max cell path,
  then you will have a conflict the next time you start max.
} {
  global CELL

  # find the directory to open file box on
  set src_cell [lay_editcell]
  set src_file [cell_file $src_cell]
  if { $src_file == "" } {
    # It is the (UNNAMED) cell, which has no file associated yet.
    set src_file [absolute_path ./$src_cell$CELL(default_suffix)]
  }
  setl {src_dir junk1 junk2} [split_file_name $src_file]

  # open file box, to let user select file
  if { $save_as } {
    set title "Save cell $src_cell as:"
  } else {
    set title "Copy cell $src_cell to:"
  }
  setl {dst_dir dst_cell dst_ext} \
    [_cell_file_box $title -path $src_dir -ext $CELL(default_suffix)]

  # if nil, file selector box cancelled -- do nothing
  if {$dst_cell == ""} {
    return 
  }

  set dst_file ${dst_dir}/${dst_cell}$CELL(default_suffix)
  set old_path [cell_file $dst_cell]


  if { $src_cell == $dst_cell } {
    # It makes no sense to use "Copy Cell Buffer" if the name is the same.
    # For "Save As", we all agreed that we would not allow this, for now,
    # in order to prevent accidently ending up with two copies
    # of a cell on the path.   I later talked to Mark, and he said
    # a popup would be acceptable when a conflict was detected.
    max_error "cell_copy: error: Cell name was unchanged.  Pick a different cell name, or use 'Change Path of Cell...' command to change path of existing cell."
    return
  }

  if { $dst_cell == "$CELL(UNNAMED)" } {
    # This is pretty unlikely, since they have to change the name.
    max_error "cell_copy: error: You must provide a new name for the cell."
    return
  }

  set old_deleted 0

  # See if the new cell buffer name already exists...
  if { $old_path != "__NO_SUCH_BUFFER__" } {
    # As a courtesy to the user, we will optionally delete the cell first.
    # If it is "Copy Cell Buffer" command, and the file already exists,
    # then the user is asking to delete the existing file
    # and then shadow it with a different file!  This is wierd,
    # so we will print a verbose message.
    if { $save_as == 0 && [file exists $dst_file] } {
      set message "The file $dst_file already exists, and is already being edited!  Do you really want to delete the in-memory copy, and then shadow and possibly overwrite the disk version?"
    } else {
      set message "Cell $dst_cell is already being edited.  Do you want to delete it first?"
    }
    set choice [tk_dialog .dialog {Delete existing cell?} $message {} 1 \
		{Yes} {Cancel}]
    if { $choice != 0 } { return }
    db_cell_delete $dst_cell
    set old_deleted 1
  }

  # make sure we don't "shadow" an existing file
  if { ! $old_deleted && [file exists $dst_file] } {
    if { $save_as } {
      # We are not just shadowing it, we are over-writing it right now!
      set message "The file $dst_file already exists!  Do you want to overwrite it?"	
    } else {
      set message "The file $dst_file already exists!  Do you really want to shadow and possibly overwrite it?"	
    }
    set choice [tk_dialog .dialog {Shadow existing cell?} $message {} 1 \
		{Yes} {Cancel}]
    if { $choice != 0 } { return }
  }

  if {$save_as && $src_cell == "$CELL(UNNAMED)"} {
    db_cell_rename "$CELL(UNNAMED)" $dst_cell $dst_file
  } else {
    # create the destination cell
    db_cell_new $dst_cell $dst_file

    # do the copy
    db_cell_copy $dst_cell 
  }

  # and load into current window
  cell_load $dst_cell

  if { $save_as } { cell_save }
}

proc cell_change_path {{-cell ""} {dirname ""}} -desc {
  Change edit cell directory to that specified.
} -doc {
  If no dirname specified as argument, prompt for one.
  We do not allow the cell name to be changed, because it is unclear
  what to do if other cells refer to this one.
  The single exception is if the cell name is (UNNAMED),
  in which case we allow the user to rename the cell and
  change the path simultaneously.
} {
  global CELL
  if {$cell == ""} {
    set oldcell [lay_editcell]
  } else {
    set oldcell $cell
  }
  set oldfile [cell_file $oldcell]
  if { $oldfile == "" } {
    # This cell has no file associated yet.  Might be UNNAMED,
    # or some other cell the user created.
    set oldfile [absolute_path ./$oldcell$CELL(default_suffix)]
  }
  setl {olddir oldcell oldsuf} [split_file_name $oldfile $CELL(default_suffix)]

  # Prompt for a directory name
  if {$dirname == ""} {
    set filename [fs_box -message "Enter new path for cell:" \
	    -filename $oldfile -dironly_ok 1]
  } else {
    set filename $dirname
  }

  # if nil, file selector box cancelled -- do nothing
  if {$filename == ""} {
    return 0
  }

  # It is ok to just specify the directory in the fs_box.
  if {[file isdirectory $filename]} {
    set filename [file join $filename $oldcell$oldsuf]
  }
 
  # Newsuf will be empty if the user did not specify an extension.
  # We dont care.  The extension is going to be .max
  setl {newdir newcell newsuf} [split_file_name $filename $CELL(default_suffix)]
  set newfile [file join $newdir $newcell$CELL(default_suffix)]
  if {$newdir == ""} {
    # malformed name
    max_error "cell_change_path: error: Bad cell name."
    return 0
  }

  if { $newsuf != "" && $newsuf != $CELL(default_suffix) } {
    max_error "cell_change_path: error: '$newfile' invalid file extension, should be '$ext'"
    return 0
  }
   
  if {![file isdirectory $newdir]} {
    # not a directory, abort.
    # We should probably check for write permission on the directory, too,
    # but we dont.
    max_error "cell_change_path: error: $newdir is not a valid directory."
    return 0
  }

  if {$newcell != $oldcell && $oldcell != "$CELL(UNNAMED)"} {
    # The user is trying to change the name also.
    # Its ok if the name was (UNNAMED), otherwise disallowed.
    max_error "cell_change_path: error: Can not change file name, only path.  Maybe you want the 'Save As' command."
    return 0
  }

  if { $newdir != $olddir } {

    # make sure we don't "shadow" an existing file
    # If user did not actually change the directory, dont print the warning.
    if { [file exists $newfile] } {
      set message "The file $newfile already exists!  Do you really want to shadow and possibly overwrite it?"	
      set choice [tk_dialog .dialog {Warning: Shadow existing cell?} $message {} 0 \
		{Yes} {Cancel} ]
      if { $choice != 0 } { return 0 }
    }
  }

  db_cell_rename $oldcell $newcell $newfile
  cell_path_add $newdir
  return 1
}

proc cell_rename {{save 0}} -desc {
  prompt user for new buffer name (and directory), then rename edit cell to it 
} -doc {
    If save argument is 1, also save the cell now.
    Note: if other cells refer to the current cell, the references
    will be changed to refer to the new name, but only if those
    cells are currently loaded into max.
} {
  global CELL

  # find the directory to open file box on
  set file [cell_file [lay_editcell]]
  set path [file dirname $file]

  # open file box, to let user select file
  if { $save } {
      set fs_title "Save cell [lay_editcell] as:"
  } else {
      set fs_title "Rename cell [lay_editcell] to:"
  }
  #setl {dir cell ext} [_cell_file_box $fs_title -ext $CELL(default_suffix) -file $file]

  setl {dir cell ext} [_cell_file_box $fs_title -ext $CELL(default_suffix) -path $path]

  # if nil, file selector box cancelled -- do nothing
  if {$cell == ""} { 
    return 
  }

  # Make sure the cell is not already loaded, or db_cell_rename will
  # complain, which is very confusing after we just asked is it
  # it ok to over-write the existing cell!
  if {[cell_flags $cell] != "__NO_SUCH_BUFFER__"} {
      set message "The cell $cell is already loaded!  Delete it first."
      tk_dialog .dialog {Error} $message {} 0 {OK} 
      return
  }

  # make sure we don't "shadow" an existing file
  if { [file exists $dir/$cell$CELL(default_suffix)] } {
    set message "The file $dir/$cell$CELL(default_suffix) already exists!  Do you really want to shadow and possibly overwrite it?"	
    set choice [tk_dialog .dialog {Shadow existing cell?} $message {} 0 \
		{Yes} {Cancel} ]
    if { $choice != 0 } { return }
  }

  # do the rename
  db_cell_rename [lay_editcell] $cell $dir/$cell$CELL(default_suffix)
  if { $save } { cell_save }
}


proc cell_save {} -desc {
  save editcell in current window to disk.  Return status 0 or 1.
} {
    global CELL cell_BACKUP_PERCENTAGE

    set cell [lay_editcell]

    # if (UNNAMED) first prompt user for name and rename it!
    if { $cell == "$CELL(UNNAMED)" } {

      set old_name $cell

      while {1} {
	setl {dir cell ext} [_cell_file_box "Save cell $CELL(UNNAMED) as:" -ext $CELL(default_suffix)]

	# if nil, file selector box cancelled -- do nothing
	if {$cell == ""} { 
	    return 0
	}

	# make sure we don't overwrite an existing file
	if { [file exists $dir/$cell$CELL(default_suffix)] } {
	    max_error "cell_save: error: file $dir/$cell$CELL(default_suffix) already exists!"	
	    continue
	}
	break
      }

      db_cell_rename $old_name $cell $dir/$cell$CELL(default_suffix)
    }

    set filename [cell_file $cell]

    # if no file attached (e.g. if read in from gds), place in current
    # directory.
    if {$filename == ""} {
      set filename [absolute_path ./$cell.max]
      cell_path_add "."
    }

    # Don't overwrite read only file, unless file is archived!
    if {[file exists $filename] && ![file writable $filename] } {
      if {[vcs_archive_exists $cell]} {
	exec chmod a+w $filename
      } else {
	error "Cell '$cell' not saved, file '$filename' is not writable.\n"
      }
    }
    
    puts "writing cell \"$cell\" to $filename"

    # User can suppress auto backup by setting CELL(backup_suffix) to ""
    if {$CELL(backup_suffix) != "" && [vcs_get_type $cell] == "" } {
      # No VCS going on.  Create a backup file in current directory.
      catch [list file rename -force -- $filename $filename$CELL(backup_suffix)]
    }

    # backup the file before writing the new one.
    # Don't overwrite the backup if it looks like the user might be
    # hosing himself or MAX may be breaking.
    #if {[file exists $filename] && [file exists $filename$CELL(backup_suffix)] && \
    #	    [file size $filename] < \
    #	    [expr $cell_BACKUP_PERCENTAGE * [file size $filename$CELL(backup_suffix)]]} {
    #	puts "Not overwriting backup $filename$CELL(backup_suffix)"
    #    } else {
    # move the existing file to be a backup
    #	catch "exec \"mv\" -f $filename $filename$CELL(backup_suffix)"
    #    }

    # remove all existing gcell properties
    #    foreach prop [db_prop] {
    #      if {[is_gcell $prop]} {
    #	db_prop -delete $prop
    #      }
    #    }
    # set up properties for saving gcells
    #    global _GCELL_INSTANCES_
    #    foreach cell [db_kids] {
    #      if {[is_gcell $cell]} {
    #	db_prop $cell $_GCELL_INSTANCES_($cell) 
    #      }
    #    }

    vc_cell_save_hook

    set delete_flylines 1
    if {[string trim [db_flyline]] != ""} {
      set message "Do you want to save the flylines in the max file?"
      set delete_flylines [tk_dialog .dialog {Max Save Cell} $message {} 1 \
		{Yes} {No} ]
    }

    if {$delete_flylines} {
      # If the :save fails, flylines will have been deleted,
      # but the user can just hit undo to recover.
      undo_delim
      db_flyline -delete
      :save
      undo_to_delim
    } else {
      :save
    }
    return 1
}

proc cell_revert {} -desc {
  revert edit cell buffer to last version saved to disk
} {

    # ask user for confirmation
    set cell [lay_editcell]
    if { [memq [_cells_modified] $cell] } {
	set message "Really throw away changes to cell '$cell'?"
	set choice [tk_dialog .dialog {Max Revert Cell?} $message {} 0 \
		{Yes} {Cancel} ]
	if { $choice != 0 } { return }
    }

    sel_clear

    :flush
    cell_load_finish
}

proc cell_exit {} -desc {
  Exit max, BUT if modified buffers exist query user first.
} {
  set modList [_cells_modified]
  set numMod [llength $modList]
  set maxShown 30	

  set message "$numMod cell(s) have changed:\n\n\t[join $modList \n\t]"
  puts $message

  # if too many cells in list, truncate it to fit on screen 
  if {$numMod > $maxShown} {
      set modList [lrange $modList 0 [expr $maxShown - 1]]
      lappend modList "..." 		
      }

  if {$numMod > 0} {
      set message "$numMod cell(s) have changed:\n\n\t[join $modList \n\t]"
      global env
      set icon $env(MMI_TOOLS)/max/images/max_icon.xbm
      if {[file readable $icon]} {
	set icon @$icon
      } else {
	set icon ""
      }
      set choice [tk_dialog .dialog {max Exit} $message $icon 0 \
		      {Cancel} {Exit and Lose Changes} ]

      # discard and exit
      if { $choice == 1 } {
	msg_end
	mn_exit -nobackup 
      }

      # cancelled
      return
    }

  msg_end
  # no modified cells, just exit 
  mn_exit
}

proc cell_load_magic {} -desc {
  Prompt user for Magic file, and read it in, and load into current window.
} {
  global CELL

  setl {dir cell ext} [_cell_file_box "Magic File to Read:" -ext .mag]

  # if nil, file selector box cancelled -- do nothing
  if {$cell == ""} { 
    return 
  }

  # make sure we don't "shadow" an existing file
  if { [file exists $dir/$cell$CELL(default_suffix)] } {
	error "file $dir/$cell$CELL(default_suffix) already exists!"	
  }

  # create the new cell
  db_cell_new $cell $dir/$cell$CELL(default_suffix)

  # add dir to path
  cell_path_add $dir

  #read the magic file into the cell
  db_magic read $cell $dir/$cell.mag

  # and load into current window
  cell_load $cell $dir

  # assign filename to buffer 
  db_cell_rename $cell $cell $dir/$cell$CELL(default_suffix)

}

proc cell_import {} {
  global CELL
  set file_type "GDSII"
  set file_name ""

  set prop_list ""
  # 8/7/00: We decided LEF/DEF not ready to ship.
  #lappend prop_list [list "File Type:" file_type -radio {GDSII LEF DEF} \
	  -reload -separator]

  lappend prop_list [list "File Type:" file_type \
	  -radio {GDSII "Create tech file from GDS file"} \
	  -values {GDSII gds_input} \
	  -reload -separator]

  #### Options for GDS files #####

  lappend prop_list [list "GDSII Import Setup Options..." {} \
	  -button gds_import_setup -when {$file_type == "GDSII"}]

  lappend prop_list [list "GDSII File Name:" file_name \
	  -filename [list -message {GDSII File to Read:} \
		  -pattern [_cell_gds_suffix_list]] \
	  -width 40 \
	  -when {$file_type == "GDSII"}]

  #### Options for gds_input #####
  set tech_name "test"
  lappend prop_list [list "Output Technology name:" tech_name \
	  -entry -when {$file_type == "gds_input"}]

  lappend prop_list [list "GDSII File Name:" file_name \
	  -filename [list -message {GDSII File to Read:} \
		  -pattern [_cell_gds_suffix_list]] \
	  -width 40 \
	  -when {$file_type == "gds_input"}]

  #### Options for LEF files #####

  #lappend prop_list [list "LEF File Name:" file_name \
	  -filename [list -message "LEF File to Read" -pattern "*.lef"] \
	  -width 40 \
	  -when {$file_type == "LEF"}]

  #### Options for DEF files #####

  #lappend prop_list [list "DEF File Name:" file_name \
	  -filename [list -message "DEF File to Read" -pattern "*.def"] \
	  -width 40 \
	  -when {$file_type == "DEF"}]

  set ret [prop_menu2 -title "Import File" $prop_list]
  # If user hit cancel
  if { $ret == 0 } { return }

  switch -- $file_type {
    "gds_input" {
      if { $file_name == "" } {
	max_error "cell_import: error: No file name specified, aborting."
	return
      }
      if { $tech_name == "" } {
	max_error "cell_import: error: No technology name specified, aborting."
	return
      }
      set tech_source tech.source
      set max_command "wm iconify .win1;\
	format_gds_layers $file_name $tech_source;
	mn_exit"

      msg "Examining gds file using max.  Please wait...\n"
      if {[catch {exec max <<$max_command >&gds_input.log}]} {
	max_error "cell_import: error: Error running max.  See file: gds_input.log. aborting."
	return
      }

      msg "Running make_tech.  Please wait...\n"
      if {[catch {exec make_tech -r -file $tech_source -tech $tech_name}]} {
	max_error "cell_import: error: Error running make_tech.  aborting."
	return
      }

      tk_dialog  .dialog "Max Create Tech File" \
	"Created technology file: $tech_name\n\
	 To use, restart max using: max -tech $tech_name" \
	{} 0 Done
    }
    "GDSII" {
      cell_load_gds $file_name
    }
    "LEF" {
      read_lef $file_name
    }
    "DEF" {
      read_def $file_name
    }
  }
}


proc cell_export {} {
  global CELL
  set file_type "GDSII"


  # find the directory
  set name [file rootname [cell_file [lay_rootcell]]]
  if {$name == ""} {
    set name [lay_rootcell]
  }
  if { $name == "$CELL(UNNAMED)" } {
    # Dont use "(UNNAMED)" as the output file name.
    set gds_file_name ""
    set def_file_name ""
  } else {
    set gds_file_name $name$CELL(gds_suffix)
    set def_file_name $name.def
  }

  set prop_list ""
  # 8/7/00: We decided LEF/DEF not ready to ship.
  #lappend prop_list [list "File Type:" file_type -radio {GDSII LEF DEF} \
      -reload -separator]
  lappend prop_list [list "File Type:" file_type -radio {GDSII} \
      -reload -separator]

  #### Options for GDS files #####
  lappend prop_list [list "GDSII File Name:" gds_file_name \
      -filename "-message {GDS II File to Write} -pattern *$CELL(gds_suffix)" \
      -width 40 \
      -when {$file_type == "GDSII"}]

  lappend prop_list [list "GDSII Export Setup Options..." {} \
      -button gds_export_setup -when {$file_type == "GDSII"} -separator]

  #### Options for LEF files #####

  # There arent any LEF export setup options yet.
  #lappend prop_list [list "LEF File Name:" lef_file_name \
      -filename "-message {LEF File to Write} -pattern *.lef" \
      -width 40 \
      -when {$file_type == "LEF"}]
  #lappend prop_list [list \
      "Note: LEF filename same as cell name with .lef suffix" {} \
      -label -when {$file_type == "LEF"}]

  #### Options for DEF files #####

  # There arent any DEF export setup options yet.
  #lappend prop_list [list "DEF File Name:" def_file_name \
      -filename "-message {DEF File to Write} -pattern *.def" \
      -width 40 \
      -when {$file_type == "DEF"} -separator]
  #lappend prop_list [list \
      "Note: you must Import a LEF file before exporting a DEF file" {} \
      -label -when {$file_type == "DEF"}]

  set ret [prop_menu2 -title "Export File" $prop_list]
  # If user hit cancel
  if { $ret == 0 } { return }

  switch -- $file_type {
    "GDSII" {
      gds_write $gds_file_name
    }
    "LEF" {
      write_lef
    }
    "DEF" {
      write_def $def_file_name
    }
  }
}


proc _cell_gds_suffix_list {} -desc {
  Return a list of possible gds suffixes for directory search purposes.
} {
  global CELL _CELL_GDS_IMPORT_SUFFIX
  set list ""
  foreach suffix $CELL(gds_suffixes) {
    lappend list *$suffix
  }
  # Extra user-supplied suffix. 
  set extra [use_first _CELL_GDS_IMPORT_SUFFIX]
  if { $extra != "" } {
    if {[lsearch $CELL(gds_suffixes) $extra] == -1} {
      lappend list *$extra
    }
  }
  return $list
}


proc cell_load_gds {{filename ""} {batch 0}} -desc {
  Prompt user for gds file, and read it in.
} -doc {
  loads toplevel cell into window.
  If GDS_READ_PARTIAL is true (1) then first scans the gds file
  for cell names and then queries the user to select a cell to
  read out of the gds file, with or without its descendents.
} {
  global CELL GDS_READ_PARTIAL _CELL_GDS_IMPORT_SUFFIX

  if {$filename == ""} {

    set filename [fs_box -message "GDSII File to Read:" \
	-pattern [_cell_gds_suffix_list]]

    # if nil, file selector box cancelled -- do nothing
    if {$filename == ""} {
      return 
    }

    set ext [file extension $filename]
    if { $ext != "" } {
      # As a user convenience, save suffix for next time
      # this function is called, to show in fs_box.
      set _CELL_GDS_IMPORT_SUFFIX $ext
    }

    cursor_busy 1
  }

  if {$GDS_READ_PARTIAL && !$batch} {

    upvar #0 _${filename}_SUBCELLS_ _SUBCELLS_
    upvar #0 _${filename}_CELLS_ _CELLS_

    if {![info exists _SUBCELLS_]} {

      puts "Analyzing file \"$filename\" for cell list ..."
      if {[catch "gds_info $filename" info]} {
	puts "Aborting: $info"
	return
      }

      # need to remove return chars from this
      regsub -all \n [lindex $info 0] "" info

      # get cells
      foreach cell [get_assoc cell_defs $info] {
	set name [get_assoc name $cell]
	set _CELLS_($name) 1
	foreach list [get_assoc subcells $cell] {
	  setl {cellname count} $list
	  lappend _SUBCELLS_($name) $cellname
	}
      }
    }

    set title "Cell List"
    set message "Cell to Load:" 

    set cell_list [lsort -dictionary [array names _CELLS_]]

    set cell [lindex $cell_list 0]

    set prop_list ""
    lappend prop_list [list "cell" cell popup $cell_list]
    set descendents 1
    lappend prop_list [list descendents descendents binary]

    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
      # cancelled
      return
    }

    if {$cell == ""} {
      return
    }
  }

  if {!$GDS_READ_PARTIAL || $batch} {
    # read the entire file
    if {[catch [list gds_read $filename] topCell]} {
      puts "Aborting, $topCell"
      return ""
    }

  } else {
    # read just the given cell and possibly descendents
    set list $cell

    if {$descendents} {
      # read descendents, too
      set trace($cell) 1
      set _LIST_ [use_first _SUBCELLS_($cell)]

      for {set i 0 ; set one [lindex $_LIST_ $i]} {$one != ""} {incr i ; set one [lindex $_LIST_ $i]} {
	
	if {[info exists trace($one)]} {
	  # already been here
	  continue
	}
	set trace($one) 1

	if {[info exists _CELLS_($one)]} {
	  # this is a cell

	  # look for all subcells
	  foreach ii [use_first _SUBCELLS_($one)] {
	    if {![info exists trace($ii)]} {
	      lappend _LIST_ $ii
	    }
	  }
	}	  
      }

      set list [array names trace]
    }

#    puts "Importing $list ..."

    if {[catch [list gds_read -cells [join $list ,] $filename] msg]} {
      puts "Aborting, $msg"
      return ""
    }

    set topCell $cell
  }

  #load toplevel cell into current window
  if { $topCell != "" } {
    cell_load $topCell
  }

  # turn off drc
  pal_special_off drc

  msg "Top cell is $topCell.\n"
  msg "Done.\n"

  return $topCell
}


proc cell_delete {} -desc {
     Delete edit cell buffer (does not effect disk version)
} {
    global CELL
    set cell [lay_editcell]

    if { [memq [_cells_modified] $cell] } {
	set choice [tk_dialog .dialog "max Delete Cell?" "Cell '$cell' has changed."  \
	  {} 0 {Delete} {Cancel} ]			
	
	if { $choice != 0 } { 
	    return
	}
    }

    sel_clear  ;# Is this necessary?
    db_cell_delete 

    # db_cell_delete does not work if the cell is in use somewhere.
    if {[cell_in_memory $cell]} {
      warning "cell $cell is being referenced somewhere, so was cleared, not entirely deleted"
    }
    cell_load_finish

    undo_flush
    edit_stack_clear


    # db_cell_delete picked a cell at random to edit.
    # First I modified it to not pick a gcell or clipboard.
    # Then it managed to find something else stupid to edit.
    # Give up.  You probably really should edit (UNNAMED) anyway.
    #if {[is_gcell [lay_rootcell]]} {}
      msg_catch {db_cell_new $CELL(UNNAMED)}
      cell_load $CELL(UNNAMED)
    #{}
}

proc cell_make_instance {cell {x ""} {y ""}} -desc {
  create instance of given cellName.
} -doc {
  If no coords given, then attach to mouse like paste.
  This is a wrapper for :getcell that prompts user if instance is "$CELL(UNNAMED)"
} {
    global CELL

    # if (UNNAMED)  prompt user for proper name and rename it!
    if { $cell == "$CELL(UNNAMED)" } {
	setl {dir cell ext} [_cell_file_box "Rename $CELL(UNNAMED):" -ext $CELL(default_suffix)]

	# if nil, file selector box cancelled -- do nothing
	if {$cell == ""} { 
	    return 
	}

	# make sure we don't overwrite an existing file
	if { [file exists $dir/$cell$CELL(default_suffix)] } {
	    error "file $dir/$cell$CELL(default_suffix) already exists!"	
	}

	# do the rename
	db_cell_rename "$CELL(UNNAMED)" $cell $dir/$cell$CELL(default_suffix)
    }

  set errmsg ""
  if {$y == ""} {
    set bbox [lay_bbox]

    # This function is called only from list_box, and the mouse
    # is currently over the list box, so dont put it at the mouse
    # location, thats off screen.  So drop it in the middle of the screen
    # and warp the mouse there.
    setl {x1 y1 x2 y2} [dbt_frame]
    layt_point -warp user [expr ($x1 + $x2) / 2] [expr ($y1 + $y2) / 2]

    # We will drop it on the nearest user grid point.
    setl {x y} [layt_point user]

    for {set i 1} {1} {incr i} {
      if { $i == 10 } {
	# Give up
	if { $errmsg == "" } { set errmsg "Can not place cell $cell" }
	max_error "cell_make_instance: error: $errmsg"
	return
      }
      # db_instance will fail if there is already a cell in this location.
      # db_instance does not return a failure code!!!
      # It just returns an empty cellname.
      if { [msg_catch [list db_instance $cell $x $y] id errmsg] ||
	  $id == "" } {
	# Try another spot
	set x [expr $x + [res -userx]]
	set y [expr $y + [res -usery]]
	continue
      }
      sel_cell2 $id
      break
    }

    # clipboard_paste ends with an i_cmd_between; dont do another.
    clipboard_paste drop $bbox

  } else {
    :getcell $cell
    i_cmd_between
  }
}

proc cell_gds2ascii {} -desc {
    Prompt user for GDS file, then translate GDS to ASCII (foo.gds -> foo.gds_ascii) 
} {
  global CELL _CELL_GDS_IMPORT_SUFFIX

  set filename [fs_box -message "GDSII File to translate:" \
      -pattern [_cell_gds_suffix_list]]

  # if nil, file selector box cancelled -- do nothing
  if {$filename == ""} {
    return 
  }

  set ext [file extension $filename]
  if { $ext != "" } {
    # As a user convenience, save suffix for next time
    # this function is called, to show in fs_box.
    set _CELL_GDS_IMPORT_SUFFIX $ext
  }
  
  #do the translation
  set result [gds_dump $filename]
  if {$result == ""} {
      error "Could not convert GDSII file '$filename' to ASCII"
  } else {
      msg "wrote $result\n"
  }
}


proc cell_save_tree {{modified 1}} -desc {
  saves the rootcell if modified and any descendents that are modified.
} -doc {
  If <modified> is 0, then save even if not modified.
} {
  set cell_list [cell_process_tree cell_save $modified]
  puts "Saved [llength $cell_list] cells."
}

proc cell_process_tree {cmd modified} -desc {
  Run cmd on edit cell and descendents.  Return list of cells processed.
} -doc {
  You alternately set cmd to "" and just process the list after it returns.
} {

  global _CELL_SAVE_TREE _CELL_SAVE

  # This var is -1 until the first time we encounter an unloaded cell.
  # Then we do a dialog to ask what to do, and set this to 0 or 1.
  set _CELL_SAVE(skip_unloaded) -1
  set _CELL_SAVE(list) ""

  # We use _CELL_SAVE_TREE to track what cells have been seen.
  catch {unset _CELL_SAVE_TREE}

  # Save where we are.
  edit_push_direct

  _cell_process_tree_internal $cmd [lay_editcell] $modified

  # return to where we were
  edit_pop_direct
  return $_CELL_SAVE(list)
}


proc _cell_process_tree_internal {cmd cell modified} -desc {
  run cmd on each cell in the tree.
} {
  global _CELL_SAVE_TREE _CELL_SAVE

  if {[info exists _CELL_SAVE_TREE($cell)]} {
    # already been here
    return
  }

  # goto the cell.  Cant fail because we checked the "available" flag, below.
  :load $cell

  set flags [lindex [cell_info $cell] 0]
  if {[lsearch $flags modified] != -1 || !$modified} {
    eval $cmd
    lappend _CELL_SAVE(list) $cell
  }

  # remember that we were here
  set _CELL_SAVE_TREE($cell) 1

  # now check on each of the subcells
  foreach subcell [db_kids $cell] {
    set flags [lindex [cell_info $subcell] 0]
    # Skip gcells.
    if {[memq $flags "generated"]} { continue }

    # See if cell has been loaded.
    if {! [memq $flags "available"]} {
      # This cell has not yet been loaded.
      # Ask the user what to do.
      if { $_CELL_SAVE(skip_unloaded) == -1 } {
	set message "Child cell $cell is not yet loaded. \
	  Do you want to load currently unloaded child cells so that\
	  the entire cell hierarchy under the edit cell can be searched?"
	set choice [tk_dialog .dialog {Load all subcells?} $message {} 1 \
		{Yes} {No}]
	set _CELL_SAVE(skip_unloaded) $choice
      }

      if {$_CELL_SAVE(skip_unloaded)} {continue}
    }

    _cell_process_tree_internal $cmd $subcell $modified
  }
}


proc _cell_load_tree_internal {parentcell cell} {
  global _CELL_SAVE_TREE

  if {[info exists _CELL_SAVE_TREE($cell)]} {
    return ;# already been here
  }

  # There could be an instance of a cell that has no .max file.
  # In that case, :load would fail, but it would still create an empty cell!
  # Since :load does not have an option to NOT create the cell,
  # call cell_path_find first.
  if {![cell_in_memory $cell]} {

    set locations [cell_path_find $cell]

    msg "loading $cell from [lindex $locations 0]\n"
    if {[llength $locations] == 0} {
      max_error -buffer "cell_load_tree error: in cell $parentcell: subcell $cell not found on disk"
      return
    }
    if {[llength $locations] > 1} {
      max_error -buffer "cell_load_tree warning: cell $cell found in multiple disk locations: $locations"
    }

    # Read in this specific file.
    cell_load_file [lindex $locations 0]
  }

  set _CELL_SAVE_TREE($cell) 1

  foreach subcell [db_kids $cell] {
    set flags [lindex [cell_info $subcell] 0]
    # Skip gcells.
    if {[memq $flags "generated"]} { continue }
    _cell_load_tree_internal $cell $subcell
  }
}

# Benchmarks from loading ng chip:
# cell_load_tree 13min; lay_internals 14min;
# cell_load_tree without the cell_path_find 8min;
# cell_load_tree using cell_path_find to feed :load 10min.
proc cell_load_tree {} -desc {
  Load all cells from disk, starting with the edit cell.
} -doc {
  Prints warning if a cell was not found on disk.
  Unlike :load, does not create an empty cell for non-existent cells.
} {
  global _CELL_SAVE_TREE

  catch {unset _CELL_SAVE_TREE}
  edit_push_direct
  _cell_load_tree_internal "" [lay_editcell]
  edit_pop_direct
}


# TODO: Give user the chance to rename (UNNAMED) first,
# then abort entire thing if user declines.
proc cell_process_all {cmd modified} -desc {
  Run cmd on all open cells.
} -doc {
  If <modified> is 0, save all cells; if 1, save only modified cells.
} {
  global CELL
  edit_push_direct

  set cell_list ""
  foreach thingy [split [string trim [db_cells]] \n] {
    setl {cell flags file} $thingy

    if {[memq $flags "internal"]} { continue }
    if {[memq $flags "generated"]} { continue }

    if {![memq $flags "modified"] && $modified != 0} {
      continue
    }

    # This is not necessary, just being ultra safe:
    if {[string match {__*} $cell]} {
      msg -warn "Ignoring cell $cell"
      continue
    }

    if {$cell == "$CELL(UNNAMED)"} {
      # Let the user rename this.
      :load $CELL(UNNAMED)
      if {[memq $flags "modified"]} {
	if {[cell_save] == 0} {
	  # User cancelled.
	  msg "Ignoring cell $CELL(UNNAMED), must rename it first\n"
	}
      }
      continue
    }
    lappend cell_list $cell
  }

  if {$cmd != ""} {
    foreach cell $cell_list {
	# goto the cell
	:load $cell

	# Process it
	eval $cmd
    }
  }

  # return to the top cell
  edit_pop_direct

  return $cell_list
}


proc cell_process_multiple {{-selection} {-cmd ""} {-title "Select Cells"}} -desc {
  Ask whether to operate on edit cell, descendents, or all cells.
} -doc {
  If -selection and some cells are selected, ask whether user if they want to process that.
  If -cmd is given, edit each cell and run that command.
  The -title is the popup window title.
} {
  set prop_list ""

  if {$selection && [sel_what cells -boolean]} {
    set result "selected"
    lappend prop_list [list "Select cells:" result \
      -radio {"Selected cells" "Current edit cell"  "Edit cell and descendents" "All loaded cells"} \
      -values {selected editcell tree all}]
  } else {

    set result "editcell"
    lappend prop_list [list "Select cells:" result \
      -radio {"Current edit cell"  "Edit cell and descendents" "All loaded cells"} \
      -values {editcell tree all}]
  }

  if {[prop_menu2 -title $title $prop_list ] == 0 } {
    return ""   ;# Cancelled.  Return empty string.
  }

  switch $result {
    "editcell" {
      if {$cmd != ""} { eval $cmd }
      set cell_list [lay_editcell]
    }
    "tree" {
      set cell_list [cell_process_tree $cmd 0]
    }
    "all" {
      set cell_list [cell_process_all $cmd 0]
    }
    "selected" {
      set cell_list ""
      foreach cell_info [sel_what_l cells] {
	struct max_cell c $cell_info
	lappend cell_list ${c.def}
      }

      # Run cmd on each selected cell.
      edit_push_direct
      if {$cmd != ""} {
	foreach cell $cell_list {
	  # goto the cell and process it.
	  :load $cell
	  eval $cmd
	}
      }
      edit_pop_direct

    }
  }
  return $cell_list
}


proc saveall {} -desc {
  saves all modify cells to disk
} {

  set count 0

  edit_push_direct

  foreach list [split [db_cells] \n] {
    setl {cell flags} $list

    if {[lsearch $flags modified] != -1 &&
	[lsearch $flags internal] == -1} {
      
      # goto the cell
      :load $cell

      # save this cell
      cell_save
      incr count
    }
  }

  # return to the top cell
  edit_pop_direct

  puts "Saved $count cells."
}



proc cell_array {} -desc {
  array the selected cell
} {

  global ARRAY_CELL_MENU_DATA

  set flag 0
  set cells [sel_what_l cells -edit_only flag]

  if {[llength $cells] != 1} {
    if { $flag } {
      max_error "cell_array: Aborting, must select a subcell of the current cell"
    } else {
      max_error "cell_array: Aborting, must select one cell to array.  Try again."
    }
    return
  }

  # Slurp all the data on this cell.
  struct max_cell c [lindex $cells 0]
  setl {xlo xhi ylo yhi xsep ysep} ${c.arrayinfo}
  struct rect bbox [db_bbox -cell ${c.def}]
  set orient [orientation ${c.transform}]

  switch $orient {
    "r90" -
    "fx_r90" -
    "fy_r90" -
    "r270" {
      # cell is rotated!
      set rotated 1
    }
    default {
      set rotated 0
    }
  }

  set prop_list ""

  # get all the layers
  set layers "_bbox_ none"
  foreach layer [split [string trim [db_types] \n] \n] {
    if {$layers != "" && [lsearch [lindex $layer 4] "builtin"] == -1} {
      lappend layers [lindex $layer 0]
    }
  }
  if {![info exists ARRAY_CELL_MENU_DATA(layer)]} {
    # initialize to happy numbers
    set ARRAY_CELL_MENU_DATA(dx)      0
    set ARRAY_CELL_MENU_DATA(dy)      0
    set ARRAY_CELL_MENU_DATA(layer)   [lindex $layers 0]
    set ARRAY_CELL_MENU_DATA(columns) 1
    set ARRAY_CELL_MENU_DATA(rows)    1
  }

  if { $xlo != "" } {
    # Init to actual numbers from current cell.
    set ARRAY_CELL_MENU_DATA(columns) [expr $xhi - $xlo + 1]
    set ARRAY_CELL_MENU_DATA(rows)    [expr $yhi - $ylo + 1]
    # Show the actual spacing.  If greater than bouding box, show
    # spacing relative to bbox, other show absolute spacing.
    if { $rotated } {
      # Max returns xsep and ysep reversed.  Fix it.
      set tmp [expr abs($ysep)]
      set ysep [expr abs($xsep)]
      set xsep $tmp
    } else {
      # Max makes these negative in certain orientations
      set xsep [expr abs($xsep)]
      set ysep [expr abs($ysep)]
    }
    set dx [expr ${bbox.x2} - ${bbox.x1}]
    set dy [expr ${bbox.y2} - ${bbox.y1}]
    if { [approx $xsep >= $dx] && [approx $ysep >= $dy] } {
      set ARRAY_CELL_MENU_DATA(layer) "_bbox_"
      set ARRAY_CELL_MENU_DATA(dx) [uusnap -mask [expr $xsep - $dx]]
      set ARRAY_CELL_MENU_DATA(dy) [uusnap -mask [expr $ysep - $dy]]
    } else {
      set ARRAY_CELL_MENU_DATA(layer) "none"
      set ARRAY_CELL_MENU_DATA(dx) [uusnap -mask $xsep]
      set ARRAY_CELL_MENU_DATA(dy) [uusnap -mask $ysep]
    }
  } else {
    # Its not an array.
    set ARRAY_CELL_MENU_DATA(columns) 1
    set ARRAY_CELL_MENU_DATA(rows)    1
    # Leave dx, dy, and layer unchanged; user could array multiple
    # cells in a row without changing that data.
  }

  lappend prop_list "columns ARRAY_CELL_MENU_DATA(columns) -number 1 -incr 1 -validate"
  lappend prop_list "rows ARRAY_CELL_MENU_DATA(rows) -number 1 -incr 1 -validate"

  lappend prop_list [list {} {} -separator]
  lappend prop_list [list {Compute Element Spacing Using:} {} -label]

  lappend prop_list \
   [list "bbox layer" ARRAY_CELL_MENU_DATA(layer) -choice $layers \
   -help {choose layer to compute relative spacing for cells or choose\
   'none' for absolute spacing.  '_bbox_' will use the maximum of all layers.}]


  lappend prop_list \
    [list "relative dx" ARRAY_CELL_MENU_DATA(dx) -number -incr [res -mask] \
    -snap 0.1 -help "horizontal spacing between array elements."]
  lappend prop_list \
    [list "relative dy" ARRAY_CELL_MENU_DATA(dy) -number -incr [res -mask] \
    -snap 0.1 -help "vertical spacing between array elements."]

  set title "Array Cell"
  set message "Options:"

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return
  }

  set layer $ARRAY_CELL_MENU_DATA(layer)
  switch -- "$layer" {
    none {
      set xr [expr $ARRAY_CELL_MENU_DATA(dx)]
      set yr [expr $ARRAY_CELL_MENU_DATA(dy)]
    }

    _bbox_ {
      set xr [expr ${bbox.x2} - ${bbox.x1} + $ARRAY_CELL_MENU_DATA(dx)]
      set yr [expr ${bbox.y2} - ${bbox.y1} + $ARRAY_CELL_MENU_DATA(dy)]
    }

    default {
      # use this layer in cell.  If layer not in cell, abort.
      # The -any_cell searches sub_cells of c.def, as well.

      set paints [db_search_l paint -cell ${c.def} -any_cell $layer]

      set polys [db_search_l polygons -cell ${c.def} -any_cell $layer]

      set wps [db_search_l wirepaths -cell ${c.def} -any_cell $layer]

      if {[llength $paints] + [llength $polys] + [llength $wps] == 0} {
	# error, this layer not in cell
	max_error "cell_array: Aborting, must select a layer that occurs in the cell."
	return
      }

      set lxmin +1e20
      set lymin +1e20
      set lxmax -1e20
      set lymax -1e20

      # get bbox of this layer
      foreach paint $paints {
	struct max_paint p $paint
	set lymax [max $lymax ${p.y2}]
	set lymin [min $lymin ${p.y1}]
	set lxmax [max $lxmax ${p.x2}]
	set lxmin [min $lxmin ${p.x1}]
      }

      foreach poly $polys {
	struct max_polygon p $paint
	struct rect r ${p.bbox}
	set lymax [max $lymax ${r.y2}]
	set lymin [min $lymin ${r.y1}]
	set lxmax [max $lxmax ${r.x2}]
	set lxmin [min $lxmin ${r.x1}]
      }

      foreach wp $wps {
	struct max_wirepath w $wp
	struct rect r ${w.bbox}
	set lymax [max $lymax ${r.y2}]
	set lymin [min $lymin ${r.y1}]
	set lxmax [max $lxmax ${r.x2}]
	set lxmin [min $lxmin ${r.x1}]
      }

      assert { $lxmin != +1e20 }

      set xr [expr $lxmax - $lxmin + $ARRAY_CELL_MENU_DATA(dx)]
      set yr [expr $lymax - $lymin + $ARRAY_CELL_MENU_DATA(dy)]
    }
  }

  if { $rotated } {
    lay_box ${bbox.x1} ${bbox.y1} [expr ${bbox.x1}+$yr] [expr ${bbox.y1}+$xr]
  } else {
    lay_box ${bbox.x1} ${bbox.y1} [expr ${bbox.x1}+$xr] [expr ${bbox.y1}+$yr]
  }
  :array $ARRAY_CELL_MENU_DATA(columns) $ARRAY_CELL_MENU_DATA(rows)

  puts "$ARRAY_CELL_MENU_DATA(columns) X $ARRAY_CELL_MENU_DATA(rows) array of cell \"${c.def}\" created."

  # The box above is not related to anything, its only used
  # to communicate to the :array command.
  # Lets leave the box somewhere nice.
  lay_box ${c.x1} ${c.y1} ${c.x2} ${c.y2}
}


proc cell_uniq_id {{prefix cell}} -desc {
  Return a unique cell id.
} {
  setl {u1 u2} [db_vstamp -new]
  return ${prefix}${u1}x${u2}
}


proc cell_id2cell {{-cell ""} cellid} -desc {
  DEPRECATED.  Use dbt_find_cell 
} -doc {
  return the cell def given the cell id.  Works with hierarchical cellid.
} {
  if {$cell=="" || $cell=="."} {set cell [lay_editcell]}

  # Old, non hierarchical:
  # struct max_cell c [lindex [db_instances_l -cell $cell -id $cellid] 0]

  foreach subcellid [split $cellid "/"] {
    if {$subcellid != "."} {
      set cell [cellinfo_def [lindex [db_instances_l -cell $cell -id $subcellid] 0]]
    }
  }
  return $cell
}

proc cell_origin {{cell_info ""}} -desc {
  return origin of selected cell in root cell coords.
} -doc {
  If cell_info (from sel_what or db_search) is given, return origin of that,
  otherwise of any selected cell.
} {
  if {$cell_info==""} {
    set cell_info [lindex [sel_what_l cells] 0]
  }
  struct max_cell cell $cell_info
  setl {a b c d e f} ${cell.transform}
  # To convert coord x,y to root-cell coords, you use:
  #   x2 = ax + by + c;  y2 = dx + ex + f.
  # Therefore, the cell origin (x=0,y=0), in root-cell coords, is at (c,f),
  # regardless of rotation.
  return [list $c $f]
}

proc cell_load_hook {name {unused1 ""} {unused2 ""}} -desc {
  This is called whenever max loads a file.
} -doc {
  name = cell def;

  Not called for generated cells.  Called before cell is loaded,
  max searches for the cell after calling this.

  WARNING: This is called from inside the max :load command.
  You MUST NOT do any processing that might cause control
  to return to max re-entrantly.  So just save the cell name
  now, and process it when the current command ends.
} {
  global VC_OPEN_FILES MaxDebug
  set ret ""
  if {[use_first MaxDebug '0]} {puts "cell_load_hook called"}
  # Throw away the return value; max is printing it out!
  catch {lappend VC_OPEN_FILES $name} junk
  # Max is not currently using the return value, but it will
  # be the location of the file to open, or "".
  if {[string index $name 0] == "#"} {
    # Gcell.  Max will deal with it.
    return ""
  } else {
    set locations [cell_path_find $name]
    set filename [lindex $locations 0]
    if {$filename != ""} {
      set msg "loading cell $name from [lindex $locations 0]"
      set ret [lindex $locations 0]
    } else {
      set msg "can't find cell $name"
    }
    # TODO: If max cant find the cell, it keeps looking over and over
    # for every instance encountered.  We would like to print the message
    # only once, but better yet, we would like to search for the cell only once.
    # The msg proc appears to be crashing max if called from here.
    # Just print the message directly.
    puts $msg
    msg_put_log "$msg\n"
  }
  return $ret
}

proc cellinfo_id {cell_info} -desc {
  Return cell id from cell info returned by db_search or sel_what.
} {
  return [lindex $cell_info 0]
}

proc cellinfo_def {cell_info} -desc {
  Return cell id from cell info returned by db_search or sel_what.
} {
  return [lindex $cell_info 1]
}

proc cellinfo_loc {cell_info} -desc {
  Return cell location {x1 y1 x2 y2} from cell info returned by db_search or sel_what.
} {
  return [lrange $cell_info 2 5]
}

proc cellinfo_x1 {cell_info} -desc {
  Return cell x1.  See also cellinfo_loc.
} {
  return [lindex $cell_info 2]
}

proc cellinfo_y1 {cell_info} -desc {
  Return cell y1.  See also cellinfo_loc.
} {
  return [lindex $cell_info 3]
}

proc cellinfo_path {{-array} cell_info} -desc {
  Return path as a list from cell info returned by db_search or sel_what.
} -doc {
  Path is always relative to root cell.
  This only matters if you are in edit-in-place.
  Path may be empty.
} {
  set path [lindex $cell_info 6]
  if {$path=="EDIT_CELL_PATH"} {
    set path [lindex [lay_path] 1]
  }
  if {$path == "."} {
    # lay_path returns "." if we are not in edit-in-place
    set path ""
  }

  return $path
}


proc cellinfo_name {{-array} cell_info} -desc {
  Return full name of cell, including path and id.
} -doc {
  If -array is set, append array designator, if any.
} {
  set path [cellinfo_path $cell_info]
  set id [lindex $cell_info 0]

  if {$array} {
    # Add in array designator, too.
    set arrayinfo [lindex $cell_info 9]
    switch [llength ${arrayinfo}] {
      0 {
	# Not an array.
      }
      8 {
	# This is a result from db_search cells.  The xindex yindex
	# are backwards and at the front of the array.  Sigh.
	struct max_dbsearcharray a ${arrayinfo}
	# It is an array.
	# If it is a one dimensional array, max only uses one 
	# array index in the cell id.
	if { ${a.ylo} == ${a.yhi} } {
	  append id "\[${a.xindex}\]"
	} elseif { ${a.xlo} == ${a.xhi} } {
	  append id "\[${a.yindex}\]"
	} else {
	  append id "\[${a.xindex},${a.yindex}\]"
	}
      }
      default {
	# Possibly someone called us with the result from sel_what cells,
	# which does not include x,y coords in the arrayinfo.
	error "cellinfo_name: invalid arrayinfo ([llength ${arrayinfo}])"
      }
    }
  }
  if {[use_list_path]} {
    return [concat $path $id]
  } else {
    return ${path}${id}
  }
}

proc _UNUSED_cell2path {cell_info {f_arrays 0}} -desc {
  return the true cell id, including array and path, from db_search or sel_what cells info
} {
  struct max_cell c $cell_info

  if {[use_list_path]} {

    # add "/" to beginning of path (to indicate its relative to rootcell)
    # also fix C-code EDIT_CELL_PATH kludge
    if { ${c.path} == "EDIT_CELL_PATH" } {
      set editpath [lindex [lay_path] 1]
      if { $editpath == "." } {
	set c.path {/}
      } else {
	  set c.path [concat {/} $editpath]
      }
    } else {
      set c.path [concat {/} ${c.path}]
    }

    # No array subscript case.
    if { $f_arrays == 0 } {
      return [concat ${c.path} ${c.id}]
    }

    # Add in array subscripts
    switch [llength ${c.arrayinfo}] {
      0 {
	return [concat ${c.path} ${c.id}]
      }
      8 {
	# This is a result from db_search cells.  The xindex yindex
	# are backwards and at the front of the array.  Sigh.
	struct max_dbsearcharray a ${c.arrayinfo}
      }
      default {
	# Possibly someone called us with the result from sel_what cells,
	# which does not include x,y coords in the arrayinfo.
	error "cell2path invalid arrayinfo ([llength ${c.arrayinfo}])"
      }
    }

    # If it is a one dimensional array, max only uses one 
    # array index in the cell id.
    if { ${a.ylo} == ${a.yhi} } {
      return [concat ${c.path} "${c.id}\[${a.xindex}\]"]
    }
    if { ${a.xlo} == ${a.xhi} } {
      return [concat ${c.path} "${c.id}\[${a.yindex}\]"]
    } 

    return [concat ${c.path} "${c.id}\[${a.xindex},${a.yindex}\]"]
  } else {

    # What bullshit.
    # Turn it into a real path, starting with "/".
    if { ${c.path} == "EDIT_CELL_PATH" } {
      set editpath [lindex [lay_path] 1]
      if { $editpath == "." } {
	set c.path /
      } else {
	set c.path /$editpath
      }
    } else {
      set c.path /${c.path}
    }

    if { $f_arrays == 0 } {
      return ${c.path}${c.id}
    }


    # Add in array designator, too.

    switch [llength ${c.arrayinfo}] {
      0 {
	return ${c.path}${c.id}
      }
      8 {
	# This is a result from db_search cells.  The xindex yindex
	# are backwards and at the front of the array.  Sigh.
	struct max_dbsearcharray a ${c.arrayinfo}
      }
      default {
	# Possibly someone called us with the result from sel_what cells,
	# which does not include x,y coords in the arrayinfo.
	error "cell2path invalid arrayinfo ([llength ${c.arrayinfo}])"
      }
    }

    # It is an array.
    # If it is a one dimensional array, max only uses one 
    # array index in the cell id.
    if { ${a.ylo} == ${a.yhi} } {
      set realid "${c.path}${c.id}\[${a.xindex}\]"
    } elseif { ${a.xlo} == ${a.xhi} } {
      set realid "${c.path}${c.id}\[${a.yindex}\]"
    } else {
      set realid "${c.path}${c.id}\[${a.xindex},${a.yindex}\]"
    }
    return $realid
  }
}

proc cellinfo_flags {cell_info} -desc {
  Return cell flags.  Currently "expanded" or "".
} {
  return [lindex $cell_info 7]
}

proc cellinfo_transform {cell_info} -desc {
  Return transform from cell info returned by db_search or sel_what.
} {
  return [lindex $cell_info 8]
}

proc cellinfo_ori {cell_info} -desc {
  Return max "orientation" string based on cell transform.  See also cellinfo_transform
} {
  return [orientation [lindex $cell_info 8]]
}

proc cellinfo_array {cell_info} -desc {
  Return array info from cell info returned by db_search or sel_what.
} {
  return [lindex $cell_info 9]
}

proc cell_load_hierarchy {{cell ""}} {
  if {$cell == ""} {
    set cell [lay_editcell]
  }

  set is_gcell [string match {#*} $cell]

  if {$is_gcell && ![string match {#GROUP*} $cell]} {
      return
  }

  # Load specified cell.  It tries to go there, so push and pop to prevent changing current cell.
  edit_push_direct
  cell_load_cell -opt $cell
  edit_pop_direct

  foreach subcell [db_kids $cell] {
    cell_load_hierarchy $subcell
  }
}
