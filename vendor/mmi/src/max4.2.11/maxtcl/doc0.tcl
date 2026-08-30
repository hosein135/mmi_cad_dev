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

set RCSVERSION(doc0.tcl) { $Revision: 1.13 $ }

# Procedures implementing "integral" documentation for procedures and variables
# INITIAL PART OF DOC MODULE - srced from max0.tcl after tcl interpeter fired
# up and init.tcl in tcl library sourced (but before tk stuff).
#
# Since this module implements code used at load time for ALL other modules,
# it is sourced first and should be independent of other modules.
#
# NOTE: redefines "proc" and "rename"

# This module redefines "proc" and "rename"
# for "auto" documentation.
# To make it clear which "proc" is which - we rename the original version
# right off the bat.  All invocations of "proc" in max should be the new one!
if { [info commands _doc_proc_orig] == ""} {
    rename proc _doc_proc_orig
    rename rename _doc_rename_orig
}

# This is the routine that is called at runtime by all procs that have
# optional arguments of the form: proc {{-option ...}...}
# min_args is the number of required arguments to the proc,
#   and is used to print an error if too few arguments are specified in the call.
# proc_name is the name of the proc that was called.
# proc_args are the runtime arguments to this call.
#
# The PROC_OPTIONS array has all other needed info.
# PROC_OPTIONS(proc_name,-option) is set if
#   this proc has an option -option.  The value of the array element
#   is the number of required arguments that appear after the option,
#   for example, 0 for a binary option, 1 for an option that takes
#   a single option, etc.
# PROC_OPTIONS(proc_name|args) is is a list of the rest of the proc arguments,
#   in order, including both non-optional and optional args.
#   The optional args are handled at compile time by adding "set" commands
#   in the proc body to initialize them.
_doc_proc_orig doc0_proc_arg_parser {min_args proc_name proc_args} {
  global PROC_OPTIONS

  set len [llength $proc_args]
  set i 0

  # Parse out the option args.
  while {$i < $len} {
    set arg [lindex $proc_args $i]
    if {[string index $arg 0] != "-"} {break}

    if {$arg == "--"} {
      incr i
      break
    }

    if {[info exists PROC_OPTIONS($proc_name,$arg)]} {
      set nn $PROC_OPTIONS($proc_name,$arg)
      set argname [string range $arg 1 end]
      upvar $argname tmp
      if {$nn == 0} {
	# Binary option.  Set value to 1.
    	set tmp 1
      } elseif {$nn == 1} {
    	set tmp [lindex $proc_args [expr $i + 1]]
      } else {
    	set tmp [lrange $proc_args [expr $i + 1] [expr $i + $nn]]
      }
      incr i [expr $nn + 1]
    } else {
      break
    }
  }

  set j 0
  set other_args $PROC_OPTIONS(${proc_name}|args)
  while {$i < $len} {
    set argname [lindex $other_args $j]
    if {$argname == ""} {
      error "too many args to proc $proc_name"
    }
    incr j
    upvar $argname tmp
    set tmp [lindex $proc_args $i]
    incr i
  }
  if {$j < $min_args} {
    error "too few args to proc $proc_name"
  }
}

