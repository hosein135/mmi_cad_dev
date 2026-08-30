# This replaces the normal sue cross-probe hotkey.
menu_add -menu sim -label "Max Cross Probe" \
  -hotkey k -command max_cross_probe_any

proc from_max_cross_probe_init {max_win type} -desc {
  Called from max when someone hits "Cross Probe Init" in max.
} {
  global MAX_CROSS_PROBE_TYPE MAX_CROSS_PROBE_ID
  set MAX_CROSS_PROBE_TYPE $type
  set MAX_CROSS_PROBE_ID $max_win

  puts "cross_probe_init $type"
  switch -- $type {
    by_name {
      # Change to verilog mode and netlist.
      # Is this really necessary?
      global NETLIST_TYPE NETLIST_PROPS
      set NETLIST_TYPE verilog
      set NETLIST_PROPS verilog
      api_change_simulation_mode
    }
    gemini {
      # This returns the name of the sim file to max.
      return [cross_probe_setup]
    }
  }
}

proc from_max_cross_probe_cell {parent cell} -desc {
  Called from max to cross probe a cell.  Parent is parent schematic to load.
} {
  puts "cross_probe_cell $parent $cell"
  set old [api_current_cell]
  set old_hier [api_cell_hierarchy]
  api_goto_cell $parent
  if {$old != $parent} {
    api_cell_hierarchy [concat [list $old] $old_hier]
  }
  # This is catch-ed because it is not implemented in older versions of sue.
  catch {api_generate_inst_names}
  api_select ""  ;# clear selection
  select_by_name $cell noninteractive
}


proc from_max_set_prop {parent cell propname value} -desc {
  Called from max to change a property on a cell.
} {
  puts "from_max_set_prop $parent $cell $propname $value"

  busy
  api_goto_cell $parent
  catch {api_generate_inst_names}
  api_select ""   ;# clear selection
  select_by_name $cell noninteractive

  set inst_list [api_instances selected]
  if {[llength $inst_list] == 0} {
    puts "error: could not find instance $cell"
  } else {
    api_change_prop $inst_list $propname $value
  }

  ready
}

proc from_max_cross_probe_net {parent net} -desc {
  Called from max to cross probe a net.  Parent is parent schematic to load.
} {
  puts "cross_probe_net $parent $net"
  set old [api_current_cell]
  set old_hier [api_cell_hierarchy]
  api_goto_cell $parent
  if {$old != $parent} {
    api_cell_hierarchy [concat [list $old] $old_hier]
  }
  api_generate_term_names
  select_wire_by_name $net
}

proc max_cross_probe_init_verilog {{max_win ""}} -desc {
  Called from sue menu to set cross probe type to floorplanner.
} -doc {
  If max_win is given, use it as the copy max we will cross probe.
  Max provides this argument if it starts sue for cross probing.
} {
  global global MAX_CROSS_PROBE_TYPE MAX_CROSS_PROBE_ID
  set MAX_CROSS_PROBE_TYPE by_name

  puts "Max Cross Probe Init..."
  #kludge_keys

  # Change to verilog mode and netlist.
  # Is this really necessary?
  global NETLIST_TYPE NETLIST_PROPS
  set NETLIST_TYPE verilog
  set NETLIST_PROPS verilog
  api_change_simulation_mode
  # 7/30/01 change: Dont need the full netlist, only need the net
  # names in the current schematic, so use api_generate_term_names
  # instead of api_netlist, and do it on demand when cross probe
  # is requested.  This does not currently generate
  # names for instances, but if the schematic came from verilog,
  # it should already have those anyway.
  # api_netlist


  # Start max if it is not running.

  if {$max_win != ""} {
    set MAX_CROSS_PROBE_ID $max_win
  } else {
    set max_win [pats_check_max -start]
    if {$max_win == ""} {
      puts  "cross probe cancelled"
      return ;# cancelled
    } else {
      set MAX_CROSS_PROBE_ID $max_win
    }
  }

  # Send max our window name and the cross probe type.
  send $max_win from_sue_cross_probe_init [list [winfo name .]] $MAX_CROSS_PROBE_TYPE
}



