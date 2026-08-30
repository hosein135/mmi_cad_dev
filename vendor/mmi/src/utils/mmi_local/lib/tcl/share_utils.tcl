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

set RCSVERSION(share_utils.tcl) { $Revision: 1.23 $ }

# Generic utilities shared between Sue and Max.
# (Much of this borrowed from Sue)
#
# The only things that really need to be here are routines that
# are used by other shared utilities, like prop_menu
# Other stuff includes user-interface routines, and filename parsing,
# and some really generic list manipulation stuff.

proc comment args -desc {takes any number or args and does nothing!} {}

proc car {l} {lindex $l 0}
proc cdr {l} {lrange $l 1 end}

proc pop {lname} {
  upvar $lname l
  set top [car $l]
  set l [cdr $l]
  return $top
}

proc push {lname new} {
  upvar $lname l
  set l [concat [list $new] $l]
}     

# see also lsearch (tcl command)
proc memq {l ewant} {
 # 6/00, pat: switch to use lsearch.
 return [expr {[lsearch -exact $l $ewant] >= 0}]

 #foreach e $l {
 #    if {$e == $ewant} { return 1 }
 #}
 #return 0
}

proc l_remove_name {list name} -desc {
    removes all copies of name from list
} {
    while { [set i [lsearch -exact $list $name]] != -1 } {
	set list [concat [lrange $list 0 [expr $i - 1]] \
		[lrange $list [expr $i + 1] end]]
    }
    return $list
}

proc absolute_path {fileName {pwd ""}} -desc {
  Returns absolute path for fileName.
} -doc {

  Turns filename into a "canonical" absolute path.
  Handles ~ expansion, and "dereferences" '.' and '..'
  Deletes automounter prefix?
  Final '/' stripped, except for root itself.

  If current working dir given as second args, it is used in place
  of pwd result, for turning relative paths into absolute paths.

  Example:
    absolute_path ~demo/max/example.max
  would return
    /home/user/max/example.max
} {

    # tilde expand
    set name [file dirname $fileName]/[file tail $fileName]
 
    # prepend current dir to relative dirs and handle auto router junk
    set name [clean_dir $name $pwd]

    set dirl [split $name /]

    # remove  '.'
    set dirl [l_remove_name $dirl "."] 

    # dereference '..'
    while { [set i [lsearch -exact $dirl ".."]] != -1 } {
	set dirl [concat [lrange $dirl 0 [expr $i - 2]] \
		[lrange $dirl [expr $i + 1] end]]
    }

    # strip blank names (no final "/")
    set dirl [l_remove_name $dirl ""]

    return "/[join $dirl /]"
}
   
proc split_file_name {filename {extensions ""} } -desc {
  split filename into directory, basename and extension parts
} -doc {
  returns the list: directory basename extension

  If extensions is nonempty, only splits off extensions in list
  from filename.

  NOTE:  extends filename into absolute path before splitting.
} {
    if {$filename == ""} { return { "" "" "" } }

    # turn filename into an absolute path if it isn't already.
    set filename [clean_dir $filename]

    # otherwise if there is no extension it gets confused
    set dir [file dirname "$filename.foo"]

    set cell [file tail [file root $filename]]

    set ext  [file extension $filename]

    # if ext not in sanctioned set, stick it on to cell name 
    if { $extensions != {} && ![memq $extensions $ext] } {
	set cell "$cell$ext"
	set ext ""
    }

    return [list $dir $cell $ext]
}


# cleans up the directory by turning it into an absolute path and removing
# any auto-mount garbage.
#
# USED by FSBox.tcl
set AUTO_MOUNT_PREFIX tmp_mnt
proc clean_dir {dir {pwd ""}} {

  global AUTO_MOUNT_PREFIX

  if {$pwd == ""} {
    set pwd [pwd]
  }
  if {[string range $dir 0 2] == "../"} {
    set dir "[file dirname $pwd]/[string range $dir 3 end]"
  } elseif {[string range $dir 0 1] == "./"} {
    set dir "$pwd[string range $dir 1 end]"
  } elseif {[string range $dir 0 1] == "."} {
    # This looks like nonsense.  dir is just "." (pat)
    set dir "$pwd[string range $dir 1 end]"
  }

  # make a relative path into an absolute path
  if {[string index $dir 0] != "/" && [string index $dir 0] != "~"} {
    set dir "$pwd/$dir"
  }

  # remove ~ stuff
  set dir [file nativename $dir]

  # don't we just love auto-mounters???
  set bogus [lindex [split $dir /] 1]
  if {$bogus == $AUTO_MOUNT_PREFIX} {
    set dir /[join [lrange [split $dir /] 2 end] /]
  }

  return $dir
}

