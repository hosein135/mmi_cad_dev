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


# Procedures implementing "integral" documentation for procedures and variables

# Since this module implements code used at load time for ALL other modules,
# it is sourced first and should be independent of other modules.
#
# NOTE: redefines "proc" and "rename"

# This module redefines "proc" and "rename"
# for "auto" documentation.
# To make it clear which "proc" is which - we rename the original version
# right off the bat.  All invocations of "proc" should be the new one!
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

	global _doc_user PROC_OPTIONS

	set pos_args [_doc_call_with_keyword $args \
			  {{desc ""} {doc ""} {internal ""} {type ""} {user}} \
		doc_proc]

	set proc_name [lindex $args 0]
	set proc_args [lindex $pos_args 1]
	set proc_body [lindex $pos_args 2]
	if {[llength $pos_args] != 3} {
	  error "wrong number of args to proc $proc_name"
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

	if {$type == "user" || $user == 1} {
	  # remember this to add to text/variable commands
	  set _doc_user($proc_name) 1
	}
    }

    # rename a command, and update documentation accordingly 
    # A new name of {} deletes command.
    proc_unrestricted rename {old new} {
      global _doc_user

      # NOTE: new procs like SCHEMATIC_ and ICON_ are special cased
      # in rename code

        if {[doc_at $old cmd_source] != ""} {

	  if {$new != ""} {
	    #copy attributes
	    doc_at $new cmd_desc [doc_at $old cmd_desc]
	    doc_at $new cmd_doc [doc_at $old cmd_doc]
	    doc_at $new cmd_source [doc_at $old cmd_source]

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

	  catch {unset _doc_user($old)}
	}

	#do actual rename
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


# setup documentation for given command
_doc_proc_orig doc_add_cmd {name desc doc {internal ""}} {
    
    doc_at $name cmd_desc [_doc_trim_white_space $desc]
    doc_at $name cmd_doc [_doc_trim_white_space $doc]
    doc_at $name cmd_internal [_doc_trim_white_space $internal]
}

###
### to insure that call_with_keyword is defined here, define out own.
###

# process args allowing keyword args 
# foo -b 23 hi -c {bar qux} there
# sets b=23, c={bar qux} and returns hi there.
# NOTE: sets local args in caller
# NOTE: using "local version" here, since don't want this module to be independent
#       of others so it's version of proc can be up and running before other
#       files sourced.
_doc_proc_orig _doc_call_with_keyword {_ARG_LIST _DEFAULT_LIST _CALLER} {
  
  set _RETURN ""

  upvar default_value default_value
  upvar defaulted defaulted
  foreach _DEFAULT $_DEFAULT_LIST {
    set _ARG_NAME [lindex $_DEFAULT 0] 
    upvar $_ARG_NAME $_ARG_NAME
    set $_ARG_NAME [lindex $_DEFAULT 1]
    set default_value($_ARG_NAME) [set $_ARG_NAME]
    set defaulted($_ARG_NAME) 1
  }

  for {set _INDEX 0} {$_INDEX < [llength $_ARG_LIST]} {} {
    if {[string index [lindex $_ARG_LIST $_INDEX] 0] == "-"} {
      # is a keyword pair
      set _ARG_NAME [string range [lindex $_ARG_LIST $_INDEX] 1 end]
      set _ARG_VALUE [lindex $_ARG_LIST [expr $_INDEX+1]]
    
      if {[info exists $_ARG_NAME] == 0} {
	error "\"$_ARG_NAME\" is not a valid argument to \"$_CALLER\""
      }
      set $_ARG_NAME $_ARG_VALUE
      set defaulted($_ARG_NAME) 0
      incr _INDEX 2

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


##
## Global variable documentation
##

proc doc_add_var {name desc doc type default flags} -desc {
  save away information about this global variable.
} {

  doc_at $name var_desc [_doc_trim_white_space $desc]
  doc_at $name var_doc [_doc_trim_white_space $doc]
  doc_at $name var_default [_doc_trim_white_space $default]
  doc_at $name var_type $type
  doc_at $name var_flags $flags
}



proc init_global {var args} -desc {
  initialize tcl global variables
} {

  global _doc_user_var

  # get the fields
  _doc_call_with_keyword $args \
      {desc doc {default _NO_DEFAULT_} flags {init 1} {type BOOLEAN}} \
      doc_proc

  # store away in doc array
  doc_add_var $var $desc $doc $type $default $flags

  if {[lsearch $flags "user"] != -1} {
    # remember this to add to text/variable commands
    set _doc_user_var($var) 1
  }

  # initialize this variable (special case for arrays)
  # If -init 0, do not init variable, just document it.
  if { $init  && $default != "_NO_DEFAULT_"} {
    global [lindex [split $var \(] 0]
    set $var $default
  }
}

