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


# routines to crossprobe schematics in irsim with analyzer.

# file id of current probe.  This will set to "" if not defined.

set PROBE_ID [use_first PROBE_ID]

# <re>netlists and then runs analyzer_init_probe

# netlist current schematic and then run irsim/analyzer (i.e. calls
# analyzer_init_probe)

proc sim_it {} {

  modify_setup sim_it

  set netlist_filename [netlist]

  if {$netlist_filename == ""} {
    sue_error "Aborting, can't run irsim/analyzer due to netlist errors."
    sue_error flush
    return
  }

  analyzer_init_probe
}


# function to send commands directly to irsim/analyzer.  Remember to quote
# special characters to "i" or call it by: i {irsim/analyzer command}.

proc i {args} {

  global PROBE_ID

  if {![check_probe |]} {
    puts "Need to initialize irsim/analyzer."
    return
  }

  # need to remove {} that wander in.
  regsub -all {(\{|\})} $args "" args

#  regsub -all {([^\])(\})} $args {\1} args
#  regsub -all {([^\])(\{)} $args {\1} args
#  regsub -all {(\\)(\{|\})} $args {\2} args

#  puts "sending to irsim/analyzer: $args"
  puts $PROBE_ID $args
  catch "flush $PROBE_ID"

  return
}


# opens an irsim/analyzer window if none is presently open

proc analyzer_init_probe {{option ""}} {
  
  global cur_s NETLIST PROBE_ID PROBE_DISPLAY SIM_PROBE_CMD SUFFIX 
  global PROBE_TMP_FILE UPDATE_FLAGS IRSIM_VECTORS

  if {[info exists NETLIST(root)] != 1} {
    sue_error "Aborting, must netlist first before initializing probe."
    sue_error flush
    return
  }

  upvar #0 SUE_$NETLIST(root) data
  set filename "$data(dir)$NETLIST(root)$SUFFIX(sim)"

  # is there a .sim file yet?
  if {[file isfile $filename] != 1} {
    # file doesn't exist so abort
    puts "Aborting, can't find SIM file $filename"
    return
  }

  if {[check_probe |]} {
    # already have a irsim/analyzer probe, must waste it
    catch "puts $PROBE_ID exit"
    catch "flush $PROBE_ID"

    catch "close $PROBE_ID"
    puts "Closed existing IRSIM/Analyzer"
  }

  catch {unset UPDATE_FLAGS(__index__)}
  set UPDATE_FLAGS(__index__) 0

  set probe_cmd "$SIM_PROBE_CMD(analyzer) $filename"

  puts "Starting irsim/analyzer with $probe_cmd"
  set PROBE_ID [open "|$probe_cmd >& [exec tty]" w]
  
  if {[check_probe |] != 1} {
    puts "ERROR: Can't start irsim/analyzer with $probe_cmd."
    return
  }

  catch {unset IRSIM_VECTORS}

  # start up the analyzer window in the appropriate window
  puts $PROBE_ID "Xdisplay [lindex $PROBE_DISPLAY 1]"
  flush $PROBE_ID

  puts $PROBE_ID "ana"
  flush $PROBE_ID

  analyzer_plot_memory

  # Try to write the temporary file in the current directory.  If you
  # can't, use /tmp
  set PROBE_TMP_FILE [pwd]/tmp[pid]
  if {([file exists $PROBE_TMP_FILE] && ![file writable $PROBE_TMP_FILE]) || \
          ![file writable [pwd]]} {
    # can't write into this directory, use /tmp
    set PROBE_TMP_FILE /tmp/tmp[pid]
  }
}


# quits the analyzer probe application

proc analyzer_close_probe {} {

  global PROBE_ID IRSIM_VECTORS

  catch {unset IRSIM_VECTORS}

  # if its still valid, kill probe
  if {[check_probe |]} {
    puts $PROBE_ID "exit"
    catch "flush $PROBE_ID"

    catch "close $PROBE_ID"
  }
}


# plot waveform of the selected net in analyzer

