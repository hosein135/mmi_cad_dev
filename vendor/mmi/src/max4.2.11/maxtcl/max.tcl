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

set RCSVERSION(max.tcl) { $Revision: 1.36 $ }

# max.tcl is a max system file, sourced after C-code 
# initialization of tcl/tk and C modules.
#
# (See also max0.tcl which is sourced immediately after 
#  the tcl interpreter is initialized, prior to tk initialization)
#
# procs defined below are part of max
# Note: tk_bisque, below, will auto-load that file from the lib,
# which will get the tk_bisque command, and others, into the documentation
# as maxtcl commands.  To prevent that, autoload it now.

set doc_source "tk"
if {[info commands tk_bisque] == ""} {
  auto_load tk_bisque
}

set doc_source maxtcl

###
### Define default Max fonts now.  User can over-ride in .maxrc.
###
init_global SMALL_FONT \
	-type STRING \
	-default {-*-helvetica-bold-r-normal--*-100-*} \
	-desc { Default font used for small text }
init_global LISTBOX_FONT \
	-type STRING \
	-default {*-courier-Bold-R-Normal-*-120-*} \
	-desc { Default font used in list-boxes; should be a fixed width font. }
init_global MENU_FONT \
	-type STRING \
	-default {*-helvetica-Bold-R-Normal-*-120-*} \
	-desc { Default font used in menus }
init_global DIALOG_FONT \
	-type STRING \
	-default {*-helvetica-Bold-R-Normal-*-140-*} \
	-desc { Default font used for prop menus }

init_global BATCH \
	-type INT -default 0 \
	-desc {if set to 1, max will not do popup menus.  Also set by max -batch}


init_global PROMPT \
	-type STRING \
	-desc {Max command line prompt}

set PROMPT "[winfo name .]> "
# Remove the embedded space from the PROMPT to make it look nice.
regsub " #" $PROMPT "#" PROMPT



###
### Define structures used by max TCL-C interface.
### Structures are accessed by the functions: struct and destruct.
### Other TCL modules can define additional structures by adding
### them to the MAX_STRUCT array.
###
# The structure returned by sel_what labels:
set MAX_STRUCT(max_label) "layer x1 y1 x2 y2 pos text path group kind"

# The structure returned by sel_what cells:
set MAX_STRUCT(max_cell) "id def x1 y1 x2 y2 path expansion transform arrayinfo"

# Structure of arrayinfo returned by db_search cells.
# Note that xindex and yindex are reversed: this is what is actually
# returned as of 3-22-00, even though documentation says its the other way.
set MAX_STRUCT(max_dbsearcharray) "yindex xindex xlo xhi ylo yhi xsep ysep"

# Structure of arrayinfo returned by sel_what cells.  (Grrr!)
set MAX_STRUCT(max_cellarray) "xlo xhi ylo yhi xsep ysep"

# The structure returned by sel_what paint:
set MAX_STRUCT(max_paint) "layer x1 y1 x2 y2"

# The structure returned by sel_what polygons:
set MAX_STRUCT(max_polygon) "layer bbox coords attrs"

# The structure returned by sel_what wirepaths:
set MAX_STRUCT(max_wirepath) "layer bbox width coords attrs"

# Generic rectangle.
set MAX_STRUCT(rect) "x1 y1 x2 y2"

# Generic point.
set MAX_STRUCT(point) "x y"



###
### SETUP AUTOMATIC DOCUMENTATION (HAS TO COME RIGHT AFTER TK INITIALIZATION) 
###

# period of periodic updates in milli seconds
set max_periodic(period) 400
# Count of elapsed ticks.
set max_periodic(count) 0
set max_periodic(enabled) 1

###
### SOURCE MAX TCL CODE FIRST, SO THAT DISK-BASED AND INTERNAL-STARTUP
### SCRIPT MODES ARE AS SIMILAR AS POSSIBLE
###

# source max tcl code
proc max_tcl_source {file} -desc {
source tcl file from max library
} {
    set path [mn_sys_find "maxtcl/$file"]
    if {$path == ""} {
	error "Could not find maxtcl/$file\n" 
    }
    uplevel \#0 source $path
}


