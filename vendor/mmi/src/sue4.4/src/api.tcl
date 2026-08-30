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


# Application programmer interface (api) routines.


# returns a list of ids of icons in the current schematic

proc api_instances {{type ""}} -type user -desc {

Returns a list of ids of all icons in the current schematic, or if the
"selected" option is used, returns a list of selected objects.

For example:

        sue> api_instances
        1 5 9 13 17 21 25 36 47 56 65 76
        sue> api_instances selected
        1 9 25 36
} {

  global cur_c

  # only allow selected
  if {$type != "selected"} {
    return [$cur_c find withtag origin]
  } else {
    return [$cur_c find withtag selected&origin]
  }
}


proc api_change_cell_path {path} -type user -desc {

Changes the path of the current cell.  Subsequent saves and all
associated files will go to this new path.

If the path is invalid (i.e. not a proper directory), the current
cell's path is not modified and the function returns 0.  Else returns 1.

For example, to write the netlist of the current cell to /tmp, do the
following:

        sue> set save_path [get_assoc filename [api_cell_info]]
        /home/user/dpc_tut/alu8/alu8.sue
        sue> api_change_cell_path /tmp
        Changing path of cell "alu8" to /tmp/
        sue> api_netlist
        ...
        sue> api_change_cell_path $save_path
        Changing path of cell "alu8" to /home/user/dpc_tut/alu8/

Sets the modified flag since the cell hasn't been saved at the new
pathname.

} {

  return [change_path $path]
}


# Change the values of the properties for all of the given ids.

proc api_change_prop {ids prop value} -type user -desc {

Changes the icons with ids in <id_list> in the current schematic
which have the property <property> to the value <value>.  Note
that any changed instances are given new ids.  This command will set
the modified flag on the cell if anything is changed.  These changes
can also be undone.

For example:

        sue> api_change_prop "1252 1265 1275" dpc newbit
        Changed 3 instances.

Will change the "dpc" property on the icons with the above ids to the
string "newbit".

Sets the modifed flag and is undoable.

} {

  global cur_s PROC

  integer_scale

  # for undo
  set PROC ""
  write_instances selected 1 undo
  set save_proc $PROC

  set new_ids ""
  foreach id $ids {
    upvar #0 ${cur_s}_inst${id} i_data
    if {[info exists i_data(_$prop)]} {
      set i_data(_$prop) "$value"
      lappend new_ids [remake $id $id "" no_scale]
    }
  }

  setup_undo $new_ids $save_proc

  unscale

  puts "Changed [llength $new_ids] instances."
}


# returns an associative list of properties and values for icon
# with the given id.

proc api_instance_data {id {prop ""}} -type user -desc {

Returns an associative list of properties and values for the icon with
the given id.  Also, returns the netlist name if already netlisted.
User-defined properties are prefixed with a "_".

USAGE: api_instance_data id [<property>]

If an optional property is supplied, only returns the value for that property.
If the property doesn't exist, errors.

For example:

        sue> api_instance_data 25
        {_model p} {_M {}} {_name {}} {orient R0} {_W 2.4} {type pmos}
        {_L lp_min} {origin {470 450}} {bbox {410 410 470 490}}
        {generator 0} {netlist_name {}}
        sue> get_assoc origin [api_instance_data 25]
        470 450
        sue> api_instance_data 25 origin
        470 450

} {

  global cur_s cur_c scale

  if {![is_tagged $id origin]} {
    # not an icon
    return ""
  }

  if {$prop != ""} {
    # only return value corresponding to this property

    switch $prop {
      bbox {
	# scale this instance only and then unscale it
	if {$scale != 10} {
	  set scalefactor [expr 10.0 / $scale]
	  $cur_c scale inst$id 0 0 $scalefactor $scalefactor
	}

	$cur_c addtag tmpapi withtag inst$id
	$cur_c dtag scaletext tmpapi
	setl {x1 y1 x2 y2} [round_list [$cur_c bbox tmpapi]]
	$cur_c dtag tmpapi
	# hack for bbox
	set bbox [list [expr $x1 + 2] [expr $y1 + 2] \
		      [expr $x2 - 2] [expr $y2 - 2]]

	# scale this guy back
	if {$scale != 10} {
	  set scalefactor [expr $scale / 10.0]
	  $cur_c scale inst$id 0 0 $scalefactor $scalefactor
	}
	
	return $bbox
      }

      origin {
	return [round_list [scale_list [lrange [$cur_c coords $id] 0 1] \
				[expr 10.0 / $scale]]]
      }

      generator {
	upvar #0 ${cur_s}_inst${id} i_data
	return [is_generator $i_data(type)]
      }

      netlist_name {
	upvar #0 TERMS_$cur_s TERMS

	if {[info exists TERMS($id)]} {
	  # instance
	  return $TERMS($id)
	}

	# could be an I/O, global, or name_net
	set terms [$cur_c find withtag inst[find_origin $id]&term]
	if {[llength $terms] == 1} {
	  # probably an I/O or global (most instances have more than one term)
	  return [use_first TERMS($terms)]
	}
      }
    }

    upvar #0 ${cur_s}_inst${id} i_data

    if {[info exists i_data($prop)]} {
      return $i_data($prop)
    }
    
    # bad property
    return -code error "Error: Instance \#$id does not have the property \"$prop\"."

  } else {
    # return assoc list of all values

    upvar #0 ${cur_s}_inst${id} i_data

    set list ""
    foreach prop [array names i_data] {
      lappend list [list $prop $i_data($prop)]
    }

    # scale this instance only and then unscale it
    if {$scale != 10} {
      set scalefactor [expr 10.0 / $scale]
      $cur_c scale inst$id 0 0 $scalefactor $scalefactor
    }

    # add origin and bbox
    lappend list [list origin [round_list [lrange [$cur_c coords $id] 0 1]]]

    $cur_c addtag tmpapi withtag inst$id
    $cur_c dtag scaletext tmpapi
    setl {x1 y1 x2 y2} [round_list [$cur_c bbox tmpapi]]
    $cur_c dtag tmpapi
    # hack for bbox
    lappend list [list bbox [list [expr $x1 + 2] [expr $y1 + 2] \
				 [expr $x2 - 2] [expr $y2 - 2]]]

    # scale this guy back
    if {$scale != 10} {
      set scalefactor [expr $scale / 10.0]
      $cur_c scale inst$id 0 0 $scalefactor $scalefactor
    }

    lappend list [list generator [is_generator $i_data(type)]]

    upvar #0 TERMS_$cur_s TERMS
    if {[info exists TERMS($id)]} {
      # instance
      lappend list [list netlist_name [use_first TERMS($id)]]

    } else {
      # could be an I/O, global, or name_net
      set terms [$cur_c find withtag inst[find_origin $id]&term]
      if {[llength $terms] == 1} {
	# probably an I/O or global (most instances have more than one term)
	lappend list [list netlist_name [use_first TERMS($terms)]]
      }
    }

    return $list
  }
}


# returns an associative properties for a instance type along with the
# default properties

proc api_instance_type_data {type {prop ""}} -type user -desc {

Returns an associative list of properties and values for the instance
parameters for the instance of the given type.  User-defined
properties are prefixed with a "_".  

USAGE: api_instance_type_data type [<property>]

If the optional property argument is given, then returns the value
for that property only.  If the property doesn't exist, errors.

For example:

        sue> api_instance_type_data inverter
        {defaults {{origin {0 0}} {orient R0} {name {}} {M {}} {WP 2}
        {LP lp_min} {WN 1} {LN ln_min}}} {creator inverter} {_name,choices {}}
        {_LN,choices {}} {prop_names {name M WP LP WN LN}} {gargs {}}
        {_M {$M}} {_LP,choices {}} {_M,default {}} {_WN,choices {}}
        {_verilog {assign $out = !($in)\;}} {generator inverter}
        {gdefaults {{demorgan 0 binary} {bubble_only 0 binary}}}
        {_WP,choices {}} {_name {$name}} {_LN {$LN}} {_name,default {}}
        {_LN,default ln_min} {_LP {$LP}} {_WN {$WN}} {_LP,default lp_min}
        {_WN,default 1} {_WP {$WP}} {_M,choices {}}
        {arglist {$name $M $WP $LP $WN $LN}} {_WP,default 2}

If you wanted to find the default value for the "LN" property of an
inverter, you could use the following expression:

        sue> get_assoc _LN,default [api_instance_type_data inverter]
        ln_min

or simply:

        sue> api_instance_type_data inverter _LN,default
        ln_min

} {

  global cur_c cur_s
  upvar #0 icon_$type g_data

  if {![info exists g_data(arglist)]} {
    if {[info_proc ICON_$type] != ""} {
      # hasn't been instantiated, instantiate and then toast
      catch "make $type" id
      # toast
      $cur_c delete inst$id
      upvar #0 ${cur_s}_inst$id i_data
      catch {unset i_data}
    } else {
      # doesn't exist
      return -code error "Error: No such instance type \"$type\"."
    }
  }

  if {$prop == ""} {
    # return the entire list
    set list ""
    foreach prop [array names g_data] {
      if {[string index $prop 0] == {$}} {
	continue
      }

      lappend list [list $prop $g_data($prop)]
    }

    return $list

  } else {
    # only return the specific property value

    if {[info exists g_data($prop)]} {
      return $g_data($prop)
    }

    return -code error "Error: Instance \"$type\" does not have the property \"$prop\"."
  }
}