# define our new definitions of proc and rename
# then delete proc_unrestricted so user can't set it in tk.tcl init file 
# to steal our code
if { [info commands proc_unrestricted] != ""} {
    proc_unrestricted proc {args} {
	global doc_user doc_source PROC_OPTIONS

	# TODO: The {user} is for backward compatibility.
	# Get rid of it soonest!
	set pos_args [_doc_call_with_keyword $args \
		{{desc ""} {doc ""} {internal ""} {user} {type ""}} \
		doc_proc]

	set proc_name [lindex $args 0]
	set proc_args [lindex $pos_args 1]
	set proc_body [lindex $pos_args 2]
	if {[llength $pos_args] != 3} {
	  error "wrong number of args to proc $proc_name"
	}

	if {$type == "user"} {
	  # Put this command in user-level documentation.
	  set doc_user($proc_name) 1
	}

	# set cmd attributes for this proc
	doc_add_cmd $proc_name $desc $doc $internal
	doc_at $proc_name cmd_args $proc_args

	# See if the first proc argument is an option like {-foo} or {-foo default}
	# If so, scan all proc args; initialize optional arguments
	# in the body of the proc, and also arrange for the argument list
	# to be processed by doc0_proc_arg_parser each time the proc is invoked.
	# Note: [lindex $arg 0] returns "-foo" if arg is "-foo" or {-foo default}.
	if {[string match {-*} [lindex [lindex $proc_args 0] 0]]} {
	  # The first arg is an option.  So scan entire command line.
	  set min_args 0
	  set new_cmds ""
	  set option_args ""
	  set other_args ""
	  foreach arg_info $proc_args {
	    # The lindex returns "-foo" if arg is "-foo" or {-foo default}.
	    set arg_name [lindex $arg_info 0]
	    if {[string index $arg_name 0] == "-"} {
	      # This is an option.
	      if {$min_args != 0} {
		# Options must appear before other arguments in the proc definition.
		error "parse error: invalid args to proc $proc_name"
	      }
	      set opt_name [string range $arg_name 1 end]
	      set PROC_OPTIONS($proc_name,$arg_name) [expr [llength $arg_info] - 1]
	      switch [llength $arg_info] {
	      1 {
		# Binary option, eg: {-foo}.  Init to 0.
		set arg_default 0
		}
	      2 {
		# Option with default, eg: {-foo default}.
		set arg_default [lindex $arg_info 1]
		}
	      default {
		# Option with 2 or more defaults, eg: {-area 0 0 0 0}
		# This will generate code, eg:
		#  set foo default
		#  set area {0 0 0 0}
		set arg_default [lrange $arg_info 1 [expr [llength $arg_info] - 1]]
		}
	      }
	      append new_cmds "set $opt_name [list $arg_default] ;"
	      lappend option_args [list $opt_name $arg_default]
	    } elseif {[llength $arg_info] == 2} {
	      # This argument has a default value.
	      append new_cmds "set $arg_name [list [lindex $arg_info 1]] ;"
	      lappend other_args $arg_name
	    } else {
	      # This is a normal argument.
	      lappend other_args $arg_name
	      incr min_args
	      if {$arg_name == "args"} {
		set min_args 0
	      }
	    }
	  }
	  append new_cmds "set __proc_options [list $option_args] ;"
	  set PROC_OPTIONS(${proc_name}|args) $other_args
	  append new_cmds "doc0_proc_arg_parser $min_args $proc_name \$args ;"
	  set proc_args "args"
	  set proc_body "$new_cmds $proc_body"
	}

	# do actual proc definiton
	# We must preserve the original namespace if "namespace" is going to work.
	# [namespace current] returns the namespace of the current proc,
	# but we want the namespace from which this proc command was invoked,
	# which is the next one up on the stack.
	# If the proc_name has an explicit namespace, ie, it starts with ::, use it.
	set namespace [uplevel {namespace current}]
	if {[string range $proc_name 0 1] != "::" && $namespace != "::"} {
	  eval _doc_proc_orig [list ${namespace}::$proc_name $proc_args $proc_body]
	} else {
	  eval _doc_proc_orig [list $proc_name $proc_args $proc_body]
	}
    }

    # rename a command, and update documentation accordingly 
    # A new name of {} deletes command.
    proc_unrestricted rename {old new} {
	if {$new != ""} {
	    global doc_developer
	    #copy attributes
	    doc_at $new cmd_desc [doc_at $old cmd_desc]
	    doc_at $new cmd_doc [doc_at $old cmd_doc]
	    doc_at $new cmd_source [doc_at $old cmd_source]
	    doc_at $new cmd_internal [doc_at $old cmd_internal]
	    doc_at $new cmd_args [doc_at $old cmd_args]
	    set doc_developer($new) 0

	    #orig name
	    set orig_name [doc_at $old cmd_orig_name]
	    if {$orig_name == ""} {
		doc_at $new cmd_orig_name $old
	    } else {
		doc_at $new cmd_orig_name $orig_name
	    }
	}

	#delete attributes from old name
	doc_at_delete $old cmd_desc
	doc_at_delete $old cmd_doc
	doc_at_delete $old cmd_source
	doc_at_delete $old cmd_orig_name
	doc_at_delete $old cmd_args
	catch {unset doc_developer($old)}

	#do actual tcl rename
	_doc_rename_orig $old $new 
    }

    # delete unrestricted proc!
    _doc_rename_orig proc_unrestricted ""
}

#attributes are stored as $name$_doc_sep$attribute
#NOTE: must be single char (since split is used below.
#NOTE: If this char is used in global variable or command names, it will
#      break this code.
set doc_sep "|"

# current source of new procs
set doc_source maxtcl

###
### setup user visible commands
###

#Set user text commands in (Help/"Text Commands") to names."
_doc_proc_orig _doc_set_user {names {type ""}} {
    global doc_user$type

    # clear array 
    if {[info exists doc_user$type]} {
	unset doc_user$type
    }

    foreach name $names {
      set doc_user${type}($name) 1
    }
}
_doc_set_user $DOC(initial_user_commands)
_doc_set_user $DOC(initial_user_variables) _var


