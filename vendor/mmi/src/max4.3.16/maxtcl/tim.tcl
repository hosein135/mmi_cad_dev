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

set RCSVERSION(tim.tcl) { $Revision: 1.2 $ }
# Code taken from sue on 2/22/01

set SUFFIX(pearl_in) .pearl_in
set SUFFIX(pearl_out) .pearl_out

set SUFFIX(primetime_in) .primetime_in
set SUFFIX(primetime_out) .primetime_out

set SUFFIX(timing_constraint) .constraint
set SUFFIX(slow_nodes) .slow_nodes

use_init SUFFIX(verilog) .vg

# TOODOO
# use .db files for timing


### TODO: errors in hier primetime -- what if read_verilog, read_parasitics
###             for each module?
### TODO: menu to use existing verilog/dspf

proc tim_time_it {} {
  global TIMING_DATA SUFFIX nl_current_design

  fplan_dspf_setup -nomenu
  timing_setup -nomenu

  # set these up even though we are only using one -- only sets vars.
  pearl_setup -nomenu
  primetime_setup -nomenu

  _fplan_init_rc

  set prop_list ""

  if {[lay_editcell] != [lay_rootcell]} {
    error "time_it: error: can not be run when in edit-in-place."
  }

  set cell [lay_editcell]
  set TIMING_DATA(toplevelcell) $cell
  # Alert the user: they must be editing the cell they are interested in.
  lappend prop_list [list "Cell:" TIMING_DATA(toplevelcell) -label -separator]

  use_init TIMING_DATA(action1,write_dspf) 1
  lappend prop_list [list "Write DSPF" TIMING_DATA(action1,write_dspf) -binary]
  use_init TIMING_DATA(action2,run_timer) 1
  lappend prop_list [list "Run Timing" TIMING_DATA(action2,run_timer) -binary]
  use_init TIMING_DATA(action3,show_critical_paths) 1
  lappend prop_list [list "Show Critical Paths" TIMING_DATA(action3,show_critical_paths) -binary]

  # If the hierarchical method works, why would you do it flat any more?
  # I guess as a check to make sure that hierarchical works.
  use_init TIMING_DATA(flat) 1
  lappend prop_list [list "Flat timing method" TIMING_DATA(flat) -binary \
    -help {Run hierarchically.}]

  use_init TIMING_DATA(update_port_timing) 1
  lappend prop_list [list "Update port timing" TIMING_DATA(update_port_timing) \
			 -binary \
    -help {If true, timing and model data on ports is automatically updated.}]

  use_init TIMING_DATA(rel_work_dir) ./time_it
  lappend prop_list [list "Work directory" TIMING_DATA(rel_work_dir) -entry -separator]

  lappend prop_list [list "Timing Setup..." "" -button "timing_setup"]

  use_init TIMING_DATA(simulator) primetime
  lappend prop_list [list "Timing Tool" TIMING_DATA(simulator) -choice {primetime pearl speedy}]

  lappend prop_list [list "Static Timing Analyser Setup..." "" -button {$TIMING_DATA(simulator)_setup}]
  lappend prop_list [list "DSPF Setup..." "" -button fplan_dspf_setup]

  if {![prop_menu2 -title "Time It" $prop_list]} {
    return ;# cancelled.
  }

  set TIMING_DATA(last_work_dir) [use_first TIMING_DATA(work_dir)]

  # now convert work dir into actual path based on toplevelcell
  if {[string index $TIMING_DATA(rel_work_dir) 0] == "."} {
    # make absolute
    if {[string index $TIMING_DATA(rel_work_dir) 1] == "."} {
      # starts with ..
      set TIMING_DATA(work_dir) \
	  "[file dirname [file dirname [lindex [cell_info $TIMING_DATA(cell)] 1]]][string range $TIMING_DATA(rel_work_dir) 2 end]"

    } else {
      set TIMING_DATA(work_dir) \
	  "[file dirname [lindex [cell_info $TIMING_DATA(cell)] 1]][string range $TIMING_DATA(rel_work_dir) 1 end]"
    }
  }

  catch {file mkdir $TIMING_DATA(work_dir)}

  # Make a list of the hierarchical subcells in cell.
  # do this even for non flat
  set TIMING_DATA(hier_defs) ""
  set TIMING_DATA(models) ""
  
  # must load all max files for below to work
  cell_load_hierarchy

  # search recursively down to find all defs
  set list $cell
  catch {unset trace}
  while {[llength $list] > 0} {
    foreach subcell [db_kids [lindex $list 0]] {    
      if {[info exists trace($subcell)]} {
	# already got this one
	continue
      }
      set trace($subcell) 1

      if {[fplan_cell_info -is_hier $subcell]} {
	if {[db_prop -def $subcell use_model] == 1} {
	  # use model
	  lappend TIMING_DATA(models) $subcell
	} else {
	  lappend TIMING_DATA(hier_defs) $subcell

	  # add to list
	  lappend list $subcell
	}
      }
    }

    set list [lrange $list 1 end]
  }

  # need the names associated with these defs
  set TIMING_DATA(hier_names) ""
  foreach def $TIMING_DATA(hier_defs) {
    foreach subcell [db_instances -of $def] {
      lappend TIMING_DATA(hier_names) [lindex $subcell 0]
    }
  }  

  if {$TIMING_DATA(action1,write_dspf)} {
    if {$TIMING_DATA(flat)} {
      # write dspf for the whole thing -- models or no
      fplan_write_dspf $TIMING_DATA(work_dir)/$cell$SUFFIX(dspf)

    } else {
      foreach subcell [concat $TIMING_DATA(hier_defs) $cell] {
	# TODO: only write dspf if older than .max or buffer modified
	set dspf_file $TIMING_DATA(work_dir)/$subcell$SUFFIX(dspf)
	fplan_write_dspf -cell $subcell -flat 0 $dspf_file
      }
    }
  }

  if {$TIMING_DATA(action2,run_timer)} {
    set vgfile $TIMING_DATA(work_dir)/$cell.tmp.vg
    msg "Writing $vgfile...\n"

    if {$TIMING_DATA(flat)} {
      # write the verilog for the whole thing to go with
      nl_write_verilog $vgfile $cell

    } else {
      # Write out one verilog with all the cells we are timing.
      catch {file delete -force $vgfile}
      foreach subcell [concat $TIMING_DATA(hier_defs) $cell] {
	# nl_write_verilog currently closes the file for you, so have to do this:
	set fd [open $vgfile "a"]
	nl_write_verilog $fd [fplan_db_cell module $subcell]
	catch {close $fd}  ;# catch in case nl closed it.
      }
    }

    set TIMING_DATA(verilog_file) $vgfile
  }

  if {$TIMING_DATA(update_port_timing)} {
    global TIMING_DATA_DEFAULTS_TRACE
    # update all budgets
    puts "Updating default timing budgets ..."
    foreach def [concat $TIMING_DATA(hier_defs) $TIMING_DATA(models) $cell] {
      if {[info exists TIMING_DATA_DEFAULTS_TRACE($def)]} {
	# only do one per session
	continue
      }
      set TIMING_DATA_DEFAULTS_TRACE($def) 1

      add_default_budgets -type timing -def $def
      add_default_budgets -type model -def $def
    }
  }

  if {$TIMING_DATA(action2,run_timer)} {

    # must make sure this is correct
    set nl_current_design $TIMING_DATA(toplevelcell)

    switch $TIMING_DATA(simulator) {
      "pearl" {
	tim_write_pearl_files
	if {[tim_run_pearl] != 0} {return}

      }
      "primetime" {
	tim_write_primetime_files
	if {[tim_run_primetime] != 0} {return}

      }
      "speedy" {
	# The pearl files are for the old sue style interface.
	#tim_write_pearl_files
	tim_run_speedy

      }
      default {
	error "invalid TIMING_DATA(simulator): $TIMING_DATA(simulator)"
      }
    }
  }

  if {$TIMING_DATA(action3,show_critical_paths)} {
    switch $TIMING_DATA(simulator) {
      "pearl" {
	tim_parse_pearl_output
      }
      "primetime" {
	tim_parse_primetime_output
      }
      "speedy" {
	tim_parse_speedy_output
      }
    }
  }

  tim_select_critical_path
  tim_display_critical_path

  tim_display_timing

  if {$TIMING_DATA(update_port_timing)} {
    # update T menu
    tim_backannotate_timing
  }

  # alert user to get to work
  bell
}


