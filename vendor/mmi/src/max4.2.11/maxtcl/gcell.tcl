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

set RCSVERSION(gcell.tcl) { $Revision: 1.60 $ }

# TODO: netlisting/extraction must be fixed for gcells



# Implements generator cells in max

set _GCELL_(last) ""

proc gcell_load {cell} -desc {
  called by C code whenever a gcell is loaded
} {
  global MAX_DEVELOPER

  if {$MAX_DEVELOPER && [use_first GCELL_TEST] == 1} {
    puts "max_developer: gcell_load $cell"
  }

  global _GCELL_ GCELL

  # get the type and props out of the name
  regsub -all "!" [string trimleft $cell \#] " " list
  set type [lindex $list 0]
  set args [lrange $list 1 end]

  if { ! [info exists GCELL($type,proplist)] } {
    # mha says: dont popup a dialog box now, because
    # this routine is called from max.
    msg "ERROR: Attempt to load non-existent gcell: $type\n"
    # need notify even on total failure (database sees empty gcell) - mha
    db_gcell_notify $cell
    return
  }

  #DEBUG
  global gcell_load_semaphore
  # Was debugging a max problem here.  Mha fixed it.
  if { $MAX_DEVELOPER && [info exists gcell_load_semaphore] } {
    puts "max_developer: gcell_load called again before previous call finished"
  }
  set gcell_load_semaphore 1

  set prev_active [use_first _GCELL_(active)]
  set _GCELL_(active) $cell

  # convert arg list from -option syntax to prop_list with keyword values
  set prop_list [_gcell_args_to_prop_list -all $type $args]
  set prop_list [rm_assoc _version $prop_list]

  # build this cell with these properties
  # The gcell is saved in this namespace.
  # Fish around in it for the name of the function we want.
  set scope gcell_$GCELL($type,basetype)
  set errstat 0

  set editid [get_assoc _edit $prop_list]

  if { $editid != "" } {
    # Special case: This is a new cell created by the user,
    # either a group or a modification to an existing gcell.
    # If we are reading in an existing max file, do nothing;
    # let max use the previous contents of the group.
    # If we are creating a new cell, the contents of the cell
    # are waiting around in the special cell named: __NEW_GCELL$id
    set cell_name __NEW_GCELL$editid
    if { [cell_info $cell_name] != "__NO_SUCH_BUFFER__"} {
      db_cell_copy -source $cell_name $cell
      db_cell_delete $cell_name
    }

    # For groups, I tried to return the name of the group, like this:
    # set ret "GROUP_$some_number"
    # but when you duplicate a group, the name doesnt change,
    # which is kind of confusing, so just return nothing.
    # Max will still label it with the typename, ie "GROUP"
    # If you return "", max uses the cell id! so return a space,
    # which forces max to leave the second cell text area blank.
    if { $type == "GROUP" } {
      set cell_text " "
    } else {
      set cell_text "modified"
    }

  } else {
    # Find a proc in the gcell to make it.
    if {[info commands ::${scope}::gcell_make_$type] != ""} {
      set cmd ::${scope}::gcell_make_$type
    } elseif {[info commands ::${scope}::gcell_make] != ""} {
      set cmd ::${scope}::gcell_make
    } else {
      set cmd ""
    }

    if { $cmd != "" } {
      if {[catch [list namespace eval $scope [list $cmd $prop_list] ] cell_text]} {
	# Note: I want to use msg -warn here, which would be safe
	# as long as this routine was called inside a msg_catch,
	# which it is, if invoked from _make_gcell_internal.
	# However, max could call this any time, so instead,
	# convert the error returned by catch, above, into an info msg,
	# and _make_gcell_internal will catch it and turn it
	# back into a -warn that creates a popup, if it contains
	# the string ERROR.  So do not remove "ERROR" from the message!
	# Its a kludge, but it works and its safe.  (pat)

	# Note: I tried to include a rudimentary stack trace in the error message,
	# but all I got was the gcell_load, because the stack has
	# already been cleaned up.
	msg "ERROR making gcell \"$type\": $cell_text\n"
	set errstat 1
      }
    } else {
      msg "ERROR making gcell \"$type\": No function gcell_make found\n"
      set errstat 1
    }
  }

  # DEBUG
  unset gcell_load_semaphore

  set _GCELL_(active) $prev_active

  if { $errstat } {
    # TODO: We need to delete the cell def, because otherwise
    # max keeps it forever and you have to restart max
    # to work on the gcell.
  } else {
    # Notify max that gcell has changed.
    db_gcell_notify $cell

    set cell_text2 $type

    if {[info commands ::${scope}::gcell_info_$type] != ""} {
      set infocmd ::${scope}::gcell_info_$type
    } elseif {[info commands ::${scope}::gcell_info] != ""} {
      set infocmd ::${scope}::gcell_info
    } else {
      set infocmd ""
    }
    if { $infocmd != "" } {
      # If this fails, the name will just be wrong, so dont worry about it.
      if {![catch [list namespace eval $scope \
	[list $infocmd cell_text $prop_list] ] ret]} {
	if { $ret != "" } {
	  set cell_text2 $ret
	}
      }
    }

    # name stuff.  Return string from gcell_make_$type is shown
    lay_cell_text -cell $cell $cell_text2 $cell_text
  }

  return
}


proc gcell_paint {layer x1 y1 x2 y2} -desc {
  required paint command for gcells.  
} {

  global _GCELL_

  # 4/4/00 Note: db_paint -cell requires a canonical rectangle,
  # even though db_paint does not.  Who knows why, but lets comply.
  setl {x1 y1 x2 y2} [can_rect [list $x1 $y1 $x2 $y2]]
  db_paint -no_notify -cell $_GCELL_(active) $layer $x1 $y1 $x2 $y2
}


proc gcell_polygon {layer args} -desc {
  required polygon command for gcells.  
} -doc {
Usage:
  gcell_polygon <layer> <x1> <y1> <x2> <y2> ...
} {

  global _GCELL_

  eval db_polygon -no_notify -cell $_GCELL_(active) $layer $args
}


proc gcell_label {text kind layer x1 y1 {x2 ""} {y2 ""}} -desc {
  required label command for gcells.  
} -doc {
Usage:
  gcell_label <text> <kind> <layer> <x1> <y1> [<x2> <y2>]
} {

  global _GCELL_

  if {$x2 == ""} {
    set x2 $x1
  }
  if {$y2 == ""} {
    set y2 $y1
  }

  db_label -no_notify -cell $_GCELL_(active) -kind $kind \
      $layer $text $x1 $y1 $x2 $y2
}


proc define_gcell {type default_properties} -desc {
  define a gcell type with the given default properties
} {

  global GCELL GCELL_DIRS _GCELL_

  # Use puts instead of msg for informational message, because 
  # this is called from the gcell that is loaded inside a msg_catch.

  if {! [info exists _GCELL_(curtype)]} {
    msg "warning: call to define_gcell \"$type\" occurred outside of any gcell\n"
  } else {
    if { $_GCELL_(curtype) != $type } {
      msg "warning: gcell file \"$_GCELL_(curtype)\" defining gcell type $type\n"
    }
  }
  set GCELL_DIRS($type) $_GCELL_(curdir)

  set GCELL($type,proplist) $default_properties
  set GCELL($type,basetype) $_GCELL_(curtype)
}

proc gcell_source {args} -desc {
  Source the specified filename as a gcell.
} -doc {
  USAGE:
    gcell_source [-force] filename

  This command is useful when developing gcells.
  You can not just use the tcl "source" command to source gcell code.
  Use this command instead.

  The -force flag forces the gcell to overwrite an existing gcell
  by the same name that was already loaded into max.  This should
  be used only for gcell development.  If the gcell is being used
  by some other cell when you call this function with this flag,
  havoc (possibly including core dumps) will ensue.

  Example:

    gcell_source /home/cad/mmi_local/max/motor.maxg
} {
  global GCELL _GCELL_ GCELL_DIRS doc_source

  set pathname [call_keyword $args {{force}}]
  if { $pathname == "" } {
    error "gcell_source with no filename"
    return   ;# Just in case
  }

  set filename [file tail $pathname]
  set type [file rootname $filename]
  set dir [file dirname $pathname]

  if {$force == 0 && [info exists GCELL_DIRS($type)]} {
    # This gcell already exists.
    # We do not allow users to redefine existing gcells -
    # it would cause havoc in any max file that was using them.
    msg "warning: gcell \"$type\" in directory $dir ignored: already defined in $GCELL_DIRS($type)\n"
    return
  }

  if {$force == 0 && [info exists GCELL($type,proplist)]} {
    # This is wierd.  A gcell file of $type has not been read in,
    # but some other gcell defined this $type.
    msg "warning: during read of gcell \"$type\" in directory $dir: \
      some other gcell already did a define_gcell \"$type\" - \
      previous definition will be ignored.  Find and fix this!\n"
  }

  set save_doc_source $doc_source
  set doc_source gcells

  set _GCELL_(curtype) $type
  set _GCELL_(curdir) $dir

  # Doesn't exist, load it and remember where we got it.
  # The namespace does not work through the redefined "proc"
  # (_doc_proc_orig) for some reason, so we need to communicate to it.
  #global GLOBAL_NAMESPACE
  set scope gcell_$type
  #set GLOBAL_NAMESPACE $scope ;# communicate to internal "proc" command.
  if {[msg_catch "uplevel \#0 namespace eval $scope {source $pathname}" \
    msg info warning]} {
    #msg "GCELL error loading $pathname: $msg $a $b\n"
    msg "error: loading gcell $pathname: $msg $info $warning\n"
  } else {
    # pass along any warnings
    if { $info != "" } {
	msg "$info\n"
    }
    if { $warning != "" } {
	msg -warn "$warning\n"
    }
  }
  #unset GLOBAL_NAMESPACE

  # The gcell can export commands from its namespace.
  # Import them to the global namespace now.
  namespace import ::${scope}::*

  # make sure it actually defined the gcell
  if {! [info exists GCELL($type,proplist)]} {
    msg "warning: gcell \"$type\" in directory $dir did not perform define_gcell \"$type\"\n"
  }
  unset _GCELL_(curtype)
  set doc_source $save_doc_source
}


proc _load_gcells {dir} -desc {
  load the gcells in the given directories if they haven't already been loaded 
} {
  global GCELL GCELL_DIRS CELL
  global _GCELL_LOADED _GCELL_

  # _load_gcells is called over and over and over and over and over...
  # Dont load it more than once.
  if {[info exists _GCELL_LOADED($dir)]} { return }

  # Define the GROUP gcell.
  # These are the generic properties for the gcell,
  # which gcell_load will need to know.
  # Could put this in a little tiny .maxg file, but why bother?
  set prop_list [list [list _edit 0]]
  set GCELL(GROUP,proplist) $prop_list
  set GCELL(GROUP,basetype) ""

  set _GCELL_LOADED($dir) 1

  # get the gcells in this directory
  set save_pwd [pwd]
  if {[catch "cd $dir"]} {
    # can't go to directory
    msg "Warning, can't goto directory \"$dir\" to load gcells.  Bad pathname or permissions.\n"
    return
  }
  set gcells [glob -nocomplain *$CELL(gcell_suffix)]

  if { $gcells != "" } {
      msg "Loading gcells from directory: $dir\n"
  }
  
  foreach gcell $gcells {
    gcell_source $dir/$gcell
  }

  cd $save_pwd
}


proc is_gcell {cell_def {option ""}} -desc {
  returns 1 if this cell is a gcell, 0 otherwise
} {

  # for now, any cell starting with a # is a gcell
  if {[string index $cell_def 0] != "\#"} {
    return 0  ;# Not a gcell.
  }

  if { $option == "nogroup" } {
    if { [gcell_typename $cell_def] == "GROUP" } { return 0 }
  }

  if { $option == "group" } {
    return [expr { [gcell_typename $cell_def] == "GROUP" }]
  }

  if { $option == "editable" } {
    if { [_gcell_has_been_edited $cell_def] == "edited" } {
      return 1
    } else {
      return 0
    }
  }
  return 1
}

proc is_gcell_selected {} -desc {
  Is there a gcell selected?
} {
  foreach cell_info [sel_what_l cells] {
    setl {inst_name cell_name} $cell_info
    if {$cell_name != "" && [is_gcell $cell_name nogroup]} {
      return 1
    }
  }
  return 0
}

proc make_gcell {{type ""}} -desc {
  select a gcell from available gcells, popup prop menu, and and make it (unless cancelled)
} -doc {
  This is invoked when user selects a gcell from a max list box.
} {

  global GCELL _GCELL_

  if {$type == ""} {
    # query user
    set choices [lsort -dictionary [array names GCELL]]

    if {$_GCELL_(last) != ""} {
      # use this as the default
      set choice $_GCELL_(last)
    } else {
      # just use the first one on the list
      set choice [lindex $choices 0]
    }

    set prop_list [list [list type $choice choice $choices]]
    
    global max_win
    set win $max_win.layout
    set winy [expr [winfo rooty $win] + 50]
    set winx [expr [winfo rootx $win] + 50]

    set title "Make Gcell"
    set message "Which Gcell:"

    # create the menu
    set new_prop_list [prop_menu $winx $winy $message $title $prop_list]

    if {$new_prop_list == ""} {
      # user hit cancel
      return
    }

    set type [get_assoc type $new_prop_list]
  }

  if {![info exists GCELL($type,proplist)]} {
    msg "Aborting, $type is not a valid gcell.\n"
    return
  }

  # prop_list popup
  set prop_list [_gcell_prop_list_popup $type]
  if {$prop_list == ""} {
    # user hit cancel
    return
  }

  set _GCELL_(last) $type

  # This code is called from list_box, and the cursor is off screen,
  # so always just stick it in the middle of the screen.
  set start [eval uusnap -user [center_bbox [dbt_frame]]]

  _make_gcell_internal $type $start $prop_list

  # let the user move it to the desired place
  #clipboard_paste drop $bbox
  clipboard_paste drop
}


proc place_gcell {type origin args} -desc {
  place a gcell
} -doc {
  The <type> is the type of gcell, for example, "fet".
  The <origin> is the coordinates where the gcell will be placed,
  as a single list or string, for example "10 15".  The gcell is placed
  so that its origin is at the specified coordinates.
  The <args> are optional, and are any number of properties
  to be passed to the gcell, given as keyword-value pairs,
  i.e. "-keyword value".

  Example:
    place_gcell fet "0 0" -type pfet
} {

  global GCELL max_win

  if {![info exists GCELL($type,proplist)]} {
    error "ERROR, gcell type \"$type\" not found."
    return
  }

  # do it (also remove defaulted args)
  _make_gcell_internal $type [eval uusnap -mask $origin] \
	[_gcell_args_to_prop_list $type $args]

}


# NOTE: all the underbars on the variables in this proc are no longer necessary.
# They were needed in a previous implementation.
proc _gcell_args_to_prop_list {{-all} {-preserve} gtype __args} -desc {
  defines random variables
} -doc {
  <__args> is a list of options of the form: -option value
  <gtype> is the type of gcell.
  This function returns a new prop_list formed by modifying
  the updating the values prop_list that appear in args.
  Eg, if you call _gcell_args_to_prop_list {{a 1} {b 2}} "-b 3"
  you get back {{a 1} {b 3}}.

  There are some special props: the _BBOX_ and _STRETCH_ may appear in args
  to do stretching, even though it does not appear in __prop_list.
  The _version prop is used by max to mark gcells whose
  contents no longer matches their generator.
  The _edit prop is used by this module to mark modified gcells.
  A modified gcell comes in two types: Groups and other gcells.
  The GROUP gcell is a special container gcell that can contain
  anything.  Each GROUP gcell gets a unique -_edit prop, and
  can be individually edited.  Any other gcell can be edited,
  in which case it is also given a unique -_edit prop, however,
  we took the ability for the user to do this out of the user
  interface because it was deemed confusing.
  
  If -all, return all props: _BBOX_ and _version default to "".
  Otherwise, _BBOX_ is removed if empty, and _version is always
  removed from the prop_list returned by this function,
  because this function is only called when the gcell is about to be
  created or recreated, and newly created gcells should not
  have a -_version property.
  Neither prop should appear in the visible list of properties

  If an option in __args does not exist in the gcell definition,
  it is not returned unless -all or -preserve
} {

  global GCELL
  set __prop_list $GCELL($gtype,proplist)

  # Create array arglist() a hash to map __args arg to value.
  set arglen [llength $__args]
  for {set i 0} {$i < $arglen} {incr i 2} {
    # The name is of the form -option, so strip off the prepended "-".
    set name [lindex $__args $i]
    set value [lindex $__args [expr $i+1]]
    # The arg name is of the form -option, so strip off the prepended "-".
    set arglist([string range $name 1 end]) $value
  }

  set new_prop_list ""
  foreach prop $__prop_list {
    set name [lindex $prop 0]
    if {[string match _* $name] && $all == 0} {
      # If ! all flag, remove props that begin with underbar
      # from prop_list before returning it.
      continue
    }
    if { [info exists arglist($name)] } {
      set prop [lreplace $prop 1 1 $arglist($name)]
      unset arglist($name)
    }
    lappend new_prop_list $prop
  }

  # What is left in arglist are args that did not appear in prop_list.
  # If all flag, append them to the prop list.
  foreach name [array names arglist] {
    # Special case: if _BBOX_ or _STRETCH_ apprears in __args,
    # it is always passed through to gcell (if value is non-empty).
    # All other args beginning with underbar are ignored unless -all set.

    # 1/18/01: took this out.
    # 4/17/01: put it back in to make stretch work again.
    if { ( $name == "_BBOX_" || $name == "_STRETCH_" ) && $arglist($name) != ""} {
      lappend new_prop_list [list $name $arglist($name)]
    }

    if { $all } {
       lappend new_prop_list [list $name $arglist($name)]
    } else {
      # If the prop is _BBOX_ or _STRETCH_, we want to just add it in.
      # Otherwise, this is an error: the user tried to change a property
      # on a gcell that does not have that property.
      #if { $name != "_BBOX_" && $name != "_STRETCH_" }
      if {[string index $name 0] != "_"} {

	# Too bad we dont know the gcell name at this point.
	msg "Warning: unrecognized property -$name on gcell $gtype that does not have that property.\n"

	if {$preserve} {
	  # If -preserve, return it even though we do not recognize it.
	  lappend new_prop_list [list $name $arglist($name)]
	}
      }
    }
  }
  return $new_prop_list

  ### OLD CODE BELOW
  set __special_props [list [list _BBOX_ {}] [list _version {}] [list _edit {}]]

  set __all_props [concat $__prop_list $__special_props]
  call_by_keyword $__args $__all_props

  set __new_prop_list ""
  foreach __pair $__all_props {
    set __var [lindex $__pair 0]
    if { ($__var == "_version" || $__var == "_edit") && $all == ""} {
      # Always discard -_version or _edit
      continue
    } elseif {$__var == "_BBOX_" && $all == ""} {
      if {$_BBOX_ != ""} {
	lappend __new_prop_list [list _BBOX_ $_BBOX_]
      }
    } elseif {[info exists $__var]} {
      # user redefined
      lappend __new_prop_list [lreplace $__pair 1 1 [set $__var]]
    } else {
      # This code is never called, and never has been!
      assert { 0 }
      lappend __new_prop_list $__pair
    }
  }

  return $__new_prop_list
}


proc _gcell_prop_list_to_args {type prop_list} -desc {
  converts a prop_list to a list of non-defaulted arguments
} {

  global GCELL

  set default $GCELL($type,proplist)

  set args ""
  foreach pair $prop_list {
    setl {var value} $pair

    if {[get_assoc $var $default] != $value} {
      lappend args -$var $value
    }
  }

  return $args
}


proc _gcell_prop_list_popup {type {prop_list ""}} -desc {
  queries user to change properties of a given gcell
} {

  global GCELL max_win

  if {$prop_list == ""} {
    set prop_list $GCELL($type,proplist)
  }

  set win $max_win.layout
  set winy [expr [winfo rooty $win] + 50]
  set winx [expr [winfo rootx $win] + 50]

  set title $type
  set message "Edit Properties:"

  # create the menu
  set new_prop_list [prop_menu $winx $winy $message $title $prop_list]

  if {$new_prop_list == ""} {
    # user hit cancel
    return ""
  }

  return $new_prop_list
}

proc _make_gcell_internal {type origin prop_list} -desc {
  actually builds a gcell from the type and properties
} -doc {
  The origin is in edit cell coords, not the root cell coords.
  They are different when you are editing in place.

  Return the list: {new_cell_def_name  new_cell_id}
} {

  global _GCELL_ GCELL MAX_DEVELOPER GCELL_TEST

  if {$MAX_DEVELOPER && [use_first GCELL_TEST] == 1} {
    #puts "max_developer: _make_gcell_internal $type $origin $prop_list"
  }

  # Give the gcell an opportunity to munge its own props.
  set scope gcell_$GCELL($type,basetype)
  if {[info commands ::${scope}::gcell_make_props_${type}] != ""} {
    # old name found
    set cmd ::${scope}::gcell_make_props_${type}
  } elseif {[info commands ::${scope}::gcell_make_props] != ""} {
    # new name found
    set cmd ::${scope}::gcell_make_props
  } else {
    set cmd ""
  }
  if { $cmd != "" } {
    if {[catch [list namespace eval $scope \
      [list $cmd $prop_list]] ret]} {
      # ret is the error message.
      error "$ret"
    } else {
      # ret is the new prop_list munged by the gcell command.
      set prop_list $ret
    }
  }

  # Remove the _BBOX_ and _STRETCH_ that were passed to gcell_make_props.
  set prop_list [rm_assoc _BBOX_ $prop_list]
  set prop_list [rm_assoc _STRETCH_ $prop_list]

  # create the unique cell name from the type and properties
  set args [_gcell_prop_list_to_args $type $prop_list]
  regsub -all " " [concat \#$type $args] "!" cell

  # place cell (also selects it)
  # (C code calls gcell_load if necessary)  
  # Catch all messages, since error messages that occur while creating
  # the gcell can not create dialog boxes until max returns.
  if {[msg_catch \
    { set id [db_instance $cell [lindex $origin 0] [lindex $origin 1]] } \
    msg info warning]} {
      msg -warn "error: loading gcell $gcell: $msg $info $warning\n"
  } else {
    # report any warnings in a dialog box
    # If info message contains the string ERROR, it was actually
    # an error caught in gcell_load, so promote it to a warning,
    # which will put it in dialog box.
    if { $info != "" } {
	if { [regexp ERROR $info] } {
	  set warning "$info$warning"
	} else {
	  msg "$info"
	}
    }
    if { $warning != "" } {
	msg -warn "gcell: $warning"
    }
  }

  # Leave the cell selected.
  if { $id == "" } {
    # no id returned by db_instance\n"
    msg "Warning, gcell placed on exact copy of itself and ignored.\n"
    return
  }
  sel_cell2 $id

  return [list $cell $id]
}


proc UNUSED_gcell_get_origin {id} -desc {
    return the origin of the cell in its own coord system.
} {

  if {1} {
    # This works, but very costly to edit_push/edit_pop, and changes display.
    edit_push override
    setl {lx ly} [lay_bbox]
    edit_pop
    return [list $lx $ly]
  } else {

    # This does not work!
    # Get gcell origin in its own cell coord system.
    #struct max_cell cell_unrotated [dbt_find_cell ${cell.id}]
    struct max_cell cell_unrotated [sel_what cells]
    setl {a b c d e f} ${cell_unrotated.transform}
    set lx [expr ${cell_unrotated.x1} - $c]	;# Transform x offset
    set ly [expr ${cell_unrotated.y1} - $f]	;# Transform y offset
    return [list $lx $ly]
  }

if {0} {
    # Get cell info in edit-cell coorinates.
    set stuff [dbt_find_cell $id]
    struct max_cell c $stuff

  struct max_cell c [sel_what cells]
  setl {a b c d e f} ${c.transform}
  set lx [expr ${c.x1} - $c]	;# Transform x offset
  set ly [expr ${c.y1} - $f]	;# Transform y offset
  set _GCELL_($cell,origin) "$lx $ly"
  # get orientation
  set orient [orientation ${cell.transform}]

  # unorient
  switch $orient {
    "r90" {
      :clockwise 270
    }
    "r180" {
      :clockwise 180
    }
    "r270" {
      :clockwise 90
    }
    "fx" {
      :sideways
    }
    "fy" {
      :upsidedown
    }
    "fx_r90" {
      :clockwise 270
      :sideways
    }
    "fy_r90" {
      :clockwise 270
      :upsidedown
    }
  }
}

}

proc _pats_unused_edit_gcell_props {{inst_name ""} args} -desc {
  edit the selected gcell's properties and remake it or named.
} -doc {
    This version works without needing special case for edit-in-place,
    and without an ugly edit_push override.  However, it does
    not work because db_instance creates cells with rotation
    edit-cell coords instead of root-cell coords.
    When that is fixed, we probably want to go back to this version.

    Return 0 on success, non-zero on failure.
} {

  global GCELL

  if {$inst_name == ""} {
    # get name of first selected instance
    set done 0
    foreach cell_list [sel_what_l cells] {
      struct max_cell cell $cell_list
      # sel_cell2 takes care of the path for edit-in-place now.
      #set inst_path "${cell.path}${cell.id}"
      set inst_name ${cell.id}
      if {[is_gcell ${cell.def}]} {
	set done 1
	break
      }
    }

    if {!$done} {
      msg "Aborting, must select a gcell.\n"
      return
    }
  }

  # select this one just in case there were multiple things selected before
  sel_cell2 $inst_name

  # This gets the cell info in root-cell coords.
  # Defines cell with fields:id def x1 y1 x2 y2 path expansion transform
  struct max_cell cell [sel_what cells]

  # get its type, properties
  setl {type existing_args} [_gcell_info ${cell.id}]

  if {$args != ""} {
    set prop_list [_gcell_args_to_prop_list $type \
		       [concat $existing_args $args]]
  } else {
    set old_prop_list [_gcell_args_to_prop_list $type $existing_args]

    # prop_list popup
    set prop_list [_gcell_prop_list_popup $type $old_prop_list]
    if {$prop_list == "" || $prop_list == $old_prop_list} {
      # user hit cancel or didn't change anything
      return
    }
  }

  # Get gcell origin in its own cell coord system.
  setl {lx ly} [_gcell_get_origin ${inst_name}]

  # Origin is difference of editcell and local coords
  set x [expr ${cell.x1} - $lx]
  set y [expr ${cell.y1} - $ly]

  # delete the old instance
  :delete

  # make the new one
  # The x, y coords are in the coord system of the edit-cell.
  _make_gcell_internal $type "$x $y" $prop_list

  # call it the same name to preserve flylines
  :identify ${cell.id}

  # reorient according to original orientation
  set orient [orientation ${cell.transform}]
  switch $orient {
    "r90" {
      :clockwise
    }
    "r180" {
      :clockwise 180
    }
    "r270" {
      :clockwise 270
    }
    "fx" {
      :sideways
    }
    "fy" {
      :upsidedown
    }
    "fx_r90" {
      :sideways
      :clockwise
    }
    "fy_r90" {
      :upsidedown
      :clockwise
    }
  }
  return 0
}


proc _gcell_has_been_edited {def} -desc {
  Returns "modified", "edited" or "", to indicate gcell state.
} -doc {
  Checks for a -_version or -_edit gcell arg.  If it exists,
  it indicates that the current contents of the gcell
  do not match what would be generated by the generator.
  This happens if the gcell is edited by hand (-_edit), or if
  the results of the generator change, possibly due
  to a tech file change (-_version).

  The return value is "edited" if the user has ever edited the gcell,
  whether they actually made any changes or not.
  Note that "GROUP" cells will always return "edited".

  The return value is "modified" if the gcell has not been edited,
  but max thinks it is modified, meaning that if you rerun
  the generator, you would get a different result from what is currently
  in the cell.
  
  Note: max will apply the _version prop to edited cells, too,
  so check _edit prop first.
} {

  global GCELL
  set type [gcell_typename $def]
  set existing_args [_gcell_args $def]
  # Get complete propertly list so we can look for -_version
  set all_prop_list [_gcell_args_to_prop_list -all $type $existing_args]
  if {[get_assoc _edit $all_prop_list] != ""} {
    return "edited"
  } elseif {[get_assoc _version $all_prop_list] != ""} {
    return "modified"
  }
  return ""
}

proc gcell_get_props {args} -desc {
  Return the properties for the indicated gcell
} -doc {
  USAGE:
    gcell_get_props [-options] inst_name
  
  Returns the properties for the cell with id: <inst_name>
  Options can be:
    -default  return the default props for this type of gcell,
	      instead of the props for this specific id.

  This is an API function for users.
  Note: This proc modifies the selection.
} {
  global GCELL

  set options [list {default}]
  set inst_name [call_keyword $args $options]

  # select this cell.
  sel_cell2 $inst_name

  # Fail if sel_cell2 failed.
  if {[llength [sel_what_l cells]] != 1} { return "" }

  # get its type, properties
  setl {type existing_args} [_gcell_info $inst_name]
  assert { $type != "" }

  # Special case:  No props for a group.
  if {$type == "GROUP"} {
      return ""
  }

  if { $default } {
    set old_prop_list $GCELL($type,proplist)
  } else {
    set old_prop_list [_gcell_args_to_prop_list $type $existing_args]
  }

  # Remove the prop_menu stuff, return just name and value.
  set prop_list ""
  foreach prop $old_prop_list {
    setl {name value} $prop
    if { $name != "" } {
      lappend prop_list [list $name $value]
    }
  }
  return $prop_list
}



proc _gcell_remake_from_props {inst_name prop_list} -desc {
  Set props for gcell to prop_list
} -doc {
  Gcell is modified according to the props in prop_list.
  Other existing props in the gcell are unmodified.

  If the gcell has been hand-edited, which turned it into a group,
  then this function sets the properties and turns it back
  into a normal gcell again.
} {

  sel_cell2 $inst_name

  # Fail if sel_cell2 failed.
  set cells [sel_what_l cells]
  if {[llength $cells] != 1} { return 0 }
  struct max_cell cell [lindex $cells 0]

  # get gcell type, current properties
  setl {type existing_args} [_gcell_info $inst_name]
  assert { $type != "" }

  # Special case:  No props for a group.
  if {$type == "GROUP"} { return 0 }

  # need to know what orientation this edit cell is in
  if {[lay_rootcell] != [lay_editcell]} {
    # in edit in place (gack!).  Push into this cell so not edit in place.
    set in_place 1

    # select this cell
    global EDIT
    sel_cell [lindex [lindex $EDIT(stack) 0] 0]
    # Need the override in case this is a GROUP gcell.
    edit_push override

    # select this here
    sel_cell $inst_name

    # This gets the cell info in root-cell coords.
    # Defines cell with fields:id def x1 y1 x2 y2 path expansion transform
    struct max_cell cell [sel_what cells]

  } else {
    # not edit in place
    set in_place 0
  }



  if {1} {
    # New way

    #set old_bbox [db_bbox -cell ${cell.def}]

    # delete the old instance
    :delete

    setl {new_def new_id} [_make_gcell_internal $type "0 0" $prop_list]

    # call it the same name to preserve flylines
    :identify $inst_name

    selt_transform -cell_origin ${new_def} -transform ${cell.transform}
  } else {
    # old way

    # make the new one
    # The x, y coords are in the coord system of the edit-cell.
    set orient [orientation ${cell.transform}]

    # unorient
    switch $orient {
      "r90" {
	:clockwise 270
      }
      "r180" {
	:clockwise 180
      }
      "r270" {
	:clockwise 90
      }
      "fx" {
	:sideways
      }
      "fy" {
	:upsidedown
      }
      "fx_r90" {
	:clockwise 270
	:sideways
      }
      "fy_r90" {
	:clockwise 270
	:upsidedown
      }
    }


    # Get gcell origin in its own cell coord system.
  #  setl {lx ly} [_gcell_get_origin ${inst_name}]

    edit_push override
    setl {lx ly} [lay_bbox]
    edit_pop

    # origin passed to _make_gcell_internal is passed to :getcell
    # which requires the origin in editcell coordinates,
    # not root cell coordinates.
    # Origin is difference of editcell and local coords
  #  set x [expr ${cell_in_edit.x1} - $lx]
  #  set y [expr ${cell_in_edit.y1} - $ly]

    set x [expr ${cell.x1} - $lx]
    set y [expr ${cell.y1} - $ly]

    # delete the old instance
    :delete
    _make_gcell_internal $type "$x $y" $prop_list

    # call it the same name to preserve flylines
    :identify ${cell.id}

    # reorient according to original orientation
    switch $orient {
      "r90" {
	:clockwise
      }
      "r180" {
	:clockwise 180
      }
      "r270" {
	:clockwise 270
      }
      "fx" {
	:sideways
      }
      "fy" {
	:upsidedown
      }
      "fx_r90" {
	:sideways
	:clockwise
      }
      "fy_r90" {
	:upsidedown
	:clockwise
      }
    }
  }

  if {$in_place} {
    # return to edit in place
    edit_pop

    sel_cell2 $inst_name
  }
}


proc edit_gcell_props {{inst_name ""} args} -desc {
  edit the selected gcell's properties and remake it or named.
} -doc {
    Return 0 on success, non-zero on failure.
} {
  global GCELL

  set gcell_list ""

  if {$inst_name == ""} {
    # Make a list of all selected gcells, excluding groups
    foreach cell_info [sel_what_l cells] {
      struct max_cell cell $cell_info
      if {[is_gcell ${cell.def} nogroup]} {
	lappend gcell_list $cell_info
	set inst_name ${cell.id}
      }
    }

    if { [llength $gcell_list] == 0} {
      msg "Aborting, must select a gcell.\n"
      return 1
    }

    if { [llength $gcell_list] > 1} {
      # Multiple gcells selected.
      # Ask if user wants to regenerate them all.
      set ret [tk_dialog .gcell_dialog "Gcell Properties" \
	  "There multiple gcells selected. \
	  Do you want to recreate all selected gcells using current gcell\
	  generators and existing gcell properties?" \
	      {} 1 OK Cancel]
      if { $ret != 0 } { return }

      # Rebuild all selected gcells.
      foreach cell_info $gcell_list {
	struct max_cell cell $cell_info
	set type [gcell_typename ${cell.def}]
	set existing_args [_gcell_args ${cell.def}]
	set old_prop_list \
	  [_gcell_args_to_prop_list $type $existing_args]
	_gcell_remake_from_props ${cell.id} $old_prop_list
      }
      return
    }
  }

  # select this one just in case there were multiple things selected before
  sel_cell2 $inst_name

  # This gets the cell info in root-cell coords.
  # Defines cell with fields:id def x1 y1 x2 y2 path expansion transform
  struct max_cell cell [sel_what cells]

  # This gets the cell info in edit-cell coords.
  # Edit-cell and root-cell are different if we are editing in place.
#  struct max_cell cell_in_edit [dbt_find_cell ${cell.id}]

  # If we are editing-in-place, we need to get the transform in
  # edit cell coords, not root cell coords.
  # Update: no, we need root cell coords.
  # When you :getcell, it reads it in upright in the root cell,
  # even if the edit-in-place cell is rotated, and it places it
  # pre-rotated in the edit-cell so that it looks upright.  Very wierd.
  #if { ${cell_in_edit.transform} == "" } {
  #  max_error "internal error: can not find cell ${cell.id}"
  #  return 1
  #}

  # get its type, properties
  setl {type existing_args} [_gcell_info ${cell.id}]

  #regsub -all "!" [string trimleft ${cell.def} \#] " " list
  #set type [lindex $list 0]
  #set existing_args [lrange $list 1 end]

  # Special case:  Editing properties on a group blows it away,
  # so dont do it.
  if {$type == "GROUP"} {
      # If no args, it is interactive, so do the popup.
      # Otherwise, just fail quietly.
      if { $args == "" } {
	set ret [tk_dialog .gcell_dialog "Warning" \
	  "There are no properties for a group." \
	      {} 0 OK]
      }
      return 1
  }

  if {$args != ""} {
    set prop_list [_gcell_args_to_prop_list $type \
		       [concat $existing_args $args]]
  } else {

    if {[set modtype [_gcell_has_been_edited ${cell.def}]] != ""} {

      set ret [tk_dialog .gcell_dialog "Warning" \
	"This gcell has been ${modtype}.  Do you want to regenerate it from its properties?" \
	{} 1 Yes No]

      if {$ret != 0} { return 1 }
    }

    set old_prop_list \
      [_gcell_args_to_prop_list $type $existing_args]

    # prop_list popup
    set prop_list [_gcell_prop_list_popup $type $old_prop_list]
    if {$prop_list == ""} {
      # user hit cancel
      return 1
    }
    if {$prop_list == $old_prop_list} {
      # user didn't change anything
      # We need to continue so we can regenerate the gcell anyway,
      # using the current tech file, etc.
    }
  }

  _gcell_remake_from_props $inst_name $prop_list

  return 0
}

proc _gcell_bbox {id} -desc {
    Get the bbox for the given cell id.  Assume it is selected.
} {
    return [lindex [_gcell_info $id] 2]
}


proc gcell_typename {def_name} -desc {
  return the gcell type (eg: "fet") from the cell def name.
} {
  regsub -all "!.*" [string trimleft $def_name \#] "" type
  return $type
}

proc _gcell_args {def_name} -desc {
  return the gcell options (eg: "-foo blah") from the cell def name.
} {
    regsub -all "!" [string trimleft $def_name \#] " " list
    return [lrange $list 1 end]
}

proc _gcell_info {id} -desc {
    Return info on the gcell.
} -doc {
    Assumes the gcell is selected.
    Returns a list:
    element 0 is the gcell type.
    element 1 is the list of gcell args for this specific gcell
	in the form -keyword value.
    element 2 is the gcell bbox in coord system of current root cell,
	which may NOT be the current edit cell if editing in place.
} {
    foreach cell_list [sel_what_l cells] {
        # Defines cell with fields:id def x1 y1 x2 y2 path expansion transform
	struct max_cell cell $cell_list
	if { ${cell.id} == $id } {
	    # get its type, properties
	    regsub -all "!" [string trimleft ${cell.def} \#] " " list
	    return [list \
		[lindex $list 0] \
		[lrange $list 1 end] \
	    	[list ${cell.x1} ${cell.y1} ${cell.x2} ${cell.y2}] \
		]
	}
    }
}

proc _gcell_stretch_show_cursor {} -desc {
  Just modify the cursor as mouse is moved, until user presses a button.
} {
  global _GCELL_
  if { $_GCELL_(drag_started) } { return }
  setl {x y} [layt_point exact]
  set _GCELL_(edit_side) [box_get_nearest_side $x $y $_GCELL_(edit_bbox)]
  if { $_GCELL_(edit_side) == "0 0 0 0" } {
      # Not near any side of the gcell bbox
      cursor_mode 1
  } else {
    # We are going to resize the gcell.  Change cursor.
    box_set_move_cursor $_GCELL_(edit_side)
  }
}

proc _gcell_stretch_mode_define {} {
    mode_def gcell_stretch _gcell_stretch_gate_keeper {BUT-2 stretches gcell edges, if supported by gcell}

    mode_bind -cmd 0 gcell_stretch \
      <Any-Motion> _gcell_stretch_show_cursor
    mode_bind -cmd 0 \
	gcell_stretch <Any-B1-ButtonRelease> "_gcell_stretch_end"
    mode_bind -cmd 0 \
	gcell_stretch <Any-B2-ButtonRelease> "_gcell_stretch_end"
    mode_bind -cmd 0 \
	-desc "change gcell bbox" \
	gcell_stretch <Any-B1-Motion> "_gcell_stretch_drag"
    mode_bind -cmd 0 \
	-desc "change gcell bbox" \
	gcell_stretch <Any-B2-Motion> "_gcell_stretch_drag"
    mode_bind -cmd 0 \
	-desc "change gcell bbox" \
	gcell_stretch <Any-Button-1> "_gcell_stretch_start 1"
    mode_bind -cmd 0 \
	-desc "change gcell bbox" \
	gcell_stretch <Any-Button-2> "_gcell_stretch_start 2"
}

proc _gcell_stretch_end {} -desc {
    End interactive gcell drag edit; bound to B2 release
} {
    global _GCELL_
    # Lay the visible box over the final gcell bbox.
    eval layt_box exact  [_gcell_bbox $_GCELL_(edit_id)]
    # And pop out of gcell_stretch mode.
    mode_pop
}

proc _gcell_stretch_start {but} -desc {
    Start interactive gcell drag edit; bound to B2.
} {
  global GCELL _GCELL_
  set _GCELL_(drag_started) 1
  setl {x y} [layt_point exact]

  # Start by getting the bbox of the cell.
  # Redundant: already done in gate keeper.
  set _GCELL_(edit_bbox) [_gcell_bbox $_GCELL_(edit_id)]
  eval layt_box exact $_GCELL_(edit_bbox)

  # Figure out which side to resize
  set _GCELL_(edit_side) [box_get_nearest_side $x $y $_GCELL_(edit_bbox)]

  if { $_GCELL_(edit_side) == "0 0 0 0" } {
      # Not near any side of the gcell bbox
      # It would be nicer to just pick the closest side, but...
      if { $but == 2 } {
	# Move the gcell.
	mode_pop  ;# Out of gcell mode.
	move_something_mode_enter
      }
  } else {
    # We are going to resize the gcell.  Change cursor.
    box_set_move_cursor $_GCELL_(edit_side)
  }
}

proc _gcell_stretch_drag {} -desc {
  resize the gcell with the cursor; bound to B2 motion.
} {
  global GCELL _GCELL_

  pan_auto _gcell_stretch_drag  

  setl {x y} [layt_point user]
  if {$x == "" || $y == ""} {
    # off screen
    return
  }

  # If not near a gcell border, do nothing.  This code probably not used.
  if { $_GCELL_(edit_side) == "0 0 0 0" } { return }

  # Original bbox.
  setl {x1 y1 x2 y2} $_GCELL_(edit_bbox)

  # compute the new box: nx1 ny1 nx2 ny2
  setl {tx1 ty1 tx2 ty2} $_GCELL_(edit_side)
  set nx1 [expr $x1 + $tx1*($x - $x1)]
  set ny1 [expr $y1 + $ty1*($y - $y1)]
  set nx2 [expr $x2 + $tx2*($x - $x2)]
  set ny2 [expr $y2 + $ty2*($y - $y2)]

  if { $nx1 > $nx2 || $ny1 > $ny2 } {
    # User has dragged box through zero and out the other side,
    # so the box size is negative, conceptually.
    # Dont allow this; set that dimension to zero.
    if { $nx1 > $x2 } { set nx1 $x2 }
    if { $nx2 < $x1 } { set nx2 $x1 }
    if { $ny1 > $y2 } { set ny1 $y2 }
    if { $ny2 < $y1 } { set ny2 $y1 }
  }

  # Let the user see it
  layt_box exact $nx1 $ny1 $nx2 $ny2

  setl {type old_args old_bbox} [_gcell_info $_GCELL_(edit_id)]

  # Get new prop-list based on new bbox.
  #set old_prop_list [_gcell_args_to_prop_list $type $old_args]
  #set newprops [gcell_make_props_${type} $old_prop_list "$nx1 $ny1 $nx2 $ny2"]

  # If the gcell is rotated, we have to make sure to hand it
  # the new bbox in its own coord system.
  struct max_cell c [sel_what cells]
  setl {ta tb tc td te tf} ${c.transform}
  set gx2 [expr abs($ta * ($nx2 - $nx1) + $tb * ($ny2 - $ny1))]
  set gy2 [expr abs($td * ($nx2 - $nx1) + $te * ($ny2 - $ny1))]

  # Stretch the gcell.
  # Pass the bbox in _BBOX_ and the side being moved in _STRETCH_.
  set newargs [list \
    -_BBOX_ "0 0 $gx2 $gy2" \
    -_STRETCH_ [box_transform_to_compass $_GCELL_(edit_side)] ]

  # Extra curly braces around edit_id are required in case id contains $,
  # it will get expanded twice by eval.
  set ret [eval edit_gcell_props {$_GCELL_(edit_id)} $newargs]
  if { $ret != 0 } {
    # Error.  Probably had -_version property.
    mode_pop
  }

  # See if the gcell resized itself.
  set bbox [_gcell_bbox $_GCELL_(edit_id)]
  if { $bbox != $_GCELL_(edit_bbox) } {
      # Move modified gcell
      setl {cx1 cy1 cx2 cy2} $bbox               ;# Current coords
      switch $_GCELL_(edit_side) {
      "0 1 0 0" { :move S [expr $cy2 - $y2] ;# Top side stationary
	:move W [expr $cx1 - $x1]  ;# And also anchor left side
	}
      "0 0 0 1" { :move S [expr $cy1 - $y1] ;# Bottom side stationary
	:move W [expr $cx1 - $x1]  ;# And also anchor left side
        }
      "1 0 0 0" { :move W [expr $cx2 - $x2] ;# Right side stationary
	:move S [expr $cy1 - $y1]  ;# And also anchor bottom side
      }
      "0 0 1 0" { :move W [expr $cx1 - $x1] ;# Left side stationary
	:move S [expr $cy1 - $y1]  ;# And also anchor bottom side
	}
      "1 1 0 0" {
	# Moving lower left corner, so upper right corner stationary, etc.
	:move S [expr $cy2 - $y2]; :move W [expr $cx2 - $x2]
      }
      "0 1 1 0" { :move S [expr $cy2 - $y2]; :move W [expr $cx1 - $x1] }
      "1 0 0 1" { :move S [expr $cy1 - $y1]; :move W [expr $cx2 - $x2] }
      "0 0 1 1" { :move S [expr $cy1 - $y1]; :move W [expr $cx1 - $x1] }
      }
  }
  # Make visible box track the cursor.
  # :move moved the box, so move it back.
  layt_box exact $nx1 $ny1 $nx2 $ny2

  box_msg_update
}

proc _gcell_stretch_gate_keeper {event} -desc {
  called whenever gcell_stretch mode is entered/exited
} {
    global _GCELL_ mode_abort

    if {$event == "PUSH_TO" } {
	# Make sure we have a gcell selected.
	set cells [sel_what_l cells]
	# Must be just one cell selected.
	setl {inst_name cell_name rx ry} [lindex $cells 0]
	if { [llength $cells] != 1 || ! [is_gcell $cell_name] } {
	    max_error "gcell stretch: error: need one gcell selected to edit"
	    mode_pop
	    return
	}
	if {[set modtype [_gcell_has_been_edited $cell_name]] != ""} {

	  set ret [tk_dialog .gcell_dialog "Warning" \
	    "This gcell has been ${modtype}.  Do you want to regenerate it?" \
	    {} 1 Yes No]

	  if {$ret != 0} {
	    mode_pop
	    return
	  }
	}

	set _GCELL_(edit_id) $inst_name
	set _GCELL_(edit_bbox) [_gcell_bbox $_GCELL_(edit_id)]
	set _GCELL_(edit_side) "0 0 0 0"
	set _GCELL_(drag_started) 0

	pan_enable
    } elseif {$event == "POP_FROM" } {
	pan_disable
	if { $mode_abort } {
	    # Restore gcell to original size.
	    undo_to_delim
	    undo_flush_redo
	    msg "aborting gcell edit!\n"
	}
	i_cmd_between
    }
}

proc gcell_stretch_mode_enter {{inst_name ""}} -desc {
  edit the specified or selected gcell bbox with the mouse.
} {
  global GCELL

  if {$inst_name == ""} {
    # get path name of first selected instance
    set done 0
    foreach cell_list [sel_what_l cells] {
      setl {inst_name cell_name rx ry} $cell_list
      if {[is_gcell $cell_name]} {
	set done 1
	break
      }
    }

    if {!$done} {
      max_error "gcell stretch: Aborting, must select a gcell."
      return
    }
  }

  # select this one just in case there were multiple things selected before
  sel_cell2 $inst_name
  set cell [sel_what cells]
  if { $cell == "" } {
    msg "Aborting, cant select $inst_name\n"
    return
  }
  struct max_cell c $cell

  # get the type out of the name
  set type [gcell_typename $cell_name]

  # See if the gcell knows what to do with a bbox.
  set scope gcell_$GCELL($type,basetype)
  if {[info commands ::${scope}::gcell_make_props_${type}] != ""} {
    # old function name
  } elseif {[info commands ::${scope}::gcell_make_props] != ""} {
    # new function name
  } else {
    max_error "gcell stretch: error: This cell can not be edited this way"
    return
  }

  mode_push gcell_stretch
}


proc UNUSED_gcell_modify {} -desc {
  Process interactive request to edit/modify gcell.
} -doc {
  Bring up prop_menu to ask the user what they really
  want to do, then do it.
} {
  global GCELL

  set cells [sel_what_l cells]
  set cnt [llength $cells]
  if { $cnt == 0 } {
    max_error "gcell_modify: error: no gcell selected"
    return ""
  }
  if { $cnt == 0 } {
    max_error "gcell_modify: error: must select just one gcell"
    return ""
  }
  struct max_cell c [lindex $cells 0]
  setl {type args bbox} [_gcell_info ${c.id}]

  set helpmsg {A gcell is a cell whose physical geometry is generated\
  automatically from by a generator program from a list of properties.
If you edit the gcell properties, the gcell's physical geometry will\
be updated to match the new properties.
Some gcells allow you to stretch the gcell by grabbing the bounding\
box with the mouse.  If you stretch the gcell, its properties will\
be modified to force the gcell geometry to match the new bounding box.
If you turn the gcell into a new group, you can edit its contents,\
as though it were a normal group. \
If you do this, and you then later attempt to edit the properties\
of the gcell, max will tell you that you edited the cell, and ask\
whether you want to regenerate it from its properties. \
If you do, you will lose your editing changes.}

  set all_prop_list [_gcell_args_to_prop_list -all $type $args]

  # If it does not have an _edit prop, it has never been edited
  # before.  See what the user really wants to do.
  if {[get_assoc _edit $all_prop_list] == ""} {
    set action "props"
    set prop_list ""
    lappend prop_list [list "This is a $type gcell (generated cell.)" "" -label]
    lappend prop_list [list "Action to take:" action \
      -radio { \
       {Edit gcell properties} \
       {Stretch gcell}\
       {Turn gcell into a new group and edit it} \
       } -values {props stretch edit}]
    lappend prop_list [list "" "" -help $helpmsg]

    set ret [prop_menu2 -title "Gcell Warning" \
	-buttons "OK=1 Cancel=0=default" $prop_list]
    if { $ret == 0 } { return "" }

    switch $action {
      edit {
	return [gcell_edit_new]
      }
      props {
	edit_gcell_props ${c.id}
	return ""
      }
      stretch {
	gcell_stretch_mode_enter
	return ""
      }
    }
  }
}


proc UNUSED_gcell_uniquify_groups {} {

  save_selection __EDIT_GCELL_TMP__
  set cell_list [sel_what_l cells]
  set old_box [layt_box exact]

  set new_groups ""
  set old_groups ""

  # Uniquify each group gcell.
  foreach cell_info $cell_list {
    struct max_cell c $cell_info
    if {! [is_gcell ${c.def} group] } { continue }

    # This is a group gcell.
    lappend old_groups ${c.id}
    sel_cell2 ${c.id}
    gcell_edit_new 1
    struct max_cell new [sel_what cells]

    lappend new_groups ${new.id}
  }

  if { $new_groups == "" } {
    # No groups found.  Just return.
    eval layt_box exact $old_box
    return
  }

  # Now restore the selection.
  # We must remove the old groups from the selection and substitute
  # the new.  To do this, remove the old groups from __EDIT_GCELL_TMP__;
  # restore the selection, then add the new cells back in.

  # Delete this cell from the former selection.
  edit_push_direct __EDIT_GCELL_TMP__
  foreach id $old_groups {
    sel_cell $id
    :delete
  }
  edit_pop_direct
  restore_selection __EDIT_GCELL_TMP__

  # Select the newly uniquified groups.
  foreach id $new_groups {
    sel_cell2 -more $id
  }
  eval layt_box exact $old_box
}


proc gcell_edit_new {{f_new_id 0}} -desc {
  Create and return a new gcell def that can be edited.
} -doc {
  Replaces selected gcell.

  NOTE: This code was previously used to edit fets and vias as
  well as groups.  It works, and creates a group
  that is labeled, eg "fet", and can be turned back into a fet
  just by selecting the group and typing "p".  But we decided
  to take out this feature and make the user flatten the gcell
  if they want to edit it.   This was deemed too confusing.
  Now it is used only on groups.

  Very similar to group_objects, but the contents are taken
  from a gcell, and the typename and properties of the
  original cell are preserved except for the added -_edit arg.
} {
  global GCELL

  set cells [sel_what_l cells]
  set cnt [llength $cells]
  if { $cnt == 0 } {
    error "no gcell selected"
  }

  struct max_cell c [lindex $cells 0]

  setl {type args bbox} [_gcell_info ${c.id}]

  # Make uniq id for the new cell
  setl {u1 u2} [db_vstamp -new] 
  set uniqid ${u1}x${u2}

  set prop_list [_gcell_args_to_prop_list $type $args]
  # The old -_version and -_edit, if any, have already been removed.
  # Add new _edit prop, which will give this particular instance
  # a cell def name that is entirely unique.
  lappend prop_list [list _edit $uniqid]

  # We have to make a new gcell whose contents are the old.
  # Since max thinks it is in charge of making gcells, we have
  # to use some subterfuge.  Save the contents we want to
  # go into the gcell in a temorary cell.  When we make
  # the next gcell, that contents will be used instead
  # of calling any generator.
  set tmp_cell __NEW_GCELL$uniqid

  # Make this special internal cell
  db_cell_new -no_undo -internal $tmp_cell

  # copy selected cell to the tmp_cell.
  #db_instance -cell $tmp_cell ${c.def} 0 0
  db_cell_copy -source ${c.def} $tmp_cell

  # Delete the selected cell from the main window.
  sel_cell2 ${c.id}
  :delete

  # Make tmp cell into a gcell.  Its type remains the same, so if the
  # user later tries to regenerate it from the generator, they can.
  # Only the -_edit prop says that its been edited.
  setl {cell_def cell_id} [_make_gcell_internal $type "0 0" $prop_list]

  if {! $f_new_id} {
    # Keep id the same.
    :identify  ${c.id}
  }

  # Move new gcell to exact location as previous cell.
  selt_transform -cell_origin ${cell_def} -transform ${c.transform}

  # Flatten the gcell that we just copied.
  # NOTE: I originally had this flatten above the make_gcell_internal,
  # which caused a max crash when you later edited the new cell
  # and tried to undo anything.  I surmise that when max does a
  # db_cell_copy of a cell with -no_undo, the undo buffer of
  # the new cell is not initialized properly.  

  #edit_push "" -cell_def $cell_def
  ## There is actually only one, despite the foreach.
  #foreach fcell [db_search_l cells] {}
  #  struct max_cell fc $fcell
  #  sel_cell ${fc.id}
  #  flatten_cells -save_labels
  #{}
  #edit_pop

  return $cell_def
}

proc gcell_group_create {} -desc {
  Create a new group cell, return its def name.
} {
  # Create a unique number and cell name for this group.
  setl {u1 u2} [db_vstamp -new]
  set uniqid ${u1}x${u2}
  set cell_name __NEW_GCELL$uniqid

  # Make this special empty internal cell
  db_cell_new -no_undo -internal $cell_name

  # This is the prop_list for this particular gcell.
  set prop_list [list [list _edit $uniqid]]

  # Make it into a gcell.
  # gcell_load does the rest.
  setl {newdef newid} [_make_gcell_internal GROUP "0 0" $prop_list]

  return [list $newdef $newid]
}


proc gcell_group_objects {} -desc {
  Implements the "Group Objects" interactive command.
} -doc {
  Replaces the selection with a gcell whose contents are the selection.
  New gcell is labeled "GROUP"
  Nothing to do with max paint groups.
} {
  global GCELL

  set cell_list [sel_what_l cells -edit_only junk1]
  set cell_cnt  [llength $cell_list]
  set label_cnt [llength [sel_what_l labels -edit_only junk2]]
  set layer_cnt [llength [sel_what_l types]]
  set poly_cnt  [llength [sel_what_l polygons]]

  if { $cell_cnt==0 && $layer_cnt==0 && $poly_cnt==0 && $label_cnt==0 } {
    msg -warn "Error: Must first select objects to be grouped."
    return
  }

  if { $junk1 || $junk2 } {
    # Should check paint too, but I dont want to do a sel_what paint
    # just to get the -edit_only flag.
    msg -warn "Error: There are selected objects that are not in the edit cell \
      - only objects in the current edit cell can be grouped."
    return
  }

  # Is a single group selected?
  if { $layer_cnt==0 && $label_cnt==0 && $poly_cnt==0 } {
    if { [llength $cell_list] == 1 } {
      struct max_cell c [lindex $cell_list 0]
      if { [is_gcell ${c.def}] && [gcell_typename ${c.def}] == "GROUP" } {
	set ret [tk_dialog .gcell_dialog "Warning" \
	  "The selection is a group. Do you want to ungroup it?" \
	      {} 0 Yes No]
	if { $ret == 0 } {
	  gcell_ungroup_objects
	}
	return
      }
    }
  }

  # Create a unique number and cell name for this group.
  setl {u1 u2} [db_vstamp -new]
  set uniqid ${u1}x${u2}
  set cell_name __NEW_GCELL$uniqid

  # Make this special internal cell
  db_cell_new -no_undo -internal $cell_name

  # copy selection in here
  db_cell_copy -source __SELECT__ $cell_name

  # Delete the selected stuff from the main window.
  :delete

  # This is the prop_list for this particular gcell.
  set prop_list [list [list _edit $uniqid]]

  # Make it into a gcell.
  # gcell_load does the rest.
  setl {def id} [_make_gcell_internal GROUP "0 0" $prop_list]

  # Give it an attractive name, instead of "GROUP-_editblahblah"
  # This is not necessary.
  global GCELL_GROUP_ID
  set GCELL_GROUP_ID [use_first GCELL_GROUP_ID '1]
  while {[catch {:identify GROUP$GCELL_GROUP_ID}]} {
    incr GCELL_GROUP_ID
  }

  # Fix flylines that used to go to anything in the new cell.
  dbt_flyline -push $id -push_def $def
}

proc gcell_ungroup_objects {} -desc {
  Ungroup any cell groups in the selection.
} -doc {
  Nothing to do with max paint groups.
} {

  set cells [sel_what_l cells -edit_only junk1]
  if { $junk1 } {
    max_error "ungroup: error: There are selected objects that are not in the edit cell \
      - only objects in the current edit cell can be ungrouped."
    return
  }

  set fnd 0
  foreach cellball $cells {
    struct max_cell c $cellball
    if { [is_gcell ${c.def}] && [gcell_typename ${c.def}] == "GROUP" } {
      sel_cell2 ${c.id}
      # Preserve labels; do not flatten them.
      flatten_cells -save_labels -cellids preserve
      set fnd 1
    }
  }
  if { ! $fnd } {
    warning "No group selected to ungroup!"
  }
}
