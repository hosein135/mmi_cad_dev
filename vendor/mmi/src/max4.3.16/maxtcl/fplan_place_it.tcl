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

set RCSVERSION(fplan.tcl) { $Revision: 1.9 $ }


proc UNUSED_PATS_fplan_place_it {{cell ""}} {
  global env MN_TECH

  fplan_check_verilog

  catch {set tech_root $env(TECH_ROOT)}

  if {$tech_root == "" || ![file isdirectory $tech_root]} {
    max_error -buffer "error: TECH_ROOT environment variable incorrect"
    return
  }


  if {$cell == ""} {set cell [lay_editcell]}
  set mod [fplan_db_cell module $cell]
  set dir "place_it"

  # Make a list of the hierarchical subcells in cell.
  set hier_defs ""
  foreach subcell [db_kids $cell] {
    if {[fplan_cell_info -is_hier $subcell]} {
      lappend hier_defs $subcell
    }
  }

  # Not used...
  set hier_ids ""
  foreach cell_info [db_search_l cells -cell $cell] {
    struct max_cell c $cell_info
    if {[fplan_cell_info -is_hier ${c.def}]} {
      lappend hier_ids ${c.id}
    }
  }

  catch {file mkdir $dir}
  if {![file isdirectory $dir]} {
    error "Can not create directory $dir"
  }

  # TODO: fix this
  set db $MN_TECH.db
  set pdb $MN_TECH.pdb


  # Write the verilog file.  Need only the modules of interest to us.
  # Note that the verilog might have changed due to grouping/ungrouping
  # of modules from the original verilog, or for sue demorgan cell removal.

  set vgfile $dir/$cell.vg
  catch {file delete -force $vgfile}
  foreach subcell [concat $hier_defs $cell] {
    # nl_write_verilog currently closes the file for you,
    # so have to do this:
    set fd [open $vgfile "a"]
    set submod [fplan_db_cell module $subcell]
    nlt_log {nl_write_verilog $fd $submod}
    catch {close $fd}  ;# catch in case nl closed it.
  }

  # Write the input file for synopsys placer.
  set fd [open $dir/$cell.psyn_in "w"]

  puts $fd "set target_library $db"
  puts $fd "set physical_library $pdb"
  puts $fd "set link_library {\"*\" $db}"
  puts $fd "set physopt_set_max_placement_density 1.0"
  puts $fd "set hdlin_dont_post_process true"

  puts $fd "read_verilog $vgfile"

  #foreach subcell [concat $cell $hier_defs] {
  #  set submod [fplan_db_cell module $subcell]
  #  puts $fd "set current_design $submod"
  #  puts $fd "read_pdef $dir/$subcell.pdef"
  #}

  puts $fd "set current_design $mod"
  puts $fd "read_pdef $dir/$cell.pdef"

  puts $fd "link"
  puts $fd "uniquify"

  puts $fd "set current_design $mod"
  foreach cell_info [db_search_l cells -cell $cell] {
    struct max_cell c $cell_info
    if {[fplan_cell_info -is_hier ${c.def}]} {
      set modi [fplan_db_cell celli2modi ${c.id}]
      # The -name is just for informational purposes.
      puts $fd "create_obstruction -placement \
      -name ${c.id}_obstruction \
      -coordinate {${c.x1} ${c.y1} ${c.x2} ${c.y2}}"

      # This doesnt seem to do anything.
      # Maybe all the cells need to be in the alu8.def
      #puts $fd "set_dont_touch_placement $modi"
      puts $fd "set_dont_touch_placement \[get_cells $modi/*\]"
      puts $fd "set_dont_touch \[get_cells $modi/*\]"
    }
  }
  #puts $fd {report_attribute [get_cells alu8]}
  #puts $fd {report_attribute [get_cells adder8]}

  #puts $fd "$weights"
  # physopt - does synthesys too.
  # compile_physical - use for RTL.
  puts $fd "create_placement -effort high"
  puts $fd "legalize_placement"
  puts $fd "write -f db -hier -o $dir/$cell.out.db"
  puts $fd "exit"
  close $fd


#  msg_run fplan_write_def -cells 2 -blockages 1 $cell $dir/$cell.def
  msg_run fplan_write_def -cells 3 -blockages 1 $cell $dir/$cell.def
  msg_run exec def2pdef -def $dir/$cell.def -pdb $pdb -output $dir/$cell.pdef

  #foreach subcell [concat $cell $hier_defs] {
  #  msg_run fplan_write_def -blockages 1 $subcell $dir/$subcell.def
  #  msg_run exec def2pdef -def $dir/$subcell.def -pdb $pdb -output $dir/$subcell.pdef
  #}


  set outfile $dir/$cell.psyn_out
  if {[catch {msg_run exec psyn_shell -f $dir/$cell.psyn_in > $outfile} stat]} {
    max_error -buffer "Placer exited abnormally.  See file $outfile"
    return
  }

  # Add placer warning/error messages to max errors.
  # The placer messages run on to multiple lines if the following
  # lines begin with a tab.
  set fnd_error 0
  if {[catch {set fd [open $outfile "r"]}]} {
    max_error -buffer "Error: could not open placer output file: $outfile"
    return
  } else {
    set line ""
    while {$line != "" || [gets $fd line] != -1} {
      set lowerline [string tolower $line]
      if {[expr [string first error: $lowerline] >= 0]} {
	set fnd_error 1
      }
      if {[string first warning: $lowerline] >= 0 || \
          [string first error: $lowerline] >= 0} {
        set msg $line
        while {[gets $fd line] != -1 && [string index $line 0] == "\t"} {
          append msg " [string trim $line]"
        }
        max_error -buffer "placer message: $msg"
        continue
      }
      set line ""
    }
    close $fd
  }

  if {$fnd_error} {
    max_error -buffer "Aborting placement update due to errors from psyn"
    return
  }

  msg_run exec db2def5 $dir/$cell.out.db -out $dir/$cell.out.def

  # Suck the placement back in.
  msg_run fplan_read_def -pins 0 -merge 1 -flat 0 $dir/$cell.out.def
}