# returns an associative list of terminals and an associative list
# of data for the given instance type

proc api_terminal_data {type} -type user -desc {

Returns an associative list of terminals with an associative list of
data for the given instance type.  Requires <type> already to be
instantiated someplace in SUE.

For example:

        sue> api_terminal_data pmos
        {d {{type inout} {origin {0 40}}}} {s {{type inout} {origin {0 -40}}}}
        {g {{type input} {origin {-60 0}}}}

This can be used in conjunction with api_orient_transform to get the
location of a port on an icon with a given orientation, for example:

        sue> api_orient_transform R0 [get_assoc origin [get_assoc g [api_terminal_data pmos]]]
        -60 0
        sue> api_orient_transform R90 [get_assoc origin [get_assoc g [api_terminal_data pmos]]]
        0 -60

} {

  global ICON_TERMS cur_s cur_c

  if {![info exists ICON_TERMS($type)]} {
    if {[info_proc ICON_$type] != ""} {
      # hasn't been instantiated, instantiate and then toast
      catch "make $type" id
      # toast
      $cur_c delete inst$id
      upvar #0 ${cur_s}_inst$id i_data
      catch {unset i_data}
    }

    if {![info exists ICON_TERMS($type)]} {
      # still didn't work
      return ""
    }
  }

  set list ""
  foreach term $ICON_TERMS($type) {
    set len [llength $term]
    set sublist ""
    set name ""
    for {set i 0} {$i < $len} {incr i 2} {
      set kind [lindex $term $i]
      set value [lindex $term [expr $i + 1]]
      if {$kind == "-name"} {
	# special case 
	set name $value
      } else {
	# add property
	lappend sublist [list [string trimleft $kind -] $value]
      }
    }
    lappend list [list $name $sublist]
  }

  return $list
}


# returns the net name of the terminal on the given instance id
# if no terminal is given, return the netlist name of the icon.

proc api_netlist_data {id {term ""}} -type user -desc {

With the optional <term> argument, returns the net name assigned to
the given terminal on the given instance id as computed by
api_generate_term_names.  You can get the terminal names for a given
instance type from the api_terminal_data command.  If the terminal
hasn't been assigned a net yet, the value "" is returned.  If the
given terminal is not associated with that id, the value 0 is
returned.

Without the optional <term> argument, the instance name assigned to
the instance of the given id during netlisting is returned.  This
name is unique across the schematic.  If the instance name has not
been assigned, a value of "" is returned.  Instance names are only
assigned during netlisting, not during api_generate_term_names.

For example:

        sue> api_netlist_data 134 in
        assert_low
        sue> api_netlist_data 134
        MMI_INVB_3
} {

  global cur_s cur_c

  if {![is_tagged $id origin]} {
    # not an icon
    return ""
  }

  upvar #0 TERMS_$cur_s TERMS

  if {$term == ""} {
    # return name of instance
    return [use_first TERMS($id)]
  }

  foreach term_id [$cur_c find withtag inst$id&term] {
    set tags [$cur_c gettags $term_id]
    set name_list [lindex $tags [lsearch $tags "name*"]]

    if {[lindex $name_list 3] == $term} {
      # found the named terminal
      return [use_first TERMS($term_id)]
    }
  }

  # can't find terminal
  return 0
}


# returns current schematic or icon

proc api_current_cell {} -type user -desc {

Returns the name of the current cell.  If that cell is an ICON, the name of the cell is ICON_<cell_name>.
} {

  global cur_s

  return $cur_s
}


# return information about cell

proc api_cell_info {{cell ""} {prop ""}} -type user -desc {

Returns information about the given cell or current cell in an
associative list.

If an optional property is supplied, only returns the value for that
property.  If the cell doesn't exist, returns "".  If invalid
property, returns "".

For example:

        sue> api_cell_info
        {filename /proj/foobar/adder.sue} {type S} {modified M} {generator 0} {read_only 0}

This cell is a schematic (type S) and is modified.  It is not a generator and
is not read-only.

        sue> api_cell_info "" type
        S
} {

  if {$cell == ""} {
    global cur_s
    set cell $cur_s
  }

  upvar #0 SUE_$cell data

  if {![info exists data(canvas)]} {
    # doesn't exist
    return ""
  }

  if {$prop != ""} {
    # only return to requested property value.
    if {![info exists data($prop)]} {
      # doesn't exist
      return ""
    } else {
      return $data($prop)
    }
  }
  
  return [list \
	      [list filename $data(filename)] \
	      [list type $data(type)] \
	      [list modified $data(modified)] \
	      [list generator $data(generator)] \
	      [list read_only $data(read_only)] \
	      ]
}


# prints

proc api_print_cell {} -type user -desc {

Prints the current cell.  This command is identical to clicking on
"print" in the "File" menu.
} {

  launch make_ps
}


proc api_new_cell {name {type S}} -type user -desc {

Creates a new schematic of icon cell and goes to it.

The given name should include the full pathname or will default to the
current working directory.

If type is "S" (the default) a new schematic view is created.  If type
is "I" a new icon view is created.

If the cell is already loaded, SUE will go to it.

Returns 1 if a new cell is created.

} {

  switch _$type {

    _S {
      if {[launch "make_new_schematic $name"] != ""} {
	return 1
      } else {
	return 0
      }
    }

    _I {
      # make an icon
      if {[launch "make_new_schematic $name I"] != ""} {
	add_properties_to_icon
	zoom_to_fit
	return 1
      } else {
	return 0
      }
    }

    default {
      return 0
    }
  }
}


proc api_cells {{type S}} -type user -desc {

Returns a list of the cells that are currently loaded in SUE.  This
list coresponds to the list of schematics in the schematics list box.

If an optional argument of "I" is added, then the icon views currently
loaded are returned.

} {

  global SUE

  set list ""

  foreach cell [array names SUE] {

    if {[is_icon $cell]} {
      if {$type == "I"} {
	lappend list $cell
      }

    } elseif {$type != "I"} {
      lappend list $cell
    }
  }

  return $list
}


# netlist

proc api_netlist {} -type user -desc {

Netlists from the current schematic using the current netlist type.
This command is identical to clicking on $NETLIST_TYPE netlist
in the "Sim" menu.

Note: To change the netlist type, you must change BOTH of the global
variables: NETLIST_TYPE and NETLIST_PROPS.  
} {

  launch netlist
}


proc api_change_simulation_mode {} -type user -desc {

To change the simulation mode once SUE has started, first change
NETLIST_TYPE and NETLIST_PROPS to the appropriate values.  Next
execute this command, which resets the "Sim" menu and flushes the
caches.

Returns 1 if successful, 0 if NETLIST_TYPE is not valid.

} {

  return [change_netlist_props_internal]
}


proc api_generate_term_names {} -type user -desc {

Generates terminal names for the current schematic.  This command is
identical to clicking on "generate term names" in the "Sim"
menu.  

This procedure does NOT generate netlisting instance names.  You must
netlist to get those.
} {

#  busy
  launch generate_term_names
#  ready

  return 1
}


# get objects on schematic/icon