# see if a unix executable exists before we try to run it.

proc executable_exists {name} {

  if {[catch "exec $name" msg] != 0} {
    # error, could be that it doesn't exist
    if {[string first "couldn't execute" $msg] == 0} {
      # out of luck
      return 0
    }
  }

  # looks good
  return 1
}

proc get_assoc {name list {nth 1}}  -desc {
  get the value for name in the association list.
} -doc {
  The <list> is an association list, which is a list of sub-lists
  where each sub-list is an association whose first element is a key
  to identify the association.
  This proc returns the value (the <nth> element) of the first association
  in <list> whose key matches <name>.
  If the optional index is given, get the "nth" value out of the list 
  (this is used for getting the default value).
  Example:

    get_assoc yyy {{xxx 3} {yyy 5 7 9}} 2
    Returns: 7
} {
  regsub -all {[][*?\\]} $name \\\\& name
  set return [lindex [lindex $list [lsearch $list "$name *"]] $nth]
  if { $return != "" } { return $return }
  # If the name has a space, quote or [] in it, tcl 8 will enclose
  # the name in {curly brackets} when it converts it to canonical
  # list notation, so search for that too.
  return [lindex [lindex $list [lsearch $list "{$name} *"]] $nth]
}

proc get_partial_assoc {name list {nth 1}} -desc {
  Only the first part of the name must match the key for a match.
} -doc {
  NOTE: This code does not work if the name contains spaces,
  brackets, or other special characters.
} {

  set match ""
  regsub -all {\[|\]} $name \\\\& name
  regexp "\{$name.*" $list match
  return [lindex [lindex $match 0] $nth]
}


proc get_assoc_cdr {name list}  -desc {
  get the value (cdr of list) for name in (assoc) list
} {
  regsub -all {[][*?\\]} $name \\\\& name
  return [lrange [lindex $list [lsearch $list "$name *"]] 1 end]
}


proc get_assoc_changed {name list1 list2 {nth 1}}  -desc {
  determine if values for name differ 
} -doc {
  Returns {} if the values match, otherwise returns value of entry in list2.
  If new entry is {}, returns "__NIL__".
 
  If nth is given, compares/returns the "nth" value out of the list.  This is
  used for getting the default value.
} {
  set value1 [get_assoc $name $list1 $nth] 
  set value2 [get_assoc $name $list2 $nth] 

    if { $value1 == $value2 } {
	return {}
    }

    if { $value2 == "" } {
	return "__NIL__"
    }

    return $value2
}

proc rm_assoc {name list} -desc {
  Removes name from assocication list.
} -doc {
  The <list> is an association list, which is a list of sub-lists
  where each sub-list is an association whose first element is a key
  to identify the association.
  This proc removes all associations from <list> whose
  key matches <name>.
  Example:

    puts [rm_assoc yyy [list {xxx 3} {yyy 5} {zzz 2}]]
  Returns the following list:
    {xxx 3} {zzz 2}
} {
  set new_list ""
  foreach assoc $list {
    if {[lindex $assoc 0] != $name} {
      lappend new_list $assoc
    }
  }
  return $new_list
}

proc put_assoc {value name list {index 1}} -desc {
  replace the value in an association list.
} -doc {
  The <list> is an association list, which is a list of sub-lists
  where each sub-list is an association whose first element is a key
  to identify the association.
  For each association whose key matches <name>, replace the
  <index> (default 1) numbered element in the association with value.
} {
  set new_list ""
  foreach assoc $list {
    if {[lindex $assoc 0] == $name} {
      lappend new_list [lreplace $assoc $index $index $value]
    } else {
      lappend new_list $assoc
    }
  }
  return $new_list
}

# copies arrays

proc copy_array {new_name old_name} {

  upvar $new_name new
  upvar $old_name old
  
  if {[info exists new]} {
    unset new
  }

  foreach name [array names old] {
    set new($name) $old($name)
  }
}