proc analyzer_plot_net {{suffix ""} {net ""}} {

  global PROBE_ID PROBE_DATA_FILE

  # make sure irsim/analyzer is still around
  if {[check_probe |]} {
    if {$net == ""} {
      set net [irsim_net]
    }

    puts "Plotting $net"
    puts $PROBE_ID "ana $net"
    flush $PROBE_ID

    return $net

  } else {
    puts "Need to initialize probe"
  }
}


# There is no analyzer command for this, unfortunately.

proc analyzer_unplot_net {{foo ""}} {

  if {$foo == "~"} {
    irsim_display_term_values
    return
  }
  
  irsim_update_flags
#  puts "To unplot node: Press Button-1 on signal in analyzer, move mouse away, and then release button."
}


proc analyzer_erase_and_plot_memory {} {

  global PROBE_ID

  # make sure analyzer is still around
  if {[check_probe |]} {

    puts $PROBE_ID "clear"
    flush $PROBE_ID
    
    analyzer_plot_memory

  } else {
    puts "Need to initialize probe"
  }
}


proc analyzer_plot_memory {} {

  global NET_MEMORY

  if {[info exists NET_MEMORY]} {
    foreach net [array names NET_MEMORY] {
      analyzer_plot_net "" $net
    }
  }
}


proc analyzer_plot_net_and_remember {} {

  global NET_MEMORY

  set net [analyzer_plot_net]
  
  set NET_MEMORY($net) 1

  puts "Remembered net $net"
}


proc analyzer_unplot_net_and_forget {} {

  global NET_MEMORY

  set net [irsim_net]
  
  catch "unset NET_MEMORY($net)"

  puts "Forgotten net $net"
}


# Updates the values of all of the flags in the current schematic by
# telling irsim to write out a logfile with the desired values and
# then reading it back in and remaking the flags.
# Also, simulates buses which irsim doesn't understand

