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

set RCSVERSION(call_by_keyword.tcl) { $Revision: 1.12 $ }



# Note all local variables used in call_keyword will interfere with the
# calling procedures.


proc call_keyword {args} -desc {
  Parse function options using -option syntax.
} -doc {
  USAGE:
    call_keyword [-nocase] [-append] [-error] [-dash <val>] [-consume] arg_list default_list

  Parses options beginning with a dash from an argument list in <arg_list>;
  sets variable with same name as option in callers context;
  returns a list of unrecognized arguments.
  The <default_list> is the list of options to recognize.
  Each entry in <default_list> is an option name (without the dash),
  optionally followed by a default value.  If no default value is specified,
  it is a binary option that does not consume an argument from <arg_list>.

  If <arg_list> contains -- it ends option parsing (depending on -dash);
  all remaining args are returned.

  Note that options and their values must be space-separated, ie:
  
    foo -a 23     not     foo -a23

  If -append specified, multiple copies of an option are appended to
  the return value.

  If -nocase, ignore case of options.

  If -error specified, an unrecognized option causes an error;
    otherwise unrecognized options are returned.

  If -consume specified the entire <arg_list> must be consumed, or error,
    and -- is not recognized in <arg_list>.
  
  The -dash argument controls parsing of "--":
    if -dash -1, ignore "--";
    if -dash 0, "--" ends option parsing, but is returned;
    if -dash 1 (the default), "--" ends option parsing and is removed from list.

  This function supercedes:
     call_use_keyword         ==> same as: call_keyword
     call_with_keyword        ==> same as: call_keyword -error
     call_by_keyword          ==> same as: call_keyword -consume
     call_with_keyword_append ==> same as: call_keyword -error -append
  The old functions may have bugs (eg: confused by negative numbers)
  that this function fixes.

  Example: (b is a binary option, defaults to 0)

  proc foo {args} {
     set options [list {a 34} {b} {c {hi there}} {d example}]
     set result [call_keyword $args $options]

     puts result=$result
     puts "a=$a b=$b c=$c d=$d"
  }

  call_keyword $input $options

  With input:
     foo -a 23 hi -b -c {bar qux} -a 17 there -x -- -a

  Will print:
    result=hi there -x -a
    a=17 b=1 c=bar qux d=example
  
  If -append specified, the result is as below.
  Note carefully the value of a: the coption values are appended
  to the default value!  When using -append, the default value
  for each option should normally be ""

  result=hi there -x -a
  a=34 23 17 b=1 c=hi there {bar qux} d=example
  
} {

  # NOTE: All variables start with __ to avoid collisions with callers variable names.
  # Alternatively, we could have used 'upvar $arg_name __$arg_name' and then
  # reference the callers variables as __$arg_name everywhere, in which case there
  # would be no conflicts with local variables.  However, it is about twice as fast
  # to references a variable as $arg_name instead of __$arg_name, so we do it the ugly way.

  # Parse -options
  set __append 0; set __consume 0; set __error 0; set __nocase 0; set __dash 1
  for {set __i 0} {$__i < [llength $args]-2} {incr __i} {
    switch -- [lindex $args $__i] {
      -append  {set __append 1}
      -error   {set __error 1}
      -consume {set __consume 1}
      -nocase  {set __nocase 1}
      -dash    {set __dash [lindex $args [incr __i]]}
      default  {error "error: call_keyword: unrecognized option: [lindex $args 0]"}
    }
  }
  set __arg_list [lindex $args $__i]
  set __default_list [lindex $args end]

  set __unrecognized ""  ;# Accumulates unrecognized args.

  # What are these?  Are they still needed?  Max doesnt use them.
  # Default_value is *really* stupid, since the caller told *us* what it is.
  upvar default_value default_value
  upvar defaulted defaulted
  foreach __DEFAULT $__default_list {
    set __arg_name [lindex $__DEFAULT 0] 
    upvar $__arg_name $__arg_name
    if {[llength $__DEFAULT] == 1} {
      set __binary($__arg_name) 1
      set default_value($__arg_name) 0
      set $__arg_name 0
    } else {
      set default_value($__arg_name) [lindex $__DEFAULT 1]
      set $__arg_name [lindex $__DEFAULT 1]
    }
    set defaulted($__arg_name) 1
    if {$__nocase} {set __translate([string toupper $__arg_name]) $__arg_name}
  }

  for {set __index 0} {$__index < [llength $__arg_list]} {} {
    set __this_arg [lindex $__arg_list $__index]
    # Dont be fooled by a negative number
    if {[string index $__this_arg 0] == "-" && ![string match {-[0-9]*} $__this_arg]} {
      set __arg_name [string range $__this_arg 1 end]
      if {$__nocase} {
	set __tmp [string toupper $__arg_name]
	if {[info exists __translate($__tmp)]} {
	  set __arg_name $__translate($__tmp)
	}
      }
    
      if {[info exists __binary($__arg_name)]} {
	# __arg_name is a binary switch
	set $__arg_name 1
	incr __index

      } elseif {[info exists $__arg_name]} {
	# __arg_name is an option with an argument
	if {$__index+1 >= [llength $__arg_list]} {
	  error "Missing argument to \"$__this_arg\" in arguments: $__arg_list"
	}
	if {$__append} {
	  lappend $__arg_name [lindex $__arg_list [expr $__index+1]]
	} else {
	  set $__arg_name [lindex $__arg_list [expr $__index+1]]
	}
	set defaulted($__arg_name) 0
	incr __index 2
      } elseif {$__arg_name == "-" && !$__consume && $__dash >= 0} {
	# Allow -- to end the options.
	set __unrecognized [concat $__unrecognized [lrange $__arg_list [expr $__index+$__dash] end]]
	break
      } else {
	# __arg_name is an option that we do not recognize.
	if {$__error || $__consume} {
	  error "\"$__this_arg\" is not a valid argument to call_keyword in $__arg_list"
	}
	lappend __unrecognized $__this_arg
	incr __index
      }

    } else {
      # __this_arg did not begin with -
      if {$__consume} {
	error "\"$__this_arg\" is not a valid argument to call_keyword in $__arg_list"
      }
      lappend __unrecognized $__this_arg

      incr __index
    }
  }
  return $__unrecognized
}