proc api_get_data {id {prop ""}} -type user -desc {

Returns an associative list of data about the given id.  ids of type
instance, wire, line, arc, text, dot, and open are valid.  See the
command "api_types" for how to get the desired id.

USAGE: api_get_data id [<property>]

If an optional property is supplied, only returns the value for that
property.  If the property doesn't exist, errors.  Also, if the id
doesn't exist or is invalid, errors.

For example:

        sue> api_get_data 1123
        {type wire} {coords {330 70 380 70}} {net net_13}
        sue> api_get_data 1123 type
        wire
        sue> api_get_data 576
        {type line} {coords {290 -180 290 -110 370 -110 370 -180 290 -180}}
        sue> api_get_data 299
        {type text} {origin {-40 280}} {text {-type user -name name}}
        {size standard} {anchor w} {rotate 0}
        sue> api_get_data 834
        {type arc} {bbox {40 -10 60 10}} {start 0} {extent 359}

Note that "api_get_data" is equivalent to "api_instance_data" if the
given id is an instance.

} {

  global cur_c cur_s scale

  if {[is_tagged $id origin]} {
    # instance, just call instance prop
    return [api_instance_data $id $prop]
  }

  if {$prop != ""} {
    # get individual property only

    if {[is_tagged $id wire]} {
      switch $prop {
	type {
	  return wire
	}

	net {
	  upvar #0 TERMS_$cur_s TERMS
	  return [use_first TERMS($id)]
	}

	coords {
	  return [round_list \
		      [scale_list [$cur_c coords $id] [expr 10.0 / $scale]]]
	}
      }

    } elseif {[is_tagged $id draw_item]} {
      if {[$cur_c type $id] == "line"} {
	switch $prop {
	  type {
	    return line
	  }

	  coords {
	    return [round_list \
			[scale_list [$cur_c coords $id] [expr 10.0 / $scale]]]
	  }
	}

      } elseif {[$cur_c type $id] == "arc"} {
	switch $prop {
	  type {
	    return arc
	  }

	  bbox {
	    return [round_list \
			[scale_list [$cur_c coords $id] [expr 10.0 / $scale]]]
	  }

	  start {
	    return [round_list [$cur_c itemcget $id -start]]
	  }

	  extent {
	    return [round_list [$cur_c itemcget $id -extent]]
	  }
	}

      } elseif {[$cur_c type $id] == "text"} {
	switch $prop {
	  type {
	    return text
	  }

	  origin {
	    return [round_list \
			[scale_list [$cur_c coords $id] [expr 10.0 / $scale]]]
	  }

	  text {
	    return [$cur_c itemcget $id -text]
	  }

	  size {
	    set tags [$cur_c gettags $id]
	    return [string range [lindex $tags [lsearch $tags size_*]] 5 end]
	  }

	  anchor {
	    return [$cur_c itemcget $id -anchor]
	  }

	  rotate {
	    return [$cur_c itemcget $id -rotate]
	  }
	}
      }
    
    } elseif {[is_tagged $id dot]} {
      switch $prop {
	type {
	  return dot
	}

	net {
	  return [display_local_net $id]
	}

	coords {
	  return [round_list \
		      [scale_list [center $id] [expr 10.0 / $scale]]]
	}
      }

    } elseif {[is_tagged $id open]} {
      switch $prop {
	type {
	  return open
	}

	net {
	  return [display_local_net $id]
	}

	coords {
	  return [round_list \
		      [scale_list [center $id] [expr 10.0 / $scale]]]
	}
      }

    } else {
      # unknown type
      return -code error "Error: Instance \#$id is invalid."
    }

    # unknown prop
    return -code error "Error: Instance \#$id does not have the property \"$prop\"."

  } else {
    # return list

    # scale this id only and then unscale it
    if {$scale != 10} {
      set scalefactor [expr 10.0 / $scale]
      $cur_c scale $id 0 0 $scalefactor $scalefactor
    }

    set return ""
    set dot_open 0

    if {[is_tagged $id wire]} {
      set return [list [list type wire] \
		      [list coords [round_list [$cur_c coords $id]]]]

      upvar #0 TERMS_$cur_s TERMS

      set net [use_first TERMS($id)]
      if {$net != ""} {
	# add net name for this wire if defined
	lappend return [list net $net]
      }

    } elseif {[is_tagged $id draw_item]} {
      if {[$cur_c type $id] == "line"} {
	set return [list [list type line] \
			[list coords [round_list [$cur_c coords $id]]]]

      } elseif {[$cur_c type $id] == "arc"} {
	set return [list [list type arc] \
			[list bbox [round_list [$cur_c coords $id]]] \
			[list start [round_list [$cur_c itemcget $id -start]]] \
			[list extent [round_list [$cur_c itemcget $id -extent]]] \
		       ]

      } elseif {[$cur_c type $id] == "text"} {
	set tags [$cur_c gettags $id]
	set return [list [list type text] \
			[list origin [round_list [$cur_c coords $id]]] \
			[list text [$cur_c itemcget $id -text]] \
			[list size [string range [lindex $tags [lsearch $tags size_*]] 5 end]] \
			[list anchor [$cur_c itemcget $id -anchor]] \
			[list rotate [$cur_c itemcget $id -rotate]] \
		       ]
      }
    } elseif {[is_tagged $id dot]} {
      set return [list [list type dot] \
		      [list coords [round_list [center $id]]]]

      set dot_open 1

    } elseif {[is_tagged $id open]} {
      set return [list [list type open] \
		      [list coords [round_list [center $id]]]]

      set dot_open 1

    } else {
      # unknown type
      return -code error "Error: Instance \#$id is invalid."
    }

    # scale this guy back
    if {$scale != 10} {
      set scalefactor [expr $scale / 10.0]
      $cur_c scale $id 0 0 $scalefactor $scalefactor
    }

    if {$dot_open} {
      set net [display_local_net $id]
      if {$net != ""} {
	lappend return [list net $net]
      }
    }

    return $return
  }
}


# load a cell

proc api_load_cell {cell} -type user -desc {

Loads the cell with the given cell name.  If the cell is already
loaded, just goes to it.

If the cell name includes a full path, then adds that path to the
search paths and loads the cell.

} {

  launch "load_schematic $cell"
  return 1
}


proc api_revert_cell {} -type user -desc {

Reverts the current cell to the last saved version.
} {

  launch "revert"
  return 1
}


proc api_push {id} -type user -desc {

Pushes into the instance with the given id

Adds to the hierarchy and goes to the desired schematic, or if none
exists the icon view.  api_pop restores this cell.

Returns 1 is succeeded, 0 if failed.

} {

  global cur_s

  set save_cur_s $cur_s

  launch "push_into_schematic $id"

  if {$save_cur_s == $cur_s} {
    # failed
    return 0
  } else {
    return 1
  }
}


proc api_pop {} -type user -desc {

Pops out of the current cell.

If already the topmost cell, does nothing.  Returns 1 is succeeded, 0
if failed.

} {
  global cur_s

  set save_cur_s $cur_s

  launch "pop_out_of_schematic"

  if {$save_cur_s == $cur_s} {
    # failed
    return 0
  } else {
    return 1
  }
}


proc api_cell_hierarchy {{hierarchy _NO_ARG_}} -type user -desc {

Returns the list of cells pushed into to get to the current cell.  If
called with an argument, sets the hierarchy to that argument and returns the previous hierarchy.

WARNING: setting the hierarchy to something invalid will have unforseen
consequences.

The elements of this list are ordered so that the first one is the
calling cell and the last one is the topmost cell.  If this is the
topmost cell, nil is returned.

Each element of this list is a pair of values: the cell type and the
id of the cell pushed into from that cell.  The id is required to
prevent ambiguity when there is more than one instance of that cell type
in the cell.

For example:

        sue> set save_hierarchy [api_cell_hierarchy]
        {adder8 581} {alu8 17}
        sue> set save_cell [api_current_cell]
        sue> api_goto_cell shift8
        ...
        sue> # restore cell and hierarchy
        sue> api_goto_cell $save_cell
        sue> api_cell_hierarchy $save_hierarchy
} {

  global HIERARCHY

  # create hierarchy list
  set list ""
  foreach pair [use_first HIERARCHY] {
    lappend list [split $pair ,]
  }

  if {$hierarchy != "_NO_ARG_"} {
    # set hierarchy
    set HIERARCHY ""
    foreach pair $hierarchy {
      lappend HIERARCHY [join $pair ,]
    }
  }

  # return current (or previous) hierarchy
  return $list
}



proc api_cell_path {{type spice}} -type user -desc {

Returns the list of cell names thru the hierarchy to create the hierachical
path name to the cell.

USAGE: api_cell_path [<type>]

Where <type> defaults to "spice".  If <type> is "verilog", returns the
test module and rootcell module names also.

For example:

        sue> api_cell_path
        alu shifter_1
        sue> api_cell_path verilog
        test unit alu shifter_1

To get the full path name of a selected wire, use:

        set local_net [get_assoc net [api_get_data [api_types wire selected]]]
        set net [join [concat [api_cell_path] $local_net] .]

for spice or

        set local_net [get_assoc net [api_get_data [api_types wire selected]]]
        set net [join [concat [api_cell_path verilog] $local_net] .]

for verilog.

} {

  global HIERARCHY VERILOG_ROOT NETLIST

  if {$type == "verilog"} {
    # verilog names require top level module and root module
    set list [list $VERILOG_ROOT $NETLIST(root)]
  } else {
    set list ""
  }

  foreach schematic [lreverse $HIERARCHY] {
    upvar #0 TERMS_[lindex [split $schematic ,] 0] TT
    lappend list $TT([lindex [split $schematic ,] 1])
  }

  # remove any {}
  regsub -all {\{|\}} $list "" list

  return $list
}


