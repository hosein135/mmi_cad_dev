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

set RCSVERSION(project.tcl) { $Revision: 1.5 $ }



proc _project_set {var args} -desc {
  Used as substitute "set" command when reading project file with output requested.
} {

  if {[llength $args] == 0} {
    return [uplevel [list _project_original_set $var]]
  }

  global _PROJECT_SETS
  _project_original_set _PROJECT_SETS($var) [lindex $args 0]

  return [uplevel [list _project_original_set $var [lindex $args 0]]]
}


proc _project_source_1file {dir {output ""}} -desc {
  Source $project.rc file in specified dir, if any.
} {
  global PROJECT env
  if {[info exists PROJECT]} {
    set fn $PROJECT.rc
  } else {
    set fn default.rc
  }

  set fn [file join $dir $fn]

  if {[file exists $fn]} {
    # Note for max: msg is not defined yet!
    puts "Sourcing $fn"
    if {$output != ""} {
      rename set _project_original_set
      rename _project_set set
    }
    if {[catch {uplevel \#0 "source $fn"} msg]} {

	# send detailed info to initial window
	global errorInfo
	puts "error reading $fn:\n$errorInfo\n"
    }

    if {$output != ""} {
      rename set _project_set
      rename _project_original_set set
    }
    return 1
  }
  return 0
}


# source project.rc file.
proc project_source_file {tool_name {output ""}} -desc {
  source project rc file(s), if any.
} -doc {
  <tool_name> is the name of the tool calling us (max, sue, mmi_wish, etc)
  This is passed to the project file as the TOOL variable.

  If <output> is specified, then after all project.rc files have been read,
  the variables set by all "set" statements in the project.rc files
  are written to stdout in a format specified by the argument to <output>,
  which may be "tcl" or "perl".  The output is preceded by
  "### PROJECT VARIABLES BEGIN ###" and followed by
  "### PROJECT VARIABLES END ###" to make the output
  easy to find among other possible output from the project.rc file.

  The name of the project file is taken from the following,
  with ".rc" appended:

  1.  The tcl PROJECT variable, if set.
      Note that this can be set in max or
      sue with the -project command line option.
  2.  The MMI_PROJECT environment variable, if set.
  3.  "default"  (uses just the file: default.rc)

  The project file is searched for on the standard MMI tools path,
  which is repeated here:

  1.  MMI_TOOLS/project directory (uses MMI_TOOLS environment variable)
  2.  MMI_LOCAL/project directory (uses MMI_LOCAL environment variable,
        if set, else $MMI_TOOLS/../mmi_local)
  3.  ~/mmi_private/project directory
  4.  ~  (users home directory)
  5.  .  (current directory)

  EACH project file found is sourced!

  Notes: The order of assignments is not preserved.
  The project.rc file is sourced multiple times by max.
} {
    global PROJECT TOOL env

    # the MN_PATH_SYS_LIB variable is not defined yet.
    if {![info exists env(MMI_TOOLS)]} {
      puts "error: MMI_TOOLS environment variable is not set!"
      return
    }
    set mmi_tools $env(MMI_TOOLS)

    if {[info exists env(MMI_LOCAL)]} {
      set mmi_local $env(MMI_LOCAL)
    } else {
      set mmi_local [file join $mmi_tools .. mmi_local]
    }

    # If PROJECT not set, try setting from MMI_PROJECT in the environment.
    if {![info exists PROJECT]} {
	if {[info exists env(MMI_PROJECT)]} {
	    set PROJECT $env(MMI_PROJECT)
	}
    }

    set TOOL $tool_name
    set fnd_project 0

    foreach dir [list $mmi_tools $mmi_local ~/mmi_private] {
      if {[_project_source_1file $dir/project $output]} {
	set fnd_project 1
      }
    }

    # Source project.rc file specific to a particular tcl incarnation.
    #global MAX_TCL_DIR
    #if {[info exists MAX_TCL_DIR]} {
      #_project_source_1file $MAX_TCL_DIR $output
    #}

    # source from users home and current directories
    if {[_project_source_1file ~ $output]} {
	set fnd_project 1
    }
    if {[_project_source_1file . $output]} {
	set fnd_project 1
    }

    if {[info exists PROJECT] && ! $fnd_project} {
      puts "WARNING: project $PROJECT not found"
    }


  # Now output the "set" statements, if requested.
  if {$output != ""} {

    puts "\n### PROJECT VARIABLES BEGIN ###"

    global _PROJECT_SETS
    foreach var [lsort [array names _PROJECT_SETS]] {
      set value [set _PROJECT_SETS($var)]

      set is_array [regexp {^(.*)\((.*)\)$} $var junk array_name array_index]
      switch -- $output {
	"tcl" {
	  if {$is_array} {
	    puts "set ${array_name}($array_index) [list $value]"
	  } else {
	    puts "set $var [list $value]"
	  }
	}
	"perl" {
	  # Change each backslash into two backslashes.
	  regsub -all "\\\\" $value "\\\\\\\\" new_value
	  # Quote all single-quotes
	  regsub -all "'" $new_value "\\'" new_value
	  if {$is_array} {
	    puts "\$$array_name\[$array_index\] = '$new_value'"
	  } else {
	    puts "\$$var = '$new_value'"
	  }
	}
	default {
	  error "unrecognized <output> argument: $output"
	}
      }
    }
    puts "### PROJECT VARIABLES END ###"
  }

  catch {unset _PROJECT_SETS}
  catch {unset TOOL}
}
