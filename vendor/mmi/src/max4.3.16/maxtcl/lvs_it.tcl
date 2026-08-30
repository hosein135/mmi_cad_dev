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


# lvs_it.tcl
set RCSVERSION(lvs_it.tcl) { $Revision: 1.9 $ }

init_global LVS_SEARCH_DIRS -default "." -desc {
  Directory search path for SUE LVS command.
} -doc {
  Specifies directories searched for sue files by SUE LVS and Cross Probe
  commands.  Example:

  set LVS_SEARCH_DIRS "/home/joe/sue /home/cad/project/sue"
} -flags internal

# This tcl procedure runs gemini LVS on the current max cell
# and compares it with a sim generated schematic netlist.  It
# will make sure that the netlist is up-to-date with the sue
# schematic.  If not or if there is no sim netlist, it will
# run SUE and create a sim netlist.  Also, if looks in the global
# array "lvs" to see what name to use for the schematic.

# options to ext2sim.
# -R = exclude resistances, -c 0 = show all caps.

proc lvs_it_max {} -desc {
  runs gemini lvs on the current cell
} {

  global lvs LVS_SEARCH_DIRS

  set save_cd [pwd]

  set cell [lay_rootcell]
  # set the directory to this file or things don't work
  cd [file dirname [lindex [cell_info $cell] 1]]

  puts "\nRunning LVS:"

  set lvs_err "lvs_err[pid]"

  # Generate the .ext file
  extract_it

  # Translate .ext file to .sim using ext2sim
  puts "running ext2sim..."
  if {[catch {exec ext2sim -B -c 0 -R -p ". [cell_path_add]" -o temp.sim $cell.ext} msg]} {
    max_error "lvs error: aborting, Error running ext2sim: $msg"
    return
  }

  # Add format: UCB to the cell_lay.sim file

  set temp_file [open temp.sim r]
  set lay_sim_file [open ${cell}_lay.sim w]

  gets $temp_file line
  puts $lay_sim_file "$line 	format: UCB"
  while {[gets $temp_file line] >= 0} {
#    regsub -all GND $line gnd line
#    regsub -all VDD $line vdd line
    puts $lay_sim_file "$line"
  }

  # Clean stuff up.
  close $temp_file
  close $lay_sim_file
  exec rm -f temp.sim

  # get the schematic name for this cell
  set schem [use_first lvs($cell) cell]

  # find the correct directory for this file
  foreach dir [use_first LVS_SEARCH_DIRS `.] {
    if {[file exists "$dir/$schem.sue"]} {
      set schem "$dir/$schem"
    }
  }

  # check to see if schematic sim netlist is up-to-date
  set regen_sim 0
  if {[file exists $schem.sim]} {
    if {[file exists $schem.sue]} {
      set schem_date [file mtime $schem.sue]
      set sim_date [file mtime $schem.sim]
      if {$sim_date < $schem_date} {
	# sim netlist is out of date
	set regen_sim 1
      }
    }
  } elseif {[file exists $schem.sue]} {
    set regen_sim 1
  } else {
    puts "Aborting, no sim netlist ($schem.sim) or sue schematic ($schem.sue)."
    return
  }

  if {$regen_sim} {
    puts "Sim netlisting schematic $schem.sue in SUE ..."
    catch {exec sue $schem.sue -SET NETLIST_TYPE=sim -SET NETLIST_PROPS=sim -CMD netlist -CMD exit -ICONIFY 1}
  }

  # Generate an equivalence file

  catch {exec rm -f $cell.equiv}

  set schem_sim [open $schem.sim r]
#  set equiv_file [open $cell.equiv w]

  while {[gets $schem_sim line] >= 0} {
    if {[lindex $line 0]  == "A"} {
      lappend schem_ports [lindex $line 1]
    }
  }
  lappend schem_ports vdd gnd

  eval lay_box [lay_bbox]
  sel_labels 
#  :select -editOnly area labels
  set lay_ports ""
  foreach label [split [sel_what labels] \n] {
    setl {layer x1 y1 x2 y2 pos text path group kind} $label
    if {$kind == "input" || $kind == "output" || $kind == "inout" || $kind == "global"} {
      lappend lay_ports $text
    }
  }

  foreach i $schem_ports {
    if {[lsearch -exact $lay_ports $i] >= 0} {
#      puts $equiv_file "= $i $i"
    } else {
      puts "Warning: No label for net $i found in layout."
    }
  }

  # Clean up
  close $schem_sim
#  close $equiv_file

  # run gemini on it
  puts "running gemini on ${cell}_lay.sim vs. $schem.sim ..."

  catch {exec rm -f $cell.gemini}

#  catch {exec gemini -n 80 -w5 -c -E $cell.equiv -D $cell.dict -M $lvs_err:5 ${cell}_lay.sim $schem.sim >& $cell.gemini 2> [exec tty]}
  catch {exec gemini -n 80 -w5 -c -D $cell.dict -M $lvs_err:5 ${cell}_lay.sim $schem.sim >& $cell.gemini 2> [exec tty]}

  # Parse the Magic output into feedback output.

  set mag_in_file [open $lvs_err.err.mag r]
  set feedback_file [open "_LVS_" w]
  set indicator 0

  while {[gets $mag_in_file line] >= 0} {
    if {$line  == "<< error_s >>"} {
      set indicator 1
      gets $mag_in_file line
      set x1 [lindex $line 1]
      set y1 [lindex $line 2]
      set x2 [lindex $line 3]
      set y2 [lindex $line 4]
      gets $mag_in_file line
      gets $mag_in_file line
      set x1 [expr $x1*1.0*[res]]
      set y1 [expr $y1*1.0*[res]]
      set x2 [expr $x2*1.0*[res]]
      set y2 [expr $y2*1.0*[res]]
      puts $feedback_file "lay_box $x1 $y1 $x2 $y2"
      puts $feedback_file ":feedback add \{[lindex $line 7]\} pale"
    }
  }

  # Clean stuff up.
  close $mag_in_file
  close $feedback_file
  exec rm -f $lvs_err.err.mag

  # show user $cell.gemini file
  catch {exec cat $cell.gemini > [exec tty]}

  # Check to see if it is REALLY clean.
  set gemini_aborted 1
  set file_id [open $cell.gemini r]
  while {[gets $file_id line] >= 0} {
    if {$line  == "The circuits are different."} {
      set indicator 1
      puts "There are hookup errors."
    }
    if {$line  == "The following transistors do not match in size:"} {
      set indicator 1
      puts "There are device size discrepancies."
    }
    # look for "0 devices and 0 nets displayed in lvs_err4339.err.mag"
    if {[string first "nets displayed" $line] != -1} {
      set gemini_aborted 0
      if {[string first "0 devices and 0 nets" $line] != 0} {
	set indicator 1
	puts "[lrange $line 0 4] mismatch."
      }
    }
  }

  if {$gemini_aborted} {
    set indicator 1
    puts "Gemini Aborted."
  }

#  puts ""
  close $file_id

  set dictionary_file [open $cell.dict r]
  gets $dictionary_file line
  gets $dictionary_file line
  while {[gets $dictionary_file line] >= 0} {
    if {[lindex $line 1]  != [lindex $line 2]} {
      if {[lsearch -exact $schem_ports [lindex $line 2]] >= 0} {
        puts "Warning: LVS matched layout node [lindex $line 1] with schematic node [lindex $line 2]"
	set indicator 1
      }
    }
  } 
  puts ""
  close $dictionary_file

  if {$indicator == 0} {
    puts "LVS is CLEAN!"
  } else {
    puts "LVS Found DISCREPANCIES!  View feedback for errors."
    # Clear previous feedback
    :feedback clear
    # Source the error output
    source _LVS_
  }

  # restore current working directory
  cd $save_cd

  sel_clear

  puts "done."
}


proc extract_it {} -desc {
  extracts the current cell to .ext format, flattening gcells.
} {

  # Generate the .ext file
  :feedback clear
  msg "extracting cell: [lay_editcell]\n"

  # MAJOR HACK: TODO FIX with new netlister
  # flattens gcells for extract
  undo_delim

  eval lay_box [lay_bbox]
#  select_q -editOnly area subcell
  eval sel_area -layers subcell [lay_bbox]

  # unselect non gcells
  foreach list [split [sel_what cells] \n] {
    setl {inst_name cell_name} $list
    if {![is_gcell $cell_name]} {
      # not a gcell, deselect
#      select_q less cell $inst_name
      sel_cell -less $inst_name
    }
  }

  if {[sel_what cells] != ""} {
    flatten_cells

    # remove all hidden labels
    sel_labels -kind hidden
    :delete
  }

  if {[msg_catch ":extract" "" info warn]} {
    msg "extract failed!\n"
  }

  undo_to_delim
  undo_flush_redo
  # DONE WITH HACK

  if {$warn != ""} {
    msg "$warn\n"
  }
  :feedback save extract_feedback

  msg "done.\n"
}

