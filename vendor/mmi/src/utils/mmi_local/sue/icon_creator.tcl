
# pops up a window with options to create an icon and create it.

menu_add -menu local -label "Icon Creator" \
    -command icon_creator \
    -help "Automatically creates an icon and places it in the current schematic from the given ports."


# defaults

set ICON_CREATOR(arrival) 1ns
set ICON_CREATOR(departure) 1ns
set ICON_CREATOR(input_port) MMI_FFB:d
set ICON_CREATOR(output_port) MMI_BUFE:out


proc icon_creator {{remake_this ""}} -desc {

  pops up a window with options to create an icon and create it.

} {

  global DEFAULT_PROPERTIES ICON_CREATOR

  set title "Icon Creator"
  set message "Enter icon name and ports:"

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

  set no_ports 25

  if {$remake_this == ""} {
    set id [api_instances selected]
    if {[llength $id] == 1 && \
	    [api_instance_data $id generator] != 1} {
      set type [api_instance_data $id type]

      if {![catch {api_instance_type_data $type _primitive} msg] && $msg == 1} {
	# ignore primitives
      } else {
	set remake_this $type
      }
    }
  }

  if {$remake_this != ""} {
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

    # now save away sorted
    set i 0
    foreach port [lsort -real -index 2 $left_ports] {
      set port$i [lindex $port 0]
      set port_type$i [lindex $port 1]
      set port_side$i left
      incr i
    }
    foreach port [lsort -real -index 3 $right_ports] {
      set port$i [lindex $port 0]
      set port_type$i [lindex $port 1]
      set port_side$i right
      incr i
    }
    foreach port [lsort -real -index 3 $top_ports] {
      set port$i [lindex $port 0]
      set port_type$i [lindex $port 1]
      set port_side$i top
      incr i
    }
    foreach port [lsort -real -index 3 $bottom_ports] {
      set port$i [lindex $port 0]
      set port_type$i [lindex $port 1]
      set port_side$i bottom
      incr i
    }

    if {$i >= $no_ports} {
      set no_ports $i
    } else {
      for {} {$i < $no_ports} {incr i} {
	set port$i ""
	set port_type$i input
	set port_side$i left
      }
    }

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
    # start from scratch
    set icon ""

    for {set i 0} {$i < $no_ports} {incr i} {
      set port$i ""
      set port_type$i input
      set port_side$i left
    }
  }

  set prop_list ""

  lappend prop_list [list "Name" icon -entry -width 40 \
			 -help "Name of Icon.  Can include a full pathname.  For example: myicon  or  /home/myname/mydir/myicon."]

  for {set i 0} {$i < $no_ports} {incr i} {
    lappend prop_list [list "Port $i" port$i -entry]
  }

  lappend prop_list [list "Properties" props -entry \
			 -help "Additional user properties for the icon and defaults added in the form: -<prop_name> <default_value> ..."]

  set lib 0
  lappend prop_list [list "Make Lib file" lib -binary \
			-help "If true, creates a synopsys .lib timing model.  Moves existing to .BAK."]

  set verilog_stub 0
  lappend prop_list [list "Make Verilog Stub" verilog_stub -binary \
			-help "If true, creates a verilog stub for the icon in the same directory.  Moves existing to .BAK."]

  set name_net 0
  lappend prop_list [list "Add Name Nets" name_net -binary \
			-help "If true, adds a name_net_s icon over the port with the same name.  Also replaces any existing."]

  # goto next column
  lappend prop_list [list "" "" -break 20]
  lappend prop_list [list "" "" -label ""]

  for {set i 0} {$i < $no_ports} {incr i} {
    lappend prop_list [list type port_type$i \
			   -choice {input output inout}]
  }

  lappend prop_list [list "" "" -label ""]

  lappend prop_list [list "arrival" ICON_CREATOR(arrival) -entry \
			 -help "Additional arrival time delay on inputs in .lib model."]

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

  set icons "<<NEW>>"

#  foreach one [api_cells I] {
#    lappend icons [string range $one 5 end]
#  }

  foreach one [array names icon_array] {
    lappend icons $one
  }

  set remake ""
  lappend prop_list [list "ReMake" remake -choice $icons -return 2]

  for {set i 0} {$i < $no_ports} {incr i} {
    lappend prop_list [list side port_side$i \
			   -choice {left right top bottom}]
  }

  lappend prop_list [list "" "" -label ""]

  set departure 1ns
  lappend prop_list [list "departure" ICON_CREATOR(departure) -entry \
			 -help "Additional departure time delay on outputs in .lib model."]

  # create the menu
  if {![set return [prop_menu2 -message $message -title $title $prop_list]]} {
    # cancelled
    return ""
  }

  if {$return == 2} {
    # reload with a specific icon to remake
    if {$remake == "<<NEW>>"} {
      icon_creator
    } else {
      icon_creator $remake
    }

    return
  }

  # replace spaces with underscores
  regsub -all " " $icon "_" icon

  set path $icon
  set icon [file rootname [file tail $icon]]

  # TODO: button for more ports

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

  set ports ""
  for {set i 0} {$i < $no_ports} {incr i} {
    if {[set port$i] != ""} {
      # here's one
      lappend ports [list [set port$i] [set port_type$i] [set port_side$i]]

      incr [set port_side$i]

      set [set port_side$i]_chars \
	  [max [set [set port_side$i]_chars] [string length [set port$i]]]
    }
  }

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

  # add the verilog property
  incr y_offset $dy
  incr y_offset $dy
  incr y_offset $dy
  make_text -origin "-$width2 $y_offset" -text [api_verilog_property]

  api_modify_cell
  api_zoom fit

  if {$verilog_stub} {
    # write the verilog stub

    set file [file rootname [api_cell_info ICON_$icon filename]].vg
    set tofile $file.BAK

    if {![catch "file rename -force -- $file $tofile"]} {
      puts "Moved file \"$file\" to \"$tofile\"."
    }

    # open file
    if {[catch "open $file w" file_id] != 0} {
      # error, probably can't write to directory
      puts "Aborting writing verilog: $file_id"

    } else {
      # not quite an api call, but...
      puts $file_id [create_verilog_framework $icon]

      # close file
      close $file_id

      puts "Created verilog stub file \"$file\"."
    }
  }

  if {$lib} {
    # write the lib file

    set file [file rootname [api_cell_info ICON_$icon filename]].lib
    set tofile $file.BAK

    if {![catch "file rename -force -- $file $tofile"]} {
      puts "Moved file \"$file\" to \"$tofile\"."
    }

    # use speedy
    speedy new_design $icon

    foreach port $ports {
      setl {name type} $port

      if {$name != ""} {
	
	if {$type == "inout"} {
	  puts "Warning: changing port $name form type inout to input for lib file."
	  set type input
	}

	foreach bit [bus_expand $name] {

	  # note: speedy add_ext... takes values in ns.

	  switch $type {
	    input { 
	      speedy add_extconn_for_limited_icon_creator \
		  $bit $type $ICON_CREATOR(input_port) \
		  [expr [parse_pp_number $ICON_CREATOR(arrival)] * 1.0e9]
	    }

	    output { 
	      speedy add_extconn_for_limited_icon_creator \
		  $bit $type $ICON_CREATOR(output_port) \
		  [expr [parse_pp_number $ICON_CREATOR(departure)] * 1.0e9]
	    }
	  }
	}
      }
    }

    speedy write_libfile $file
  }

  # return to where we were to place the cell 
  api_goto_cell $save_cell
  api_cell_hierarchy $save_hierarchy

  api_zoom setup

  # put the cell down
  if {$remake_this != $icon} {
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


# source ~/dev/tcl/icon_creator.tcl ; icon_creator


