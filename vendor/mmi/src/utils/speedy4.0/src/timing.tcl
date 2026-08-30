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


# Runs timing analysis using either the Pearl Static Timing Analyzer
# or the Primetime Static Timing Analyzer

# first does a dpc netlist then runs timing

proc dpc_it {} {

  global cur_s DISABLE_CANVAS_EVENT

  modify_setup dpc_it

  if {$DISABLE_CANVAS_EVENT} {
    # ignore, probably key repeat
    return
  }

  # don't run from a placement file
  if {[is_placement $cur_s]} {
    # we are in a placement file
    sue_error "Aborting, can't netlist from a placement file."
    sue_error flush
    return
  }

  set netlist_filename [netlist 1]

  check_interrupt

  if {$netlist_filename == ""} {
    sue_error "Aborting, can't time due to netlist errors."
    sue_error flush
    return
  }

  update

  time_it 1

  # somehow this is needed here
  set DISABLE_CANVAS_EVENT 0
}


# sets up and runs timing

proc time_it {{use_defaults 0}} {

  global cur_s cur_c SUE_TIMING_DATA NETLIST SUFFIX DPC_TIMING TIMING_TERMS
  global DPC_CAP PLACEMENT_DATA

  if {![info exists NETLIST(root)]} {
    sue_error "Aborting, must dpc netlist first before timing."
    sue_error flush
    return
  }

  set root $NETLIST(root)
  upvar #0 SUE_$root data

  # just creates the filename
  create_parasitics filename

  # for backwards compatibility
  set DPC_TIMING(max_transition) [use_first DPC_TIMING(max_transition) DPC_TIMING(max_gate_delay)]

  # {name default}
  set params [list \
    {clk_names DPC_TIMING(clk_names)} \
    {clk_period DPC_TIMING(clk_period)} \
    "timing_type 'setup" \
    "constraint_file '$NETLIST(dir)$root$SUFFIX(timing_constraint)" \
    "parasitic_file '$DPC_CAP(filename)" \
    "verilog_file '$NETLIST(dir)$root$SUFFIX(dpc)" \
    {input_transition DPC_TIMING(input_transition)} \
    {driver_cell DPC_TIMING(driver_cell)} \
    {max_paths DPC_TIMING(paths)} \
    {max_transition DPC_TIMING(max_transition)} \
    {default_arrival_time DPC_TIMING(arrival_time)} \
    {default_setup_time DPC_TIMING(departure_time)} \
  ]

  if {$use_defaults} {
    catch {unset SUE_TIMING_DATA}
    catch {unset TIMING_TERMS}

    # use defaults
    foreach param $params {
      setl {name default} $param
#      set SUE_TIMING_DATA($name) [use_first $default]
      set SUE_TIMING_DATA($name) [use_first DPC_TIMING(->$name,$root) $default]
    }

  } else {
    # don't just use defaults, ask user for changes

    set winy [expr [winfo rooty $cur_c] + 50]
    set winx [expr [winfo rootx $cur_c] + 50]
    set title "Timing Setup"
    set message "Change Desired Timing Setup:" 

    set prop_list ""
    foreach param $params {
      setl {name default} $param
      regsub "_" $name " " nice_name 

      lappend prop_list \
	  [list $nice_name [use_first DPC_TIMING(->$name,$root) $default]]
    }

    # create the menu
    set new_prop_list [prop_menu $winx $winy $message $title $prop_list]
    if {$new_prop_list == ""} {
      # empty list means the user hit cancel
      return
    }

    catch {unset SUE_TIMING_DATA}
    catch {unset TIMING_TERMS}

    foreach param $params {
      set name [lindex $param 0]
      regsub "_" $name " " nice_name 
      set SUE_TIMING_DATA($name) [get_assoc $nice_name $new_prop_list] 
      # save this data for next time
      set DPC_TIMING(->$name,$root) $SUE_TIMING_DATA($name)
    }
  }

  # make sure that we are at the top level
  goto_schematic $root 1

  if {[use_first PLACEMENT_DATA($cur_s,parasitics)] != 1 && \
	  $SUE_TIMING_DATA(parasitic_file) == $DPC_CAP(filename)} {
    # need to compute parasitics

    check_interrupt

    busy
    create_parasitics
    ready
    
    # so we don't do this again till another dpc run
    set PLACEMENT_DATA($cur_s,parasitics) 1

    check_interrupt
  }

  set SUE_TIMING_DATA(cp,index) 1

  # run timing analyser
  if {[setup_$DPC_TIMING(simulator)] > 0} {
    # failed
    return
  }

  set SUE_TIMING_DATA(design) $NETLIST(root)

  puts "Nodes slower than $SUE_TIMING_DATA(max_transition):"
  catch "exec cat $NETLIST(dir)$root$SUFFIX(slow_nodes)" msg
  puts $msg
  puts ""

  select_critical_path

  display_critical_path
  display_timing

  # alert user to get to work
  bell
}


proc spice_critical_path {} {

  global DPC_TIMING

  switch $DPC_TIMING(simulator) {
    pearl {
      setup_pearl spice
    }

    primetime {
      sue_error "Aborting, primetime can't create a spice netlist of a critical path"
      sue_error flush
    }

    pathmill {
      setup_pathmill spice
    }
  }
}


# uses the Micro Magic "speedy" static timing analyser which has copied
# the input/output format of pearl.

# NOTE: moved to speedy_procs.tcl

proc setup_speedy_old {{mode ""}} {

  global NETLIST SUFFIX cur_s cur_c scale DPC_TIMING SUE_TIMING_DATA HIERARCHY
  global env

  if {[is_icon $cur_s]} {
    puts "Aborting, can't run timing from an icon, only a schematic."
    return 69
  }

  if {[is_placement $cur_s]} {
    puts "Aborting, can't run timing from a placement, only a schematic."
    return 69
  }

  if {[info exists NETLIST(root)] != 1} {
    sue_error "Aborting, must dpc netlist first before timing."
    sue_error flush
    return 69
  }

  if {$mode == "spice"} {
    puts "Aborting, speedy doesn't support spice last critical path."
    return 69
  }

  if {$mode == "timing"} {
    # write nets that are in a subcell
    write_all_nets [dpc_cell_name]

    return
  }

  busy

  set save_dir [pwd]
  cd $NETLIST(dir)

  # open (create) speedy timing command file
  set cmd_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_in)
  if {[catch "open $cmd_file w" msg]} {
    # error
    puts "DPC TIMING ERROR: $msg"

  }
  set FILE_ID $msg

  # slope for input pins
  puts $FILE_ID "inputslew * $SUE_TIMING_DATA(input_transition) $SUE_TIMING_DATA(input_transition) $SUE_TIMING_DATA(input_transition) $SUE_TIMING_DATA(input_transition)"

  # put capacitance on output nodes
  foreach id [$cur_c find withtag icon_output] {
    # find the net that is attached to this term
    set net [find_timing_net_name [get_intersect_tag term inst$id]]
    if {![info exists trace($net)]} {
      puts $FILE_ID "setnodecapacitance $net +$DPC_TIMING(out_cap)"
    }
  }

  # save terminal data for this cell
  write_all_nets

  close $FILE_ID

  set in_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_in)
  set constraint_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_constraint)
  set out_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_out)

  # what is this???
  set fix_file $NETLIST(dir)$NETLIST(root).fixfile

  speedy read_timing_in_file $in_file

  if {[file readable $constraint_file]} {
      speedy read_timing_in_file $constraint_file
  }
  if {[file readable $fix_file]} {
      speedy read_fixfile $fix_file
  }

  speedy compute_timing

  speedy write_timing_out_file $out_file
  parse_pearl_output $out_file $mode

  # return to calling directory
  cd $save_dir

  ready

  # return OK exit status
  return 0
}


proc setup_pearl {{mode ""}} {

  global NETLIST SUFFIX cur_s cur_c scale DPC_TIMING SUE_TIMING_DATA HIERARCHY
  global env

  if {[is_icon $cur_s]} {
    puts "Aborting, can't run timing from an icon, only a schematic."
    return 69
  }

  if {[is_placement $cur_s]} {
    puts "Aborting, can't run timing from a placement, only a schematic."
    return 69
  }

  if {[info exists NETLIST(root)] != 1} {
    sue_error "Aborting, must dpc netlist first before timing."
    sue_error flush
    return 69
  }

#  if {![info exists env(SUE_DEMO)] && \
	  ![executable_exists "$DPC_TIMING(pearl,command) -version"]} {
#    sue_error "Aborting, can't execute $DPC_TIMING(pearl,command).  Check paths."
#    sue_error flush
#    return 69
#  }

  if {$mode == "timing"} {
    # write nets that are in a subcell
    write_all_nets [dpc_cell_name]

    return
  }

  busy

  puts "Setting up Pearl ..."

  # compute the filename for the verilog file
  upvar #0 SUE_$NETLIST(root) data
#  set filename "$NETLIST(dir)$NETLIST(root)$SUFFIX(dpc)"
  set filename $SUE_TIMING_DATA(verilog_file)

  set save_dir [pwd]
  cd $NETLIST(dir)

  set cmd_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_in)

  set out_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_out)

  # first write the commands out to a file

  # open to write the pearl command file
  if {[catch "open $cmd_file w" msg]} {
    # error
    puts "DPC TIMING ERROR: $msg"
    return 69
  }
  set FILE_ID $msg

  if {![file readable $DPC_TIMING(tech_file)]} {
    sue_error "Aborting, can't read file $DPC_TIMING(tech_file).  This file is specified in the .suerc file in the variable DPC_TIMING(tech_file)."
    sue_error flush

    ready
    return 69
  }

  puts $FILE_ID "readtechnology $DPC_TIMING(tech_file)"
  foreach lib $DPC_TIMING(ctlf_file) {
    if {[string first ctlf $lib] != -1} {
      puts $FILE_ID "readctlf $lib"
    } else {
      # assume it is an uncompiled tlf file
      puts $FILE_ID "readtlf $lib"
    }
  }

  global DPC_FROM_DEF DPC_SIZE

  foreach cell [array names DPC_FROM_DEF] {
    set file $DPC_SIZE($cell,dir)/$cell$SUFFIX(dpc)
    puts $FILE_ID "readverilog $file"
  }

  puts $FILE_ID "readverilog $filename"

  puts $FILE_ID "toplevelcell $NETLIST(root)"

  # if the suffix isn't rspf or dspf, assume a capacitance only file
  set suffix [string tolower [file extension $SUE_TIMING_DATA(parasitic_file)]]
  if {[string first spf $suffix] != -1} {
    # an rspf or dspf file
    puts $FILE_ID "readspf $SUE_TIMING_DATA(parasitic_file)"
  } elseif {[string first sdf $suffix] != -1} {
    # an sdf file
    puts $FILE_ID "readsdf $SUE_TIMING_DATA(parasitic_file)"
  } else {
    # assume it's just a plain old vanilla cap file
    puts $FILE_ID "readcapacitances $SUE_TIMING_DATA(parasitic_file)"
  }

  puts $FILE_ID "setmaxpossibilities $SUE_TIMING_DATA(max_paths)"

  # save the current canvas info
  set save_cur_c $cur_c
  set save_cur_s $cur_s
  set save_scale $scale
  set save_hierarchy $HIERARCHY

  # set for the top level
  set cur_s $NETLIST(root)
  global SUE_${cur_s}
  set cur_c $data(canvas)
  set scale $data(scale)
  set HIERARCHY ""

  set clks ""
  set net ""
  set suggested_clks [use_first SUE_TIMING_DATA(clk_names)]
  foreach id [$cur_c find withtag icon_input] {
    foreach net [bus_expand [find_timing_net_name [get_intersect_tag inst$id term]]] {

      if {[lsearch -exact $suggested_clks $net] != -1 && [lsearch -exact $clks $net] == -1} {
	# this is a good clock input, use it
	lappend clks $net
      }
    }
  }

  setl {period clk_fall} $SUE_TIMING_DATA(clk_period)
  set period [convert_if_no_units $period p]
  if {$clk_fall == ""} {
    # assume falling edge is mid way into period
    set clk_fall [pp_number [expr [parse_pp_number $period]/2.0]]
  }

  if {$clks == ""} {
    # no clocks, choose any input instead
    if {$net == ""} {
      # no inputs
      sue_error "Aborting, no inputs to schematic \"$cur_s\"."
      sue_error flush

      ready
      return 69
    }

    puts "DPC INFO:  No input matches clock names, assuming combinational logic with no clocks."

    puts $FILE_ID "clock -domain $DPC_TIMING(wave_name) -cycle_time $period -create_node _input_ 0 $clk_fall"

    set input _input_
    set clk _input_
    set type input

    set arrival 0
    set departure 0

  } else {
    puts $FILE_ID "waveform -name $DPC_TIMING(wave_name) -period $period -rise_first 0 $clk_fall"

    set input $DPC_TIMING(wave_name)
    set type arrival

    foreach clk $clks {
      puts $FILE_ID "clockwaveform $clk $DPC_TIMING(wave_name)"
      set trace($clk) 1
    }

    set arrival $SUE_TIMING_DATA(default_arrival_time)
    set departure $SUE_TIMING_DATA(default_setup_time)
  }

  # if there is a default, use the default driver cell
  # TODO: can't turn off driver cell, if set to null, takes default
  if {[use_first SUE_TIMING_DATA(driver_cell)] != ""} {
    setl {cell port} $SUE_TIMING_DATA(driver_cell)
    
    if {$port == ""} {
      # use the port name "out" for the output port if not specified
      set port out
    }

    puts $FILE_ID "drivercell $cell $port *"
    set string ""

  } else {
    # need to add this for every input
    set string "inputslew %s $SUE_TIMING_DATA(input_transition) $SUE_TIMING_DATA(input_transition) $SUE_TIMING_DATA(input_transition) $SUE_TIMING_DATA(input_transition)"
  }

  foreach id [$cur_c find withtag icon_input] {
    set net [find_timing_net_name [get_intersect_tag inst$id term]]
    if {![info exists trace($net)]} {
      puts $FILE_ID "$type $net $input ^ $arrival $arrival $arrival $arrival"

      if {$string != ""} {
	puts $FILE_ID [format $string $net]
      }

      set trace($net) 1
    }
  }

  # put capacitance on output nodes
  foreach id [$cur_c find withtag icon_output] {
    # find the net that is attached to this term
    set net [find_timing_net_name [get_intersect_tag term inst$id]]
    if {![info exists trace($net)]} {
      puts $FILE_ID "setnodecapacitance $net +$DPC_TIMING(out_cap)"
      if {$clks != ""} {
	puts $FILE_ID "departure $net $input ^ $departure $departure $departure $departure"
      }
      set trace($net) 1
    }
  }

  # restore the current canvas, schematic, scale and hierarchy.
  set cur_c $save_cur_c
  set cur_s $save_cur_s
  set scale $save_scale
  set HIERARCHY $save_hierarchy

  puts $FILE_ID "setpathfilter $DPC_TIMING(filter)"
