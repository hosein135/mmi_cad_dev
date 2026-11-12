# Local-menu commands. Sourced from the system .suerc while SUE is
# starting, before the window exists. menu_add holds the items until
# the menus are built.

# Write Verilog, SIM, SPICE, and DPC for the current cell, then put
# the previous simulation mode back. DPC uses the verilog properties,
# which is what Change Simulation Mode does.

proc netlist_all_modes {} {
  global NETLIST_TYPE NETLIST_PROPS

  set old_type $NETLIST_TYPE
  set old_props $NETLIST_PROPS
  set plan {{verilog verilog} {sim sim} {spice spice} {dpc verilog}}
  set wrote {}
  set failed {}

  foreach pair $plan {
    set NETLIST_TYPE [lindex $pair 0]
    set NETLIST_PROPS [lindex $pair 1]
    if {![api_change_simulation_mode]} {
      lappend failed $NETLIST_TYPE
      continue
    }
    set result ""
    if {[catch {set result [api_netlist]} msg]} {
      puts "Netlist $NETLIST_TYPE failed: $msg"
      lappend failed $NETLIST_TYPE
      continue
    }
    if {$result == ""} {
      puts "Netlist $NETLIST_TYPE failed."
      lappend failed $NETLIST_TYPE
    } else {
      puts "Wrote $NETLIST_TYPE netlist: $result"
      lappend wrote $NETLIST_TYPE
    }
  }

  set NETLIST_TYPE $old_type
  set NETLIST_PROPS $old_props
  api_change_simulation_mode

  puts "Netlist all modes wrote: [join $wrote {, }]"
  if {[llength $failed]} {
    puts "Netlist all modes failed: [join $failed {, }]"
  }
}

menu_add -menu local -label "Netlist All Modes" -command netlist_all_modes \
    -help "Write Verilog, SIM, SPICE, and DPC netlists for the current cell."


# Print every net name on the wires of the current schematic.

proc show_net_names {} {
  api_generate_term_names
  api_zoom setup

  foreach id [api_types wire] {
    set net [api_get_data $id net]
    if {$net == ""} {
      continue
    }
    set coords [api_get_data $id coords]
    if {$coords == ""} {
      continue
    }
    set origin [show_net_names_center $coords]
    set x [lindex $origin 0]
    set y [lindex $origin 1]

    set skip 0
    if {[info exists nearby($net,x,$x)]} {
      foreach ny $nearby($net,x,$x) {
        if {[expr {abs($ny - $y)}] < 100} {
          set skip 1
          break
        }
      }
    }
    if {$skip} {
      continue
    }
    lappend nearby($net,x,$x) $y

    if {[info exists nearby($net,y,$y)]} {
      foreach nx $nearby($net,y,$y) {
        if {[expr {abs($nx - $x)}] < 100} {
          set skip 1
          break
        }
      }
    }
    if {$skip} {
      continue
    }
    lappend nearby($net,y,$y) $x

    if {[lindex $coords 0] == [lindex $coords 2]} {
      api_annotate_text -text $net -anchor s -origin $origin -rotate 1
    } else {
      api_annotate_text -text $net -anchor s -origin $origin
    }
  }

  foreach id [api_instances] {
    set type [api_instance_data $id type]
    set origin [api_instance_data $id origin]
    set x [lindex $origin 0]
    set y [lindex $origin 1]

    foreach term_pair [api_terminal_data $type] {
      set term [lindex $term_pair 0]
      set assoc [lindex $term_pair 1]
      set net [api_netlist_data $id $term]
      if {$net == "" || $net == 0} {
        continue
      }
      set port [api_orient_transform [api_instance_data $id orient] \
          [get_assoc origin $assoc]]
      set coords [list [expr {$x + [lindex $port 0]}] \
          [expr {$y + [lindex $port 1]}]]

      set show 1
      foreach pair [api_overlap_ports $coords] {
        if {[llength [lindex $pair 1]] == 2} {
          set show 0
        }
      }
      if {$show} {
        api_annotate_text -text $net -anchor s -origin $coords
      }
    }
  }

  api_zoom restore
  puts "Showed net names."
}

proc show_net_names_center {coords} {
  return [list [expr {([lindex $coords 0] + [lindex $coords 2]) / 2}] \
      [expr {([lindex $coords 1] + [lindex $coords 3]) / 2}]]
}

menu_add -menu local -label "Show Net Names" -command show_net_names \
    -help "Annotate the net name on every wire in the current schematic."


