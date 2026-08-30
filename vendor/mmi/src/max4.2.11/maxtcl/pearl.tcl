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

set RCSVERSION(pearl.tcl) { $Revision: 1.1 $ }
# Code taken from sue on 2/22/01

set SUFFIX(pearl_in) .pearl_in
set SUFFIX(pearl_out) .pearl_out
set SUFFIX(timing_constraint) .constraint
set SUFFIX(slow_nodes) .slow_nodes

proc fplan_time_it {} {
  global TIMING_DATA
  global SUFFIX

  fplan_dspf_setup -nomenu
  pearl_setup -nomenu

  set prop_list ""

  if {[lay_editcell] != [lay_rootcell]} {
    error "time_it: error: can not be run when in edit-in-place."
  }

  set cell [lay_editcell]
  set TIMING_DATA(toplevelcell) $cell
  # Alert the user: they must be editing the cell they are interested in.
  lappend prop_list [list "Cell:" TIMING_DATA(toplevelcell) -label]

  use_init TIMING_DATA(action1,write_dspf) 1
  lappend prop_list [list "Write verilog+DSPF" TIMING_DATA(action1,write_dspf) -binary]
  use_init TIMING_DATA(action2,run_pearl) 1
  lappend prop_list [list "Run Pearl" TIMING_DATA(action2,run_pearl) -binary]
  use_init TIMING_DATA(action3,show_critical_paths) 1
  lappend prop_list [list "Show Critical Paths" TIMING_DATA(action3,show_critical_paths) -binary]

  # If the hierarchical method works, why would you do it flat any more?
  # I guess as a check to make sure that hierarchical works.
  set TIMING_DATA(flat) 0
  lappend prop_list [list "Flat timing method" TIMING_DATA(flat) -binary \
    -help {This might be used only for checking that the hierarchical method works.}]

  use_init TIMING_DATA(work_dir) time_it
  lappend prop_list [list "Work directory" TIMING_DATA(work_dir) -entry]


  lappend prop_list [list "DSPF Setup..." "" -button fplan_dspf_setup]
  lappend prop_list [list "Pearl Setup..." "" -button "pearl_setup"]

  if {![prop_menu2 -title "Time It" $prop_list]} {
    return ;# cancelled.
  }

  catch {file mkdir $TIMING_DATA(work_dir)}

  if {$TIMING_DATA(action1,write_dspf)} {
    if {$TIMING_DATA(flat)} {
      fplan_write_dspf $TIMING_DATA(work_dir)/$cell.est_dspf
    } else {

      # Make a list of the hierarchical subcells in cell.
      set hier_defs ""
      foreach subcell [db_kids $cell] {
	if {[fplan_cell_info -is_hier $subcell]} {
	  lappend hier_defs $subcell
	}
      }

      foreach subcell $hier_defs {
	if {[fplan_cell_info -is_hier $subcell]} {
	  fplan_write_dspf -cell $subcell -flat 0 $TIMING_DATA(work_dir)/$subcell.est_dspf
	}
      }

      # Write out verilog for the cells we are timing.
      set vgfile $TIMING_DATA(work_dir)/$cell.tmp.vg
      msg "Writing $vgfile...\n"
      catch {file delete -force $vgfile}
      foreach subcell [concat $hier_defs $cell] {
	# nl_write_verilog currently closes the file for you,
	# so have to do this:
	set fd [open $vgfile "a"]
	nl_write_verilog $fd [fplan_db_cell module $subcell]
	catch {close $fd}  ;# catch in case nl closed it.
      }

      set TIMING_DATA(verilog_file) $vgfile
    }
  }

  if {$TIMING_DATA(action2,run_pearl)} {
    if {[pearl_run] != 0} {return}
  }
  if {$TIMING_DATA(action3,show_critical_paths)} {
    pearl_parse_output
    pearl_select_critical_path
  }
}

