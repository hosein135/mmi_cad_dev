## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
## LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
## CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
## DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
## INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
## 
## JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
## DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
## PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************


# routines to crossprobe verilog schematics.
# Works with either signalscan or simwave, depending on VERILOG_PROBE_TYPE
# Also allows "interactive" single step crossprobing.

# file id of current probe.  This will set to "" if not defined.

set PROBE_ID [use_first PROBE_ID]

set VERILOG_ROOT [use_first VERILOG_ROOT 'test]

# netlist current schematic and then run verilog

proc verilog_it {} {

  global cur_s PROBE_DATA_FILE VERILOG_CMD PROBE_TYPE SUE_DIR NETLIST_TYPE
  global SUE_${cur_s}  

  modify_setup verilog_it

  if {$PROBE_TYPE == "interactive" && [check_probe //]} {
    set button [tk_dialog .verilog_it "Waste Interactive Verilog" \
		    "Close interactive verilog session?" \
		    @$SUE_DIR/sue_icon.xbm 0 {ok} {cancel}]

    if {$button == 1} {
      # user hit the cancel key
      return
    }
    interactive_close_probe
  }

  set netlist_filename [netlist]

  if {$netlist_filename == ""} {
    sue_error "Aborting, can't run verilog due to netlist errors."
    sue_error flush
    return
  }

  set dir [set SUE_${cur_s}(dir)]
  
  # push into directory of toplevel schematic for running verilog
  set save_dir [pwd]
  cd $dir

  puts "\nStarting Verilog on \"$netlist_filename\" ..."
  eval exec $VERILOG_CMD $netlist_filename &

  # return to calling directory
  cd $save_dir
}


# compute the hierarchical verilog net name.

proc verilog_net {{id ""}} {

  global cur_c cur_s NETLIST

  if {$id == ""} {
    set id [lindex [$cur_c find withtag selected] 0]
  }

  if {[is_tagged $id "wire"]} {
    set net [find_verilog_net_name $id]
    return $net
  }

  if {[is_tagged $id "dot"] || [is_tagged $id "open"]} {
    integer_scale
    set net [find_verilog_net_name [center $id]]
    unscale
    return $net
  }

  # check if it's an icon
  set origin_id [find_origin $id]
  if {[is_tagged $origin_id origin]} {
    # find all terminal on this inst
    set terms ""
    foreach id2 [$cur_c find withtag inst$origin_id] {
      if {[is_tagged $id2 "term"]} {
	lappend terms $id2
      }
    }

    if {[llength $terms] == 1} {
      # probably an I/O or global (most instances have more than one term)
      set net [find_verilog_net_name $terms]
      return $net

    } else {
      puts "Can't probe icon."
    }
  }
  return Unknown
}


# finds all the ids of terminals on this net that have names.

proc find_verilog_net_name {id} {

  global cur_c cur_s NETS VERILOG_ROOT NETLIST HIERARCHY _VP_
  upvar #0 TERMS_$cur_s TERMS

  if {[llength id] == 2} {
    # coord, find id
    catch {unset NETS}
    set id [lindex [eval find_terms $id 0] 0]
  }

  if {$id == " "} {
    puts "Aborting, wire is not connected to any terminals.  can't probe."
    return
  }

  generate_term_names

  if {![info exists TERMS($id)]} {
    return ""
  }

  set net $TERMS($id)

  set SEP .

  set path ""
  foreach schematic $HIERARCHY {
    upvar #0 TERMS_[lindex [split $schematic ,] 0] TT

    set inst $TT([lindex [split $schematic ,] 1])
    if {[bus_width $inst] > 1} {

      if {[info exists _VP_($HIERARCHY)]} {
	# use this.  Reset with plot net
	set inst $_VP_($HIERARCHY)

      } else {

	# query user, remember last choice
	set message "Select bit of $inst"
	set title "bit selection"

	set bus $inst
	set list [bus_expand $bus]
	regsub -all {\[|\]} $list \$ list

	set inst [use_first LAST_SPICE_NET_INDEX($bus)]
	if {[lsearch -exact $list $inst] == -1} {
	  # not in this range
	  set inst [lindex $list 0]
	}

	set prop_list [list [list "Which Instance" inst choice $list]]
	# create the menu
	if {![prop_menu2 -message $message -title $title $prop_list]} {
	  # cancelled
	  return ""
	}

	# save for next time
	set LAST_SPICE_NET_INDEX($bus) $inst

	set _VP_($HIERARCHY) $inst
      }
    }

    set path "$inst$SEP$path"
  }

  set cnet ""
  foreach one [split $net ,] {
    if {[string first ' $one] == -1} {
      lappend cnet "$VERILOG_ROOT.$NETLIST(root).$path$one"
    } else {
      # constant, don't add prefix
      lappend cnet $one
    }
  }

  return [join $cnet ,]
}


# open signalscan (>= v. 4) probe window.  If one already exists, kills it first

proc signalscan_init_probe {{options 0}} {
  
  global cur_s NETLIST VERILOG_PROBE PROBE_ID PROBE_DATA_FILE 
  global VERILOG_PROBE_TYPE GEOMETRY

  if {[info exists NETLIST(root)] != 1} {
    sue_error "Aborting, must netlist first before initializing probe."
    sue_error flush
    return
  }

  upvar #0 SUE_$NETLIST(root) data
  set dir $data(dir)

  # push into directory of toplevel schematic 
  set save_dir [pwd]
  cd $dir

  # just set it to verilog.dump for now.
  set PROBE_DATA_FILE verilog.dump

  if {[file isfile $PROBE_DATA_FILE] != 1} {
    # file doesn't exist so abort
    sue_error "Aborting, can't find verilog data file $PROBE_DATA_FILE"
    sue_error flush

    # restore current directory
    cd $save_dir

    return
  }

  if {[check_probe "."]} {
    # already have a probe, must waste it
    puts $PROBE_ID "exit noconfirm"
    puts $PROBE_ID "\n"
    flush $PROBE_ID
  }

  set probe_cmd \
      "[uplevel #0 {eval concat $VERILOG_PROBE_CMD(signalscan)}] $PROBE_DATA_FILE"
  puts "Starting probe $probe_cmd"

  set PROBE_ID [open "|$probe_cmd >& [exec tty]" w]

  if {![check_probe "."]} {
    sue_error "Aborting, can't open signalscan."
    sue_error flush

    # restore current directory
    cd $save_dir

    return 0
  }

  # open the waveform windown
  set geom "[split $GEOMETRY(signalscan) "x+-"] 0 0"
  puts $PROBE_ID \
      "open window waveform geometry [lrange $geom 2 3] [lrange $geom 0 1]"
  flush $PROBE_ID

  catch {puts $PROBE_ID "zoom outfull"}
  catch "flush $PROBE_ID"  

  signalscan_plot_memory

  # restore current directory
  cd $save_dir
}


# quits the signalscan probe application

proc signalscan_close_probe {} {

  global PROBE_ID

  # if its still valid, kill probe
  if {[check_probe "."]} {
    puts $PROBE_ID "exit noconfirm"
    catch "flush $PROBE_ID"
  }
}


# plot waveform of the selected net on signalscan

proc signalscan_plot_net {{net ""}} {

  global PROBE_ID

  # make sure probe is still around
  if {![check_probe "."]} {
    puts "Need to initialize probe"
    return
  }

  if {$net == ""} {
    set net [verilog_net]
  }

  puts "Plotting $net"
  puts $PROBE_ID "add var $net"
  flush $PROBE_ID
    
  return $net
}


proc signalscan_erase_and_plot_memory {} {

  global PROBE_ID

  # make sure probe is still around
  if {![check_probe "."]} {
    puts "Need to initialize probe"
    return
  }

  puts $PROBE_ID "select all"
  puts $PROBE_ID "cut"
  flush $PROBE_ID
    
  signalscan_plot_memory
}


proc signalscan_plot_memory {} {

  global NET_MEMORY

  if {[info exists NET_MEMORY]} {
    foreach net [array names NET_MEMORY] {
      signalscan_plot_net $net
    }
  }
}


proc signalscan_plot_net_and_remember {} {

  global NET_MEMORY

  set net [signalscan_plot_net]
  
  set NET_MEMORY($net) 1

  puts "Remembered net $net"
}


# Unfortunately signalscan does support delete net_name like add net_name.
# Only the selected nets in signalscan can be deleted.  However this is
# still useful since the last thing plotted is selected.

proc signalscan_unplot_net {{net ""}} {

  global PROBE_ID

  # make sure probe is still around
  if {![check_probe "."]} {
    puts "Need to initialize probe"
    return
  }

  if {$net == ""} {
    set net [verilog_net]
  }

  puts "Deleting Last"
# I Wish
#  puts $PROBE_ID "delete $net"
  puts $PROBE_ID "cut"
  flush $PROBE_ID
    
  return $net
}


proc signalscan_unplot_net_and_forget {} {

  global NET_MEMORY

  set net [verilog_net]
  
  catch "unset NET_MEMORY($net)"

  puts "Forgotten net $net"
}


# open simwave probe window.  If one already exists, kills it first
# Note that simwave can be used for both spice or verilog.

proc simwave_init_probe {{options 0}} {
  
  global cur_s NETLIST VERILOG_PROBE PROBE_ID PROBE_DATA_FILE NETLIST_TYPE
  global SPICE_TYPE tmpformat TR0_FORMAT

  if {[info exists NETLIST(root)] != 1} {
    sue_error "Aborting, must netlist first before initializing probe."
    sue_error flush
    return
  }

  upvar #0 SUE_$NETLIST(root) data
  set dir $data(dir)

  # push into directory of toplevel schematic 
  set save_dir [pwd]
  cd $dir

  if {$NETLIST_TYPE == "spice"} {
    # if not defined, assume spice.
    set SPICE_TYPE [use_first SPICE_TYPE 'spice]

    switch $SPICE_TYPE {
      spice {
	set PROBE_DATA_FILE $NETLIST(root).tr0
	set tmpformat "-inputformat hspice"
      }
      adm {
	set PROBE_DATA_FILE $NETLIST(root).xp
	set tmpformat "-inputformat hspice"
      }
      powermill {
	set PROBE_DATA_FILE $NETLIST(root).out
	set tmpformat "-inputformat epic"
      }
      default {
	 warning "Aborting, Invalid simulator type \"$SPICE_TYPE\".  This type is not supported by simwave."
         return
      }
    }

    if {$SPICE_TYPE != "powermill"} {
      # figure out the format of the tr0 file
      # NOTE: this is bad for the case of the last tr0 file having a different
      # format than the new one -- pretty rare.
      if {![catch "open $PROBE_DATA_FILE r" tmp_id]} {
	# look for format
	read $tmp_id 16
	read $tmp_id 16
	set format [read $tmp_id 4]

	if {$format == "9601" || $format == "9007"} {
	  set TR0_FORMAT $format
	  puts "$PROBE_DATA_FILE is $format format"
	}

	close $tmp_id
      }

      # use format of last file, default to 9601
      set TR0_FORMAT [use_first TR0_FORMAT '9601]
    }

  } else {
    # just set it to verilog.dump for now.
    set PROBE_DATA_FILE verilog.dump
  }

  if {[file isfile $PROBE_DATA_FILE] != 1} {
    # file doesn't exist so abort
    sue_error "Aborting, can't find $NETLIST_TYPE data file $PROBE_DATA_FILE"
    sue_error flush

    # restore current directory
    cd $save_dir

    return
  }

  # needs to do this twice for some reason
  check_probe
  if {[check_probe]} {
    # already have a probe, must waste it
    puts $PROBE_ID "quit"
    catch "flush $PROBE_ID"
  }

  if {$NETLIST_TYPE == "spice"} {
    set probe_cmd \
	"[uplevel #0 {eval concat $SPICE_PROBE_CMD(simwave) $tmpformat $PROBE_DATA_FILE}]"
  } else {
    set probe_cmd \
	"[uplevel #0 {eval concat $VERILOG_PROBE_CMD(simwave) $PROBE_DATA_FILE}]"
  }
  puts "Starting probe $probe_cmd"

  set PROBE_ID [open "|$probe_cmd >& [exec tty]" w]

  simwave_plot_memory

  # needs to do this twice for some reason
  check_probe
  # if its still valid, do a zoom to fit (nice syntax)
  if {[check_probe]} {
    puts $PROBE_ID "view start $"
    flush $PROBE_ID
  }

  # restore current directory
  cd $save_dir
}


# quits the simwave probe application

proc simwave_close_probe {} {

  global PROBE_ID

  # needs to do this twice for some reason
  check_probe
  # if its still valid, kill probe
  if {[check_probe]} {
    puts $PROBE_ID "quit"
    catch "flush $PROBE_ID"
  }
}


# plot waveform of the selected net on simwave

proc simwave_plot_net {{net ""}} {

  global PROBE_ID NETLIST_TYPE SPICE_TYPE

  # make sure probe is still around
  # needs to do this twice for some reason
  check_probe
  if {![check_probe]} {
    puts "Need to initialize probe"
    return
  }

  if {$net == ""} {
    set net [${NETLIST_TYPE}_net]
  }

  if {[string first $net :]} {
    # lose the [:] in buses
    set net [bus_root $net]
  }

  if {[use_first SPICE_TYPE] == "powermill"} {
    # special case for powermill
    if {[string range $net 0 1] == "I("} {
      set net [string range $net 2 end]
      set prefix "i("
    } else {
      set prefix "v("
    }

    if {[string first . $net] == -1} {
      # no hierarchy
      set net "$prefix$net)"
    } else {
      # hierarchy
      regsub {.([^.]*)$} $net ".$prefix\\1)" net
    }
  }

  puts "Plotting $net"
  puts $PROBE_ID "display $net"
  flush $PROBE_ID
    
  return $net
}


proc simwave_erase_and_plot_memory {} {

  global PROBE_ID

  # make sure probe is still around
  # needs to do this twice for some reason
  check_probe
  if {![check_probe]} {
    puts "Need to initialize probe"
    return
  }

  puts $PROBE_ID "clear"
  flush $PROBE_ID
    
  simwave_plot_memory
}


proc simwave_plot_memory {} {

  global NET_MEMORY

  if {[info exists NET_MEMORY]} {
    foreach net [array names NET_MEMORY] {
      simwave_plot_net $net
    }
  }
}


proc simwave_plot_net_and_remember {} {

  global NET_MEMORY

  set net [simwave_plot_net]
  
  set NET_MEMORY($net) 1

  puts "Remembered net $net"
}


proc simwave_unplot_net {{net ""}} {

  global PROBE_ID NETLIST_TYPE SPICE_TYPE

  # make sure probe is still around
  # needs to do this twice for some reason
  check_probe
  if {![check_probe]} {
    puts "Need to initialize probe"
    return
  }

  if {$net == ""} {
    set net [${NETLIST_TYPE}_net]
  }

  if {[string first $net :]} {
    # lose the [:] in buses
    set net [bus_root $net]
  }

  if {[use_first SPICE_TYPE] == "powermill"} {
    # special case for powermill
    if {[string range $net 0 1] == "I("} {
      set net "$net)"
    } else {
      set net "v($net)"
    }
  }

  puts "UnPlotting $net"
  puts $PROBE_ID "clear $net"
  flush $PROBE_ID
    
  return $net
}


proc simwave_unplot_net_and_forget {} {

  global NET_MEMORY NETLIST_TYPE

  set net [${NETLIST_TYPE}_net]
  
  simwave_unplot_net $net

  catch "unset NET_MEMORY($net)"
  puts "Forgotten net $net"
}


# In interactive verilog mode, verilog is run interactively (-s option)
# from SUE.  Net values are automatically updated on "flags" which can
# be placed anywhere on nets.

# NOTE: The top level module in your simulation needs to define:
#   integer tmp_channel;

# Starts up verilog in interactive mode.

proc interactive_init_probe {{options 0}} {

  global NETLIST SUFFIX cur_s PROBE_ID PROBE_TMP_FILE VERILOG_PROBE_CMD
  global cur_c UPDATE_FLAGS

  if {[info exists NETLIST(root)] != 1} {
    sue_error "Aborting, must netlist first before initializing probe."
    sue_error flush
    return
  }

  if {$PROBE_ID != ""} {
    if {[check_probe //]} {
      # already have a verilog probe, must waste it
      # if verilog is still running, stop it.
      v {$finish;}

      catch "close $PROBE_ID"
      set PROBE_ID ""
    }
  }

  catch {unset UPDATE_FLAGS(__index__)}
  set UPDATE_FLAGS(__index__) 0

  # compute the filename for the verilog file
  upvar #0 SUE_$NETLIST(root) data
  set filename "$data(dir)$NETLIST(root)$SUFFIX(verilog)"

  # allows up to three options
  setl {option1 option2 option3} [use_first VERILOG_PROBE_CMD(option)]

  if {$options} {
    set winy [expr [winfo rooty $cur_c] + 50]
    set winx [expr [winfo rootx $cur_c] + 50]
    set title "Interactive options"
    set message "Enter options (one per line):" 

    set prop_list ""
    lappend prop_list [list option1 $option1]
    lappend prop_list [list option2 $option2]
    lappend prop_list [list option3 $option3]

    # create the menu
    set new_prop_list [prop_menu $winx $winy $message $title $prop_list]
    if {$new_prop_list == ""} {
      # empty list means the user hit cancel 
      return
    } else {
      set option "[lindex [lindex $new_prop_list 0] 1] [lindex [lindex $new_prop_list 1] 1] [lindex [lindex $new_prop_list 2] 1]"
    }

    # save the option
    set VERILOG_PROBE_CMD(option) $option
  } else {
    set option ""
  }

  busy

  regsub -all {\"} $option {\\"} option
  set probe_cmd "$VERILOG_PROBE_CMD(interactive) $option $filename"

  puts "\nStarting Verilog ..."
  puts "$probe_cmd"

#  set PROBE_ID [open |$probe_cmd w]
#  set PROBE_ID [open "|$probe_cmd |& cat -u" w]
  set PROBE_ID [open "|$probe_cmd >& [exec tty]" w]

  # Try to write the temporary file in the current directory.  If you
  # can't, use /tmp
  set PROBE_TMP_FILE [pwd]/tmp[pid]
  if {([file exists $PROBE_TMP_FILE] && ![file writable $PROBE_TMP_FILE]) || \
          ![file writable [pwd]]} {
    # can't write into this directory, use /tmp
    set PROBE_TMP_FILE /tmp/tmp[pid]
  }

  ready
  return
}


# quits verilog and end interactive session.

proc interactive_close_probe {} {

  global PROBE_ID

  if {$PROBE_ID != ""} {
    # if verilog is still running, stop it.
    v {$finish;}

    catch "close $PROBE_ID"
    set PROBE_ID ""
  }

  # toast this menu if it exists
  catch "destroy .vcd"
}


# Updates the values of all of the flags in the current schematic by
# telling verilog to write out a file with the desired values and
# then reading it back in and remaking the flags.

proc verilog_update_flags {} {

  global cur_c cur_s PROBE_ID PROBE_TMP_FILE UPDATE_FLAGS HIERARCHY
  global SEPARATOR VERILOG_ROOT NETLIST VERILOG_PROBE_CMD

  if {[is_icon $cur_s]} {
    puts "Can only update flags in schematics."
    return
  }

  if {![check_probe //]} {
    puts "Need to initialize verilog."

    catch {unset UPDATE_FLAGS(__index__)}
    return
  }

  if {[string first vcs $VERILOG_PROBE_CMD(interactive)] != -1} {
    # vcs is different
    set simulator vcs
  } else {
    set simulator verilog
  }

  busy

  set UPDATE_FLAGS($cur_c) $UPDATE_FLAGS(__index__)
  set UPDATE_FLAGS($cur_c,hierarchy) $HIERARCHY

  set flag_ids [$cur_c find withtag icon_flag] 
  if {$flag_ids == ""} {
    # no flags, that was easy.
    puts "No flags in \"$cur_s\" to update."
    ready
    return
  }

  # compute offset of terminal in flag to origin
  set offset 0
  foreach id [$cur_c find withtag inst[lindex $flag_ids 0]] {
    if {[is_tagged $id "term"]} {
      set offset [expr $id - [lindex $flag_ids 0]]
      break
    }
  }

#  set prefix $VERILOG_ROOT$SEPARATOR$NETLIST(root)$SEPARATOR

  upvar #0 TERMS_$cur_s TERMS

  integer_scale

  # first write the values out to a file
  if {$simulator == "vcs"} {
    # doesn't allow assignment.  Seems to always return 2.
    puts $PROBE_ID "\$fopen(\"$PROBE_TMP_FILE\");"
  } else {
    puts $PROBE_ID "tmp_channel = \$fopen(\"$PROBE_TMP_FILE\");"
  }

  # drop all of the flag locations into a tmp file
  foreach id $flag_ids {
    upvar #0 ${cur_s}_inst$id i_data
    set net [find_verilog_net_name [expr $id + $offset]]
    if {$net == ""} {
      # no net name on this flag, might be recently placed
      set net [verilog_net $id]
      set TERMS([expr $id + $offset]) \
	  [lindex [lreverse [split $net $SEPARATOR]] 0]

      if {$net == ""} {
	# still nothing
	continue
      }
    }

    if {![info exists flags($net)]} {
      if {$simulator == "vcs"} {
	puts $PROBE_ID "\$fdisplay(2,\"${net}\t$i_data(_format)\",\{$net\});"
      } else {
	puts $PROBE_ID \
	    "\$fdisplay(tmp_channel,\"${net}\t$i_data(_format)\",\{$net\});"
      }
    }
    lappend flags($net) $id
  }

  if {$simulator == "vcs"} {
    puts $PROBE_ID "\$fclose(2);"
  } else {
    puts $PROBE_ID "\$fclose(tmp_channel);"
  }
  flush $PROBE_ID

  # now read in the file and stuff the flags with data
  set increment 100
  set count 0
  while {![file exists $PROBE_TMP_FILE]} {
    # wait for a while to give verilog a chance to write this file
    after $increment
    incr count $increment
    if {$count > 5000} {
      # Waited 5 seconds, it ain't gonna happen
      puts "ERROR: Verilog not responding."
      unscale
      ready
      return
    }
  }

  set try 0
  set count 0

  # Sometimes this doesn't work the first time.  If not try twice more.
  while {$count == 0 && $try < 3} {
    set tmp_id [open $PROBE_TMP_FILE r]

    while {[gets $tmp_id line] >= 0} {
      if {[info exists flags([lindex $line 0])]} {
	set ids $flags([lindex $line 0])
	foreach id $ids {
	  upvar #0 ${cur_s}_inst$id i_data
	  set i_data(_value) [lindex $line 1]
	  set new_id [remake $id $id dont_modify no_scale]
	  set TERMS([expr $new_id + $offset]) \
	      [use_first TERMS([expr $id + $offset])]
	  incr count
	}
      }
    }

    # close the file
    close $tmp_id
    incr try

    if {$count == 0} {
      # try waiting a second before trying again
      after 1000
    }
  }

  unscale

  # now delete the tmp file
  exec rm -f $PROBE_TMP_FILE

  puts "Updated $count flags."
  ready

  return 
}


# Displays the verilog value of each terminal on the terminal temporarily.
# Cleared with any click.

proc verilog_display_term_values {} {

  global cur_c cur_s PROBE_ID PROBE_TMP_FILE scale COLORS FONT DISPLAY_TERMS
  global SEPARATOR VERILOG_ROOT NETLIST VERILOG_PROBE_CMD

  if {[is_icon $cur_s]} {
    puts "Can only display terminal values in schematics."
    return
  }

  if {![check_probe //]} {
    puts "Need to initialize verilog."
    return
  }

  if {[string first vcs $VERILOG_PROBE_CMD(interactive)] != -1} {
    # vcs is different
    set simulator vcs
  } else {
    set simulator verilog
  }

  busy

  # waste any old values
  $cur_c delete tmp

  integer_scale

  # first write the values out to a file
  if {$simulator == "vcs"} {
    # doesn't allow assignment.  Seems to always return 2.
    puts $PROBE_ID "\$fopen(\"$PROBE_TMP_FILE\")";
  } else {
    puts $PROBE_ID "tmp_channel = \$fopen(\"$PROBE_TMP_FILE\");"
  }

  # drop all of the term locations into a tmp file
#  set root "$VERILOG_ROOT$SEPARATOR$NETLIST(root)$SEPARATOR"

  foreach id [$cur_c find withtag term] {
    set origin_id [find_origin $id]
    if {![is_tagged $origin_id icon_flag] && \
	    ![is_tagged $origin_id icon_global] && \
	    ![is_tagged $origin_id icon_$cur_s]} {
      # find the net that is attached to this term
      set net [find_verilog_net_name $id]

      if {![info exists flags($net)]} {
	if {$simulator == "vcs"} {
	  puts $PROBE_ID "\$fdisplay(2,\"${net}\t$DISPLAY_TERMS(verilog)\",\{$net\});"
	} else {
	  puts $PROBE_ID \
	      "\$fdisplay(tmp_channel,\"${net}\t$DISPLAY_TERMS(verilog)\",\{$net\});"
	}
	flush $PROBE_ID
      }
      lappend flags($net) $id
    }
  }

  # put in something at the end of the file so we can look for it to make
  # sure that the entire file was written before we read it.
  if {$simulator == "vcs"} {
    puts $PROBE_ID "\$fdisplay(2,\"*DONE*\");"
  } else {
    puts $PROBE_ID \
	"\$fdisplay(tmp_channel,\"*DONE*\");"
  }
  flush $PROBE_ID

  # close the tempfile
  if {$simulator == "vcs"} {
    puts $PROBE_ID "\$fclose(2);"
  } else {
    puts $PROBE_ID "\$fclose(tmp_channel);"
  }
  flush $PROBE_ID

  # now read in the file and stuff the flags with data
  set increment 100
  set count 0
  while {![file exists $PROBE_TMP_FILE]} {
    # wait for a while to give verilog a chance to write this file
    after $increment
    incr count $increment
    if {$count > 5000} {
      # Waited 5 seconds, it ain't gonna happen
      puts "ERROR: verilog not responding."
      unscale
      ready
      return
    }
  }

  set done 0
  set try 0
  set max_lines 0
  while {1} {
    incr try

    set tmp_id [open $PROBE_TMP_FILE r]
    set lines 0

    while {[gets $tmp_id line] >= 0} {
      if {$line == "*DONE*"} {
	set done 1
	break
      }

      incr lines

      if {[info exists flags([lindex $line 0])]} {
	set ids $flags([lindex $line 0])
	catch {unset close}

	foreach id $ids {
	  # Put the values on the terminals
	  set coords [$cur_c coords $id]

	  set x [expr round([lindex $coords 0])]
	  set y [expr round([lindex $coords 1])]

	  # if this is close to another id on the same net, don't show it
	  if {[info exists close(y,$x)]} {
	    if {[expr abs($close(y,$x)-$y)/$scale] < 20} {
	      # too close
	      continue
	    }
	  }
	  if {[info exists close(x,$y)]} {
	    if {[expr abs($close(x,$y)-$x)/$scale] < 20} {
	      # too close
	      continue
	    }
	  }
	  set close(y,$x) $y
	  set close(x,$y) $x

	  if {[is_tagged $id rotate]} {
	    $cur_c create text $x $y -tags "tmp scaletext size_standard" \
		-fill $COLORS(anchor) -text [lindex $line 1] \
		-font $FONT(standard,$scale) -rotate 1
	  } else {
	    $cur_c create text $x $y -tags "tmp scaletext size_standard" \
		-fill $COLORS(anchor) -text [lindex $line 1] \
		-font $FONT(standard,$scale)
	  }
	}
      }
    }

    # close the file
    close $tmp_id

    if {$done} {
      break
    }

    if {$lines > $max_lines} {
      # file is growing
      set max_lines $lines
      set try 0

    } elseif {$try > 5} {
      # we lost
      puts "WARNING: didn't read complete verilog output."

      break
    }

    after 1000
  }

  unscale

  # now delete the tmp file
  exec rm -f $PROBE_TMP_FILE

  ready

  return
}


# so the hotkeys work

proc interactive_unplot_net {{foo ""}} {

  if {$foo == "~"} {
    verilog_display_term_values
    return
  }

  verilog_update_flags
}


# function to send commands directly to verilog.  Remember to quote
# special characters to "v" or call it by: v {verilog command}.

proc v {args} {

  global PROBE_ID

  if {![check_probe //]} {
    puts "Need to initialize verilog."
    return
  }

  # need to remove {} that wander in.
  regsub -all {(\{|\})} $args "" args

#  regsub -all {([^\])(\})} $args {\1} args
#  regsub -all {([^\])(\{)} $args {\1} args
#  regsub -all {(\\)(\{|\})} $args {\2} args

# puts "sending to verilog: $args"
  puts $PROBE_ID $args
  catch "flush $PROBE_ID"

  return
}


# Useful verilog command to step the simulation forward by a given time.

proc step {{time ""}} {

  global cur_c VERILOG_STEP UPDATE_FLAGS VERILOG_PROBE_CMD

  if {[string first vcs $VERILOG_PROBE_CMD(interactive)] != -1} {
    # vcs is different
    set simulator vcs
  } else {
    set simulator verilog
  }

  set time [use_first time VERILOG_STEP]

  puts "Stepping $time"

  if {$simulator == "vcs"} {
    v "once \#$time ; ."
  } else {
    # pver wants this to be on two lines
    v "\#$time \$stop;"
    v "."
  }

  if {![info exists UPDATE_FLAGS(__index__)]} {
    set UPDATE_FLAGS(__index__) 0
  }
  incr UPDATE_FLAGS(__index__)

  # Fix up the flags now that time has moved forward.
  verilog_update_flags

  # waste any old values
  $cur_c delete tmp
}


# Displays the value of a net without using a flag.

proc interactive_plot_net {{format %d}} {

  global PROBE_ID HIERARCHY _VP_

  # to make the hotkeys work
  if {$format == "~"} {
    set format %h
  }

  # make sure probe is still around
  if {![check_probe //]} {
    puts "Need to initialize verilog."
    return
  }

  # use this to clear inst selection
  catch {unset _VP_($HIERARCHY)}

  set net [verilog_net]

  puts $PROBE_ID "\$display(\"$net = $format\",\{$net\});"
  flush $PROBE_ID
    
  return
}


# Used to make the hotkeys work

proc interactive_plot_net_and_remember {} {

  interactive_plot_net %b
}


# These commands don't do anything in interactive mode.

proc interactive_erase_and_plot_memory {} {

  return
}


proc interactive_plot_memory {} {

  return
}


proc interactive_unplot_net_and_forget {} {

  return
}