proc call_by_keyword {_ARG_LIST _DEFAULT_LIST} -desc {
  Deprecated: see call_keyword.  Parse function options using -option syntax.
} -doc {
  Like call_keyword, but does not support binary options,
  and will generate an error if an argument is not in the list of options.
  Returns nothing.

  The call_by_keyword procedure is meant to facilitate call by keyword in tcl 
  instead of call by order.  A procedure "foo" with variables a, b, c can
  be called, for example, by

       foo -b 23 -c {bar qux}

  if it is defined as follows

  proc foo {args} {
     call_by_keyword $args {{b 34} {c {hi there}}}
     ...
  }

  call_by_keyword will define, in the context of foo, the variables b,c,
  the array default_value which stores the default values of b,c, and
  the array defaulted which stores whether the default value was used (1)
  or not (0).
} {
  
  upvar default_value default_value
  upvar defaulted defaulted
  foreach _DEFAULT $_DEFAULT_LIST {
    set _ARG_NAME [lindex $_DEFAULT 0] 
    upvar $_ARG_NAME $_ARG_NAME
    set $_ARG_NAME [lindex $_DEFAULT 1]
    set default_value($_ARG_NAME) [set $_ARG_NAME]
    set defaulted($_ARG_NAME) 1
  }

  for {set _INDEX 0} {$_INDEX < [llength $_ARG_LIST]} {incr _INDEX 2} {
    set _ARG_NAME [string range [lindex $_ARG_LIST $_INDEX] 1 end]
    set _ARG_VALUE [lindex $_ARG_LIST [expr $_INDEX+1]]
    
    if {[info exists $_ARG_NAME] == 0} {
      error "\"$_ARG_NAME\" is not a valid argument to call_by_keyword in $_ARG_LIST."
      continue
    }
    set $_ARG_NAME $_ARG_VALUE
    set defaulted($_ARG_NAME) 0
  }
}