#  puts $FILE_ID "setpathfilter -same_path"

  # this is the simplest
  puts $FILE_ID "idealclocks yes"

  # read in the constraint file if it exists
  if {[file readable $SUE_TIMING_DATA(constraint_file)]} {
    puts "Including constraint file: $SUE_TIMING_DATA(constraint_file)"
    puts $FILE_ID "include $SUE_TIMING_DATA(constraint_file)"
  } else {
    puts "Note: No constraint file: $SUE_TIMING_DATA(constraint_file)"
  }

  if {$clks == ""} {
    # combinational
    puts $FILE_ID "findpathsfrom $clk"
  } else {
    # sequential
    puts $FILE_ID "timingverify -check $SUE_TIMING_DATA(timing_type)"
  }

  if {$mode == "spice"} {

    puts $FILE_ID "setdelaypathformat out_delay delta_delay load_cap fanout out_rise_fall out_node device cell"

    # show the current critical path
    puts $FILE_ID "showpossibility $SUE_TIMING_DATA(cp,index)"

    puts $FILE_ID "spicedelaypath"

  } else {

    # to highlite the critical path
    puts $FILE_ID "setdelaypathformat out_delay delta_delay load_cap fanout out_rise_fall out_node device cell"

#    for {set i 1} {$i <= $SUE_TIMING_DATA(max_paths)} {incr i} {
#      puts $FILE_ID "showpossibility $i"
#    }

    puts $FILE_ID "showpossibility 1 $SUE_TIMING_DATA(max_paths)"

    # comments needed by reader
    puts $FILE_ID "\# done"
    puts $FILE_ID "\# done"

    puts $FILE_ID "findmincycletime"
    # comments needed by reader
    puts $FILE_ID "\# done"
    puts $FILE_ID "\# done"

    # hack to get pearl to write out all delays
    set tmpin_file $NETLIST(dir)$NETLIST(root).tmp_in
    set tmpout_file $NETLIST(dir)$NETLIST(root).tmp_out

    puts $FILE_ID "shownodematches * > $tmpin_file"
    puts $FILE_ID "system sed -e 's/^ /showdelays/' -e 's/^Found/\#/' $tmpin_file > $tmpout_file"
    puts $FILE_ID "include $tmpout_file"
    # clean up

    puts $FILE_ID "system rm -f $tmpin_file"
    puts $FILE_ID "system rm -f $tmpout_file"

    # save terminal data for this nell
    write_all_nets

#    puts $FILE_ID "findclockdelays"

    # show slow nodes
    puts $FILE_ID "findslownodes -limit $SUE_TIMING_DATA(max_transition) > $NETLIST(dir)$NETLIST(root)$SUFFIX(slow_nodes)"
  }

  # close the tempfile
  close $FILE_ID

  if {$mode == "spice"} {
    set status [run_pearl $cmd_file $out_file see]
  } else {
    set status [run_pearl $cmd_file $out_file $DPC_TIMING(out)]
  }

  if {$status > 0} {
    puts "Aborting, pearl return status is $status"

    catch "exec cat $out_file" msg
    puts $msg

    ready
    return $status
  }

  if {$mode != "spice"} {
    parse_pearl_output $out_file $mode

#    exec rm -f $out_file
  }

  # now delete the tmp files
#  exec rm -f $cmd_file

  # return to calling directory
  cd $save_dir

  ready

  # return OK exit status
  return 0
}


# create the script file to run pearl (required becuase exec in tcl
# is broken) and then run it.  Return the pearl exit status.

proc run_pearl {cmd_file out_file {type hidden}} {

  global DPC_TIMING env

  if {[info exists env(SUE_DEMO)]} {
    # special demo mode with no PEARL (but pearl output)

    puts "*DEMO* Mode.  Skipping Pearl and using existing timing files."
    puts "To exit demo mode, \"unset env(SUE_DEMO)\" from SUE or \"unsetenv SUE_DEMO\" from Unix."

    return 0
  }

  puts "\nRunning Pearl ..."

  if {$type == "hidden"} {
    # direct all output to output file
    if {[catch "exec csh -cf \"$DPC_TIMING(pearl,command) < $cmd_file >&! $out_file\"" msg]} {
      puts $msg
      return 69
    }

  } else {
    # direct all output to screen and output file
    if {[catch "exec csh -cf \"$DPC_TIMING(pearl,command) < $cmd_file |& tee $out_file >&! [exec tty]\"" msg]} {
      puts $msg
      return 69
    }
  }

  # show the user any error messages except bogus show possibility ones
  if {![catch "exec grep -i error: $out_file | grep -v possibility" msg]} {
    puts $msg
  }

  puts "Pearl completed.\n"

  return 0
}


proc parse_pearl_output {out_file {mode ""}} {

  global cur_s SUE_TIMING_DATA

  # waste any old values and deselect all
  select_ids ""

  set FILE_ID [open $out_file r]
     
  if {$mode == ""} {
    # parse critical paths

    set index 0
    while {[gets $FILE_ID line] >= 0} {
      if {[lindex $line 0] == "cmd>" && \
	      [lsearch "timingverify findpathsfrom" [lindex $line 1]] != -1} {
	while {[gets $FILE_ID line] >= 0} {
	  setl {first type constraint condition time} $line
	  if {$first == "cmd>"} {
	    break
	  }

	  if {[regexp {[0-9]+:} $first]} {
	    # this is a path
	    incr index 
	    set string($index) "$type $condition $time"
	  }
	}
	break
      }
    }

    set index 0
    set poss 0
    while {$poss || [gets $FILE_ID line] >= 0} {
      if {[lindex $line 2] == "done"} {
	break
      }
      if {[lindex $line 0] == "Possibility"} { 
	# read in a critical path
	set poss 0
	incr index
	set SUE_TIMING_DATA(cp,$index) ""
	set SUE_TIMING_DATA(cpmessage,$index) {{}}
	set node "???"
	set first_node ""
	set last_node ""
	
	set first 1
	while {[gets $FILE_ID line] >= 0} {
	  if {[lindex $line 0] == "cmd>"} {
	    break
	  }
	  if {[lindex $line 0] == "Possibility"} { 
	    # next one
	    set poss 1
	    break
	  } 

	  if {$first} {
	    if {[lindex $line 0] == "Delay"} {
	      # done with first part
	      set first 0

	      lappend SUE_TIMING_DATA(cpmessage,$index) ""
	    }

	    lappend SUE_TIMING_DATA(cpmessage,$index) $line
	    continue
	  }

	  lappend SUE_TIMING_DATA(cpmessage,$index) $line

	  set word [string tolower [lindex $line 0]]
	  switch [string range _$word 0 5] {
	    _error - _warni - "_-----" {
	      # ignore warnings and errors here.
	      continue
	    }
	  }

	  switch [llength $line] {
	    9 {
	      # normal path
	      setl {delay delta cap fanout rf node dir cell} $line
	  
	      lappend SUE_TIMING_DATA(cp,$index) "cell $cell"
	      lappend SUE_TIMING_DATA(cp,$index) "net $node $delay $dir$rf"

	      set last_node $node

	      if {$first_node == ""} {
		set first_node $cell
	      }
	    }

	    8 {
	      # input node
	      setl {delay delta cap fanout rf node dir} $line
	  
	      lappend SUE_TIMING_DATA(cp,$index) "net $node $delay $dir$rf"

	      if {$first_node == ""} {
		set first_node $node
	      }
	    }

	    7 {
	      # normal path + net
	      setl {delay delta cap fanout rf node dir} $line
	      if {$last_node == $node} {
		set SUE_TIMING_DATA(cp,$index) \
		    [lreplace $SUE_TIMING_DATA(cp,$index) end end \
			 "net $node $delay $dir$rf"]
	      }

	      set last_node ""
	    }

	    5 {
	      # input node
	      setl {delay fanout rf node dir} $line
	  
	      lappend SUE_TIMING_DATA(cp,$index) "net $node $delay $dir$rf"
	    }
	  }
	}

	set SUE_TIMING_DATA(cp,value,$index) \
	    "$string($index) \($first_node -> $node\)"

	lappend SUE_TIMING_DATA(cpmessage,$index) ""
      }
    }

    # number of critical paths
    set SUE_TIMING_DATA(critical_paths) $index

    # read the min cycle time

    while {[gets $FILE_ID line] >= 0} {
      if {[lrange $line 0 1] == "cmd> findmincycletime"} {
	break
      }
    }

    set answer ""
    set before_space 1
    while {[gets $FILE_ID line] >= 0} {
      if {[lindex $line 0] == "cmd>"} {
	break
      }

      if {$line == ""} {
	set before_space 0
	continue
      }

      if {[lrange $line 0 1] == "No timing"} {
	set answer ""
	continue
      }

      if {$before_space} {
	lappend answer $line
      }
    }
    if {$answer != ""} {
      # show min cycle time if there is one
      puts "Minimum cycle time (includes setup times):"
      puts [join $answer \n]
      puts ""
    }
  }

  # read term values
  set cell [string trimright [dpc_cell_name] /]
  set length [expr [string length $cell] + 1]

  set error 0
  set SUE_TIMING_DATA($cell,net_values) ""
  set got_data 1
  set name ""

  set clks [use_first SUE_TIMING_DATA(clk_names)]

  while {[gets $FILE_ID line] >= 0} {

    set word [string tolower [lindex $line 0]]
    if {[string first $word "error warning"] == 0} {
      # ignore warnings and errors here.
      continue
    }

    if {[lindex $line 1] == "showdelays"} {
      # reset for new show command
      set name [lindex $line 2]
      set got_data 0
      continue
    }

    if {[lindex $line 0] == "cmd>"} {
      set name ""
      continue
    }

    if {$name == ""} {
      continue
    }

    if {$line == "Clock network node"} {
      continue
    }

    if {$word == "constant"} {
      set name ""
      continue
    }

    # must be data
    set got_data 1

    if {[lsearch $clks $name] != -1} {
      # special case for clocks
# TODO falling edge of clock designs
      if {[lindex $line 1] == "^"} {

	set rise [lindex $line 3]
	set pos [string first - $rise]
	if {$pos > 0} {
	  # two numbers, second always bigger
	  set rise [string range $rise [expr $pos + 1] end]
	}
	# else one number, maybe negative

	lappend SUE_TIMING_DATA($cell,net_values) \
	    "$name [parse_pp_number $rise]"
      }
      continue
    }

    set rise [lindex $line 3]

    if {[lindex $line 5] == ""} {
      # must be on the next line
      if {[gets $FILE_ID line2] < 0} {
	break
      }
      set fall [lindex $line2 3]

    } else {
      set fall [lindex $line 5]
    }

    set pos [string first - $rise]
    if {$pos > 0} {
      # two numbers, second always bigger
      set rise [string range $rise [expr $pos + 1] end]
    }
    # else one number, maybe negative

    set pos [string first - $fall]
    if {$pos > 0} {
      # two numbers, second always bigger
      set fall [string range $fall [expr $pos + 1] end]
    }
    # else one number, maybe negative

    set rise [parse_pp_number $rise]
    set fall [parse_pp_number $fall]

    if {[catch "expr $rise"] || [catch "expr $fall"]} {
      # skip these, not good value
#      puts "WARNING: no timing for net $name."
      continue
    }

    if {[info exists values($name)]} {
      set values($name) [max $values($name) $rise $fall]
    } else {
      set values($name) [max $rise $fall]
    }
  }

  foreach name [array names values] {
    lappend SUE_TIMING_DATA($cell,net_values) "$name $values($name)"
  }

  if {[info exists no_timing_nets]} {
    regsub -all {\{|\}} $no_timing_nets "" no_timing_nets
    puts "DPC WARNING, No timing for nets: $no_timing_nets\n"
  }

  # close the file
  close $FILE_ID
}


# displays the critical path on the schematic by selecting the 
# wires/instances in the paths and displaying the timing along it.