# goto a cell

proc api_goto_cell {cell} -type user -desc {

Changes the current cell to the given cell, if it exists.  Returns 1
if succeeded, otherwise 0.

Tries to go to the schematic view of the cell, unless specifically
given an "ICON_" name, but if none exists will go to the icon view
instead.  NOTE: if goes to the other view, will return 0, even though
it has changed the current cell.

Any hierarchy is lost, i.e. you cannot pop out of the cell.

If the schematic is not loaded but in the auto-load path, it will be
loaded.
} {

  global cur_s

  launch "goto_schematic $cell 1"

  if {$cur_s == $cell} {
    # went there
    return 1
  } else {
    # deosn't exist
    return 0
  }
}


# save current cell

proc api_save_cell {} -type user -desc {

Saves the current cell and associated schematic or icon.  

This command is identical to clicking on "save" in the "File" menu.
} {

  global cur_s

  launch "write_file $cur_s"
  return 1
}


# clean connects on a cell

proc api_clean_connections {{type ""} {mod ""}} -type user -desc {

Recomputes the connection information, breaking wires and adding
solder dots and opens, on either the entire schematic or just the
selected area.  Breaks wires that intersect with wire ends or icon
terminals.  

USAGE: api_clean_connections [<type>] [<modify>]

If <type> is "selected", only cleans connections on selected objects.
This option is meant for performance purposes.  Cleaning entire large
schematics can be slow.  The default is "" (clean everything).

If <modify> is "" (the default), then api_clean_connections sets the
modified flag on the current cell.  Otherwise the modify flag is not
set.

For example:

        sue> api_clean_connections "" no_modify

NOTE: this procedure only applies to schematics.  Run on an icon or
placement, it will return 0, else 1.

NOT UN-DOABLE

} {

  global cur_s

  if {[is_icon $cur_s] || [is_placement $cur_s]} {
    return 0
  }

  # only allow selected
  if {$type != "selected"} {
    set type ""
  }

  show_connects $type clean

  if {$mod == ""} {
    is_modified
  }

  return 1
}


proc api_show_connections {{type ""}} -type user -desc {

Displays the connection information on a schematic.

Does NOT break wires -- use api_clean_connections for that.

USAGE: api_show_connections [<type>]

If <type> is "selected", only shows connections on selected objects.
This option is meant for performance purposes.  The default is ""
(show everywhere).

For example:

        sue> api_show_connections

NOTE: this procedure only applies to schematics.  Run on an icon or
placement, it will return 0, else 1.

} {

  global cur_s

  if {[is_icon $cur_s] || [is_placement $cur_s]} {
    return 0
  }

  # only allow selected
  if {$type != "selected"} {
    set type ""
  }

  show_connects $type fast

  return 1
}


# should eventually take a cell argument

proc api_bbox {} -type user -desc {

Returns a list of the coordinates of the bounding box of the current
cell.

For example:

        sue> api_bbox
        10 10 200 300
} {

  global cur_c scale 

  set bbox ""

  $cur_c addtag bbox withtag all
  $cur_c dtag grid bbox
  $cur_c dtag tmp bbox

  foreach x [$cur_c bbox bbox] {
    lappend bbox [expr round($x / $scale) * 10]
  }

  $cur_c dtag bbox

  return $bbox
}


# select 

proc api_select {name {add ""} {by_type 0}} -type user -desc {

Selects the named object, either a net or an instance, in the current
cell.  If successful returns 1, else 0.  Deselects first unless
the "add" argument is given.  <name> can include the * for
wildcarding, for example:

USAGE: api_select <name> [add] [by_type]

if [by_type] is "1" (true) then the search is done by instance type.
Defaults to "0" (false).  Note, can only be used with the [add] argument, which can be "".

For example:

        sue> api_select uc_*
        1

will select all the unconnected nets in the schematic and

        sue> api_select *
        1

will select everything in the schematic and 

        sue> api_select suggested_name "" 1
        1

will select all of the suggested_name instances, for example, for deletion.

Other than for selecting all, you need to netlist the design in order
to select instances (i.e. anything but wires).
} {

  if {$add != "add"} {
    # clear selection first
    select_ids ""
  }

  # if * then select all
  if {$name == "*"} {
    global cur_c COLORS

    # get rid of any edit markers, and other temp. stuff
    $cur_c delete tmp

    $cur_c addtag selected withtag all
    $cur_c dtag grid selected

    # change color to show selected
    show_color selected $COLORS(selected)

    display_selection *

    if {[$cur_c find withtag all] == ""} {
      return 0
    } else {
      return 1
    }

  } else {
    return [launch "select_by_name $name batch $by_type"]
  }
}


proc api_select_ids {ids {add ""}} -type user -desc {

Selects the given ids in the current cell.  If successful returns 1,
else 0.  Deselects first unless the "add" argument is given.

USAGE: api_select_ids <ids> [add]

For example:

        sue> api_select_ids "24 88 104"
        1

To deselect everything, use:

        sue> api_select_ids ""
        1

} {

  select_ids $ids $add
  return 1
}


proc api_move_selected {dx dy} -type user -desc {

Moves selected objects, preserving connectivity.

Movements in x (dx) and y (dy) need to be rounded to multiples of 10, the
minimum grid size, or else objects will go off-grid.

Returns 1, or 0 if nothing is selected or bad distance.

Sets the modifed flag and is undoable.

} {

  global cur_c scale

  set ids [$cur_c find withtag selected]

  if {$ids == ""} {
    # nothing selected
    return 0
  }

  if {[catch "expr $dx"] || [catch "expr $dy"]} {
    # bad numbers
    return 0
  }

#  set dx [round_list_scale $dx 10]
#  set dy [round_list_scale $dy 10]

  set dx [expr $scale*$dx/10.0]
  set dy [expr $scale*$dy/10.0]

  if {($dx == 0 && $dy == 0) || $dx > 20000 || $dx < -20000 || \
	  $dy > 20000 || $dy < -20000} {
    # bad numbers
    return 0
  }

#  set save_scale $scale
#  scale_canvas 10

  setup_move_mode 0 0
  move_drag $dx $dy
  end_move_mode

#  scale_canvas $save_scale

  return 1
}


# transform

proc api_transform_selected {xform} -type user -desc {

Transforms the selected objects.  Legal transforms are rotate
clockwise (rotate), flip sideways (sideways), and flip upsidedown
(upsidedown).  If something gets transformed, returns 1, else 0.

For example:

        sue> api_transform_selected rotate
        1

Sets the modifed flag and is undoable.

} {

  global cur_c

  switch $xform {
    rotate {
      launch "transform_selected ROTATE"
    }
    sideways {
      launch "transform_selected MX"
    }
    upsidedown {
      launch "transform_selected MY"
    }
    default {
      puts "WARNING: illegal transform \"$xform\" given to api_transform_selected.  Legal transforms are \"rotate, sideways, and upsidedown\"."
      return 0
    }
  }

  if {[$cur_c find withtag selected] == ""} {
    return 0
  } else {
    return 1
  }
}
    

# return objects of a certain type in cell

proc api_types {type {selected ""}} -type user -desc {

Returns a list of ids for all of the objects of the specified type in
the current cell.  Legal types are: instance, wire, line, arc, text,
dot, open.  If the optional keyword "selected" is given, only those
objects that are selected are returned.

        sue> api_types wire
        251 252 253 254 255 256 257 318
        sue> api_types wire selected
        257

Note that "api_types instance [selected]" is equivalent to
"api_instances [selected]".
} {

  global cur_c scale

  # either all or selected only
  if {$selected != "selected"} {
    set selected ""
  } else {
    set selected "&selected"
  }

  set return ""

  switch _$type {

    _instance {
      set return [$cur_c find withtag origin$selected]
    }

    _wire {
      set return [$cur_c find withtag wire$selected]
    }

    _line {
      foreach id [$cur_c find withtag draw_item$selected] {
	if {[$cur_c type $id] == "line"} {
	  lappend return $id
	}
      }
    }

    _arc {
      foreach id [$cur_c find withtag draw_item$selected] {
	if {[$cur_c type $id] == "arc"} {
	  lappend return $id
	}
      }
    }

    _text {
      foreach id [$cur_c find withtag draw_item$selected] {
	if {[$cur_c type $id] == "text"} {
	  lappend return $id
	}
      }
    }

    _dot {
      set return [$cur_c find withtag dot$selected]
    }

    _open {
      set return [$cur_c find withtag open$selected]
    }

    default {
      return -code error "Error in api_types, type must be one of instance, wire, line, arc, text."
    }
  }

  return $return
}


