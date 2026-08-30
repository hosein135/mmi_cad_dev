
# pops up a window with options to create an icon from a spice
# subckt definition and then create it.

menu_add -menu local -label "Spice Icon Creator" \
    -command spice_icon_creator \
    -help "Automatically creates an icon from a spice subckt definition and places it in the current schematic from the given ports."


# defaults

set SPICE_ICON_CREATOR(global) "VDD* GND*"
set SPICE_ICON_CREATOR(suffix) "*.inc"


proc spice_icon_creator {{remake_this ""} {drop 1}} -desc {

  pops up a window with options to create an icon and create it.

} {

  global DEFAULT_PROPERTIES SPICE_ICON_CREATOR

  set title "Spice Icon Creator"
  set message "Enter icon name or spice file and modify port info:"

  set props ""
  set other_props ""
  foreach prop $DEFAULT_PROPERTIES {
    call_keyword $prop {{type ""} {name ""} {default ""}}

    if {$type == "user"} {
      lappend props -$name $default

    } else {
      lappend other_props $prop
    }
  }

  set no_ports 0

  if {$remake_this == ""} {
    set id [api_instances selected]
    if {[llength $id] == 1 && \
	    [api_instance_data $id generator] != 1} {
      set type [api_instance_data $id type]

      if {![catch {api_instance_type_data $type _primitive} msg] && $msg == 1} {
	# ignore primitives
      } else {
	set remake_this $type
	set drop 0
      }
    }
  }

  if {[file isfile $remake_this] && [info_proc ICON_$remake_this] == ""} {

    # use spice file
    set data [parse_spice_file $remake_this]

    if {$data == ""} {
      # start over
      spice_icon_creator
      return
    }

    set icon [lindex $data 0]

    set i 0
    foreach port [lrange $data 1 end] {
      set port$i $port
      set port_side$i left
      set port_type$i input

      foreach global $SPICE_ICON_CREATOR(global) {
	if {[lsearch [string toupper $port] $global] != -1} {
	  set port_type$i global
	  break
	}
      }

      incr i
    }

    set no_ports $i

  } elseif {$remake_this != ""} {
    set icon $remake_this

    # find the ports

    # save where we were
    set save_cell [api_current_cell]
    set save_hierarchy [api_cell_hierarchy]

    api_goto_cell ICON_$icon

    set left_ports ""
    set right_ports ""
    set top_ports ""
    set bottom_ports ""

    # get existing spice line if exists
    set spice_ports ""
    foreach id [api_types text] {
      set text [api_get_data $id text]
      if {[string first "-type fixed -name spice" $text] == 0} {
	# got it
	set spice_ports [lrange [lindex $text 5] 3 end]
	break
      }
    }

    regsub -all "\{|\}|\\\$" $spice_ports "" spice_ports
    # remove icon type at end
    set spice_ports [lrange $spice_ports 0 [expr [llength $spice_ports] - 2]]
    set spice_ports [string toupper $spice_ports]
    set i [llength $spice_ports]

    # figure out port sides based on orient only -- could be wrong
    api_select input "" 1
    api_select output add 1
    api_select inout add 1
    foreach id [concat [api_instances selected]] {

      set orient [api_instance_data $id orient]
      set type [api_instance_data $id type]

      set port "[api_instance_data $id _name] $type [api_instance_data $id origin]"

      switch $type {
	input {
	  switch $orient {
	    RX - RXY { lappend right_ports $port }
	    R90 - R90X { lappend top_ports $port }
	    R270 - R90Y { lappend bottom_ports $port }
	    default { lappend left_ports $port }
	  }
	}
	output - input {
	  switch $orient {
	    R0 - RY { lappend right_ports $port }
	    R90 - R90X { lappend bottom_ports $port }
	    R270 - R90Y { lappend top_ports $port }
	    default { lappend left_ports $port }
	  }
	}
      }
    }

    set j 0
    foreach name $spice_ports {
      set port$j $name
      set port_type$j global
      set port_side$j left
      incr j
    }

    # now save away sorted
    set i [llength $spice_ports]
    foreach side "left right top bottom" {
      foreach port [lsort -real -index 2 [set ${side}_ports]] {
	set name [lindex $port 0]
	if {[set j [lsearch $spice_ports [string toupper $name]]] == -1} {
	  # not found, add
	  set j [incr i]
	}

	set port$j $name
	set port_type$j [lindex $port 1]
	set port_side$j $side
      }
    }

    set no_ports $i

    # find any extra properties
    foreach id [api_types text] {
      set prop [string trim [api_get_data $id text]]

      if {[string index $prop 0] == "-"} {
	# property
	call_keyword $prop {{type ""} {name ""} {default ""}}
	
	if {$type == "user" && [lsearch -exact $props "-$name"] == -1} {
	  lappend props -$name $default
	}
      }
    }

    api_select_ids ""

    # return to where we were
    api_goto_cell $save_cell
    api_cell_hierarchy $save_hierarchy

  } else {
    # nothing

    set icon ""

    set i 0
    foreach port "" {
      set port$i ""
      set port_type$i input
      set port_side$i left
      incr i
    }

    set no_ports $i
  }

  set prop_list ""

  lappend prop_list [list "Name" icon \
			 -filename [list -pattern $SPICE_ICON_CREATOR(suffix)] \
			 -return 2 \
			 -width 40 \
			 -help "Name of Icon.  Can include a full pathname.  For example: myicon  or  /home/myname/mydir/myicon.  NOTE: port order must be preserved for spice calls -- don't change."]

  for {set i 0} {$i < $no_ports} {incr i} {
    lappend prop_list [list "Port $i" port$i -entry]
  }

  lappend prop_list [list "Properties" props -entry \
			 -help "Additional user properties for the icon and defaults added in the form: -<prop_name> <default_value> ..."]

  set name_net 0
  lappend prop_list [list "Add Name Nets" name_net -binary \
			-help "If true, adds a name_net_s icon over the port with the same name.  Also replaces any existing."]

  # goto next column
  lappend prop_list [list "" "" -break 20]
  lappend prop_list [list "" "" -label ""]

  for {set i 0} {$i < $no_ports} {incr i} {
    lappend prop_list [list type port_type$i \
			   -choice {input output inout global}]
  }

  lappend prop_list [list "" "" -label ""]

  # goto next column
  lappend prop_list [list "" "" -break 20]

  # get icons in current schematic as possibilities
  foreach id [api_instances] {
    if {[api_instance_data $id generator] == 1} {
      # ignore generators -- can't change them
      continue
    }

    set type [api_instance_data $id type]

    if {![catch {api_instance_type_data $type _primitive} msg] && $msg == 1} {
      # ignore primitives
      continue
    }

    set icon_array($type) 1
  }

  # goto next column
#  lappend prop_list [list "" "" -break 20]

  set remake ""
  lappend prop_list [list "Remake" remake -binary -return 2]

  for {set i 0} {$i < $no_ports} {incr i} {
    lappend prop_list [list side port_side$i \
			   -choice {left right top bottom}]
  }

  lappend prop_list [list "" "" -label ""]

  # create the menu
  if {![set return [prop_menu2 -message $message -title $title $prop_list]]} {
    # cancelled
    return ""
  }

  if {$icon == ""} {
    puts "Aborted: no icon given."
    return
  }

  if {$return == 2} {
    spice_icon_creator $icon $drop
    return
  }

  # replace spaces with underscores
  regsub -all " " $icon "_" icon

  set path $icon
  set icon [file rootname [file tail $icon]]

  set undo_me 0
  if {$remake_this != "" && $name_net} {
    api_select $icon "" 1

    # toast any old name nets directly on top of ports
    set ids ""
    foreach id [api_instances selected] {
      set orient [api_instance_data $id orient]
      setl {x y} [api_instance_data $id origin]

      foreach term [api_terminal_data $icon] {
	set name [lindex $term 0]
	setl {tx ty} [api_orient_transform $orient \
			  [get_assoc origin [lindex $term 1]]]

	foreach pair [api_overlap_ports [list [expr $x + $tx] [expr $y + $ty]]] {
	  setl {_id _name} $pair
	  if {$_id != $id && $_name == $name && \
		  [lsearch "name_net name_net_s name_net_sw" \
		       [api_instance_data $_id type]] != -1} {
	    # toast this name net
	    lappend ids $_id
	  }
	}
      }
    }

    if {[llength $ids] > 0} {
      api_delete $ids
      set undo_me 1
    }
  }

  # save where we were
  set save_cell [api_current_cell]
  set save_hierarchy [api_cell_hierarchy]

  # first try going to cell
  if {[api_goto_cell ICON_$icon]} {
    # already exists, warn user
    set button [tk_dialog .warning "Cell Exists" \
		    "Cell \"$icon\" already exists.  Replace?" \
		    "" 0 {Cancel} {Replace}]

    if {$button == 0} {
      # user hit the cancel key

      # return to where we were to place the cell 
      api_goto_cell $save_cell
      api_cell_hierarchy $save_hierarchy

      if {$undo_me} {
	# put name nets back
	api_undo
      }

      return
    }

    # toast this guy
    api_delete_buffer ICON_$icon
  }

  # make the new icon

  # we will deal with the default user properties ourselves
  set save_DEFAULT_PROPERTIES $DEFAULT_PROPERTIES
  set DEFAULT_PROPERTIES $other_props

  api_new_cell $path I

  # restore
  set DEFAULT_PROPERTIES $save_DEFAULT_PROPERTIES

  api_zoom setup

  # place name of cell in center of icon
  make_text -origin "0 0" -text $icon -anchor c

  # assumes that a character is the width of a grid
  set min_width [string length $icon]
  set min_height 2

  # number of ports on each side
  set left 0
  set right 0
  set top 0
  set bottom 0

  # number of characters to leave room for in icon
  set left_chars 2
  set right_chars 2
  set top_chars 2
  set bottom_chars 2

  set spice "\[unique_name X \$name\]"

  set ports ""
  for {set i 0} {$i < $no_ports} {incr i} {
    if {[set port$i] == ""} {
      continue
    }
      
    if {[set port_type$i] != "global"} {
      # here's one
      lappend ports [list [set port$i] [set port_type$i] [set port_side$i]]

      incr [set port_side$i]

      set [set port_side$i]_chars \
	  [max [set [set port_side$i]_chars] [string length [set port$i]]]

      # make spice line -- same order as here
      lappend spice \$[set port$i]

    } else {
      # global
      # make spice line -- same order as here
      lappend spice [set port$i]
    }
  }

  lappend spice $icon
  regsub -all "\{|\}" $spice "" spice

  set height [expr [max $left $right $min_height] + $top_chars + $bottom_chars]
  set width [expr [max $top $bottom $min_width] + $left_chars + $right_chars]

  # should be divisible by 2
  set height2 [expr round( ($height + 1) / 2.0) * 20]
  set width2 [expr round( ($width + 1) / 2.0) * 20]

  # make the bounding box
  make_line -$width2 -$height2 $width2 -$height2 \
      $width2 $height2 -$width2 $height2 -$width2 -$height2

  # put in the ports
  set left_pos [expr 20 * ($top_chars + 1) - $height2]
  set right_pos [expr 20 * ($top_chars + 1) - $height2]
  set top_pos [expr 20 * ($left_chars + 1) - $width2]
  set bottom_pos [expr 20 * ($left_chars + 1) - $width2]

  foreach port $ports {
    setl {name type side} $port

    if {$type == "ignore"} {
      # don't put into icon
      continue
    }

    # replace spaces with underscores
    regsub -all " " $name "_" name

    # save side for name_nets
    set save_side($name) $side

    switch $side {
      left {
	if {$type == "input"} {
	  set orient R0
	} else {
	  set orient RX
	}

	make $type -name $name -origin [list -$width2 $left_pos] \
	    -orient $orient
	make_text -text $name -origin [list [expr -$width2 + 10] $left_pos] \
	    -anchor w

	set left_pos [expr $left_pos + 20]
      }

      right {
	if {$type == "input"} {
	  set orient RX
	} else {
	  set orient R0
	}

	make $type -name $name -origin [list $width2 $right_pos] \
	    -orient $orient
	make_text -text $name -origin [list [expr $width2 - 10] $right_pos] \
	    -anchor e

	set right_pos [expr $right_pos + 20]
      }

      top {
	if {$type == "input"} {
	  set orient R90
	} else {
	  set orient R90Y
	}

	make $type -name $name -origin [list $top_pos -$height2] \
	    -orient $orient
	make_text -text $name -origin [list $top_pos [expr -$height2 + 10]] \
	    -anchor w -rotate 1

	set top_pos [expr $top_pos + 20]
      }

      bottom {
	if {$type == "input"} {
	  set orient R90Y
	} else {
	  set orient R90
	}

	make $type -name $name -origin [list $bottom_pos $height2] \
	    -orient $orient
	make_text -text $name -origin [list $bottom_pos [expr $height2 - 10]] \
	    -anchor e -rotate 1

	set bottom_pos [expr $bottom_pos + 20]
      }
    }
  }

  set y_offset [expr $height2 + 100]
  set dy 20 
  # add any properties
  set i 0
  while {1} {
    setl {prop_name prop_value} [lrange $props $i [expr $i+1]]

    if {$prop_name == ""} {
      break
    }

    set prop_name [string trimleft $prop_name -]

    # add the property
    if {$prop_value != ""} {
      make_text -origin "-$width2 [incr y_offset $dy]" -text "-type user -name $prop_name -default $prop_value"
    } else {
      make_text -origin "-$width2 [incr y_offset $dy]" -text "-type user -name $prop_name"
    }

    incr i 2
  }

  # add the spice property
  incr y_offset $dy
  incr y_offset $dy
  incr y_offset $dy
  make_text -origin "-$width2 $y_offset" -text "-type fixed -name spice -text \{$spice\}"

  # add the verilog property
  incr y_offset $dy
  incr y_offset $dy
  incr y_offset $dy
  make_text -origin "-$width2 $y_offset" -text [api_verilog_property]

  api_modify_cell
  api_zoom fit

  # return to where we were to place the cell 
  api_goto_cell $save_cell
  api_cell_hierarchy $save_hierarchy

  api_zoom setup

  # put the cell down
  if {$remake_this != $icon && [string toupper [file root [file tail $remake_this]]] != [string toupper $icon] || $drop} {
    setl {x1 y1 x2 y2} [api_bbox]
    if {$y2 == ""} {
      # nothing here yet
      setl {x1 y1 x2 y2} "0 0 0 0"
    }

    api_select_ids [api_make $icon -origin [list [expr $x1 - $width2 - 100] \
				[expr round(($y2 + $y1) / 20.0) * 10]]]

  } else {
    # just select it
    api_select $icon "" 1
  }

  # add name_nets if specified
  if {$name_net} {
    foreach id [api_instances selected] {
      set orient [api_instance_data $id orient]
      setl {x y} [api_instance_data $id origin]

      if {[lsearch "R90 R90X R90Y R270" $orient] != -1} {
	set rotated 1
      } else {
	set rotated 0
      }

      foreach term [api_terminal_data $icon] {
	setl {tx ty} [api_orient_transform $orient \
			  [get_assoc origin [lindex $term 1]]]

	set name [lindex $term 0]
	switch $save_side($name) {
	  left - right { 
	    if {$rotated} {
	      set n_orient R90
	    } else {
	      set n_orient R0
	    }
	  }
	  top - bottom {
	    if {$rotated} {
	      set n_orient R0
	    } else {
	      set n_orient R90
	    }
	  }
	}
	
	lappend ids [api_make name_net_s -name $name -orient $n_orient \
			 -origin [list [expr $x + $tx] [expr $y + $ty]]]
      }

      api_select_ids $ids add
    }
  }

  api_zoom selected
  api_zoom 0.5

puts "Icon \"$icon\" created with filename \"[api_cell_info ICON_$icon filename]\"."

  return 1
}


