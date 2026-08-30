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

set RCSVERSION(max0.tcl) { $Revision: 1.32 $ }

# max0.tcl is a max system file, sourced after the tcl_intepreter
# is initialized, but before tk stuff.
# The MN_TECH and MN_TECH_VAR var must be set in this file, because
# max eats the technology files after this file is read but before max.tcl.
#
# (See also max.tcl, which is sourced after all C code initialization)

###
### DON'T AUTOMATICALLY PASS COMMANDS TO SHELL!
###
set auto_noexec 1

###
### TEMPORARY HACK!!!!!!
### If the user wants to enable the Mark menu, we have to do it
### before calling win_new.  So grep for the command in the max.rc file.
### Yuck.
### 9/5/01: This code no longer needed: can now use max -set MAX_MARK_MENU=1
###
# grep is defined in a tcl file elsewhere, but we need it now,
# before that tcl file is sourced.
proc _grep {pat file} -desc {
  search file for regexp pattern, return 1 or 0
} {
    if {[catch {set fd [open $file "r"]}]} { return 0 }
    set result 0
    while {! [eof $fd]} {
	if {[regexp $pat [gets $fd]]} {
	    set result 1
	    break
	}
    }
    close $fd
    return $result
}


global MAX_MARK_MENU
set MAX_MARK_MENU 0

set _mark_menu_pat {[ 	]*set[ 	]+MAX_MARK_MENU[ 	]+1}
if {[_grep $_mark_menu_pat ".maxrc"] || \
    [_grep $_mark_menu_pat "max.rc"]} {
	set MAX_MARK_MENU 1
}

# This controls the new features in the Prototype and Test version.
# If we are a MAX_DEVELOPER, we can turn them on/off with environment
# variable or if the max -maxtcl
# option is set to the pattcl directory.
global MAXPAT
set MAXPAT 0
if { $MAX_DEVELOPER && [info exists env(MAXPAT)]} {
    set MAXPAT $env(MAXPAT)
}


###
### Control optional new max features
###

proc MAXPAT {} { global MAXPAT; return $MAXPAT }

# MAX_NEW_SELECT tried to keep the selection in a group until
# the next command was executed, to try to keep the selection
# from merging when you drop it.
global MAX_NEW_SELECT
set MAX_NEW_SELECT 0

# Set this to 1 when db_search is fixed to return coords
# in parent cell coordinates.
global MAX_DB_SEARCH_FIXED
set MAX_DB_SEARCH_FIXED 0

set MAX_EDIT_PAINT 0

# Set MN_BIN_DIR.  Mha may eventually add this as a global variable.
global MN_BIN_DIR
switch "$tcl_platform(os)" {
  "SunOS" { set MN_BIN_DIR "bin.sparc-solaris2" }
  "HP-UX" { set MN_BIN_DIR "bin.hppa-hpux10" }
  "Linux" { set MN_BIN_DIR "bin.i486-linux" }
  default { puts "Warning: unrecognized computer platform: $tcl_platform(os)" }
}


# Do this now, so -set command line options can be used in the project.rc file.
proc _max0_parse_set {} -desc {
  Execute -set options from command line, before reading max.rc files.
  They will be executed again later.
} {
  global argv
  call_keyword -nocase -append $argv {{set ""}}
  foreach c $set {
    setl {variable value} [split $c =]
    puts "set $variable $value\n"
    global $variable
    set $variable $value
  }
}
_max0_parse_set