proc display_critical_path {{slopes ""} {index ""}} {

  global cur_s SUE_TIMING_DATA NETLIST

  if {$index == ""} {
    set index $SUE_TIMING_DATA(cp,index)
  }

  if {![info exists SUE_TIMING_DATA(cp,$index)]} {
    # no critical paths
    puts "Aborting, can't highlite critical path $index."
    return
  }

  if {$SUE_TIMING_DATA(design) != $NETLIST(root)} {
    warning "Aborting, must dpc_it on $NETLIST(root) first."
    catch "destroy .cp"
    return
  }

  if {[is_placement $cur_s]} {
    set return [display_cp_on_placement $slopes $index]
  } else {
    set return [display_cp_on_schematic $slopes $index]
  }

  # show the critical path message to the user
  if {$return == 1} {
    display_cp_message $index
  }
}


# display the critical path on a placement

proc display_cp_on_placement {slopes index} {

  global SUE_TIMING_DATA HIERARCHY DPC_ABS cur_s cur_c scale COLORS FONT 
  global DPC DPC_TIMING DPC_SIZE NETLIST

  upvar #0 TERMS_$cur_s TERMS

  if {![info exists TERMS]} {
    # haven't netlisted yet
    sue_error "Aborting, can't display critical path on this cell.  It probably wasn't in the hierarchy."
    sue_error flush
    return ""
  }

  if {"$SUE_TIMING_DATA(design)_placement" != $cur_s} {
    warning "Aborting, incorrect placement.  Must goto $SUE_TIMING_DATA(design)_placement."
    return ""
  }

  busy

  # clear selection
  select_ids ""

  set last_cell ""
  set last_net ""
  set value ""
  set x2 ""

  integer_scale

  # walk thru critical path, highliting
  foreach pair $SUE_TIMING_DATA(cp,$index) {

    setl {type name this_value slope} $pair
    
    switch $type {
      cell {

	while {[catch {nl_get_cell_reference $name} ref]} {
	  # can't find this try higher
	  set name [file dirname $name]
    
	  if {$name == ""} {
	    continue
	  }
	}

	# figure out name of cell for highliting
# TODO: fix for pathmill
	if {0 && [use_first DPC_ABS($name)] == ""} {
	  if {$DPC_TIMING(simulator) == "pathmill"} {
	    set stop 1
	    # in pathmill, cells often include transistory stuff
	    # that must be removed.

	    while {[string first / $name] != -1} {
	      # strip off last part of hierarchy
	      set name [file dirname $name]
	      
	      if {[use_first DPC_ABS($name)] != ""} {
		# found it
		set stop 0
		break
	      }
	    }

	    if {$stop} {
	      # unknown, skip
	      continue
	    }
	  } else {
	    # unknown, skip
	    continue
	  }
	}

	# get port location
	setl {x y} [display_find_port_location $name $last_net]
      
	# select the cell
	set id [find_by_name $name first]

	if {$id == ""} {
	  # probably not expanded, select hier cell
	  set list [split $name /]
	  for {set i [expr [llength $list] - 2]} {$i >= 0} {incr i -1} {
	    set id [find_by_name [join [lrange $list 0 $i] /] first]
	    if {$id != ""} {
	      # found it, add a tmp box and label for the cell

	      # get cell info
	      if {[info exists DPC_ABS($name)]} {
		setl {tmp1 type row col delta_row delta_col} $DPC_ABS($name)
	      } else {
		# not hierarchical, get from nl
		setl {col row} [nl_get_cell_location $name]
		set col [expr $col / $DPC(xscale)]
		set row [expr $row / $DPC(yscale)]

		set type [nl_get_reference_name [nl_get_cell_reference $name]]
# can't use because it's a string
#		set type [nl_get_cell_reference $name]

		setl {delta_col delta_row} $DPC_SIZE($type)
	      }

	      # get the center of the cell
	      set xo [expr $scale * ($row + $delta_row/2.0)]
	      set yo [expr $scale * ($col + $delta_col/2.0)]

	      $cur_c create line $row $col $row [expr $col + $delta_col] \
		  [expr $row + $delta_row] [expr $col + $delta_col] \
		  [expr $row + $delta_row] $col $row $col \
		  -tags "tmp_scale tmp1" -fill $COLORS(anchor) -stipple gray50
	      $cur_c create text $xo [expr $yo - 0.5 * $scale] \
		  -tags "tmp1 scaletext size_standard" \
		  -fill $COLORS(anchor) -text $type \
		  -font $FONT(standard,$scale)
	      $cur_c create text $xo [expr $yo + $scale] \
		  -tags "tmp1 scaletext size_small" \
		  -fill $COLORS(anchor) -text $name \
		  -font $FONT(small,$scale)
	      break
	    }
	  }
	}

	if {$id == ""} {
	  # still can't find it, punt
	  continue
	}

	if {$last_cell == $name} {
	  # already got this one
	  continue
	}

	# select it
	$cur_c addtag selected withtag inst$id

	# if first cell, just add timing on it
	if {$last_cell == "" && [use_first value] != ""} {
	  if {$DPC(PINS) && \
		  ![catch {nl_get_port_location $last_net} pair]} {
	    # add timing to the pin
	    set x1 [expr 1.0 * $scale * [lindex $pair 1] / $DPC(yscale)]
	    set y1 [expr 1.0 * $scale * [lindex $pair 0] / $DPC(xscale)]

	    $cur_c create line $x1 $y1 $x $y -tags "tmp1" \
		-fill $COLORS(anchor) -arrow last

	    set x $x1
	    set y $y1
	  }

	  # note: uses input port location
	  $cur_c create text $x $y \
	      -tags "tmp1 scaletext size_standard" \
	      -fill $COLORS(anchor) -text $value \
	      -font $FONT(standard,$scale)
	  set value ""
	}

	# otherwise draw a wire to it from the last cell
	if {$last_cell != "" && $value != ""} {
	  # draw a temporary wire to display the connection

	  # no port location, use center of cell
	  setl {x1 y1} [display_find_port_location $last_cell $last_net]
	
	  if {$x2 != ""} {
	    if {$x1 != $x2 || $y1 != $y2} {
	      # draw a dotted line from input to output of gate
	      $cur_c create line $x1 $y1 $x2 $y2 -tags "tmp1" \
		  -fill $COLORS(anchor) -arrow first -stipple gray50
	    }
	  }
	
	  set x2 $x
	  set y2 $y

	  $cur_c create line $x1 $y1 $x $y -tags "tmp1" \
	    -fill $COLORS(anchor) -arrow last
	
	  # label the time on the wire
	  $cur_c create text [expr ($x1 + $x)/2] [expr ($y1 + $y)/2] \
	      -tags "tmp1 scaletext size_standard" \
	      -fill $COLORS(anchor) -text $value \
	      -font $FONT(standard,$scale)
	  set value ""
	}
      
	# remember this cell
	set last_cell $name
      }

      net {
	set last_net $name

	# save the value
	if {$slopes != "" && $slope != ""} {
	  set value "$this_value\n$slope"
	} else {
	  set value $this_value
	}
      }
    }
  }
  
  if {$value != "" && $last_cell != ""} {
    if {$DPC(PINS) && \
	    ![catch {nl_get_port_location $last_net} pair]} {
      # add timing to the pin
      set x [expr 1.0 * $scale * [lindex $pair 1] / $DPC(yscale)]
      set y [expr 1.0 * $scale * [lindex $pair 0] / $DPC(xscale)]

      setl {x1 y1} [display_find_port_location $last_cell $last_net]
	
      if {$x2 != ""} {
	if {$x1 != $x2 || $y1 != $y2} {
	  # draw a dotted line from input to output of gate
	  $cur_c create line $x1 $y1 $x2 $y2 -tags "tmp1" \
	      -fill $COLORS(anchor) -arrow first -stipple gray50
	}
      }

      $cur_c create line $x1 $y1 $x $y -tags "tmp1" \
	  -fill $COLORS(anchor) -arrow last

    } else {
      # just add timing info on this last cell
      setl {x y} [display_find_port_location $last_cell ""]
    }

    $cur_c create text $x $y \
	-tags "tmp1 scaletext size_standard" \
	-fill $COLORS(anchor) -text $value \
	-font $FONT(standard,$scale)
  }
  
  # change color to show selected
  show_color selected $COLORS(selected)

  $cur_c scale tmp_scale 0 0 $scale $scale
  $cur_c dtag tmp_scale

  # if we just made these tmp then the select_id would blow them away.
  $cur_c addtag tmp withtag tmp1
  $cur_c dtag tmp1
  
  unscale
  
  ready
  return 1
}


# find the port location in the cell for display cp on placement

proc display_find_port_location {name net} {

  global scale DPC XFORM DPC_SIZE

  # NOTE: net could be attached to multiple ports, using only
  # the first one.

#  set ref [nl_get_reference_name [nl_get_cell_reference $name]]
  set ref [nl_get_cell_reference $name]

  if {$net == "" || [catch {nl_get_net_pins -recursive -noassign $net} pins]} {
    # this is not a valid net, just return the center of the cell
    setl {x y} [nl_get_cell_location $name]
    if {$y == ""} {
      # TODO: return "" but calling procs must deal with
      return [list 0 0]
    }

    if {[info exists DPC_SIZE($ref)]} {
      # middle of cell
      setl {dx dy} $DPC_SIZE($ref)
      set dx [expr $dx / 2.0]
      set dy [expr $dy / 2.0]

    } else {
      set dx 0
      set dy 0
    }

    return [list [expr $scale * (1.0*$y/$DPC(yscale) + $dy)] \
	      [expr $scale * (1.0*$x/$DPC(xscale) + $dx)]]
  }

  set found 0
  foreach pin $pins {
    if {[nl_get_pin_owner $pin] == $name} {
      # found it
      set found 1
      break
    }
  }

  if {!$found} {
    # can't find it
    return "0 0"
  }

  return [_pin_location $pin $scale]
}


# display the critical path on the current schematic

proc display_cp_on_schematic {slopes index} {

  global SUE_TIMING_DATA HIERARCHY cur_s cur_c scale COLORS FONT 
  global DPC_TIMING DPC_NET_EQ RDPC_NET_EQ

  upvar #0 TERMS_$cur_s TERMS

  if {![info exists TERMS]} {
    # haven't netlisted yet
    sue_error "Aborting, can't display critical path on this cell.  It probably wasn't in the hierarchy."
    sue_error flush
    return ""
  }

  if {$SUE_TIMING_DATA(design) != $cur_s && \
	  $SUE_TIMING_DATA(design) != [lindex [split [lreverse $HIERARCHY] ,] 0]} {
    warning "Aborting, bad hierarchy.  Must go to top level cell ($SUE_TIMING_DATA(design)) and then push down to desired cell to display critical path."
    return ""
  }

  busy

  # clear selection
  select_ids ""

  # get the name in this critical path
  set cell [dpc_cell_name ""]
  set length [string length $cell]

  set io_possible 0

  # scale to 10 for assigns.  Also needed integer_scale
  set save_scale $scale
  scale_canvas 10
  set del [expr $scale/3.0]
#  integer_scale

  # check for special case
  if {$DPC_TIMING(simulator) == "pathmill" && $HIERARCHY != ""} {
    # is this a spice cell that has not been processed into DPC_NET_EQ yet?
    set ids [concat [$cur_c find withtag icon_input] \
		 [$cur_c find withtag icon_output] \
		 [$cur_c find withtag icon_inout]]

    set id [lindex $ids 0]

    global ${cur_s}_inst$id
    set name [set ${cur_s}_inst${id}(_name)]

    if {![info exists DPC_NET_EQ($cell$name)]} {
      # ok, need to add these

      foreach id $ids {
	global ${cur_s}_inst$id
	set name [set ${cur_s}_inst${id}(_name)]

	set node [climb_hierarchy $name]
	# turn into a full name
	set name $cell$name

	# TODO fix for nl
	if {![info exists RDPC_NET_EQ]} {
	  get_net_equiv $name
	}

	# add to both DPC_NET_EQ and RDPC_NET_EQ arrays
	if {[info exists DPC_NET_EQ($node)]} {
	  set DPC_NET_EQ($name) $DPC_NET_EQ($node)
	} else {
	  set DPC_NET_EQ($name) $node
	}

	set xlate $DPC_NET_EQ($name)
	lappend RDPC_NET_EQ($xlate) $name
	set RDPC_NET_EQ(p,$name) $xlate
      }
    }
  }

  set not_cp 1
  set cells 0

  # walk thru the critical path highliting stuff visible on this schematic
  foreach pair $SUE_TIMING_DATA(cp,$index) {

    setl {type name value slope} $pair

    if {$type == "cell" && $cell != "" && [string first $cell $name] != 0} {
      incr cells

      if {$type == "cell" || !$io_possible} {
	# wrong cell
	set io_possible 0
	continue
      }
      # this might be a cell connected up through the hierarchy.
      # need to find its name in this level
      set name [find_name_this_schematic $name $cell]
      if {$name == ""} {
	continue
      }
      set name "$cell$name"
    }

    switch $type {
      cell {
	# select the gate
	set io_possible 1

	# at least this schematic is in the cp
	set not_cp 0

	# fix up the name for hierarchy
	set name [string range $name $length end]

	set ids [find_by_name $name]
      
	if {$ids != ""} {
	  select_ids $ids add no_display
	} else {
	  setl {root bit} [split $name \$]
	  set ids [find_by_name $root]
	  if {$ids != ""} {
	    # one of these instances
	    select_ids $ids add no_display
	    
	    setl {x y} [center [lindex $ids 0]]
	    
	    if {[is_tagged $ids rotate]} {
	      $cur_c create text $x $y -tags "tmp1 scaletext size_standard" \
		  -fill $COLORS(anchor) -text "\[$bit\]" \
		  -font $FONT(standard,$scale) -rotate 1
	    } else {
	      $cur_c create text $x $y -tags "tmp1 scaletext size_standard" \
		  -fill $COLORS(anchor) -text "\[$bit\]" \
		  -font $FONT(standard,$scale)
	    }
	    
	  } else {
	    # must be inside an instance, select the instance
	    # TODO: fix for nested???
	    set name [lindex [split $name /] 0]
	    
	    if {$name != ""} {
	      set id [find_by_name $name first]
	      select_ids $id add no_display
	    }
	  }
	}
      }

      net {
	# select the net

	if {$slopes != "" && $slope != ""} {
	  set value "$value\n$slope"
	}

	foreach name [get_net_equiv $name] {
	  if {![info exists select_nets($name)]} {

	    setl {ident this_schem x y pos} $name
	    if {$ident == "id"} {
	      # probably a bus combiner or some such, select it
	      if {$this_schem == $cur_s} {
		# correct schematic.  need to figure out the id from the coords
		# TODO: should cache these results
		set ids [$cur_c find enclosed \
			     [expr $x - $del] [expr $y - $del] \
			     [expr $x + $del] [expr $y + $del]]
		
		set id [lindex $ids $pos]
		
		select_ids $id add no_display
	      }
	      continue
	    }
	    
	    # fix up the name for hierarchy
	    if {$cell != "" && ![string first $cell $name] == 0} {
	      # this is net is not in this cell, skip
	      continue
	    }

	    set name [string range $name $length end]
	    
	    # save this net name for later when all cells are selected
	    set select_nets($name) $value
	  }
	}
      }
    }
  }

  set del [expr $scale * 8.0]

  # now show timing numbers on selected nets
  foreach name [array names select_nets] {

    # get terminals of this name
    set ids [find_by_name $name terms]

    if {$ids == ""} {
      continue
    }

    select_wire_by_name $name add no_display

    # look for i/o's to put value on
    set select_ids ""

    # only put on terminals of selected instances, otherwise it
    # seems to follow wires that aren't on critical path.
    foreach id $ids {
      if {[is_tagged $id selected]} {
	lappend select_ids $id
      }
    }

    if {$select_ids == ""} {
      # nothing selected, use all
      set select_ids $ids
    }

    set coords ""

    foreach id $select_ids {
      # add values to terminal
      setl {x y} [center $id]

      # if close to one already, skip
      set skip 0
      foreach coord $coords {
	setl {x1 y1} $coord
	if {[expr abs($x1-$x)] < $del && [expr abs($y1-$y)] < $del} {
	  set skip 1
	  break
	}
      }
      lappend coords "$x $y"
      if {$skip} {
	continue
      }

      if {[is_tagged $id rotate]} {
	$cur_c create text $x $y -tags "tmp1 scaletext size_standard" \
	    -fill $COLORS(anchor) -text $select_nets($name) \
	    -font $FONT(standard,$scale) -rotate 1
      } else {
	$cur_c create text $x $y -tags "tmp1 scaletext size_standard" \
	    -fill $COLORS(anchor) -text $select_nets($name) \
	    -font $FONT(standard,$scale)
      }
    }
  }

  # if we just made these tmp then the select_id would blow them away.
  $cur_c addtag tmp withtag tmp1
  $cur_c dtag tmp1

  scale_canvas $save_scale
#  unscale

  ready

  if {$not_cp && $cells > 0} {
    sue_error "Aborting, can't display critical path thru this cell.  It probably wasn't in the critical path or is a leaf cell."
    sue_error flush
    return 0
  }

  return 1
}