proc _max_source_maxtcl {} -desc {
    source maxtcl files
} -doc {
  This procecure is only called if are sourcing max tcl files from disk.
} {
  global MN_SCRIPT_FILE
  set tcl_dir [file dirname $MN_SCRIPT_FILE]
  foreach name [lsort -ascii [glob $tcl_dir/*.tcl]]  {
      # extract base name
      set name [file tail [file rootname $name]]

      # filter out names ending in 0 (sourced with max0.tcl)
      if { [regexp ".*0$" $name] == 1 } continue

      # filter out max.tcl (this file!)
      if { $name == "max" } continue

      #max_tcl_source $name.tcl
      uplevel \#0 source $tcl_dir/$name.tcl
  }

  # Source any sharedtcl.
  if {[file isdirectory $tcl_dir/sharedtcl]} {
    foreach name [lsort -ascii [glob $tcl_dir/sharedtcl/*.tcl]]  {
      uplevel \#0 source $name
    }
  }
}
# if we are working from disk, source remaining maxtcl/*.tcl files
if { [info exists MN_SCRIPT_FILE] } { _max_source_maxtcl }

# Load documentation from installation lib directory.
# The files might already have been loaded, if they were invoked.
# But auto_load will load it even if it is already loaded,
# so dont do it in that case.
foreach cmd [list tk_dialog prop_menu l_remove_name fs_box call_keyword] {
  if {[info commands $cmd] == ""} {
    catch {auto_load $cmd}
  }
}

# setup message processing - must be done after reading tcl files
msg_init

### ANNOUNCE INSTALLATION TREE
msg "Current Directory: [pwd]\n"
msg "MMI Tools Directory: $MMI_TOOLS\n"

###
### MAX SOURCE CODE NOW LOADED, CONTINUE INITIALIZATION
###

# Default font size for menus, etc.
option add *Font $MENU_FONT

# not using initial main window
wm withdraw .

# set the background colors to be like in tk3.6
tk_bisque

# don't allow button motion in listboxes
bind Listbox <B1-Motion> ""
bind Listbox <B2-Motion> ""
bind Listbox <B3-Motion> ""

# set prompts for controlling terminal
proc _max_prompt_main {} {global PROMPT; puts -nonewline $PROMPT}
proc _max_prompt_partial {} {puts -nonewline "max? "}
set tcl_prompt1 _max_prompt_main
set tcl_prompt2 _max_prompt_partial

# intercept tk "exit" commands.
rename exit tkExit
proc exit {args} -desc {
    exit max
} -doc {
  USAGE:
    exit [-force [code]]

  If -force is specified, max exits immediately.
  If integer <code> is also specified, it is the exit code.

  Otherwise, if any cells have been modified, pops up a dialog
  box that gives the user the option to save modified buffers on
  normal exit.
} {
    set code 0
    set force 0
    if {[string match {-f*} [lindex $args 0]]} {
      set force 1
      set args [lrange $args 1 end]
    }
    set argc [llength $args]
    if {$argc != 0} { set code [lindex $args 0] }

    if { $force } {
	mn_exit -nobackup
    } else {
	cell_exit
    }
}

proc _max_source {fn} -desc {
    source file at top level, catching errors
} {
    msg "Sourcing $fn\n"

    if {[catch {uplevel \#0 "source $fn"} msg]} {

	# send detailed info to initial window
	global errorInfo
	msg "$errorInfo\n\n"

	# warning dialog window      
	# Note: msg -warn does not work at this point for some reason.
	# Update: because msg_init has not been called yet, maybe?
	warning "Error reading $fn:\n  $msg\n"
    }
}

proc max_tech_path {extension {warn ""}} -desc {
    locate tcl tech file in syslib path
} {

  global MN_PATH_SYS_LIB MN_TECH MN_TECH_VAR

  set path_name ""
  set name1 ""
  set name2 ""

  # first try for variation specific file 
  if {$MN_TECH_VAR != ""} {
    set name1 tech/${MN_TECH}/${MN_TECH}-${MN_TECH_VAR}.$extension
    set path_name [mn_sys_find $name1]
  }

  # if no variation specific file, try generic
  if {$path_name == "" } {
    set name2 tech/${MN_TECH}/${MN_TECH}.$extension
    set path_name [mn_sys_find $name2]
  }

  # if still not found, warn and return.
  if {$path_name == ""} {
    if { $warn == "" } {
	if {$name1 == "" || $name2 == "" } {
	  msg "$name1$name2 not found in System Library Path:\n\t$MN_PATH_SYS_LIB\n"

	} else {
	  msg "Neither $name1 nor $name2 found in System Library Path:\n\t$MN_PATH_SYS_LIB\n"
	}
    }
    return ""
  }

  return $path_name
}

proc max_private_dir {} -desc {
  locate the max local dir.
} -doc {
  Return name of existing dir, or if dir does not exist,
  return a default dir name.  This is needed because we 
  now allow the user to use ~/mmi_private/max$MAX_VERSION
  as the name of the local dir, but if it does not exist,
  just use ~/mmi_private/max.
} {
  global MAX_VERSION MMI_PRIVATE

  set maxroot [file nativename $MMI_PRIVATE]

  set major_version [lindex [split $MAX_VERSION .] 0]

  # search first for max3 and then max (doesn't look for max2 or max1)
  if {[file isdir $maxroot/max$major_version]} {
    return $maxroot/max$major_version
  } else {
    return $maxroot/max
  }
}


proc max_local_pref_file_name {} -desc {
  Return name of users local preferences file.
} -doc {
 This is the file for user config preference options.
 This proc does not create the file or dir.
} {
  global MN_TECH MN_TECH_VAR
  set techroot [max_private_dir]/tech/$MN_TECH

  # make the filename
  if {$MN_TECH_VAR == ""} {
    set filename $techroot/$MN_TECH.pref
  } else {
    # technology variation
    set filename $techroot/${MN_TECH}-$MN_TECH_VAR.pref
  }
  return $filename
}


proc max_local_tech_dir {} -desc {
  locate and possibly build local tech dir
} {
  global MN_TECH

  set techroot [max_private_dir]/tech/$MN_TECH

  # make the directory if needed
  if {![file isdir $techroot]} {
    set makedir ""
    foreach string [split $techroot /] {
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

  return $techroot
}


# source tcl tech file (if any)
# (contains technology dependent tcl code.)
proc _max_source_tech {} -desc {
    source tcl tech file from syslib path
} {

  set path_name [max_tech_path tcl]

  if { $path_name == "" } {
    # An error mssage was already printed.
    return
  }

  # source it!    
  _max_source $path_name
}
_max_source_tech 

# initialize tcl coded modules
mode_init

# This is the initial directory that will appear in the list boxes.
cell_path_add "."

# Do this now, so developer variables set this way can control how windows get packed.
proc _max_parse_set {} -desc {
  Execute -set options from command line, before reading max.rc files.
  They will be executed again later.
} {
  global argv
  call_keyword -append $argv {{set ""}}
  foreach c $set {
    setl {variable value} [split $c =]
    msg "set $variable $value\n"
    global $variable
    set $variable $value
  }
}
_max_parse_set

# open initial main window
win_new
cursor_busy 1 ;# And initial cursor in main window is busy cursor.

# cell_init comes after win_new, so that cell_path_add commands
# for directories added by cell_init will appear in the list boxes.
# If additional cell_path_add commands happen later, ie, in max.rc files,
# then those will show up in the list-boxes, instead.
cell_init

# process initial expose, to avoid double redisplay after loading
# command line file, and then issueing "update idletasks"
update 
# set initial grid size
grid_init
cursor_update

# Load up the keymap.
keymap_init

# Source auto-generated preference file
# Source before .maxrc file, so user
# can over-ride variable settings in .maxrc file.
proc _max_source_pref {} -desc {
    source tcl preferences file from max syslib path
} {

  # File name is <technology>.pref
  set path_name [max_tech_path pref nowarning]

  if { $path_name == "" } {
    # An error mssage was already printed.
    return
  }

  # source it!    
  _max_source $path_name
  grid_update
}
_max_source_pref


# Load gcells on current cell_path now.
# Must be after loading technology.
# Should be before max.rc file, so user can load cells there.
# Dont know about relative order vs the preference file.
max_gcell_init


proc _max_source_1maxrc {dir} -desc {
  Source max.rc or .maxrc file from specified dir, if any.
} {
  set maxrc_cnt 0
  foreach maxrc [list .maxrc max.rc] {
    if {[file exists $dir/$maxrc]} {
      incr maxrc_cnt
      _max_source $dir/$maxrc
    }
  }
  if { $maxrc_cnt == 2 } {
    # Note: msg -warn does not work at this point for some reason.
    warning "Files max.rc and .maxrc both found in directory: $dir"
  }
}


# source .maxrc's
proc max_source_maxrc {} -desc {
    source .maxrc (if any)
} -doc {
    max.rc and .maxrc files are sourced (if present):
    1. from each directory in MN_PATH_SYS_LIB (in reverse order);
    1b.  from max -maxtcl directory, if any;
    2. from users home directory;
    3. from current directory.

    EACH max.rc or .maxrc found is sourced!
    If both files exist in some directory, issue a warning.
} {
    global MN_PATH_SYS_LIB doc_source
    set save_source $doc_source

    set doc_source maxrc

    foreach dir [lreverse $MN_PATH_SYS_LIB] {
      _max_source_1maxrc $dir
    }

    # Source max.rc file specific to a particular tcl incarnation.
    global MAX_TCL_DIR
    if {[info exists MAX_TCL_DIR]} {
      _max_source_1maxrc $MAX_TCL_DIR
    }

    #source .maxrc's in users home and current directories
    _max_source_1maxrc ~
    _max_source_1maxrc .
    set doc_source $save_source 
}
max_source_maxrc

proc max_parse_args {} -desc {
  parses max command line - pass 2.
} -doc {
  Pass 1 in max0.tcl already processed the -tech option,
  but we parse and discard it here.
} {
  global argv

  # load command line files and execute options (all at top level)
  # This call should be identical to the one in max_parse_args0 in max0.tcl
  set cells [call_keyword -append -dash 0 $argv \
	       {{set ""} {command ""} {iconify ""} {batch ""} {tech ""} {technology ""}}]

  if {[string match -* [lindex $cells 0]]} {
    if {[lindex $cells 0] == "--"} {
      set cells [lrange $cells 1 end]
    } else {
      msg "Warning: unrecognized command line option: [lindex $cells 0]  (use -- to end options to load a cell starting with \"-\")\n"
    }
  }

  if {$iconify != "" && $iconify != 0} {
    # iconify the main max window
    global max_win
    wm iconify $max_win
  }

  if {$batch != "" && $batch != 0} {
    # batch mode, no dialog boxes
    global BATCH
    set BATCH 1
  }

  # execute any set statements in MAX command line
  foreach c $set {
    setl {variable value} [split $c =]
    msg "set $variable $value\n"
    global $variable
    set $variable $value
  }


  # note this may already be called from cell_load if
  # done in .maxrc
  # 9/21/01: pat moved to above max.rc files.  Otherwise, cells loaded
  # from a max.rc file cause errors.
  #max_gcell_init

  cell_load_files $cells

  # execute any command line MAX commands
  foreach c $command {
    msg "Executing \"$c\"\n"
    if {[msg_catch {uplevel #0 $c} error info warn]} {
      max_error "Error executing -command switch: $error $info $warn"
    }
  }

}
max_parse_args


#start periodic updates
proc _max_periodic_update {} -desc {
  collection of updates done every max_periodic(period) milliseconds
} {
  global max_periodic

  # zero period means no updates.  FOR DEBUGGING ONLY!
  # Not updating the db_vstamp can lead to instability
  # in max database, particular for gcells.
  if {$max_periodic(period) == 0} {
    return
  }

  db_vstamp -update

  if {[focus] == "" || $max_periodic(enabled) == 0} {
    # do nothing, focus isn't in window, or we are disabled.
    after [expr 3 * $max_periodic(period)] _max_periodic_update 
    return
  }

  # updates
  pal_update

  incr max_periodic(count)

  if { $max_periodic(count) % 3 == 0 } {
    drc_status_update
  }

  # schedule next update
  after $max_periodic(period) _max_periodic_update 
}
_max_periodic_update

# procs defined after now could be auto-loaded tcl/tk files,
# or user defined procs.
set doc_source local

# TODO:   BUG:  when window destroyed "enter" event not always sent to 
#         window below.
# (at least during grab/tkwait).  Thus we can "teleport" into layout window,
# without enter event, hence not setting the focus, hence keyboard bindings
# won't work.  Hopefully this will be fixed when we switch to a newer tcl/tk.
# In the mean time we KLUDGE it by making the layout window the default
# focus window.  This will sometimes cause the layout window to become 
# the focus when we are not in it - but this shouldn't do too much harm :-)
#
# NO focus default in tk4.1
# focus default $max_win.layout

# prepare for first interactive command
i_cmd_between

# we are ready for input, clear busy cursor
cursor_busy 0