# This is needed, so user can set PROBE_DISPLAY
# in their .suerc file or in the sue window.
proc _misc_get_probe_display {} {
  global env PROBE_DISPLAY
  set probe [use_first PROBE_DISPLAY env(PROBE_DISPLAY) env(DISPLAY) ':0]

  # Remove leading "-display", if any.
  if {[string range $probe 0 7] == "-display"} {
    set probe [string range $probe 8 end]
  }
  set probe [string trim $probe]

  if {$probe == "other"} {
    # deals with dots in the computer name, e.g.: mmi21.foo.com:0.1
    regexp {^(.*):(.*)$} [winfo screen .] junk display screen
    set parts [split $screen .]
    return " $display:[lindex $parts 0].[expr 1 - [lindex $parts 1]]"
  }

  return $probe
}



proc pats_check_max {args} -desc {
  Syntax: [-start] [max_win]
  Version of check_max that looks for executable: maxx or maxy or max
  Start max if not already running.  Return "" on failure.
} {

  if {[set start [expr {[lindex $args 0] == "-start"}]]} {
    set args [lrange $args 1 end]
  }
  set max_win [lindex $args 0]
  
  if {$max_win != ""} {
    # See if this specific window is still running.
    if {[catch {send $max_win {#}}]} {
      return ""
    } else {
      return $max_win  ;# Still running
    }
  }

  set possible_maxes ""
  foreach interp [winfo interps] {
    if {[string match max* $interp]} {
      lappend possible_maxes $interp
    }
  }

  set max_list $possible_maxes

  if {! $start} {
    # Just return name of existing max window,
    # but error out if there are two.
    if {[llength $max_list] > 1} {
      puts "Warning: multiple max are running"
      return ""
    }
    return [lindex [lindex $max_list 0] 0]
  }

  # If max is not running, start one.

  set prop_list ""
  lappend max_list "Start a new copy of max"
  set use_max [lindex $max_list 0]
  lappend prop_list [list "Which max" use_max -radio $max_list]

  global PROBE_DISPLAY env
  set display [_misc_get_probe_display]

  lappend prop_list [list "X display for new max" display -entry]
  set max_name maxy
  lappend prop_list [list "max executable" max_name -entry]

  if {![prop_menu2 -title "Cross Probe max" $prop_list]} {
    return ""  ;# cancelled
  }

  if {$use_max == "Start a new copy of max"} {
    global PROJECT env
    set project [use_first PROJECT env(PROJECT)]
    if {$project != ""} {set env(PROJECT) $project}

    # Fire up a new max.
    set cmd "xterm -sb -sl 1000 -display $display -T {Max Terminal}"
    append cmd " -e $max_name"

    # Tell max what sue it is supposed to be hooked to.
    # Carefully quote for shell because winfo name may contain spaces.
    append cmd " -set \"SUE_CROSS_PROBE_ID=[winfo name .]\""


    # Figure out the technology to use.
    global env
    set tech [use_first env(MAX_DEFAULT_TECH)]
    if {$tech == ""} {
	msg "cross_probe_init: No MAX_DEFAULT_TECH specified, using tech mmi15-fplan\n"
    }
    # Append -fplan if technology does not have it.
    if {[string first "-" $tech] == -1} {
	append cmd " -tech ${tech}-fplan"
    } elseif {[string first "-flan" $tech] == -1} {
	# Technology has some other variation.
	# Use existing technology; call fplan_init to get the fplan menu up.
	append cmd " -tech $tech -command fplan_init"
    } else {
	# Technology already includes -fplan variation.  Use it.
	append cmd " -tech $tech"
    }

    # Tell max to try to load this cell.
    append cmd " [api_current_cell]"

    # environment variable: MAX_DEFAULT_TECH
    puts "$cmd"
    eval exec $cmd &

    # Now we wait for it to start.
    # It will be a max interpreter that was not in the possible_maxes list.
    # If it doesnt start in 10 seconds, give up.
    # Note: the timeout is waiting for max to exist.
    # After max exists, the send will wait until its initialization is
    # complete before returning.
    busy
    set max ""
    for {set i 0} {$max=="" && $i < 10} {incr i} {
      foreach trymax [winfo interps] {
	if {! [string match max* $trymax]} {continue}
	if {[lsearch -exact possible_maxes $trymax] != -1} {continue}
	if {![catch {send $trymax "use_first SUE_CROSS_PROBE_ID"} result]} {
	  if {$result == [winfo name .]} {
	    set max $trymax  ;# Found it
	    break
	  }
	}
      }
      after 1000 ;# Wait a second.
    }
    ready

    if {$max == ""} {
      error "Error: Timeout waiting for max to start"
    }

  } else {
    set max $use_max
  }

  return $max
}


proc max_cross_probe_any {} -desc {
    Called to cross probe from sue to max.
} {
  global MAX_CROSS_PROBE_TYPE MAX_CROSS_PROBE_ID

  switch -- [use_first MAX_CROSS_PROBE_TYPE] {
    "" {
      puts "Cross probe not initialized"
      return
    }
    by_name {
      return [max_cross_probe_verilog]
    }
    gemini {
      return [max_cross_probe]
    }
    default {
      puts "error: Unrecognized cross probe type: $MAX_CROSS_PROBE_TYPE"
      return
    }
  }
}


proc max_cross_probe_verilog {} -desc {
  Cross probe from sue to max in verilog mode
} {
  global MAX_CROSS_PROBE_ID
  if {[use_first MAX_CROSS_PROBE_ID] == ""} {
    error "Cross probe not initialized"
  }

  if {[set max [pats_check_max $MAX_CROSS_PROBE_ID]] == ""} {
    puts "cross probe: Cant find max!"
    return
  }

  # This is the schematic we are editing.
  set sue_cell [api_current_cell]

  api_generate_term_names
  # This is catched because the proc is new and not in all maxes yet.
  catch {api_generate_inst_names}

  set cell [lindex [api_instances selected] 0]
  if {$cell != ""} {
    # Check to see if it is really a port.
    switch -glob -- [api_instance_data $cell type] {
      input -
      output -
      inout -
      name_net* -
      bus_* {
	set cell ""  ;# This is not a cell!
      }
    }
  }

  if {$cell != ""} {
    set cell_name [api_instance_data $cell netlist_name]
    if {$cell_name == ""} {

      # No netlist_name, meaning the cell has not been verilog netlisted.
      # If the cell came from verilog, the call name will have been specified,
      # or the user could type one in, in which case, THAT is the name
      # used in the netlist (UNLESS THERE ARE CONFLICTS).  So use
      # the name.
      #
      # NOTE: Lee may provide an alternate way to get
      # the netlist name in the future, provided by a function
      # similar to api_generate_term_names.
      # At least, I requested it on 7/30/01.
      set cell_name [api_instance_data $cell _name]

      # Sue allows you to specify a name as just [7:0], for example.
      # This is not a valid netlist name, so just ignore it.
      if {$cell_name == "" || [string index $cell_name 0] == {[}} {
	puts "cross probe: No name for selected object, or not verilog netlisted yet!"
	return
      }
    }
    send $max _cross_probe_cell -cell $sue_cell [list $cell_name]
  } elseif {[set net [display_local_net]] != ""} {
    send $max _cross_probe_net -cell $sue_cell [list $net]
  } else {
    puts "warning: cross probe: nothing selected!"
  }
}

proc fplan_sue_dump {} -desc {
  Set up sue, and dump the current schematic to a file.
  Info can then be read in by floorplanner.
} {
  # Change to verilog mode and netlist.  Again.
  # This is not right, because we should netlist from the
  # top level cell to get all names that same as in previous
  # netlists, but this at least gives the floorplanner some
  # verilog to read in.
  global NETLIST NETLIST_TYPE NETLIST_PROPS NETLIST_LEVEL
  global MAX_CROSS_PROBE_ID NO_HIER_DEMORGAN

  busy

  set NETLIST_TYPE verilog
  set NETLIST_PROPS verilog
  set NETLIST(no_header) 1
  api_change_simulation_mode

  # 7/30/01 change: Dont need the full netlist, only need the net
  # names in the current schematic, so use api_generate_term_names
  # instead of api_netlist.  This does not currently generate
  # names for instances, but if the schematic came from verilog,
  # it should already have those anyway.
  puts "chipper dump: generating term names"
  api_generate_term_names
  catch {api_generate_inst_names}

  set cell [get_assoc filename [api_cell_info]]
  if {[string match *.sue $cell]} {set cell [file rootname $cell]}
  set filename ${cell}.suedump

  set fd [open $filename "w"]
  puts "chipper dump: writing $filename"

  foreach id [api_instances] {
      set props [api_get_data $id]
      lappend props [list sue_id $id]
      set type [get_assoc type $props]
      if {$type == $cell} {
	  # If a schematic contains a copy of its own icon, ignore it.
	  continue
      }
      lappend props [list terminals [api_terminal_data $type]]
      #set ignore 0
      #foreach ignore_type $PAT(ignore_types) {
      #    if {[string match $ignore_type $type]} {set ignore 1; break}
      #}
      #if {$ignore} continue
      puts $fd $props
  }

  close $fd

  # Generate a verilog netlist for this level only.
  # By default, goes in same dir as schematic with .vh suffix.
  set save [use_first NETLIST_LEVEL(__CURRENT__)]
  set NETLIST_LEVEL(__CURRENT__) 999999
  set NO_HIER_DEMORGAN 1
  api_netlist
  if {$save != ""} {set NETLIST_LEVEL(__CURRENT__) $save}

  # The verilog netlister prints its own message when it starts up.

  # If we are cross probing, try to pop up the window in max.
  if {[use_first MAX_CROSS_PROBE_ID] != ""} {
    set max_win [pats_check_max $MAX_CROSS_PROBE_ID]
    if {$max_win != ""} {
      send -async $max_win "fplan_read_sue -menu 1 $filename"
    }
  }

  ready
}

proc UNUSED_kludge_keys {} {
  global WIN_DATA WIN

  # Make sure the hot-key k is hooked to the new cross-probe command.
  # This should go away when this is integrated into sue.

  set menulabel "Chip Cross Probe"
  # Temporary: Just blast the new hotkey into sue.
  set trimlabel [join $menulabel _]
  set MENUS(HOTKEY,$trimlabel) $hotkey
  set WIN_DATA($WIN,keys,k) [list launch max_cross_probe_any]
  update_bindings
}