proc api_annotate_text {args} -type user -desc {

Adds a text annotation to the current cell.  Annotations are temporary.
  
USAGE: api_annotate_text -text <text> -origin <list> 
          [-anchor <n|s|e|w|c|nw|ne|se|sw>] [-rotate <0|1>]
          [-color <color>] [-size <small|standard|large>] [-tags <tags>]

anchor defaults to w
rotate defaults to 0 -- not rotated
color defaults to COLORS(anchor)
size defaults to standard

Optional tags can be supplied.  Without any tags, the annotations are
removed by executing many SUE commands or by clicking on the screen.
With tags, the annotations have to be cleared using
api_clear_annotations with the appropriate argument.

For example,

        sue> api_annotate_text -text "hi there" -origin "20 -40" -color pink
        1

Returns 1 if successful, 0 otherwise.
} {

  global cur_c scale COLORS FONT

  call_by_keyword $args [list {origin ""} {text ""} {anchor w} {rotate 0} \
			     "color $COLORS(anchor)" {size standard} "tags {}"]

  if {$text == "" || $origin == ""} { 
    return 0
  }

  set fscale [expr int(ceil($scale))]

  # scale x,y
  setl {x y} [scale_list $origin [expr $scale / 10.0]]

  if {$tags == ""} {
    set tags "tmp scaletext size_$size"
  } else {
    # get rid of extra spaces
    regsub -all {[ ]+} [string trim $tags] " " tags

    # add a tmp__ to each tag
    regsub -all {(^| )} $tags {\0tmp__} tags

    # so we can find them all
    lappend tags tmp_all scaletext size_$size
  }

  if {[catch {$cur_c create text $x $y -tags $tags \
		  -fill $color -text $text -font $FONT($size,$fscale) \
		  -rotate $rotate -anchor $anchor} msg]} {
    # failure
    return 0
  } else {
    # success
    return 1
  }
}


proc api_annotate_line {args} -type user -desc {

Adds a line annotation to the current cell.  Annotations are temporary.
Lines can be multi-segment such as in a rectangle.
  
USAGE: api_annotate_line -coords <list> [-color <color>] [-tags <tags>]
                         [-width <width>]

color defaults to COLORS(anchor)
width defaults to 1 (pixel)

Optional tags can be supplied.  Without any tags, the annotations are
removed by executing many SUE commands or by clicking on the screen.
With tags, the annotations have to be cleared using
api_clear_annotations with the appropriate argument.

For example,

        sue> api_annotate_line -coords "0 0 100 0 100 100 0 100 0 0" -color green
        1

Returns 1 if successful, 0 otherwise.
} {

  global cur_c scale COLORS

  call_by_keyword $args [list {coords ""} "color $COLORS(anchor)" "width 1" "tags {}"]

  if {$coords == ""} { 
    return 0
  }

  if {[catch "expr $width"] || $width < 1} {
    return 0
  }

  if {$tags == ""} {
    set tags tmp
  } else {
    # get rid of extra spaces
    regsub -all {[ ]+} [string trim $tags] " " tags

    # add a tmp__ to each tag
    regsub -all {(^| )} $tags {\0tmp__} tags

    # so we can find them all
    lappend tags tmp_all
  }

  if {[catch "$cur_c create line [scale_list $coords [expr $scale / 10.0]] \
		  -tags \{$tags\} -fill $color -width $width"]} {
    # failure
    return 0
  } else {
    # success
    return 1
  }
}


proc api_annotate_filled_rect {args} -type user -desc {

Adds a filled rectangle annotation to the current cell.  To get a hollow
rectangle, use api_annotate_line.
  
USAGE: api_annotate_filled_rect -coords <x1 y1 x2 y2> [-fill <color>] [-outline <color>] [-tags <tags>]

color defaults to COLORS(anchor)

Optional tags can be supplied.  Without any tags, the annotations are
removed by executing many SUE commands or by clicking on the screen.
With tags, the annotations have to be cleared using
api_clear_annotations with the appropriate argument.

For example,

        sue> api_annotate_filled_rect -coords "0 0 100 100" -fill green -outline yellow
        1

Returns 1 if successful, 0 otherwise.
} {

  global cur_c scale COLORS

  call_by_keyword $args [list {coords ""} "fill $COLORS(anchor)" "outline $COLORS(anchor)" "tags {}"]

  if {$coords == "" || [llength $coords] != 4} { 
    return 0
  }

  if {$tags == ""} {
    set tags tmp
  } else {
    # get rid of extra spaces
    regsub -all {[ ]+} [string trim $tags] " " tags

    # add a tmp__ to each tag
    regsub -all {(^| )} $tags {\0tmp__} tags

    # so we can find them all
    lappend tags tmp_all
  }

  if {[catch "$cur_c create rectangle [scale_list $coords [expr $scale / 10.0]]\
		  -tags \{$tags\} -fill $fill -outline $outline"]} {
    # failure
    return 0
  } else {
    # success
    return 1
  }
}


proc api_annotate_change_color {tag color} -type user -desc {

Changes all annotation with a given tag to a given color.
  
USAGE: api_annotate_change_color <tag> <color>

For example,

        sue> api_annotate_line -coords "0 0 100 100" -color pink -tags "foo bar"
        1
        sue> api_annotate_change_color foo green
        1

Returns 1 if successful, 0 otherwise.
} {

  global cur_c

  if {$color == ""} {
    return 0
  }

  if {$tag == ""} {
    return 0

  } elseif {$tag == "all"} {
    set tag tmp_all

  } else {
    set tag tmp__$tag
  }

  $cur_c itemconfigure $tag -fill $color

  return 1
}


proc api_clear_annotations {{tags ""}} -type user -desc {

Removes annotations from the current cell.

USAGE: api_clear_annotations [all|<tags>]

If annotations are created with the api and given tags, then you must
delete them by speicifing one of the tags or with "all".

Returns 1 if successful, 0 otherwise.
} {

  global cur_c

  if {$tags == ""} {
    $cur_c delete tmp

  } elseif {$tags == "all"} {
    $cur_c delete tmp
    $cur_c delete tmp_all

  } else {
    foreach tag $tags {
      $cur_c delete tmp__$tag
    }
  }

  return 1
}


proc api_delete_selected {} -type user -desc {

Deletes the selected items in the current cell.

Returns 1.

Sets the modifed flag and is undoable.

} {

  launch {delete_selected "" "" batch}

  return 1
}


proc api_delete {ids} -type user -desc {

Deletes the given list of ids in the current cell.

Returns 1.

For example,

        sue> api_delete "23 105 111"
        1

Sets the modifed flag and is undoable.

} {

  launch [list delete_selected $ids {} batch]

  return 1
}


proc api_orient_transform {orient point} -type user -desc {

  Transforms the given point through the given orientation around {0 0}.

For example,

        sue> api_orient_transform R0 "-20 10"
        -20 10
        sue> api_orient_transform R90 "-20 10"
        -10 -20

Returns "" if either the orientation or point are invalid.

Remember that Y increases downward on the screen.

} {

  setl {x y} $point
  if {[catch "expr $x + $y"]} {
    # failed, bad data
    return ""
  }

  switch _[string toupper $orient] {

    _R0 {
      return $point
    }

    _RX {
      return "[expr 0 - $x] $y"
    }

    _RY {
      return "$x [expr 0 - $y]"
    }

    _RXY {
      return "[expr 0 - $x] [expr 0 - $y]"
    }

    _R90 {
      return "[expr 0 - $y] $x"
    }

    _R270 {
      return "$y [expr 0 - $x]"
    }

    _R90X {
      return "$y $x"
    }

    _R90Y {
      return "[expr 0 - $y] [expr 0 - $x]"
    }

    default {
      return ""
    }
  }
}