# displays the critical path message.

proc display_cp_message {index} {

  global SUE_TIMING_DATA

  if {[use_first SUE_TIMING_DATA(cpmessage,display)] == $index} {
    # already displayed this one
    return
  }
  set SUE_TIMING_DATA(cpmessage,display) $index

  if {[info exists SUE_TIMING_DATA(cp,value,$index)]} {
    regsub -all {\{|\}} $SUE_TIMING_DATA(cp,value,$index) "" cpdelay
    msg_window "selected: critical path $index:  $cpdelay" no_save
    puts "critical path $index:  $cpdelay"
    puts [join [use_first SUE_TIMING_DATA(cpmessage,$index)] \n]
  } else {
    puts "No critical paths found.  Probably a problem in the schematic."
  }
}


# Displays the static time of each terminal on the terminal temporarily.
# Cleared with any click.

proc display_timing {} {

  global cur_s cur_c scale COLORS FONT SUE_TIMING_DATA HIERARCHY DPC_TIMING

  # figure out the cell path to here
  set cell [string trimright [dpc_cell_name] /]

  if {![info exists SUE_TIMING_DATA($cell,net_values)]} {
    # no timing data here.
    # if there is timing for the top level hierarchy but not this
    # level, query pearl for this level
    if {![info exists SUE_TIMING_DATA(_TOP_,net_values)]} {
      puts "Aborting, can't display timing"
      return
    } else {
      # run timing
      if {[setup_$DPC_TIMING(simulator) timing] > 0} {
	# failed
	return
      }
    }
  }

  busy

  set fscale [expr int(ceil($scale))]

  # remove all tmp values
  $cur_c delete tmp

  set mult 1.0
  switch $DPC_TIMING(simulator) {
    pathmill {
      set mult 1.0e-9
    }
    primetime {
      set mult [parse_pp_number $DPC_TIMING(db_time_units)]
    }
    pearl {
      set mult 1.0
    }
  }

  global DPC_NET_EQ NETLIST

  set prefix [dpc_cell_name ""]
  set net_values ""

  # save values
  upvar #0 TIMING_TERMS values
  if {![info exists values]} {
    # only do this once
    foreach list $SUE_TIMING_DATA(_TOP_,net_values) {
      setl {name value} $list
      set values($name) [expr $mult * $value]
    }
  }

  foreach name [array names SUE_TIMING_DATA $cur_s,terms,*] {
    set node [string trimleft [lindex [split $name ,] 2] /]
    
    if {[info exists values($prefix$node)]} {
      lappend net_values $node
    } else {
      # might be an i/o
      if {[info exists DPC_NET_EQ($prefix$node)]} {
	set top_node $DPC_NET_EQ($prefix$node)
	if {[info exists values($top_node)]} {
	  lappend net_values $node
	  set values($prefix$node) $values($top_node)
	}
      } else {
	# if this is a spice net, use this
	set top_node [climb_hierarchy $node]
	if {[info exists values($top_node)]} {
	  lappend net_values $node
	  set values($prefix$node) $values($top_node)
	} elseif {[info exists DPC_NET_EQ($top_node)]} {
	  set top_node $DPC_NET_EQ($top_node)
	  if {[info exists values($top_node)]} {
	    lappend net_values $node
	    set values($prefix$node) $values($top_node)
	  }
	}
      }
    }
  }

  upvar #0 TERMS_$cur_s TERMS

  foreach list $net_values {

    set name [lindex $list 0]

    if {[info exists SUE_TIMING_DATA($cur_s,terms,$name)]} {
      catch {unset close}

      foreach id $SUE_TIMING_DATA($cur_s,terms,$name) {

	# if this is a bus, take the max of all values here
	# prevents "optical ORing"
	if {[info exists TERMS($id)] && [is_cbus $TERMS($id)]} {
	  set bus $prefix$TERMS($id)
	  if {[info exists bus_value($bus)]} {
	    # use the bus value
	    set value $bus_value($bus)
	  } else {
	    # make the bus value
	    set value 0

	    foreach bit [cbus_expand $TERMS($id)] {
	      if {[info exists values($prefix$bit)]} {
		set value [max $value $values($prefix$bit)]
	      }
	    }
	    set bus_value($bus) $value
	  }

	} else {
	  set value $values($prefix$name)
	}

	# Put the values on the terminals
	set coords [$cur_c coords $id]
	if {$coords == ""} {
	  # user probably changed icon
	  continue
	}

	set x [expr round([lindex $coords 0])]
	set y [expr round([lindex $coords 1])]

	# if this is close to another id on the same net, don't show it
	if {[info exists close(y,$x)]} {
	  if {[expr abs($close(y,$x)-$y)/$scale] < 20} {
	    # too close
	    continue
	  }
	}
	if {[info exists close(x,$y)]} {
	  if {[expr abs($close(x,$y)-$x)/$scale] < 20} {
	    # too close
	    continue
	  }
	}
	set close(y,$x) $y
	set close(x,$y) $x

	if {[is_tagged $id rotate]} {
	  $cur_c create text $x $y -tags "tmp scaletext size_standard" \
	      -fill $COLORS(anchor) -text [pp_number $value] \
	      -font $FONT(standard,$fscale) -rotate 1
	} else {
	  $cur_c create text $x $y -tags "tmp scaletext size_standard" \
	      -fill $COLORS(anchor) -text [pp_number $value] \
	      -font $FONT(standard,$fscale)
	}
      }
    }
  }

  ready
}


proc find_timing_net_name {id {separator /} {prefix ""}} {

  global cur_s HIERARCHY

  upvar #0 TERMS_$cur_s TERMS

  if {![info exists TERMS($id)]} {
    # punt
    return ""
  }

  set root ""

  # concatenate the cell names of the hierarchy onto
  # the front of the net to produce the full net name
  foreach schematic $HIERARCHY {
    upvar #0 TERMS_[lindex [split $schematic ,] 0] TT
    set root "$TT([lindex [split $schematic ,] 1])$separator$root"
  }

  set net ""
  foreach one [split $TERMS($id) ,] {
    if {[string first ' $one] == -1} {
      lappend net "$prefix$root$one"
    } else {
      # constant, don't add prefix
      lappend net $one
    }
  }

  return [join $net ,]
}


# Looks up the hierarchy to resolve net name

proc find_name_this_schematic {name cell} {

  foreach eq_name [get_net_equiv $name] {
    if {[string first $cell $eq_name] == 0} {
      # got it, strip off path
      return [string range $eq_name [string length $cell] end]
    }
  }

  # nothing appropriate
  return ""
}


# Creates a top level window for displaying critical paths

proc select_critical_path {} {

  global SUE_TIMING_DATA WIN DPC_TIMING NETLIST

  set win .cp

  # Just in case there is an old one around
  if {![catch "winfo rootx $win" x]} {
    set y [winfo rooty $win]

    # hack to account for borders
    incr x -3
    incr y -25

    catch "destroy $win"

  } else {
    set x [max 0 [expr [winfo rootx $WIN] - 100]]
    set y [expr [winfo rooty $WIN] + 100]
  }

  if {![info exists SUE_TIMING_DATA(cp,1)]} {
    warning "Aborting, must dpc_it first."
    return
  }

  if {$SUE_TIMING_DATA(design) != $NETLIST(root)} {
    warning "Aborting, must dpc_it on $NETLIST(root) first."
    return
  }

  toplevel $win 

  wm geometry $win "+$x+$y"
  wm title $win "DPC Timing for $NETLIST(root)"

  # don't let user resize this
  wm resizable $win 0 0
    
  label $win.note -text "Select Critical Path:"

  pack $win.note -side top

  set max_paths 20

  if {$SUE_TIMING_DATA(critical_paths) <= $max_paths} {

    set c [frame $win.entry]
    pack $c -side left
    for {set i 1} {$i <= $SUE_TIMING_DATA(critical_paths)} {incr i} {
    
      set text "$i: $SUE_TIMING_DATA(cp,value,$i)"
      regsub -all {\{|\}} $text "" text

      set b [radiobutton $c.cp$i \
		 -text $text \
		 -variable SUE_TIMING_DATA(cp,index) \
		 -command {launch "display_critical_path_instances ifexists"} \
		 -value $i \
		 -relief raised \
		 -anchor w]

      pack $b -side top -fill x
    }

  } else {
    # put in a scroll bar, which requires a canvas

    set c [frame $win.entry]
    pack $c -side left -expand 1 -fill both

    set canvas $c.c

    scrollbar $c.vscroll -relief sunken -command "$canvas yview" \
      -highlightthickness 0
    pack $c.vscroll -side left -fill y

    canvas $canvas -highlightthickness 0 -yscrollcommand "$c.vscroll set"
    pack $canvas -side left -expand 1 -fill both

    set f [frame $canvas.f]
    $canvas create window 0 0 -window $f -anchor nw

    for {set i 1} {$i <= $SUE_TIMING_DATA(critical_paths)} {incr i} {
    
      set text "$i: $SUE_TIMING_DATA(cp,value,$i)"
      regsub -all {\{|\}} $text "" text



      set b [radiobutton $f.cp$i \
		 -text $text \
		 -variable SUE_TIMING_DATA(cp,index) \
		 -command {launch "display_critical_path_instances ifexists"} \
		 -value $i \
		 -relief raised \
		 -anchor w]

      grid $b -sticky w
    }

    # wait for the size of this
    tkwait visibility $b
    # compute and setup sizes of stuff
    set incr [lindex [grid bbox $f 0 0] 3]
    set width [winfo reqwidth $f]
    set height [winfo reqheight $f]
    $canvas config -scrollregion "0 0 $width $height"
    $canvas config -yscrollincrement $incr
    set max [min $max_paths $SUE_TIMING_DATA(critical_paths)]
    set height [expr $incr * $max]
    $canvas config -width $width -height $height
  }

  frame $win.buttons

  frame $win.default -relief sunken -bd 1
  button $win.done -text "Display CP" -padx 1 -pady 1 \
    -command {launch "display_critical_path slopes"}
  pack $win.done -in $win.default -padx 1m -pady 1m -ipadx 2m
  pack $win.default -side left -in $win.buttons \
      -padx 4m -ipadx 1m -pady 1m

  button $win.all -text "Display All" -padx 1 -pady 1 \
    -command {launch display_timing}
  pack $win.all -side left -in $win.buttons \
      -padx 4m -ipadx 1m -pady 1m

  button $win.cpi -text "CP Instances" -padx 1 -pady 1 \
    -command {launch "display_critical_path_instances raise"}
  pack $win.cpi -side left -in $win.buttons \
      -padx 4m -ipadx 1m -pady 1m

  # exit
  button $win.cancel -text "Close" -padx 1 -pady 1 \
    -command {catch "destroy .cp"}
  pack $win.cancel -side left -in $win.buttons \
    -padx 4m -ipadx 2m -pady 1m

  pack $win.buttons -side bottom
  pack $c -side top -fill x
   
  bind $win <Control-c> {catch {destroy .cp}}
  bind $win <Escape> {catch {destroy .cp}}

  # update this
  display_critical_path_instances ifexists
}


# figure out the cell path to this schematic for dpc
# uses the critical path to help on bused hierarchical cells

proc dpc_cell_name {{top _TOP_}} {

  global SUE_TIMING_DATA HIERARCHY

  if {$HIERARCHY == ""} {
    return $top
  }

  set cell ""
  set backup ""
  foreach pair $HIERARCHY {
    setl {schematic id} [split $pair ,]
    upvar #0 TERMS_$schematic TT

    # choose correct bit of bused instance that is in critical path
    if {[is_bus $TT($id)]} {
      set cell "[bus_root $TT($id)]\$\[0-9\]*$/$cell"
    } else {
      set cell "$TT($id)/$cell"
    }
    set backup "$TT($id)/$backup"
  }

  set string "cell $cell"
  regsub -all {\$} $string {\$} string

  if {[info exists SUE_TIMING_DATA(cp,index)] && \
	  [info exists SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(cp,index))] && \
	  [regexp $string $SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(cp,index)) a]} {
    # found in cp, use that
    return [lindex $a 1]
  } else {
    # could find, get booby prize
    return $backup
  }
}