###
### documentation attribute routines 
###

# get/set attribute of name
#     doc_at name attribute [value]

_doc_proc_orig doc_at {name attribute args} {
    global _doc_at_db doc_sep
    set argc [llength $args]

    if {$argc == 0} {
	# no value given, return current value 
	set value ""
	if { $attribute == "cmd_usage" } {
	    set cmd_desc [doc_at $name cmd_desc]
	    set cmd_doc [doc_at $name cmd_doc]
	    if {[info procs $name] != "" && \
		![regexp -nocase "USAGE" "$cmd_desc $cmd_doc"]} {
		# The info args returns a list of procedure arguments.
		# To denote optional arguments, we will query which have
		# default values, and add brackets around those.
		# This is not quite right, because if a proc has two optional args,
		# It should be: foo [a [b]] instead of foo [a] [b], but oh well...
		set usage "$name"
		set cmd_args [doc_at $name cmd_args]
		if {$cmd_args == ""} {
		  # Ask tcl what the cmd args are.
		  set cmd_args ""
		  foreach arg [info args $name] {
		    if {[info default $name $arg unused]} {
		      lappend cmd_args $arg
		    } else {
		      lappend cmd_args {$arg whatever}
		    }
		  }
		}
		foreach arg_info $cmd_args {
		  set arg_name [lindex $arg_info 0]
		  if {[string match {-*} $arg_name]} {
		    if {[llength $arg_info] == 1} {
		      append usage " \[$arg_name\]"
		    } else {
		      append usage " \[$arg_name"
		      foreach arg1 [lrange $arg_info 1 end] {
			append usage " value"
		      }
		      append usage "\]"
		    }
		  } else {
		    if {[llength $arg_info] == 1} {
		      append usage " $arg_name"
		    } else {
		      append usage " \[$arg_name\]"
		    }
		  }
		}
		return $usage
	    }
	    return ""
	}
	catch {set value $_doc_at_db($name$doc_sep$attribute)}
	return $value
    } elseif {$argc == 1} {
	# value given, do set
	set _doc_at_db($name$doc_sep$attribute) [lindex $args 0]
    } else {
	# too many args
	error "doc_at called with too many args"
    }
}

# return list of {name attribute value} triples where name and attriubte match
# the (glob style) arg patterns.
_doc_proc_orig doc_at_search {name_pat at_pat} {
    global _doc_at_db doc_sep

    set result ""
    set sid [array startsearch _doc_at_db]
    while {[array anymore _doc_at_db $sid]} {
	set e [array nextelement _doc_at_db $sid]
	set el [split $e $doc_sep]
	set e_name [lindex $el 0]
	set e_at [lindex $el 1]
	if {[string match $name_pat $e_name] && [string match $at_pat $e_at]} {
	        lappend result [list $e_name $e_at $_doc_at_db($e)]
	}
    }
    return $result
}

# setup documentation for given command
_doc_proc_orig doc_add_cmd {name desc doc {internal ""}} {
    global MAX_DEVELOPER doc_user doc_source doc_developer

    # This is a KLUDGE.  Commands documented between this file
    # and max.tcl include max internal commands, followed by tk commands.
    # The first tk command is tkInit, ignore everything after it.

    if { $name == "tkInit" } { set doc_source "tk" }

    # 10/2000: Dont bother to include tk internal commands in max documentation.
    # Commands defined after max.tcl has run are labeled "local",
    # because they could be defined in the max command window, but
    # they are more likely auto-loaded tcl/tk procs, so ignore them too.
    if { $doc_source == "tk" } { return }
    if { $doc_source == "local" } { return }

    # if not in developer mode, only document user commands
    if { $MAX_DEVELOPER == 0 && 
	 (![info exists doc_user($name)] || $doc_user($name) == 0) } return;
    
    set doc_developer($name) 0
    doc_at $name cmd_desc [_doc_trim_white_space $desc]
    doc_at $name cmd_doc [_doc_trim_white_space $doc]
    doc_at $name cmd_internal [_doc_trim_white_space $internal]
    doc_at $name cmd_source $doc_source
}

###
### our new proc (preceded by helper routines)
###

