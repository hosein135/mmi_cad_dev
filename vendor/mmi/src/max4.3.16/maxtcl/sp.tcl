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

set RCSVERSION(sp.tcl) { $Revision: 1.1 $ }


proc sp_run {} -desc {
  Run speedy to display timing.
} {
  set cell [lay_editcell]
  set mod [fplan_db_cell module $cell]

  fplan_save_nl_props

  catch {nl_create_library foobar}
  nl_read_lef mmi15.lef foobar

  global nl_current_design
  set nl_current_design $mod
  nl_link -libraries foobar
  nl_create_pdesign 	;# Without the -nohierarchy switch this time
  nl_update_cell_locations

  util_load_pkg /volume/mmi/src/speedy/speedy_package.so

  # TODO: Make this programmable!!!!
  speedy_cmd read_libfile /volume/mmi_proj/proj/tech/mmi15/library/synopsys/mmi15.lib
  speedy_cmd set rconst 1
  speedy_cmd set cconst 1
  set nl_current_design alu8
  speedy_set_tcl_obj nl_current_design $nl_current_design
  speedy_cmd load_design_from_nl
  speedy_cmd global_timing
  set tmpfile "speedy_output.tmp"
  speedy_cmd write_timing_out_file $tmpfile

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
  sp_parse_crit_path $result
}


proc sp_dump_nl_locations {{-flat} cells} -desc {
  Dump nl cell placement info to see if it is correct.
} {

  foreach cell $cells {
    if {$flat} {
      foreach icell [nl_list_cells -recursive $cell] {
	puts "flat $icell: [nl_get_cell_location $icell] [nl_get_cell_orientation $icell]"
      }
    } else {
      foreach nlcell [nl_list_cells $cell] {
	puts "hier $cell:$nlcell [nl_get_cell_location $nlcell] [nl_get_cell_orientation $nlcell]"
      }
    }
  }
}


proc sp_parse_crit_path {cpath} {

  global TIMING_OUT TIMING_DATA

  # parse critical paths

  for {set index 0} {index < [llength $cpath]} {incr index} {
      # read in a critical path
      set TIMING_OUT(cp,$index) ""
      set TIMING_OUT(cpmessage,$index) {{}}
      set node "???"
      set first_node ""
      set last_node ""

      if {[llength $line] < 2} {
	error "bad critical path: $cpath"
      }

      # Parse first line.
      set line [lindex $cpath 0]
      setl {delay      cap slope rf node} $line
      lappend TIMING_OUT(cp,$index) [list net $delay $node $rf$slope]
      set first_node $node

      # Parse middle lines.
      for {set i 1} {$i < [expr [llength $cpath]-1]} {incr i} {
	  set line [lindex $cpath $i]
	  setl {delay delta cap slope rf node instpath cell} $line
	  lappend TIMING_OUT(cp,$index) [list pin $delay $node $instpath $rf$slope]
      }

      # Parse last line.
      set line [lindex $cpath end]
      setl {delay  setup node instpath cell} $line
      lappend TIMING_OUT(cp,$index) "term $delay $setup $instpath"
      
      set first 1
      set line [lindex $cpath $index]

      set TIMING_OUT(cp,value,$index) \
	  "$string($index) \($first_node -> $node\)"
  }

  # number of critical paths
  set TIMING_OUT(critical_paths) $index

  # read the min cycle time

  if {0} {
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
}