# special procs for primetime

proc setup_primetime {{mode ""}} {

  global NETLIST SUFFIX cur_s cur_c scale DPC_TIMING SUE_TIMING_DATA HIERARCHY

  if {[is_icon $cur_s]} {
    puts "Aborting, can only display timing information in schematics."
    return 69
  }

  if {[lindex [lreverse [split $cur_s _]] 0] == "placement"} {
    puts "Aborting, can't display timing information in a placement, only critical paths."
    return 69
  }

  if {[info exists NETLIST(root)] != 1} {
    sue_error "Aborting, must dpc netlist first before timing."
    sue_error flush
    return 69
  }

#  if {![info exists env(SUE_DEMO)] && \
	  ![executable_exists "$DPC_TIMING(primetime,command) -version"]} {
#    sue_error "Aborting, can't execute $DPC_TIMING(primetime,command).  Check paths."
#    sue_error flush
#    return 69
#  }

  if {$mode == "timing"} {
    # write nets that are in a subcell
    write_all_nets [dpc_cell_name]

    return
  }

  busy

  puts "Setting up Primetime ..."

  # compute the filename for the verilog file
  upvar #0 SUE_$NETLIST(root) data
#  set filename "$NETLIST(dir)$NETLIST(root)$SUFFIX(dpc)"
  set filename $SUE_TIMING_DATA(verilog_file)

  set save_dir [pwd]
  cd $NETLIST(dir)

  set cmd_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_in)

  set out_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_out)

  # first write the commands out to a file

  # open to write the primetime command file
  if {[catch "open $cmd_file w" msg]} {
    # error
    puts "DPC TIMING ERROR: $msg"
    return 69
  }
  set FILE_ID $msg

  set search_path ""
  set link_path "*"
  foreach lib $DPC_TIMING(db_file) {

puts "...lib \"$lib\""

    set path [file dirname $lib]

puts "...path \"$path\""
    if {[lsearch $search_path $lib] == -1} {
      # add to search path
      lappend search_path $path
puts ".......lappend.... \"$search_path\""
    }

    set name [file tail $lib]
puts "...name \"$name\""

    if {[lsearch $link_path $lib] == -1} {
      # add to link path
      lappend link_path $name
puts "......lappend \"$link_path\""
    } else {
      puts "WARNING, duplicate link_path names $name."
    }
  }
  puts $FILE_ID "set search_path \"$search_path\""
  puts $FILE_ID "set link_path \"$link_path\""

  global DPC_FROM_DEF DPC_SIZE

  foreach cell [array names DPC_FROM_DEF] {
    set file $DPC_SIZE($cell,dir)/$cell$SUFFIX(dpc)
    puts $FILE_ID "read_verilog $file"
  }

  puts $FILE_ID "read_verilog $filename"

  puts $FILE_ID "link_design $NETLIST(root)"

  # if the suffix isn't rspf or dspf, assume a capacitance only file
  set suffix [string tolower [file extension $SUE_TIMING_DATA(parasitic_file)]]
  if {[string first spf $suffix] != -1} {
    # an rspf or dspf file
    puts $FILE_ID "read_parasitics $SUE_TIMING_DATA(parasitic_file)"
    # and fix it up
    puts $FILE_ID "complete_net_parasitics -complete_with zero"
  } elseif {[string first sdf $suffix] != -1} {
    # an sdf file
    puts $FILE_ID "read_sdf $SUE_TIMING_DATA(parasitic_file)"
  } else {
    # assume it's just a plain old vanilla cap file
    puts $FILE_ID "source $SUE_TIMING_DATA(parasitic_file)"
  }

  # tell primetime to save timing values for probing nets
  # need to turn this on before update_timing or first report_timing
  puts $FILE_ID "set timing_save_pin_arrival_and_slack true"

  # save the current canvas info
  set save_cur_c $cur_c
  set save_cur_s $cur_s
  set save_scale $scale
  set save_hierarchy $HIERARCHY

  # set for the top level
  set cur_s $NETLIST(root)
  global SUE_${cur_s}
  set cur_c $data(canvas)
  set scale $data(scale)
  set HIERARCHY ""

  set clks ""
  set net ""
  set suggested_clks [use_first SUE_TIMING_DATA(clk_names)]
  foreach id [$cur_c find withtag icon_input] {
    foreach net [bus_expand [find_timing_net_name [get_intersect_tag inst$id term]]] {

      if {[lsearch -exact $suggested_clks $net] != -1 && [lsearch -exact $clks $net] == -1} {
	# this is a good clock input, use it
	lappend clks $net
      }
    }
  }

  setl {period clk_fall} $SUE_TIMING_DATA(clk_period)
  set period [parse_pp_number [convert_if_no_units $period p]]
  if {$clk_fall == ""} {
    # assume falling edge is mid way into period
    set clk_fall [expr $period/2]
  }

  # scale to primetime units from db file
  set mult [expr 1.0 / [parse_pp_number $DPC_TIMING(db_time_units)]]

  if {$clks == ""} {
    # no clocks, must be combinational
    if {$net == ""} {
      # no inputs
      sue_error "Aborting, no inputs to schematic \"$cur_s\"."
      sue_error flush

      ready
      return 69
    }

    puts "DPC INFO:  No input matches clock names, assuming combinational logic with no clocks."

    set SUE_TIMING_DATA(timing_type) combinational

    set clock $DPC_TIMING(wave_name)

    puts $FILE_ID "create_clock -name $clock -period [expr $mult * $period] -waveform \{0 [expr $mult * $clk_fall]\}"

    set arrival 0
    set departure 0

  } else {

    set SUE_TIMING_DATA(timing_type) sequential

    foreach clk $clks {
      puts $FILE_ID "create_clock -period [expr $mult * $period] -waveform \{0 [expr $mult * $clk_fall]\} $clk"
      set trace($clk) 1
    }

    set clock [lindex $clks 0]
    set arrival [expr [parse_pp_number $SUE_TIMING_DATA(default_arrival_time)] / \
		     [parse_pp_number $DPC_TIMING(db_time_units)]]

    set departure [expr [parse_pp_number $SUE_TIMING_DATA(default_setup_time)] / \
		     [parse_pp_number $DPC_TIMING(db_time_units)]]
  }

  foreach id [$cur_c find withtag icon_input] {
    set net [find_timing_net_name [get_intersect_tag inst$id term]]
    foreach bit [cbus_expand $net] {
      if {![info exists trace($bit)]} {
	puts $FILE_ID "set_input_delay -clock $clock $arrival $bit"
	set trace($bit) 1
      }
    }
  }

  # if there is a default, use the default driver cell
  # TODO: can't turn off driver cell, if set to null, takes default
  if {[use_first SUE_TIMING_DATA(driver_cell)] != ""} {
    setl {cell port} $SUE_TIMING_DATA(driver_cell)
    
    if {$port == ""} {
      # use the port name "out" for the output port if not specified
      set port out
    }

    puts $FILE_ID "set_driving_cell -lib_cell $cell -from_pin $port \[all_inputs\]"
  } else {
    # use a constant slope
    set input_transition \
	[expr [parse_pp_number $SUE_TIMING_DATA(input_transition)] * $mult]
    puts $FILE_ID "set_input_transition $input_transition \[all_inputs\]"
  }

  # put capacitance on output nodes
  set out_cap [expr [parse_pp_number $DPC_TIMING(out_cap)] / \
		   [parse_pp_number $DPC_TIMING(db_cap_units)]]
		   
  foreach id [$cur_c find withtag icon_output] {
    set net [find_timing_net_name [get_intersect_tag inst$id term]]
    foreach bit [cbus_expand $net] {
      regsub -all {\$} $bit \\\\$ bit
      if {![info exists trace($bit)]} {
	puts $FILE_ID "set_capacitance $out_cap $bit"

	puts $FILE_ID "set_output_delay -clock $clock $departure $bit"
	set trace($bit) 1
      }
    }
  }

  # restore the current canvas, schematic, scale and hierarchy.
  set cur_c $save_cur_c
  set cur_s $save_cur_s
  set scale $save_scale
  set HIERARCHY $save_hierarchy

  # this is the simplest
#  puts $FILE_ID "idealclocks yes"

  # read in the constraint file if it exists
  if {[file readable $SUE_TIMING_DATA(constraint_file)]} {
    puts "Including constraint file: $SUE_TIMING_DATA(constraint_file)"
    puts $FILE_ID "source $SUE_TIMING_DATA(constraint_file)"
  } else {
    puts "Note: No constraint file: $SUE_TIMING_DATA(constraint_file)"
  }

  if {$mode == "timing"} {

  } else {

    # to highlite the critical path
    puts $FILE_ID "report_timing -nosplit -nets -input_pins -transition_time -capacitance -significant_digits 3 -max_paths $SUE_TIMING_DATA(max_paths)"

    # comments needed by reader
    puts $FILE_ID "echo *DONE*"

#    puts $FILE_ID "findmincycletime"
    # comments needed by reader
#    puts $FILE_ID "\# done"
#    puts $FILE_ID "\# done"

#NEW
    # get all of the pin/net timing values through the hierarchy
    puts $FILE_ID "foreach_in_collection p \[get_pins * -hier\] \{"
    puts $FILE_ID {  echo "TIMING: [get_object_name $p] [get_object_name [get_nets -of_objects $p]] [get_attribute $p max_rise_arrival] [get_attribute $p max_fall_arrival]"}
    puts $FILE_ID "\}"

    # save terminal data for this nell
    write_all_nets

#    puts $FILE_ID "findclockdelays"

    # show slow nodes
    puts $FILE_ID "set_max_transition [expr [parse_pp_number $SUE_TIMING_DATA(max_transition)] / [parse_pp_number $DPC_TIMING(db_time_units)]] $NETLIST(root)"
    puts $FILE_ID "report_constraint -all_violators -max_transition -significant_digits 3 > $NETLIST(dir)$NETLIST(root)$SUFFIX(slow_nodes)"
  }

  puts $FILE_ID "quit"

  # close the tempfile
  close $FILE_ID

  set status [run_primetime $cmd_file $out_file $DPC_TIMING(out)]

  if {$status > 0} {
    puts "Aborting, primetime return status is $status"

    catch "exec cat $out_file" msg
    puts $msg

    ready
    return $status
  }

  # primetime does not seem to return a meaningful exit status
  if {[catch "exec grep {Thank you for using} $out_file" result] || $result == ""} {
    # primetime choked, show user entire output file

    catch "exec cat $out_file" msg
    puts $msg

    puts "DPC aborted due to primetime error."
    ready
    return 69
  }

  if {[catch "exec grep {was successfully linked} $out_file" result] || $result == ""} {
    # primetime choked, show user entire output file

    catch "exec cat $out_file" msg
    puts $msg

    puts "DPC aborted due to primetime error."

    ready
    return 69
  }

  parse_primetime_output $out_file $mode

  # now delete the tmp files
#  exec rm -f $cmd_file

  # return to calling directory
  cd $save_dir

  ready

  # return OK exit status
  return 0
}


# create the script file to run primetime (required becuase exec in tcl
# is broken) and then run it.  Return the pearl exit status.