proc _max0_source_project {} {
      global argv doc_source PROJECT

      call_keyword -nocase $argv {{norc} {project ""}}
      if {$norc} {
	# -norc option suppresses reading the project.rc files.
	# Message will be printed when we look for max.rc files.
	return
      }

      if {$project != ""} {
	set PROJECT $project  ;# This sets the project file name for project_source_file
      }

      # You cant set doc_source here!  If max is running from its integral tcl code,
      # it doesnt source the doc0.tcl code until after max0.tcl
      #set save_source $doc_source
      #set doc_source projectrc

      # KLUDGE!!!!  If we are reading tcl code from disk, we want to get the
      # latest version of any sharedtcl found in the directory:
      # [file dirname $MN_SCRIPT_FILE]/sharedtcl.   This is done in max.tcl,
      # but we need to run the project file NOW, so source any updated
      # sharedtcl code NOW.
      global MN_SCRIPT_FILE
      if {[info exists MN_SCRIPT_FILE]} {
	set tcl_dir [file dirname $MN_SCRIPT_FILE]

	# Source any sharedtcl.
	if {[file isdirectory $tcl_dir/sharedtcl]} {
	  foreach name [lsort -ascii [glob -nocomplain $tcl_dir/sharedtcl/*.tcl]]  {
	    uplevel \#0 source $name
	  }
	}
      }

      # Read the project file.
      if {[catch {project_source_file MAX} msg]} {
	puts "error sourcing project file: $msg"
      }
      #set doc_source $save_source 
}

_max0_source_project



proc _max0_parse_tech {} -desc {
  parses max command line options - first pass
} -doc {
  Processes just those args that need
  to be processed in max0.tcl  Rest are done in max.tcl.
} {
  global argv env MN_TECH MN_TECH_VAR

  # Look at command line options.
  call_keyword -nocase $argv {{tech ""} {technology ""}}

  if {$tech == ""} {set tech $technology}
  # The MAX_TECHNOLOGY variable can be set in the project .rc file.
  global MAX_TECHNOLOGY
  if {$tech == "" && [info exists MAX_TECHNOLOGY]} {
    set tech $MAX_TECHNOLOGY
  }

  set envtech ""
  if {[info exists env(MAX_DEFAULT_TECH)]} {
    set envtech $env(MAX_DEFAULT_TECH)
  }

  if {$tech == ""} {
    # Get the technology from the last cell.
    # In versions of max newer than 8/15/01,
    # Max stores the technology of the last file in MN_FILE_TECH.
    # It uses the last cell, because we dont know exactly what
    # the options are in the C part of max, so we cant skip
    # the options with assurance.
    global MN_FILE_TECH
    if {[info exists MN_FILE_TECH] && $MN_FILE_TECH != ""} {
      set tech $MN_FILE_TECH

      # If file tech matches MAX_DEFAULT_TECH and MAX_DEFAULT_TECH includes
      # a variation part, use it!
      set envtechbase ""
      set envtechvar ""
      regexp {^(.*)-(.*)$} $envtech junk envtechbase envtechvar
      if {$tech != "" && $tech == $envtechbase && $envtechvar != ""} {
	set tech ${tech}-${envtechvar}
      }
    }
  }

  # If still no tech, try environment variable.
  if {$tech == ""} {
    set tech $envtech
  }

  # Last ditch, use mmi25.
  if {$tech == ""} {
    set tech mmi25
  }

  if {[regexp {^(.*)-(.*)$} $tech junk techbase techvar]} {
    set MN_TECH $techbase
    set MN_TECH_VAR $techvar
  } else {
    set MN_TECH $tech
    set MN_TECH_VAR ""
  }

}

_max0_parse_tech


###
### INITIALIZE INTEGRAL DOCUMENTATION
### (redefines "proc" and "rename")
###
### NOTS:  only source files, if we are working from disk.
### NOTE:  Do this last in this file!  This emulates the behavior when
###        max has integral tcl code, in which case these files are
###        are read after max0.tcl returns.
###
###
if {[info exists MN_SCRIPT_FILE]} {

  # If and only if we are sourcing this file (max0.tcl) from disk,
  # then MN_SCRIPT_FILE is the full pathname of the file.
  set MAX_TCL_DIR [file dirname $MN_SCRIPT_FILE]

  # If this is the Prototype And Test version of max, set MAXPAT.
  global MAXPAT
  if {[string match {*pattcl*} $MAX_TCL_DIR]} {
    set MAXPAT 1
  }

  if {![file exists $MAX_TCL_DIR] || ![file isdirectory $MAX_TCL_DIR]} {
    # How did this happen?  C code is sposed to prevent this.
    puts "ERROR: directory $MAX_TCL_DIR does not exist or not readable"
    exit 2
  }

  # order of sourcing is important!
  puts "Sourcing Max tcl code from: $MAX_TCL_DIR"
  uplevel \#0 source ${MAX_TCL_DIR}/doc_user0.tcl
  uplevel \#0 source ${MAX_TCL_DIR}/doc_var_user0.tcl
  uplevel \#0 source ${MAX_TCL_DIR}/doc0.tcl
  uplevel \#0 source ${MAX_TCL_DIR}/help0.tcl
}