proc api_overlap_ports {point {radius 0.33}} -type user -desc {

Returns a list of objects and their ports whose ports overlap the
given coordinates.  The radius defaults to 0.33 (1/3) grid which is
used for determining connectivity.  Only icons and wires will ever be
returned because they are the only objects that create connectivity.

The return list comprises pairs.  For icons, the pair contains the
icon id followed by the port name.  For wires, the pair contains the
wire id followed by the coordinates of the overlapping endpoint.

Returns "" if either the point or radius are invalid.

NOTE: a wire segment has two ports, one at each end of the line.  If
neither of these ports overlaps the given coordinates, the wire will
not be returned.

For example:

        sue> api_overlap_ports "410 260"
        {8 in} {36 {410 260}}
        sue> api_overlap_ports "410 260" 2
        {8 in} {36 {410 260}} {88 {410 270}}
} {

  global cur_c scale

  integer_scale

  if {[catch {setl {x y} [scale_list $point [expr $scale / 10.0]]}]} {
    # must be bad numbers
    unscale
    return ""
  }

  if {$y == ""} {
    unscale
    return ""
  }

  if {[catch "expr $scale * $radius" del]} {
    # must be bad numbers
    unscale
    return ""
  }

  # get all ids of things overlapping the given coordinates
  set ids [$cur_c find overlapping [expr $x - $del] [expr $y - $del] \
	      [expr $x + $del] [expr $y + $del]]

  set list ""
  foreach id $ids {
    if {[is_tagged $id term]} {
      # terminal on icon
      set tags [$cur_c gettags $id]
      set term [lindex [lindex $tags [lsearch $tags "name*"]] 3]
      lappend list [list [find_origin $id] $term]

    } elseif {[is_tagged $id wire]} {
      # wire, is it an endpoint
      setl {x1 y1 x2 y2} [$cur_c coords $id]

      # Note: both endpoints could be nearby if radius large enough
      if {[nearby $x $y $x1 $y1 $del] == 1} {
	lappend list \
	    [list $id [round_list [scale_list "$x1 $y1" [expr 10.0 / $scale]]]]
      }

      if {[nearby $x $y $x2 $y2 $del] == 1} {
	lappend list \
	    [list $id [round_list [scale_list "$x2 $y2" [expr 10.0 / $scale]]]]
      }
    }
  }

  unscale

  return $list
}


proc api_overlap {x1 y1 x2 y2 {mode overlap}} -type user -desc {

Returns a list of objects that overlap the rectangle given by the
supplied coordinates.  

USAGE: api_overlap x1 y1 x2 y2 [<mode>]

Returns a list of object id's.  if <mode> is "overlap" (the default)
then all objects are returned that are at least partially inside the
given rectangle.  if <mode> is "enclose", then only the objects that
are completely enclosed by the rectangle are returned.

For computing connectivity, see "api_overlap_ports".

For example:

        sue> api_overlap 100 200 400 300
        23 46 88 105
        sue> api_overlap 100 200 400 300 enclose
        23 105

NOTE: text which is part of an icon is ignored when computing
overlap/enclosure.

} {

  global cur_c scale

  integer_scale

  if {[catch {set bbox [scale_list "$x1 $y1 $x2 $y2" [expr $scale /10.0]]}]} {
    # must be bad numbers
    unscale
    return ""
  }

  if {[lindex $bbox 3] == ""} {
    unscale
    return ""
  }

  if {$mode == "enclose"} {
    eval $cur_c addtag enclosed enclosed $bbox

    # get all enclosed of type wire or draw_item
    set ids [concat [get_intersect_tag enclosed wire] \
		 [get_intersect_tag enclosed draw_item] \
		 [get_intersect_tag enclosed dot] \
		 [get_intersect_tag enclosed open]]

    setl {x1 y1 x2 y2} $bbox

    # icon can have parts of them enclosed, ignore those
    foreach id [get_intersect_tag enclosed origin] {

      # don't include the text in the bbox
      $cur_c addtag xxx withtag inst$id
      $cur_c dtag scaletext xxx
      set instbbox [$cur_c bbox xxx]
      $cur_c dtag xxx

      # select an inst only if fully enclosed by original bbox
      if {[lindex $instbbox 0] > $x1 && [lindex $instbbox 1] > $y1 && \
	      [lindex $instbbox 2] < $x2 && [lindex $instbbox 3] < $y2} {
	lappend ids $id
      }
    }

    $cur_c dtag enclosed

  } else {
    # overlap
    eval $cur_c addtag overlapping overlapping $bbox

    # get all overlapping of type wire or draw_item
    set ids [concat [get_intersect_tag overlapping wire] \
		 [get_intersect_tag overlapping draw_item] \
		 [get_intersect_tag overlapping dot] \
		 [get_intersect_tag overlapping open]]

    setl {x1 y1 x2 y2} $bbox

    # icon can have parts of them overlapping, find those
    foreach id [get_intersect_tag overlapping icon] {

      set tag [find_origin_tag $id]
      if {[info exists trace($tag)]} {
	# already been here
	continue
      }

      # ignore text in icons
      if {[$cur_c type $id] == "text"} {
	continue
      }

      set trace($tag) 1

      lappend ids [find_origin $id]
    }

    $cur_c dtag overlapping
  }

  unscale

  return $ids
}


proc api_replace_instances {ids type} -type user -desc {

Replaces the instance with the given ids with an instance of the given type.
Tries to keep all properties of the original instance.

USAGE: api_replace_instances <list_of_ids> <type>

For example:

        sue> api_replace_instances "34 102" INVB
        1

Returns 1 if successful, 0 otherwise

Note that SUE must know how to make <type> or it will return 0.  If you 
want to replace with a generated ICON that hasn't been generated in
the SUE session yet, you will have to generate it yourself using the
"generate" command.  For example:

        sue> api_replace_instances 68 MMI_NAND2D
        0
        sue> generate MMI_NAND2 MMI_NAND2D -Size D
        -1
        sue> api_replace_instances 68 MMI_NAND2D
        1
} {

  global cur_c cur_s PROC

  if {$ids == ""} {
    return 0
  }

  integer_scale

  # make a dummy icon for replacement
  if {[info proc ICON_$type] == ""} {
    # not around
    unscale
    return 0
  }

  if {[catch "make $type -origin {-100001 -100001}" id_tmp]} {
    # didn't work
    unscale
    return 0
  }

  upvar #0 ${cur_s}_inst$id_tmp i_data_tmp

  set PROC ""
  set new_ids ""
  set save_proc ""

  # replace each id
  foreach id $ids {

    if {![is_tagged $id origin]} {
      # not an icon
      continue
    }

    upvar #0 ${cur_s}_inst$id i_data

    # get all of the properties out of the existing icon
    # and put these properties temporarily into the id_tmp
    foreach prop [array names i_data _*] {
      set save($prop) [use_first i_data_tmp($prop)]
      set i_data_tmp($prop) $i_data($prop)
    }

    # setup undo stuff and do the switch
    set PROC $save_proc
    write_instances inst$id 1 undo
    set save_proc $PROC

    lappend new_ids [remake $id $id_tmp "" no_scale]

    # restore existing properties to id_tmp
    if {[info exists save]} {
      foreach prop [array names save] {
	set i_data($prop) $save($prop)
      }

      catch {unset save}
    }
  }

  # delete tmp icon and lose  data structure
  $cur_c delete inst$id_tmp
  unset i_data_tmp

  # undo
  setup_undo $new_ids $save_proc

  unscale

  if {$new_ids != ""} {
    return 1
  } else {
    return 0
  }
}


proc api_undo {} -type user -desc {

Undoes the last change to the current cell.

Returns 1.

} {

  launch undo_last

  return 1
}


proc api_zoom {arg} -type user -desc {

Zooms the current schematic based on the argument.

The arguments can be any one of the following:

        fit      - zoom to fit.
        selected - zoom the fit the selected in the window.
        <number> - zoom amount.  Less than 1 zoom out.  Greater than 1 in.
        <region> - zoom to fit region described by list of "x1 y1 x2 y2".
        setup    - sets zoom for fastest response of certain api commands.
        restore  - restores zoom after setup

Certain repeated commands will run much quicker if they are surrounded
by "api_zoom setup" and "api_zoom restore".  These command include:
api_change_prop, api_instance_data, api_overlap_ports, api_overlap, api_make,
api_make_wire, api_replace_instances.

In addition, make, make_wire, make_line, make_text, and make_arc must
be preceded by "api_zoom setup" or be invoked in a new schematic.
Otherwise, they will be placed incorrectly.

Don't need to do a restore after a setup.  A zoom to fit is fine, too.

For example:

        sue> api_zoom fit
        1
        sue> api_zoom selected
        1
        sue> api_zoom setup
        1
        sue> api_...
        sue> api_...
        sue> api_zoom restore
        1
} {

  global cur_s cur_c scale _ZOOM_

  if {![catch "expr [lindex $arg 0]"]} {
    # number
    if {[llength $arg] == 1} {
      if {$arg == 1} {
	# does nothing -- hangs though
	return 1
      }

      if {$arg < 0.1} {
	# not valid
	return 0
      }

      launch "zoom $arg"
      return 1
    }
  }

  # region
  if {[llength $arg] == 4} {
    if {[catch {scale_list $arg [expr $scale / 10.0]} region]} {
      # not valid
      return
    }

    eval $cur_c create rectangle $region -tags stroke_box

    launch [list zoom_to_bbox $region 0]
    eval center_canvas [center_bbox [$cur_c bbox stroke_box]]

    # get rid of stroke box
    $cur_c delete stroke_box 

    return 1
  }

  switch _$arg {
    _setup {
      set _ZOOM_($cur_s) $scale
      scale_canvas 10
      return 1
    }

    _restore {
      if {[info exists _ZOOM_($cur_s)]} {
	scale_canvas $_ZOOM_($cur_s)
	unset _ZOOM_($cur_s)
	return 1
      } else {
	return 0
      }
    }

    _fit {
      launch zoom_to_fit
      return 1
    }

    _selected {
      return [launch "zoom_to_selected 1"]
    }

    default {
      return 0
    }
  }
}