# process args allowing keyword args 
# foo -b 23 hi -c {bar qux} there
# sets b=23, c={bar qux} and returns hi there.
# NOTE: sets local args in caller
# NOTE: using "local version" here, since don't want this module to be independent
#       of others so it's version of proc can be up and running before other
#       files sourced.  Also, there are slight differences from call_with_keyword.
_doc_proc_orig _doc_call_with_keyword {_ARG_LIST _DEFAULT_LIST _CALLER} {
  
  set _RETURN ""

  foreach _DEFAULT $_DEFAULT_LIST {
    set _ARG_NAME [lindex $_DEFAULT 0] 
    upvar $_ARG_NAME $_ARG_NAME
    if {[llength $_DEFAULT] == 1} {
      set binary($_DEFAULT) 1
      set $_ARG_NAME 0
    } else {
      set binary([lindex $_DEFAULT 0]) 0
      set $_ARG_NAME [lindex $_DEFAULT 1]
    }
  }

  for {set _INDEX 0} {$_INDEX < [llength $_ARG_LIST]} {} {
    set _THIS_ARG [lindex $_ARG_LIST $_INDEX]
    if {[string index $_THIS_ARG 0] == "-"} {
      # is a keyword pair
      set _ARG_NAME [string range $_THIS_ARG 1 end]
      if {[info exists $_ARG_NAME] == 0} {
	error "\"$_ARG_NAME\" is not a valid argument to \"$_CALLER\""
      }
      if {$binary($_ARG_NAME)} {
	set $_ARG_NAME 1
	incr _INDEX 1
      } else {
	set _ARG_VALUE [lindex $_ARG_LIST [expr $_INDEX+1]]
	set $_ARG_NAME $_ARG_VALUE
	incr _INDEX 2
      }

    } else {
      # not a keyword pair
      lappend _RETURN [lindex $_ARG_LIST $_INDEX]

      incr _INDEX
    }
  }
  return $_RETURN
}

# trim leading and trailing white-space
_doc_proc_orig _doc_trim_white_space {s} {
    set tab "\t"
    set nl "\n" 
    set ws "\[ \\$tab\\$nl\]*"
    regsub "^$ws" $s "" s 
    regsub "$ws\$" $s "" s 
    return $s
}

proc doc_at_delete {name at} -desc {
    delete given documentation attribute from name
} {
    global _doc_at_db
    catch {unset _doc_at_db($name$doc_sep$at)}
}

#document the doc module code above, so our on-line docomentation is complete.
proc _doc_doc_doc {} -desc {
    document doc procs defined prior to doc version of proc
} {
    doc_add_cmd doc_at \
	    "get/set documentation attribute of name" \
	    "USAGE: doc_at name attribute ?value?]"

    doc_add_cmd doc_at_search \
	    "search documentation attribute database" \
	    {returns list of {name attribute value} triples where name and attribute match (glob style) patterns.}

    doc_add_cmd _doc_call_with_keywords \
	    {process args interpeting "-keyword value" pairs} \
	    {
	foo -b 23 hi -c {bar qux} there 
	sets b=23, c={bar qux} and returns hi there.
	NOTE: sets local args in caller
	NOTE: using "local version" here, since don't want this module to be 
	independent of others so it's version of proc can be up and running 
	before other files sourced. 
    }

    doc_add_cmd doc_trim_white_space \
	    "trim leading and trailing white space" \
            ""
}

proc _doc_doc_tcl {} -desc {
    document tcl procs and commands (all commands defined prior to doc0) 
} {
    global doc_source MAX_DEVELOPER

    # skip if in user mode (info commands) disabled for one thing!
    if {$MAX_DEVELOPER == 0} return

    set save $doc_source
    set doc_source "tcl"
    
    # first all commands
    foreach cmd [info commands] {
	if { [doc_at $cmd cmd_source] != "max" } {
	    doc_add_cmd $cmd "tcl" ""
	}
    }

    set doc_source $save
}

# document commands that are already defined
_doc_doc_doc
#10/2000: We do not need to document tcl/tk builtin commands!
#_doc_doc_tcl



##
## Global variable documentation
##

proc doc_add_var {name desc doc type flags} -desc {
  save away information about this global variable.
} {
  global doc_source

  doc_at $name var_desc [_doc_trim_white_space $desc]
  doc_at $name var_doc [_doc_trim_white_space $doc]
  doc_at $name var_source $doc_source
  doc_at $name var_type $type
  doc_at $name var_flags $flags
}



proc init_global {var args} -desc {
  initialize tcl global variables
} {

  # get the fields
  _doc_call_with_keyword $args \
      {{desc ""} {doc ""} {default ""} {flags ""} {init 1} {type BOOLEAN}} \
      doc_proc

  # store away in doc array
  doc_add_var $var $desc $doc $type $flags

  # initialize this variable (special case for arrays)
  # If -init 0, do not init variable, just document it.
  if { $init } {
    global [lindex [split $var \(] 0]
    if {![info exists $var]} {
      set $var $default
    }
  }
}


# any procs defined between now and max.tcl are max commands,
# followed by tk commands.
set doc_source "max"