proc timing_setup {{-nomenu} {filename ""}} -desc {
  setup for everything that is not timing tool specific
} {

  global SUFFIX TIMING_DATA MN_TECH

#  puts "Setting up timing parameters ..."

  if {[lay_editcell] != [use_first TIMING_DATA(cell)]} {
    # different cell, reset these
    set TIMING_DATA(cell) [lay_editcell]

    catch {unset TIMING_DATA(verilog_file)}
    catch {unset TIMING_DATA(spf_file)}
    catch {unset TIMING_DATA(constraint_file)}
  }

  if {$filename == ""} {
    set filename [lindex [cell_info $TIMING_DATA(cell)] 1]
  }

  # TODO: THIS IS USED ONLY IF FLAT
#  use_init TIMING_DATA(verilog_file) [file rootname $filename]$SUFFIX(verilog)

  # TODO: THIS IS NOT USED IF NOT FLAT???
#  use_init TIMING_DATA(spf_file) [file rootname $filename]$SUFFIX(dspf)

  # add a separator
  set TIMING_DATA_PROPS(spf_file) {-entry -separator}

  use_init TIMING_DATA(constraint_file) "[file rootname $filename]$SUFFIX(timing_constraint)"
  use_init TIMING_DATA(timing_type) "setup"
  set TIMING_DATA_PROPS(timing_type) {-choice {setup hold}}

  use_init TIMING_DATA(max_paths) "10"
  set TIMING_DATA_PROPS(max_paths) {-number 1 -incr 1}
  use_init TIMING_DATA(clk_names) "clk"
  use_init TIMING_DATA(clk_period) "5ns"
  use_init TIMING_DATA(ext_input_budget) "3ns"
  use_init TIMING_DATA(ext_output_budget) "2ns"

  use_init TIMING_DATA(ext_driver) ""
  use_init TIMING_DATA(input_transition) "200ps"
  use_init TIMING_DATA(max_transition) "1ns"

  use_init TIMING_DATA(ext_cap) "20fF"

  if {!$nomenu} {
    set prop_list ""
    foreach entry [list verilog_file constraint_file spf_file \
		       timing_type max_paths clk_names clk_period \
		       ext_input_budget ext_output_budget ext_driver \
		       input_transition max_transition ext_cap \
		      ] {

      lappend prop_list [concat $entry TIMING_DATA($entry) \
			     [use_first TIMING_DATA_PROPS($entry) '-entry]]
      }

    set title "Timing Setup"

    if {![prop_menu2 -title $title $prop_list]} {
      return ;# cancelled
    }
  }
}


proc pearl_setup {{-nomenu}} -desc {
  pearl specific timing
} {

  global SUFFIX TIMING_DATA MN_TECH

#  puts "Setting up Pearl timing ..."

  use_init TIMING_DATA(pearl,command) "pearl"

  use_init TIMING_DATA(pearl_setup) ""
  #  use_init TIMING_DATA(pearl_setup) "module add pearl"

  use_init TIMING_DATA(tech_file) "$MN_TECH.tech"
  use_init TIMING_DATA(ctlf_file) "$MN_TECH.ctlf"
  use_init TIMING_DATA(filter) {-same_path -similar_path -node_suffix [#]}

  use_init TIMING_DATA(pearl,register_input_data_names) "d*"

  use_init TIMING_DATA(wave_name) _WAVE_
  use_init TIMING_DATA(see_output) 0
  set TIMING_DATA_PROPS(see_output) {-binary}

  if {!$nomenu} {
    set prop_list ""
    foreach entry [list pearl,command pearl_setup tech_file ctlf_file filter \
		       pearl,register_input_data_names wave_name see_output \
		      ] {

      lappend prop_list [concat $entry TIMING_DATA($entry) \
			     [use_first TIMING_DATA_PROPS($entry) '-entry]]
      }

    set title "Pearl Setup"

    if {![prop_menu2 -title $title $prop_list]} {
      return ;# cancelled
    }
  }
}


proc primetime_setup {{-nomenu}} -desc {
  primetime specific timing
} {

  global SUFFIX TIMING_DATA MN_TECH

#  puts "Setting up Primetime timing ..."

  use_init TIMING_DATA(primetime,command) pt_shell

#  use_init TIMING_DATA(primetime_setup) "source /volume/cad/cad_cshrc ; module add primetime"
  use_init TIMING_DATA(primetime_setup) "module add primetime/2001.08"

  set TIMING_DATA(db_file) [use_first TIMING_DATA(db_file) TIMING_DATA(syn_libdb)'$MN_TECH.db]
  use_init TIMING_DATA(db_time_units) 1ns
  use_init TIMING_DATA(db_cap_units) 1pF

  use_init TIMING_DATA(wave_name) _WAVE_
  use_init TIMING_DATA(see_output) 0
  set TIMING_DATA_PROPS(see_output) {-binary}

  if {!$nomenu} {
    set prop_list ""
    foreach entry [list primetime,command primetime_setup \
		       db_file db_time_units db_cap_units \
		       wave_name see_output \
		      ] {

      lappend prop_list [concat $entry TIMING_DATA($entry) \
			     [use_first TIMING_DATA_PROPS($entry) '-entry]]
      }

    set title "Primetime Setup"

    if {![prop_menu2 -title $title $prop_list]} {
      return ;# cancelled
    }
  }
}


proc tim_write_pearl_files {} -desc {
  Run pearl using info in global TIMING_DATA
  Code originally by Lee from sue, modified for max.
} {
  global SUFFIX TIMING_DATA

  set dir $TIMING_DATA(work_dir)

  set cell $TIMING_DATA(toplevelcell)

  set TIMING_DATA(cmd_file) $dir/$cell$SUFFIX(pearl_in)

  set TIMING_DATA(out_file) $dir/$cell$SUFFIX(pearl_out)

  # first write the commands out to a file

  # open to write the pearl command file
  if {[catch "open $TIMING_DATA(cmd_file) w" msg]} {
    # error
    max_error -abort "Can not open $TIMING_DATA(cmd_file).  Error: $msg"
    return 0
  }
  set FILE_ID $msg

  if {![file readable $TIMING_DATA(tech_file)]} {
    max_error -abort "Aborting, can't read file $TIMING_DATA(tech_file). \
    This file is specified in the .maxrc file in the variable TIMING_DATA(tech_file)."
  }

  puts $FILE_ID "readtechnology $TIMING_DATA(tech_file)"
  foreach lib $TIMING_DATA(ctlf_file) {
    puts $FILE_ID "readctlf $lib"
  }

  # add models
  foreach subcell $TIMING_DATA(models) {
    set filename [lindex [cell_info $subcell] 1]

    puts $FILE_ID "readctlf [file rootname $filename].ctlf"
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
    # hierarchical
    set topmod [fplan_unfix_name $cell]

    # This file is a temp verilog file generated previously.
    puts $FILE_ID "readverilog $TIMING_DATA(verilog_file)"
    puts $FILE_ID "toplevelcell $topmod"

    # Make pearl suck in a dspf file for each instance.
    foreach one $TIMING_DATA(hier_names) {
      foreach cell_info [db_instances -id $one -cell $cell] {
	struct max_cell c $cell_info
	if {[fplan_cell_info -is_hier ${c.def}]} {
	  set modi [fplan_unfix_name ${c.id}]
	  set mod [fplan_unfix_name ${c.def}]
	  puts $FILE_ID "readspf -hierarchical -path_prefix $modi $dir/$mod$SUFFIX(dspf)"
	}
      }
    }

    # Suck in top level dspf.
    puts $FILE_ID "readspf -hierarchical $dir/$topmod$SUFFIX(dspf)"
  }

  puts $FILE_ID "setmaxpossibilities $TIMING_DATA(max_paths)"

  set clks ""
  set net ""
  set suggested_clks [use_first TIMING_DATA(clk_names)]

  # Sue searches to see if the clk names actually exist.
  foreach lab_info [db_search_labels -non_hier] {
    struct max_label l $lab_info
    if {${l.kind} != "input"} {continue}

    set net ${l.text}  ;# TODO: this is not necessarily true.

    if {[lsearch -exact $suggested_clks $net] != -1 && \
	    [lsearch -exact $clks $net] == -1} {
      # this is a good clock input, use it
      lappend clks $net
    }
  }

  setl {period clk_fall} $TIMING_DATA(clk_period)
  set period [tim_convert_if_no_units $period p]
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

    msg "Warning:  No input matches clock names, assuming combinational logic with no clocks.\n"

    puts $FILE_ID "clock -domain $TIMING_DATA(wave_name) -cycle_time $period -create_node _input_ 0 $clk_fall"

    set input _input_
    set clk _input_
    set type input

  } else {
    puts $FILE_ID "waveform -name $TIMING_DATA(wave_name) -period $period -rise_first 0 $clk_fall"

    set input $TIMING_DATA(wave_name)
    set type arrival

    foreach clk $clks {
      puts $FILE_ID "clockwaveform $clk $TIMING_DATA(wave_name)"
      set trace($clk) 1
    }
  }

  # if there is a default, use the default driver cell
  # TODO: can't turn off driver cell, if set to null, takes default
  if {[use_first TIMING_DATA(ext_driver)] != ""} {
    setl {cell port} $TIMING_DATA(ext_driver)
    
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

  foreach lab_info [db_search_labels -non_hier] {
    struct max_label l $lab_info
    if {${l.kind} != "input"} {continue}

    set net ${l.text}  ;# TODO: this is not necessarily true.
    if {![info exists trace($net)]} {

      if {$clks != ""} {
	# sequential
	set actual [fplan_db_pin getprop ${l.text} ext_actual]
	set budget [string trim [fplan_db_pin getprop ${l.text} ext_budget] <>]
	set arrival [use_first actual budget TIMING_DATA(ext_input_budget)]

      } else {
	set arrival 0
      }

      puts $FILE_ID "$type $net $input ^ $arrival $arrival $arrival $arrival"

      if {$string != ""} {
	puts $FILE_ID [format $string $net]
      }

      set trace($net) 1
    }
  }

  # put external delay and capacitance on output nodes
  foreach lab_info [db_search_labels -non_hier] {
    struct max_label l $lab_info
    if {${l.kind} != "output"} {continue}

    set net ${l.text}  ;# TODO: this is not necessarily true.
    if {![info exists trace($net)]} {

      set cap [string trim [fplan_db_pin getprop ${l.text} ext_cap] <>]
      set ext_cap [use_first cap TIMING_DATA(ext_cap)]
      puts $FILE_ID "setnodecapacitance $net +$ext_cap"

      if {$clks != ""} {
	# sequential
	set actual [fplan_db_pin getprop ${l.text} ext_actual]
	set budget [string trim [fplan_db_pin getprop ${l.text} ext_budget] <>]
	set departure [use_first actual budget TIMING_DATA(ext_output_budget)]

	puts $FILE_ID "departure $net $input ^ $departure $departure $departure $departure"
      }
      set trace($net) 1
    }
  }


  puts $FILE_ID "setpathfilter $TIMING_DATA(filter)"

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

  # write only inputs/outputs and data in on regs
  puts $FILE_ID "\# type port"

  puts $FILE_ID "showpinmatches * > $tmpin_file"
  puts $FILE_ID "system sed -e 's/^ /showdelays/' -e 's/^Found/\#/' $tmpin_file > $tmpout_file"
  puts $FILE_ID "include $tmpout_file"

  puts $FILE_ID "\# type pin"

  foreach pin_name $TIMING_DATA(pearl,register_input_data_names) {
    puts $FILE_ID "showpinmatches */$pin_name > $tmpin_file"
    puts $FILE_ID "system sed -e 's/^ /showdelays/' -e 's/^Found/\#/' $tmpin_file > $tmpout_file"
    puts $FILE_ID "include $tmpout_file"

# add this and parse for slews
#    puts $FILE_ID "showpinmatches */$pin_name > $tmpin_file"
#    puts $FILE_ID "system sed -e 's/^ /showslews/' -e 's/^Found/\#/' $tmpin_file > $tmpout_file"
#    puts $FILE_ID "include $tmpout_file"
  }

  # clean up
  #puts $FILE_ID "system rm -f $tmpin_file"
  #puts $FILE_ID "system rm -f $tmpout_file"

  # save terminal data for this nell
  #write_all_nets

#    puts $FILE_ID "findclockdelays"

  # show slow nodes
  puts $FILE_ID "findslownodes -limit $TIMING_DATA(max_transition) > $dir/$cell$SUFFIX(slow_nodes)"

  # close the tempfile
  close $FILE_ID
}


proc tim_run_speedy {} -desc {
  Run speedy using the old interface, similar to sue.
} -doc {
  In this mode, speedy does not use the NL database.
  Speedy gets its info from the dspf file, the verilog netlist, and the
  pearl command file.
} {

  global TIMING_DATA nl_current_design

# TODO: add constraints like arrival and dept.

  # make sure speedy is loaded
#  util_load_pkg speedy_package.so
  util_load_pkg /volume/mmi/src/speedy/speedy_package.so

  set cell $TIMING_DATA(toplevelcell)
  set TIMING_DATA(out_file) $TIMING_DATA(work_dir)/$cell.speedy_out

  # Speedy bitches if you do this twice, so do it just once.
  global TIM_SPEEDY_HAS_READ_LIBFILE
  if {[use_first TIM_SPEEDY_HAS_READ_LIBFILE] == ""} {
    speedy_command read_libfile $TIMING_DATA(lib_file)
    set TIM_SPEEDY_HAS_READ_LIBFILE 1
  }

  set nl_current_design $TIMING_DATA(toplevelcell)

puts aaa

  speedy_set_tcl_obj nl_current_design $nl_current_design
  speedy_command load_design_from_nl

puts bbb

  speedy_command read_dspffile $TIMING_DATA(spf_file) 

puts ccc

  speedy_command global_timing

puts ddd

  set tmpfile $TIMING_DATA(work_dir)/speedy_output.tmp
  speedy_command write_timing_out_file $tmpfile

puts eee

  # Slurp up the speedy timing stuff.
  unwind_catch {
    set fd [open $tmpfile r]
    set result ""
    while {[gets $fd line] >= 0} {
      lappend result [string trim $line]
    }
  } always {
    close $fd
  }



#  speedy_command load_design_from_nl
#  speedy_command regularize_nets
#  speedy_command compute_net_characteristics
#  speedy_command global_timing
#  speedy_command write_long_paths_file 10 $TIMING_DATA(out_file)

  #speedy_command read_timing_in_file $TIMING_DATA(cmd_file)
  #speedy_command global_timing
  #speedy_command write_timing_out_file $TIMING_DATA(out_file)
}


proc tim_run_pearl {} {
  global TIMING_DATA

  unwind_catch {

    set status [tim_pearl_exec $TIMING_DATA(cmd_file) $TIMING_DATA(out_file) $TIMING_DATA(see_output)]

    if {$status > 0} {
      puts "Aborting, pearl return status is $status"

      catch "exec cat $TIMING_DATA(out_file)" msg
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


proc tim_pearl_exec {cmd_file out_file {see_output 0}} -desc {
Run pearl.  Return the pearl exit status.
} {

  global TIMING_DATA

  puts "\nRunning Pearl ..."

  if {$TIMING_DATA(pearl_setup) == ""} {
    set setup ""
  } else {
    set setup "$TIMING_DATA(pearl_setup) ; "
  }

  # changed from csh -cf to csh -c

  if {$see_output == 0} {
    # direct all output to output file
    if {[catch "exec csh -c \"$setup$TIMING_DATA(pearl,command) < $cmd_file >&! $out_file\"" msg]} {
      puts $msg
      return 69
    }

  } else {
    # direct all output to screen and output file
    if {[catch "exec csh -c \"$setup$TIMING_DATA(pearl,command) < $cmd_file |& tee $out_file >&! [exec tty]\"" msg]} {
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


proc tim_parse_pearl_output {} -desc {
  Code originally by Lee from sue, modified for max.
} {
  global TIMING_OUT TIMING_DATA

  set pearl_out_file $TIMING_DATA(out_file)

  set FILE_ID [open $pearl_out_file r]
     
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
    set last_cell ""
    while {$poss || [gets $FILE_ID line] >= 0} {
      if {[lindex $line 2] == "done"} {
	# add last if there is one
	if {$last_cell != "" && $last_cell != "."} {
	  lappend TIMING_OUT(cp,$index) "cell $last_cell"	      
	}

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
	set last_cell ""
	
	set first 1
	while {[gets $FILE_ID line] >= 0} {
	  if {[lindex $line 0] == "cmd>"} {
	    break
	  }
	  if {[lindex $line 0] == "Possibility"} { 
	    # next one
	    set poss 1

	    # add last if there is one
	    if {$last_cell != "" && $last_cell != "."} {
	      lappend TIMING_OUT(cp,$index) "cell $last_cell"	      
	    }

	    break
	  } 

	  if {$first} {
	    if {[lindex $line 0] == "Data"} {
	      # look for end point here (hack)
	      set last_cell [file dirname [lindex $line 5]]

	      continue
	    }

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

  # read term values
  set cell $TIMING_DATA(toplevelcell)
  set length [expr [string length $cell] + 1]

  set error 0
  set TIMING_OUT($cell,net_values) ""
  set got_data 1
  set name ""
  set type port

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
      if {[lrange $line 1 3] == "\# type port"} {
	set type port
      }
      if {[lrange $line 1 3] == "\# type pin"} {
	set type pin
      }

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
	    "$name port [parse_pp_number $rise]"
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

    set types($name) $type

    if {[info exists values($name)]} {
      set values($name) [max $values($name) $rise $fall]
    } else {
      set values($name) [max $rise $fall]
    }
  }

  foreach name [array names values] {
    lappend TIMING_OUT($cell,net_values) "$name $types($name) [pp_number $values($name)]"
  }

  #if {[info exists no_timing_nets]} {
  #  regsub -all {\{|\}} $no_timing_nets "" no_timing_nets
  #  puts "DPC WARNING, No timing for nets: $no_timing_nets\n"
  #}

  # close the file
  close $FILE_ID
}


proc tim_parse_speedy_output {{mode ""}} -desc {
} {
  global TIMING_OUT TIMING_DATA SUFFIX

  set FILE_ID [open $TIMING_DATA(out_file) r]
     
  if {$mode == ""} {
    # parse critical paths

    set index 0

    # vvvv TEMPORARY: just start the first path.
    #incr index
    #set TIMING_OUT(cp,$index) ""
    #set last_node ""
    # ^^^^ TEMPORARY:

    set first_node ""

    while {[gets $FILE_ID line] >= 0} {

	switch [lindex $line 0] {
	  "N" {	;# net, format:  N v delay
	    set net [lindex $line 1]
	    if {$first_node == ""} {
	      set first_node $net
	    } else {
	      set last_node $net
	    }
	  }
	  "O" {	;# output pin, format: O  pin_name cumulative_delay
	  }
	  "I" {	;# input pin, format: I  pin_name cumulative_delay
	    if {$last_node != ""} {
	      lappend TIMING_OUT(cp,$index) "net $last_node [lindex $line 2]"
	    }
	  }
	  "G" {	;# gate, format: G inst_name type_name internal_delay
	    # The first G from speedy is not really a gate, it is the input pin, maybe.
	    set gate_type [lindex $line 2]
	    if {$gate_type != "external_in" && $gate_type != "external_out"} {
	      lappend TIMING_OUT(cp,$index) "cell [lindex $line 1]"
	    }
	  }
	  "path" {
	    # Start next path.
	    if {$first_node != ""} {
	      # Finish the previous path
	      set TIMING_OUT(cp,value,$index) "slack $slack \($first_node -> $last_node\)"
	    }
	    incr index
	    set TIMING_OUT(cp,$index) ""
	    set slack [pp_number [expr [parse_pp_number $TIMING_DATA(clk_period)] - \
		[parse_pp_number [lindex $line 2]]]]
	    set last_node ""
	    set first_node ""
	  }
	}
    }


    if {$index} {
      set TIMING_OUT(cp,value,$index) "slack $slack \($first_node -> $last_node\)"
    }
  }
  set TIMING_OUT(critical_paths) $index

  # close the file
  close $FILE_ID
}


# if a number has no units, add the given units, otherwise, simply
# return the number.  This is for backwards compatibility.
proc tim_convert_if_no_units {number units} {

  if {[catch "expr $number + 0"]} {
    # not a valid number, assume it contains units
    return $number
  }

  # unitify this
  return $number$units
}


proc tim_display_critical_path_instances {{mode ""}} -desc {
  make CP instances window
} {

  global TIMING_OUT max_win TIMING_DATA

  set win .cpi

  if {$mode == "ifexists" && ![winfo exists $win]} {
    # don't update if this doesn't exists yet
    return
  }

  if {![info exists TIMING_OUT(cp,1)]} {
    puts "Aborting, must run timing tool first."
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
	"tim_display_critical_path $selected"

    frame $win.buttons

    frame $win.default -relief sunken -bd 1
    button $win.done -text "Display CP" -padx 1 -pady 1 \
	-command {tim_display_critical_path}
    pack $win.done -in $win.default -padx 1m -pady 1m -ipadx 2m
    pack $win.default -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m

    button $win.all -text "Display All" -padx 1 -pady 1 \
	-command {tim_display_timing}
    pack $win.all -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m

    button $win.previous -text "Previous CP" -padx 1 -pady 1 \
	-command {tim_change_cp -1}
    pack $win.previous -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m

    button $win.next -text "Next CP" -padx 1 -pady 1 \
	-command {tim_change_cp 1}
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
  wm title $win "$TIMING_DATA(toplevelcell) Timing: Critical Path \#$index Instances"

  # fill 'er up
  set i 1
  set cell ""
  set cell_type ""
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

      set text [format "%4d: %8s %12s  %s %s" $i $delay $slew $cell $cell_type]
      regsub -all {\{|\}} $text "" text

      $win.instances insert end $text

      incr i
      set cell ""
      set cell_type ""

    } elseif {[lindex $list 0] == "cell"} {

      if {$cell != ""} {
	# no timing for this one
	set text "$i: ---- \[----\] $cell"
	regsub -all {\{|\}} $text "" text

	$win.instances insert end $text
      }

      set cell [lindex $list 1]

      global nl_hierarchy_separator
      set save_nl_hierarchy_separator $nl_hierarchy_separator
      set nl_hierarchy_separator /

      if {[catch {nl_get_cell_reference $cell} cell_type]} {
	set cell_type ""
      } else {
	set cell_type "($cell_type)"
      }
      set nl_hierarchy_separator $save_nl_hierarchy_separator

    }
  }

  if {$cell != ""} {
    # no timing for this one
    set text [format "%4d: %8s %12s  %s %s" $i end ---- $cell $cell_type]
    regsub -all {\{|\}} $text "" text

    $win.instances insert end $text
  }
}


proc tim_change_cp {inc} {

  global TIMING_OUT

  incr TIMING_OUT(cp,index) $inc

  if {$TIMING_OUT(cp,index) < 1} {
    set TIMING_OUT(cp,index) 1
  }

  if {$TIMING_OUT(cp,index) > $TIMING_OUT(critical_paths)} {
    set TIMING_OUT(cp,index) $TIMING_OUT(critical_paths)
  }

  # call this
  tim_display_critical_path_instances

  update idletasks

  tim_display_critical_path
}


proc tim_select_critical_path {} {

  global TIMING_OUT max_win TIMING_DATA

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
  wm title $win "$TIMING_DATA(simulator) Timing for $TIMING_DATA(toplevelcell)"

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
		 -command {tim_display_critical_path_instances ifexists} \
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
		 -command {tim_display_critical_path_instances ifexists} \
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
    -command {tim_display_critical_path}
  pack $win.done -in $win.default -padx 1m -pady 1m -ipadx 2m
  pack $win.default -side left -in $win.buttons \
      -padx 4m -ipadx 1m -pady 1m

  button $win.all -text "Display All" -padx 1 -pady 1 \
    -command {tim_display_timing}
  pack $win.all -side left -in $win.buttons \
      -padx 4m -ipadx 1m -pady 1m

  button $win.cpi -text "CP Instances" -padx 1 -pady 1 \
    -command {tim_display_critical_path_instances raise}
  pack $win.cpi -side left -in $win.buttons \
      -padx 4m -ipadx 1m -pady 1m

  button $win.clear -text "Clear Annotations" -padx 1 -pady 1 \
    -command {lay_text -tag timing -clear}
  pack $win.clear -side left -in $win.buttons \
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
  tim_display_critical_path_instances ifexists
}


proc tim_display_critical_path {{-index ""} {this_cell ""}} -doc {
  displays the critical path on the schematic by selecting the 
  wires/instances in the paths and displaying the timing along it.
  code originally by Lee from sue, modified for max.
} {

  global TIMING_DATA TIMING_OUT cur_s cur_c COLORS FONT 

  if {$index == "" } {
    set index $TIMING_OUT(cp,index)
  }

  # clear selection
  sel_clear
  db_flyline -delete

  # delete text annotations
  lay_text -tag timing -clear

  # You can subedit from the timing root cell and see critical path in those
  # cell but if you edit some other cell somewhere, this code will just goof up.
  set timingroot $TIMING_DATA(toplevelcell)
  setl {rootcell inst_path} [lay_path -all]
  if {$rootcell != $timingroot} {
    max_error "Top level cell ($rootcell) differs from cell that was timed ($timingroot)\n"
    return
  }

  set prev_label ""
  set prev_cell ""
  set net_name ""

  # check for special case
  set cells 0
  set text ""

  if {$inst_path != "." && [lay_rootcell] == [lay_editcell]} {
    # editing a subcell, not in place

    set cell [lay_rootcell]

    set prefix [join $inst_path /]/
    set i [string length $prefix]
    set j [expr $i - 1]

  } else {
    set prefix ""
  }

  if {$this_cell != ""} {
    # special case, just select this cell
    if {$prefix != ""} {
      # editing a subcell, not in place
      if {[string range $this_cell 0 $j] == $prefix} {
	set name [string range $this_cell $i end]
	sel_cell -more [cellinfo_name [dbt_find_cell $name]]

      } else {
	# not in this subcell
	warning "Cell $this_cell not in current subedited cell $cell."
      }
    } else {
      sel_cell -more [cellinfo_name [dbt_find_cell $this_cell]]
    }

    return 
  }

  tim_display_cp_message $index

  # walk thru the critical path highliting stuff
  foreach pair $TIMING_OUT(cp,$index) {

    setl {type name value slope} $pair

    if {$prev_cell == $name} {
      # already got this one
      continue
    }

    if {$prefix != ""} {
      # editing a subcell, not in place
      if {[string range $name 0 $j] == $prefix} {
	set name [string range $name $i end]

      } elseif {$type == "net"} {
	# look to see if this net goes into here
	set found 0

	global nl_hierarchy_separator
	set save_nl_hierarchy_separator $nl_hierarchy_separator
	set nl_hierarchy_separator /

	foreach pin [nl_get_net_pins $name] {
	  if {[string range $pin 0 $j] == $prefix} {
	    set name [string range $pin $i end]
	    set found 1
	    break
	  }
	}

	set nl_hierarchy_separator $save_nl_hierarchy_separator

	if {!$found} {
	  continue
	}

      } else {
	# not in this subcell
	continue
      }
    }

    switch $type {
      cell {
	sel_cell -more [cellinfo_name [dbt_find_cell $name]]
	incr cells
	
	if {$prev_label != ""} {
	  # port
	  set label1 $net_name
	  set prev_label ""
	} else {
	  # pin on an instance
	  set label1 [_tim_find_pin_on_instance $prev_cell $net_name $prefix]
	}

	set label2 [_tim_find_pin_on_instance $name $net_name $prefix]

	if {$label1 != ""} {
	  db_flyline -text $text $label1 $label2
	}

	set net_name ""
	set prev_cell $name
      }

      net {
	# select the label, add timing

	if {$slope != ""} {
	  set text "$value\n$slope"
	} else {
	  set text $value
	}

	set net_name $name

	if {[string first "/" $name] == -1} {
	  # It might be a label in the top cell.

	  if {[set label [db_search_labels -no_glob $name]] != ""} {
	    # found one, select it
	    sel_labels -more -text $name
	    set prev_label $name

	    if {$text != ""} {
	      set label [lindex $label 0]
	      lay_text -size 3 -tag timing \
		  [lindex $label 1] [lindex $label 2] $text
	    }
	  }
	}
      }
    }
  }

  if {$prev_label != ""} {
    # ends on a label
    set label1 [_tim_find_pin_on_instance $prev_cell $net_name $prefix]

    db_flyline -text $text $label1 $prev_label
  }

  # TODO: fix
  eval lay_box [db_bbox]
  return

  if {$cells > 0} {
    error "Aborting, no cells in critical."
    return 0
  }

  return 1
}


proc tim_display_timing {} -desc {
  Displays timing on inputs and outputs and on the data inputs of rising edge triggered flops.

  Display timing; code originally by Lee from sue, modified for max.
} {

  global TIMING_OUT TIMING_DATA

  # You can subedit from the timing root cell and see critical path in those
  # cell but if you edit some other cell somewhere, this code will just goof up.
  set timingroot $TIMING_DATA(toplevelcell)
  setl {rootcell inst_path} [lay_path -all]
  if {$rootcell != $timingroot} {
    max_error "Top level cell ($rootcell) differs from cell that was timed ($timingroot)\n"
    return
  }

  # toast existing
  lay_text -tag timing -clear

  if {$inst_path != "." && [lay_rootcell] == [lay_editcell]} {
    # editing a subcell, not in place

    set cell [lay_rootcell]

    set prefix [join $inst_path /]/
    set i [string length $prefix]
    set j [expr $i - 1]

    foreach list $TIMING_OUT($TIMING_DATA(toplevelcell),net_values) {
      setl {name type delay skew} $list
      if {$type == "pin" && [string range $name 0 $j] == $prefix} {
	# add to pin location on instance
	set info [dbt_find_label [string range $name $i end]]
	set name_list [concat [labinfo_path $info] [labinfo_text $info]]

	foreach label [db_search_labels -cell $cell -non_hier -no_glob $name_list] {
	  lay_text -tag timing -align [tim_opposite_orient [lindex $label 5]] \
	      -size 3 [lindex $label 1] [lindex $label 2] "$delay $skew"
	}
      }
    }
    return
  }

  foreach list $TIMING_OUT($TIMING_DATA(toplevelcell),net_values) {
    setl {name type delay skew} $list

    if {$type == "port"} {
      # find label and add
      foreach label [db_search_labels -no_glob $name] {
	# orient opposite as label
	lay_text -tag timing -align [tim_opposite_orient [lindex $label 5]] \
	    -size 3 [lindex $label 1] [lindex $label 2] "$delay $skew"
      }

    } else {
      # add to pin location on instance
      set info [dbt_find_label $name]
      set name_list [concat [labinfo_path $info] [labinfo_text $info]]

      foreach label [db_search_labels -cell $timingroot -non_hier -no_glob $name_list] {
	lay_text -tag timing -align [tim_opposite_orient [lindex $label 5]] \
	    -size 3 [lindex $label 1] [lindex $label 2] "$delay $skew"
      }
    }
  }
}


proc tim_opposite_orient {orient} {

  switch $orient {
    NORTH - n { return SOUTH }
    SOUTH - s { return NORTH }
    WEST - w { return EAST }
    EAST - e { return WEST }
    default { return $orient }
  }
}


proc tim_display_cp_message {index} -desc {
  show the user the critical path output from the STA
} {

  global TIMING_OUT

  if {[use_first TIMING_OUT(cpmessage,display)] == $index} {
    # already displayed this one
    return
  }
  set TIMING_OUT(cpmessage,display) $index

  if {[info exists TIMING_OUT(cp,value,$index)]} {
    regsub -all {\{|\}} $TIMING_OUT(cp,value,$index) "" cpdelay
#    msg_window "selected: critical path $index:  $cpdelay" no_save
    puts "critical path $index:  $cpdelay"
    puts [join [use_first TIMING_OUT(cpmessage,$index)] \n]

  } else {
    puts "No critical paths found."
  }
}



proc tim_write_primetime_files {{mode ""}} {

  global SUFFIX TIMING_DATA

  set dir $TIMING_DATA(work_dir)

  set cell $TIMING_DATA(toplevelcell)

  set TIMING_DATA(cmd_file) $dir/$cell$SUFFIX(primetime_in)

  set TIMING_DATA(out_file) $dir/$cell$SUFFIX(primetime_out)

  # first write the commands out to a file

  # open to write the primetime command file
  if {[catch "open $TIMING_DATA(cmd_file) w" msg]} {
    # error
    max_error -abort "Can not open $TIMING_DATA(cmd_file).  Error: $msg"
    return 69
  }
  set FILE_ID $msg

  set search_path ""
  set link_path "*"
  foreach lib $TIMING_DATA(db_file) {
    set path [file dirname $lib]
    if {[lsearch $search_path $path] == -1} {
      # add to search path
      lappend search_path $path
    }

    set name [file tail $lib]
    if {[lsearch $link_path $lib] == -1} {
      # add to link path
      lappend link_path $name
    } else {
      puts "WARNING, duplicate link_path names $name."
    }
  }

  # add models
  foreach subcell $TIMING_DATA(models) {
    set filename [lindex [cell_info $subcell] 1]

    lappend link_path [file rootname $filename].db
  }

  puts $FILE_ID "set search_path \"$search_path\""
  puts $FILE_ID "set link_path \"$link_path\""

  if {$TIMING_DATA(flat)} {
    # flat
    puts $FILE_ID "read_verilog $TIMING_DATA(verilog_file)"

    puts $FILE_ID "link_design $cell"
  
    # if the suffix isn't rspf or dspf, assume a capacitance only file
    set suffix [string tolower [file extension $TIMING_DATA(spf_file)]]
    if {[string first spf $suffix] != -1} {
      # an rspf or dspf file
      puts $FILE_ID "read_parasitics $TIMING_DATA(spf_file)"
      # and fix it up
      puts $FILE_ID "complete_net_parasitics -complete_with zero"
    } elseif {[string first sdf $suffix] != -1} {
      # an sdf file
      puts $FILE_ID "read_sdf $TIMING_DATA(spf_file)"
    } else {
      # assume it's just a plain old vanilla cap file
      puts $FILE_ID "source $TIMING_DATA(spf_file)"
    }

  } else {
    # hierarchical
    set topmod [fplan_unfix_name $cell]

    # This file is a temp verilog file generated previously.
    puts $FILE_ID "read_verilog $TIMING_DATA(verilog_file)"

    puts $FILE_ID "link_design $topmod"

    puts $FILE_ID "read_parasitics -quiet $TIMING_DATA(spf_file)"
#    puts $FILE_ID "complete_net_parasitics -complete_with zero"

    # Make primetime suck in a dspf file for each instance.
    foreach one $TIMING_DATA(hier_names) {
      foreach cell_info [db_instances -id $one -cell $cell] {
	struct max_cell c $cell_info
	if {[fplan_cell_info -is_hier ${c.def}]} {
	  set modi [fplan_unfix_name ${c.id}]
	  set mod [fplan_unfix_name ${c.def}]

	  puts $FILE_ID "read_parasitics -quiet -increment -path $modi $dir/$mod$SUFFIX(dspf)"
#	puts $FILE_ID "complete_net_parasitics -complete_with zero"
#	puts $FILE_ID "report_annotated_parasitics -check -list_not_annotated"
	}
      }
    }

    puts $FILE_ID "complete_net_parasitics -complete_with zero"
  }

  # tell primetime to save timing values for probing nets
  # need to turn this on before update_timing or first report_timing
   puts $FILE_ID "set timing_save_pin_arrival_and_slack true"

  set clks ""
  set net ""
  set suggested_clks [use_first TIMING_DATA(clk_names)]

  # Sue searches to see if the clk names actually exist.
  foreach lab_info [db_search_labels -non_hier] {
    struct max_label l $lab_info
    if {${l.kind} != "input"} {continue}

    set net ${l.text}  ;# TODO: this is not necessarily true.
    if {[lsearch -exact $suggested_clks $net] != -1 && \
	    [lsearch -exact $clks $net] == -1} {
      # this is a good clock input, use it
      lappend clks $net
    }
  }

  setl {period clk_fall} $TIMING_DATA(clk_period)
  set period [parse_pp_number $period]
  if {$clk_fall == ""} {
    # assume falling edge is mid way into period
    set clk_fall [expr $period / 2.0]
  }

  # scale to primetime units from db file
  set mult [expr 1.0 / [parse_pp_number $TIMING_DATA(db_time_units)]]

  if {$clks == ""} {
    # no clocks, must be combinational
    if {$net == ""} {
      # no inputs
      error "Aborting, no inputs to schematic \"$cur_s\"."
      return 69
    }

    msg "Warning:  No input matches clock names, assuming combinational logic with no clocks.\n"

    set TIMING_DATA(timing_kind) combinational

    set clock $TIMING_DATA(wave_name)

    puts $FILE_ID "create_clock -name $clock -period [expr $mult * $period] -waveform \{0 [expr $mult * $clk_fall]\}"

  } else {

    set TIMING_DATA(timing_kind) sequential

    puts $FILE_ID "create_clock -period [expr $mult * $period] -waveform \{0 [expr $mult * $clk_fall]\} $clks"

    foreach clk $clks {
      set trace($clk) 1
    }

    set clock [lindex $clks 0]
  }

  foreach lab_info [db_search_labels -non_hier] {
    struct max_label l $lab_info
    if {${l.kind} != "input"} {continue}

    set net ${l.text}  ;# TODO: this is not necessarily true.
    if {![info exists trace($net)]} {

      if {$clks != ""} {
	# sequential
	set actual [fplan_db_pin getprop ${l.text} ext_actual]
	set budget [string trim [fplan_db_pin getprop ${l.text} ext_budget] <>]
	set arrival [use_first actual budget TIMING_DATA(ext_input_budget)]

	set arrival [expr [parse_pp_number $arrival] / \
			 [parse_pp_number $TIMING_DATA(db_time_units)]]

      } else {
	set arrival 0
      }

      puts $FILE_ID "set_input_delay -clock $clock $arrival $net"
      set trace($net) 1
    }
  }

  # if there is a default, use the default driver cell
  # TODO: can't turn off driver cell, if set to null, takes default
  if {[use_first TIMING_DATA(ext_driver)] != ""} {
    setl {cell port} $TIMING_DATA(ext_driver)
    
    if {$port == ""} {
      # use the port name "out" for the output port if not specified
      set port out
    }

    puts $FILE_ID "set_driving_cell -lib_cell $cell -from_pin $port \[all_inputs\]"
  } else {
    # use a constant slope
    set input_transition \
	[expr [parse_pp_number $TIMING_DATA(input_transition)] * $mult]
    puts $FILE_ID "set_input_transition $input_transition \[all_inputs\]"
  }

  # put external delay and capacitance on output nodes
  foreach lab_info [db_search_labels -non_hier] {
    struct max_label l $lab_info
    if {${l.kind} != "output"} {continue}

    set net ${l.text}  ;# TODO: this is not necessarily true.
    if {![info exists trace($net)]} {

      if {$clks != ""} {
	# sequential
	set actual [fplan_db_pin getprop ${l.text} ext_actual]
	set budget [string trim [fplan_db_pin getprop ${l.text} ext_budget] <>]
	set departure [use_first actual budget TIMING_DATA(ext_output_budget)]

	set departure [expr [parse_pp_number $departure] / \
			   [parse_pp_number $TIMING_DATA(db_time_units)]]

      } else {
	set departure 0
      }
    
      puts $FILE_ID "set_output_delay -clock $clock $departure $net"

      set cap [string trim [fplan_db_pin getprop ${l.text} ext_cap] <>]
      set ext_cap [use_first cap TIMING_DATA(ext_cap)]

      # convert number to correct units
      set ext_cap [expr [parse_pp_number $ext_cap] / \
		       [parse_pp_number $TIMING_DATA(db_cap_units)]]
      puts $FILE_ID "set_capacitance $ext_cap $net"

      set trace($net) 1
    }
  }

  # this is the simplest
#  puts $FILE_ID "idealclocks yes"

  # read in the constraint file if it exists
  if {[file readable $TIMING_DATA(constraint_file)]} {
    puts "Including constraint file: $TIMING_DATA(constraint_file)"
    puts $FILE_ID "source $TIMING_DATA(constraint_file)"
  } else {
    puts "Note: No constraint file: $TIMING_DATA(constraint_file)"
  }

  # to highlite the critical path
  puts $FILE_ID "report_timing -nosplit -nets -input_pins -transition_time -capacitance -significant_digits 3 -max_paths $TIMING_DATA(max_paths)"
  
  # comments needed by reader
  puts $FILE_ID "echo *DONE*"

#    puts $FILE_ID "findmincycletime"
    # comments needed by reader
#    puts $FILE_ID "\# done"
#    puts $FILE_ID "\# done"

  # save all inputs/outputs, inputs to flops

  puts $FILE_ID "foreach_in_collection n \[get_nets -of_objects \[get_ports *\]\] \{"
#  puts $FILE_ID "foreach_in_collection n \[get_nets -of_objects \[add_to_collection \[all_inputs\] \[all_outputs\]\]\] \{"
  puts $FILE_ID {  set p [index_collection [get_pins -of_objects $n] 0]}
  puts $FILE_ID {  echo "TIMING: [get_object_name [get_nets -of_objects $p]] port [get_attribute $p max_rise_arrival] [get_attribute $p max_fall_arrival] [get_attribute $p actual_rise_transition_max] [get_attribute $p actual_fall_transition_max] [get_attribute $p max_rise_slack] [get_attribute $p max_fall_slack]"}
  puts $FILE_ID "\}"

  puts $FILE_ID "foreach n \{[concat $TIMING_DATA(hier_names) $TIMING_DATA(models)]\} \{"
  puts $FILE_ID "  foreach_in_collection p \[get_pins -of_objects \$n\] \{"
  puts $FILE_ID {    echo "TIMING: [get_attribute $p full_name] pin [get_attribute $p max_rise_arrival] [get_attribute $p max_fall_arrival] [get_attribute $p actual_rise_transition_max] [get_attribute $p actual_fall_transition_max] [get_attribute $p max_rise_slack] [get_attribute $p max_fall_slack]"}
  puts $FILE_ID "  \}"
  puts $FILE_ID "\}"

  puts $FILE_ID "foreach_in_collection p \[get_pins -of_objects \[all_registers\] -filter \"is_rise_edge_triggered_data_pin == true\"\] \{"
  puts $FILE_ID {  echo "TIMING: [get_object_name $p] [get_object_name [get_nets -of_objects $p]] [get_attribute $p max_rise_arrival] [get_attribute $p max_fall_arrival] [get_attribute $p actual_rise_transition_max] [get_attribute $p actual_fall_transition_max]"}
  puts $FILE_ID "\}"

#    puts $FILE_ID "findclockdelays"

  # show slow nodes
  puts $FILE_ID "set_max_transition [expr [parse_pp_number $TIMING_DATA(max_transition)] / [parse_pp_number $TIMING_DATA(db_time_units)]] $cell"
  puts $FILE_ID "report_constraint -all_violators -max_transition -significant_digits 3 > $dir/$cell$SUFFIX(slow_nodes)"

  puts $FILE_ID "quit"

  # close the tempfile
  close $FILE_ID
}


proc tim_run_primetime {} {
  global TIMING_DATA

  set status [tim_primetime_exec $TIMING_DATA(cmd_file) $TIMING_DATA(out_file) $TIMING_DATA(see_output)]

  if {$status > 0} {
    puts "Aborting, primetime return status is $status"

    catch "exec cat $TIMING_DATA(out_file)" msg
    puts $msg
    
    return $status
  }

  # primetime does not seem to return a meaningful exit status
  if {[catch "exec grep {Thank you for using} $TIMING_DATA(out_file)" result] || $result == ""} {
    # primetime choked, show user entire output file

    catch "exec cat $TIMING_DATA(out_file)" msg
    puts $msg

    puts "Aborted due to primetime error."
    return 69
  }

  if {[catch "exec grep {was successfully linked} $TIMING_DATA(out_file)" result] || $result == ""} {
    # primetime choked, show user entire output file

    catch "exec cat $TIMING_DATA(out_file)" msg
    puts $msg

    puts "Aborted due to primetime error."
    return 69
  }

  # return OK exit status
  return 0
}


# create the script file to run primetime (required because exec in tcl
# is broken) and then run it.  Return the pearl exit status.

proc tim_primetime_exec {cmd_file out_file {see_output 0}} {

  global TIMING_DATA

  puts "\nRunning Primetime ..."

  if {$TIMING_DATA(primetime_setup) == ""} {
    set setup ""
  } else {
    set setup "$TIMING_DATA(primetime_setup) ; "
  }

  if {$see_output == 0} {
    # direct all output to output file
    if {[catch "exec csh -c \"$setup$TIMING_DATA(primetime,command) -f $cmd_file >&! $out_file\"" msg]} {
      puts $msg
      return 69
    }

  } else {
    # direct all output to screen and output file
    if {[catch "exec csh -c \"$setup$TIMING_DATA(primetime,command) -f $cmd_file |& tee $out_file >&! [exec tty]\"" msg]} {
      puts $msg
      return 69
    }
  }

  # show the user any error messages except bogus ones
  if {![catch "exec grep -i error: $out_file | grep -v collection" msg]} {
    puts $msg
  }

  puts "Primetime completed.\n"

  return 0
}


proc tim_parse_primetime_output {} {

  global TIMING_OUT TIMING_DATA

  # scale from db units
  set mult [parse_pp_number $TIMING_DATA(db_time_units)]

  set primetime_out_file $TIMING_DATA(out_file)
  set FILE_ID [open $primetime_out_file r]
     
    # parse the critical paths

    set TIMING_OUT(critical_paths) 0

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
	incr TIMING_OUT(critical_paths)
	set TIMING_OUT(cpmessage,$TIMING_OUT(critical_paths)) ""
	set TIMING_OUT(cp,$TIMING_OUT(critical_paths)) ""

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
	  lappend TIMING_OUT(cpmessage,$TIMING_OUT(critical_paths)) $line

	  if {[string first "*DONE*" $line] != -1} {
	    # shouldn't have gotten here
	    set error 1
	    # we're done
	    break
	  }

	  if {[string first "slack " $line] != -1} {
	    # last line
	    set time [lindex $line [expr [llength $line] - 1]]
	    break
	  }

	  if {$done} {
	    continue
	  }

	  # I don't know what these & are for -- lose them
	  regsub -all & $line "" line

	  if {[string first " clock " $line] != -1} {
	    # from the clock (register input)
	    set clock [lindex $line 1]
	    set clks [use_first TIMING_DATA(clk_names)]
	    if {[lsearch $clks $clock] != -1} {
	      # found the clock input
	      set net $clock
	      set time [pp_number [expr $mult * [lindex $line 6]]]
	      lappend TIMING_OUT(cp,$TIMING_OUT(critical_paths)) \
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

	    lappend TIMING_OUT(cp,$TIMING_OUT(critical_paths)) \
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

		lappend TIMING_OUT(cp,$TIMING_OUT(critical_paths)) \
		    "net $net $time $trans"

		lappend TIMING_OUT(cp,$TIMING_OUT(critical_paths)) \
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

	if {$TIMING_DATA(timing_kind) == "sequential"} {
	  set TIMING_OUT(cp,value,$TIMING_OUT(critical_paths)) \
	      "[pp_number [expr $mult * $time]] Slack ($start -> $end)"
	} else {
	  set TIMING_OUT(cp,value,$TIMING_OUT(critical_paths)) \
	      "$out_time ($start -> $end)"
	}
      }
    }


  # remove any critical paths that don't exist.
  # not exactly right since a middle one could be broken
  while {![info exists TIMING_OUT(cp,value,$TIMING_OUT(critical_paths))] && \
	     $TIMING_OUT(critical_paths) > 0} {
    incr TIMING_OUT(critical_paths) -1
  }

  # read term values
  set cell $TIMING_DATA(toplevelcell)
  set TIMING_OUT($cell,net_values) ""

  while {[gets $FILE_ID line] >= 0} {
    if {[string range $line 0 6] != "TIMING:"} {
      continue
    }

    set slack ""

    # timing line
    switch [llength $line] {
      6 {
	# input/output port
	setl {tmp name rise fall rise_slew fall_slew} $line
	set type port
      }

      7 {
	# data input of flop
	setl {tmp name net rise fall rise_slew fall_slew} $line
	set type pin
      }

      8 {
	# input/output port -- not used
	setl {tmp name rise fall rise_slew fall_slew rise_slack fall_slack} $line

	if {![catch {expr $rise_slack + $fall_slack}]} {
	  set slack [tim_convert_to_pp [max $rise_slack $fall_slack]]
	}
	set type port
      }

      9 {
	# input/output port
	setl {tmp name type rise fall rise_slew fall_slew rise_slack fall_slack} $line

	if {![catch {expr $rise_slack + $fall_slack}]} {
	  set slack [tim_convert_to_pp [max $rise_slack $fall_slack]]
	}
      }
    }

    if {[catch {expr $rise}] || [catch {expr $fall}]} {
      # skip these, not a good value
      continue
    }

    set slew ""

    if {$rise > $fall} {
      set delay [tim_convert_to_pp $rise]

      if {![catch {expr $rise_slew}]} {
	set slew "^[tim_convert_to_pp $rise_slew]"
      } 
    } else {
      set delay [tim_convert_to_pp $fall]

      if {![catch {expr $fall_slew}]} {
	set slew "v[tim_convert_to_pp $fall_slew]"
      } 
    }

    lappend TIMING_OUT($cell,net_values) "$name $type $delay $slew $slack"
  }

  # close the file
  close $FILE_ID
}


proc tim_convert_to_pp {number} -desc {
  mostly for converting primetime to readable
} {

  global TIMING_DATA

  if {$TIMING_DATA(simulator) == "primetime"} {
    return [pp_number [format "%.4g" [expr [parse_pp_number $TIMING_DATA(db_time_units)] * \
					$number]]]
  }

  return [format "%.4g" $number]
}


proc _tim_find_pin_on_instance {name net {prefix ""}} -desc {
  Returns the pin on the instance that is connected to this net.

  Note: could be connected to multiple -- ignored.
} {

  global nl_hierarchy_separator nl_current_design

  set save_nl_hierarchy_separator $nl_hierarchy_separator
  set nl_hierarchy_separator /

  # set to subcell if one
  set save_design $nl_current_design
  if {$prefix != ""} {
    set nl_current_design [lay_rootcell]
  }

  if {[catch {nl_get_cell_reference $name} ref]} {
    # error
    set nl_hierarchy_separator $save_nl_hierarchy_separator
    set nl_current_design $save_design
    return ""
  }

  if {![catch {nl_get_net_pins -recursive -noassign $net} pins]} {
    foreach pin $pins {
      if {[nl_get_pin_owner $pin] == "$prefix$name"} {
	# found it

	# convert with old hier
	set pin_name [format "%s" $pin]
	set nl_hierarchy_separator $save_nl_hierarchy_separator
	set nl_current_design $save_design

	if {$prefix != ""} {
	  regsub "^$prefix" $pin_name "" pin_name
	}

	set info [dbt_find_label $pin_name]
	return [concat [labinfo_path $info] [labinfo_text $info]]
      }
    }
  }

  set nl_hierarchy_separator $save_nl_hierarchy_separator
  set nl_current_design $save_design

  # not valid, return {*center*}
  return [concat [cellinfo_name [dbt_find_cell $name]] {{{*center*}}}]
}


proc tim_backannotate_timing {} -desc {
  adds timing numbers back into port props, visible in T menu
} {

  global TIMING_OUT TIMING_DATA

  # You can subedit from the timing root cell and see critical path in those
  # cell but if you edit some other cell somewhere, this code will just goof up.
  set timingroot $TIMING_DATA(toplevelcell)
  setl {rootcell inst_path} [lay_path -all]
  if {$rootcell != $timingroot} {
    max_error "Top level cell ($rootcell) differs from cell that was timed ($timingroot)\n"
    return
  }

  set cycle_time [parse_pp_number $TIMING_DATA(clk_period)]

  foreach list $TIMING_OUT($TIMING_DATA(toplevelcell),net_values) {
    setl {name type delay skew slack} $list

    if {$slack == ""} {
      # ignore if no slack
      continue
    }

    if {$type == "port"} {
      # add to top level label props

      # different for input vs. output
      set dir [lindex [lindex [db_search_labels -no_glob $name] 0] 9]

      if {$dir != "output"} {
	set ext_delay $delay
	set int_delay [pp_number [expr $cycle_time - [parse_pp_number $delay] \
				      - [parse_pp_number $slack]]]

      } else {
	# output delay must be computed from cycle time, delay, and slack
	set ext_delay [pp_number [expr $cycle_time - [parse_pp_number $delay] \
				      - [parse_pp_number $slack]]]
	set int_delay $delay
      }

      fplan_db_pin setprop $name ext_actual $ext_delay
      fplan_db_pin setprop $name slack $slack

      # add to internal delays for modeling
      fplan_db_pin setprop $name int_actual $int_delay

    } else {
      # pins on subcells
      # NOTE: requires that subcells are unique

      # Remember -- only for cells one level down
      set cell_id [file dirname $name]
      set pin [file tail $name]

      set cell_info [db_instances -id $cell_id]
      if {[llength $cell_info] == 0} {
	# hmmm
	continue
      }

      # get defname
      set def [lindex [lindex $cell_info 0] 1]

      # different for input vs. output
      set dir [lindex [lindex [db_search_labels -cell $def -non_hier -no_glob $pin] 0] 9]

      if {$dir != "output"} {
	set ext_delay $delay
	set int_delay [pp_number [expr $cycle_time - [parse_pp_number $delay] \
				      - [parse_pp_number $slack]]]

      } else {
	# output delay must be computed from cycle time, delay, and slack
	set ext_delay [pp_number [expr $cycle_time - [parse_pp_number $delay] \
					- [parse_pp_number $slack]]]
	set int_delay $delay
      }

      fplan_db_pin -cell $def setprop $pin ext_actual $ext_delay
      fplan_db_pin -cell $def setprop $pin slack $slack

      # add to internal delays for modeling
      fplan_db_pin -cell $def setprop $pin int_actual $int_delay
    }
  }

  puts "Port/pin timing updated."

  # show changes in timing in "T" label menu
  label_lbox
}
