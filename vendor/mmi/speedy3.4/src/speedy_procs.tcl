###############################################################

# menus

menu_add -menu local -label "Speedy Resize" -command speedy_resize -position 10 \
    -help "Speedy tries to optimize cell sizes, prints results in console window."

proc speedy_resize {} {
    speedy resize
}


menu_add -menu local -label "Annotate Resizes" -command annotate_resizes -position 10 \
    -help "Annotate the display with result of previous Speedy Resize command; DON'T alter the design in Sue."

proc annotate_resizes {} {
    global annotate_or_replace
    set annotate_or_replace annotate

    set saved_current_cell [api_current_cell]
    source resizes.tcl
    api_goto_cell $saved_current_cell

    puts "sue>"
}

menu_add -menu local -label "Replace Resizes" -command replace_resizes -position 10 \
    -help "Load the result of previous Speedy Resize command; alter the design in Sue."

proc replace_resizes {} {
    global annotate_or_replace
    set annotate_or_replace replace

    set saved_current_cell [api_current_cell]
    source resizes.tcl
    api_goto_cell $saved_current_cell

    puts "sue>"
}

menu_add -menu local -label "Find Unresizeable Cells" -command find_unresizeable_cells -position 10 \
    -help "Walk the tree of the current design to find generators that contain basic cells.  Output is written to file <cell-name>.fixfile, where it will prevent Speedy Resize command from tinkering with these generators."

menu_add -menu local -label "Set Speedy Variables" -command speedy_variables_popup -position 10 \
    -help "Make a popup to display current values of various speedy variables; user can modify."

menu_add -menu local -label "Recommend Target Slope" -command recommend_target_slope -position 10 \
    -help "Try various target slopes in current design; recommend the one with the least delay averaged over 50 longest paths"

menu_add -menu local -label "Try Buffer Insertion" -command try_buffer_insertion -position 10 \
    -help "Try inserting a buffer at slow nodes; print net name if there's an improvement. Don't preserve the change in Speedy or Sue database"

proc try_buffer_insertion {} {
    speedy try_buffer_insertion
    puts "sue>"
}


###############################################################


# generalized user interface procedure... 
# command line interface to speedy functions
# "cmd" can be anything listed in "do_something()" in speedy_commands.cc

set speedy_is_initialized false

proc speedy { {cmd ""} {arg1 ""} {arg2 ""} {arg3 ""} {arg4 ""} } {
    global	speedy_is_initialized

    if {$speedy_is_initialized == "false"} {
	sue_error "speedy is not initialized"
	sue_error flush
	return 0	
    }

    puts "speeeeedy! $cmd $arg1 $arg2 $arg3 $arg4"
    set result [speedy_cmd $cmd $arg1 $arg2 $arg3 $arg4]

    if {$result != ""} {
	sue_error "SPEEDY: command failed: $result.... $cmd $arg1 $arg2 $arg3 $arg4"
	sue_error flush
	return 0
    }
}


###############################################################

# set variables
set speedy_vars ""

proc speedy_variables_popup {} {
    global speedy_vars

    if {![speedy get_speedy_vars_to_tcl]} {
	return 0
    }

    set old_target_slope [lindex $speedy_vars 0]
    set target_slope $old_target_slope

    set title "Speedy Variables"
    set message "Speedy Variables"

    set prop_list ""
    lappend prop_list [list "target slope" target_slope -entry -help \
			 "speedy resize command will begin by trying to make ouput slopes as close to this as possible."]

    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
        # cancelled
        return ""
    }

    if {$target_slope != $old_target_slope} {
	speedy set target_slope $target_slope
    }
}

set recommended_target_slope ""

proc recommend_target_slope {} {
    global speedy_vars
    global recommended_target_slope
    set accept_recommended 1

    if {![speedy get_speedy_vars_to_tcl]} {
	return 0
    }
    set old_target_slope [lindex $speedy_vars 0]

    speedy select_target_slope
	
    set title "Recommend Target Slope"
    set message "current target slope: $old_target_slope\
recommended target slope: $recommended_target_slope"

    set prop_list ""
    lappend prop_list [list "accept recommended?" accept_recommended -binary -help \
			 "speedy resize command will begin by trying to make ouput slopes as close to this as possible."]

    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
        # cancelled
        return ""
    }

    if {$accept_recommended == 1} {
	speedy set target_slope $recommended_target_slope
    }
}