proc api_icon_listboxes {} -type user -desc {

Returns the number of icon listboxes.

} {

  global ICON_WINDOWS ICON_MENU

  if {$ICON_MENU == "flat"} {
    # doesn't work on these
    return 1
  }

  return [llength $ICON_WINDOWS]
}


proc api_icon_listbox {args} -type user -desc {

Add, delete, and modify contents of icon listboxes.

USAGE: api_icon_listbox -command <dir|change|add|delete> [-index <index>]
                        [-dir <dir_name>]

The indexes start from 0 for the top icon listbox (the one right below
the schematic listbox) and increment downwards.  If the index is not
specified in defaults to the bottom one.

If -command is "dir" then the directory linsted in the nth icon listbox given
by <index> is returned.

For example:

        sue> for {set i 0} {$i < [api_icon_listboxes]} {incr i} {
        sue?   puts "icon listbox $i: [api_icon_listbox -command dir -index $i]"
        sue? }
        icon listbox 0: /proj/foobar/stdcell/sue
        icon listbox 1: /proj/foobar/sue/devices
        icon listbox 2: /proj/foobar/sue/mspice

} {

  global ICON_WINDOWS ICON_MENU WIN auto_path

  call_by_keyword $args {{dir ""} {index end} {command ""}}
  
  if {$ICON_MENU == "flat"} {
    # doesn't work on these
    return 0
  }

  if {$index == "end"} {
    set index [expr [api_icon_listboxes] - 1]
  }

  if {[catch "expr $index"] || $index < 0 || $index >= [api_icon_listboxes]} {
    # error
    return 0
  }

  set paths [concat $auto_path generators]

  switch _$command {

    _add {
      # is this valid
      if {[lsearch -exact $paths $dir] == -1} { 
	# not valid
	return 0
      } else {
	# valid
	new_icon_menu $dir $index
	return 1
      }
    }

    _delete {
      # remove nth listbox
      if {[api_icon_listboxes] < 2} {
	# need at least one
	return 0
      }

      waste_icon_listbox ".[lindex $ICON_WINDOWS $index]"
      return 1
    }

    _dir {
      set win "$WIN.lb.[lindex $ICON_WINDOWS $index]"
      return [$win.dir cget -text]
    }

    _change {
      if {[lsearch -exact $paths $dir] == -1} { 
	# not valid
	return 0
      } else {
	# valid
	set win "$WIN.lb.[lindex $ICON_WINDOWS $index]"
	make_icon_listbox $dir $win
	return 1
      }
    }

    default {
      return 0
    }
  }
}


proc api_make {what args} -type user -desc {

Adds an icon to the current cell.  Like "make" but is undoable and
doesn't require special procedures to be run either before or after
it.  However, if wrapped with "api_zoom setup" and "api_zoom restore",
multiple api_make commands will run faster.

NOTE: slower than "make".

USAGE: api_make <icon_name> -origin <x_y_list> [-orient <orient>] <keyword_arguments>

<orient> defaults to R0 and can be any of the standard SUE
orientations: R0, RX, RY, RXY, R90X, R90Y, R270.

The keyword/argument pair order is unimportant.

<keyword_arguements> are unique for each icon and depend on the user
properties in the icon view of the cell.  Typically they contain at
least the "name" property.

Special tcl characters such as []$ must be quoted or surrounded by {}.

For example:

        sue> api_make inverter -origin {120 100} -orient RX -name foo

Returns the id of the icon or "" if unsuccessful.

Sets the modifed flag and is undoable.

} {

  global scale __MAKE_SPECIAL__ cur_s

  set index [lsearch -exact $args "-origin"]
  if {$index == -1} {
    # needs an origin
    return ""
  }

  # scale origin
  incr index
  set args [lreplace $args $index $index \
		[scale_list [lindex $args $index] [expr $scale / 10.0]]]

  set __MAKE_SPECIAL__ 1
  set id [eval make $what $args]
  set __MAKE_SPECIAL__ 0

  if {$id == ""} {
    # didn't work
    return ""
  }

  # show connection info on new icon unless we are in an icon
  if {![is_icon $cur_s] && ![is_placement $cur_s]} {
    integer_scale
    show_term_connects inst$id
    unscale
  }

  # save undo information
  setup_undo $id ""

  is_modified

  return $id
}


proc api_make_wire {x1 y1 x2 y2} -type user -desc {

Adds a wire to the current schematic.  Like "make_wire" but is
undoable and doesn't require any special procedures to be run either
before or after it.  However, if wrapped with "api_zoom setup" and
"api_zoom restore", multiple api_make_wire commands will run faster.

NOTE: slower than "make_wire".

USAGE: api_make_wire x1 y1 x2 y2

For example:

        sue> api_make_wire 100 200 180 200
        sue> api_make_wire 180 200 180 240

Merges connected wires.

Returns the id of the wire or "" if unsuccessful.

Sets the modifed flag and is undoable.

} {

  global scale cur_s

  if {[is_icon $cur_s] || [is_placement $cur_s]} {
    return ""
  }

  set id [eval make_wire [scale_list [list $x1 $y1 $x2 $y2] \
			      [expr $scale / 10.0]]]

  if {$id == ""} {
    # didn't work
    return ""
  }

  # show connection info
  integer_scale
  show_connect_wire $id
  unscale

  # save undo information
  setup_undo $id ""

  is_modified

  return $id
}


proc api_make_text {args} -type user -desc {

Adds text to the current cell.  Like "make_text" but is
undoable and doesn't require any special procedures to be run either
before or after it.

USAGE: api_make_text -origin <x_y_list> -text <text> [-size <size>]
                     [-anchor <anchor>] [-rotate <0|1>]

Text has two orientations: normal (0) and rotated (1).  Text defaults
to normal (0).

Size can be one of: very-small, small, standard, large, very-large.
Size defaults to standard.

Anchor can be one of: n, s, e, w, ne, nw, se, sw, center, or c.
Anchor defaults to w.

For example:

        sue> api_make_text -origin {120 140} -text "Doesn't need a keeper."

Returns the id of the wire or "" if unsuccessful.

Sets the modifed flag and is undoable.

} {

  global scale cur_s

  set index [lsearch -exact $args "-origin"]
  if {$index == -1} {
    # needs an origin
    return ""
  }

  # scale origin
  incr index
  set args [lreplace $args $index $index \
		[scale_list [lindex $args $index] [expr $scale / 10.0]]]

  set index [lsearch -exact $args "-text"]
  if {$index == -1 || [lindex $args [incr index]] == ""} {
    # needs text
    return ""
  }

  set save_scale $scale
  set scale [expr int(ceil($scale))]
  if {[catch "make_text $args" id]} {
    set id ""
  }
  set scale $save_scale

  if {$id == ""} {
    # didn't work
    return ""
  }

  # save undo information
  setup_undo $id ""

  is_modified

  return $id
}


proc api_make_line {args} -type user -desc {

Adds a line to the current cell.  Like "make_line" but is
undoable and doesn't require any special procedures to be run either
before or after it.

USAGE: api_make_line <list_of_x_y_pairs>

For example:

        sue> api_make_line 120 150 200 300
        sue> api_make_line 0 0 100 0 100 100 0 100 0 0

Returns the id of the line or "" if unsuccessful.

Sets the modifed flag and is undoable.

} {

  global scale cur_s

  # scale
  if {[catch "scale_list \"$args\" [expr $scale / 10.0]" coords]} {
    # problem
    return ""
  }

  if {[expr [llength $coords] % 2] == 1} {
    # problem
    return ""
  }

  if {[catch "make_line $coords" id]} {
    # didn't work
    return ""
  }

  # save undo information
  setup_undo $id ""

  is_modified

  return $id
}