proc UNUSED_fplan_find_memories {{-inst ""} {mem_list ""} {parent_cell ""}} -desc {
  Find all cells that match mem_list below the inst in parent_cell.
} -doc {
  Procedure returns a list of instance and cell pairs for each memory found.  The
  pairs are both hierarchical paths separated by periods.

  mem_list      contains a list of all memory cells to search for.
  -inst         optional.  if given, then instances is recursively searched.  If not
                then all instances in parent cell are recursively searched.
  parent_cell   parent of inst, or top level cell to be searched if inst not given.
} {

  foreach thingy $__proc_options {
    set option [lindex $thingy 0]
    set _FPLAN_FIND_MEMORIES($option) [set $option]
  }

  if {$_FPLAN_FIND_MEMORIES(inst) != ""} {
    set cell [lindex [split [db_instances_l -cell $parent_cell -id $_FPLAN_FIND_MEMORIES(inst)] " "] 1]
    set inst_cell_list ""
    foreach inst_info [db_instances_l -cell $cell] {
      set subinst [fplan_unfix_name [lindex [split $inst_info " "] 0]]
      set subcell [fplan_unfix_name [lindex [split $inst_info " "] 1]]
      if {[fplan_cell_info -is_hier $subcell]} {
        set subinst_cell_list [_fplan_find_memories -inst $subinst $mem_list $cell]
        foreach {subsubinst subsubcell} $subinst_cell_list {
          set inst_cell_list "$inst_cell_list ${inst}[nlt_hier_char]${subsubinst} ${cell}[nlt_hier_char]$subsubcell"
        }
      } elseif {[lsearch -exact $mem_list $subcell] != -1} { 
        set inst_cell_list "$inst_cell_list ${inst}[nlt_hier_char]${subinst} ${cell}[nlt_hier_char]$subcell"
      }
    }
  } else {
    set inst_cell_list ""
    foreach inst_info [db_instances_l -cell $parent_cell] {
      set subinst [fplan_unfix_name [lindex [split $inst_info " "] 0]]
      set subcell [fplan_unfix_name [lindex [split $inst_info " "] 1]]
      if {[fplan_cell_info -is_hier $subcell]} {
        set subinst_list [_fplan_find_memories -inst $subinst $mem_list $parent_cell]
        foreach {subsubinst subsubcell} $subinst_list {
          set inst_cell_list "$inst_cell_list ${subsubinst} $subsubcell"
        }
      } elseif {[lsearch -exact $mem_list $subcell] != -1} {
        set inst_cell_list "$inst_cell_list ${subinst} $subcell"
      }
    }
  }

  return $inst_cell_list
}     
       

proc _fplan_find_fixed_inst {{-inst ""} {mem_list ""} {parent_cell ""}} -desc {
  Find all cells that match mem_list below the inst in parent_cell.
} -doc {
  Procedure returns a list of instance and cell pairs for each memory found.  The
  pairs are both hierarchical paths separated by periods.

  mem_list      contains a list of all memory cells to search for.
  -inst         optional.  if given, then instance is recursively searched.  If not
                then all instances in parent cell are recursively searched.
  parent_cell   parent of inst, or top level cell to be searched if inst not given.
} {

  foreach thingy $__proc_options {
    set option [lindex $thingy 0]
    set _FPLAN_FIND_FIXED_INST($option) [set $option]
  }

  if {$_FPLAN_FIND_FIXED_INST(inst) != ""} {
    set cell [lindex [split [db_instances_l -cell $parent_cell -id [fplan_fix_name $_FPLAN_FIND_FIXED_INST(inst)]] " "] 1]
    set inst_cell_list ""
    foreach inst_info [db_instances_l -cell $cell] {
      set subinst [fplan_unfix_name [lindex [split $inst_info " "] 0]]
      set subcell [fplan_unfix_name [lindex [split $inst_info " "] 1]]
      if {[fplan_cell_info -is_hier $subcell]} {
        set subinst_cell_list [_fplan_find_fixed_inst -inst $subinst $mem_list $cell]
        foreach {subsubinst subsubcell} $subinst_cell_list {
          set inst_cell_list "$inst_cell_list ${inst}[nlt_hier_char]${subsubinst} ${cell}[nlt_hier_char]$subsubcell"
        }
      } elseif {[fplan_db_inst -cell $parent_cell getprop [fplan_fix_name $subinst] place] == "fixed"} {
        set inst_cell_list "$inst_cell_list ${inst}[nlt_hier_char]${subinst} ${cell}[nlt_hier_char]$subcell"
      }
    }
  } else {
    set inst_cell_list ""
    foreach inst_info [db_instances_l -cell $parent_cell] {
      set subinst [fplan_unfix_name [lindex [split $inst_info " "] 0]]
      set subcell [fplan_unfix_name [lindex [split $inst_info " "] 1]]
      if {[fplan_cell_info -is_hier $subcell]} {
        set subinst_list [_fplan_find_fixed_inst -inst $subinst $mem_list $parent_cell]
        foreach {subsubinst subsubcell} $subinst_list {
          set inst_cell_list "$inst_cell_list ${subsubinst} $subsubcell"
        }
      } elseif {[fplan_db_inst -cell $parent_cell getprop [fplan_fix_name $subinst] place] == "fixed"} {
        set inst_cell_list "$inst_cell_list ${subinst} $subcell"
      }
    }
  }

  return $inst_cell_list
}     
       