############################################################################

# resizing

# call to "speedy resize" from menu or from command line generates
# resizes.tcl file.  
# call to "speedy annotate_resizes" or "speedy replace_resizes"
# reads the file, generating a stream of calls to "resize", which 
# does annotate or replace, whichever.

# command sourced from resize.tcl
proc load_resize {{arg_cellname ""} {arg_netlist_name ""} 
			      {arg_new_size ""}} {

    global cur_s

    global annotate_or_replace
    puts "load_resize $annotate_or_replace $arg_cellname $arg_netlist_name $arg_new_size"

    if {$arg_cellname != [api_current_cell]} {
	api_goto_cell $arg_cellname
    }

    api_select $arg_netlist_name
    set instance [api_instances selected]
    set type [get_assoc type [api_get_data $instance]]

    if {$annotate_or_replace == "replace"} {

	upvar #0 SUE_$cur_s data

	if {$data(generator)} {
	    puts "load resize: this is a generator: modifications ignored."
	    return
	}


        if {[string range $type end end] == "_"} {
            # deMorgan generators
            set type [string range $type 0 [expr [string len $type] - 3]]
            set typesize "${type}${arg_new_size}_"
            generate $type $typesize -Size $arg_new_size
            api_replace_instances $instance $typesize
    
        } else {
            #  vanillla case
            set type [string range $type 0 [expr [string len $type] - 2]]
            set typesize "${type}${arg_new_size}"
    
            # puts "generate $type $typesize -Size $arg_new_size"
            # puts "api_replace_instances $instance $typesize"
    
            generate $type $typesize -Size $arg_new_size
            api_replace_instances $instance $typesize
        }
    } else {

	set bbox [get_assoc bbox [api_get_data [api_instances selected]]]
        api_annotate_text \
	    -text "resize==>$arg_new_size" \
            -origin "[lindex $bbox 0] [expr [lindex $bbox 1] - 20]" \
            -color red -tags SPEEDY
    }

    return
}


#############################################

proc find_unresizeable_cells {} {
    global UNRESIZEABLE
    global FIXFILE_ID

    set filename [api_current_cell].fixfile
    if {[catch {open $filename w} FIXFILE_ID] != 0} {
	sue_error "can't open file \"$filename\" for output"
	return
    }
    puts "writing unresizeable cells to file \"$filename\""

    set UNRESIZEABLE(cells_looked_at) ""
    set UNRESIZEABLE(save_cell) ""
    
    set cell [api_current_cell]
    find_unresizeable_subcells $cell

    close $FIXFILE_ID  
}

proc find_unresizeable_subcells {{type ""}} {
    global UNRESIZEABLE
    global cur_s
    global FIXFILE_ID

    set UNRESIZEABLE(save_cell) "[api_current_cell] $UNRESIZEABLE(save_cell)"
    api_goto_cell $type

    set cell_is_generator false

    upvar #0 SUE_$cur_s data
    if {$data(generator)} {
	set cell_is_generator true
    }
    
    set instances [api_instances]
    foreach instance $instances {
        set instance_data [api_get_data $instance]
        set instance_type [get_assoc type $instance_data]

	if {$instance_type == $type}	continue
        switch $instance_type {
            "input"		continue
	    "output"		continue
            "inout"		continue
            "title_bar"		continue
            "sccs_title_bar"	continue
            "nmos"		continue
            "pmos"		continue
            "global"		continue
	    "xgate"		continue
	    "spacer"		continue
            ""			continue
            default	{
		if {[string range $instance_type 0 10] == "bus_combine"}	continue
		if {[string range $instance_type 0 10] == "row_spanner"}	continue
		if {[string range $instance_type 0 7]  == "inverter"}		continue
		if {[string range $instance_type 0 3]  == "nand"}		continue
		if {[string range $instance_type 0 2]  == "nor"}		continue
		if {[string range $instance_type 0 7]  == "name_net"}		continue

		if {$cell_is_generator == "true"} {
		    puts $FIXFILE_ID "# generator $type contains instance of $instance_type"
	            puts $FIXFILE_ID "dont_resize cell $type"
		    break
		}

		if {[lsearch $UNRESIZEABLE(cells_looked_at) $instance_type] != -1} continue
		lappend UNRESIZEABLE(cells_looked_at) $instance_type
		find_unresizeable_subcells $instance_type
	    }
	}
    }
    
    # restore
    api_goto_cell [lindex $UNRESIZEABLE(save_cell) 0]
    set UNRESIZEABLE(save_cell) [lrange $UNRESIZEABLE(save_cell) 1 end]
}