proc run_primetime {cmd_file out_file {type hidden}} {

  global GO DPC_TIMING env

  if {[info exists env(SUE_DEMO)]} {
    # special demo mode with no PRIMETIME (but primetime output)

    puts "*DEMO* Mode.  Skipping Primetime and using existing timing files."
    puts "To exit demo mode, \"unset env(SUE_DEMO)\" from SUE or \"unsetenv SUE_DEMO\" from Unix."

    return 0
  }

  puts "\nRunning Primetime ..."

  # direct all output to output file
  if {[catch "exec csh -cf \"$DPC_TIMING(primetime,command) -f $cmd_file >&! $out_file\"" msg]} {
    puts $msg
    return 69
  }

  # show the user any error messages except bogus show possibility ones
  if {![catch "exec grep -i error: $out_file | grep -v collection" msg]} {
    puts $msg
  }

  puts "Primetime completed.\n"

  return 0
}


proc parse_primetime_output {out_file {mode ""}} {

  global cur_s SUE_TIMING_DATA DPC_TIMING

  # waste any old values and deselect all
  select_ids ""

  # scale from db units
  set mult [parse_pp_number $DPC_TIMING(db_time_units)]

  set FILE_ID [open $out_file r]
     
  if {$mode == ""} {
    # parse the critical paths

    set SUE_TIMING_DATA(critical_paths) 0

    # look for the word report

    while {[gets $FILE_ID line] >= 0} {
      if {[string first "Report" $line] == 0} {
	# inside the report section
	break
      }
    }

    # now look for Startpoint or *DONE*
    set error 0
    while {[gets $FILE_ID line] >= 0} {
      if {$error || [string first "*DONE*" $line] != -1} {
	# we're done
	break
      }

      if {[string first "Startpoint:" $line] != -1} {
	# inside a specific critical path
	incr SUE_TIMING_DATA(critical_paths)
	set SUE_TIMING_DATA(cpmessage,$SUE_TIMING_DATA(critical_paths)) ""
	set SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(critical_paths)) ""

	set start [lindex $line 1]
	while {[string first "Endpoint" $line] == -1} {
	    gets $FILE_ID line
	}
	set end [lindex $line 1]

	gets $FILE_ID line
	gets $FILE_ID line
	gets $FILE_ID line

	set net ""
	set done 0

	while {[gets $FILE_ID line] >= 0} {
	  lappend SUE_TIMING_DATA(cpmessage,$SUE_TIMING_DATA(critical_paths)) $line

	  if {[string first "*DONE*" $line] != -1} {
	    # shouldn't have gotten here
	    set error 1
	    # we're done
	    break
	  }

	  if {[string first "slack " $line] != -1} {
	    # last line
	    set time [lindex $line 2]
	    break
	  }

	  if {$done} {
	    continue
	  }

	  if {[string first " clock " $line] != -1} {
	    # from the clock (register input)
	    set clock [lindex $line 1]
	    set clks [use_first SUE_TIMING_DATA(clk_names)]
	    if {[lsearch $clks $clock] != -1} {
	      # found the clock input
	      set net $clock
	      set time [pp_number [expr $mult * [lindex $line 6]]]
	      lappend SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(critical_paths)) \
		  "net $net $time"

	      # ignore next two lines
	      gets $FILE_ID line
	      gets $FILE_ID line
	      continue
	    }
	  }

	  if {[string first " (in)" $line] != -1} {
	    # found the start from an external input
	    continue
	  }

	  if {[string first " (net)" $line] != -1} {

	    # this is a net -- get the name
	    if {$net == ""} {
	      set net [lindex $line 0]

	    } else {
	      # duplicate name, must be hierarchy.  Get one iwth least /
	      set other_net [lindex $line 0]
	      if {[llength [split $net /]] >= [llength [split $other_net /]]} {
		set net $other_net
	      }
	    }

	    continue
	  }

	  if {[string first " (out)" $line] != -1} {
	    # done
	    set out_time [pp_number [expr $mult * [lindex $line 4]]]

	    set trans \
                "[lindex $line 5]=[pp_number [expr $mult * [lindex $line 2]]]"

	    lappend SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(critical_paths)) \
		"net $net $out_time $trans"

	    set done 1
	    continue
	  }

	  if {[string first "data arrival time" $line] != -1} {
	    # done
	    set done 1
	    continue
	  }

	  if {[llength $line] == 6} {
	    if {[lindex $line 2] == 0.0 && [lindex $line 3] == 0.0} {
	      # hierarchical name
	      # ??????

	    } else {
	      # must be a cell with timing
	      # if there is a net defined then this is an input

	      if {$net != ""} {
		# input -- save data

		set portname [lindex $line 0]
		if {[set pos [string last / $portname]] != -1} {
		  # get rid of port at end of cell
		  set cellname [string range $portname 0 [incr pos -1]]
		} else {
		  set cellname $portname
		}

		set time [pp_number [expr $mult * [lindex $line 4]]]
		set trans \
		  "[lindex $line 5]=[pp_number [expr $mult * [lindex $line 2]]]"

		lappend SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(critical_paths)) \
		    "net $net $time $trans"

		lappend SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(critical_paths)) \
		    "cell $cellname"

		set net ""
		continue

	      } else {
		# output
		continue
	      }
	    }
	  }
	}

	if {$error} {
	  continue
	}

	if {$SUE_TIMING_DATA(timing_type) == "sequential"} {
	  set SUE_TIMING_DATA(cp,value,$SUE_TIMING_DATA(critical_paths)) \
	      "[pp_number [expr $mult * $time]] Slack ($start -> $end)"
	} else {
	  set SUE_TIMING_DATA(cp,value,$SUE_TIMING_DATA(critical_paths)) \
	      "$out_time ($start -> $end)"
	}
      }
    }
  }

  # remove any critical paths that don't exist.
  # not exactly right since a middle one could be broken
  while {![info exists SUE_TIMING_DATA(cp,value,$SUE_TIMING_DATA(critical_paths))] && \
	     $SUE_TIMING_DATA(critical_paths) > 0} {
    incr SUE_TIMING_DATA(critical_paths) -1
  }

  # read term values
  set cell [dpc_cell_name]
  set SUE_TIMING_DATA($cell,net_values) ""

  while {[gets $FILE_ID line] >= 0} {
    if {[string range $line 0 6] != "TIMING:"} {
      continue
    }

    # timing line
    setl {tmp pin net rise fall} $line

    if {[catch "expr $rise"] || [catch "expr $fall"]} {
      # skip these, not good value
#      puts "WARNING: no timing for net $net ($pin)"
      continue
    }

    # put them here to remove duplicates
    if {[info exists save($net)]} {
      # get max -- different if resistances
      set save($net) [max $save($net) $rise $fall]
    } else {
      set save($net) [max $rise $fall]
    }
  }

  foreach net [array names save] {
    lappend SUE_TIMING_DATA($cell,net_values) "$net $save($net)"
  }

  # close the file
  close $FILE_ID
}



# special procs for pathmill

proc setup_pathmill {{mode ""}} {

  global NETLIST SUFFIX cur_s cur_c scale DPC_TIMING SUE_TIMING_DATA HIERARCHY
  global VERSION

  if {[is_icon $cur_s]} {
    puts "Aborting, can't run timing from an icon, only a schematic."
    return 69
  }

  if {[lindex [lreverse [split $cur_s _]] 0] == "placement"} {
    puts "Aborting, can't run timing from a placement, only a schematic."
    return 69
  }

  if {[info exists NETLIST(root)] != 1} {
    sue_error "Aborting, must dpc netlist first before timing."
    sue_error flush
    return 69
  }

#  if {![info exists env(SUE_DEMO)] && \
	  ![executable_exists "$DPC_TIMING(pathmill,command) --version"]} {
#    sue_error "Aborting, can't execute $DPC_TIMING(pathmill,command).  Check paths."
#    sue_error flush
#    return 69
#  }

  if {$mode == "timing"} {
    # write nets that are in a subcell
    write_all_nets [dpc_cell_name]

    return
  }

  busy

  puts "Setting up Pathmill ..."

  # compute the filename for the verilog file
  upvar #0 SUE_$NETLIST(root) data
  set filename $SUE_TIMING_DATA(verilog_file)
  # TODO, include other verilog from nl stuff

  set save_dir [pwd]
  cd $NETLIST(dir)

  set cmd_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_in)

  set out_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_out)

  # first write the commands out to a file

  # open to write the pathmill command file
  if {[catch "open $cmd_file w" msg]} {
    # error
    puts "DPC TIMING ERROR: $msg"
    return 69
  }
  set FILE_ID $msg

  puts $FILE_ID "; Pathmill control file built by $VERSION\n"

  puts $FILE_ID "hierarchical_id /\n"

  puts $FILE_ID "; User defined configuration options:"

  puts $FILE_ID [join $DPC_TIMING(pathmill,cfg_options) \n]
  puts $FILE_ID ""

  # if the suffix isn't rspf or dspf, assume a capacitance only file
  set suffix [string tolower [file extension $SUE_TIMING_DATA(parasitic_file)]]
  if {[string first spf $suffix] != -1} {
    # an rspf or dspf file
    set parasitic_file ""
    puts $FILE_ID "read_file type=spf $SUE_TIMING_DATA(parasitic_file)\n"
  } elseif {[string first sdf $suffix] != -1} {
    # an sdf file
    set parasitic_file ""
    puts $FILE_ID "read_file type=sdf $SUE_TIMING_DATA(parasitic_file)\n"
  } else {
    # assume it's just a plain old vanilla cap file
    set parasitic_file " $SUE_TIMING_DATA(parasitic_file)"
  }

  # save the current canvas info
  set save_cur_c $cur_c
  set save_cur_s $cur_s
  set save_scale $scale
  set save_hierarchy $HIERARCHY

  # set for the top level
  set cur_s $NETLIST(root)
  global SUE_${cur_s}
  set cur_c $data(canvas)
  set scale $data(scale)
  set HIERARCHY ""

  set clks ""
  set net ""
  set suggested_clks [use_first SUE_TIMING_DATA(clk_names)]
  foreach id [$cur_c find withtag icon_input] {
    foreach net [bus_expand [find_timing_net_name [get_intersect_tag inst$id term]]] {

      if {[lsearch -exact $suggested_clks $net] != -1 && [lsearch -exact $clks $net] == -1} {
	# this is a good clock input, use it
	lappend clks $net
      }
    }
  }

  setl {period clk_fall} $SUE_TIMING_DATA(clk_period)
  set period [expr [parse_pp_number [convert_if_no_units $period p]] / 1.0e-9]
  if {$clk_fall == ""} {
    # assume falling edge is mid way into period
    set clk_fall [expr $period/2.0]
  }

  # scale to pathmill units from db file
  set mult [expr 1.0 / 1.0e-9]

  # convert to ns (gotta luv it).
  set input_transition \
      [expr [parse_pp_number $SUE_TIMING_DATA(input_transition)] * $mult]

  if {$clks == ""} {
    # no clocks, must be combinational
    if {$net == ""} {
      # no inputs
      sue_error "Aborting, no inputs to schematic \"$cur_s\"."
      sue_error flush

      ready
      return 69
    }

    puts "DPC INFO:  No input matches clock names, assuming combinational logic with no clocks."

    set SUE_TIMING_DATA(timing_type) combinational

    set clock $DPC_TIMING(wave_name)

    set arrival ""
    set departure ""

    set refnode ""

  } else {

    set SUE_TIMING_DATA(timing_type) sequential

#    puts $FILE_ID "ref_clock $DPC_TIMING(wave_name) period=$period rise_delay=0 fall_delay=$clk_fall slope=$input_transition"

    foreach clk $clks {
      set trace($clk) 1

      puts $FILE_ID "clock_node $clk period=$period rise_delay=0 fall_delay=$clk_fall slope=$input_transition"

      puts $FILE_ID "source_node $clk"
    }

    set refnode [lindex $clks 0]

    puts $FILE_ID "\ntiming_verify\n"

    set clock [lindex $clks 0]
    set arrival [expr [parse_pp_number $SUE_TIMING_DATA(default_arrival_time)] / 1.0e-9]
    set arrival "delay=$arrival clock=a r $clk"

    set departure [expr [parse_pp_number $SUE_TIMING_DATA(default_setup_time)] / 1.0e-9]
    set departure "delay=$departure clock=b r $clk"
  }

  foreach id [$cur_c find withtag icon_input] {
    set net [find_timing_net_name [get_intersect_tag inst$id term]]
    foreach bit [cbus_expand $net] {
      if {![info exists trace($bit)]} {
	puts $FILE_ID "source_node $bit slope=$input_transition $arrival"

	if {$refnode == ""} {
	  set refnode $bit
	}

	set trace($bit) 1
      }
    }
  }

  if {[use_first SUE_TIMING_DATA(driver_cell)] != ""} {
    puts "WARNING, driver cell ignored in Pathmill.  Using input transition."
  }

  # put capacitance on output nodes (in fF)
  set out_cap [expr [parse_pp_number $DPC_TIMING(out_cap)] / 1.0e-15]
		   
  foreach id [$cur_c find withtag icon_output] {
    set net [find_timing_net_name [get_intersect_tag inst$id term]]
    foreach bit [cbus_expand $net] {
      if {![info exists trace($bit)]} {
	puts $FILE_ID "sink_node $bit cap=$out_cap $departure"
	set trace($bit) 1
      }
    }
  }

  # restore the current canvas, schematic, scale and hierarchy.
  set cur_c $save_cur_c
  set cur_s $save_cur_s
  set scale $save_scale
  set HIERARCHY $save_hierarchy

  # this is the simplest