proc _fplan_physopt_run {script_file temp_file_name} {

  global _FPLAN_PLACE_IT

  puts $script_file "proc physopt_run {command} {"
  puts $script_file ""
  puts $script_file "  set max_cnt $_FPLAN_PLACE_IT(max_wait_cnt)"
  puts $script_file "  set wait [expr $_FPLAN_PLACE_IT(wait_time) * 1000]"
  puts $script_file "  set license_exit $_FPLAN_PLACE_IT(license_exit)"
  puts $script_file "  set cnt 0"
  puts $script_file ""
  puts $script_file "  # evaluate command"
  puts $script_file "  eval \$command > $temp_file_name"
  puts $script_file ""
  puts $script_file "  # load command output into message"
  puts $script_file "  set fd \[open $temp_file_name \"r\"\]"
  puts $script_file "  set message \"\""
  puts $script_file "  while {\[gets \$fd line\] != -1} {"
  puts $script_file "    lappend message \$line"
  puts $script_file "  }"
  puts $script_file "  close \$fd"
  puts $script_file ""
  puts $script_file "  while {\$cnt < \$max_cnt} {"
  puts $script_file ""
  puts $script_file "    # if command status 0, then it failed."
  puts $script_file "    if {! \[lindex \$message end\]} {"
  puts $script_file ""
  puts $script_file "      # if command output had SEC-50, then it was a license failure."
  puts $script_file "      # if license failure, then print warning and wait, else, print"
  puts $script_file "      # failure message and exit."
  puts $script_file "      if {\[regexp {PhysOpt.* license.*SEC-50} \[lindex \$message 0\]\]} {"
  puts $script_file ""
  puts $script_file "        # exit imediately if license_exit is set"
  puts $script_file "        if {\$license_exit} {"
  puts $script_file "          puts \"Aborting psyn_shell script.\""
  puts $script_file "          foreach line \$message {"
  puts $script_file "            puts \"\$line\""
  puts $script_file "          }"
  puts $script_file "          exit 1"
  puts $script_file "        }"
  puts $script_file ""
  puts $script_file "        # print warning on first pass"
  puts $script_file "        if {\$cnt == 0} {"
  puts $script_file "          puts \"Warning: All \'PhysOpt\' licenses are in use. {SEC-50}\""
  puts $script_file "          puts \[lindex \$message 1\]"
  puts $script_file "          puts \[lindex \$message 2\]"
  puts $script_file "          puts \"Waiting for license...\""
  puts $script_file "        } else {"
  puts $script_file "          puts \"Waiting for license \[expr \$cnt * \$wait / 1000\] sec\""
  puts $script_file "        }"
  puts $script_file "        after \$wait"
  puts $script_file "        if {\$cnt >= \[expr \$max_cnt - 1\]} {"
  puts $script_file "          puts \"Maximum wait time of \[expr \$max_cnt * \$wait / 1000\] sec exceeded.\""
  puts $script_file "          puts \"Aborting psyn_shell script.\""
  puts $script_file "          foreach line \$message {"
  puts $script_file "            puts \"\$line\""
  puts $script_file "          }"
  puts $script_file "          exit 1"
  puts $script_file "        } else {"
  puts $script_file "          eval \$command > $temp_file_name"
  puts $script_file "          set fd \[open $temp_file_name \"r\"\]"
  puts $script_file "          set message \"\""
  puts $script_file "          while {\[gets \$fd line\] != -1} {"
  puts $script_file "            lappend message \$line"
  puts $script_file "          }"
  puts $script_file "          close \$fd"
  puts $script_file "        }"
  puts $script_file "        incr cnt"
  puts $script_file "      } else {"
  puts $script_file ""
  puts $script_file "        # command failed for reason other than license"
  puts $script_file "        foreach line \$message {"
  puts $script_file "          puts \"\$line\""
  puts $script_file "        }"
  puts $script_file "        set cnt \$max_cnt"
  puts $script_file "      }"
  puts $script_file "    } else {"
  puts $script_file ""
  puts $script_file "      # command passed"
  puts $script_file "      set cnt \$max_cnt"
  puts $script_file "      foreach line \$message {"
  puts $script_file "        puts \"\$line\""
  puts $script_file "      }"
  puts $script_file "    }"
  puts $script_file "  }"
  puts $script_file "}"
}