proc parse_spice_file {filename} -desc {
  parse a spice file, looking for a subckt definition.  Returns name and
  ports in subckt definition.
} {

  # open file for reading
  if {[catch "open $filename r" FILE_ID]} {
    # problem
    warning "Warning: $FILE_ID"
    return ""
  } 

  set data ""

  set cont 0
  while {[gets $FILE_ID line] >= 0} {
    if {$cont} {
      # look for continuation lines
      if {[string index [string trimleft $line] 0] == "+"} {      
	if {[set pos [string first \$ $line]] > -1} {
	  # toast dollar comments
	  set line [string range $line 0 [expr pos - 1]]
	}
	
	set line [string trim [string range $line 1 end]]
	set data [concat $data $line]

	# look again
	continue

      } else {
	break
      }
    }

    if {[string toupper [string range [string trimleft $line] 0 6]] == ".SUBCKT"} {
      # found the subckt definition
      # TODO check that it is the correct cell def -- for now just finds
      # the first one.

      if {[set pos [string first \$ $line]] > -1} {
	# toast dollar comments
	set line [string range $line 0 [expr pos - 1]]
      }

      set data [lrange $line 1 end]
      set cont 1
    }
  }

  # close the file
  close $FILE_ID

  return $data
}



# source ~/dev/tcl/spice_icon_creator.tcl ; spice_icon_creator


