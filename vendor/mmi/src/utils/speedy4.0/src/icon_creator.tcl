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

puts "reading icon_creator.tcl"

proc sy_icon_creator {} {
	global SY

	set title "Lee's Icon Creator"
	set message "welcome to..."

	set input_name	"input"
	set input_delay	"0.0"
	set input_proto	"MMI_FFB:d"
	set inputs	""

	set output_name	"output"
	set output_delay "0.0"
	set output_proto "MMI_BUFE:out"
	set outputs	""

	set write_libfile_name $SY(top_level_cellname).lib
	set write_iconfile_name $SY(top_level_cellname).sue
	set write_libfile_results ""
	set write_iconfile_results ""

	speedy new_design $SY(top_level_cellname)
	speedy print top_level_cellname

	while {1} {
		set proplist ""
	    	set xxxtop_level_cellname $SY(top_level_cellname)

		# icon name
		lappend proplist [list "Icon Name" xxxtop_level_cellname -entry]    
		lappend proplist [list "clear cell" "" -button "" -return "clear_cell"]
		lappend proplist [list "-------------" "" -label]

		# inputs
		lappend proplist [list "    Inputs:" "" -label]    
		if {$inputs == ""} {
			lappend proplist [list "...no inputs yet..." "" -label]
		} else {
			foreach input $inputs {
				set input_str "[lindex $input 0]\t[lindex $input 1]\t[lindex $input 2]"
				lappend proplist  [list "$input_str" "" -label]
			}
		}
		lappend proplist [list "new input name" input_name -entry]    
		lappend proplist [list "delay:" input_delay -entry]    
		lappend proplist [list "prototype pin:" input_proto -entry]    
		lappend proplist [list "make new input" "" -button "" -return make_new_input]

		# outputs
		lappend proplist [list "    Outputs:" "" -label]    
		if {$outputs == ""} {
			lappend proplist [list "...no outputs yet..." "" -label]
		} else {
			foreach output $outputs {
				set output_str "[lindex $output 0]\t[lindex $output 1]\t[lindex $output 2]"
				lappend proplist  [list "$output_str" "" -label]
			}
		}
		lappend proplist [list "new output name" output_name -entry]    
		lappend proplist [list "delay:" output_delay -entry]    
		lappend proplist [list "prototype pin:" output_proto -entry]    
		lappend proplist [list "make new output" "" -button "" -return make_new_output]
		lappend proplist [list "-------------" "" -label]

		# write....
		lappend proplist [list "output libfile name (.lib):" write_libfile_name -entry]
		lappend proplist [list "...or select" "" -button "" -return "select_libfile"]
		lappend proplist [list "write cell to libfile" "" -button "" -return "write_libfile"]
		#lappend proplist [list "-------------" "" -label]

		#lappend proplist [list "output iconfile name (.sue):" write_iconfile_name -entry]
		#lappend proplist [list "...or select" "" -button "" -return "select_iconfile"]
		#lappend proplist [list "write inconfile" "" -button "" -return "write_iconfile"]

		##############################
		## HOKAY!

		set rv [prop_menu2 -message $message -title $title $proplist]
	
		# so.....what?
		set message "...ok..."

		if {$rv == 0}	return

		if {$xxxtop_level_cellname != $SY(top_level_cellname)} {

			set SY(top_level_cellname) $xxxtop_level_cellname
			speedy set top_level_cellname $SY(top_level_cellname)
			set write_libfile_name $SY(top_level_cellname).lib
			set write_iconfile_name $SY(top_level_cellname).sue

			# warning in case he manually selected an output filename...
			set message "ouput libfile name also changed"

		}

		switch -- $rv {

			make_new_input {
				set rc [speedy add_extconn_for_limited_icon_creator $input_name input $input_proto $input_delay]
				switch -- $rc {
					"" {
						lappend inputs [list $input_name input $input_proto $input_delay]
					}

					default {
						set message $rc
					}
				}
				continue
			}

			make_new_output {
				set rc [speedy add_extconn_for_limited_icon_creator $output_name output $output_proto $output_delay]
				switch -- $rc {
					"" {
						lappend outputs [list $output_name output $output_proto $output_delay]
					}
					default {
						set message $rc
					}
				}
				continue
			}

			clear_cell {
				speedy new_design $SY(top_level_cellname)
				set inputs ""
				set outputs ""
				set message "cell is empty"
				continue
			}

			select_libfile {
				set name [fs_box -message "Select Output Library File" -pattern "*.lib"]
				if {$name != 0} {
					set write_libfile_name $name
					set message [speedy write_libfile $write_libfile_name]
				}
				continue
			}

			write_libfile {
				speedy set net_model IGNORE_NETS
				speedy flag_net_as_clock clk
				set message [speedy write_libfile $write_libfile_name]
				continue
			}
		
			select_iconfile {
				set name [fs_box -message "Select Output Icon File" -pattern "*.lib"]
				if {$name != 0} {
					set write_iconfile_name $name
					set write_iconfile_results [speedy write_iconfile $write_iconfile_name]
				}
				continue
			}

			write_iconfile {
				set message [speedy write_iconfile $write_iconfile_name]
				continue
			}

			default {
				set message "say what???"
				continue
			}
		
		}
		break		
	}

	return
}

proc write_iconfile {filename} {

	return "we don't do that yet"

}

