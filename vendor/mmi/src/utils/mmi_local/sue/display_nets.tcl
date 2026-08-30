
# displays all of the net names on the schematic

menu_add -menu local -label "Display Nets" -command display_nets \
	-help "Annotates the net names over the wires in the current schematic."


proc display_nets {} {

  # make sure this is done
  api_generate_term_names 

  api_zoom setup

  # annotate each wire
  foreach id [api_types wire] {

    set net [api_get_data $id net]
    if {$net == ""} {
      # no name, skip
      continue
    }

    set coords [api_get_data $id coords]
    if {$coords == ""} {
      continue
    }
    set origin [center_coords $coords]
    setl {x y} $origin

    set skip 0
    if {[info exists nearby($net,x,$x)]} {
      # don't show if nearby in y
      foreach ny $nearby($net,x,$x) {
	if {[expr abs($ny - $y)] < 100} {
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
      # don't show if nearby in x
      foreach nx $nearby($net,y,$y) {
	if {[expr abs($nx - $x)] < 100} {
	  set skip 1
	  break
	}
      }
    }

    if {$skip} {
      continue
    }
    lappend nearby($net,y,$y) $x

    # display name over wire
    if {[lindex $coords 0] == [lindex $coords 2]} {
      # vertical wire
      api_annotate_text -text $net -anchor s -origin $origin -rotate 1
    } else {
      api_annotate_text -text $net -anchor s -origin $origin
    }
  }

  # annotate ports that aren't attached to wires
  # can't just look for opens since two overlapping terminals have
  # no wire between them
  foreach id [api_instances] {
    set type [api_instance_data $id type]
    setl {x y} [api_instance_data $id origin]

    # walk thru the terminals of this type
    foreach list [api_terminal_data $type] {
      setl {term assoc} $list
      
      set net [api_netlist_data $id $term]

      if {$net == "" || $net == 0} {
	continue
      }

      # get position of port
      setl {xt yt} [api_orient_transform [api_instance_data $id orient] \
		      [get_assoc origin $assoc]]

      set coords [list [expr $x + $xt] [expr $y + $yt]]

      # don't display if there is a wire there
      set show 1
      foreach pair [api_overlap_ports $coords] {
	if {[llength [lindex $pair 1]] == 2} {
	  # wire
	  set show 0
	}
      }

      if {$show} {
	api_annotate_text -text $net -anchor s -origin $coords
      }
    }
  }

  api_zoom restore

  puts "done"
}


# Finds the center of the 4 coords.

proc center_coords {coords} {

  return [list [expr ([lindex $coords 0]+[lindex $coords 2])/2] \
	       [expr ([lindex $coords 1]+[lindex $coords 3])/2]]
}