proc api_make_arc {args} -type user -desc {

Adds an arc to the current cell.  Like "make_arc" but is
undoable and doesn't require any special procedures to be run either
before or after it.

Arcs are drawn by specifying the bounding box of an ellipse.  The
start angle and the extent of the arc counterclockwise are also
specified, both in degrees.  Circles are arcs with square bounding
boxes and an extent of 359 degrees.

SUE does not support splines.

USAGE: api_make_arc x1 y1 x2 y2 -start <start_angle> -extent <extent_angle>

<start_angle> defaults to 0 degrees which corresponds to the middle of
the right side of the bounding box.  

<extent_angle> defaults to 90 degrees and proceeds counterclockwise.
Note: the maximum extent is 359 degrees and creates a closed
circle/ellipse.

For example:

        sue> api_make_arc 0 0 200 200 -start 90 -extent 180
        sue> api_make_arc 100 100 300 300 -extent 359

Returns the id of the line or "" if unsuccessful.

Sets the modifed flag and is undoable.

} {

  global scale cur_s

  # scale
  if {[catch "scale_list \"[lrange $args 0 3]\" [expr $scale / 10.0]" coords]} {
    # problem
    return ""
  }

  if {[llength $coords] != 4} {
    # problem
    return ""
  }

  if {[catch "make_arc $coords [lrange $args 4 end]" id]} {
    # didn't work
    return ""
  }

  # save undo information
  setup_undo $id ""

  is_modified

  return $id
}


proc api_check_ios {{cell ""}} -type user -desc {

Checks that the schematic and icon I/O's match for a given cell.  If
no cell is given, checks the current cell.

USAGE: api_check_ios [<cell>]

For example:

        sue> api_check_ios

Returns "" if equivalent, otherwise outputs differences.

} {

  global cur_c

  set save_cell [api_current_cell]

  if {$cell == ""} {
    set cell [get_rootname [api_current_cell]]
  }

  if {[info proc SCHEMATIC_$cell] == ""} {
    # no schematic
    return "Schematic $cell doesn't exist."
  }

  if {[info proc ICON_$cell] == ""} {
    # no icon
    return "Icon $cell doesn't exist."
  }

  if {![info exists SUE($cell)]} {
    # load this
    api_goto_cell $cell
  }

  if {![info exists SUE(ICON_$cell)]} {
    # load this
    api_goto_cell ICON_$cell
  }

  global SUE_$cell SUE_ICON_$cell

  set canvas [set SUE_${cell}(canvas)]

  set ids [concat [$cur_c find withtag icon_input] \
	       [$cur_c find withtag icon_inout] \
	       [$cur_c find withtag icon_output]]

  check_ios $cell $ids $cur_c

  api_goto_cell $save_cell

  return ""
}


proc api_visible_bbox {} -type user -desc {

Returns the coordinates of the visible part of the screen for the
current cell.

Useful for adding something to the screen that is guaranteed to be
visible to the user without zooming.

For example:

        sue> api_visible_bbox
        650 -1470 1270 -930
} {

  global scale

  return [round_list_scale [scale_list [visible_bbox] [expr 10.0 / $scale]] 10]
}


proc api_verilog_property {} -type user -desc {

Returns the verilog property text string for the current icon.

Creates the same string as in the menu command "Create Verilog Property."

For example:

        sue> api_verilog_property
       -type auto -name verilog -text {MMI_AND2B [unique_name "" $name MMI_AND2B] \
        (.in0($in0), .in1($in1), .out($out))\;}

If the current cell is not an icon, returns "".

} {

  global cur_s

  if {[is_icon $cur_s]} {
    return [create_verilog_property string]

  } else {
    return ""
  }
}


proc api_netlist_info {what {cell ""}} -type user -desc {

Returns information about the netlist of the current cell or the
optional givel cell.

USAGE: api_netlist_info status|warnings|errors [<cell>]

"status" returns 1 if there is netlist information about the cell and
0 if there is none.  "warnings" returns any netlist warnings about the
cell and "errors" returns any netlist errors.

For example:

        sue> api_netlist_info status
        1
        sue> api_netlist_info warnings
        {NETLIST WARNING: Unconnected net on terminal "out" in icon inverter "" (1) in schematic "no_name".} {NETLIST WARNING: Unconnected net on terminal "in" in icon inverter "" (1) in schematic "no_name".}
        sue> api_netlist_info errors
        ""

} {

  global cur_s NETLIST_CACHE

  if {$cell == ""} {
    set cell $cur_s
  }

  switch $what {

    status {
      return [info exists NETLIST_CACHE($cur_s)]
    }

    warnings {
      return $NETLIST_CACHE($cell,warnings)

    }

    errors {
      return $NETLIST_CACHE($cell,error)

    }
  }

  return -code error "Error: unknown netlist query \"$what\"."
}


proc api_clipboard {operation {origin {0 0}}} -type user -desc {

Invokes the SUE clipboard on the selected object(s).  Valid operations
are cut, copy, and paste.

USAGE: api_clipboard cut|copy|paste [<origin>]

Returns 1 if successful.

The origin is the offset of the lower right hand corner of the bbox of
the selection area wrt the upper left hand corner of the bbox of the
cell that it is getting pasted into.  The origin defaults to {0 0}.
NOTE: the y coord increases downward on the screen.

For example:

        sue> api_clipboard copy
        1
        sue> api_goto_cell foo
        1
        sue> api_clipboard paste {100 100}
        1

This will copy the selected objects from the current cell, switch to the
cell "foo" and paste the objects back with an origin of {100 100}.

} {

  global cur_c scale CLIPBOARD_FILE

  switch $operation {

    cut - copy {
      # check if anything selected
      if {[llength [$cur_c find withtag selected]] == 0} {
	# nothing selected
	return 0
      }

      launch {delete_selected_undo cut_to_clipboard}

      if {$operation == "cut"} {
	# delete 
	launch {delete_selected "" "" batch}
      }
    }

    paste {

      $cur_c addtag object all
      $cur_c dtag grid object

      set bbox [$cur_c bbox object]
      $cur_c dtag object

      if {[catch {source $CLIPBOARD_FILE}]} {
	return 0
      }

      if {$bbox != ""} {
	# place wrt the ll corner

	set cbbox [$cur_c bbox selected]
	if {$cbbox == ""} {
	  # nothing pasted, punt
	  return 0
	}

	# get lower left stuff
	setl {xl yl} $bbox
	setl {xo yo} $origin
	setl {tmp1 tmp2 x y} $cbbox

	# scale origin
	set xo [expr 1.0*$xo*($scale/10.0)]
	set yo [expr 1.0*$yo*($scale/10.0)]

	# now move it
	$cur_c move selected [expr $scale * int(($xl - $x + $xo) / $scale)] \
	    [expr $scale * int(($yl - $y + $yo) / $scale)]
      }

      launch end_duplication
    }

    default {
      # illegal operation
      return 0
    }
  }
}


proc api_generate_inst_names {} -type user -desc {

Generates sample instance names for the current schematic.  These
instance names are ONLY correct for instances that create their names
in the standard way.  This is handy for searching instances without
needing to netlist the entire hierarchy.

Always returns 1.

} {

  global cur_c cur_s NAMES

  catch {unset NAMES}
  set NAMES(_unique) 0

  # TODO: check if needed

  busy

  foreach id [$cur_c find withtag origin] {

    upvar #0 TERMS_$cur_s TERMS

    upvar #0 ${cur_s}_inst$id i_data
    # the type is the really the instance name
    set type $i_data(type)

    # don't allow recursion.  Useful for placing cell icon in cell.
    if {$type == $cur_s} {
      continue
    }

    set inst_name [lookup_name [use_first i_data(_name)]]
    set root [unique_name "" [bus_root $inst_name] $type]

    if {[bus_width $inst_name] > 1} {
      setl {min max} [lsort -integer [bus_range $inst_name]]
      set TERMS($id) "$root\[$max:$min\]"
    } else {
      set TERMS($id) "$root"
    }
  }

  make_reverse_terms_array

  ready
  return 1
}


proc api_modify_cell {} -type user -desc {

Sets the modified flag on the current cell.  Returns 1
if successful, 0 otherwise.

} {

  global cur_s

  upvar #0 SUE_$cur_s data

  # check if read-only
  if {!$data(read_only)} {
    is_modified 1
    return 1

  } else {
    return 0
  }
}


proc api_delete_buffer {{name ""}} -type user -desc {

Deletes the given buffer from the SUE memory.  To remove the file from disk use the unix "rm" command.

Only deletes the schematic or icon, not both.  To remove an icon, make sure the name contains ICON_<name>.

Returns 1 if successful, 0 otherwise.

} {

  return [delete_schematic $name even_no_name batch]
}


proc api_is_selected {id} -type user -desc {

Returns 1 if the id is selected, 0 otherwise.  Also returns 0 if id
doesn't exist.

} {

  return [is_tagged $id selected]
}


proc api_toggle_placement {} -type user -desc {

Creates the placement for the last DPC run and goes to it.  If the
placement file already exists and is up-to-date, just goes to it.  If
in a placement file, goes to the schematic.

DPC Netlist or DPC it must be run first on the schematic.

Returns 1 if successful, 0 otherwise.

} {

  return [launch toggle_show_placement]
}