#  puts $FILE_ID "idealclocks yes"

  # read in the constraint file if it exists
  if {[file readable $SUE_TIMING_DATA(constraint_file)]} {
    puts "Including constraint file: $SUE_TIMING_DATA(constraint_file)"
    puts $FILE_ID "\n; including $SUE_TIMING_DATA(constraint_file)"
    catch "exec cat $SUE_TIMING_DATA(constraint_file)" msg
    puts $FILE_ID $msg
  } else {
    puts "Note: No constraint file: $SUE_TIMING_DATA(constraint_file)"
  }

  # to highlite the critical path
  if {$SUE_TIMING_DATA(timing_type) == "sequential"} {
    # force all paths in error report
#    puts $FILE_ID "\nreport_paths error max $SUE_TIMING_DATA(max_paths) sink 1 up_bound=1000\n"
    puts $FILE_ID "\nreport_paths error max $SUE_TIMING_DATA(max_paths) up_bound=1000\n"
  } else {
    # combinational
#    puts $FILE_ID "\nreport_paths critical max $SUE_TIMING_DATA(max_paths) sink 1\n"
    puts $FILE_ID "\nreport_paths critical max $SUE_TIMING_DATA(max_paths)\n"
  }

  if {$mode == "spice"} {
    # spice last critical path
    if {[info exists DPC_TIMING(pathmill,spice_include)]} {
      puts $FILE_ID "%spice_include"
      puts $FILE_ID [join $DPC_TIMING(pathmill,spice_include) \n]
      puts $FILE_ID "%end_spice_include\n"
    }
    if {$SUE_TIMING_DATA(timing_type) == "sequential"} {
      puts $FILE_ID "print_spice_paths error max $SUE_TIMING_DATA(cp,index)\n"
    } else {
      puts $FILE_ID "print_spice_paths critical max $SUE_TIMING_DATA(cp,index)\n"
    }

  } else {
    # write all nets (all levels of hierarchy)
    puts $FILE_ID "probe_node * delay net report"

    # save terminal data for this nell
    write_all_nets

    # show slow nodes
    puts $FILE_ID "; display slow nodes"
    puts $FILE_ID "probe_node * max_slope=[expr [parse_pp_number $SUE_TIMING_DATA(max_transition)] / 1.0e-9] slope net report\n"
  }

  # close the tempfile
  close $FILE_ID

  if {[use_first DPC_TIMING(pathmill,spice_header)] != ""} {
    set header "-nspice $DPC_TIMING(pathmill,spice_header) "
  } else {
    set header ""
  }

  if {[use_first DPC_TIMING(pathmill,tech_file)] == ""} {
    # no tech file
    set command "${header}-nvlog $filename -c $cmd_file$parasitic_file -m $NETLIST(root) -o $out_file -L $DPC_TIMING(pathmill,library)"
  } else {
    # tech file
    set command "${header}-nvlog $filename -c $cmd_file$parasitic_file -p $DPC_TIMING(pathmill,tech_file) -m $NETLIST(root) -o $out_file -L $DPC_TIMING(pathmill,library)"
}

  set status [run_pathmill $command $out_file.log $DPC_TIMING(out)]

  if {$status != 1} {
    puts "\nDPC aborted due to pathmill error.\n"

    ready
    return 69
  }

  if {$mode == "spice"} {
    # spice last critical path.  Run spice
    puts "Running Spice ..."
    catch "exec rm -f $out_file.spout"

    # figure out what dir to get the spice script from
    global env SUE_DIR
    set mmi_local $env(MMI_LOCAL)
    set mmi_private [file nativename ~/mmi_private]

    if {[file exists $mmi_private/sue/spice]} {
      set dir $mmi_private/sue
    } elseif {[file exists $mmi_local/sue/spice]} {
      set dir $mmi_local/sue
    } else {
      set dir $SUE_DIR
    }

    catch "exec $dir/spice $out_file.spi $out_file.spout >&! [exec tty]" msg
    puts $msg
    puts "done.\n"

    catch "exec rm -f $out_file.diff"

    catch "exec $DPC_TIMING(pathmill,spice_command) -i $out_file.spout -o $out_file.diff >&! [exec tty]"
    catch "exec cat $out_file.diff" msg
    puts $msg

    puts "done."

  } else {
    parse_pathmill_output $out_file $mode
  }

  # now delete the tmp files
#  exec rm -f $cmd_file

  # return to calling directory
  cd $save_dir

  ready

  # return OK exit status
  return 0
}


# create the script file to run pathmill (required becuase exec in tcl
# is broken) and then run it.  Return the pearl exit status.

proc run_pathmill {command logfile {type hidden}} {

  global DPC_TIMING env

  if {[info exists env(SUE_DEMO)]} {
    # special demo mode with no PATHMILL (but pathmill output)

    puts "*DEMO* Mode.  Skipping Pathmill and using existing timing files."
    puts "To exit demo mode, \"unset env(SUE_DEMO)\" from SUE or \"unsetenv SUE_DEMO\" from Unix."

    return 1
  }

  puts "\nRunning Pathmill ..."

  # remove the old log file
  catch "exec rm -f $logfile"

  # TODO see -- why?
  if {[catch "exec $DPC_TIMING(pathmill,command) $command" msg]} {
    # bad news?

    if {![file readable $logfile]} {
      # probably couldn't even execute
      puts $msg
      return 0
    }

    if {[catch "exec grep {; Path tracing completed at } $logfile" result] \
	  || $result == ""} {
      # pathmill choked, show user entire output file

      catch "exec cat $logfile" msg
      puts $msg
      return 69
    }
  }

  puts "Pathmill completed.\n"

  return 1
}


# compute all net names for displaying timing values

proc write_all_nets {{cell ""}} {

  global cur_c cur_s SUE_TIMING_DATA

  if {$cell == ""} {
    puts "Adding nets for top cell \"$cur_s\" ..."
  } else {
    if {[info exists SUE_TIMING_DATA($cur_s,traced)]} {
      # already done this one
      return
    }
    set SUE_TIMING_DATA($cur_s,traced) 1
    puts "Adding nets for cell \"$cur_s\" ..."
  }

  upvar #0 TERMS_$cur_s TERMS

  # get all terminals
  foreach id [$cur_c find withtag term] {
    set origin_id [find_origin $id]
    if {![is_tagged $origin_id icon_flag] && \
	    ![is_tagged $origin_id icon_global] && \
	    ![is_tagged $origin_id icon_$cur_s]} {

      # find the net that is attached to this term
      if {![info exists TERMS($id)]} {
	continue
      }
      set net $TERMS($id)

#      if {[string first ' $net] != -1} {
	# constant, skip
#	continue
#      }

      foreach name [cbus_expand $net] {
	lappend SUE_TIMING_DATA($cur_s,terms,$name) $id
      }
    }
  }

  puts "done."
}


proc parse_pathmill_output {out_file {mode ""}} {

  global cur_s SUE_TIMING_DATA DPC_TIMING NETLIST SUFFIX

  # waste any old values and deselect all
  select_ids ""

  # scale from pathmill ns 
  set mult 1.0e-9

  if {$mode == ""} {
    # parse the critical paths

    if {$SUE_TIMING_DATA(timing_type) == "sequential"} {
      set FILE_ID [open $out_file.err r]
    } else {
      # conbinational
      set FILE_ID [open $out_file.out r]
    }

    set SUE_TIMING_DATA(critical_paths) 0

    # look for the start of the critical paths
    while {[gets $FILE_ID line] >= 0} {
      if {[string trim $line] != "*** Longest Paths ***"} {
	# inside the critical path section
	continue
      }

      # now look for each path
      set in_cp 0
      set start 1
      while {[gets $FILE_ID line] >= 0} {

	if {[string range $line 0 5] == "Path ("} {
	  # found one
	  incr SUE_TIMING_DATA(critical_paths)
	  set SUE_TIMING_DATA(cp,value,$SUE_TIMING_DATA(critical_paths)) ""
	  set SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(critical_paths)) ""
	  set SUE_TIMING_DATA(cpmessage,$SUE_TIMING_DATA(critical_paths)) ""
	  set in_cp 0
	  set first ""
	  set start 0

	  if {$SUE_TIMING_DATA(timing_type) == "sequential"} {
	    # get the slack/violation from here
	    set slack [lrange $line 11 12]
	    set stages [lindex $line 6]
	  }

	  continue
	}

	if {!$start} {
	  # save this for the message
	  lappend SUE_TIMING_DATA(cpmessage,$SUE_TIMING_DATA(critical_paths)) $line
	}

	if {[string first "-----" $line] != -1} {
	  # get us in or out of a cp
	  if {$in_cp} {
	    if {[use_first DPC_TIMING(pathmill,filter)] == "1" && \
		    [info exists trace([lindex $first 0],$node)]} {
	      # already got this one, skip
	      incr SUE_TIMING_DATA(critical_paths) -1
	    } else {
	      set trace([lindex $first 0],$node) 1
	      set delta [pp_number [parse_pp_number ${delta}n]]s

	      if {$SUE_TIMING_DATA(timing_type) == "sequential"} {
		lappend SUE_TIMING_DATA(cp,value,$SUE_TIMING_DATA(critical_paths)) \
		    "$slack slack in $stages stages ($first -> $node \[$dir\])"
	      } else {
		# combinational
		lappend SUE_TIMING_DATA(cp,value,$SUE_TIMING_DATA(critical_paths)) \
		    "$delay ($first -> $node \[$dir\])"
	      }
	    }
	  }

	  set in_cp [expr 1 - $in_cp]
	  continue
	}

	if {$in_cp} {
	  # get this line of cp

	  # first eliminate (xx), also SP,EP,SE,EE
	  regsub {[SPE]*\([a-zA-Z][0-9]?\)} $line "" line

	  # the next lindex eats \n so protect them
	  regsub -all {\\} $line {\\\\\\\\} line

	  setl {delay delta rf dir cap node name} $line

	  if {[catch "expr $delay + 0"]} {
	    # not a number, skip line
	    continue
	  }

	  if {[llength $line] == 3} {
	    set last_name $rf
	  }

	  if {$cap == ""} {
	    # probably just a net delay, ignore
	    continue
	  }

          set delay [pp_number [expr $delay * 1.0e-9]]
          set rf [pp_number [expr $rf * 1.0e-9]]

	  if {$name == "" && $first == ""} {
	    # probably an input
	    lappend SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(critical_paths)) \
		"net $node $delay $dir=$rf"
	    set first "$node \[$dir\]"
	    continue
	  }

	  if {$name == ""} {
	    set name $last_name
	  }

	  lappend SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(critical_paths)) "cell $name"
	  lappend SUE_TIMING_DATA(cp,$SUE_TIMING_DATA(critical_paths)) \
	      "net $node $delay $dir=$rf"
	}
      }
    }
  }

  # read term values
  set FILE_ID [open $out_file.log r]

  set cell [dpc_cell_name]

  set SUE_TIMING_DATA($cell,net_values) ""

#  set clks [use_first SUE_TIMING_DATA(clk_names)]

  # for parsing output
  switch $SUE_TIMING_DATA(timing_type) {
    sequential {
      set lnum 6
    }
    combinational {
      set lnum 4
    }
  }

  while {[gets $FILE_ID line] >= 0} {

    if {$mode == "" && $line == "***Node Slopes"} {
      # write slow nodes to file
      if {[catch "open $NETLIST(dir)$NETLIST(root)$SUFFIX(slow_nodes) w" FILE_ID2]} {
	puts "WARNING: $FILE_ID2"
	continue
      }

      set in_slope 0
      set count 0

      while {[gets $FILE_ID line] >= 0} {

	if {$line == "***End Node Slopes"} {
	  # we're done
	  break
	}

	if {[string range $line 0 9] == "=========="} {
	  set in_slope 1
	  continue
	}

	if {$in_slope} {
	  puts $FILE_ID2 $line
	  if {[llength $line] == 4} {
	    incr count
	  }
	}
      }

      if {$count == 0} {
	puts $FILE_ID2 "No nodes found."
      }

      # close the file
      close $FILE_ID2
    }

    # look for start of node delay section
    if {$line != "***Node Delays"} {
      continue
    }

    set node ""
    set value -1
    while {[gets $FILE_ID line] >= 0} {

      if {$line == "***End Node Delays"} {
	# we're done
	break
      }

      if {[llength $line] != $lnum} {
	# bogus
	continue
      }

      # this is it.  This and next lines are values.  max them.
      # the next lindex eats \n so protect them
      regsub -all {\\} $line {\\\\\\\\} line
      set this_node [lindex $line 0]
      
      if {$this_node != $node} {
	if {$value != -1} {
	  # done with last node
	  lappend SUE_TIMING_DATA($cell,net_values) "$node $value"
	}

	# new node
	set value 0
	set node $this_node
      }

      set value [max $value [lindex $line 2]]
    }

    # get the last node value
    if {$node != ""} {
      lappend SUE_TIMING_DATA($cell,net_values) "$node $value"
    }

    break
  }

  # close the file
  close $FILE_ID
}


# if a number has no units, add the given units, otherwise, simply
# return the number.  This is for backwards compatibility.

proc convert_if_no_units {number units} {

  if {[catch "expr $number + 0"]} {
    # not a valid number, assume it contains units
    return $number
  }

  # unitify this
  return $number$units
}


# display selected in the other view

proc display_other_view {} {

  global cur_s NETLIST

  if {[info exists NETLIST(root)] != 1} {
    warning "Aborting, must dpc netlist first."
    return 
  }

  if {[is_placement $cur_s]} {
    display_in_schematic

  } else {
    display_in_placement
  }
}


# display selected cell in schematic in placement
# doesn't clear selection first if given the pathname

