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


puts "reading $SPEEDY_PATH/src/speedy_menu.tcl"

###############################################################
# dynamic-load package

# dynamic-load object package 
if {[info commands speedy_command] == ""} {
	puts "Loading speedy shared object from $SPEEDY_PATH ... (override with unix environment variable SPEEDY_PATH)"
	if {[catch {load $SPEEDY_PATH/speedy_package.so} msg]} {
		puts $msg
		return
	}
}

###############################################################
# menus
# SUE has a fixed set of menus.  See utilities.tcl line 626. 
# MAX is willing to add menus.  Crap.
#	.... besides which, Sue menu names are lower case, despite what you see on the screen.
# ....argyle, this won't work with Sue.

menu_add -menu Speedy -label "Libfiles" -command "sy_libfile_popup"	\
    -help "Info and commands about .lib timing information files"
    
menu_add -menu Speedy -label "Design" -command "sy_load_design_popup"	\
    -help "Initialize the speedy design data base, from verilog or nl"
    
menu_add -menu Speedy -label "Time It" -command "sy_timing_popup"	\
    -help "Stuff for computing long path, &c."
    
menu_add -menu Speedy -label "Resize" -command "sy_resize_popup"	\
    -help "Stuff for computing long path, &c."
    
menu_add -menu Speedy -label "Lee's Icon Creator" -command "sy_icon_creator"	\
    -help "Create an oversimplified lib file for use in higher level timing analysis"

source $SPEEDY_PATH/src/icon_creator.tcl 

###############################################################
###############################################################
###############################################################
# procs
# .... proc names should have prefix "sy_" 

# development hack
proc sy_rewhack {} {
	global SPEEDY_PATH

	puts "sy_resource"
	source /homes/marshall/speedy3/src/speedy_menu.tcl
}

###############################################################
# generalized user interface
# "cmd" can be anything listed in "do_something()" in speedy_commands.cc

proc speedy { {cmd ""} {arg1 ""} {arg2 ""} {arg3 ""} {arg4 ""} } {
	global	TOOLNAME

	puts "speeeeedy! $cmd $arg1 $arg2 $arg3 $arg4"
	set result [speedy_command $cmd $arg1 $arg2 $arg3 $arg4]

	if {$result != ""} {
		# if {$TOOLNAME == "SUE"} {
		# 	sue_error "SPEEDY: command failed: $result.... $cmd $arg1 $arg2 $arg3 $arg4"
		# 	sue_error flush
		# 	return 0
		# }

		puts "SPEEDY: command failed: $result.... $cmd $arg1 $arg2 $arg3 $arg4"
		return $result				
	}
}

######################################################
## libfile stuff

set SY(libfilelist) ""
proc sy_libfile_popup {} {
	global SY

	puts "proc libfile_popup"

	set title	"libfiles"
	set message	""
    
	while {1} {
		set proplist ""

		if {$SY(libfilelist) == ""} {
			lappend proplist [list "...no Lib Files are Loaded" "" -label]
		} else {
			lappend proplist [list "    Lib Files Loaded:" "" -label]
			foreach libfile $SY(libfilelist) {
				lappend proplist  [list "$libfile" ""	-label]
			}
		}
		lappend proplist [list "---major functions----------" "" -label]
		lappend proplist [list "read named libfile"   ""	-button ""	-return "sy_load_libfile_from_dialog_box"]
		lappend proplist [list "write top-level libfile"   ""	-button ""	-return "sy_write_libfile"]

		##############################
		## HOKAY!

		set rv [prop_menu2 -message $message -title $title $proplist]

		# so.....what?
		set message "...ok..."

		switch -- $rv {
			0	return
			1	return

			sy_load_libfile_from_dialog_box {
				sy_load_libfile_from_dialog_box
			}

			sy_write_libfile {
				sy_write_libfile
			}

			default	{
				set message "say what?"
				continue
			}
		}
		break		
	}
	return
}


proc sy_load_libfile_from_dialog_box {} {
	global SY

	puts "proc sy_load_libfile_from_dialog_box"

	set lib_fn [fs_box -message "Select Cell Library File" -pattern "*.lib"]
	switch -- $lib_fn {
		0	return
		default {}
	}

	sy_load_libfile $lib_fn
	return
}

