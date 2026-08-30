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

#########################################
# called from dpc_it in timing.tcl

# backwards compatibility until timing.tcl gets updated
proc setup_speedy {{mode {}}} {
    sy_setup_speedy $mode
}


#############################################################
#############################################################
#############################################################

proc sy_setup_speedy {{mode ""}} {

	global NETLIST SUFFIX cur_s cur_c scale DPC_TIMING SUE_TIMING_DATA HIERARCHY
	global DPC_FROM_DEF DPC_SIZE

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
	if {$mode == "timing"} {
		# write nets that are in a subcell
		write_all_nets [dpc_cell_name]
		return
	}

	busy
	puts "Setting up Speedy ..."


	set save_dir [pwd]
	cd $NETLIST(dir)

	# this is return info
	set out_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_out)

	# cell libraries
	set search_path ""
	set link_path "*"
	foreach dbfilename $DPC_TIMING(db_file) {
		set len [string length $dbfilename]
		set len [expr $len - 3]
		set dotdb [string range $dbfilename $len end]
		if {$dotdb != ".db"} {
			puts "ERROR: \"$dbfilename\" from DPC_TIMING(db_file) doesn't have suffix \".db\"; it will be ignored"
			continue
		}			
		set fnroot [string range $dbfilename 0 $len]
		set libfilename ${fnroot}db
		if {[file readable $libfilename] != 1} {
			puts "ERROR: \"$libfilename\" derived from DPC_TIMING(db_file) is not readable; it will be ignored"
			continue
		}
			
		speedy read_libfile $libfilename
	}

	# load nl
	set nl_bus_naming_style "%s_%d"
	foreach cell [array names DPC_FROM_DEF] {
		set cellfilename $DPC_SIZE($cell,dir)/$cell$SUFFIX(dpc)
		nl_read_verilog $cellfilename
	}
	# ... read Big Daddy
	# compute the filename for the verilog file
	upvar #0 SUE_$NETLIST(root) data
	set filename "$NETLIST(dir)$NETLIST(root)$SUFFIX(dpc)"
	set filename $SUE_TIMING_DATA(verilog_file)
	nl_read_verilog $filename"
	# complete nl initialization
	nl_link -silent
	nl_create_idesign

	# load speedy design from nl
	speedy_set_tcl_obj "nl_current_design" $nl_current_design	
	speedy load_design_from_nl


speedy set net_model ignore_nets
#
# .... we can do better, but first things first.....
#
#	# if the suffix isn't rspf or dspf, assume a capacitance only file
#	set suffix [string tolower [file extension $SUE_TIMING_DATA(parasitic_file)]]
#	if {[string first spf $suffix] != -1} {
#		# an rspf or dspf file
#		puts $FILE_ID "read_parasitics $SUE_TIMING_DATA(parasitic_file)"
#		# and fix it up
#		puts $FILE_ID "complete_net_parasitics -complete_with zero"
#	} elseif {[string first sdf $suffix] != -1} {
#		# an sdf file
#		puts $FILE_ID "read_sdf $SUE_TIMING_DATA(parasitic_file)"
#	} else {
#		# assume it's just a plain old vanilla cap file
#		puts $FILE_ID "source $SUE_TIMING_DATA(parasitic_file)"
#	}


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


	# identify the clock net(s) to speedy
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
	foreach clk $clks {
		speedy flag_net_as_clock $clk
	}

	setl {period clk_fall} $SUE_TIMING_DATA(clk_period)
	set period [parse_pp_number [convert_if_no_units $period p]]
	speedy set clock_period $period

#	if {$clk_fall == ""} {
#		# assume falling edge is mid way into period
#		set clk_fall [expr $period/2]
#	}