proc fplan_place_it {{-submod 0} {-timing low} {-congest none} {-function physopt} \
                     {-coarse 0} {-incremental 0} {-limit_x 80} {-limit_y 80} \
		     {-flat 1} {cell ""}}  -desc {
  Place specified cell using physopt.
} -doc {
  -granularity  Determines whether a lgalization pass is made after the initial coarse
  		placement pass.  Set to 0 for legalization pass, or 1 for coarse placement 
		only.  In the furure it could determine if an incremental pass is made, 
		or perhaps this switch should go away and timing and congestion directive 
		could be given for each pass: coarse, legal, and incremental.

  -flat    	Flat placement removes all hierarchical constraints  from the placement 
           	attempt.  This gives the placement engine (physopt) full freedom put any 
	   	unplaced cell anywhere in the cell prb layer.

  -timing	Sets -effort level to low, medium, or high during all placement steps.

  -congestion	Sets -congestion_effort level to low, medium, or high during all placement 
  		steps.

  -submod       used only for internal calls of fplan_place_it.

  If both timing and congestion are set to high, the flag -timing_driven_congestion is 
  set insted of either timing or congestion.

} {
  global env MN_TECH FPLAN TIMING_DATA _FPLAN_PLACE_IT

  # if license_exit is zero, psyn_shell job will attempt to get a physopt 
  # license every wait_time minutes.  It will attempt it for max_wait_cnt 
  # attempts, then it will fail if license isn't aquired.  
  # if license_exit is 1, the job will fail if the license isn't availible
  # on the first pass through.
  set _FPLAN_PLACE_IT(wait_time) 600 ;		# 10 minutes
  set _FPLAN_PLACE_IT(max_wait_cnt) 144 ; 	# times 10 minutes is 24 hours
  set _FPLAN_PLACE_IT(license_exit) 0

  if {$cell == ""} {
    # Show interactive menu.  Init options to defaults on first pass.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      use_init _FPLAN_PLACE_IT($option) [set $option]
    }

    # There are 3 basic psyn_shell functions: physopt, create, legalize.  Any 
    # of these could be used with the an incremental flag.  
    # 
    # Additionally, the create placement step could be executed with in coarse 
    # mode.  This is not a psyn_shell mode, rather it alters the input files 
    # generated for psyn_shell.  In this mode only ports that are fixed are 
    # passed to psyn_shell.  The rest are removed.  Since physopt will remove
    # any cells that don't drive logic or ports, only placements can be done 
    # in this mode.  This mode is not compatable with the incremental flag.
    # OK, THIS IS NOT TRUE.  The value physopt_delete_unloaded_cells set to
    # "false" should prevent this.  Then we can add the ports back on once the 
    # run is complete.
    #
    # Generate menu for placement result quality and hierarchy.
    set prop_list ""
    lappend prop_list [list "Function" _FPLAN_PLACE_IT(function) -radio [list \
      "physopt" \
      "create_placement" \
      "legalize_placement" \
      "none"] -values {physopt create_placement legalize_placement none}]
    lappend prop_list [list "Coarse" _FPLAN_PLACE_IT(coarse) -binary]
    lappend prop_list [list "Incremental" _FPLAN_PLACE_IT(incremental) -binary]

    set title "Place It"
    if {![prop_menu2 -title $title $prop_list]} {
      return ;# cancelled
    }

    set cell [lay_editcell]
    set interactive "true"

  } {
    # Non-interactive.  Set _FPLAN_PLACE_IT from command line options.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      set _FPLAN_PLACE_IT($option) [set $option]
    }

    set interactive "false"

  }

  proc _fplan_run {args} {
    msg "$args\n"
    return [eval $args]
  }

  set mod [fplan_db_cell module $cell]
  set cnt 0
  set sub_dir ""
  if {$_FPLAN_PLACE_IT(submod)} {
    set sub_dir "$cell\."
  }
  while {([file isdirectory place_it.${sub_dir}${cnt}]) || \
         ([file isdirectory place_it.${sub_dir}${cnt}.incr])} {
    incr cnt
  }
  set dir place_it.${sub_dir}${cnt}
  if {$_FPLAN_PLACE_IT(incremental) == 1} {
    regexp {^(.*)\.[0-9]+$} $dir junk incr_dir
    set incr_dir "${incr_dir}.[expr $cnt - 1]"

    set incr_def_file $incr_dir/$cell.def
    set incr_vg_file $incr_dir/$cell.vg

    set dir ${dir}.incr
    if {![file isdirectory $incr_dir]} {
      error "Incremental source directory $incr_dir doesn't exist"
      return
    }
    if {![file exists $incr_def_file]} {
      error "Incremental source file $incr_def_file doesn't exist"
      return
    }
    if {![file exists $incr_vg_file]} {
      error "Incremental source file $incr_vg_file doesn't exist"
      return
    }
  }

  catch {file mkdir $dir}
  if {![file isdirectory $dir]} {
    error "Can not create directory $dir"
    return
  }

  if {! $_FPLAN_PLACE_IT(submod)} {
    fplan_write_props -filename $dir/$cell.etc $cell

    # get incremental verilog and placement if incremental set
    if {$_FPLAN_PLACE_IT(incremental) == 1} {
      cell_delete
      _fplan_run fplan_read_verilog $incr_vg_file
      _fplan_run fplan_import_verilog $cell
      _fplan_run fplan_read_def -pins 1 -merge 0 -flat 2 $incr_def_file

      # read props just incase they need to be used later in proc.
      fplan_read_props $dir/$cell.etc
    }
  }

  # hier_defs -			list of all hierarchical cells in current cell.
  #
  # hier_insts -	 	list of all hierarchical instances in current cell.  The
  #				user is given the opportunity to flatten or retain the 
  #				hierarchy an each of these instances.  Any retained 
  #				instance hierarchy will take on the placement method 
  #				selected for the associated module.
  # 
  # inst_flat -			array of flatten decision for each of the instances in 
  #				hier_insts.  Value is set to 1 for flatten, and 0 for 
  #				retain hierarchy.
  #
  # hier_insts_keep -		list of any hierarchical instances that were not set to 
  #				flat in the inst_flat array.
  #
  # hier_insts_x -		array of x coordinates for any hierarchical instances 
  #				that are in hier_insts_keep list.
  #
  # hier_insts_y -		array of y coordinates for any hierarchical instances 
  #				that are in hier_insts_keep list.
  #
  # hier_defs_keep -		list of any hierarchical defs with associated instances 
  #				listed in hier_insts_keep.
  #
  # subcell_place_src -		array of placement sources decisions for each of the 
  #				cells listed in hier_defs_keep.  Current source options 
  #				are the def file place_it/cell_name.out.def, existing 
  #				max placement, or a new physopt placement.
  #
  # subcell_place_obstr -	array of obstruction decisions for each of the cells 
  #				listed in hier_defs_keep.
  #
  # subcell_place_time -	array of timing effort decisions for each of the cells 
  #				listed in hier_defs_keep with a subcell_place_src entry 
  #				set to "new".
  #
  # subcell_place_cong -	array of congestion effort decisions for each of the cells 
  #				listed in hier_defs_keep with a subcell_place_src entry 
  #				set to "new".
  set hier_defs ""
  set hier_insts ""
  set hier_defs_keep ""
  set hier_insts_keep ""
  set hier_insts_flatten ""

  if {$interactive == "true"} {

    # Make a list of the hierarchical subcells in cell.
    foreach subcell [db_kids $cell] {
      if {[fplan_cell_info -is_hier $subcell]} {
        lappend hier_defs $subcell
	set _FPLAN_PLACE_IT(flat) 0
      }
    }

    if {!$_FPLAN_PLACE_IT(flat)} {

      foreach subcell [lsort $hier_defs] {
        set submod [fplan_db_cell module $subcell]
        foreach instance_info [db_instances_l -of $subcell] {
	  set inst [lindex [split $instance_info " "] 0]
          lappend hier_insts $inst
	  set inst_status [fplan_db_inst getprop $inst place]
	  set inst_flat($inst) 0
	  if {$inst_status != "fixed"} {
	    set inst_flat($inst) 1
	    set inst_status flatten
	  }
        }
      }

      # If hier cells exist, query user about flattening, otherwise error out.
      if {[llength $hier_defs]} {

        # If keep hierarchy is selected for any submodule, build list of modules 
        # which will be retained in top current hierarchy.  Also generate property 
        # list to query user for submodule placement source.
        foreach inst [array names inst_flat] {
      	  set submod [lindex [split [db_instances_l -id $inst]] 1]
	  if {!$inst_flat($inst)} {
      	    lappend hier_insts_keep $inst
	    # flattening is selected based on instances, so only append defs to list once.
	    if {[lsearch -exact $hier_defs_keep $submod] == -1} {
      	      lappend hier_defs_keep $submod
              fplan_write_props -filename $dir/$submod.etc $submod
	    }
	  } else {
            lappend hier_insts_flatten $inst
	  }
        }

        # Generate summary report for placement directives of current cell and any 
        # sub cell selected for new placement.
        set cell_timing [db_prop -def $cell timing_effort]
        if {$cell_timing != ""} {
          set _FPLAN_PLACE_IT(timing) $cell_timing
        }
        set cell_congestion [db_prop -def $cell congestion_effort]
        if {$cell_congestion != ""} {
          set _FPLAN_PLACE_IT(congest) $cell_congestion
        }
        set cell_limit_x [db_prop -def $cell place_wire_obstruct_x]
        if {$cell_limit_x != ""} {
          set _FPLAN_PLACE_IT(limit_x) $cell_limit_x
        }
        set cell_limit_y [db_prop -def $cell place_wire_obstruct_y]
        if {$cell_limit_y != ""} {
          set _FPLAN_PLACE_IT(limit_y) $cell_limit_y
        }
        foreach subcell $hier_defs_keep {
          set subcell_place_time($subcell) medium
          set subcell_timing [db_prop -def $subcell timing_effort]
          if {$subcell_timing != ""} {
            set subcell_place_time($subcell) $subcell_timing
          }
          set subcell_place_cong($subcell) low
          set subcell_congestion [db_prop -def $subcell congestion_effort]
          if {$subcell_congestion != ""} {
            set subcell_place_cong($subcell) $subcell_congestion
          }
          set subcell_place_obstr($subcell) 0
          set subcell_obstruction [db_prop -def $subcell place_obstruct_parent]
          if {$subcell_obstruction == "yes"} {
            set subcell_place_obstr($subcell) 1
          } else {
            set subcell_obstruction "no"
          }
          set subcell_place_limit_x($subcell) 80
          set subcell_limit_x [db_prop -def $subcell place_wire_obstruct_x]
          if {$subcell_limit_x != ""} {
            set subcell_place_limit_x($subcell) $subcell_limit_x
          }
          set subcell_place_limit_y($subcell) 80
          set subcell_limit_y [db_prop -def $subcell place_wire_obstruct_y]
          if {$subcell_limit_y != ""} {
            set subcell_place_limit_y($subcell) $subcell_limit_y
          }
        }
      }

    } else {

      # Flat Placement.

      foreach subcell [db_kids $cell] {
        if {[fplan_cell_info -is_hier $subcell]} {
          foreach instance_info [db_instances_l -of $subcell] {
            set inst [lindex [split $instance_info " "] 0]
            lappend hier_insts_flatten $inst
	  }
        }
      }

      set cell_timing [db_prop -def $cell timing_effort]
      if {$cell_timing != ""} {
        set _FPLAN_PLACE_IT(timing) $cell_timing
      }
      set cell_congestion [db_prop -def $cell congestion_effort]
      if {$cell_congestion != ""} {
        set _FPLAN_PLACE_IT(congest) $cell_congestion
      }
      set cell_limit_x [db_prop -def $cell place_wire_obstruct_x]
      if {$cell_limit_x != ""} {
        set _FPLAN_PLACE_IT(limit_x) $cell_limit_x
      }
      set cell_limit_y [db_prop -def $cell place_wire_obstruct_y]
      if {$cell_limit_y != ""} {
        set _FPLAN_PLACE_IT(limit_y) $cell_limit_y
      }
    }
  } else {

    # Flat Placement only supported for non interactive for the moment.  Hierarchical 
    # non interactive to follow shortly.
    foreach subcell [db_kids $cell] {
      if {[fplan_cell_info -is_hier $subcell]} {
        foreach instance_info [db_instances_l -cell $cell -of $subcell] {
          set inst [lindex [split $instance_info " "] 0]
          lappend hier_insts_flatten $inst
        }
      }
    }

  }

  # The RA and SRAM memories require special handling by physopt due to there large size.  The 
  # following code hierarchically searches the design to locate RA and SRAM cells, and builds 
  # a list of them.  Each memory found generates 2 list entries, a hierarchical instance path 
  # and a hierarchical cell path.  These 2 paths are used to query the user for directives as 
  # to how to place each memory, and then to actually palce the memories.
  #
  # A list of all available memory lefs is automatically generated by the Makefile used to 
  # generate sizes, ports and full lef files.  This list is used to compare with lef cells in 
  # the design to identify memory cells.

  set mem_hier_inst_list ""
  if {! $_FPLAN_PLACE_IT(submod)} {
    # get list of all memory lefs
    set mem_cells ""
  
    # Find RA's and SRAM's in design.
    set mem_inst_cell_list [_fplan_find_fixed_inst $mem_cells $cell]
  
    # mem_cells	 	 list of all available memory lefs read from techname.mem file.  file 
    #			 is generated by Makefile in lefs directory by greping tachname.ports.lefs
    #			 dircetly.  design lefs are recognized by searching for them in this list.
    # mem_inst_cell_list list of all found memories in the design.  Each memory has a pair of 
    #			 entries in the list, the first is a hierarchical instance name, and the 
    #			 second is a hierarchical path name.
    # mem_hier_inst_list list of all hierarchical instances names found in mem_inst_cell_list.
    # mem_hier_cell	 array of hierarchical cell names for each hierarchical instance name.
    # mem_x		 array of x coordinates for each hierarchical instance name.
    # mem_y		 array of y coordinates for each hierarchical instance name.
    # mem_top_inst	 array of top level instance in hierarchical path for each hierarchical 
    #			 instance.
    # mem_status	 array of placement status for each hierarchical instance name.  PLACED
    #			 actually floats, while FIXED is fixed.
    # mem_flat_name	 array of flat placement names for all hierarchical instances whose 
    #			 mem_top_inst has been slected for flattening.
    #
    foreach {hier_inst hier_cell} $mem_inst_cell_list {
  
      # load memory array values
      lappend mem_hier_inst_list $hier_inst
      set mem_hier_cell($hier_inst) $hier_cell
      set mem_x($hier_inst) 0
      set mem_y($hier_inst) 0
      set mem_top_inst($hier_inst) ""
      if {! [regexp {^([A-Za-z0-9_]+)\..*$} $hier_inst full_match mem_top_inst($hier_inst)]} {
        set mem_top_inst($hier_inst) $cell
      }
      set mem_bot_inst($hier_inst) ""
      if {! [regexp {^.*\.([A-Za-z0-9_]+)$} $hier_inst full_match mem_bot_inst($hier_inst)]} {
        set mem_bot_inst($hier_inst) $hier_inst
      }
  
      set child_hier_inst $hier_inst
      set child_hier_cell $mem_hier_cell($hier_inst)
      set parent_cell $cell
      while {[regexp {^([A-Za-z0-9_]+)\.(.*)$} $child_hier_inst full_match current_inst child_hier_inst]} {
        setl {dx dy} [lrange [split [db_instances_l -cell $parent_cell -id [fplan_fix_name $current_inst]] " "] 2 3 ]
        set mem_x($hier_inst) [expr $mem_x($hier_inst) + $dx]
        set mem_y($hier_inst) [expr $mem_y($hier_inst) + $dy]
        regexp {^([A-Za-z0-9_]+)\.(.*)$} $child_hier_cell full_match parent_cell child_hier_cell
      }
      set current_inst $child_hier_inst
      set mem_cell($hier_inst) $child_hier_cell
      setl {dx dy} [lrange [split [db_instances_l -cell $parent_cell -id [fplan_fix_name $current_inst]] " "] 2 3 ]
      set mem_x($hier_inst) [expr $mem_x($hier_inst) + $dx]
      set mem_y($hier_inst) [expr $mem_y($hier_inst) + $dy]
    }  
  
    # There are currently 3 cases.  memories top parent was flattened, memory is already 
    # at the top, or memories top parent wasn't flattened and exists as a direct child 
    # of the top cell.  There may or may not have been hierarchy between the memory and 
    # its top parent.
    foreach mem_inst [lsort $mem_hier_inst_list] {
      if {[lsearch $hier_insts_flatten $mem_top_inst($mem_inst)] != -1} {
        set mem_flat_name($mem_inst) $mem_inst
        while {[regexp {^([A-Za-z0-9_]+)\.(.*)$} $mem_flat_name($mem_inst) full_match parent_inst child_inst]} {
          set mem_flat_name($mem_inst) "${parent_inst}_${child_inst}"
        }
      } elseif {"$mem_top_inst($mem_inst)" == "$cell"} {
        set mem_flat_name($mem_inst) $mem_inst
      } else {
        regexp {^([A-Za-z0-9_]+)\.(.*)$} $mem_inst full_match parent_inst child_inst
        set mem_flat_name($mem_inst) "${parent_inst}/${child_inst}"
        while {[regexp {^([A-Za-z0-9_]+)\.(.*)$} $mem_flat_name($mem_inst) full_match parent_inst child_inst]} {
          set mem_flat_name($mem_inst) "${parent_inst}_${child_inst}"
        }
      }
      set mem_status($mem_inst) [fplan_db_inst -cell [lindex [split [db_instances_l -id $mem_top_inst($mem_inst)] " "] 1] \
                              getprop [fplan_fix_name $mem_bot_inst($mem_inst)] place]
      if {$mem_status($mem_inst) == ""} {
        set mem_status($mem_inst) placed
      }
    }
  }

  # Concat is needed since Lee requires this to be a 2 item list.  The 
  # first item is the standard cell lib and the second is a list of the
  # other libs.