proc pearl_setup {{-nomenu} {filename ""}} {

  global SUFFIX TIMING_DATA _VERILOG_OPT MN_TECH

  puts "Setting up Pearl ..."

  if {$filename == ""} {
    set filename [lay_editcell].est_dspf
    # TODO: THIS IS NOT USED IF NOT FLAT
    set TIMING_DATA(spf_file) time_it/[file tail $filename]
  } else {
    set TIMING_DATA(spf_file) $filename
  }

  set basename [file rootname [file tail $filename]]

  # TODO: THIS IS USED ONLY IF FLAT
  set TIMING_DATA(verilog_file) time_it/$basename.vg

  use_init TIMING_DATA(constraint_file) "[file root $filename]$SUFFIX(timing_constraint)"
  use_init TIMING_DATA(timing_type) "setup"

  use_init TIMING_DATA(max_paths) "10"
  set TIMING_DATA_PROPS(max_paths) {-number}
  use_init TIMING_DATA(clk_names) "clk"
  use_init TIMING_DATA(clk_period) "5ns"
  use_init TIMING_DATA(driver_cell) ""
  use_init TIMING_DATA(input_transition) "200ps"
  use_init TIMING_DATA(max_transition) "1n"
  use_init TIMING_DATA(wave_name) "_WAVE_"
  use_init TIMING_DATA(arrival_time) "3n"
  use_init TIMING_DATA(departure_time) "2n"
  use_init TIMING_DATA(out_cap) "20fF"
  use_init TIMING_DATA(filter) "-same_path -same_node -same_pin"
  use_init TIMING_DATA(tech_file) "$MN_TECH.tech"
  use_init TIMING_DATA(ctlf_file) "$MN_TECH.ctlf"
  use_init TIMING_DATA(see_output) "1"
  set TIMING_DATA_PROPS(see_output) {-binary}
  use_init TIMING_DATA(pearl,command) "pearl"


  if {!$nomenu} {
    set prop_list ""
    foreach entry "arrival_time departure_time input_transition max_transition \
	clk_names clk_period wave_name \
	timing_type filter  max_paths \
	verilog_file constraint_file ctlf_file syn_libdb tech_file spf_file \
	pearl,command see_output" {
      set props [use_first TIMING_DATA_PROPS($entry) '-entry]
      lappend prop_list [eval list $entry TIMING_DATA($entry) $props]
    }

    set title "Pearl Setup"

    if {![prop_menu2 -title $title $prop_list]} {
      return ;# cancelled
    }
  }
}

proc pearl_run {} -desc {
  Run pearl using info in global TIMING_DATA
} {
  global SUFFIX TIMING_DATA

  set dir $TIMING_DATA(work_dir)

  set cell $TIMING_DATA(toplevelcell)

  set cmd_file $dir/$cell$SUFFIX(pearl_in)

  set out_file $dir/$cell$SUFFIX(pearl_out)


  # first write the commands out to a file

  # open to write the pearl command file
  if {[catch "open $cmd_file w" msg]} {
    # error
    max_error -buffer "pearl_run: Can not open $cmd_file.  Error: $msg"
    return 0
  }
  set FILE_ID $msg

  if {![file readable $TIMING_DATA(tech_file)]} {
    max_error -buffer "pearl_run: Aborting, can't read file $TIMING_DATA(tech_file). \
    This file is specified in the .maxrc file in the variable TIMING_DATA(tech_file)."
    return 0
  }

  puts $FILE_ID "readtechnology $TIMING_DATA(tech_file)"
  foreach lib $TIMING_DATA(ctlf_file) {
    puts $FILE_ID "readctlf $lib"
  }

  if {$TIMING_DATA(flat)} {

    puts $FILE_ID "readverilog $TIMING_DATA(verilog_file)"

    puts $FILE_ID "toplevelcell $cell"

    # if the suffix isn't rspf or dspf, assume a capacitance only file
    set suffix [string tolower [file extension $TIMING_DATA(spf_file)]]
    if {[string first spf $suffix] != -1} {
      # an rspf or dspf file
      puts $FILE_ID "readspf $TIMING_DATA(spf_file)"
    } elseif {[string first sdf $suffix] != -1} {
      # an sdf file
      puts $FILE_ID "readsdf $TIMING_DATA(spf_file)"
    } else {
      # assume it's just a plain old vanilla cap file
      puts $FILE_ID "readcapacitances $TIMING_DATA(spf_file)"
    }

  } else {

    # This file is a temp vierlog file generated previously.
    puts $FILE_ID "readverilog $TIMING_DATA(verilog_file)"

    # Make pearl suck in a dspf file for each instance.
    foreach cell_info [db_search_l cells -cell $cell] {
      struct max_cell c $cell_info
      if {[fplan_cell_info -is_hier ${c.def}]} {
	set modi [fplan_unfix_name ${c.id}]
	set mod [fplan_unfix_name ${c.def}]
	puts $FILE_ID "readspf -hierarchical -path_prefix $modi $dir/$mod.est_dspf"
      }
    }

    # Suck in top level dspf.
    set mod [fplan_unfix_name $cell]
    puts $FILE_ID "readdspf -hierarchical $dir/$mod.est_dspf"
    puts $FILE_ID "toplevelcell $mod"
  }

  puts $FILE_ID "setmaxpossibilities $TIMING_DATA(max_paths)"

  set clks ""
  set net ""
  set suggested_clks [use_first TIMING_DATA(clk_names)]

  # Sue searches to see if the clk names actually exist.
  foreach lab_info [db_search_l labels -non_hier] {
    struct max_label l $lab_info
    if {${l.kind} != "input"} {continue}

    set net ${l.text}  ;# TODO: this is not necessarily true.

    if {[lsearch -exact $suggested_clks $net] != -1 && [lsearch -exact $clks $net] == -1} {
      # this is a good clock input, use it
      lappend clks $net
    }
  }

  setl {period clk_fall} $TIMING_DATA(clk_period)
  set period [convert_if_no_units $period p]
  if {$clk_fall == ""} {
    # assume falling edge is mid way into period
    set clk_fall [pp_number [expr [parse_pp_number $period]/2.0]]
  }

  if {$clks == ""} {
    # no clocks, choose any input instead
    if {$net == ""} {
      # no inputs
      error "Aborting, no inputs found"
      return 69
    }

    puts "DPC INFO:  No input matches clock names, assuming combinational logic with no clocks."

    puts $FILE_ID "clock -domain $TIMING_DATA(wave_name) -cycle_time $period -create_node _input_ 0 $clk_fall"

    set input _input_
    set clk _input_
    set type input

    set arrival 0
    set departure 0

  } else {
    puts $FILE_ID "waveform -name $TIMING_DATA(wave_name) -period $period -rise_first 0 $clk_fall"

    set input $TIMING_DATA(wave_name)
    set type arrival

    foreach clk $clks {
      puts $FILE_ID "clockwaveform $clk $TIMING_DATA(wave_name)"
      set trace($clk) 1
    }

    set arrival $TIMING_DATA(arrival_time)
    set departure $TIMING_DATA(departure_time)
  }

  # if there is a default, use the default driver cell
  # TODO: can't turn off driver cell, if set to null, takes default
  if {[use_first TIMING_DATA(driver_cell)] != ""} {
    setl {cell port} $TIMING_DATA(driver_cell)
    
    if {$port == ""} {
      # use the port name "out" for the output port if not specified
      set port out
    }

    puts $FILE_ID "drivercell $cell $port *"
    set string ""

  } else {
    # need to add this for every input
    set string "inputslew %s $TIMING_DATA(input_transition) $TIMING_DATA(input_transition) $TIMING_DATA(input_transition) $TIMING_DATA(input_transition)"
  }

  foreach lab_info [db_search_l labels -non_hier] {
    struct max_label l $lab_info
    if {${l.kind} != "input"} {continue}

    set net ${l.text}  ;# TODO: this is not necessarily true.
    if {![info exists trace($net)]} {
      puts $FILE_ID "$type $net $input ^ $arrival $arrival $arrival $arrival"

      if {$string != ""} {
	puts $FILE_ID [format $string $net]
      }

      set trace($net) 1
    }
  }

  # put capacitance on output nodes
  foreach lab_info [db_search_l labels -non_hier] {
    struct max_label l $lab_info
    if {${l.kind} != "output"} {continue}

    set net ${l.text}  ;# TODO: this is not necessarily true.
    if {![info exists trace($net)]} {
      # TODO: Must use something real here!!!
      puts $FILE_ID "setnodecapacitance $net +$TIMING_DATA(out_cap)"
      if {$clks != ""} {
	puts $FILE_ID "departure $net $input ^ $departure $departure $departure $departure"
      }
      set trace($net) 1
    }
  }


  puts $FILE_ID "setpathfilter $TIMING_DATA(filter)"
#  puts $FILE_ID "setpathfilter -same_path"

  # this is the simplest
  puts $FILE_ID "idealclocks yes"

  # read in the constraint file if it exists
  if {[file readable $TIMING_DATA(constraint_file)]} {
    puts "Including constraint file: $TIMING_DATA(constraint_file)"
    puts $FILE_ID "include $TIMING_DATA(constraint_file)"
  } else {
    puts "Note: No constraint file: $TIMING_DATA(constraint_file)"
  }

  if {$clks == ""} {
    # combinational
    puts $FILE_ID "findpathsfrom $clk"
  } else {
    # sequential
    puts $FILE_ID "timingverify -check $TIMING_DATA(timing_type)"
  }

  # to highlite the critical path
  puts $FILE_ID "setdelaypathformat out_delay delta_delay load_cap fanout out_rise_fall out_node device cell"

#    for {set i 1} {$i <= $TIMING_DATA(max_paths)} {incr i} {
#      puts $FILE_ID "showpossibility $i"
#    }

  puts $FILE_ID "showpossibility 1 $TIMING_DATA(max_paths)"

  # comments needed by reader
  puts $FILE_ID "\# done"
  puts $FILE_ID "\# done"

  puts $FILE_ID "findmincycletime"
  # comments needed by reader
  puts $FILE_ID "\# done"
  puts $FILE_ID "\# done"

  # hack to get pearl to write out all delays
  set tmpin_file $dir/${cell}.tmp_in
  set tmpout_file $dir/${cell}.tmp_out

  puts $FILE_ID "shownodematches * > $tmpin_file"
  puts $FILE_ID "system sed -e 's/^ /showdelays/' -e 's/^Found/\#/' $tmpin_file > $tmpout_file"
  puts $FILE_ID "include $tmpout_file"

  # clean up
  #puts $FILE_ID "system rm -f $tmpin_file"
  #puts $FILE_ID "system rm -f $tmpout_file"

  # save terminal data for this nell
  #write_all_nets

#    puts $FILE_ID "findclockdelays"

  # show slow nodes
  puts $FILE_ID "findslownodes -limit $TIMING_DATA(max_transition) > $dir/${cell}$SUFFIX(slow_nodes)"

  # close the tempfile
  close $FILE_ID

  #set save_dir [pwd]
  #cd $dir
  unwind_catch {

    set status [pearl_exec $cmd_file $out_file $TIMING_DATA(see_output)]

    if {$status > 0} {
      puts "Aborting, pearl return status is $status"

      catch "exec cat $out_file" msg
      puts $msg

      return $status
    }

    # now delete the tmp files
    #exec rm -f $cmd_file

  } always {

    # return to calling directory
    #cd $save_dir
  }

  # return OK exit status
  return 0
}


# create the script file to run pearl (required becuase exec in tcl
# is broken) and then run it.  Return the pearl exit status.
proc pearl_exec {cmd_file out_file {see_output 0}} {

  global TIMING_DATA

  puts "\nRunning Pearl ..."

  if {$see_output == 0} {
    # direct all output to output file
    if {[catch "exec csh -cf \"$TIMING_DATA(pearl,command) < $cmd_file >&! $out_file\"" msg]} {
      puts $msg
      return 69
    }

  } else {
    # direct all output to screen and output file
    if {[catch "exec csh -cf \"$TIMING_DATA(pearl,command) < $cmd_file |& tee $out_file >&! [exec tty]\"" msg]} {
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


proc pearl_parse_output {{mode ""}} {

  global TIMING_OUT TIMING_DATA SUFFIX


  set basename [file root $TIMING_DATA(spf_file)]

  set pearl_out_file [file join $TIMING_DATA(work_dir) $basename$SUFFIX(pearl_out)]

  set FILE_ID [open $pearl_out_file r]
     
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
	set TIMING_OUT(cp,$index) ""
	set TIMING_OUT(cpmessage,$index) {{}}
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

	      lappend TIMING_OUT(cpmessage,$index) ""
	    }

	    lappend TIMING_OUT(cpmessage,$index) $line
	    continue
	  }

	  lappend TIMING_OUT(cpmessage,$index) $line

	  set word [string tolower [lindex $line 0]]
	  switch -- [string range _$word 0 5] {
	    _error - _warni - "_-----" {
	      # ignore warnings and errors here.
	      continue
	    }
	  }

	  switch [llength $line] {
	    9 {
	      # normal path
	      setl {delay delta cap fanout rf node dir cell} $line
	  
	      lappend TIMING_OUT(cp,$index) "cell $cell"
	      lappend TIMING_OUT(cp,$index) "net $node $delay $dir$rf"

	      set last_node $node

	      if {$first_node == ""} {
		set first_node $cell
	      }
	    }

	    8 {
	      # input node
	      setl {delay delta cap fanout rf node dir} $line
	  
	      lappend TIMING_OUT(cp,$index) "net $node $delay $dir$rf"

	      if {$first_node == ""} {
		set first_node $node
	      }
	    }

	    7 {
	      # normal path + net
	      setl {delay delta cap fanout rf node dir} $line
	      if {$last_node == $node} {
		set TIMING_OUT(cp,$index) \
		    [lreplace $TIMING_OUT(cp,$index) end end \
			 "net $node $delay $dir$rf"]
	      }

	      set last_node ""
	    }

	    5 {
	      # input node
	      setl {delay fanout rf node dir} $line
	  
	      lappend TIMING_OUT(cp,$index) "net $node $delay $dir$rf"
	    }
	  }
	}

	set TIMING_OUT(cp,value,$index) \
	    "$string($index) \($first_node -> $node\)"

	lappend TIMING_OUT(cpmessage,$index) ""
      }
    }

    # number of critical paths
    set TIMING_OUT(critical_paths) $index

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
  set cell [lay_editcell]
  set length [expr [string length $cell] + 1]

  set error 0
  set TIMING_OUT($cell,net_values) ""
  set got_data 1
  set name ""

  set clks [use_first TIMING_DATA(clk_names)]

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

	lappend TIMING_OUT($cell,net_values) \
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
    lappend TIMING_OUT($cell,net_values) "$name $values($name)"
  }

  #if {[info exists no_timing_nets]} {
  #  regsub -all {\{|\}} $no_timing_nets "" no_timing_nets
  #  puts "DPC WARNING, No timing for nets: $no_timing_nets\n"
  #}

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

