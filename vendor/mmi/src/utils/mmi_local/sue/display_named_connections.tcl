
# displays flylines between all same named name_nets in a schematic

menu_add -menu local -label "Display Named Connections" \
    -command display_named_connections \
    -help "Annotates the connections between like named name_nets and I/O's in the current schematic.  If nothing is selected, show all connections, otherwise only show connections to selected."


proc display_named_connections {} -desc {

  displays flylines between all same named name_nets in a schematic.
  Also between duplicate I/O's and between name_nets and I/O's.
  Note: doesn't do globals.

  For performance reasons doesn't check if connected by net.

} {

  global COLORS

  api_zoom setup

  api_generate_term_names

  # save away what's selected
  foreach id [api_instances selected] {
    set selected($id) 1
  }

  # clear selection
  api_select_ids ""

  # walk thru each name net and i/o
  foreach thing "name_net name_net_s name_net_sw input output inout" {
    api_select $thing add 1
  }

  foreach id [api_instances selected] {

    # get this thing's name
    set name [api_instance_data $id netlist_name]

    if {[bus_root [api_instance_data $id _name]] == ""} {
      # ignore [3] since must be connected by net
      continue
    }

    # do it bit by bit.  
    foreach one [cbus_expand $name] {
      lappend names($one) $id
    }
  }

  # clear selection
  api_select_ids ""

  # ignore constants
  catch {unset names(1'b0)}
  catch {unset names(1'b1)}

  # now look for dupes
  foreach name [array name names] {
    if {[llength $names($name)] == 1} {
      # ignore
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

    # if multiple, tie the first found to all the others -- not optimal
    set first [lindex $names($name) 0]
    foreach last [lrange $names($name) 1 end] {

      api_annotate_line -coords "[api_instance_data $first origin] [api_instance_data $last origin]" \
	  -color $COLORS(stroke_box)
    }
  }

  if {[info exists selected]} {
    select_ids [array names selected] add
  }

  api_zoom restore

  puts "done"
}