#  set db [concat [lindex $TIMING_DATA(syn_libdb) 0] [lindex $TIMING_DATA(syn_libdb) 1]]
  set db [lindex $TIMING_DATA(syn_libdb) 0]

  # Writting the initial def foot print doesn't require any cells for the
  # moment, and keeping the header separate makes it much faster.
  set pdb_header $FPLAN(pdb_header_file)
#  set pdb "$pdb_header $FPLAN(pdb_cells_file)"
  set pdb "$pdb_header [lindex $FPLAN(pdb_cells_file) 0]"


  # Hierarchical module placement.
  # 
  set reload_top 0
  foreach subcell $hier_defs_keep {
    foreach option [array names _FPLAN_PLACE_IT] {
      set temp_fplan_place_it($option) $_FPLAN_PLACE_IT($option)
    }
    _fplan_run fplan_place_it -submod 1 -timing $subcell_place_time($subcell) \
       -limit_x $subcell_place_limit_x($subcell) -limit_y $subcell_place_limit_y($subcell) \
       -congest $subcell_place_cong($subcell) -function $_FPLAN_PLACE_IT(function) \
       -coarse $_FPLAN_PLACE_IT(coarse) -incremental $_FPLAN_PLACE_IT(incremental) -flat 1 $subcell
    foreach option [array names _FPLAN_PLACE_IT] {
      set _FPLAN_PLACE_IT($option) $temp_fplan_place_it($option)
    }
    set reload_top 1
  }
  if {$reload_top} {
    cell_load $cell
    nlt_log {nl_link $cell}
  }

  set max_out_vg_file $dir/$cell.psyn_in.vg

  set nl_in_pre_vg_file $dir/$cell.nl_in_pre.vg

  set def2pdef_in_file $dir/$cell.def2pdef_in.def

  set psyn_in_vg_file $dir/$cell.psyn_in.vg
  set psyn_in_pdef_file $dir/$cell.psyn_in.pdef

  set psyn_out_vg_file $dir/$cell.vg

  set nl_in_post_vg_file $dir/$cell.nl_in_post.vg

  set placed_vg_file $dir/$cell.vg
  set placed_db_file $dir/$cell.db
  set placed_def_file $dir/$cell.def

  # Write the verilog file.  Need only the modules of interest to us.
  # Note that the verilog might have changed due to grouping/ungrouping
  # of modules from the original verilog, or for sue demorgan cell removal.
  set fd [open $max_out_vg_file "w"]
  nlt_log {nl_write_verilog -hierarchy $fd $cell}
  catch {close $fd}  ;# catch in case nl closed it.


  # Write the input file for synopsys placer.
  set fd [open $dir/$cell.psyn_in "w"]

  if {$_FPLAN_PLACE_IT(function) == "none"} {
    set psyn_comment "# "
  } else {
    set psyn_comment ""
  }

  # write the physopt license handler routine into script file.
  _fplan_physopt_run $fd $dir/$cell.psyn_temp

  puts $fd "${psyn_comment}physopt_run \"get_license PhysOpt\""

  puts $fd "# suppress ideal net message UID-406"
  puts $fd "# suppress port driver design rule message UID-401"
  puts $fd "# suppress verilog assign written out message VO-4"
  puts $fd "# suppress linking logical to physical library message PSYN-036"
  puts $fd "suppress_message \"UID-406 UID-401 VO-4 PSYN-036\""
  puts $fd "set target_library \"$TIMING_DATA(target_lib)\" "
  puts $fd "set physical_library \"$pdb\" "
  puts $fd "set link_library {\"*\" $db}"
  puts $fd "set physopt_set_max_placement_density 1.0"
  puts $fd "set hdlin_dont_post_process true"

  puts $fd "read_file -f verilog $psyn_in_vg_file"
  puts $fd "set current_design $mod"

  puts $fd "${psyn_comment}read_pdef $psyn_in_pdef_file"

  puts $fd "link"
  puts $fd "uniquify"

  # set dont touches on fixed memories.
  foreach mem_inst $mem_hier_inst_list {
    if {$mem_status($mem_inst) == "fixed"} {
      if {[lsearch $hier_insts_flatten $mem_top_inst($mem_inst)] == -1} {
        set mem_name $mem_inst
        while {[regexp {^([A-Za-z0-9_/]+)\.(.*)$} $mem_name full_match parent_inst child_inst]} {
          set mem_name "${parent_inst}/${child_inst}"
        }
      } else {
        set mem_name $mem_flat_name($mem_inst)
      }
      puts $fd "${psyn_comment}set_dont_touch_placement \[get_cells $mem_name\]"
      puts $fd "${psyn_comment}set_dont_touch \[get_cells $mem_name\]"
    }
  }

  foreach inst $hier_insts_keep {
    puts $fd "${psyn_comment}set_dont_touch_placement \[get_cells $inst/*\]"
    puts $fd "${psyn_comment}set_dont_touch \[get_cells $inst/*\]"
  }

  # set congestion limit percentages
  if {($_FPLAN_PLACE_IT(limit_x) != 80) || ($_FPLAN_PLACE_IT(limit_y) != 80)} {
    puts $fd "set_congestion_options -horizontal [expr $_FPLAN_PLACE_IT(limit_x)/100.0] \
      -vertical [expr $_FPLAN_PLACE_IT(limit_y)/100.0]"
  }

  # create obstruction regions for hierarchical instances with obstruct selected.
  foreach subcell [array names subcell_place_obstr] {
    if {$subcell_place_obstr($subcell)} {
      foreach inst_info [db_instances_l -of $subcell] {
        setl {c.id junk c.x1 c.y1 c.x2 c.y2} [lrange [split $inst_info " "] 0 5]
	if {[lsearch -exact $hier_insts_keep ${c.id}] != "-1"} {
	  # Obstructions will effect the prb layer size.
          # The -name is just for informational purposes.
          puts $fd "${psyn_comment}create_obstruction -placement \
            -name ${c.id}_obstruction \
            -coordinate {${c.x1} ${c.y1} ${c.x2} ${c.y2}}"
	}
      }
    }
  }

  set cnt 0
  foreach paintball [db_search_paint -cell $cell pl_obs] {
    set rect [lrange $paintball 1 4]
    puts $fd "${psyn_comment}create_obstruction -placement -name pl_obs_${cnt} -coordinate \{$rect\}"
    incr cnt
  }
  set metal_layers "m1 m2 m3 m4 m5 mq lm"
  foreach layer $metal_layers {
    foreach paintball [db_search_paint -cell $cell ${layer}_obs] {
      set rect [lrange $paintball 1 4]
      puts $fd "${psyn_comment}create_obstruction -layer $FPLAN(${layer}_obs_name) -name ${layer}_obs_${cnt} -coordinate \{$rect\}"
      incr cnt
    }
  }

  # Set io constraints.
  #
  # If the clk_name is not a pin on the current cell, create_clock 
  # shouldn't be output.  
  set psyn_clkopt ""
  set psyn_ideal_nets ""
  foreach port [fplan_db_pin_list -cell $cell] {
    set port_status [fplan_db_pin -cell $cell getprop $port place]
    if {$TIMING_DATA(clk_names) == "$port"} {
      set psyn_clk_period [expr [parse_pp_number $TIMING_DATA(clk_period)]/[parse_pp_number 1ns]]
      puts $fd "create_clock -period $psyn_clk_period $port"
      puts $fd "set_ideal_net $port"
      set psyn_clkopt "-clock $port"
      lappend psyn_ideal_nets $port
    } elseif {($port_status != "fixed") && $_FPLAN_PLACE_IT(coarse)} {
      puts $fd "set_ideal_net $port"
      lappend psyn_ideal_nets $port
    }
  }

  set psyn_default_arrival_time [expr [parse_pp_number $TIMING_DATA(ext_input_budget)]/[parse_pp_number 1ns]]
  set psyn_default_driver_lib "-library $TIMING_DATA(target_lib):$TIMING_DATA(ext_driver_lib)"
  set psyn_default_driver_cell "$psyn_default_driver_lib -cell $TIMING_DATA(ext_driver)"

  set psyn_default_departure_time [expr [parse_pp_number $TIMING_DATA(ext_output_budget)]/[parse_pp_number 1ns]]
  set psyn_default_load [expr [parse_pp_number $TIMING_DATA(ext_cap)]/[parse_pp_number 1fF] / 1000]

  foreach port [fplan_db_pin_list -cell $cell] {
    set pin_dir [lindex [fplan_db_pin2 -cell $cell $port] 2]
    if {[lsearch -exact $psyn_ideal_nets $port] == -1} {
      if {$pin_dir == "input"} {

	set psyn_arrival_time [fplan_db_pin -cell $cell getprop $port ext_budget]
	if {$psyn_arrival_time != ""} {
          puts $fd "set_input_delay $psyn_clkopt [expr [parse_pp_number $psyn_arrival_time]/[parse_pp_number 1ns]] $port"
	} else {
          puts $fd "set_input_delay $psyn_clkopt $psyn_default_arrival_time $port"
	}

	set psyn_driver_cell [fplan_db_pin -cell $cell getprop $port ext_driver]
	if {$psyn_driver_cell != ""} {
	  # TODO: if driver isn't in default lib, then this will fail.
          puts $fd "set_driving_cell $psyn_default_driver_lib -cell $psyn_driver_cell $port"
	} else {
          puts $fd "set_driving_cell $psyn_default_driver_cell $port"
	}

      } elseif {$pin_dir == "output"} {

	set psyn_departure_time [fplan_db_pin -cell $cell getprop $port ext_budget]
	if {$psyn_departure_time != ""} {
          puts $fd "set_output_delay $psyn_clkopt [expr [parse_pp_number $psyn_departure_time]/[parse_pp_number 1ns]] $port"
	} else {
          puts $fd "set_output_delay $psyn_clkopt $psyn_default_departure_time $port"
	}

	set psyn_load [fplan_db_pin -cell $cell getprop $port ext_cap]
	if {$psyn_load != ""} {
          puts $fd "set_load [expr [parse_pp_number $psyn_load]/[parse_pp_number 1fF] / 1000] $port"
	} else {
          puts $fd "set_load $psyn_default_load $port"
	}
      }
    }
  }

  if {$_FPLAN_PLACE_IT(incremental)} {
    set incr_flag "-incremental"
    set congestion_effort_flag ""
  } else {
    set incr_flag ""
    set congestion_effort_flag "-congestion_effort $_FPLAN_PLACE_IT(congest)"
  }
  if {$_FPLAN_PLACE_IT(congest) == "none"} {
    puts $fd "${psyn_comment}$_FPLAN_PLACE_IT(function) -effort $_FPLAN_PLACE_IT(timing) $incr_flag"
  } elseif {($_FPLAN_PLACE_IT(timing) != "high") || ($_FPLAN_PLACE_IT(congest) != "high")} {
    puts $fd "${psyn_comment}$_FPLAN_PLACE_IT(function) -effort $_FPLAN_PLACE_IT(timing) -congestion $congestion_effort_flag $incr_flag"
  } else {
    puts $fd "${psyn_comment}$_FPLAN_PLACE_IT(function) -timing_driven_congestion $incr_flag"
  }

  puts $fd "${psyn_comment}report_timing -nets -trans -physical"
  if {$_FPLAN_PLACE_IT(congest) == "high"} {
    puts $fd "${psyn_comment}report_congestion -congestion_effort high"
  } else {
    puts $fd "${psyn_comment}report_congestion"
  }
  puts $fd "write -f db -hier -o $placed_db_file"
  puts $fd "write -f verilog -hier -o $psyn_out_vg_file"
  puts $fd "exit"
  close $fd


  # Write unplaced def starting point
  _fplan_run fplan_write_def -cells 3 -blockages 0 $cell $def2pdef_in_file

  # run nl pre process script
  if {$_FPLAN_PLACE_IT(coarse)} {
    catch {_fplan_run exec nl_shell < $dir/$cell.nl_in_pre |& tee $dir/$cell.nl_out_pre}
  }

  set pdb_string [join $pdb " -pdb "]
  eval _fplan_run exec [concat def2pdef -def $def2pdef_in_file -pdb $pdb_string -output $psyn_in_pdef_file]

  set outfile $dir/$cell.psyn_out
  _fplan_run exec rsh lnxcomp1 "cd [pwd]; psyn_shell.lnx -f $dir/$cell.psyn_in |& tee $outfile"

  # Add placer warning/error messages to max errors.
  # The placer messages run on to multiple lines if the following
  # lines begin with a tab.
  set fnd_error 0
  if {[catch {set fd [open $outfile "r"]}]} {
    max_error -buffer "Error: could not open placer output file: $outfile"
    return
  } else {
    set line ""
    while {$line != "" || [gets $fd line] != -1} {
      set lowerline [string tolower $line]
      if {[expr [string first error: $lowerline] >= 0]} {
	set fnd_error 1
      }
      if {[string first warning: $lowerline] >= 0 || \
          [string first error: $lowerline] >= 0} {
        set msg $line
        while {[gets $fd line] != -1 && [string index $line 0] == "\t"} {
          append msg " [string trim $line]"
        }
        max_error -buffer "placer message: $msg"
        continue
      }
      set line ""
    }
    close $fd
  }

  if {$fnd_error} {
    max_error -buffer "Aborting placement update due to errors from psyn"
    msg_flush
    return
  }

  if {$_FPLAN_PLACE_IT(function) != "none"} {
    _fplan_run exec db2def5 -components -pins -no_legalize $placed_db_file \
                             -out $placed_def_file |& tee $dir/$cell.db2def_out
  }

  if {! $_FPLAN_PLACE_IT(submod)} {

    cell_delete
    _fplan_run fplan_read_verilog $placed_vg_file
    _fplan_run fplan_import_verilog $cell

    fplan_read_props $dir/$cell.etc
    foreach subcell $hier_defs_keep {
      fplan_read_props $dir/$subcell.etc
    }

    # Suck the placement back in.
    # once the non-hierarchical slash problem is resolved, this if shouldn't be needed.
    # for now, it allowes flat modules with slashes in the names to read correctly.
    if {$_FPLAN_PLACE_IT(function) != "none"} {
      if {$_FPLAN_PLACE_IT(flat)} {
        _fplan_run fplan_read_def -pins 1 -merge 0 -flat 0 $placed_def_file
      } else {
        _fplan_run fplan_read_def -pins 1 -merge 1 -flat 2 $placed_def_file
      }
    }
  } else {

    cell_load $cell
    cell_delete
    _fplan_run fplan_read_verilog $placed_vg_file
    _fplan_run fplan_import_verilog $cell
    if {$_FPLAN_PLACE_IT(function) != "none"} {
      _fplan_run fplan_read_def -pins 1 -merge 0 -flat 2 $placed_def_file
    }
  }
}

