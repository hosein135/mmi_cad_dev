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

set RCSVERSION(proc_redef.tcl) { $Revision: 1.11 $ }

# This file creates the enhanced proc command.
# The proc command is redefined to support -option arguments
# and to ignore optional proc documentation.
# This file must be sourced before any enhanced proc definitions are encountered.

# Syntax of enhanced proc command:
#
#   procedure ::=
#     proc proc_name {proc_arguments} [-option value] ... {proc_body}
#
#   proc_arguments ::=
#     {-option [default ...]} ... req_arg ... {opt_arg [default]} ...
#
# Notes:
# o The option arguments begin with a dash (-) and must appear
#   inside curly braces {} in the proc arguments.
# o In the proc invocation, the -option arguments may appear in any order,
#   but they must all appear before any req_arg (required argument)
#   or opt_arg (optional argument).
# o If the proc has -option arguments, a -- may appear in proc invocation
#   to indicate that the next argument is a regular argument.
# o Any unrecognized -option argument in the proc invocation is treated
#   as a regular argument, and causes all remaining arguments to also
#   be treated as regular arguments.

# There three types of option arguments:
#
#  {-foo}
#     foo is a binary variable, with an implicit default value of 0.
#     If -foo appears in the proc invocation, the value of foo will be 1.
#  {-foo default}
#    An option with an argument.  If a value for -foo is not specified in the
#    proc invocation, the value of variable foo in the proc will be "default".
#  {-foo x y}
#    An option with two or more arguments.  This number of arguments will
#    be consumed from the proc invocation args, and placed in the variable
#    foo as a list.  If -foo is not specified in the proc invocation,
#    it will default to {x y}.
#
# Example:
#   proc myproc {{-a} {-b def} {-point 0 0} c d {e cdef}} -desc {
#     this is a one line description of what myproc does
#   } -doc {
#     this is an optional multi-line discussion of myproc.
#   } {
#     setl {x y} $point
#     puts "a=$a b=$b c=$c d=$d e=$e x=$x y=$y"
#   }
#
#  > myproc this that
#  a=0 b=def c=this d=that e=cdef x=0 y=0
#  > myproc -b new -a -point 1 2 this that those
#  a=1 b=new c=this d=that e=those x=1 y=2
#  > myproc -a -- -b c
#  a=1 b=def c=-b d=c e=cdef x=0 y=0
#  > myproc -unrecognized -a b c
#  a=0 b=def c=-unrecognized d=-a e=b x=0 y=0


# NOTE: This file is not needed inside sue or max, which have their own
# versions of this.  If sue or max is running, dont redefine proc.
# If it is not sue or max, it is tclsh, wish, mmi_tclsh or mmi_wish,
# in which case this file is needed to define the enhanced proc command.
if {! ([info exists SUE_VERSION] || [info exists MAX_VERSION])} {



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
proc __proc_arg_parser {min_args proc_name proc_args} {
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
      if {$i > $len} {
	# oops.  not enough args for a -option.
	error "proc $proc_name: insufficient args to $arg"
      }
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
    if {$argname == "args"} {
      set tmp [lrange $proc_args $i end]
      break
    } else {
      set tmp [lindex $proc_args $i]
    }
    incr i
  }
  if {$j < $min_args} {
    error "too few args to proc $proc_name"
  }
}

rename proc _oldproc

# Redefine the proc command.
# Must use "proc" in tclsh or wish,
# or "proc_unrestricted" in mmi_tclsh or mmi_wish.
# The new proc command scans the procedure elements when the proc
# is encountered (ie, compiled)
#
if {[info commands proc_unrestricted] == "proc_unrestricted"} {
    set _oldproc proc_unrestricted
} else {
    set _oldproc _oldproc
}

$_oldproc proc {proc_name proc_args args} {
  global PROC_OPTIONS PROC_DOCUMENTATION

  # We must preserve the original namespace if "namespace" is going to work.
  # [namespace current] returns the namespace of the current proc,
  # but we want the namespace from which this proc command was invoked,
  # which is the next one up on the stack.
  # But if the proc_name has an explicit namespace, ie, it starts with ::, use it.
  if {[string range $proc_name 0 1] != "::"} {
    set namespace [uplevel {namespace current}]
    if {$namespace != "::"} {
      set proc_name ${namespace}::$proc_name
    }
  }

  set argc [llength $args]
  set proc_body [lindex $args [expr $argc-1]]
  # Save the proc -desc, -doc, -internal, etc. arguments in PROC_DOCUMENTATION.
  for {set i 0} {$i < $argc - 1} {incr i 2} {
    set proc_option_name [string range [lindex $args $i] 1 end]
    set proc_option_val [string trim [lindex $args [expr $i + 1]]]
    set PROC_DOCUMENTATION($proc_name,$proc_option_name) $proc_option_val
  }
  # Also save the original args to the proc:
  set PROC_DOCUMENTATION($proc_name,args) $proc_args


  # See if the first proc argument is an option like {-foo} or {-foo default}
  # If so, scan all proc args; initialize optional arguments
  # in the body of the proc, and also arrange for the argument list
  # to be processed by __proc_arg_parser each time the proc is invoked.
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
	lappend option_args $arg_info
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
    set PROC_OPTIONS(${proc_name}|args) $other_args
    append new_cmds "__proc_arg_parser $min_args $proc_name \$args ;"
    set proc_args "args"
    set proc_body "$new_cmds $proc_body"
  }


  # Define the procedure with the modified arguments and body.
  _oldproc $proc_name $proc_args $proc_body
}

proc _proc_doc_usage {proc_name} -desc {
  Return the canonical USAGE documentation for the specified proc.
} {
  global PROC_DOCUMENTATION

  # Figure out the usage, and add it to documentation.
  set proc_args $PROC_DOCUMENTATION($proc_name,args)

  set usage $proc_name
  foreach arg_info $proc_args {
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

}