#	# scale to speedy units from db file
#	set mult [expr 1.0 / [parse_pp_number $DPC_TIMING(db_time_units)]]


	if {$clks == ""} {
		# no clocks, must be combinational
		if {$net == ""} {
			# no inputs
			sue_error "Aborting, no inputs to schematic \"$cur_s\"."
			sue_error flush

			ready
			return 69
		}

		puts "DPC INFO:	No input matches clock names, assuming combinational logic with no clocks."
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


	## input delay
	foreach id [$cur_c find withtag icon_input] {
		set net [find_timing_net_name [get_intersect_tag inst$id term]]
		foreach bit [cbus_expand $net] {
			if {![info exists trace($bit)]} {

				# puts $FILE_ID "set_input_delay -clock $clock $arrival $bit"
				speedy set_input_delay $bit $arrival
			
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
		set input_transition [expr [parse_pp_number $SUE_TIMING_DATA(input_transition)] * $mult]
		# puts $FILE_ID "set_input_transition $input_transition \[all_inputs\]"
		speedy set_input_slope ALL $input_transition
	}

	# put capacitance on output nodes
	set out_cap [expr [parse_pp_number $DPC_TIMING(out_cap)] / [parse_pp_number $DPC_TIMING(db_cap_units)]]
			 
	foreach id [$cur_c find withtag icon_output] {
		set net [find_timing_net_name [get_intersect_tag inst$id term]]
		foreach bit [cbus_expand $net] {
			regsub -all {\$} $bit \\\\$ bit
			if {![info exists trace($bit)]} {
##				puts $FILE_ID "set_capacitance $out_cap $bit"
##				puts $FILE_ID "set_output_delay -clock $clock $departure $bit"
puts "set_capacitance $out_cap $bit"
puts "set_output_delay -clock $clock $departure $bit"
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
#	puts $FILE_ID "idealclocks yes"

	# read in the constraint file if it exists
	if {[file readable $SUE_TIMING_DATA(constraint_file)]} {
		puts "Including constraint file: $SUE_TIMING_DATA(constraint_file)"
		puts $FILE_ID "source $SUE_TIMING_DATA(constraint_file)"
	} else {
		puts "Note: No constraint file: $SUE_TIMING_DATA(constraint_file)"
	}

# 	if {$mode == "timing"} {
# 
# 	} else {
# 
# 		# to highlite the critical path
# 		puts $FILE_ID "report_timing -nosplit -nets -input_pins -transition_time -capacitance -significant_digits 3 -max_paths $SUE_TIMING_DATA(max_paths)"
# 
# 		# comments needed by reader
# 		puts $FILE_ID "echo *DONE*"
# 
# #		puts $FILE_ID "findmincycletime"
# 		# comments needed by reader
# #		puts $FILE_ID "\# done"
# #		puts $FILE_ID "\# done"
# 
# 		# NEW
# 		# get all of the pin/net timing values through the hierarchy
# 		puts $FILE_ID "foreach_in_collection p \[get_pins * -hier\] \{"
# 		puts $FILE_ID {	echo "TIMING: [get_object_name $p] [get_object_name [get_nets -of_objects $p]] [get_attribute $p max_rise_arrival] [get_attribute $p max_fall_arrival]"}
# 		puts $FILE_ID "\}"
# 
# 		# save terminal data for this nell
# 		write_all_nets
# 
# #		puts $FILE_ID "findclockdelays"
# 
# 		# show slow nodes
# 		puts $FILE_ID "set_max_transition [expr [parse_pp_number $SUE_TIMING_DATA(max_transition)] / [parse_pp_number $DPC_TIMING(db_time_units)]] $NETLIST(root)"
# 		puts $FILE_ID "report_constraint -all_violators -max_transition -significant_digits 3 > $NETLIST(dir)$NETLIST(root)$SUFFIX(slow_nodes)"
# 	}
# 

	if {$status > 0} {
		puts "Aborting, speedy return status is $status"

		catch "exec cat $out_file" msg
		puts $msg

		ready
		return $status
	}

	# speedy does not seem to return a meaningful exit status
	if {[catch "exec grep {Thank you for using} $out_file" result] || $result == ""} {
		# speedy choked, show user entire output file

		catch "exec cat $out_file" msg
		puts $msg

		puts "DPC aborted due to speedy error."
		ready
		return 69
	}

	if {[catch "exec grep {was successfully linked} $out_file" result] || $result == ""} {
		# speedy choked, show user entire output file

		catch "exec cat $out_file" msg
		puts $msg

		puts "DPC aborted due to speedy error."

		ready
		return 69
	}

	parse_speedy_output $out_file $mode

	# now delete the tmp files
#	exec rm -f $cmd_file

	# return to calling directory
	cd $save_dir

	ready

	# return OK exit status
	return 0
}



proc parse_speedy_output {out_file {mode ""}} {

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
				# duplicate name, must be hierarchy.	Get one iwth least /
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
#			puts "WARNING: no timing for net $net ($pin)"
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


#############################################################
#############################################################
#############################################################

proc old_sy_setup_speedy {{mode ""}} {
    global nl_current_design

    global NETLIST SUFFIX cur_s cur_c scale DPC_TIMING HIERARCHY DPC
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
        puts "spice mode is bad for speedy dpc"
        return 69
    }

    if {$mode == "timing"} {
        # write nets that are in a subcell
        write_all_nets [dpc_cell_name]

        return
    }

    busy

    speedy flag_net_as_clock clk
    puts "setting \"clk\" as the clock net...\n"
    puts "...add others using \"speedy flag_net_as_clock <netname>\"

    #
    # do net delay or not?
    #
    if {$DPC(dspf) == 1} {
	speedy set use_rc_net_delay true
    } else {
	speedy set use_rc_net_delay false
    }

    #
    # open (create) speedy timing command file
    #
    set cmd_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_in)
    if {[catch "open $cmd_file w" msg]} {
        # error
        puts "DPC TIMING ERROR: $msg"
        return 69
    }
    set FILE_ID $msg

    #
    # delay for input pins
    #
    # set f1 $DPC_TIMING(arrival_time)
    # puts $FILE_ID "arrival * clk ^ $f1 $f1 $f1 $f1"
        

    #
    # slope for input pins
    #
    set f1 $DPC_TIMING(input_transition)
    puts $FILE_ID "inputslew * $f1 $f1 $f1 $f1"


    #
    # put capacitance on output nodes
    #
    foreach id [$cur_c find withtag icon_output] {
            # find the net that is attached to this term
            set net [find_timing_net_name [get_intersect_tag term inst$id]]
            if {![info exists trace($net)]} {
                    puts $FILE_ID "setnodecapacitance $net +$DPC_TIMING(out_cap)"
            }
    }

    #
    # how many long paths to display?
    #
    puts $FILE_ID "setmaxpossibilities $DPC_TIMING(paths)"

    #
    # this does some necessary linking inside sue
    #
    write_all_nets


    # 
    # ... off we go!
    #
    close $FILE_ID

    set in_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_in)
    set constraint_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_constraint)
    set out_file $NETLIST(dir)$NETLIST(root)$SUFFIX(timing_out)
    set slow_nodes_file $NETLIST(dir)$NETLIST(root)$SUFFIX(slow_nodes)

    set fix_file $NETLIST(dir)$NETLIST(root).fixfile

    speedy read_timing_in_file $in_file

    if {[file readable $constraint_file]} {
        speedy read_timing_in_file $constraint_file
    }
    if {[file readable $fix_file]} {
        speedy read_fixfile $fix_file
    }

    speedy global_timing

    speedy write_timing_out_file $out_file
    speedy write_slow_nodes_file $slow_nodes_file $DPC_TIMING(max_transition) 

    parse_pearl_output $out_file $mode

    ready

    # return OK exit status
    puts "....end setup_speedy..."
    return 0
}