proc pearl_display_critical_path_instances {{mode ""}} {

  global TIMING_OUT max_win

  set win .cpi

  if {$mode == "ifexists" && ![winfo exists $win]} {
    # don't update if this doesn't exists yet
    return
  }

  if {![info exists TIMING_OUT(cp,1)]} {
    puts "Aborting, must run pearl first."
    return
  }

  set index $TIMING_OUT(cp,index)

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

    set x [max 0 [expr [winfo rootx $max_win] - 50]]
    set y [expr [winfo rooty $max_win] + 150]

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
	"pearl_select_instance_path \{$selected\} same demorgan"

    frame $win.buttons

    frame $win.default -relief sunken -bd 1
    button $win.done -text "Display CP" -padx 1 -pady 1 \
	-command {pearl_display_critical_path slopes}
    pack $win.done -in $win.default -padx 1m -pady 1m -ipadx 2m
    pack $win.default -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m

    button $win.all -text "Display All" -padx 1 -pady 1 \
	-command {pearl_display_timing}
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
  wm title $win "MAX Timing: Critical Path \#$index Instances"

  # fill 'er up
  set i 1
  set cell ""
  foreach list [use_first TIMING_OUT(cp,$index)] {
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

proc pearl_select_critical_path {} {

  global TIMING_OUT max_win

  set win .cp

  # Just in case there is an old one around
  if {![catch "winfo rootx $win" x]} {
    set y [winfo rooty $win]

    # hack to account for borders
    incr x -3
    incr y -25

    catch "destroy $win"

  } else {
    set x [max 0 [expr [winfo rootx $max_win] - 100]]
    set y [expr [winfo rooty $max_win] + 100]
  }

  if {![info exists TIMING_OUT(cp,1)]} {
    puts "Aborting, must run pearl first."
    return
  }

  toplevel $win 

  wm geometry $win "+$x+$y"
  wm title $win "MAX Timing"

  # don't let user resize this
  wm resizable $win 0 0
    
  label $win.note -text "Select Critical Path:"

  pack $win.note -side top

  set max_paths 20

  set TIMING_OUT(cp,index) 1

  if {$TIMING_OUT(critical_paths) <= $max_paths} {

    set c [frame $win.entry]
    pack $c -side left
    for {set i 1} {$i <= $TIMING_OUT(critical_paths)} {incr i} {
    
      set text "$i: $TIMING_OUT(cp,value,$i)"
      regsub -all {\{|\}} $text "" text

      set b [radiobutton $c.cp$i \
		 -text $text \
		 -variable TIMING_OUT(cp,index) \
		 -command {pearl_display_critical_path_instances ifexists} \
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

    for {set i 1} {$i <= $TIMING_OUT(critical_paths)} {incr i} {
    
      set text "$i: $TIMING_OUT(cp,value,$i)"
      regsub -all {\{|\}} $text "" text



      set b [radiobutton $f.cp$i \
		 -text $text \
		 -variable TIMING_OUT(cp,index) \
		 -command {pearl_display_critical_path_instances ifexists} \
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
    set max [min $max_paths $TIMING_OUT(critical_paths)]
    set height [expr $incr * $max]
    $canvas config -width $width -height $height
  }

  frame $win.buttons

  frame $win.default -relief sunken -bd 1
  button $win.done -text "Display CP" -padx 1 -pady 1 \
    -command {pearl_display_critical_path slopes}
  pack $win.done -in $win.default -padx 1m -pady 1m -ipadx 2m
  pack $win.default -side left -in $win.buttons \
      -padx 4m -ipadx 1m -pady 1m

  button $win.all -text "Display All" -padx 1 -pady 1 \
    -command {pearl_display_timing}
  pack $win.all -side left -in $win.buttons \
      -padx 4m -ipadx 1m -pady 1m

  button $win.cpi -text "CP Instances" -padx 1 -pady 1 \
    -command {pearl_display_critical_path_instances raise}
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
  pearl_display_critical_path_instances ifexists
}


proc pearl_display_critical_path {{slopes ""} {index ""}} -doc {
  displays the critical path on the schematic by selecting the 
  wires/instances in the paths and displaying the timing along it.
} {

  global TIMING_OUT HIERARCHY cur_s cur_c COLORS FONT 

  if {$index == "" } {
    set index $TIMING_OUT(cp,index)
  }

  # clear selection
  sel_clear
  db_flyline -delete

  # get the name in this critical path
  set cell [lay_editcell]
  set curmod [fplan_db_cell module $cell]
  set length [string length $curmod]

  set io_possible 0

  # check for special case
  set not_cp 1
  set cells 0

  # walk thru the critical path highliting stuff visible on this schematic
  foreach pair $TIMING_OUT(cp,$index) {

    setl {type name value slope} $pair

    # TODO: reenable this:
    if {0} {

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
    }

    switch $type {
      cell {
	sel_cell2 -more $name
	continue

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

	if {[string first "/" $name] == -1} {
	  # It might be a label in the top cell.
	  # sel_labels does nothing if it fails, but catch it against future changes.
	  catch {sel_labels -more -text $name}
	  #set lab_list [db_search_l labels -non_hier -exact $name]
	}

	# TODO
	continue

	if {$slopes != "" && $slope != ""} {
	  set value "$value\n$slope"
	}

	set all_names [get_net_equiv $name]

	foreach name [concat $name $all_names] {
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

  # TODO: fix
  eval lay_box [db_bbox]
  return

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


  if {$not_cp && $cells > 0} {
    error "Aborting, can't display critical path thru this cell.  It probably wasn't in the critical path or is a leaf cell."
    return 0
  }

  return 1
}