# Pretty prints a number using the spice metric suffixes

proc pp_number {num {format %g%s}} -desc {
  Create a pretty print version of the number.
} -doc {
  A pretty print number may contain a suffix of: G M K m u n p f a
  meaning Giga, Mega, Kilo, milli, micro, nano, pico, femto, atto.

  Example:

    pp_number 1.0e-7
    Returns: 100n
} {
  set num [parse_pp_number $num]

  if {$num == 0} {
    return 0
  }

  if {![regexp {\.} $num] && ![regexp -nocase e $num]} {
    # must make into a float otherwise could be int too large
    # very gross hack
    set num $num.0
  }

  set suffixes {G M K "" m u n p f a}
  set logscale [expr floor(log10(abs(1.0*$num))/3.0)]
  set mantissa [expr 1.0*$num/pow(10,3.0*$logscale)]
  set exp [lindex $suffixes [expr round(3 - $logscale)]]
  return [format $format $mantissa $exp]
}


# Parses a string with spice notation into a number.  Trailing units
# are ignored.  Examples: 3.2e-4, 32.4fF, 23 Ohms

proc parse_pp_number {string} -desc {
  Parse a pretty print number.
} -doc {
  A pretty print number may contain a suffix of: G M K m u n p f a
  meaning Giga, Mega, Kilo, milli, micro, nano, pico, femto, atto.

  Example:

    parse_ppp_number 120p
    Returns: 1.2e-10
} {
  regexp -indices -nocase {[a-d]|[f-z]} $string index
  
  if {[info exists index] == 0} {
    return $string
  }

  set mantissa [string range $string 0 [expr [lindex $index 0]-1]]
  if {[catch "expr 1 + $mantissa"]} {
    # not a correct number
    return 0
  }

  set suffixes "GMK munpfa"
  set suffix [string range $string [lindex $index 0] [lindex $index 1]]
  set pos [string first $suffix $suffixes]
  if {$pos == -1} {
    return $mantissa
  }
  set num [expr $mantissa * pow(10,3.0*(3-$pos))]
  return $num
}


proc lreverse {list} -desc {
  reverses the elements in a list
} {

  set new_list ""

  foreach element $list {
    set new_list [concat [list $element] $new_list]
  }

  return $new_list
}


# returns maximum of any number of numbers
proc max {a args} -desc {
  Returns the maximum of the arguments.
} -doc {
  Usage: max arg1 [arg2 ...]
} {
  set max $a
  foreach i $args {
    if {$i > $max} { set max $i }
  }
  return $max
}

# returns minimum of any number of numbers
proc min {a args} -desc {
  Returns the minimum of the arguments.
} -doc {
  Usage: min arg1 [arg2 ...]
} {
  set min $a
  foreach i $args {
    if {$i < $min} { set min $i }
  }
  return $min
}

proc use_first args -desc {
  return the value of the first variable name that is defined and not "".
} -doc {
  The <args> is a list of variable names.
  Evaluates variable names in <args> in the current context in order.
  If the variable is defined and non-nil, returns its value. If none are
  defined, returns nil (""), or the value of the final literal argument.

  If the first character of the name is ' then it is a literal
  that is returned verbatim.  This is useful as the final arg
  to be returned if none of the variables are defined or have
  non nil values.

  For example: 

        set b 23
        sue> use_first a b c
        23
        sue> use_first aa bb cc '58
        58
} {

  foreach var $args {
    if {[string index $var 0] == "'"} {
      return [string range $var 1 end]
    }
    upvar $var name
    if {[info exists name] && [string compare $name ""] != 0} {
	return $name
    }
  }
}