# Flylines between name_nets and I/O ports that share a name.
# Globals are left out. A selection limits the drawing to nets that
# touch a selected instance.

proc show_named_connections {} {
  global COLORS

  api_zoom setup
  api_generate_term_names

  foreach id [api_instances selected] {
    set selected($id) 1
  }
  api_select_ids ""

  foreach thing "name_net name_net_s name_net_sw input output inout" {
    api_select $thing add 1
  }

  foreach id [api_instances selected] {
    set name [api_instance_data $id netlist_name]
    if {[bus_root [api_instance_data $id _name]] == ""} {
      continue
    }
    foreach one [cbus_expand $name] {
      lappend names($one) $id
    }
  }
  api_select_ids ""

  catch {unset names(1'b0)}
  catch {unset names(1'b1)}

  set drawn 0
  foreach name [array names names] {
    if {[llength $names($name)] < 2} {
      continue
    }
    if {[info exists selected]} {
      set skip 1
      foreach id $names($name) {
        if {[info exists selected($id)]} {
          set skip 0
          break
        }
      }
      if {$skip} {
        continue
      }
    }
    set first [lindex $names($name) 0]
    foreach last [lrange $names($name) 1 end] {
      api_annotate_line -coords "[api_instance_data $first origin] [api_instance_data $last origin]" \
          -color $COLORS(stroke_box)
      incr drawn
    }
  }

  if {[info exists selected]} {
    select_ids [array names selected] add
  }
  api_zoom restore
  puts "Drew $drawn named connections."
}

menu_add -menu local -label "Show Named Connections" \
    -command show_named_connections \
    -help "Draw flylines between name_nets and I/O ports that share a name. A selection limits the drawing to those instances."


# Select instances whose property name or value contains the text.
# Coordinates are not searched. Select by Name remains the search
# for net and instance names.

proc find_by_property {} {
  set term ""
  set prop_list [list [list "Property" term -entry \
      -help {Text matched against instance property names and values. W, L, model, and resistance are properties.}]]
  if {![prop_menu2 -title "Find Property" -message "Find instances by property:" \
      $prop_list]} {
    return
  }
  if {$term == ""} {
    puts "Find property: nothing to search for."
    return
  }

  set want [string tolower $term]
  set pattern "*$want*"
  api_select_ids ""
  set found {}

  foreach id [api_instances] {
    set hit 0
    foreach pair [api_instance_data $id] {
      set key [lindex $pair 0]
      if {$key == "origin" || $key == "bbox" || $key == "orient" || \
          $key == "generator"} {
        continue
      }
      regsub {^_} $key "" key
      set val [lindex $pair 1]
      if {[string match $pattern [string tolower $key]] || \
          [string match $pattern [string tolower $val]]} {
        set hit 1
        break
      }
    }
    if {$hit} {
      api_select_ids $id add
      lappend found $id
    }
  }

  puts "Find property \"$term\": [llength $found] instances."
  if {[llength $found]} {
    zoom_to_selected
  }
}

menu_add -menu local -label "Find Property" -command find_by_property \
    -help "Select instances whose property name or value contains the text. Coordinates are not searched."


# Select everything in the current cell whose data is not in another
# schematic. Position is part of the comparison.

proc compare_schematic {} {
  set other_cell [fs_box -message "Schematic to compare:" -pattern *.sue]
  if {$other_cell == ""} {
    return
  }

  set current_cell [api_current_cell]
  if {![api_goto_cell $other_cell]} {
    api_load_cell $other_cell
  }
  if {[api_current_cell] == $current_cell} {
    puts "Compare schematic: cannot open $other_cell"
    return
  }

  foreach id [compare_schematic_ids] {
    set data [api_get_data $id]
    set compare_other($data) 1
  }

  if {![api_goto_cell $current_cell]} {
    puts "Compare schematic: cannot return to $current_cell"
    return
  }

  api_select_ids ""
  set count 0
  foreach id [compare_schematic_ids] {
    set data [api_get_data $id]
    if {![info exists compare_other($data)]} {
      api_select_ids $id add
      incr count
    }
  }
  puts "Compare schematic: $count objects are not in $other_cell"
  if {$count} {
    zoom_to_selected
  }
}

proc compare_schematic_ids {} {
  set list ""
  foreach thing "instance wire line arc text dot open" {
    set list [concat $list [api_types $thing]]
  }
  return $list
}

menu_add -menu local -label "Compare Schematic" -command compare_schematic \
    -help "Open another schematic and select everything in this cell that is not in it."