###################################################################

# used by dpc_it (timing.tcl) 

# The way this works these days, a lot of stuff has to get loaded
# *during* the dpc process... that is, we want to do the steiner stuff
# from the normal speedy design, which the right way to get is from 
# the .vg file.  Which, thankfully, gets written by Sue early on.
# SO, speedy_load_design_for_netlist is a callback from "output_file",
# which is the call from sue DPC to get ready to steinerfy nets and write
# the est_dspf file.  A bit twisted, but OK.
# LATER, setup_speedy gets called to create the timing_out file.

##########################################

proc speedy_load_design_for_netlist {} {
    global NETLIST env
    global lib_file_paths
    global DPC_TIMING
    global nl_current_design
    global speedy_is_initialized

    set speedy_is_initialized "in_progress"
   
    puts "Setting up Speedy ... current cell [api_current_cell]"
    speedy clear all
    api_clear_annotations SPEEDY

    # set top_bbox [api_bbox]
    # speedy top_bbox [lindex $top_bbox 0] [lindex $top_bbox 1] [lindex $top_bbox 2] [lindex $top_bbox 3]

    #
    # cell library
    # 
    set ctlf_file_paths $DPC_TIMING(ctlf_file)
    puts "ctlf_file_paths: <$ctlf_file_paths>"

    foreach filename $ctlf_file_paths {
	set filename [string range $filename 0 [expr [string length $filename] - 6]]
	set filename ${filename}.lib		      

	set ix [string last tlf $filename]
	if {$ix != -1} {
		set libfilename [string range $filename 0 [expr $ix - 1]]synopsys[string range $filename [expr $ix + 3] end]
	} else {
		set libfilename $filename
	}
	puts "load libfile $libfilename...."

	set rc [catch "speedy read_cell_library $libfilename"]
	if {$rc != 0} {puts "WARNING: loading lib file $libfilename failed..."}
    }

#    #
#    # verilog file 
#    # 
#    set verilog_file $NETLIST(dir)[api_current_cell].vg
#
#    if {[file readable $verilog_file]} {
#        speedy set top_level_cellname [api_current_cell]
#        speedy read_vgfile $verilog_file
#    } else {
#        puts "no verilog file \"$verilog_file\""
#        return 70
#    }

    puts "speedy initializing from nl"
    speedy_cmd speedy_initialize $nl_current_design
    puts "speedy initialize complete"
    
    set speedy_is_initialized "true"
}


#######
# called from dpc_it in timing.tcl

proc setup_speedy {{mode ""}} {
    global nl_current_design

    global NETLIST SUFFIX cur_s cur_c scale DPC_TIMING TIMING_DATA HIERARCHY DPC
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
    set f1 $TIMING_DATA(input_transition)
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
    puts $FILE_ID "setmaxpossibilities $TIMING_DATA(max_paths)"

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
    speedy write_slow_nodes_file $slow_nodes_file $TIMING_DATA(max_transition) 

    parse_pearl_output $out_file $mode

    ready

    # return OK exit status
    puts "....end setup_speedy..."
    return 0
}

####################

# don't know if these procs are being used now... I think not... 