proc call_with_keyword {_ARG_LIST _DEFAULT_LIST} -desc {
  Deprecated: see call_keyword.  Parse function options using -option syntax.
} -doc {
  Like call_by_keyword, but returns a list of its arguments not keyworded.
  Generates error if -option argument not specified in options.
  Example:
      foo -b 23 hi -c {bar qux} there
  sets b=23, c={bar qux} and returns hi there.
} {
  
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
	error "\"$_ARG_NAME\" is not a valid argument to call_with_keyword."
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



proc call_with_keyword_append {_ARG_LIST _DEFAULT_LIST} -desc {
  Deprecated: see call_keyword.  Parse function options using -option syntax.
} -doc {
  Like call_with_keyword except
  [ no its not!  if -option not in _DEFAULT_LIST, its tossed!]
  appends the values onto the variable
  instead of setting the variables.  e.g.:
    foo -b hi bar -b there
  sets b={hi there} and returns bar
} {
  
  set _RETURN ""

  upvar default_value default_value
  upvar defaulted defaulted

  for {set _INDEX 0} {$_INDEX < [llength $_ARG_LIST]} {} {
    if {[string index [lindex $_ARG_LIST $_INDEX] 0] == "-"} {
      # is a keyword pair
      set _ARG_NAME [string range [lindex $_ARG_LIST $_INDEX] 1 end]
      set _ARG_VALUE [lindex $_ARG_LIST [expr $_INDEX+1]]

      upvar $_ARG_NAME $_ARG_NAME
      lappend $_ARG_NAME $_ARG_VALUE
      set defaulted($_ARG_NAME) 0
      incr _INDEX 2

    } else {
      # not a keyword pair
      lappend _RETURN [lindex $_ARG_LIST $_INDEX]

      incr _INDEX
    }
  }

  foreach _DEFAULT $_DEFAULT_LIST {
    set _ARG_NAME [lindex $_DEFAULT 0] 
    upvar $_ARG_NAME $_ARG_NAME
    if {![info exists $_ARG_NAME]} {
      set $_ARG_NAME [lindex $_DEFAULT 1]
      set defaulted($_ARG_NAME) 1
    }
    set default_value($_ARG_NAME) [set $_ARG_NAME]
  }

  return $_RETURN
}


proc call_use_keyword {_ARG_LIST _DEFAULT_LIST} -desc {
  Deprecated: see call_keyword.  Parse function options using -option syntax.
} -doc {
  Like call_with_keyword but returns a list of arguments not keyworded AND
  keyworded arguments not in default list.  unlike call_with_keyword,
  doesn't error if arguments aren't in default list.
} {
  
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
	lappend _RETURN -$_ARG_NAME $_ARG_VALUE
      } else {
	set $_ARG_NAME $_ARG_VALUE
	set defaulted($_ARG_NAME) 0
      }
      incr _INDEX 2

    } else {
      # not a keyword pair
      lappend _RETURN [lindex $_ARG_LIST $_INDEX]

      incr _INDEX
    }
  }
  return $_RETURN
}

    
#proc test {args} {
#  call_by_keyword $args {{a 4} {b ""}}
#  puts "a=$a def=$default_value(a) $defaulted(a) b=$b def=$default_value(b)"
#}

#proc test2 {args} {
#  set value [call_with_keyword $args {{a 4} {b ""}}]
#  puts "a=$a def=$default_value(a) $defaulted(a) b=$b def=$default_value(b)"
#  return $value
#}