proc use_init {varname val} -desc {
  init variable varname to val if it does not already exist
} -doc {
  identical to:
  set varname [use_first varname '$val]
} {
  upvar $varname tmp
  if {! [info exists tmp]} {
    set tmp $val
  }
}


# inserts the args into the list if they are not already in it.

proc insert_unique {qlist pos args} {

  upvar $qlist list

  foreach element $args {
    if {[lsearch $list $element] == -1} {
      set list [linsert $list $pos $element]
    }
  }
  return $list
}


proc info_proc {name} -desc {
  like info but check auto_index
} -doc {
  Returns the name of the procedure if it exists, "" otherwise.
  Differs from info commands since this will also check to see if the
  procedure is in the auto_index.
} {

  global auto_index

  if {[info commands $name] != ""} {
    return $name
  }

  if {[info exists auto_index($name)]} {
    return $name
  }

  return ""
}


proc backquote {list} -doc {
  like backquote notation in Lisp.  Nothing is eval'd unless preceded
  by a $ (instead of a comma).  Thus in:
      backquote {foo $$bar $baz}
  bar is evaluated but baz isn't.
  Note that this procedure will not work with all TCL syntax
  and will presently only work on $$<var> not on $[<exp>]
} {

  set front ""
  while (1) {

    # look for the next string to be evaluated, if there is one.
    if {[regexp -indices {\$\$} $list pos] == 0} {
      break
    }
    set pos [expr [lindex $pos 0] + 1]

    # now search for the end of the expression to be evaluated.
    set back [string range $list $pos end]

    if {[regexp -indices {\ |\$|\}|,|\]|\.|\\|\"} \
	     [string range $back 1 end] index] == 1} {
      set index [lindex $index 0]
    } else {
      set index [string length $back]
    }

    set value [uplevel "set [string range $back 1 $index]"]
#    puts "[string range $back 0 $index] -> $value"

    set front "$front[string range $list 0 [expr $pos - 2]]$value"

    set list [string range $back [expr $index + 1] end]
  }

  return $front$list
}

proc setl {names values} -desc {
  sets list of variable names to corresponding entries in list of values
} -doc {
    Example:

	setl {a b c} "4 12 foo"

    is the same as the following commands:

	set a 4
	set b 12
	set c foo
} {
  set i 0
  foreach name $names {
    #uplevel [list set $name [lindex $values $i]]
    upvar $name x
    set x [lindex $values $i]
    incr i
  }
  # returns number of variables set
  return $i
}


proc lremove {list what} -desc {
  remove an element from a list if it exists.
} {

  while {[set pos [lsearch $list $what]] != -1} {
    set list [lreplace $list $pos $pos]
  }
  return $list
}


proc struct {structname varname values} -desc {
  Unpack a list into structure format.
} -doc {
  Structname is a structure defined in the MAX_STRUCT array.
  Each entry in the MAX_STRUCT array defines the field names
  of the structure.  This routine breaks out the values of the
  fields in the structure from the list: values,
  and assign them to variables named varname.field.
  Example, change the box to a point at its lower left corner:
    set MAX_STRUCT(rect) "x1 y1 x2 y2"
    struct rect r [lay_box]
    lay_box ${r.x1} ${r.y1} ${r.x1} ${r.y1}
} {
  global MAX_STRUCT
  set structdef $MAX_STRUCT($structname)
  set i 0
  foreach name $structdef {
    upvar $varname.$name x
    set x [lindex $values $i]
    incr i
  }
  # returns number of variables set
  return $i
}


proc destruct {structname varname} -desc {
  The reverse of struct.  Return the list given the structure def and varname.
} {
  global MAX_STRUCT
  set retval ""
  set structdef $MAX_STRUCT($structname)
  foreach name $structdef {
    upvar $varname.$name x
    if {[catch {lappend retval $x}]} {
      msg "warning: in destruct of struct $structname: $varname.$name not defined\n"
      # Give it a null value.
      lappend retval ""
    }
  }
  return $retval
}

proc approx {a op b {res 0}} -desc {
  Determines a op b where op is ==, !=, etc.,
  within floating point round-off error, or error
  specified by optional <res> argument.
  Example:
    approx 1.000 <= 1.001 .01
  returns:
    1   (true)
} {
    set diff [expr $a - $b]
    # Dont know whether it uses single or double precision.
    # But this is close enough for government work.
    set eq [expr abs($diff) < ($res ? $res : 1e-10)]
    switch $op {
    "==" { return $eq }
    "!=" { return [expr !$eq] }
    ">=" { return [expr $a > $b || $eq] }
    "<=" { return [expr $a < $b || $eq] }
    ">" { return [expr $a > $b] }
    "<" { return [expr $a < $b] }
    }
}

proc assert {expression} -desc {
  if expression is not TRUE, print error message.
} {
    uplevel 1 "if { !($expression) } { error {assertion failed: $expression} }"
}