proc irsim_update_flags {} {

  global cur_c cur_s PROBE_ID PROBE_TMP_FILE UPDATE_FLAGS HIERARCHY

  if {![check_probe |]} {
    puts "Need to initialize irsim/analyzer."

    catch {unset UPDATE_FLAGS(__index__)}
    return
  }

  if {![info exists PROBE_TMP_FILE]} {
    puts "Need to initialize irsim/analyzer."

    catch {unset UPDATE_FLAGS(__index__)}
    return
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

  # first write the values out to a file
  puts $PROBE_ID "logfile $PROBE_TMP_FILE"

  # drop all of the flag locations into a tmp file
  foreach id $flag_ids {
    set net [irsim_net $id]
    if {![info exists flags($net)]} {
      puts $PROBE_ID "d $net"
    }
    lappend flags($net) $id
  }

  # close the logfile
  puts $PROBE_ID "logfile"
  flush $PROBE_ID

  # now read in the file and stuff the flags with data
  set increment 100
  set count 0
  while {![file exists $PROBE_TMP_FILE]} {
    # wait for a while to give irsim a chance to write this file
    after $increment
    incr count $increment
    if {$count > 5000} {
      # Waited 5 seconds, it ain't gonna happen
      puts "ERROR: irsim not responding."
      ready
      return
    }
  }

  set try 0
  set count 0

  integer_scale

  # Sometimes this doesn't work the first time.  If not try twice more.
  while {$count == 0 && $try < 3} {
    set tmp_id [open $PROBE_TMP_FILE r]

    # read the file and set flags
    while {[gets $tmp_id line] >= 0} {
      setl {cmd net_name value} [split $line "= "]
      set net_name [string tolower $net_name]
      set values($net_name) $value
      if {$cmd == "|" && [info exists flags($net_name)]} {
	foreach id $flags($net_name) {
	  upvar #0 ${cur_s}_inst$id i_data

	  if {$i_data(_format) == "%d"} {
	    # only convert this to decimal if it is a number 
	    # (i.e. no X's or Z's), otherwise binary.
	    if {![catch "expr $value"]} {
	      # convert me
	      set decimal 0
	      for {set i 0} {$i < [string length $value]} {incr i} {
		set decimal [expr $decimal * 2 + [string index $value $i]]
	      }
	      set value $decimal
	    }
	  }

	  set i_data(_value) $value
	  remake $id $id dont_modify no_scale
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
}


# Needed because NETLIST_TYPE is set to sim, not irsim

proc sim_update_flags {} {

  irsim_update_flags
}


proc irsim_display_term_values {} {

  global cur_c cur_s PROBE_ID PROBE_TMP_FILE scale COLORS FONT

  if {![check_probe |]} {
    puts "Need to initialize irsim/analyzer."
    return
  }

  busy

  # waste any old values
  $cur_c delete tmp

  # first write the values out to a file
  puts $PROBE_ID "logfile $PROBE_TMP_FILE"

  integer_scale

  # drop all of the term locations into a tmp file
  foreach id [$cur_c find withtag term] {
    set origin_id [find_origin $id]
    if {![is_tagged $origin_id icon_flag] && \
	    ![is_tagged $origin_id icon_global] && \
	    ![is_tagged $origin_id icon_$cur_s]} {
      # find the net that is attached to this term
      set net [irsim_net $id]

      if {![info exists flags($net)]} {
	puts $PROBE_ID "d $net"
      }
      lappend flags($net) $id
    }
  }

  # close the logfile
  puts $PROBE_ID "logfile"
  flush $PROBE_ID

  # now read in the file and stuff the flags with data
  set increment 100
  set count 0
  while {![file exists $PROBE_TMP_FILE]} {
    # wait for a while to give irsim a chance to write this file
    after $increment
    incr count $increment
    if {$count > 5000} {
      # Waited 5 seconds, it ain't gonna happen
      puts "ERROR: irsim not responding."
      unscale
      ready
      return
    }
  }

  set tmp_id [open $PROBE_TMP_FILE r]
     
  while {[gets $tmp_id line] >= 0} {
    setl {cmd net_name value} [split $line "= "]
    set net_name [string tolower $net_name]
    set values($net_name) $value
    if {$cmd == "|" && [info exists flags($net_name)]} {
      foreach id $flags($net_name) {
	# Put the values on the terminals
	setl {x y} [$cur_c coords $id]

	if {[is_tagged $id rotate]} {
	  $cur_c create text $x $y -tags "tmp scaletext size_standard" \
	      -fill $COLORS(anchor) -text $value \
	      -font $FONT(standard,$scale) -rotate 1
	} else {
	  $cur_c create text $x $y -tags "tmp scaletext size_standard" \
	      -fill $COLORS(anchor) -text $value \
	      -font $FONT(standard,$scale)
	}
      }
    }
  }

  # close the file
  close $tmp_id

  unscale

  # now delete the tmp file
  exec rm -f $PROBE_TMP_FILE

  ready
}


# Some useful irsim commands

proc irsim_step {} {

  global cur_c NETLIST_TYPE UPDATE_FLAGS

  # only do this if we are in sim mode
  if {[use_first NETLIST_TYPE] == "verilog" || \
	  [use_first NETLIST_TYPE] == "csim"} {
    step
    return
  }

  if {[use_first NETLIST_TYPE] != "sim"} {
    return
  }

  puts "Stepping irsim."
  i s

  if {![info exists UPDATE_FLAGS(__index__)]} {
    set UPDATE_FLAGS(__index__) 0
  }
  incr UPDATE_FLAGS(__index__)

  # now update flags
  irsim_update_flags

  # waste any old values
  $cur_c delete tmp
}


proc irsim_set {dir} {

  set dirs(h) 1
  set dirs(l) 0
  set dirs(u) x

  set net [irsim_net]
  puts "Setting net \"$net\" to $dirs($dir) in irsim."
  i $dir [irsim_net]
}


# returns the selected net name

proc irsim_net {{id ""}} {

  global IRSIM_VECTORS

  set net [spice_net $id]

  if {[bus_width $net] > 1 && ![info exists IRSIM_VECTORS($net)]} {
    # need to create this vector
    i vector $net [lreverse [bus_expand $net]]
    
    # remember that we did this so we don't have to in the future
    set IRSIM_VECTORS($net) 1
  }

  return $net
}