proc sy_load_libfile {libfn} {
	global SY

	puts "proc sy_load_libfile $libfn"
	if {[catch [speedy read_libfile $libfn]] != 0} {
		puts "libfile \"$libfn\" not found or not readable or at any rate not read"
	} else {
		lappend SY(libfilelist) $libfn
	}
}

proc sy_write_libfile {} {
	global SY

	puts "proc sy_write_libfile $SY(top_level_cellname)"
	if {[catch [speedy write_libfile $SY(top_level_cellname)"]] != 0} {
		puts "write libfile failed"
	} 
}

###############################################################
## loading design
# set SY(top_level_cellname) [use_first $nl_current_design 'no_name]

set SY(top_level_cellname) "no_name"

proc sy_load_design_popup {} {
	global SY
	
	puts "proc sy_load_design"

	set title "Load Design"
	set message "welcome to..."

	set vg_filename		$SY(top_level_cellname).vg
	set dspf_filename	$SY(top_level_cellname).dspf
	set def_filename	$SY(top_level_cellname).def

	while {1} {
		set proplist ""

		set xxxtop_level_cellname $SY(top_level_cellname)
		lappend proplist [list "top name:"	xxxtop_level_cellname	-entry]		
		lappend proplist [list ".dspf filename:" dspf_filename		-entry]		
		lappend proplist [list ".def filename:" def_filename		-entry]		

		lappend proplist [list "---major functions----------"     ""	-label]
		lappend proplist [list "load nl from vg"		  ""	-button "" -return "sy_load_nl_from_vg"]
		lappend proplist [list "load netlist from nl"		  ""	-button "" -return "sy_load_netlist_from_nl"]
		lappend proplist [list "load physical nets dspf"	  ""	-button "" -return "sy_load_physical_nets_from_dspf"]

		lappend proplist [list "---other functions----------"     ""	-label]
		lappend proplist [list "load nl from vg"		  ""	-button "" -return "sy_load_nl_from_vg"]
		lappend proplist [list "load instance location from def"  ""	-button "" -return "sy_load_instance_location_from_def"]


		##############################
		## HOKAY!

		set rv [prop_menu2 -message $message -title $title $proplist]

		if {$rv == 0}	return

		if {$SY(top_level_cellname) != $xxxtop_level_cellname} {
			set SY(top_level_cellname)	$xxxtop_level_cellname
			set vg_filename			$SY(top_level_cellname).vg
			set dspf_filename		$SY(top_level_cellname).dspf
			set def_filename		$SY(top_level_cellname).def

			if {$rv == 1} {
				set rv OK
			}
		} 

		# so.....what?
		set message "...ok..."

		switch -- $rv {
			1	return
			OK	continue
		
			sy_load_netlist_from_nl {
				sy_load_netlist_from_nl $vg_filename
				continue
			}

			sy_load_instance_location_from_def {
				sy_load_instance_location_from_def $def_filename
				continue
			}

			sy_load_physical_nets_from_dspf {
				sy_load_physical_nets_from_dspf $dspf_filename
				continue
			}

			sy_load_nl_from_vg {
				sy_load_nl_from_vg $vg_filename
				continue
			}

			sy_load_instance_location_from_def {
				sy_load_instance_location_from_def $def_filename
				continue
			}

			sy_load_physical_nets_from_dspf {
				sy_load_physical_nets_from_dspf $dspf_filename
				continue
			}

			default	{
				set message "say what?"
			}
		}
		continue
	}
	return
}

proc sy_load_netlist_from_nl {vg_filename} {
	global SY

	puts "sy_load_netlist_from_nl $SY(top_level_cellname) $vg_filename"

	speedy set top_level_cellname $SY(top_level_cellname)
	sy_load_speedy_from_nl
}

proc sy_load_nl_from_vg {vg_filename} {

	puts "proc sy_load_nl_from_vg $vg_filename"

	# nl commands
	set nl_bus_naming_style "%s_%d"
	nl_read_verilog $vg_filename
	nl_link -silent
	nl_create_idesign
}

proc sy_load_speedy_from_nl {} {
	global nl_current_design

	puts "proc sy_load_speedy_from_nl"

	# "nl_current_design" is nl variable, a Tcl_Obj
	# note "speedy_set", not "speedy set" .... sorry about that...
	speedy_set_tcl_obj "nl_current_design" $nl_current_design	
	speedy load_design_from_nl
}

proc sy_load_speedy_instances_from_nl {} {
	global nl_current_design

	puts "proc sy_load_speedy_instances_from_nl"

	# note "speedy_set", not "speedy set" .... sorry about that...
	speedy_set_tcl_obj "nl_current_design" $nl_current_design	
	speedy load_instances_from_nl
}

proc sy_load_instance_location_from_def {def_filename} {

	puts "proc load_def $def_filename"
	speedy read_deffile $def_filename
}

proc sy_load_physical_nets_from_dspf {dspf_filename} {

	puts "proc load_dspf $dspf_filename"
	speedy read_dspffile $dspf_filename
}


###############################################################
## timing

set SY(net_model)		"IGNORE_NETS"
set SY(did_regularize_nets)	false
set SY(did_compute_net_characteristics)	false

set SY(clock_nets)		""

proc sy_timing_popup {} {
	global SY
	puts "proc timing_stuff"

	set title "Timing Stuff"
	set message "welcome to..."
	set selected_net_model		"IGNORE_NETS"
	set xxxselected_net_model	"IGNORE_NETS"
	speedy set net_model $selected_net_model

	set rconst [speedy get rconst]
	set xxxrconst $rconst
	set cconst [speedy get cconst]
	set xxxcconst $cconst
	set target_slope [speedy get target_slope]
	set xxxtarget_slope $target_slope
	

	set long_path_filename $SY(top_level_cellname).lp
	set n_long_paths 5

	while {1} {
		set proplist ""
		set net_modellist ""
		lappend net_modellist	"EXTRACTED_NETS"
		lappend net_modellist	"STEINER_RC_NETS"
		lappend net_modellist	"STEINER_CAP_NETS"
		lappend net_modellist	"WIRE_LOAD_CAP_NETS"
		lappend net_modellist	"EXPLICIT_CAP_NETS"
		lappend net_modellist	"IGNORE_NETS"

		lappend proplist	[list "" selected_net_model		-radio $net_modellist]

		lappend proplist [list "ohms per grid unit:" xxxrconst	-entry]		
		lappend proplist [list "pf per grid unit:" xxxcconst	-entry]		
		lappend proplist [list "target slope:" xxxtarget_slope	-entry]		

		# clock nets
		lappend proplist [list "    clock nets:" "" -label]    
		if {$SY(clock_nets) == ""} {
			lappend proplist [list "...no clock nets..." "" -label]
		} else {
			foreach net $SY(clock_nets) {
				lappend proplist  [list "$net" "" -label]
			}
		}
		lappend proplist [list "new clock net name" new_clock_net_name -entry]    
		lappend proplist [list "add clock net" "" -button "" -return add_clock net]


		lappend proplist [list "---major functions----------" ""		-label]
		
		lappend proplist [list "time it" ""			-button "" -return "time_it"]

		lappend proplist [list "---sub-functions----------" ""		-label]
		
		lappend proplist [list "regularize nets"	     ""	-button "" -return "regularize_nets"]
		lappend proplist [list "compute net characteristics" ""	-button "" -return "compute_net_characteristics"]
		lappend proplist [list "global timing" ""		-button "" -return "global_timing"]

		lappend proplist [list "-------------" ""		-label]
		lappend proplist [list "long path file:" long_path_filename	-entry]		
		lappend proplist [list "n long paths:" n_long_paths	-entry]		
		lappend proplist [list "write lp file" ""		-button "" -return "write_long_path_file"]


		##############################
		## HOKAY!

		set rv [prop_menu2 -message $message -title $title $proplist]
		puts "rv $rv"
	
		# so.....what?
		set message "...ok..."

		if {$selected_net_model != $xxxselected_net_model} {

			set rv [speedy set net_model $selected_net_model]
			if {$rv != ""} {
				puts "set net_model failed, rv \"$rv\""
				set message $rv
				continue
			} 
			set xxxselected_net_model $selected_net_model 
		}

		if {$xxxrconst != $rconst} {
			set rv [speedy set rconst $xxxrconst]
			if {$rv != ""} {
				puts "reset target slope failed, rv \"$rv\""
				set message $rv
			} else {
				set rconst $xxxrconst
			}
		}

		if {$xxxcconst != $cconst} {
			set rv [speedy set cconst $xxxcconst]
			if {$rv != ""} {
				puts "reset target slope failed, rv \"$rv\""
				set message $rv
			} else {
				set cconst $xxxcconst
			}
		}

		if {$xxxtarget_slope != $target_slope} {
			set rv [speedy set target_slope $xxxtarget_slope]
			if {$rv != ""} {
				puts "reset target slope failed, rv \"$rv\""
				set message $rv
			} else {
				set target_slope $xxxtarget_slope
			}
		}

		switch -- $rv {
			0	return
			1	return

			add_clock_net {	
				puts "add_clock_net"
				set rv [speedy flag_net_as_clock $new_clock_net_name]
				if {$rv != ""} {
					puts "add_clock_net failed, rv \"$rv\""
					set message $rv
				} 
			}

			time_it {	
				puts "begin time_it"

				if {$SY(did_regularize_nets) == "false"} {
					set rv [speedy regularize_nets]
					if {$rv != ""} {
						puts "regularize_nets failed, rv \"$rv\""
						set message $rv
					} else {
						set SY(did_regularize_nets) true
					}
				}
				if {$SY(did_compute_net_characteristics) == "false"} {
					set rv [speedy compute_net_characteristics]
					if {$rv != ""} {
						puts "compute_net_characteristics failed, rv \"$rv\""
						set message $rv
					} else {
						set SY(did_compute_net_characteristics) true
					}
				}

				set rv [speedy global_timing]
				if {$rv != ""} {
					puts "global_timing failed, rv \"$rv\""
					set message $rv
				} 

				set rv [speedy write_long_paths_file $n_long_paths $long_path_filename]
				if {$rv != ""} {
					puts "write_long_path_file failed, rv \"$rv\""
					set message $rv
				} 
			}

			regularize_nets {	
				puts "regularize_nets"
				set rv [speedy regularize_nets]
				if {$rv != ""} {
					puts "regularize_nets failed, rv \"$rv\""
					set message $rv
				} else {
					set SY(did_regularize_nets) true
				}
			}

			compute_net_characteristics {	
				puts "compute_net_characteristics"
				set rv [speedy compute_net_characteristics]
				if {$rv != ""} {
					puts "compute_net_characteristics failed, rv \"$rv\""
					set message $rv
				} else {
					set SY(did_compute_net_characteristics) true
				}
			}

			global_timing {	
				puts "global_timing"
sd				set rv [speedy global_timing]
				if {$rv != ""} {
					puts "global_timing failed, rv \"$rv\""
					set message $rv
				} 
			}

			write_long_path_file {
				puts "write_long_path_file"
				set rv [speedy write_long_paths_file $n_long_paths $long_path_filename]
				if {$rv != ""} {
					puts "write_long_path_file failed, rv \"$rv\""
					set message $rv
				} 
			}

			default	{
				set message "say what?"
				continue
			}
		}
		continue
	}
	return
}



###############################################################
## resize

set SY(target_slope)			.050
set SY(maximum_desireable_slope)	.500
set SY(minimum_desireable_slack)	.020

proc sy_resize_popup {} {
	global SY
	puts "proc sy_resize_popup"
	set title "Resize Stuff"
	set message "welcome to..."

	speedy set target_slope $SY(target_slope)
	set xxxtarget_slope $SY(target_slope)
	speedy set maximum_desireable_slope $SY(maximum_desireable_slope)
	set xxxmaximum_desireable_slope $SY(maximum_desireable_slope)
	speedy set minimum_desireable_slack $SY(minimum_desireable_slack)
	set xxxminimum_desireable_slack $SY(minimum_desireable_slack)

	while {1} {
		set proplist ""
		lappend proplist [list "target slope:" xxxtarget_slope	-entry]		
		lappend proplist [list "maximum desireable slope:" xxxmaximum_desireable_slope	-entry]		
		lappend proplist [list "minimum desireable slack:" xxxminimum_desireable_slack	-entry]		

		lappend proplist [list "---major functions----------" ""		-label]
		
		lappend proplist [list "resize ... the works" ""		-button "" -return "resize_the_works"]
		lappend proplist [list "resize by output load" ""		-button "" -return "resize_by_output_load"]
		lappend proplist [list "optimize along long path" ""		-button "" -return "optimize_along_long_path"]
		lappend proplist [list "downsize to save area" ""		-button "" -return "downsize_to_save_area"]
		lappend proplist [list "  ---" ""		-label]
		lappend proplist [list "display changed cells" ""		-button "" -return "display_changed_cells"]
		lappend proplist [list "restore original cells" ""		-button "" -return "restore_original_cells"]
		lappend proplist [list "display long path" ""			-button "" -return "display_long_path"]

		lappend proplist [list "  ---" ""		-label]
		lappend proplist [list "remove and replace buffers" ""		-button "" -return "remove_and_replace_buffers"]

		##############################
		## HOKAY!

		set rv [prop_menu2 -message $message -title $title $proplist]
		puts "rv $rv"
	
		# so.....what?
		set message "...ok..."

		if {$xxxtarget_slope != $SY(target_slope)} {

			set rv [speedy set target_slope $xxxtarget_slope]
			if {$rv != ""} {
				puts "set target slope failed, rv \"$rv\""
				set message $rv
				continue
			} 
			set SY(target_slope) $xxxtarget_slope 
		}

		if {$xxxmaximum_desireable_slope != $SY(maximum_desireable_slope)} {

			set rv [speedy set net_model $xxxmaximum_desireable_slope]
			if {$rv != ""} {
				puts "set maximum desireable slope failed, rv \"$rv\""
				set message $rv
				continue
			} 
			set SY(maximum_desireable_slope) $xxxmaximum_desireable_slope 
		}

		if {$xxxminimum_desireable_slack != $SY(minimum_desireable_slack)} {

			set rv [speedy set net_model $xxxminimum_desireable_slack]
			if {$rv != ""} {
				puts "set net_model failed, rv \"$rv\""
				set message $rv
				continue
			} 
			set SY(minimum_desireable_slack) $SY(minimum_desireable_slack)
		}


		switch -- $rv {
			0	return
			1	return

			resize_the_works {	

				set rv [speedy resize instances]
				if {$rv != ""} {
					puts "resize failed, rv \"$rv\""
					set message $rv
				} 

				set rv [speedy resize for_area_by_instances]
				if {$rv != ""} {
					puts "resize for area failed, rv \"$rv\""
					set message $rv
				} 
			}

			resize_by_output_load {	

				set rv [speedy resize thresholds_by_instances]
				if {$rv != ""} {
					puts "resize failed, rv \"$rv\""
					set message $rv
				} 

				set rv [speedy resize downsize_by_instances]
				if {$rv != ""} {
					puts "resize failed, rv \"$rv\""
					set message $rv
				} 
			}

			optimize_along_long_path {

				set rv [speedy resize optimize_by_instances]
				if {$rv != ""} {
					puts "resize failed, rv \"$rv\""
					set message $rv
				} 
			}

			downsize_to_save_area {

				set rv [speedy resize for_area_by_instances]
				if {$rv != ""} {
					puts "resize failed, rv \"$rv\""
					set message $rv
				} 
			}

			display_changed_cells {

				set rv [speedy summarize_resized_instances]
				if {$rv != ""} {
					puts "display changed cells failed, rv \"$rv\""
					set message $rv
				} 
			}

			restore_original_cells {

				set rv [speedy restore_nominal_cells]
				if {$rv != ""} {
					puts "resize failed, rv \"$rv\""
					set message $rv
				} 
			}

			display_long_path {

				set rv [speedy print long_path]
				if {$rv != ""} {
					puts "resize failed, rv \"$rv\""
					set message $rv
				} 
			}

			remove_and_replace_buffers {

				set rv [speedy remove_all_buffers]
				if {$rv != ""} {
					puts "remove buffers failed, rv \"$rv\""
					set message $rv
				} 
				set rv [speedy insert_buffers]
				if {$rv != ""} {
					puts "insert buffers failed, rv \"$rv\""
					set message $rv
				} 
			}

			default	{
				set message "say what?"
				continue
			}
		}
		continue
	}
	return
}






###############################################################
###############################################################
###############################################################
# more setup?



###############################################################
# done
puts "done with $SPEEDY_PATH/speedy_menu.tcl"
