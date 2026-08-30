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

# this file is designed to be loaded with speedy_procs.tcl....
# .... that is, the old Sue interface ....
# there was some thought about making it general, but it is
# *NOT* loaded with speeedy_menu.tcl.

######################################################
# utilities

puts "file utils.tcl"

###############################################################
# generalized user interface
# "cmd" can be anything listed in "do_something()" in speedy_commands.cc

proc speedy { {cmd ""} {arg1 ""} {arg2 ""} {arg3 ""} {arg4 ""} } {
	global	MODE

	puts "speeeeedy! $cmd $arg1 $arg2 $arg3 $arg4"
	set result [speedy_command $cmd $arg1 $arg2 $arg3 $arg4]

	if {$result != ""} {
		if {$MODE == "SUE"} {
			sue_error "SPEEDY: command failed: $result.... $cmd $arg1 $arg2 $arg3 $arg4"
			sue_error flush
			return 0
		}

		return $result				
	}
}

######################################################
## misc

proc sy_is_integer {str} {

	# this should be enhanced....
	return true

}

proc sy_getline {FILE} {

	set rv [catch gets $FILE line]
	if {$rv == -1} {
		return "END OF FILE"
	}
	return [string trim $line]
}



######################################################
## libfile stuff

proc sy_libfile_popup {} {
	global libfilelist

	puts "proc sy_libfile_popup"

	set title	"libfiles"
	set message	""
    
	while {1} {
		set proplist ""

		if {$libfilelist == ""} {
			lappend proplist [list "...no Lib Files are Loaded" "" -label]
		} else {
			lappend proplist [list "    Lib Files Loaded:" "" -label]
			foreach libfile $libfilelist {
				lappend proplist  [list "$libfile" ""	-label]
			}
		}
		lappend proplist [list "-------------" "" -label]
		lappend proplist [list "read libfile"   ""	-button ""	-return "read_named_libfile"]

		##############################
		## HOKAY!

		set rv [prop_menu2 -message $message -title $title $proplist]
		puts "rv .... $rv"	

		# so.....what?
		set message "...ok..."

		switch -- $rv {
			0	return
			1	return

			read_named_libfile {
				read_named_libfile
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


proc sy_read_named_libfile {} {
	global libfilelist

	puts "proc sy_read_named_libfile"

	set lib_fn [fs_box -message "Select Cell Library File" -pattern "*.lib"]
	switch -- $lib_fn {
		0	return
		default {}
	}

	load_libfile $lib_fn
	return
}

proc sy_load_libfile {libfn} {
	global libfilelist

	puts "proc sy_load_libfile $libfn"
	if {[catch [speedy read_libfile $libfn]] != 0} {
		puts "project libfile \"$libfn\" not found or not readable or at any rate not read"
	} else {
		lappend libfilelist $libfn
	}
}



