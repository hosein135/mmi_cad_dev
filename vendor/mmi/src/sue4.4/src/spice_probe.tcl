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


# routines to crossprobe spice schematics.

# file id of current probe.  This will set to "" if not defined.

set PROBE_ID [use_first PROBE_ID]

# default to 9601
set TR0_FORMAT [use_first TR0_FORMAT '9601]

# netlist current schematic, run spice-like simulator based on SPICE_TYPE
# variable, and initialize probe if successful.

proc spice_it {} {

  global cur_s SUE_DIR PROBE_STATUS NETLIST_TYPE SPICE_TYPE SPICE_TYPES env
  global SPICE_SUFFIX

  modify_setup spice_it

  # if not defined, assume spice.
  set SPICE_TYPE [use_first SPICE_TYPE 'spice]

  # make sure we have a valid SPICE_TYPE
  # these are the only valid ones
  set simulators "spice adm powermill intel"
  if {[lsearch $simulators $SPICE_TYPE] == -1} {
    warning "Aborting, Invalid simulator type \"$SPICE_TYPE\".  Valid supported simulators are \"$simulators\".  Change variable SPICE_TYPE in .suerc or \"Select Simulator\" in \"Sim\" menu."
    return
  }

  # netlist from this schematic
  set netlist_filename [netlist]

  if {$netlist_filename == ""} {
    sue_error "Aborting, can't run spice due to netlist errors."
    sue_error flush
    return
  }

  upvar #0 SUE_$cur_s data
  set dir $data(dir)
  
  # we are possibly going away for a long time here so
  update
  
  busy

  # push into directory of toplevel schematic for spicing
  set save_dir [pwd]
  cd $dir

  set SPICE_SUFFIX(current) \
      [use_first SPICE_SUFFIX(current) SPICE_SUFFIX($SPICE_TYPE)]

  # move the existing output data file if it exists to a backup
  # not used for powermill since nst doesn't read it
  switch $SPICE_TYPE {
    spice - adm {
      move_file_or_copy ${cur_s}$SPICE_SUFFIX(current) \
	  ${cur_s}$SPICE_SUFFIX(current)~
    }
    intel {
      move_file_or_copy ${cur_s}$INTEL_CORNER$SPICE_SUFFIX(current) \
	  ${cur_s}$INTEL_CORNER$SPICE_SUFFIX(current)~
      move_file_or_copy ${cur_s}.spo ${cur_s}.spo~
    }
  }
  set PROBE_STATUS new_sim

  set process_name [winfo name .]	
  regsub -all " " $process_name {\ } process_name
  regsub -all \# $process_name {\#} process_name

  # run appropriate script to start simulation.  Script needs to do a send
  # back to SUE to tell it when it is done and what the completion status
  # is.  This is usually done with a "callback".
  set mmi_local $env(MMI_LOCAL)
  set mmi_private [file nativename ~/mmi_private]

  switch $SPICE_TYPE {
    adm {
      # figure out what dir to get the adm script from
      if {[file exists $mmi_private/adm_go]} {
	set dir $mmi_private/sue
      } elseif {[file exists $mmi_local/sue/adm_go]} {
	set dir $mmi_local/sue
      } else {
	set dir $SUE_DIR
      }

      puts "Starting $dir/adm_go on file \"$netlist_filename\" ..."
      set error [catch "exec $dir/adm_go $netlist_filename -CALLBACK \"send $process_name spice_callback\" &" msg]
    } 

    spice - intel {
      # figure out what dir to get the spice script from
      if {[file exists $mmi_private/sue/spice]} {
	set dir $mmi_private/sue
      } elseif {[file exists $mmi_local/sue/spice]} {
	set dir $mmi_local/sue
      } else {
	set dir $SUE_DIR
      }

      puts "Starting $dir/spice on file \"$netlist_filename\" ..."
      set error [catch "exec $dir/spice $netlist_filename -CALLBACK \"send $process_name spice_callback\" &" msg]
    }

    powermill {
      # figure out what dir to get the powermill script from
      if {[file exists $mmi_private/sue/powermill_go]} {
	set dir $mmi_private/sue
      } elseif {[file exists $mmi_local/sue/powermill_go]} {
	set dir $mmi_local/sue
      } else {
	set dir $SUE_DIR
      }

      puts "Starting $dir/powermill_go on file \"$netlist_filename\" ..."
      set error [catch "exec $dir/powermill_go $netlist_filename -CALLBACK \"send $process_name spice_callback\" &" msg]
    }
  }

  # return to calling directory
  cd $save_dir

  if {$error != 0} {
    # error, probably can't find simulation script.
    puts $msg
  }

  ready
}


# is called upon completion of spice with the code: 0=ok, 1=spice error.

proc spice_callback code {

  global PROBE_TYPE

  if {$code == 1} {
    ${PROBE_TYPE}_init_probe
  }
}


proc flat_spice_it {} {
  spice_it
}


# switch between spice-like simulators

proc select_simulator {} {

  global cur_c SPICE_TYPE SPICE_TYPES SPICE_SUFFIX

  if {[llength $SPICE_TYPES] == 0} {
    warning "Aborting, no \"spice-like\" simulators available.  Change the variable SPICE_TYPES in .suerc to add some."
    return
  } elseif {[llength $SPICE_TYPES] == 1} {
    warning "Aborting, only available \"spice-like\" simulator is $SPICE_TYPES.  Change the variable SPICE_TYPES in .suerc to add more."
    return
  }

  set title "Change Simulator"
  set message "Choose \"spice-like\" simulator:" 
  set prop_list ""

  lappend prop_list [list simulator SPICE_TYPE -radio $SPICE_TYPES \
			 -reload -command _change_current_spice_suffix]
  lappend prop_list [list "" "" -separator]

  set SPICE_SUFFIX(current) \
      [use_first SPICE_SUFFIX(current) SPICE_SUFFIX($SPICE_TYPE)]
  lappend prop_list [list suffix SPICE_SUFFIX(current) -entry -help "Change to .sw0, .ac0, etc. if doing other than transient simulations."]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  puts "Spice-like simulator is now $SPICE_TYPE and suffix is now $SPICE_SUFFIX(current)."

  return
}


proc _change_current_spice_suffix {} {

  global SPICE_TYPE SPICE_SUFFIX

  set SPICE_SUFFIX(current) \
      [use_first SPICE_SUFFIX($SPICE_TYPE) SPICE_SUFFIX(current)]
}


# opens an NST window if none is presently open and loads tr0 into it.

proc NST_init_probe {{options 0}} {
  
  global NETLIST NST_DIR PROBE_ID PROBE_DATA_FILE PA0_READ INTEL_CORNER
  global SPICE_PROBE NET_MEMORY PROBE_STATUS SPICE_TYPE TR0_FORMAT SPICE_SUFFIX

  if {[info exists NETLIST(root)] != 1} {
    sue_error "Aborting, must netlist first before initializing probe."
    sue_error flush
    return
  }

  upvar #0 SUE_$NETLIST(root) data
  set dir $data(dir)

  # push into directory of toplevel schematic 
  set save_dir [pwd]
  cd $dir

  set old_name [use_first PROBE_DATA_FILE]

  # if not defined, assume spice.
  set SPICE_TYPE [use_first SPICE_TYPE 'spice]

  if {$SPICE_TYPE == "intel"} {
    set INTEL_CORNER [use_first INTEL_CORNER '_1]
  }

  if {$options && $SPICE_TYPE == "intel"} {
    # query user for different corner
    set message "Select simulation file"
    set title "Intel Corner"

    set prop_list [list [list "Which Corner" INTEL_CORNER]]
    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
      # cancelled
      return ""
    }
  }

  set SPICE_SUFFIX(current) \
      [use_first SPICE_SUFFIX(current) SPICE_SUFFIX($SPICE_TYPE)]

  switch $SPICE_TYPE {
    spice - adm {
      set PROBE_DATA_FILE $NETLIST(dir)$NETLIST(root)$SPICE_SUFFIX(current)
    }
    intel {
      set PROBE_DATA_FILE $NETLIST(dir)$NETLIST(root)$INTEL_CORNER$SPICE_SUFFIX(current)
    }
    powermill {
      warning "Aborting, NST doesn't read powermill output format."
      return
    }
  }

  # is there a output data file file yet?
  if {[file isfile $PROBE_DATA_FILE] != 1} {
    # file doesn't exist so abort
    puts "Aborting, can't find data output file $PROBE_DATA_FILE.  Probably still computing DC operating point."

    # restore old file name
    set PROBE_DATA_FILE $old_name

    # restore current directory
    cd $save_dir

    return
  }

  if {[check_probe]} {
    # this file id is valid so we don't need to bring NST up
    puts "Resetting existing NST."

    if {$old_name == $PROBE_DATA_FILE} {
      if {[use_first PROBE_STATUS] == "new_sim"} {
	set PROBE_STATUS ""
	puts $PROBE_ID "nst_copy [file tail $PROBE_DATA_FILE] [file tail ${PROBE_DATA_FILE}]~"
	flush $PROBE_ID
      }
    } else {
      regsub {(_[0-9]+)\.split} $old_name "" old
      regsub {(_[0-9]+)\.split} $PROBE_DATA_FILE "" new

      if {$SPICE_TYPE == "intel" && $old == $new} {
	# different corners
	set PROBE_STATUS ""

      } else {
	puts $PROBE_ID "nst_reset"
	flush $PROBE_ID

	# erase net memory
	catch {unset NET_MEMORY}
      }
    }
  } else {
    # close the last file if there was one
    catch {close $PROBE_ID}

    set probe_cmd [uplevel #0 {eval concat $SPICE_PROBE_CMD(NST)}]

    puts "Starting new NST with $probe_cmd"
    set PROBE_ID [open "|$probe_cmd >& [exec tty]" w]
  
    if {[check_probe] != 1} {
      puts "ERROR: Can't start NST."
      cd $save_dir
      return
    }
  }

  # figure out the format of the tr0 file
  # NOTE: this is bad for the case of the last tr0 file having a different
  # format than the new one -- pretty rare.
  if {![catch "open $PROBE_DATA_FILE r" tmp_id]} {
    # look for format
    read $tmp_id 16
    read $tmp_id 16
    set format [read $tmp_id 4]

    if {$format == "9601" || $format == "9007"} {
      set TR0_FORMAT $format
      puts "$PROBE_DATA_FILE is $format format"
    }

    close $tmp_id
  }

  # use format of last file, default to 9601
  set TR0_FORMAT [use_first TR0_FORMAT '9601]

  # now load in the tr0 file
  puts $PROBE_ID "nst_load $PROBE_DATA_FILE"
  flush $PROBE_ID

  # reset so that we know that we have to reread the hspice translation table
  set PA0_READ ""

  NST_plot_memory

  # restore current directory
  cd $save_dir
}


# quits the NST probe application

proc NST_close_probe {} {

  global PROBE_ID

  # if its still valid, kill probe
  if {[check_probe]} {
    puts $PROBE_ID "exit"
    catch "flush $PROBE_ID"
  }

  catch {close $PROBE_ID}
}


# plot waveform of the selected net on NST

proc NST_plot_net {{suffix ""} {net ""}} {

  global PROBE_ID PROBE_DATA_FILE SPICE_TYPE

  # make sure NST is still around
  if {[check_probe]} {
    if {$net == ""} {
      set net [spice_net]
    }

    if {[string tolower $net] == "gnd"} {
      set net 0
    }

    if {[use_first SPICE_TYPE] == "adm"} {
      set net [string toupper $net]
    }

    set file [file tail $PROBE_DATA_FILE]

    puts "Plotting $file$suffix $net"
    # don't ask
    regsub -all {\[|\]} $net \\\\& foo
    puts $PROBE_ID "nst_plot $file$suffix $foo"
    flush $PROBE_ID

    return $net

  } else {
    puts "Need to initialize probe"
  }
}

# unplot waveform of the selected net on NST

proc NST_unplot_net {{suffix ""} {net ""}} {

  global PROBE_ID PROBE_DATA_FILE SPICE_TYPE

  # make sure NST is still around
  if {[check_probe]} {
    if {$net == ""} {
      set net [spice_net]
    }

    if {[string tolower $net] == "gnd"} {
      set net 0
    }

    if {[use_first SPICE_TYPE] == "adm"} {
      set net [string toupper $net]
    }

    set file [file tail $PROBE_DATA_FILE]

    puts "Unplotting $file$suffix $net"
    # don't ask
    regsub -all {\[|\]} $net \\\\& foo
    puts $PROBE_ID "nst_unplot $file$suffix $foo"
    flush $PROBE_ID

    return $net

  } else {
    puts "Need to initialize probe"
  }
}


proc NST_erase_and_plot_memory {} {

  global PROBE_ID

  # make sure NST is still around
  if {[check_probe]} {

    puts $PROBE_ID "nst_erase_all"
    flush $PROBE_ID
    
    NST_plot_memory

  } else {
    puts "Need to initialize probe"
  }
}


proc cancel_memory {} {

  global NET_MEMORY

  catch {unset NET_MEMORY}

  puts "Memory cancelled."
}

proc NST_plot_memory {} {

  global NET_MEMORY

  if {[info exists NET_MEMORY]} {
    foreach net [lsort -decreasing [array names NET_MEMORY]] {
      NST_plot_net "" $net
    }
  }
}

proc NST_plot_net_and_remember {} {

  global NET_MEMORY

  set net [NST_plot_net]
  
  set NET_MEMORY($net) 1

  puts "Remembered net $net"
}

proc NST_unplot_net_and_forget {} {

  global NET_MEMORY

  set net [NST_unplot_net]
  
  catch "unset NET_MEMORY($net)"

  puts "Forgotten net $net"
}


# compute the hierarchical spice net name in hspice syntax.  Note that 
# spice has a complicated way of renaming net names when they get to long
# which has to be followed.

proc spice_net {{id ""}} {

  global cur_c cur_s NETLIST HIERARCHY SPICE_TYPE TR0_FORMAT
  upvar #0 TERMS_$cur_s TERMS

  if {$id == ""} {
    set id [lindex [$cur_c find withtag selected] 0]
  }

  if {[is_tagged $id wire]} {
    integer_scale
    set net [find_net_name $id]
    unscale
    return $net
  }

  if {[is_tagged $id dot] || [is_tagged $id open] || [is_tagged $id term]} {
    integer_scale
    set net [find_net_name [center $id]]
    unscale
    return $net
  }

  # check if it's an icon
  set origin_id [find_origin $id]
  if {[is_tagged $origin_id origin]} {
    # find all terminals on this inst
    set terms ""
    foreach id2 [$cur_c find withtag inst$origin_id] {
      if {[is_tagged $id2 "term"]} {
	lappend terms $id2
      }
    }

    if {[llength $terms] == 1} {
      # probably an I/O or global (most instances have more than one term)
      integer_scale
      set net [find_net_name $terms]
      unscale
      return $net
    }

    # Assume that the user wants the current through the inst
    if {[llength $terms] == 2} {
      set net $TERMS([find_origin $id])

      # concatenate the spice instance names of the hierarchy onto
      # the front of the net to produce the full net name
      foreach schematic $HIERARCHY {
	upvar #0 TERMS_[lindex [split $schematic ,] 0] TT

	set inst $TT([lindex [split $schematic ,] 1])
	if {[bus_width $inst] > 1} {
	  # query user, remember last choice
	  set message "Select bit of $inst"
	  set title "bit selection"

	  set bus $inst
	  set list [bus_expand $bus]

	  set inst [use_first LAST_SPICE_NET_INDEX($bus)]
	  if {[lsearch -exact $list $inst] == -1} {
	    # not in this range
	    set inst [lindex $list 0]
	  }

	  set prop_list [list [list "Which Instance" inst choice $list]]
	  # create the menu
	  if {![prop_menu2 -message $message -title $title $prop_list]} {
	    # cancelled
	    return ""
	  }

	  # save for next time
	  set LAST_SPICE_NET_INDEX($bus) $inst
	}

	set net "$inst.$net"
      }

      # if the full net name is too long, then hspice translaes it
      # to something shorter, so we have to too.  Remember we must
      # add a I( later.
      switch $SPICE_TYPE {
	adm {
	  if {$TR0_FORMAT == "9007" && [string length $net] > 13} {
	    set net [translate_spice_net $net]
	  }
	}
	spice {
	  if {$TR0_FORMAT == "9007" && [string length $net] > 12} {
	    set net [translate_spice_net $net]
	  }
	}
	intel {
	  # don't translate
	}
	powermill {
	  # don't translate
	}
      }

      # tack the special current stuff on the front
      return I\([string tolower $net]
    }
  }

  return Unknown
}


# Finds the net name on the id.  If the id is a coord, looks up id first
# Since spice has converted net names to lowercase, we need to also.
# Note that if an IO is selected, we have to walk up the hierarchy.
# Picks the wire out of a bus depending on "index".

proc find_net_name {id {index ""}} {

  global cur_c cur_s NETS NETLIST HIERARCHY GLOBALS SPICE_TYPE
  global NETLIST_TYPE TR0_FORMAT LAST_SPICE_NET_INDEX
  upvar #0 TERMS_$cur_s TERMS

  if {[llength $id] == 2} {
    # coord, find id
    catch {unset NETS}
    set id [lindex [lindex [eval find_terms $id 0] 0] 0]
  }

  if {$id == " "} {
    puts "Aborting, wire is not connected to any terminals.  can't probe."
    return
  }

  generate_term_names

  if {![info exists TERMS($id)]} {
    return ""
  }

  set net $TERMS($id)

  if {$index != ""} {
    set net [lindex [cbus_expand $net] $index]
  }

  if {$NETLIST_TYPE == "spice" && [cbus_width $net] > 1} {
    # query user, remember last choice
    set message "Select bit of $net"
    set title "bit selection"

    set bus $net
    set list [cbus_expand $bus]

    set net [use_first LAST_SPICE_NET_INDEX($bus)]
    if {[lsearch -exact $list $net] == -1} {
      # not in this range
      set net [lindex $list 0]
    }

    set prop_list [list [list "bit" net choice $list]]
    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
      # cancelled
      return ""
    }

    # save for next time
    set LAST_SPICE_NET_INDEX($bus) $net
  }

  # if there is hierarchy above us, look for IOs
  if {[use_first HIERARCHY] != ""} {
    set root [bus_root $net]

    foreach io_id [concat [$cur_c find withtag icon_input] \
		       [$cur_c find withtag icon_output] \
		       [$cur_c find withtag icon_inout]] {

      set io_id [$cur_c find withtag term&inst$io_id]

      if {[info exists TERMS($io_id)]} {
	if {$root == [bus_root $TERMS($io_id)]} {
	  # this is an I/O
	  return [climb_hierarchy $net]
	}
      }
    }
  }

  if {$NETLIST_TYPE == "dpc"} {
    # special case called thru climb_hierarchy in a spice cell in pathmill
    return [dpc_cell_name ""]$net
  }

  set SEP .

  # concatenate the spice instance names of the hierarchy onto
  # the front of the net to produce the full net name unless
  # it's a global
  set globals [array names GLOBALS]

  if {[lsearch $globals [string tolower $net]] == -1} {
    foreach schematic $HIERARCHY {
      upvar #0 TERMS_[lindex [split $schematic ,] 0] TT

      set inst $TT([lindex [split $schematic ,] 1])
      if {[bus_width $inst] > 1} {
	# query user, remember last choice
	set message "Select bit of $inst"
	set title "bit selection"

	set bus $inst
	set list [bus_expand $bus]

	set inst [use_first LAST_SPICE_NET_INDEX($bus)]
	if {[lsearch -exact $list $inst] == -1} {
	  # not in this range
	  set inst [lindex $list 0]
	}

	set prop_list [list [list "Which Instance" inst choice $list]]
	# create the menu
	if {![prop_menu2 -message $message -title $title $prop_list]} {
	  # cancelled
	  return ""
	}

	# save for next time
	set LAST_SPICE_NET_INDEX($bus) $inst
      }

      set net "$inst$SEP$net"
    }
  }

  # if the full net name is too long, then hspice translates it
  # to something shorter, so we have to too.
  switch $SPICE_TYPE {
    adm {
      if {$TR0_FORMAT == "9007" && [string length $net] > 15} {
	set net [translate_spice_net $net]
      }
    }
    spice {
      if {$TR0_FORMAT == "9007" && [string length $net] > 14} {
	set net [translate_spice_net $net]
      }
    }
    intel {
      # don't translate
    }
    powermill {
      # don't translate
    }
  }

  return [string tolower $net]
}


# returns a list of ids of the terminals on the net containing the
# coordinate given.  Terminals alone remember their net names but if
# they change they will forget them.  

proc find_terms {x y {distance 0}} {

  global cur_c cur_s scale NETLIST_TYPE NETS
  upvar #0 TERMS_$cur_s TERMS

  set attach_list ""
  set del [expr $scale/3.0]

  # get all ids of things overlapping the given coordinates
  set ids [$cur_c find overlapping [expr $x - $del] [expr $y - $del] \
	      [expr $x + $del] [expr $y + $del]]

  # The order is very important here.  Nearby terminals will be first.
  # This will allow us to probe bus pieces correctly.
  foreach id $ids {
    if {[is_tagged $id "term"]} {
      # terminal info can go away if icon is remade
      if {[info exists TERMS($id)]} {
	# save its id
	lappend attach_list "$id $distance"
      }
    }
  }

  if {$attach_list != ""} {
    if {[lsearch "verilog dpc csim" $NETLIST_TYPE] != -1} {
      # don't need to look any farther for verilog
      return $attach_list
    }

    incr distance
  }

  foreach id $ids {
    # if we've marked this one, we've already been here.
    if {[info exists NETS($id)]} {
      continue
    }

    # mark it
    set NETS($id) traced

    # follow wires
    if {[is_tagged $id "wire"]} {
      set wire_coords [$cur_c coords $id]
      set x1 [lindex $wire_coords 0]
      set y1 [lindex $wire_coords 1]
      set x2 [lindex $wire_coords 2]
      set y2 [lindex $wire_coords 3]

      if {[nearby $x $y $x1 $y1] == 1} {
	# recursively walk down wire
	set attach_list [concat $attach_list [find_terms $x2 $y2 $distance]]
	continue
      } 

      if {[nearby $x $y $x2 $y2] == 1} {
	# recursively walk down wire
	set attach_list [concat $attach_list [find_terms $x1 $y1 $distance]]
	continue
      }

      continue
    }
  }
  return $attach_list
}


# the tr0 only saves the node voltage/current once per node.  The name
# it uses for a node is the highest in the hierarchy.  Thus, an IO in
# a subcircuit must be traced up through the hierarchy to find its
# highest point.

proc climb_hierarchy {term_name} {

  global cur_c cur_s scale NETLIST HIERARCHY

  if {$HIERARCHY == ""} {
    # already at top
    return ""
  }

  # save away current canvas info
  set save_cur_c $cur_c
  set save_cur_s $cur_s
  set save_scale $scale
  set save_hierarchy $HIERARCHY

  set up [split [lindex $HIERARCHY 0] ,]
  set HIERARCHY [lrange $HIERARCHY 1 end]

  set cur_s [lindex $up 0]

  global SUE_${cur_s}

  set cur_c [set SUE_${cur_s}(canvas)]
  set scale [set SUE_${cur_s}(scale)]
  
  set term_id ""

  upvar #0 TERMS_$cur_s TERMS

  set index ""

  foreach id [get_intersect_tag "inst[lindex $up 1]" term] {
    if {[use_first TERMS($id,name)] == ""} {
      get_term_info $id noglobal
    }

    # this only works with the -exact flag because of the brackets
    set index [lsearch -exact [bus_expand $TERMS($id,name)] $term_name]
    if {$index != -1} {
      # found it
      set term_id $id
      break
    }
  }

  if {$index == -1 || ![is_bus $term_name]} {
    set index ""
  }

  if {$term_id == ""} {
    # restore the current canvas info
    set cur_c $save_cur_c
    set cur_s $save_cur_s
    set scale $save_scale
    set HIERARCHY $save_hierarchy

    # we really should never get here unless someone remade the icon
#    puts "Can't climb hierarchy during probing.  Must re-netlist."
    return ""
  }

  # puts "climbing through $cur_s $term_name"
  set net [find_net_name $term_id $index]

  # restore the current canvas info
  set cur_c $save_cur_c
  set cur_s $save_cur_s
  set scale $save_scale
  set HIERARCHY $save_hierarchy

  return $net
}


# Reads in the file .pa0 which contains the net name translations if
# it isn't current and then translated the spice net.  We
# could also compute this table, but this way is easier.

proc translate_spice_net {net} {

 global PA0_READ PA0 NETLIST SPICE_TYPE NETLIST_TYPE

 if {$NETLIST_TYPE == "sim"} {
   # don't do the hspice translation
   return $net
 }

 upvar #0 SUE_$NETLIST(root) data

 # do we have to read in the translation table file
 if {$PA0_READ == ""} {

   # forget the old translation table if there is one
   catch {unset PA0}

   # compute the filename for the .pa0 file
   set dir $data(dir)

   if {[use_first SPICE_TYPE] == "adm"} {
     set suffix pa
   } else {
     set suffix pa0
   }

   set filename "$dir$NETLIST(root).$suffix"

   puts "Loading hspice translation table from $filename"

   # push into directory of toplevel schematic 
   set save_dir [pwd]
   cd $dir
 
   if {![file isfile $filename]} {
     # file doesn't exist so abort
     puts "Error, can't find hspice translation file $filename"

     # restore current directory
     cd $save_dir

     return Unknown
   }

   if {[file size $filename] == 0} {
     # hspice bug that it doesn't write the data into this file until
     # the end of the simulation.  However, it does write it into the .out
     # file.
   
     set suffix out
     set filename "$dir$NETLIST(root).$suffix"

     # open the out file
     set PA0_ID [open $filename r]
     
     # now read in the table (once we find it)
     set read 0
     while {[gets $PA0_ID line] >= 0} {
       if {$read == 1} {
	 if {[string index $line 0] == "*"} {
	   # this means we're done
	   set read 0
	 } else {
	   set PA0([string tolower [lindex $line 1]]) [lindex $line 0]
	 }
	 continue
       }
       if {$line == "number  circuitname                   definition  multiplier"} {
	 # this line comes at the beginning of the table
	 set read 1
       }
     }

     # close the file
     close $PA0_ID

     puts "Snagged hspice translation table from $filename"

   } else {
     # pa0 file exists and has data in it.

     # open the file
     set PA0_ID [open $filename r]
     
     # now read in the table
     while {[gets $PA0_ID line] >= 0} {
       set PA0([string tolower [lindex $line 1]]) [lindex $line 0]
     }

     # close the file
     close $PA0_ID
   }

   # restore current directory
   cd $save_dir

   # remember that we read this file
   set PA0_READ 1
 }

 set net_parts [split $net .]
 set last [expr [llength $net_parts] - 1]
 set net_path [string tolower \
		   "[join [lrange $net_parts 0 [expr $last-1]] .]."]

 set translate_net "$PA0($net_path):[lindex $net_parts $last]"

 return $translate_net
}


# checks the NST id by trying to flush it to see if the other end of the
# pipe is still there.

proc check_probe {{bogus_char \#}} {

  global PROBE_ID

  if {[info exists PROBE_ID] != 1} {
    # PROBE_ID isn't even defined.  Must be a bad pipe
    return 0
  }

  if {$PROBE_ID == ""} {
    # never used
    return 0
  }

  # first put something bogus into the pipe
  if {[catch "puts $PROBE_ID $bogus_char"]} {
    # failed, bad pipe
    return 0
  }

  if {[catch "flush $PROBE_ID"]} {
    # failed, bad pipe
    return 0

  } else {
    # ok
    return 1
  }
}


proc kill_spice_job {} {

  global SPICEHOSTS NETLIST SUFFIX SUE_DIR

  busy

  set filename $NETLIST(root)$SUFFIX(spice)

  foreach host $SPICEHOSTS {
    set error [catch "exec rsh $host /usr/ucb/ps -auxww | grep \"spice $filename\"" msg]

    if {$error == 0} {
      if {$msg == ""} {
	# nothing matches, try the next host.
	continue
      }

      foreach line [split $msg \n] {
	# must weed out lines with either rsh, grep, or CALLBACK since
	# we will see this on the current host
	if {[lsearch $line rsh] != -1 || [lsearch $line grep] != -1 || \
		[lsearch $line -CALLBACK] != -1} {
	  continue
	}

	# must have found it.

	# the first job is the one to kill and the second atom is the job #
	set death [lindex $msg 1]

	ready
	# make a popup to ask the user if they are really sure about this
	set button [tk_dialog .waste "HSPICE DEATH" \
			"Kill spice job $death, ($filename) on ${host}?" \
			@$SUE_DIR/sue_icon.xbm 0 {ok} {cancel}]

	if {$button == 1} {
	  # user wimped out
	  puts "Aborting spice kill job."
	  return
	}

	puts "Killing spice job $death ($filename) on $host ..."
	catch "exec rsh $host kill $death"

	return
      }
    }
  }

  sue_error "Aborting, can't find spice job \"$filename\" on hosts: $SPICEHOSTS"
  sue_error flush
  ready
  return 
}


# Returns the local net name independent of netlist type.  Must have 
# netlisted first

proc display_local_net {{id ""}} {

  global cur_c cur_s scale NETS
  upvar #0 TERMS_$cur_s TERMS

  if {![info exists TERMS]} {
    return ""
  }

  if {$id == ""} {
    set id [$cur_c find withtag selected]
  }

  # if more than one thing, only look at first one
  set id [lindex $id 0]

  if {[is_tagged $id "wire"]} {
    return [use_first TERMS($id)]

  } elseif {[is_tagged $id "dot"] || [is_tagged $id "open"]} {
    # get the name from what is attached to this guy
    integer_scale

    set del [expr $scale/3.0]
    setl {x y} [center $id]
    # get all ids of things overlapping the given coordinates
    set ids [$cur_c find overlapping [expr $x - $del] [expr $y - $del] \
		 [expr $x + $del] [expr $y + $del]]

    set net ""
    foreach id $ids {
      if {[is_tagged $id "term"] || [is_tagged $id "wire"]} {
	set net [use_first TERMS($id)]
	if {$net != ""} {
	  break
	}
      }
    }

    unscale

    return $net

  } elseif {[is_tagged [find_origin $id] origin]} {
    # find all terminals on this inst
    set terms ""
    foreach id2 [$cur_c find withtag inst[find_origin $id]] {
      if {[is_tagged $id2 "term"]} {
	lappend terms $id2
      }
    }
  
    if {[llength $terms] == 1} {
      # probably an I/O or global (most instances have more than one term)
      return [use_first TERMS($terms)]

    } else {
      # just return the instance name, if there is one
      return [use_first TERMS([find_origin $id])]
    }

  } else {
    # Non named object like a draw_item
    return
  }
}


# Reads in a back annotation capacitance file for the current cell and
# places or replaces the pcap icons occordingly.  If an argument is given,
# first deletes all pcap icons.

proc back_annotate_caps {{toast ""} {lvs_tool gemini}} {

  global cur_c cur_s SUFFIX XFORM BACK_ANNOTATE_PATH

  # make sure we are in a schematic.  Otherwise punt
  if {[is_icon $cur_s]} {
    sue_error "Aborting, cannot back annotate an icon."
    sue_error flush
    return
  }

  if {$lvs_tool != "gemini"} {
    sue_error "Aborting, don't know how to use lvs tool $lvs_tool."
    sue_error flush
    return
  } elseif {![executable_exists gemini]} {
    sue_error "Aborting, can find gemini executable."
    sue_error flush
    return
  }

  busy

  puts "\nBack Annotating cell $cur_s ..."

  # Try to find the back annotation file.
  upvar #0 SUE_$cur_s data
  set dir [string trimright $data(dir) /]

  set dirs $BACK_ANNOTATE_PATH
  insert_unique dirs end $dir

  set back_file ""
  foreach vdir $dirs {
    if {[file exists $vdir/$cur_s$SUFFIX(back_annotate)]} {
      set back_file "$vdir/$cur_s$SUFFIX(back_annotate)"
      break
    }
  }

  if {$back_file == ""} {
    # can't find a back annotation file
    sue_error "Aborting, Can't find back annotation file $cur_s$SUFFIX(back_annotate) in:\n\t[join $dirs \n\t]."
    sue_error flush
    ready
    return
  }

  if {![file readable $back_file]} {
    sue_error "Aborting, Can't read back annotation file $back_file."
    sue_error flush
    ready
    return
  }

  # delete all existing pcap icons if requested
  if {$toast != ""} {
    foreach id [$cur_c find withtag icon_pcap] {
      # delete icon and lose data structure
      upvar #0 ${cur_s}_inst$id i_data
      $cur_c delete inst$id
      unset i_data
    }
  }

  upvar #0 TERMS_$cur_s TERMS

  # gemini mode.  First run gemini on sim netlist vs. back annotate
  # netlist to find net name equivalences.

  # need to have a sim netlist of this schematic
  set filename $dir/$cur_s$SUFFIX(default)
  if {[catch {set date [file mtime $filename]}] != 0} {
    # user has never saved this, assume sim file is newer
    set date 0
  }

  set sim_file [cross_probe_setup]

  # now run gemini and write name equivalence file
  puts "Running gemini to determine node equivalents ..."
  set tmp_file tmp[pid]
  catch "exec gemini -D$tmp_file $back_file $sim_file"

  # create an equivalence array
  if {[catch "open $tmp_file r" tmp_id] != 1} {
    # good, file exists
    while {[gets $tmp_id line] >= 0} {
      if {[lindex $line 0] == "="} {
	set equiv([lindex $line 1]) [lindex $line 2]
      }
    }
    # close the file
    close $tmp_id

    # now delete the tmp file
    catch {exec rm -f $tmp_file}
  }

  # Read in the back annotation file which should have the format:
  # Capacitance is in fF.  Unfortunately it is rounded to nearest fF.
  #   C   net  gnd   capacitance
  # All other lines are ignored.

  puts "Creating/Replacing pcap's ..."

  set tmp_id [open $back_file r]

  set replaced 0
  set placed 0
  set new_ids ""
  while {[gets $tmp_id line] >= 0} {
    if {[string tolower [lindex $line 0]] == "c"} {
      # found a parasitic capacitance line
      setl {foo net net2 value} $line

      # net and net2 might be backwards
      if {[string tolower $net] == "gnd"} {
	set net $net2
      } elseif {[string tolower $net2] != "gnd"} {
	# this is bad, neither are tied to ground
	puts "Warning, ignoring capacitor between nets $net and $net2."
	continue
      }

      # look up the net in the equivalence array
      if {[info exists equiv($net)]} {
	set net $equiv($net)
      }
#puts "$line --> $net"

      set done 0

      # see if there is already a pcap on the net that we can just modify
      integer_scale

      set ids [find_by_name $net]
      foreach id $ids {
	if {[is_tagged [find_origin $id] icon_pcap]} {
	  # already a pcap here, just update it with a new value
	  set pcap_id [find_origin $id]
	  upvar #0 ${cur_s}_inst$pcap_id i_data
	  set i_data(_capacitance) "${value}fF"
	  set new_id [remake $pcap_id $pcap_id "" no_scale]

	  # need to set the TERMS array (netlisting info)
	  foreach test_id [$cur_c find withtag inst$new_id] {
	    if {[is_tagged $test_id term]} {
	      # found it's terminal, now mark the name
	      set TERMS($test_id) $net
	      break
	    }
	  }

	  incr replaced
	  set done 1
	  break
	}
      }

      unscale

      if {$done == 1} {
	continue
      }

      # figure out where to put the new pcap.  I/O's are desired
      set save_id ""
      foreach id $ids {
	if {![is_tagged $id term]} {
	  # punt, probably a wire
	  continue
	}
	if {![is_tagged $id name*term*] || $save_id == ""} {
	  set save_id $id
	}
      }

      if {$save_id == ""} {
	# no net of that name in this schematic, punt
	continue
      }

      # make a new pcap and put it on the correct net
      set id $save_id
      upvar #0 ${cur_s}_inst[find_origin $id] i_data

      if {([is_tagged $id name*input*] && [is_tagged $id *name*term*]) || \
	      ([is_tagged $id name*output*] && ![is_tagged $id *name*term*])} {
	# to make it look nice, flip the pcap left to right on input terms
	# that are not input icons and also on output icons.
	if {$XFORM($i_data(orient)) == ""} {
	  set dir MX
	} else {
	  set dir MY
	}

	set new_id [make pcap -origin [center $id] -capacitance ${value}fF \
			-orient $XFORM($dir,$i_data(orient))]
      } else {
	set new_id [make pcap -origin [center $id] -capacitance ${value}fF \
			-orient $i_data(orient)]
      }

      lappend new_ids $new_id

      # need to set the TERMS array (netlisting info)
      foreach test_id [$cur_c find withtag inst$new_id] {
	if {[is_tagged $test_id term]} {
	  # found it's terminal, now mark the name
	  set TERMS($test_id) $net
	  break
	}
      }

      incr placed
    }
  }

  if {$new_ids != ""} {
    # remember for undo
    setup_undo $new_ids ""
  }

  # close the file
  close $tmp_id

  # must get the netlisting information for the pcaps
  generate_term_names

  puts "Placed $placed, replaced $replaced parasitic capacitance icons."

  puts "Done."
  ready
}


proc max_cross_probe_init {{lvs_tool gemini}} {

  global cur_c cur_s SUFFIX MAX_DATA BACK_ANNOTATE_PATH SUE_DIR 

  modify_setup cross_probe

  # make sure we are in a schematic.  Otherwise punt
  if {[is_icon $cur_s]} {
    sue_error "Aborting, cannot cross probe an icon."
    sue_error flush
    return
  }

  if {$lvs_tool != "gemini"} {
    sue_error "Aborting, don't know how to use lvs tool $lvs_tool."
    sue_error flush
    return
  } elseif {![executable_exists gemini]} {
    sue_error "Aborting, can find gemini executable."
    sue_error flush
    return
  }

  busy

  upvar #0 SUE_$cur_s data
  set dir [string trimright $data(dir) /]

  # special case for generators, get dir where generator came from
  upvar #0 icon_$cur_s g_data
  if {[use_first g_data(generator)] != ""} {
    # this is a generator.
    global auto_index
    set genname [lindex [split_filename [use_first g_data(generator)]] 1]
    if {[info exists auto_index(SCHEMATIC_$genname)]} {
      set dir [file dirname [lindex $auto_index(SCHEMATIC_$genname) 1]]/
    }
  }

  set max [check_max -start]
  if {$max == "*CANCEL*"} {
    ready
    return 0
  }
    
  set max [check_max]
  if {$max == ""} {
    ready
    return 0
  }

  # load correct cell
  # TODO: this should look through a translation to get the dir and name
  catch "send $max cell_load $cur_s $dir"
    
  set max_cell [send $max lay_editcell]
  if {$max_cell != $cur_s} {
    if {[catch "send \{$max\} cell_load -search $cur_s"]} {
      # cell doesn't exist, make a new one
      set button [tk_dialog .new "cross probe" \
		      "MAX can't find cell \"$cur_s\".  Do you want to create a new cell in MAX or load it yourself (probably from a different location) from MAX and rerun?" \
		  @$SUE_DIR/sue_icon.xbm 1 {new} {load myself}]
      
      switch $button {
	0 {
	  # new cell
	  catch "send \{$max\} db_cell_new $cur_s $dir/$cur_s.max"
	  send $max ":load $cur_s ; win_title_update"
	}
	
	1 {
	  # user will rerun
	  ready
	  return 0
	}
      }
    }
  }

  # gemini mode.  First run gemini on sim netlist vs. back annotate
  # netlist to find net name equivalences.

  # need to have a sim netlist of this schematic
  set filename $dir/$cur_s$SUFFIX(default)
  if {[catch {set date [file mtime $filename]}] != 0} {
    # user has never saved this, assume sim file is newer
    set date 0
  }

  set sim_file [cross_probe_setup]

  # run lvs on cell
  puts "Running lvs on max cell to get node correspondance..."
  # note that this will wait until max is done before continuing
  send $max lvs_it_max

  puts "\nInitializing max cross probe..."

  # Try to find the back annotation file.
  set dirs $BACK_ANNOTATE_PATH
  insert_unique dirs end $dir

  # get the lvs filename translation from max (i.e. the current max cell)
  set max_file [send $max lay_editcell]

  set back_file ""
  foreach vdir $dirs {
    if {[file exists $vdir/$max_file$SUFFIX(back_annotate)]} {
      set back_file "$vdir/$max_file$SUFFIX(back_annotate)"
      set ext_file "$vdir/$max_file.ext"
      break
    }
  }

  if {$back_file == ""} {
    # can't find a back annotation file
    sue_error "Aborting, Can't find max file $max_file$SUFFIX(back_annotate) in:\n\t[join $dirs \n\t]."
    sue_error flush
    ready
    return
  }

  if {![file readable $back_file]} {
    sue_error "Aborting, Can't read max file $back_file."
    sue_error flush
    ready
    return
  }

  # now run gemini and write name equivalence file
  puts "  Running gemini to determine node equivalents ..."
  set tmp_file tmp[pid]
  catch "exec gemini -c -D $tmp_file $back_file $sim_file"

  # deselect all
  select_id ""

  # set up sue's cross probe corresponence
  set matches [create_cross_probe_correspondence $tmp_file]

  # set up max's cross probe corresponence so we don't have to run it there
  send $max _create_cross_probe_correspondence $tmp_file

  # now delete the tmp file
  catch {exec rm -f $tmp_file}

  # now show non-matching wires in max
  send $max sel_clear
  send $max eval lay_box \[lay_bbox\]
  send $max lay_internals -area
  foreach match $matches {
    max_cross_probe $match "more quiet"
  }

  puts "Done."
  ready
}


proc create_cross_probe_correspondence {file} {

  global MAX_DATA

  set matches ""
  catch {unset MAX_DATA}

  # create an equivalence array
  if {[catch "open $file r" tmp_id] != 1} {
    # good, file exists
    while {[gets $tmp_id line] >= 0} {
      if {[lindex $line 0] == "="} {
	set MAX_DATA(equiv,[lindex $line 2]) [lindex $line 1]
	# select this to show user that we found a correspondance with
	# this wire and the layout
	set name [lindex $line 2]
	if {[select_wire_by_name $name add no_display]} {
	  lappend matches $name
	}
      }
    }
    # close the file
    close $tmp_id
  }

  return $matches
}


proc max_cross_probe {{net ""} {option ""}} {

  global MAX_DATA

  # get the net name in sue
  if {$net == ""} {
    set net [display_local_net]
  }

  if {$net == ""} {
    puts "Aborting, must select a net before cross probing."
    return
  }

  set max_net [use_first MAX_DATA(equiv,$net)]
  
  if {$max_net == ""} {
    puts "Aborting, can't find max net corresponding to $net."
    return
  }

  set max [check_max]
  if {$max == ""} {
    return
  }

  # do it
  send $max "_cross_probe_net $max_net \"[concat no_zoom $option]\""
}


# find a max interp and then insure that max is up and running

set MAX_CROSS_PROBE_ID ""

proc check_max {{start ""}} -doc {

  Version of check_max that looks for all running maxs,
  pops up window to ask which one.
  If -start, forget old max we were using, query user
  which max to use.
  Return name of max window, or "" if cancelled by user, or on failure
  to find or bring up a max.
  sets MAX_CROSS_PROBE_ID with the max tied to this max for cross-probing
} {
  global CELL MAX_CROSS_PROBE_ID PROBE_DISPLAY

  if {$start == ""} {
    set start 0
  } else {
    set start 1
  }

  if {! $start} {
    if {$MAX_CROSS_PROBE_ID == ""} {
      warning "Must first run Max Cross Probe Init."
      return ""
    }

    # See if this max window is still running.
    if {[catch {send $MAX_CROSS_PROBE_ID \#}]} {
      warning "Can't find $MAX_CROSS_PROBE_ID.  Must rerun Max Cross Probe Init"
      return ""
    } else {
      # found max!
      return $MAX_CROSS_PROBE_ID  ;# Still running
    }
  }

  # Forget previous cross-probe max.
  set MAX_CROSS_PROBE_ID ""

  set possible_maxes ""
  foreach interp [winfo interps] {
    if {[string match max* $interp]} {
      lappend possible_maxes $interp
    }
  }
  set max_list $possible_maxes

  # We will give the user the option to start a new max.
  set use_max "Start a new copy of max"
  set prop_list ""

  lappend max_list "Start a new copy of max"
  set use_max [lindex $max_list 0]
  lappend prop_list [list "Which max" use_max -radio $max_list]

  set max_exe max
  lappend prop_list [list "Max executable for new max" max_exe -entry]

  regsub {^-display } $PROBE_DISPLAY "" display
  lappend prop_list [list "X display for new max" display -entry ]

  # default tech to sue PROJECT, if any.
  global PROJECT env
  set tech [use_first PROJECT env(PROJECT) env(MAX_DEFAULT_TECH)]
  lappend prop_list [list "Max technology" tech]

  if {![prop_menu2 -title "Cross Probe max" $prop_list]} {
    # cancelled
    return "*CANCEL*"
  }

  if {$use_max == "Start a new copy of max"} {

    # Fire up a new max.
    set cmd "xterm -sb -sl 1000 -display $display -T \"Max Terminal\""
    append cmd " -e $max_exe"

    if {$tech != ""} {
      append cmd " -tech $tech"
    }

    # Carefully quote for shell because winfo name may contain spaces.
    # Ain't tcl grand!
    append cmd " -command \"send \{[winfo name .]\} \\\"set MAX_CROSS_PROBE_ID \\\{\\\[winfo name .\\\]\\\}\\\"\""

    puts "Starting new max on display $display with tech $tech ..."
    global SOURCE_DIR
    if {[use_first SOURCE_DIR] != ""} {
      # only for developers to see
      puts $cmd
    }
    if {[catch "exec $cmd &" msg]} {
      # failed
      puts $msg
      ready
      return 0
    }

    # wait for max to come up
    for {set i 0} {$i < 10} {incr i} {		   
      # set by max using send
      if {$MAX_CROSS_PROBE_ID != ""} {
	# we're there
	puts "done."
	break
      }
      after 1000
      update
    }

  } else {
    # use existing
    set MAX_CROSS_PROBE_ID $use_max
  }

  if {$MAX_CROSS_PROBE_ID != ""} {
    # set up this variable in max so it knows which sue to talk to.
    send $MAX_CROSS_PROBE_ID [list set SUE_CROSS_PROBE_ID [winfo name .]]
  }

  return $MAX_CROSS_PROBE_ID
}


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


# make sure that this schematic is setup for cross-probing

proc cross_probe_setup {} {

  global cur_s SUFFIX

  upvar #0 SUE_$cur_s data
  set dir [string trimright $data(dir) /]

  # need to have a sim netlist of this schematic
  set filename $dir/$cur_s$SUFFIX(default)
  if {[catch {set date [file mtime $filename]}] != 0} {
    # user has never saved this, assume sim file is newer
    set date 0
  }

  set sim_file $dir/$cur_s$SUFFIX(sim)

  if {$data(modified) != "" || ![file readable $sim_file] || \
	  [catch "file mtime $sim_file" sim_date] || \
	  $sim_date < $date} {
    # schematic is modified, has no sim file or sim file is out of date.  
    # Must netlist

    global NETLIST_TYPE NETLIST_PROPS NETLIST_CACHE

    if {$NETLIST_TYPE != "sim" || $NETLIST_PROPS != "sim"} {
      set save_netlist_type $NETLIST_TYPE
      set save_netlist_props $NETLIST_PROPS

      set NETLIST_TYPE sim
      set NETLIST_PROPS sim

      # forget about what's cached (is this really needed?)
      catch {unset NETLIST_CACHE}

      # netlist
      netlist
    
      # restore everyting

      set NETLIST_TYPE $save_netlist_type
      set NETLIST_PROPS $save_netlist_props

      catch {unset NETLIST_CACHE}
    } else {
      # just need to netlist
      netlist
    }

  } else {
    # insure that the terminal names are up-to-date
    puts "Generating term names ..."
    generate_term_names
  }

  return $sim_file
}