proc display_in_placement {{name ""}} {

  global cur_s cur_c scale DPC_ABS COLORS FONT DPC DPC_SIZE NETLIST

  if {$name == ""} {

    if {[is_placement $cur_s]} {
      # must run from a schematic
      return
    }

    if {[is_icon $cur_s]} {
      # must run from a schematic
      warning "Aborting, can't display in other view from an icon."
      return
    }

    # first get the selected cell
    set id [$cur_c find withtag selected&origin]

    if {[llength $id] != 1} {
      warning "Aborting, You must select one icon to display in the placement."
      return 
    }

    # get the name of this icon
    upvar #0 TERMS_$cur_s TERMS

    set local_name [use_first TERMS($id)]

    if {$local_name == ""} {
      upvar #0 ${cur_s}_inst$id i_data

      if {$cur_s == [use_first NETLIST(root)] && $DPC(PINS) && \
	      [lsearch "input output inout" $i_data(type)] != -1} {
	# special case of a pin in top level
	set local_name $i_data(_name)

      } else {
	warning "Aborting, you must select a valid icon to display in the placement."
	return 
      }
    }

    # get the full name
    set name "[dpc_cell_name ""]$local_name"
  }

  if {![is_placement $cur_s]} {
    # now goto placement view
    toggle_show_placement

    # deselect
    select_ids ""

  } 

  # display it
  set fscale [expr int(ceil($scale))]

  foreach name [bus_expand $name] {

    # special case for top-level I/O's
    if {$DPC(PINS) && ![catch {nl_get_pin_direction $name}]} {
      # this is a pin
      select_by_name $name batch

      continue
    }

    regsub -all {\[|\]} $name "$" name

    while {[catch {nl_get_cell_reference $name}]} {
      # something went wrong
#      warning "Aborting, can't find cell \"$name\"."

      # might be a subcell from pathmill, search higher in hierarchy
      set name [join [lreverse [lrange [lreverse [split $name /]] 1 end]] /]

      if {$name == ""} {
	return
      }
    }

    # get center of cell
    if {[info exists DPC_ABS($name)]} {
      # hierarchical cell
      setl {tmp1 type row col delta_row delta_col} $DPC_ABS($name)
    } else {
      # leaf cell
      setl {col row} [nl_get_cell_location $name]

      set col [expr $col / $DPC(xscale)]
      set row [expr $row / $DPC(yscale)]

      set type [nl_get_reference_name [nl_get_cell_reference $name]]
# can't use because string
#      set type [nl_get_cell_reference $name]

      setl {delta_col delta_row} $DPC_SIZE($type)
    }

    set x [expr $scale * ($row + $delta_row/2.0)]
    set y [expr $scale * ($col + $delta_col/2.0)]

    # select the cell
    if {![select_by_name $name batch]} {
      # probably not expanded, select hier cell
      set found 0
      set list [split $name /]
      for {set i [expr [llength $list] - 2]} {$i >= 0} {incr i -1} {
	set id [find_by_name [join [lrange $list 0 $i] /] first]
	if {$id != ""} {
	  # found it, add a tmp box and label for the cell
	  $cur_c create line $row $col $row [expr $col + $delta_col] \
	      [expr $row + $delta_row] [expr $col + $delta_col] \
	      [expr $row + $delta_row] $col $row $col \
	      -tags "tmp_scale tmp tmpbox" -fill $COLORS(anchor) -stipple gray50
	  $cur_c create text $x [expr $y - 0.5 * $scale] \
	      -tags "tmp scaletext size_standard" \
	      -fill $COLORS(anchor) -text $type \
	      -font $FONT(standard,$fscale)
	  $cur_c create text $x [expr $y + $scale] \
	      -tags "tmp scaletext size_small" \
	      -fill $COLORS(anchor) -text $name \
	      -font $FONT(small,$fscale)

	  $cur_c scale tmp_scale 0 0 $scale $scale
	  $cur_c dtag tmp_scale
	  
	  set found 1
	  break
	}
      }

      if {!$found} {
	# Assume that it is an expanded hier cell
	$cur_c create line $row $col $row [expr $col + $delta_col] \
	    [expr $row + $delta_row] [expr $col + $delta_col] \
	    [expr $row + $delta_row] $col $row $col \
	    -tags "tmp_scale tmp tmpbox" -fill $COLORS(anchor)
	$cur_c create text $x [expr $y - 1 * $scale] \
	    -tags "tmp scaletext size_large" \
	    -fill $COLORS(anchor) -text $type \
	    -font $FONT(standard,$fscale)
	$cur_c create text $x [expr $y + 2*$scale] \
	    -tags "tmp scaletext size_standard" \
	    -fill $COLORS(anchor) -text $name \
	    -font $FONT(small,$fscale)
	
	$cur_c scale tmp_scale 0 0 $scale $scale
	$cur_c dtag tmp_scale
      }
    }
  }

  # zoom to selected + tmpbox, otherwise zoom to fit
  set bbox [$cur_c bbox tmpbox]
  if {$bbox != ""} {
    $cur_c addtag tmpzoom withtag selected
    $cur_c addtag tmpzoom withtag tmpbox

    set bbox [$cur_c bbox tmpzoom]

    zoom_to_bbox $bbox 20
    eval center_canvas [center_bbox [$cur_c bbox tmpzoom]]
    
    # get rid of tmpzoom tag
    $cur_c dtag tmpzoom

    set_scrollbars

  } elseif {[$cur_c find withtag selected] == ""} {
    zoom_to_fit

  } else {
    zoom_to_selected
  }
}


# display the selected from placement in schematic

proc display_in_schematic {} {

  global cur_s cur_c

  if {![is_placement $cur_s]} {
    # must run from a placement
    return
  }

  # first get the selected cell
  set id [$cur_c find withtag selected&origin]

  set error 0

  if {[llength $id] > 1} {
    # see if they all map back to the same place
    foreach one $id {
      upvar #0 ${cur_s}_inst$one i_data
      set name [use_first i_data(_instance)]
      regsub {\$[0-9]+\$$} $name "" name
      if {![info exists save]} {
	set save $name
      } elseif {$name != $save} {
	set error 1
	break
      }
    }

    if {$error} {
      set id ""
    } else {
      set id [lindex $id 0]
    }
  }

  if {!$error && $id == ""} {
    # nothing selected but if there is something in tmp, use that
    set error 1
    foreach id [$cur_c find withtag tmp] {
      if {[is_tagged $id scaletext]} {
	# text
	set name [$cur_c itemcget $id -text]
	if {![catch {nl_get_cell_reference $name}]} {
	  # got something
	  set error 0
	  break
	}
      }
    }

  } else {
    # get the name out of this
    upvar #0 ${cur_s}_inst$id i_data

    switch $i_data(type) {
      input - output - inout {
	# special case for I/O's
	set name $i_data(_name)
      }

      default {
	set name [use_first i_data(_instance)]
	if {[catch {nl_get_cell_reference $name}]} {
	  set error 1
	}
      }
    }
  }

  if {$error} {
    warning "Aborting, You must select one icon to display in the schematic."
    return 
  }

  launch "select_instance_path \{$name\}"
}


# selects from the netlist root the full path on the instance,
# pushing down into the correct schematic

proc select_instance_path {name {mode ""} {ignore ""}} {

  global cur_s _SAVE_HIERARCHY_ NETLIST

  if {$mode == "same" && [is_placement $cur_s]} {
    display_in_placement $name
    return 
  }

  # needed?
  set _SAVE_HIERARCHY_ ""

  if {![info exists NETLIST(root)]} {
    warning "Aborting, must netlist first"
    return
  }

  # reset hierarchy and goto root
  goto_schematic $NETLIST(root) 1

  set cell_list [split [string trim $name] /]

  set len [expr [llength $cell_list] - 1]

  set select_cell [lindex $cell_list $len]
  set cell_list [lrange $cell_list 0 [expr $len - 1]]

# puts "----> $name ---> $cell_list --> $select_cell --"

  foreach cell $cell_list {
    # clean up name
    regsub {\$[0-9]+\$$} $cell "" cell

    # deselect all first
    select_ids ""

    # select the cell here
    if {![select_by_name $cell batch]} {
      # problem
      pop_out_of_schematic
      zoom_to_selected
#      warning "Aborting, can't find \"$cell\" in \"$name\"."
      return
    }

    # push into it
    push_into_schematic
  }

  # now select the final cell
  regsub {\$[0-9]+\$$} $select_cell "" select_cell

  select_ids ""
  if {![select_by_name $select_cell batch]} {
    # couldn't find it, pop up a level
    pop_out_of_schematic
  }

  # ignore demorgans if any
  if {$ignore == "demorgan" && [regexp _$ $cur_s]} {
    # demorgan
    pop_out_of_schematic
  }

  zoom_to_selected
}



# Creates a top level window for displaying critical paths

proc display_critical_path_instances {{mode ""}} {

  global SUE_TIMING_DATA WIN DPC_TIMING

  set win .cpi

  if {$mode == "ifexists" && ![winfo exists $win]} {
    # don't update if this doesn't exists yet
    return
  }

  if {![info exists SUE_TIMING_DATA(cp,1)]} {
    puts "Aborting, must dpc_it first."
    return
  }

  set index $SUE_TIMING_DATA(cp,index)

  # does this window already exist?
  if {![catch "winfo rootx $win" x]} {
    # yes, just erase everything in it
    $win.instances delete 0 end

    # raise it
    if {$mode == "raise"} {
      raise $win
    }

  } else {
    # make a new one

    set x [max 0 [expr [winfo rootx $WIN] - 50]]
    set y [expr [winfo rooty $WIN] + 150]

    toplevel $win 

    wm geometry $win "+$x+$y"

    label $win.note -text "Pick Instance to Select:"

    pack $win.note -side top

    frame $win.lb

    scrollbar $win.scroll -command "$win.instances yview" -highlightthickness 0
    pack $win.scroll -side right -fill y -in $win.lb
    scrollbar $win.hscroll -command "$win.instances xview" \
	-orient horizontal -highlightthickness 0
    pack $win.hscroll -side bottom -fill x -in $win.lb

    listbox $win.instances -yscrollcommand "$win.scroll set" \
	-xscrollcommand "$win.hscroll set" \
	-highlightthickness 0 -exportselection 0
    pack $win.instances -side left -fill both -expand 1 -in $win.lb

    pack $win.lb -side top -fill both -expand 1

    set selected [backquote \
      {[if {[set sel_index [$$win.instances curselection]] != ""} { \
	lindex [$$win.instances get $sel_index] 3 \
      }] \
    }]

    bind $win.instances <Motion> \
	{%W selection clear 0 end; %W selection set [%W nearest %y]}

    # single click on button-1 drops into current schematic
    bind $win.instances <Button-1> \
	"launch \"select_instance_path \{$selected\} same demorgan\""

    frame $win.buttons

    frame $win.default -relief sunken -bd 1
    button $win.done -text "Display CP" -padx 1 -pady 1 \
	-command {launch "display_critical_path slopes"}
    pack $win.done -in $win.default -padx 1m -pady 1m -ipadx 2m
    pack $win.default -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m

    button $win.all -text "Display All" -padx 1 -pady 1 \
	-command {launch display_timing}
    pack $win.all -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m

    button $win.previous -text "Previous CP" -padx 1 -pady 1 \
	-command {change_cp -1}
    pack $win.previous -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m

    button $win.next -text "Next CP" -padx 1 -pady 1 \
	-command {change_cp 1}
    pack $win.next -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m

    # exit
    button $win.cancel -text "Close" -padx 1 -pady 1 \
	-command {catch "destroy .cpi"}
    pack $win.cancel -side left -in $win.buttons \
	-padx 4m -ipadx 2m -pady 1m

    pack $win.buttons -side bottom
   
    bind $win <Control-c> {catch {destroy .cpi}}
    bind $win <Escape> {catch {destroy .cpi}}
  }

  # change title
  wm title $win "SUE Timing: Critical Path \#$index Instances"

  # fill 'er up
  set i 1
  set cell ""
  foreach list [use_first SUE_TIMING_DATA(cp,$index)] {
    if {[lindex $list 0] == "net" && $cell != ""} {
      set delay [lindex $list 2]
      if {$delay == ""} {
	set delay ----
      } else {
	regsub " " $delay "" delay
      }

      set slew [lindex $list 3]
      if {$slew == ""} {
	set slew ----
      } else {
	regsub " " $slew "" slew
      }

      set text "$i: $delay \[$slew\] $cell"
      regsub -all {\{|\}} $text "" text

      $win.instances insert end $text

      incr i
      set cell ""

    } elseif {[lindex $list 0] == "cell"} {

      if {$cell != ""} {
	# no timing for this one
	set text "$i: ---- \[----\] $cell"
	regsub -all {\{|\}} $text "" text

	$win.instances insert end $text
      }

      set cell [lindex $list 1]
    }
  }

  if {$cell != ""} {
    # no timing for this one
    set text "$i: ---- \[----\] $cell"
    regsub -all {\{|\}} $text "" text

    $win.instances insert end $text
  }
}


proc change_cp {inc} {

  global SUE_TIMING_DATA

  incr SUE_TIMING_DATA(cp,index) $inc

  if {$SUE_TIMING_DATA(cp,index) < 1} {
    set SUE_TIMING_DATA(cp,index) 1
  }

  if {$SUE_TIMING_DATA(cp,index) > $SUE_TIMING_DATA(critical_paths)} {
    set SUE_TIMING_DATA(cp,index) $SUE_TIMING_DATA(critical_paths)
  }

  # call this
  display_critical_path_instances

  update idletasks

  launch "display_critical_path slopes"
}