proc make_timing_annotation {{arg_instance_name ""} {arg_port_name ""} {arg_timing_info ""}} {

    puts "make timing annotation $arg_instance_name $arg_port_name $arg_timing_info"

    set bbox [get_bbox_for_netlist_name $arg_instance_name]
    api_annotate_text \
	-text "$arg_timing_info" \
	-origin "[lindex $bbox 0] [expr [lindex $bbox 1] - 20]" \
	-color white -tags SPEEDY
}


proc speedy_timeit {} {

    speedy global_timing
    set out_file [api_current_cell].timing_out
    parse_pearl_output $out_file 
    display_timing
}    
    
proc get_top_level_cellname {} {

    while {[api_cell_hierarchy] != ""} {
	api_pop
    }
    set cellname [get_assoc filename [api_cell_info]]

    set index [string last "/" $cellname]
    if {$index != -1} {set cellname [string range $cellname [expr $index + 1] end]}

    set index [string last ".sue" $cellname]
    if {$index != -1} {set cellname [string range $cellname 0 [expr $index - 1]]}

    return $cellname
}


###############################################################

# global routing doesn't make sense unless you've done DPC_it,
# which has caused the design to be loaded and steiner-routed.
# from the sue "sim" menu, you call speedy_global_route_command,
#
# annotations won't be very meaningful unless sue is displaying
# the placement view.

# called from sue user interface

proc speedy_global_route_command {{x_pts_per_grid 10} {y_pts_per_grid 22}} {

    puts "... init global route"
    speedy init_global_route $x_pts_per_grid $y_pts_per_grid

    puts "... do global route"
    speedy global_route

    puts "... annotate congetstion"
    speedy annotate_congestion

    puts "... done"
}

# utility display command

proc gb {{gx ""} {gy ""}} {
	if {$gx == ""} {
		show_selected_gridbox
	} else {
		speedy show_gridbox $gx $gy
	}
}

proc show_selected_gridbox {} {
	set instances [api_instances selected]
	set id [lindex $instances 0]
	set data [api_instance_data $id]
	
	# the origin is in a corner, which means gridbox
	# may be off-by-one if instance is flipped.
	# so it seems better to take the center of the bbox.

	set bbox [get_assoc bbox $data]
	# divide by 2 for average, by 10 for scale
	set x [expr [expr [lindex $bbox 0] + [lindex $bbox 2]] / 20]
	set y [expr [expr [lindex $bbox 1] + [lindex $bbox 3]] / 20]

	speedy show_gridbox_at_point $x $y
}

proc show_nets_for_selected_instance {} {

	set instances [api_instances selected]
	while {$instances != ""} {
		set id [lindex $instances 0]
		set instances [lrange $instances 1 end]
		
		set data [api_instance_data $id]
		set name [get_assoc _instance $data]
	
		speedy show_nets_for_instance $name
	}
}


##################################################

# these procs are used by "annotate_congestion" &tc in speedy_commands.cc

proc gr_draw_congestion_annotation {{annotate_list ""}} {

	while {$annotate_list != ""} {
		set annotate_expr [lindex $annotate_list 0]
		set annotate_list [lrange $annotate_list 1 end]
		gr_draw_annotate_box [lindex $annotate_expr 0] \
			[lindex $annotate_expr 1] [lindex $annotate_expr 2] \
			[lindex $annotate_expr 3] [lindex $annotate_expr 4]	
	}
}


proc gr_draw_annotate_box {{x1 ""} {y1 ""} {x2 ""} {y2 ""} {color "green"}} {

	if {$color == ""} {set color "green"}
	# set coords "[expr $x1 * 10] [expr $y1 * 10] [expr $x2 * 10] [expr $y2 * 10]"
	set coords "$x1 $y1 $x2 $y2"
	api_annotate_filled_rect -coords $coords  -fill $color -outline $color -tags congestion
}

proc gr_clear_congestion_annotation {} {

	api_clear_annotations congestion
}

####################################################

# just for me

proc alioop {} {
	source /homes/marshall/speedy3/src/speedy_procs.tcl
}


