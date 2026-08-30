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


# Generic procedures for netlisting in sue.  Determines connectivity.

proc netlist {{save_timing_window 0}} {

  global cur_c cur_s scale NETLIST SCHEMS GLOBALS HIERARCHY SUFFIX NAMES
  global NETLIST_TYPE INTERRUPT WIN_DATA DISABLE_CANVAS_EVENT auto_index
  global __LAUNCH__ FLASH_CELL_ON_LOAD

  if {$DISABLE_CANVAS_EVENT} {
    # ignore, probably key repeat
    return
  }
  set DISABLE_CANVAS_EVENT 1

  set INTERRUPT 0

  modify_setup netlist

  if {[is_icon $cur_s]} {
    puts "Aborting, cannot netlist from an icon."
    set DISABLE_CANVAS_EVENT 0
    return
  }

  # toast timing window if it exists
  if {!$save_timing_window} {
    catch "destroy .cp"
  }

  set type $NETLIST_TYPE
  # initialization
  netlist_setup $type $cur_s [lindex [use_first HIERARCHY] 0]

  if {!$FLASH_CELL_ON_LOAD} {
    # by incr, appears to come from inside 2 launches and thus delays pack
    incr __LAUNCH__
  }

  if {$type == "dpc"} {
    # special case
    puts "Starting Data Path Compiler:"
    set type verilog
  }

  busy

  puts "[string toupper $type] netlisting from main cell \"$cur_s\" ..."

  # this is now the top level cell
  set HIERARCHY ""

  # need to remember the toplevel schematic 
  set NETLIST(root) $cur_s

  set NETLIST(error) 0

  # used in trace hierarchy
  catch {unset SCHEMS}

  # needed for flat netlisting
  catch {unset NAMES}
  set NAMES(_unique) 0

  # reset the list of global signals
  catch {unset GLOBALS}

  # save the current canvas, schematic, and scale
  set save_cur_c $cur_c
  set save_cur_s $cur_s
  set save_scale $scale

  set schematic_name [get_rootname $cur_s]

  global SUE_$schematic_name
  set dir [set SUE_${schematic_name}(dir)]

  upvar #0 icon_$schematic_name g_data
  if {[use_first g_data(generator)] != ""} {
    # this is a generator.
    set genname [lindex [split_filename [use_first g_data(generator)]] 1]
    if {[info exists auto_index(SCHEMATIC_$genname)]} {
      set dir [file dirname [lindex $auto_index(SCHEMATIC_$genname) 1]]/
    }
  }
  set NETLIST(dir) $dir

  set filename "$dir$schematic_name$SUFFIX($NETLIST_TYPE)"
  set NETLIST(filename) $filename

  ###### Open file
  if {[catch "open $filename w" msg] != 0} {
    # error, probably can't write to directory
    puts "Aborting, $msg"
    ready

    # enable general canvas events
    set DISABLE_CANVAS_EVENT 0

    if {!$FLASH_CELL_ON_LOAD} {
      # fix up
      incr __LAUNCH__ -1
    }

    return
  }
  set NETLIST(file_id) $msg

  # set up variable to postpone running make_icon_listbox a million times
  set WIN_DATA(make_icon_listbox) 0

  # call the specified netlister
  ${NETLIST_TYPE}_netlist $cur_s $dir

  ###### Close file
  # Note: in dpc_netlist, closes after verilog netlist but before dpc.
  catch {close $NETLIST(file_id)}

  # restore the current canvas, schematic, and scale
  set cur_c $save_cur_c
  set cur_s $save_cur_s
  set scale $save_scale

  if {$WIN_DATA(make_icon_listbox) > 0} {
    # need to update this
    make_icon_listbox
  }
  unset WIN_DATA(make_icon_listbox)

  if {$INTERRUPT} {
    puts "Interrupt, Aborting $NETLIST_TYPE netlist."
    ready
    sue_error flush

    # enable general canvas events
    set DISABLE_CANVAS_EVENT 0

    if {!$FLASH_CELL_ON_LOAD} {
      # fix up
      incr __LAUNCH__ -1
    }

    return ""
  }

  puts "Wrote $NETLIST_TYPE netlist to $filename"

  # if there is a hierarchy display window, remake it.
  if {[winfo exists .design]} {
    create_design_listbox
  }

  ready

  display_selection

  # enable general canvas events
  set DISABLE_CANVAS_EVENT 0

  if {!$FLASH_CELL_ON_LOAD} {
    # fix up
    incr __LAUNCH__ -1
  }

  puts "done.\n"

  if {[sue_error flush] == 1} {
    # 1 means error, abort
    return ""
  } else {
    return "$schematic_name$SUFFIX($NETLIST_TYPE)"
  }
}


# walks down thru the hierarchy and collects a list of the instances.
# In addition, checks to insure that the icon/schematic pairs are well
# formed (their I/O's match in name and they all have names.)

proc trace_hierarchy {schematic {level {}}} {

  global cur_c cur_s scale SCHEMS SUE NETLIST_PROPS NETLIST_CACHE

  if {[info exists SCHEMS($schematic)]} {
    # already been here
    return
  }

  check_interrupt

  set SCHEMS($schematic) traced

  # check to see if we should netlist this schematic and isn't top cell.
  if {$level == "" && [get_property_info $schematic $NETLIST_PROPS] != ""} {
    # don't need to netlist this cell
    return
  }

  # might have to make canvases for some leaf cells
  if {[info exists SUE($schematic)] != 1} {
    if {[goto_schematic $schematic] == ""} {
      sue_error "NETLIST ERROR: Can't find cell $schematic during netlisting"
      return
    }
  } else {
    # save the current canvas, schematic, and scale
    set save_cur_c $cur_c
    set save_cur_s $cur_s
    set save_scale $scale

    # by entering the canvas, we will update any changed icons
    # this is faster and cleaner than going to the schematic
    enter_canvas $schematic

    # if any icon in this schematic has changed then we must re-netlist
    if {[icons_changed]} {
      set NETLIST_CACHE($schematic) ""
    }

    # restore the current canvas, schematic, and scale
    set cur_c $save_cur_c
    set cur_s $save_cur_s
    set scale $save_scale
  }
  
  global SUE_$schematic
  set canvas [set SUE_${schematic}(canvas)]

  foreach id [$canvas find withtag origin] {
    upvar #0 ${schematic}_inst${id} i_data
    # the type is really the instance name
    set type $i_data(type)
    upvar #0 icon_$type g_data

    # if this id has a property in the icon that matches one of the
    # netlist props, then we don't have to trace any further
    if {[get_property_info $type $NETLIST_PROPS] != ""} {
      set SCHEMS($type) icon
      continue
    }

    # if this has a schematic, trace down through it's hierarchy
    if {[info exists SUE($type)] || [info commands SCHEMATIC_$type] != "" || \
	    [info commands SCHEMATIC_[use_first g_data(generator)]] != ""} {
      # recurse
      lappend SCHEMS(dpc,$type) $schematic
      trace_hierarchy $type

      # if hasn't been checked yet, check i/o's
      if {$SCHEMS($type) == "traced"} {
	check_ios $type $id $canvas

	# mark as checked
	set SCHEMS($type) checked
      }
    }
  }
  # busy gets reset so we must do it again
  busy

  lappend SCHEMS(_LIST_) $schematic

  return
}


# to speed up find_by_name procedure

proc make_reverse_terms_array {} {

  global cur_s

  upvar #0 TERMS_$cur_s TERMS
  upvar #0 RTERMS_$cur_s RTERMS

  catch {unset RTERMS}

  # put everything in the RTERMS array that is indexed by an id only
  foreach id [array names TERMS {*[0-9]}] {
    # break apart concatenated buses
    foreach one [split $TERMS($id) ,] {
      lappend RTERMS($one) $id
    }
  }
}


# get the term name and priority out of the tags and save in a global array.

proc get_term_info {id {noglobal ""}} {

  global cur_c cur_s TERM_PRIORITY GLOBALS GLOBAL_TRANSLATIONS
  global NETLIST_CACHE NETLIST_TYPE NETLIST_CONVERT_CONSTANT
  upvar #0 TERMS_$cur_s TERMS 

  set tags [$cur_c gettags $id]
  set name_list [lindex $tags [lsearch $tags "name*"]]

  # remove spaces
  regsub -all " |\{|\}" [lrange $name_list 3 end] "" name

  set TERMS($id,type) [lindex $name_list 1]
  set TERMS($id,priority) $TERM_PRIORITY([lindex $name_list 1])
  set TERMS($id,dir) [lindex $name_list 2]

  if {$NETLIST_TYPE == "dpc"} {
    set ntype verilog
  } else {
    set ntype $NETLIST_TYPE
  }

  # save the names of all globals
  set xname ""
  if {$noglobal == "" && $TERMS($id,priority) == $TERM_PRIORITY(global)} {
    # allows for globals variables to be substituted for indeces.
    foreach part [split [lookup_name $name] ,] {
      if {[info exists GLOBAL_TRANSLATIONS($ntype,$part)]} {
	lappend xname $GLOBAL_TRANSLATIONS($ntype,$part)
	set lname [string tolower $GLOBAL_TRANSLATIONS($ntype,$part)]

      } else {
	lappend xname $part
	set lname [string tolower $part]
      }

      if {![regexp {'(b|h|d|o)} $lname]} {
	# only put in non-constants
	set GLOBALS($lname) 1

	# save the globals by cell so the caching works
	if {[lsearch [use_first NETLIST_CACHE($cur_s,globals)] \
		 $lname] == -1} {
	  lappend NETLIST_CACHE($cur_s,globals) $lname
	}
      }
    }

  } else {
    # not a global -- still needs global translation if concatenated
    # allows for globals variables to be substituted for indeces.
    foreach part [split [lookup_name $name] ,] {
      if {[info exists GLOBAL_TRANSLATIONS($ntype,$part)]} {
	lappend xname $GLOBAL_TRANSLATIONS($ntype,$part)
      } else {
	lappend xname $part
      }
    }
  }

  if {$NETLIST_CONVERT_CONSTANT} {
    # convert consts to binary
    set list ""
    foreach name $xname {
      if {[regexp {'(h|d|o)} $name]} {
	lappend list [const_to_binary $name 1]
      } else {
	lappend list $name
      }
    }

    set TERMS($id,name) [join $list ,]
  } else {
    # don't convert
    set TERMS($id,name) [join $xname ,]
  }
}


# Returns a unique name which it tries to make as similar to the given
# name as possible.

proc unique_name {prefix {first ""} {second ""}} {

  global NAMES NETLIST_MAX_NAME_LENGTH

  set original_name $prefix[use_first first second]
  regsub -all {\[[0-9]+\]} $original_name "" original_name

  # first check if 
  if {[info exists NAMES([string tolower $original_name])]} {
    # lookup without trailing _#
    regsub {_[0-9]+$} $original_name "" original_name

    if {![info exists NAMES([string tolower $original_name])]} {
      set NAMES([string tolower $original_name]) 0
    }
  }

  set name $original_name

  # make a unique name (case insensitive)
  set lower_name [string tolower $name]

  while {[info exists NAMES($lower_name)]} {
    set name ${original_name}_[incr NAMES($lower_name)]
    set lower_name [string tolower $name]
  }

  # now name is unique.  remember it.
  set NAMES($lower_name) 0

  if {$name == $prefix} {
    return [unique_name $prefix $first $second]
  }

  # Mostly for spice netlisting
  if {[string length $name] > $NETLIST_MAX_NAME_LENGTH} {
    # just retain the first letter
    set name $prefix[incr NAMES(_unique)]
  }

  return $name
}


# evaluates a name with possible global variables in it.

proc lookup_name {name} {

  if {[string index $name 0] == "\\"} {
    # special quoting char
    return $name
  }

  # allows for global variables to be substituted for indeces.
  regsub -all {\[} $name <<< name
  regsub -all {\]} $name >>> name

  # don't change things like 1`b0
  regsub -all {([^0-9]|^)(`)} $name {\1$__} name

  if {[catch {uplevel #0 "concat $name"} msg]} {
    global cur_s
    sue_error "NETLIST ERROR: $msg in cell $cur_s." $cur_s
  } else {
    set name $msg
  }

  regsub -all {<<<} $name \[ name
  regsub -all {>>>} $name \] name

  return $name
}


# checks to insure that there are the same number of ios in the
# schematic and in the icon and they have correct names, i.e. no
# duplicates and one schematic name for each icon name.

proc check_ios {schematic icon_id icon_canvas} {

  global SUE
  set icon ICON_$schematic

  global SUE_$schematic SUE_$icon

  set s_canvas [set SUE_${schematic}(canvas)]

  set ids [concat [$s_canvas find withtag icon_input] \
	       [$s_canvas find withtag icon_inout] \
	       [$s_canvas find withtag icon_output]]

  set s_ios [get_io_names $ids $s_canvas $schematic]
  set i_ios [get_io_names $icon_id $icon_canvas "ICON $schematic" nodups]

  if {$s_ios != $i_ios} {
#    puts "  schematic I/O's: $s_ios"
#    puts "  icon I/O's: $i_ios"

    sue_error "NETLIST ERROR: Icon and schematic I/O's don't match in cell \"$schematic\"." $schematic
    foreach one $s_ios {
      if {[set pos [lsearch -exact $i_ios $one]] == -1} {
	puts "  Schematic terminal \"$one\" has no icon counterpart."
      } else {
	set i_ios [lreplace $i_ios $pos $pos]
      }
    }
    foreach one $i_ios {
      puts "  Icon terminal \"$one\" has no schematic counterpart."
    }
  }
}


proc get_io_names {ids canvas schematic {dups ""}} {

  set io_names ""

  foreach inst_id $ids {
    foreach id [$canvas find withtag inst$inst_id] {
      set tags [$canvas gettags $id]

      if {[lsearch $tags "term"] != -1} {
	set name_list [lindex $tags [lsearch $tags "name*"]]
	set type [lindex $name_list 2]
	set name [lookup_name [lindex $name_list 3]]
	
	set root [bus_root $name]
	if {$name == $root} {
	  # scalar
	  if {$dups != "" && [info exists names($root)]} {
	    # duplicate error
	    sue_error "NETLIST ERROR: Can't have duplicate terminals \"$name\" in cell \"$schematic\"." $schematic
	  }
	  set names($root) $name

	} else {
	  # bus
	  lappend names($root) $name
	}

	if {[info exists types($root)]} {
	  if {$types($root) != $type} {
	    # problem, different types
	    sue_error "NETLIST ERROR: port \"$root\" can't be both \"$type\" and \"$types($root)\" in cell \"$schematic\"." $schematic
	  }
	} else {
	  set types($root) $type
	}
      }
    }
  }

  set ios ""
  foreach root [lsort [array names names]] {
    if {[lindex $names($root) 1] == ""} {
      lappend ios $names($root)
    } else {
      lappend ios $root[bus_extent $names($root)]

      # check for duplicates
      if {$dups != ""} {
	# can't have duplicates terminals
	regsub -all {\{|\}} $names($root) "" names($root)
	sue_error "NETLIST ERROR: Can't break up/duplicate bused terminals \"$names($root)\" in cell \"$schematic\"." $schematic
      }
    }
  }

  # remove any {}
  regsub -all {\{|\}} $ios "" ios

  return $ios
}


# returns 1 if any icon in this schematic has changed since the last netlist
# and updates a pointer into the modified icon list for the next netlist.

proc icons_changed {} {

  global cur_s cur_c MODIFY_ICON MODIFY_ICON_LEVEL NETLIST_CACHE
  upvar #0 SUE_$cur_s data

  set return 0
  if {$MODIFY_ICON(_index) > $data(netlist_icon_index)} {
    # check to see if we contain any icons that have changed
    for {set i $data(netlist_icon_index)} {$i < $MODIFY_ICON(_index)} {} {
      set icon $MODIFY_ICON([incr i])

      if {[info exists updated($icon)]} {
	# already propagated
	continue
      }
	  
      # remember so we don't have to recheck
      set updated($icon) 1

      if {[$cur_c find withtag icon_$icon] != ""} {
	# found a modified icon
	set return 1

	# must also renetlist schematic (if there is one) since the
	# user properties might have changed
	if {[info exists NETLIST_CACHE($icon)]} {
	  set NETLIST_CACHE($icon) ""
	}
      }
    }
    
    # update this canvas to remember which icons were checked
    set data(netlist_icon_index) $MODIFY_ICON(_index)

    if {$return} {
      return $return
    }
  }

  catch {unset updated}

  # Special check for changes in the netlist level of an icon
  if {$MODIFY_ICON_LEVEL(_index) > $data(netlist_level_index)} {
    # check to see if we contain any icons that have changed
    for {set i $data(netlist_level_index)} {$i < $MODIFY_ICON_LEVEL(_index)} {} {
      set icon $MODIFY_ICON_LEVEL([incr i])

      if {[info exists updated($icon)]} {
	# already propagated
	continue
      }
	  
      # remember so we don't have to recheck
      set updated($icon) 1

      if {[$cur_c find withtag icon_$icon] != ""} {
	# update this canvas to remember which icons were checked
	set data(netlist_level_index) $MODIFY_ICON_LEVEL(_index)

	set data(modified_term_names) changed

	# found a modified icon
	return 1
      }
    }
    
    # update this canvas to remember which icons were checked
    set data(netlist_level_index) $MODIFY_ICON_LEVEL(_index)
  }

  return 0
}


# generic line to file for cached data.  Doesn't have to do anything special

proc line_to_file {lines} {

  global NETLIST

  puts $NETLIST(file_id) [join $lines \n]
}


# change the NETLIST_TYPE and NETLIST_PROPS string and forget the netlist cache.
# Note that types are currently hardcoded inside

proc change_netlist_props {} {

  global NETLIST_TYPE NETLIST_PROPS NETLIST WIN WIN_DATA command

  set types "verilog dpc spice flat_spice sim"
#  set types "verilog vhdl dpc spice flat_spice sim"
  set default(dpc) verilog
  set default(flat_spice) spice

  set old_netlist_type $NETLIST_TYPE
  set old_netlist_props $NETLIST_PROPS

  set win .change_sim

  # toast the window if it is already there
  catch {destroy $win}

  toplevel $win 

  wm geometry $win [relative_origin]
  wm minsize $win 200 10
  wm title $win "Change Simulation Mode"

  label $win.note1 -text "Select Netlist Type:"
  pack $win.note1 -side top

  set c [frame $win.entry1]
  pack $c -side top
  foreach type $types {
    set b [radiobutton $c.$type \
	       -text $type \
	       -command "set NETLIST_PROPS [use_first default($type) type]" \
	       -variable NETLIST_TYPE \
	       -value $type \
	       -relief raised \
	       -width 12 \
	       -anchor w]
    pack $b -side top 
  }

  # netlist properties
  frame $win.args
  label $win.props -text "Properties:"
  pack $win.props -side left -in $win.args -anchor w -ipady 1

  entry $win.value -textvariable NETLIST_PROPS -relief sunken \
      -bd 2 -highlightthickness 1
  pack $win.value -side left -in $win.args -expand 1 -fill x
  pack $win.args -side top -expand 1 -fill x

  # header
  frame $win.header
  label $win.header.label -text "No Header:"
  pack $win.header.label -side left -anchor w -ipady 1

  # make sure it is defined
  checkbutton $win.header.button -variable NETLIST(no_header) -anchor w 
  pack $win.header.button -side left -fill x -expand 1 
  pack $win.header -side top -expand 1 -fill x

  # done/cancel buttons
  frame $win.buttons

  frame $win.default -relief sunken -bd 1
  button $win.done -text "Done" -padx 1 -pady 1 \
    -command {set command 1}
  pack $win.done -in $win.default -padx 1m -pady 1m -ipadx 2m
  pack $win.default -side left -in $win.buttons \
      -padx 4m -ipadx 1m -pady 1m -expand 1

  # restore old value and exit
  button $win.cancel -text "Cancel" -padx 1 -pady 1 \
    -command {set command 0}
  pack $win.cancel -side left -in $win.buttons \
    -padx 4m -ipadx 2m -pady 1m -expand 1

  pack $win.buttons -side bottom
  pack $c -side top -fill x -expand 1

  # change the cursor and add a message
  update

  set cursor [lindex [$WIN configure -cursor] 4]
  $WIN configure -cursor question_arrow
  set WIN_DATA($WIN,display_msg) "?:  Change Simulation Mode"

  grab set $win

  bind $win <Control-c> {set command 0}
  bind $win <Escape> {set command 0}

  bind $win <Any-Return> {set command 1}

  bind $win <Visibility> "if {{%s} == {VisibilityFullyObscured}} {raise $win}"

  _warp_cursor_window $win.default

  tkwait variable command

  catch "destroy $win"

  focus -force $WIN

  # restore
  $WIN configure -cursor $cursor
  display_selection

  if {$command} {
    # user wants these to stick
    change_netlist_props_internal $old_netlist_type $old_netlist_props
  } else {
    # restore old
    set NETLIST_TYPE $old_netlist_type
    set NETLIST_PROPS $old_netlist_props
  }
}


proc change_netlist_props_internal {{old_netlist_type ""} {old_netlist_props ""}} {

  global NETLIST_TYPE NETLIST_CACHE SUE_DIR WIN auto_index NETLIST_PROPS

  if {[info commands ${NETLIST_TYPE}_netlist] == "" && \
	  ![info exists auto_index(${NETLIST_TYPE}_netlist)]} {
    # invalid netlist type.  
    if {$old_netlist_type == ""} {
      return 0
    }

    set button [tk_dialog .bad_netlist_type "Bad Netlist Type" \
		    "Illegal netlist type \"$NETLIST_TYPE\".  Try Again." \
		    @$SUE_DIR/sue_icon.xbm 0 {ok}]

    set NETLIST_TYPE $old_netlist_type
    set NETLIST_PROPS $old_netlist_props
    # try again
    change_netlist_props
    return
  }

  if {$NETLIST_TYPE != $old_netlist_type || \
	  $NETLIST_PROPS != $old_netlist_props} {
    if {$old_netlist_type != ""} {
      puts "Netlist type/properties changed and netlist cache flushed."
    }

    # forget about what's cached
    catch {unset NETLIST_CACHE}

    # toast the hierarchical design display because it's probably wrong now.
    catch {destroy .design}

    # toast the dpc window
    catch {destroy .cp}
  }

  if {$NETLIST_TYPE != $old_netlist_type} {
    # close any probes that might be around
    global PROBE_TYPE
    if {$PROBE_TYPE != ""} {
      catch "${PROBE_TYPE}_close_probe"
    }

    # set the probe type to the correct flavor
    set type [string toupper $NETLIST_TYPE]_PROBE_TYPE
    global $type PROBE_TYPE
    set PROBE_TYPE [use_first $type]
    # make a new sim menu
    make_sim_menu $WIN

    # save the new bindings
    save_bindings newest

    # increment this number so canvases will know if they have old bindings
    global CURRENT_BINDINGS
    incr CURRENT_BINDINGS
  }

  display_title

  return 1
}


# Allows the user to change the probe type on the fly, for example from
# interactive to simwave (postprocessing).

proc change_probe_type {} {

  global cur_c NETLIST_TYPE PROBE_TYPE WIN

  set types ""
  upvar #0 [string toupper ${NETLIST_TYPE}]_PROBE_CMD cmds
  # No more signalscan4
  foreach type [array names cmds] {
    if {$type != "option" && $type != "signalscan4"} {
      lappend types $type
    }
  }

  if {$types == ""} {
    warning "Aborting, no probe types for \"$NETLIST_TYPE\" simulation."
    return
  }

  set types [lsort $types]

  set winy [expr [winfo rooty $cur_c] + 50]
  set winx [expr [winfo rootx $cur_c] + 50]
  set title "Change Type of $NETLIST_TYPE Probe"
  set message "Enter probe type:" 
  set prop_list [list [list type $PROBE_TYPE radio $types]]

  # create the menu
  set new_prop_list [prop_menu $winx $winy $message $title $prop_list]
  if {$new_prop_list == "" || $new_prop_list == $prop_list} {
    # empty list means the user hit cancel or didn't change anything
    return
  }

  set type [lindex [lindex $new_prop_list 0] 1]
  if {[lsearch $types $type] == -1} {
    puts "Aborting, probe type \"$type\" not valid."
    return
  }

  # close any probes that might be around
  if {$PROBE_TYPE != ""} {
    catch "${PROBE_TYPE}_close_probe"
  }

  # set the probe type to the correct flavor
  global [string toupper $NETLIST_TYPE]_PROBE_TYPE
  set [string toupper $NETLIST_TYPE]_PROBE_TYPE $type
  set PROBE_TYPE $type
  # make a new sim menu
  make_sim_menu $WIN

  puts "Probe type changed to \"$type\"."

  return
}


# make a list of all instances in this schematic that might be
# modified and thus would invalidate a disk-based cache.

proc make_netlist_cache_cells {} {

  global cur_c cur_s NETLIST_CACHE NETLIST_PROPS NETLIST_LEVEL SUE
  global NETLIST_TYPE

  if {[lsearch "verilog dpc" $NETLIST_TYPE] != -1} {
    set save_level 1
  } else {
    set save_level 0
  }

  foreach id [$cur_c find withtag origin] {
    upvar #0 ${cur_s}_inst${id} i_data
    # the type is really the instance name
    set type $i_data(type)

    if {$type == $cur_s} {
      # recursive, must be a comment
      continue
    }

    upvar #0 icon_$type g_data

    # if this id has a property in the icon that matches one of the
    # netlist props, then remember it.  Also remember if it has a schematic.
    if {[get_property_info $type $NETLIST_PROPS] != ""} {
      if {[use_first g_data(generator)] != "" && $type != $g_data(generator)} {
	set creator "generate $g_data(generator) $type $g_data(gargs)"
	set gen_name $g_data(generator)
      } else {
	set creator ""
	set gen_name $type
      }

      if {$save_level && [use_first NETLIST_LEVEL($type)] != ""} {
	set kind [list level $NETLIST_LEVEL($type)]
	
      } elseif {[info exists SUE($type)] || \
		     [info commands SCHEMATIC_$gen_name] != ""} {
	set kind has_schematic

      } else {
	set kind ""
      }

      if {$creator == ""} {
	set inst_cells($type) [list icon $type $kind]
      } else {
      	set inst_cells($type) [list icon $type $creator $kind]
      }

    } elseif {[use_first g_data(generator)] != ""} {
      # if it's a generator and the icon doesn't have the property, assume
      # there is a schematic.  Also must remember how to make the schematic.
      if {$save_level && [use_first NETLIST_LEVEL($type)] != ""} {
	set kind [list level $NETLIST_LEVEL($type)]
      } else {
	set kind ""
      }

      if {[info commands SCHEMATIC_$g_data(generator)] != ""} {
	if {$type != $g_data(generator)} {
	  set creator "generate $g_data(generator) $type $g_data(gargs)"
	  set inst_cells($type) [list schematic $type $creator $kind]
	} else {
	  set inst_cells($type) [list schematic $type $kind]
	}
      }

    } elseif {[info exists SUE($type)] || \
		  [info commands SCHEMATIC_$type] != ""} {
      if {$save_level && [use_first NETLIST_LEVEL($type)] != ""} {
	set inst_cells($type) \
	    [list schematic $type [list level $NETLIST_LEVEL($type)]]
      } else {
	set inst_cells($type) "schematic $type"
      }
    }

    set NETLIST_CACHE($cur_s,cells) ""
    if {[info exists inst_cells]} {
      foreach type [array names inst_cells] {
	lappend NETLIST_CACHE($cur_s,cells) $inst_cells($type)
      }
    }
  }
}


# write out the netlist cache so it can be reread when sue is rerun.

proc write_netlist_cache {{cell ""}} {

  global cur_s SUFFIX NETLIST_CACHE NETLIST_TYPE NETLIST_PROPS auto_index
  global NETLIST_LEVEL VERSION

  if {[lsearch "sim flat_spice" $NETLIST_TYPE] != -1} {
    # these don't get cached.  Called from write_file.
    return
  }

  if {$cell == ""} {
    set cell [get_rootname $cur_s]
  }

  if {[use_first NETLIST_CACHE($cell,error)] != ""} {
    # don't save it if it has errors
    set NETLIST_CACHE($cell) ""
    return
  }

  if {[use_first NETLIST_CACHE($cell)] == ""} {
    # not a valid cache
    return
  }

  upvar #0 SUE_$cell data
  if {[use_first data(modified)] != ""} {
    # don't write out the cache if the cell is modified since if the
    # user doesn't save these changes, the cache is bogus.
    return
  }

  upvar #0 SUE_ICON_$cell icon_data
  if {[use_first icon_data(modified)] != ""} {
    # Icon is modified, punt
    return
  }

  # don't write if any of the subcells are modified since they could
  # have created bogus calls
  foreach pair [use_first NETLIST_CACHE($cell,cells)] {
    setl {type cellname} $pair
    upvar #0 SUE_$cellname cell_data
    if {[use_first cell_data(modified)] != ""} {
      # don't write out the cache
      return
    }
    upvar #0 SUE_ICON_$cellname cell_data
    if {[use_first cell_data(modified)] != ""} {
      # don't write out the cache
      return
    }
  }

  set dir [use_first data(dir) icon_data(dir)]

  upvar #0 icon_$cell g_data
  if {[use_first g_data(generator)] != ""} {
    # this is a generator.
    set genname [lindex [split_filename [use_first g_data(generator)]] 1]
    if {[info exists auto_index(SCHEMATIC_$genname)]} {
      set dir [file dirname [lindex $auto_index(SCHEMATIC_$genname) 1]]/
    }
  }

  set filename \
    "$dir$cell$SUFFIX($NETLIST_TYPE)$SUFFIX(netlist_cache)"

  # Open the file.  If we fail, just punt.
  if {[catch "open $filename w" msg] != 0} {
    # error, probably can't write to directory.  Just skip.
    return
  }
  set file_id $msg

  # first write the names of the subcells
  puts $file_id \
      "set NETLIST_CACHE($cell,cells) [list [use_first NETLIST_CACHE($cell,cells)]]"

  # write the netlist properties since they may change
  puts $file_id "set netlist_props [list $NETLIST_PROPS]"

  # write the current netlist level since they may change
  puts $file_id "set netlist_level $NETLIST_LEVEL(__CURRENT__)"

  # save out the netlist level of this icon if there is one.
  set level [use_first NETLIST_LEVEL($cell)]
  if {[use_first NETLIST_LEVEL($cell)] != ""} {
    set NETLIST_CACHE($cell,level) $NETLIST_LEVEL($cell)
  }

  # write the netlist level if non-nil.
  if {[use_first NETLIST_CACHE($cell,level)] != ""} {
    puts $file_id \
	"set NETLIST_CACHE($cell,level) [list $NETLIST_CACHE($cell,level)]"
  }

  # write the globals (for spice) if there are any
  if {[use_first NETLIST_CACHE($cell,globals)] != ""} {
    puts $file_id \
	"set NETLIST_CACHE($cell,globals) [list $NETLIST_CACHE($cell,globals)]"
  }

  # write any netlist warnings
  if {[use_first NETLIST_CACHE($cell,warnings)] != ""} {
    puts $file_id \
	"set NETLIST_CACHE($cell,warnings) [list $NETLIST_CACHE($cell,warnings)]"
  }

  # finally write the netlist cache info
  # write the sue version since if this changes, need to flush cache
  puts $file_id "set NETLIST_CACHE($cell,version) $VERSION"
  puts $file_id "set NETLIST_CACHE($cell) [list [use_first NETLIST_CACHE($cell)]]"

  # write the names info
  puts $file_id "set NETLIST_CACHE($cell,names) [list [cache_names]]"
  puts $file_id "set NETLIST_CACHE($cell,wires) [list [cache_wire_names]]"

  # write the dpc data if any
  if {[use_first NETLIST_CACHE($cell,dpc)] != ""} {
    puts $file_id \
	"set NETLIST_CACHE($cell,dpc) [list $NETLIST_CACHE($cell,dpc)]"

    puts $file_id \
	"set NETLIST_CACHE($cell,dpc_size) [list $NETLIST_CACHE($cell,dpc_size)]"
  }

  # Close the happy file
  close $file_id
}


# like trace_hierarchy but using the disk cache.  Doesn't need to load
# in all schematics.

proc trace_cached_hierarchy {schematic {level {}}} {

  global cur_c cur_s scale SCHEMS SUE NETLIST_PROPS NETLIST_CACHE
  global NETLIST_TYPE SPICE_EXTRACTED_CELL_PATH SUFFIX

  if {[info exists SCHEMS($schematic)]} {
    # already been here
    return
  }

  check_interrupt

  set SCHEMS($schematic) traced

  # check to see if we should netlist this schematic.

  if {$level == "" && [get_property_info $schematic $NETLIST_PROPS] != ""} {
    # don't need to netlist this cell
    return
  }

  if {[regexp spice $NETLIST_TYPE] && $SPICE_EXTRACTED_CELL_PATH != ""} {
    # lookup to see if we have a readable extracted  netlist for this already

    set file "$schematic$SUFFIX($NETLIST_TYPE)"
    foreach path $SPICE_EXTRACTED_CELL_PATH {
      if {[file readable $path/$file]} {
	# got one
	lappend SCHEMS(_LIST_) $schematic
	set SCHEMS($schematic) [list from $path/$file]
	return
      }
    }
  }

  if {[info exists SUE($schematic)]} {
    # there's a canvas for this schematic

    # save the current canvas, schematic, and scale
    set save_cur_c $cur_c
    set save_cur_s $cur_s
    set save_scale $scale

    # by entering the canvas, we will update any changed icons
    # this is faster and cleaner than going to the schematic
    enter_canvas $schematic

    # Does this have to be netlisted due to changes in its icons?
    if {[icons_changed]} {
      set NETLIST_CACHE($schematic) ""
    }

    if {![info exists NETLIST_CACHE($schematic)]} {
      upvar #0 SUE_$schematic data
      if {[use_first data(modified)] == ""} {
	# cell is not modified
	# try looking for a disk cache as user has never changed this
	get_disk_cache $schematic
	# if there is a disk cache then set the term and inst names
	set_cached_names
      }
    }

    # restore the current canvas, schematic, and scale
    set cur_c $save_cur_c
    set cur_s $save_cur_s
    set scale $save_scale

  } else {
    # no canvas.  We might not need to make one if there is an up-to-date
    # cached netlist.
    get_disk_cache $schematic
    if {$NETLIST_CACHE($schematic) == ""} {
      # cache out of date or nonexistant.
      # need to make a canvas for this schematic.
      if {[goto_schematic $schematic] == ""} {
	sue_error \
	    "NETLIST ERROR: Can't find cell $schematic during netlisting"
	return
      }

      # busy gets reset so we must do it again
      busy

    } else {
      # check spice level stuff
      set spice_level [use_first NETLIST_CACHE($schematic,level)]
      if {($level == "main" || $spice_level == "main") && \
	      $level != [use_first NETLIST_CACHE($schematic,level)]} {
	# wrong spice level
	if {[goto_schematic $schematic] == ""} {
	  sue_error \
	      "NETLIST ERROR: Can't find cell $schematic during netlisting"
	  return
	}

	# busy gets reset so we must do it again
	busy
      }
    }
  }

  if {[info exists SUE($schematic)]} {
    global SUE_$schematic
    set canvas [set SUE_${schematic}(canvas)]

    foreach id [$canvas find withtag origin] {
      upvar #0 ${schematic}_inst${id} i_data
      # the type is really the instance name
      set type $i_data(type)
      upvar #0 icon_$type g_data

      # if this id has a property in the icon that matches one of the
      # netlist props, then we don't have to trace any further
      if {[get_property_info $type $NETLIST_PROPS] != ""} {
	set SCHEMS($type) icon
	continue
      }

      # if this has a schematic, trace down through it's hierarchy
      set genname [lindex [split_filename [use_first g_data(generator)]] 1]
      if {[info exists SUE($type)] || [info commands SCHEMATIC_$type] != "" || \
	      [info commands SCHEMATIC_$genname] != ""} {
	# recurse
	lappend SCHEMS(dpc,$type) $schematic
	trace_cached_hierarchy $type
	# if hasn't been checked yet, check i/o's
	if {$SCHEMS($type) == "traced" && [info exists SUE($type)]} {
	  check_ios $type $id $canvas
	  # mark as checked
	  set SCHEMS($type) checked
	}
      }

      check_interrupt
    }

  } else {
    # use the information from the disk cache to continue the trace through
    # the sub cells that are schematics.
    foreach pair [use_first NETLIST_CACHE($schematic,cells)] {
      if {[lindex $pair 0] == "schematic"} {
	# recurse
	lappend SCHEMS(dpc,[lindex $pair 1]) $schematic
	trace_cached_hierarchy [lindex $pair 1]
      } elseif {[lindex $pair 0] == "icon"} {
	set SCHEMS([lindex $pair 1]) icon
      }
    }
  }

  # busy gets reset so we must do it again
  busy

  lappend SCHEMS(_LIST_) $schematic

  return 
}


# Get the netlist cache from the filesystem if it exists and is up-to-date.

proc get_disk_cache {schematic} {

  global NETLIST_CACHE auto_index SUFFIX NETLIST_TYPE NETLIST_PROPS 
  global NETLIST_LEVEL VERSION

  if {[info exists auto_index(SCHEMATIC_$schematic)]} {
    set dir [file dirname [lindex $auto_index(SCHEMATIC_$schematic) 1]]/
  } elseif {[info exists auto_index(ICON_$schematic)]} {
    set dir [file dirname [lindex $auto_index(ICON_$schematic) 1]]/
  } else {
    # can't even find the file
    set NETLIST_CACHE($schematic) ""
    return
  }

  set cell $schematic

  upvar #0 icon_$schematic g_data
  if {[use_first g_data(generator)] != ""} {
    # this is a generator.
    set genname [lindex [split_filename [use_first g_data(generator)]] 1]
    if {[info exists auto_index(SCHEMATIC_$genname)]} {
      set dir [file dirname [lindex $auto_index(SCHEMATIC_$genname) 1]]/
      set cell $genname
    }
  }

  if {[catch {set date [file mtime $dir$cell$SUFFIX(default)]}] != 0} {
    # can't find SUE file.  Punt.
    set NETLIST_CACHE($schematic) ""
    return
  }

  set cache_filename $dir$schematic$SUFFIX($NETLIST_TYPE)$SUFFIX(netlist_cache)
  if {[catch {set cache_date [file mtime $cache_filename]}] != 0} {
    # no cache file.  Punt.
    set NETLIST_CACHE($schematic) ""
    return
  }

  if {$cache_date < $date} {
    # out of date.  Punt.
    set NETLIST_CACHE($schematic) ""
    return
  }

  # Eureka.

  # Source the cache info file
  if {[catch "source $cache_filename" msg] != 0} {
    # error, huh.  Punt.
    set NETLIST_CACHE($schematic) ""
    set NETLIST_CACHE($schematic,cells) ""
    set NETLIST_CACHE($schematic,names) ""
    return
  }

  if {![info exists NETLIST_CACHE($schematic,cells)]} {
    # file is not valid if it doesn't create this variable, punt.
    set NETLIST_CACHE($schematic) ""
    set NETLIST_CACHE($schematic,cells) ""
    set NETLIST_CACHE($schematic,names) ""
    return
  }

  if {[use_first NETLIST_CACHE($schematic,version)] != $VERSION} {
    # file was built with different version of SUE, flush
    set NETLIST_CACHE($schematic) ""
    set NETLIST_CACHE($schematic,cells) ""
    set NETLIST_CACHE($schematic,names) ""
    set NETLIST_CACHE($schematic,invalid) "wrong version: [use_first NETLIST_CACHE($schematic,version)]"
    return
  }

  # if the subcells are newer than this file, the cache might be corrupted
  # Note that if the cell is in a canvas as an icon it might have also
  # been changed.  Also if a subcell is a generator, we need to make it.
  foreach pair $NETLIST_CACHE($schematic,cells) {
    setl {type cell misc1 misc2} $pair
    set type [string toupper $type]

    # check to see if the netlist level for any subcell has changed.
    if {[lindex $misc1 0] == "level"} {
      set level [lindex $misc1 1]
    } elseif {[lindex $misc2 0] == "level"} {
      set level [lindex $misc2 1]
    } else {
      set level ""
    }

    if {$level != [use_first NETLIST_LEVEL($cell)]} {
      # if NETLIST_LEVEL(__CACHE__) is non-nil, set the cell level
      # Subtle point: if NETLIST_LEVEL is set to nil, it won't be redefined,
      # only if it is unset will it be.
      if {[use_first NETLIST_LEVEL(__CACHE__)] != "" && \
	       ![info exists NETLIST_LEVEL($cell)]} {
	# set the netlist level for this cell
	set NETLIST_LEVEL($cell) $level
      } else {
	# this changed, must renetlist the cell that includes this.
	set netlist_props ""
	continue
      }
    }

    if {[info exists auto_index(${type}_$cell)]} {
      set icon_filename [lindex $auto_index(${type}_$cell) 1]
    } elseif {[lindex $misc1 0] == "generate"} {
      # this is a generator.  Must create the generator.
      if {[catch {uplevel #0 $misc1} msg]} {
	# error, uh oh
	continue
      }
      # get the generator name
      set gen [lindex $misc1 1]
      if {[info exists auto_index(${type}_$gen)]} {
	set icon_filename [lindex $auto_index(${type}_$gen) 1]
      } else {
	# hmm, should exist
	continue
      }
    } else {
      # hmm, should exist
      continue
    }

    if {[catch {set date [file mtime $icon_filename]}] != 0} {
      # hmm, should exist
      continue
    }

    if {$cache_date < $date} {
      # out of date.  Punt.
      set netlist_props ""
      continue
    }

    # invalidate dpc cache if port file newer
    set port_filename [file rootname $icon_filename]$SUFFIX(dpc_ports)
    if {![catch "file mtime $port_filename" port_date]} {
      # port file and cache file.
      if {$cache_date < $port_date} {
        # out of date
	set netlist_props ""
        set NETLIST_CACHE($schematic,dpc) ""
	set NETLIST_CACHE($schematic,invalid) "port file out of date"
      }
    }
  }

  # check that we netlisted with the same netlist properties and level
  if {$netlist_props == $NETLIST_PROPS && \
	  [use_first netlist_level] == $NETLIST_LEVEL(__CURRENT__)} {
    # netlist cache is good!
    set NETLIST_CACHE($schematic,cache_type) "disk cached"
    set NETLIST_CACHE($schematic,date) $cache_date

    # special for dpc
    if {[info exists NETLIST_CACHE($schematic,dpc)]} {
      # remove id's for assigns.  Recompute them later
      regsub -all {\{id ([0-9]+)} $NETLIST_CACHE($schematic,dpc) \
	  "\{id \"\"" NETLIST_CACHE($schematic,dpc)
    }

  } else {
    set NETLIST_CACHE($schematic) ""
    set NETLIST_CACHE($schematic,cells) ""
    set NETLIST_CACHE($schematic,names) ""
  }
}


# returns a list of term and origin (i.e. instance) names based on
# coordinates.  Will be written to the disk cache.

proc cache_names {} {

  global cur_c cur_s scale
  upvar #0 TERMS_$cur_s TERMS

  # Scale the canvas to "10" for remembering names
  set old_scale $scale
  scale_canvas 10

  set del [expr $scale/3.0]

  set tmplist "[$cur_c find withtag term] [$cur_c find withtag origin]"
  foreach to_id $tmplist {
    if {[info exists traced($to_id)]} {
      # already been here
      continue
    }

    set center [round_list [center $to_id]]
    setl {x y} $center
    
    set ids [$cur_c find enclosed [expr $x - $del] [expr $y - $del] \
		 [expr $x + $del] [expr $y + $del]]
    foreach id $ids {
      # remember that we've been here
      set traced($id) 1
      
      if {[use_first TERMS($id)] != ""} {
	lappend info($center) "[lsearch $ids $id] $TERMS($id)"
      }
    }
  }

  set list ""
  if {[info exists info]} {
    foreach item [array names info] {
      lappend list "$item $info($item)"
    }
  }

  # restore the scale
  scale_canvas $old_scale

  return $list
}


# returns a list of coords and name for all wires.  Will be written to
# the disk cache.

proc cache_wire_names {} {

  global cur_c cur_s scale
  upvar #0 TERMS_$cur_s TERMS

  # Scale the canvas to "10" for remembering names
  set old_scale $scale
  scale_canvas 10

  set list ""
  foreach id [$cur_c find withtag wire] {
    
    if {[use_first TERMS($id)] != ""} {
      # save it away
      setl {x1 y1 x2 y2} [round_list [$cur_c coords $id]]

      if {$x2 < $x1 || $y2 < $y1} {
	lappend list "$x2 $y2 $x1 $y1 $TERMS($id)"
      } else {
	lappend list "$x1 $y1 $x2 $y2 $TERMS($id)"
      }
    }
  }

  # restore the scale
  scale_canvas $old_scale

  return $list
}


# sets the term names and instance names based on the disk cached information

proc set_cached_names {{load ""}} {

  global cur_c cur_s scale NETLIST_CACHE NETLIST_TYPE SHOW_WIRE_WIDTH
  global DPC_TIMING NETLIST_PROPS DPC HIERARCHY
  upvar #0 TERMS_$cur_s TERMS

  if {[use_first NETLIST_CACHE($cur_s,names)] == ""} {
    # doesn't exist

    # Only consider if in dpc and pushed into a cell that doesn't
    # have a netlist cache.
    if {[use_first DPC(CELLS)] != "" && $HIERARCHY != "" && \
	    $DPC_TIMING(simulator) == "pathmill" && $NETLIST_TYPE == "dpc"} {
      # very special case of mixed verilog/spice timing analysis
      # change to spice mode
      set NETLIST_TYPE spice
      set save_props $NETLIST_PROPS
      set NETLIST_PROPS spice

      get_disk_cache $cur_s

      # restore
      set NETLIST_TYPE dpc
      set NETLIST_PROPS $save_props
      
      if {$NETLIST_CACHE($cur_s) == ""} {
	# couldn't find cache file
	unset NETLIST_CACHE($cur_s)

	puts "TIMING WARNING: no up-to-date spice netlist cache for cell \"$cur_s\"."
	menu_generate_term_names
	return
      }

      if {[use_first NETLIST_CACHE($cur_s,names)] == ""} {
	# still nothing, punt
	puts "TIMING WARNING: no up-to-date spice netlist cache for cell \"$cur_s\"."
	menu_generate_term_names
	return
      }

    } else {
      return
    }
  }

  # there is a chance that someone else has gone and changed this 
  # schematic after you have read in the disk cache but before you
  # actually push into the cell.  However, since we don't konw when
  # the file is actually autoloaded we can't fix this!!!!
  
  # Scale the canvas to "10" for restoring names
  set old_scale $scale
  scale_canvas 10

  set del [expr $scale/3.0]

  foreach list $NETLIST_CACHE($cur_s,names) {
    setl {x y} $list
    
    set ids [$cur_c find enclosed [expr $x - $del] [expr $y - $del] \
		 [expr $x + $del] [expr $y + $del]]

    foreach pair [lrange $list 2 end] {
      set TERMS([lindex $ids [lindex $pair 0]]) [lindex $pair 1]
    }
  }

  # now add names to wires
  foreach list [use_first NETLIST_CACHE($cur_s,wires)] {
    setl {x1 y1 x2 y2 net} $list
    
    $cur_c addtag tmp_tag enclosed [expr $x1 - $del] [expr $y1 - $del] \
	[expr $x2 + $del] [expr $y2 + $del]

    foreach id [get_intersect_tag wire tmp_tag] {
      set TERMS($id) $net
    }

    $cur_c dtag tmp_tag
  }

  # restore the scale
  scale_canvas $old_scale

  # so generate_term_names doesn't need to be run
  upvar #0 SUE_$cur_s data
  set data(modified_term_names) ""

  set NETLIST_CACHE($cur_s,names) ""
  set NETLIST_CACHE($cur_s,wires) ""

  upvar #0 RTERMS_$cur_s RTERMS
  catch {unset RTERMS}

  if {$SHOW_WIRE_WIDTH} {
    show_wire_width
  }
}


# Get the netlisting property line from the icon.  Search through the
# NETLIST_PROPS to find one that is defined and is not precluded by the
# current NETLIST_LEVEL. 

proc get_property_info {type props} {

  global NETLIST_LEVEL SUE
  upvar #0 icon_$type g_data

  if {[info exists NETLIST_LEVEL($type)]} {
    set level $NETLIST_LEVEL($type)
  } elseif {[info exists g_data(_netlist_level)]} {
    set level $g_data(_netlist_level)
    set NETLIST_LEVEL($type) $level
  } else {
    set level 0
  }

  if {$level >= $NETLIST_LEVEL(__CURRENT__)} {
    # skip all properties (i.e. use schematic) if there is a schematic to use.
    set gen_name [use_first g_data(generator) type]
    if {[info exists SUE($type)] || [info_proc SCHEMATIC_$gen_name] != ""} {
      # use the schematic
      return ""
    }
  }

  # walk through global simulation properties in order to try to
  # find one that is defined in this icon.
  foreach prop $props {
    if {[use_first g_data(_$prop)] != ""} {
      # got one
      return $g_data(_$prop)
    }
  }

  # no property data
  return ""
}


# Used to select by name.  Looks up in the RTERMS array.
# Checks for bits of buses.

proc find_by_name {name {search all} {mode interactive}} {

  global cur_s cur_c

  upvar #0 TERMS_$cur_s TERMS
  upvar #0 RTERMS_$cur_s RTERMS

  if {![info exists RTERMS]} {
    if {[info exists TERMS]} {
      # make the reverse array to speed up find_by_name
      make_reverse_terms_array

    } else {
      # haven't netlisted yet
      menu_generate_term_names

      if {[info exists TERMS]} {
	# make the reverse array to speed up find_by_name
	make_reverse_terms_array
      }
    }
  }

  set result ""

  # first look for an exact name match

  if {[string first * $name] != -1} {
    # wild card search
    set ids ""
    foreach one [array names RTERMS $name] {
      eval lappend ids $RTERMS($one)
    }

    set wildcard 1

  } else {
    set ids [use_first RTERMS($name)]
    set wildcard 0
  }

  foreach id $ids {

    if {[$cur_c coords $id] == ""} {
      # might be part of a bused instance
      set id [lindex [split $id ,] 1]
      if {[$cur_c coords $id] == ""} {
	# this id was deleted or is not right somehow
	continue
      }
    }

    switch $search {

      first {
	return $id
      }

      term {
	if {[is_tagged $id term]} {
	  return $id
	}
      }

      terms {
	if {[is_tagged $id term]} {
	  lappend result $id
	}
	continue
      }
    }

    lappend result $id
  }

  if {$result != ""} {
    # got it
    return $result
  }

  if {$wildcard} {
    # wild card search, we're done
    return $result
  }

  # now look for a root name match
  set root [bus_root $name]

  set ids ""
  foreach one [array names RTERMS "${root}\\\[*"] {
    if {$one != $name} {
      eval lappend ids $RTERMS($one)
    }
  }

  foreach id $ids {

    if {[$cur_c coords $id] == ""} {
      # this id was deleted or is not right somehow
      continue
    }

    if {![info exists TERMS($id)] || ![cbus_subset $name $TERMS($id)]} { 
      continue
    }

    switch $search {

      first {
	return $id
      }

      term {
	if {[is_tagged $id term]} {
	  return $id
	}
      }

      terms {
	if {[is_tagged $id term]} {
	  lappend result $id
	}
	continue
      }
    }

    lappend result $id
  }

  return $result
}


# need to have netlisted first

proc list_design {{schematic ""} {prefix ""}} {

  global cur_s NETLIST_CACHE LIST EXCLUDE_ICONS NETLIST_LEVEL

  # if schematic is nil, reset everything and start from the top
  if {$schematic == ""} {
    set schematic [get_rootname $cur_s]

    set LIST ""
  }

  foreach cell [use_first NETLIST_CACHE($schematic,cells)] {
    setl {type name args1 args2} $cell

    if {$name == $schematic} {
      # comment, skip
      continue
    }

    set skip 0
    foreach exclude $EXCLUDE_ICONS {
      if {[lsearch $name $exclude] != -1} {
	# don't include this cell
	set skip 1
	break
      }
    }
    if {$skip} {
      continue
    }

    if {$args1 == "has_schematic" || $args2 == "has_schematic"} {
      set info "- "
    } elseif {$type == "schematic" && [use_first NETLIST_LEVEL($name)] != ""} {
      set info "> "
    } else {
      set info "  "
    }

    lappend LIST "$prefix$info[string toupper [string index $type 0]] $name"

    if {$type == "schematic"} {
      list_design $name "$prefix  "
    }
  }
}


proc create_design_listbox {} {

  global cur_s LIST GEOMETRY NETLIST LISTBOX_FONT HIERARCHY SUE_DIR

  if {[use_first NETLIST(root)] == ""} {
    # user hasn't netlisted yet, so do it from here.
    netlist
  } else {
    if {$cur_s != $NETLIST(root)} {
      # not in top level.  are we pushed down from
      if {[lindex [split [lreverse $HIERARCHY] ,] 0] != $NETLIST(root)} {
	# different -- query the user
	set button [tk_dialog .query "Display Design Hierarchy" \
	   "This schematic is not in the current netlist hierarchy:" \
	   @$SUE_DIR/sue_icon.xbm 0 {Cancel} {Make this the new top level} \
			"Goto $NETLIST(root)"]

	if {$button == 0} {
	  # user hit the cancel key
	  return
	}

	if {$button == 1} {
	  # new top level
	  netlist
	} else {
	  # goto other top level
	  goto_schematic $NETLIST(root)
	}
      }
    }
  }

  # get the design info
  list_design

  # now build a top level listbox

  set win .design

  if {[winfo exists $win]} {
    # deiconify and raise the window
    wm deiconify $win
    raise $win

    # clean out old listbox
    $win.names delete 0 end

  } else {
    # build a toplevel window
    toplevel $win 

    wm geometry $win $GEOMETRY(design_hierarchy)
    wm title $win "$NETLIST(root) hierarchy"
    wm min $win 0 0

    bind $win <Unmap> {map_others %W "wm iconify"}
    bind $win <Map> {map_others %W "wm deiconify"}

    bind $win <Control-c> "catch \"destroy $win\""
    bind $win <Any-Return> {launch netlist_from_hierarchy_display}

    frame $win.buttons

    frame $win.default -relief sunken -bd 1
    button $win.done -text "Netlist" -padx 1 -pady 1 \
	-command {launch netlist_from_hierarchy_display}
    pack $win.done -in $win.default -padx 1m -pady 1m -ipadx 2m
    pack $win.default -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m -expand 1
    
    button $win.cancel -text "Close" -padx 1 -pady 1 \
	-command "catch \"destroy $win\""
    pack $win.cancel -side left -in $win.buttons \
	-padx 4m -ipadx 2m -pady 1m -expand 1

    pack $win.buttons -side bottom

    scrollbar $win.scroll -command "$win.names yview" -highlightthickness 0

    pack $win.scroll -side right -fill y
    # need to use a fixed width font here
    listbox $win.names -yscrollcommand "$win.scroll set" \
	-highlightthickness 0 -exportselection 0
    pack $win.names -side left -fill both -expand 1

    # need to use a fixed width font here
    $win.names configure -font $LISTBOX_FONT

    set selected \
	"\[string range \[$win.names get \[$win.names curselection\]\] 0 end\]"

    bind $win.names <Motion> \
	{%W selection clear 0 end; %W selection set [%W nearest %y]} 
    # single click on button-1 changes nelist status
    bind $win.names <Button-1> "change_netlist_status"
  }

  # Now put the design list into it
  foreach line $LIST {
    $win.names insert end $line
  }
}


proc change_netlist_status {} -desc {

called from design hierarchy box to change the netlist status of a cell

} {

  global NETLIST_LEVEL NETLIST_CACHE MODIFY_ICON_LEVEL NETLIST

  set win .design

  # get the selected line
  set selection [$win.names curselection]

  if {$selection == ""} {
    # sometimes TK screws up and leaves nothing selected
    return
  }

  set line [string range [$win.names get $selection] 0 end]

  set spaces [expr [string first "- " $line] + [string first "> " $line]]

  if {[lindex $line 0] == "-"} {
    # used an icon, now use the schematic 
    set name [lindex $line 2]
    set value [expr 2 * $NETLIST_LEVEL(__CURRENT__)]
    set NETLIST_LEVEL($name) $value

    set MODIFY_ICON_LEVEL([incr MODIFY_ICON_LEVEL(_index)]) $name

    change_hierarchy_display $line "> S $name <<<<<" "..." $spaces

  } elseif {[lindex $line 0] == ">"} {
    # BUG: should check properties in icon to see if this is possible
    # maybe this should be done in list_design
#xxxxxx

    # used the schematic, now use the icon
    set name [lindex $line 2]
    # don't unset this, only set it to nil
    set NETLIST_LEVEL($name) ""

    set MODIFY_ICON_LEVEL([incr MODIFY_ICON_LEVEL(_index)]) $name

    change_hierarchy_display $line "- I $name <<<<<" "" $spaces

  } else {
    puts "Aborting, Can't change status of [lindex $line 1]."
    return 0
  }
}


# called from the display hierarchy window

proc netlist_from_hierarchy_display {} {

  global NETLIST_CACHE NETLIST

  # flush the cache
  catch {unset NETLIST_CACHE}

  # now renetlist after returning to the top cell
  if {[use_first NETLIST(root)] != ""} {
    goto_schematic $NETLIST(root)
  }

  netlist

  display_title
}


# Changes display when user has clicked on something.

proc change_hierarchy_display {line new_line next_line spaces} {

  set win .design

  set space [string range "                                        " 0 $spaces]

  # find all instances of this line in the listbox
  set index 0
  foreach element [$win.names get 0 end] {
    if {$element == $line} {
      # found a match, replace it
      $win.names delete $index
      $win.names insert $index "$space$new_line"
      if {$next_line != ""} {
	# add this line
	incr index
	$win.names insert $index "$space    $next_line"
      } else {
	# now toast anything below this to next of same level
	for {set i [expr $index + 1]} {1} {incr i} {
	  if {[catch {set tmp [$win.names get $i]}]} {
	    # must be the end of the listbox
	    break
	  }
	  if {[string first ... $tmp] != -1} {
	    # close what was just opened
	    $win.names delete $i
	    break
	  }

	  # replace and - or > with a space
	  regsub {\-|\>} $tmp " " tmp
	  if {"$space    " == [string range $tmp 0 [expr $spaces + 4]]} {
	    $win.names delete $i
	    incr i -1
	  } else {
	    break
	  }
	}
      }
      # make sure this is selected (bug in TK) -- this doesn't fix it.
      $win.names selection set $index
    }

    incr index
  }
}


# changes the width of buses to be fatter than scalar wires.

proc show_wire_width {} {

  global cur_c cur_s scale
  upvar #0 TERMS_$cur_s TERMS

  foreach id [$cur_c find withtag wire] {

    if {![info exists TERMS($id)]} {
      # not a bus
      $cur_c dtag $id bus
      $cur_c itemconfigure $id -width 1

    } elseif {[cbus_width $TERMS($id)] > 1} {
      # this is a bus
      $cur_c addtag bus withtag $id

    } elseif {[regexp {^([0-9]+)'} $TERMS($id) tmp width] && $width > 1} {
      # bus connected to a global
      $cur_c addtag bus withtag $id

    } else {
      # not a bus
      $cur_c dtag $id bus
      $cur_c itemconfigure $id -width 1
    }
  }

  $cur_c itemconfigure bus -width [expr int(floor($scale)) / 4 + 1]
  $cur_c itemconfigure bus -capstyle round
}



# called from menu

proc menu_generate_term_names {} {

  global cur_s

  puts "Generating terminal names for \"$cur_s\" ..."

  busy

  generate_term_names

  display_selection

  ready

  puts "done."
}


# New version of generate_term_names
# Allows concatenated buses (should eliminate need for most assigns).
# All globals prefixed by CC (for create_connectivity).

proc generate_term_names {{type ""}} {

  global cur_c cur_s scale TERM_PRIORITY CC_TRACE CC_COORDS CC_UNNAMED CC_TMP
  global NET_INDEX CC_ROOTS CC_NET_ROOTS SHOW_WIRE_WIDTH CC_RANGE CC_IMPLICIT
  global CC_NET CC_NET_INDEX TERM_LIST NAMES CC_SUGGEST CC_SUGGEST_NAMES
  global CREATE_SUGGESTED_NAMES

  upvar #0 TERMS_$cur_s TERMS
  upvar #0 RTERMS_$cur_s RTERMS

  upvar #0 SUE_$cur_s data

  if {$data(modified_term_names) == $type && [info exists TERMS]} {
    # no need to run
    return
  }

  if {[info exists TERMS]} {
    # must save inst names that aren't primitives -- so we don't lose them
    foreach id [$cur_c find withtag origin] {

      upvar #0 ${cur_s}_inst$id i_data
      upvar #0 icon_$i_data(type) g_data
      if {[info exists g_data(_primitive)]} {
	continue
      }

      if {[info exists TERMS($id)]} {
	set save($id) $TERMS($id)
      }
    }

    # now erase any existing TERMS data structure
    catch {unset TERMS}

    foreach id [array names save] {
      set TERMS($id) $save($id)
    }
  }

  catch {unset RTERMS}

  # clear annotations
  api_clear_annotations

  set NET_INDEX 0

  integer_scale

  if {$type != "flat"} {
    # Used to generate unique names in subcircuits/modules.
    catch {unset NAMES}
    set NAMES(_unique) 0
  }

  catch {unset TERM_LIST}

  catch {unset CC_COORDS}
  catch {unset CC_ROOTS}
  catch {unset CC_RANGE}
  catch {unset CC_IMPLICIT}
  catch {unset CC_NET}
  catch {unset CC_NET_ROOTS}
  catch {unset CC_SUGGEST}
  catch {unset CC_SUGGEST_NAMES}
  set CC_NET_INDEX 0

  # find all terminals

  # Ignore terminals on recursive icons
  set ids [$cur_c find withtag icon_$cur_s]
  foreach id $ids {
    # this is a recursive icon
    foreach id_int [$cur_c find withtag inst$id] {
      set IGNORE($id_int) 1
    }
  }

  # NOTE: important that terms come before wires in CC_COORDS

  set name_terms ""
  set root_name_terms ""
  foreach id [$cur_c find withtag term] {
    if {[info exists IGNORE($id)]} {
      # on a recursive icon, ignore
      continue
    }
    
    set coord [round_list_scale [center $id] $scale]
    lappend CC_COORDS($coord) "term $id"

    # save away the name and priority of this term in TERMS($id,name)
    # and TERMS($id,priority)
    get_term_info $id

    if {$TERMS($id,priority) >= $TERM_PRIORITY(io)} {
      # can't overlap name terminals
      if {[info exists TRACE($coord)]} {
	set id2 $TRACE($coord)

	if {$TERMS($id,name) != $TERMS($id2,name)} {
	  # not same name
	  sue_error "NETLIST ERROR: Can't overlap $TERMS($id,type) \"$TERMS($id,name)\" ([find_origin $id]) and $TERMS($id2,type) \"$TERMS($id2,name)\" ([find_origin $id2]) in schematic \"$cur_s\"." $cur_s
	  continue
	}
      }

      set TRACE($coord) $id

      set name $TERMS($id,name)
      if {$name == ""} {
	# ignore blank name_nets
	if {$TERMS($id,priority) != $TERM_PRIORITY(name)} {
	  sue_error "NETLIST ERROR: Unnamed $TERMS($id,type) ([find_origin $id]) in schematic \"$cur_s\"." $cur_s
	}
	continue
      }

      set TERMS($id) $name

      # save away special terms that have names
      set TERMS($id,root) [cbus_root $name]
      if {$TERMS($id,root) != ""} {
	# has a root name -- ordered first
	lappend root_name_terms [list $id $coord]

	if {$TERMS($id,priority) != $TERM_PRIORITY(name)} {
	  # can't change this
	  foreach root $TERMS($id,root) {
	    set IMMUTABLE($root) 1
	  }
	}

      } else {
	if {$TERMS($id,priority) == $TERM_PRIORITY(io)} {
	  # I/O's need root names
	  sue_error "NETLIST ERROR: Unnamed (no root) $TERMS($id,type) $name ([find_origin $id]) in schematic \"$cur_s\"." $cur_s
	  continue
	}

	lappend name_terms [list $id $coord]
      }

    } elseif {$TERMS($id,priority) == $TERM_PRIORITY(suggest)} {
      # remember suggested, make a root if isn't
      set TERMS($id,suggest) [bus_root $TERMS($id,name)]
      set CC_SUGGEST_NAMES($TERMS($id,suggest)) 1
    }
  }

  # Now get all the wires
  foreach id [$cur_c find withtag wire] {
    set wire [round_list_scale [$cur_c coords $id] $scale]

    lappend CC_COORDS([lrange $wire 0 1]) [list wire $id [lrange $wire 2 3]]
    lappend CC_COORDS([lrange $wire 2 3]) [list wire $id [lrange $wire 0 1]]
  }

  # base connectivity established, now use it

  # find all connected nets
  # look for buses without roots
  # connect nets by name
  # figure out min/max of buses -- in CC_RANGE
  # figure out implicit stuff -- in CC_IMPLICIT

  catch {unset CC_TRACE}
  catch {unset CC_UNNAMED}

  # make an array of all coords.  Unset when visited by named stuff
  # which leaves unnamed nets.
  foreach coord [array names CC_COORDS] {
    set CC_UNNAMED($coord) 1
  }

  set CC_TMP ""
  foreach term [concat $root_name_terms $name_terms] {
#    setl {id coord} $term
    set coord [lindex $term 1]

    if {[info exists CC_TRACE($coord)]} {
      # already got this one
      continue
    }

    set id [lindex $term 0]
    # find this connected net and get roots
    _cc_find_root $coord "" ""

    if {$CC_TMP != ""} {
      # no root or name, make one up
      set root [_cc_make_root_name $CC_TMP]

      foreach id_tmp $CC_TMP {
	set TERMS($id_tmp,root) $root

	if {[info exists TERMS($id_tmp)]} {
	  # add range for unnamed
	  lappend CC_RANGE($root) $TERMS($id_tmp)
	}
      }

      # just save last coord.  Can't be connected by name to anything else
      lappend CC_ROOTS($root) $coord

      set CC_TMP ""

    } else {
      # transfer roots to permanent array

      foreach root [array names CC_NET_ROOTS] {
	lappend CC_ROOTS($root) $CC_NET_ROOTS($root)
      }

      catch {unset CC_NET_ROOTS}
    }
  }

  # change names of buses that don't have bus ranges but should
  foreach root [array names CC_RANGE] {
    set CC_RANGE($root) [bus_extent $CC_RANGE($root)]
  }

  # iii implicit
  foreach root [array names CC_IMPLICIT] {
    # not implicit if any root either I/O or global
    if {$CC_IMPLICIT($root) > 1 && ![info exists IMMUTABLE($root)] && \
	    ![info exists CC_RANGE($root)]} {
      # this is an implicit bus
      set CC_RANGE($root) "\[[expr $CC_IMPLICIT($root) - 1]:0\]"
    }
  }

  foreach rootplus [array names CC_NET implicit,*] {
    set root [lindex [split $rootplus ,] 1]

    if {[info exists CC_IMPLICIT($root)]} {
      continue
    }

    # not implicit if any root either I/O or global
    if {$CC_NET($rootplus) > 1 && ![info exists IMMUTABLE($root)] && \
	    ![info exists CC_RANGE($root)]} {
      # this is an implicit bus
      set CC_RANGE($root) "\[[expr $CC_NET($rootplus) - 1]:0\]"
    }
  }

  foreach term $root_name_terms {
#    setl {id coord} $term
    set id [lindex $term 0]

    foreach root $TERMS($id,root) {
      if {[info exists CC_RANGE($root)]} {
	if {[regsub -all "(^|,)($root)(,|\$)" $TERMS($id) \
		 "\\1\\2$CC_RANGE($root)\\3" TERMS($id)]} {
	  # made a substitution.  If it was an I/O or global -- error
	  if {$TERMS($id,priority) == $TERM_PRIORITY(io) || \
		  $TERMS($id,priority) == $TERM_PRIORITY(global)} {
	    sue_error "NETLIST ERROR: scalar $TERMS($id,type) ([find_origin $id]) on bus in schematic \"$cur_s\"." $cur_s
	  }
	}
      }
    }
  }

  # combine nets with the same roots
  foreach root [array names CC_ROOTS] {
    if {[lindex $CC_ROOTS($root) 1] != ""} {
      # must combine
      set first_coord ""
      foreach coord $CC_ROOTS($root) {
	if {$first_coord == ""} {
	  set first_coord $coord
	} else {
	  # combine with a bogus wire (id = -1)
	  lappend CC_COORDS($first_coord) [list wire -1 $coord]
	  lappend CC_COORDS($coord) [list wire -1 $first_coord]
	}
      }
      set CC_ROOTS($root) [list $first_coord]
    }
  }

  # compute the wire names and error messages
  for {set i 1} {$i <= $CC_NET_INDEX} {incr i} {
    set max 0
    foreach id $CC_NET(term,$i) {
      set this [cbus_width $TERMS($id)]
      if {$this > $max} {
	set max $this
	set max_name $TERMS($id)
	set max_id $id
      }
    }

#puts "$max_name $max_id --> $CC_NET(term,$i)"

    # now check for errors in bus naming
    foreach id $CC_NET(term,$i) {
      if {$id == $max_id} {
	# don't worry about self
	continue
      }

      set subset 0
      foreach one $TERMS($id,root) {
	if {[lsearch $TERMS($max_id,root) $one] != -1} {
	  # subset
	  set subset 1
	  break
	}
      }

      if {!$subset} {
	# try the other way
	foreach one $TERMS($max_id,root) {
	  if {[lsearch $TERMS($id,root) $one] != -1} {
	    # subset
	    set subset 1
	    break
	  }
	}

	if {!$subset} {
	  sue_error "NETLIST ERROR: Connected buses must be related unlike \"$TERMS($id,root)\" ([find_origin $id]) and \"$TERMS($max_id,root)\" ([find_origin $max_id]) in schematic \"$cur_s\"." $cur_s
	}
      }
    }

    # save the max name for later use
    set CC_NET(term,$i) $max_name
  }

  # now repeat above for nets with nothing named on them
  foreach coord [array names CC_UNNAMED] {

    if {![info exists CC_UNNAMED($coord)]} {
      # already got this one
      continue
    }

    # find this connected net
    _cc_find_root $coord "" ""

    # no root or name, make one up
    set root [_cc_make_root_name $CC_TMP]

    # iii implicit
    set width 0
    foreach id $CC_TMP {
      if {$TERMS($id,dir) == "output"} {
	# output terminal, get width for implicit stuff

	upvar #0 ${cur_s}_inst[find_origin $id] i_data

	# ignore primitives -- e.g. bus_combines have outputs
	upvar #0 icon_$i_data(type) g_data
	if {[info exists g_data(_primitive)]} {
	  continue
	}

	set width [bus_width $TERMS($id,name)]
	if {[info exists i_data(_name)] && $i_data(_name) != ""} {
	  # multiply by width of name 
	  set width [expr $width * [bus_width [lookup_name $i_data(_name)]]]
	}
	break
      }
    }

    if {$width == 0} {
      # special case, no output
      foreach id $CC_TMP {
	# get max width of anything not a primitive
	upvar #0 ${cur_s}_inst[find_origin $id] i_data

	# ignore primitives -- e.g. bus_combines have outputs
	upvar #0 icon_$i_data(type) g_data
	if {[info exists g_data(_primitive)]} {
	  continue
	}

	set this_width [bus_width $TERMS($id,name)]
	if {[info exists i_data(_name)] && $i_data(_name) != ""} {
	  # multiply by width of name 
	  set this_width \
	      [expr $this_width * [bus_width [lookup_name $i_data(_name)]]]
	}

	if {$this_width > $width} {
	  set width $this_width
	}
      }
    }

    # just save last coord.  Can't be connected by name to anything else
    lappend CC_ROOTS($root) $coord

    if {$width > 1} {
      # implicit bus
      set bus "\[[expr $width - 1]:0\]"
      set CC_RANGE($root) $bus
      set root "$root$bus"

      # special case for tracing -- get root right at start
      set cc_imp_bus($coord) $root
    }

    foreach id_tmp $CC_TMP {
      set TERMS($id_tmp) $root

      # add to terminal list
      lappend TERM_LIST([find_origin $id_tmp]) \
	  "$TERMS($id_tmp,name) $TERMS($id_tmp)"
    }

    set CC_TMP ""
  }

  # propagate from known names: I/O's, globals, and name_nets
  # or from a coord on an unnamed net.
  catch {unset CC_TRACE}

  foreach name [array names CC_ROOTS] {
    set CC_TRACE(_dir_) ""
    set CC_TRACE(_input_) 0
    set CC_TRACE(_output_) 0
    set CC_TRACE(_inout_) 0

    set coord [lindex $CC_ROOTS($name) 0]
    if {[info exists cc_imp_bus($coord)]} {
      set name $cc_imp_bus($coord)
    }
    _cc_prop_names $coord $name

# puts "$CC_TRACE(_dir_) --> $CC_TRACE(_output_) && $CC_TRACE(_input_)"

    # check for illegal connections
    switch $CC_TRACE(_dir_) {
      input {
	if {$CC_TRACE(_output_) && !$CC_TRACE(_input_) && !$CC_TRACE(_inout_)} {
	  set id $CC_TRACE(_dirid_)
	  sue_error "NETLIST ERROR: $TERMS($id,type) \"$TERMS($id)\" ([find_origin $id]) only connected to outputs in schematic \"$cur_s\"." $cur_s
	}
      }
      output {
	if {!$CC_TRACE(_output_) && !$CC_TRACE(_inout_) && $CC_TRACE(_input_)} {
	  set id $CC_TRACE(_dirid_)

#puts "--> o $CC_TRACE(_output_) i $CC_TRACE(_input_) io $CC_TRACE(_inout_) d $CC_TRACE(_dir_)"

	  sue_error "NETLIST ERROR: $TERMS($id,type) \"$TERMS($id)\" ([find_origin $id]) only connected to inputs in schematic \"$cur_s\"." $cur_s
	}
      }
    }
  }

  unscale

  # save the internal nets
  foreach one [array names CC_ROOTS] {
    if {![info exists IMMUTABLE($one)] && ![regexp {'(b|h|d|o)} $one]} {
      if {[info exists CC_RANGE($one)]} {
	lappend TERMS(internal_nets) "$one$CC_RANGE($one)"
      } else {
	lappend TERMS(internal_nets) $one
      }
    }
  }

  # toast any worthless suggested_names
  set ids ""
  foreach string [array names TERMS *,suggest] {
    lappend ids [find_origin [lindex [split $string ,] 0]]
  }

  if {!$data(generator) && !$data(read_only)} {
    # only on not read-only stuff (includes generators)

    if {[llength $ids] > 0} {
      # toast'm
      delete_selected $ids "" batch

      is_modified
    }

    # add new suggested names
    if {$CREATE_SUGGESTED_NAMES && [info exists CC_SUGGEST]} {
      # create suggested names for next time
      set save_scale $scale
      scale_canvas 10
      
      set ids ""

      generate name_net_s suggested_name -cell suggested_name
      foreach root [array names CC_SUGGEST] {
	foreach id $CC_SUGGEST($root) {
	  if {[is_tagged $id term]} {
	    # found a term, put it here
	    if {[is_tagged $id rotate]} {
	      # find origin of cell, orient suggested_name away from
	      # NOTE: sometime origin is lower left

	      set yo [lindex [$cur_c coords [find_origin $id]] 1]
	      set y [lindex [$cur_c coords $id] 1]
	      if {$y < $yo} {
		# on top
		lappend ids [make suggested_name -name $root -origin [center $id] -orient R90Y]
	      } else {
		# on bottom
		lappend ids [make suggested_name -name $root -origin [center $id] -orient R90]
	      }
	    } else {
	    
	      # find origin of cell, orient suggested_name away from
	      # NOTE: sometime origin is lower left

	      set xo [lindex [$cur_c coords [find_origin $id]] 0]
	      set x [lindex [$cur_c coords $id] 0]
	      if {$x > $xo} {
		# on right
		lappend ids [make suggested_name -name $root -origin [center $id]]
	      } else {
		# on left
		lappend ids [make suggested_name -name $root -origin [center $id] -orient RX]
	      }
	    }

	    break
	  }
	}
      }

      if {[llength $ids] != 0} {
	# save undo information
	setup_undo $ids ""

	foreach id $ids {
	  eval show_connect_point [center $id]
	}

	is_modified
      }

      scale_canvas $save_scale
    }
  }

  if {$SHOW_WIRE_WIDTH} {
    show_wire_width
  }

  set data(modified_term_names) $type
}


# trace all nets.  Look for unnamed.  Create names for unnamed.

proc _cc_find_root {coord current_root net_id} {

  global cur_s TERM_PRIORITY CC_TRACE CC_COORDS CC_TMP CC_UNNAMED CC_NET_ROOTS
  global CC_RANGE CC_IMPLICIT CC_NET CC_NET_INDEX

  if {[info exists CC_TRACE($coord)]} {
    # already been here
    return
  }
  set CC_TRACE($coord) ""

  upvar #0 TERMS_$cur_s TERMS

  # traced this so eliminate it
  unset CC_UNNAMED($coord)

  set new ""

  foreach pair $CC_COORDS($coord) {
#    setl {type id} $pair
    set type [lindex $pair 0]
    set id [lindex $pair 1]

    if {$type == "term"} {
      # found a terminal, does it have a root name
      
      if {[info exists TERMS($id)]} {
	# named term

	# save on old and new net_id and make a new one to go forward
	lappend CC_NET(term,$net_id) $id
	set new $id

	if {$TERMS($id,root) != ""} {
	  # do one at a time to catch unrooted
	  foreach one [split $TERMS($id) ,] {
	    set root [bus_root $one]

	    if {$root == ""} {
	      # error, can't mix named and unnamed buses
	      sue_error "NETLIST ERROR: Can't mix named and unnamed buses $TERMS($id) ([find_origin $id]) in schematic \"$cur_s\"." $cur_s
	      continue
	    }
	    
	    if {$root != $one} {
	      # not just a root but a range, too
	      lappend CC_RANGE($root) $one
	    }

	    set CC_NET_ROOTS($root) $coord
	  }

	  set current_root $TERMS($id,root)

	} else {
	  # no root
	  lappend CC_TMP $id

	  if {[lindex $current_root 1] != ""} {
	    # can't add a concatenated
	    sue_error "NETLIST ERROR: Can't use a concatenated bus ($current_root) to name the unnamed bus $TERMS($id) ([find_origin $id]) in schematic \"$cur_s\"." $cur_s
	    continue
	  }

	  if {$current_root != ""} {
	    foreach one [split $TERMS($id) ,] {
	      lappend CC_RANGE($current_root) $one
	    }
	  }
	}

      } else {
	# not named
	lappend CC_TMP $id
      }

    } else {
      # must be a wire
      set coord2 [lindex $pair 2]

      if {![info exists CC_TRACE($coord2)]} {

	if {$new != ""} {
	  # make new id and save on net_id
	  set net_id [incr CC_NET_INDEX]
	  lappend CC_NET(term,$net_id) $new
	}

	lappend CC_NET($id) $net_id

	_cc_find_root $coord2 $current_root $net_id
      }
    }
  }

  if {$current_root != ""} {

    if {[lindex $current_root 1] == "" && \
	    ![regexp {'(b|h|d|o)} $current_root]} {
      set range [info exists CC_RANGE($current_root)]

      foreach id_tmp $CC_TMP {
	set TERMS($id_tmp,root) $current_root

	# iii implicit
	# compute size for implicit

	if {!$range && $TERMS($id_tmp,dir) == "output"} {

	  # output terminal, get width for implicit stuff
	  upvar #0 ${cur_s}_inst[find_origin $id_tmp] i_data

	  # ignore primitives -- e.g. bus_combines have outputs
	  upvar #0 icon_$i_data(type) g_data
	  if {[info exists g_data(_primitive)]} {
	    continue
	  }

	  set width [bus_width $TERMS($id_tmp,name)]
	  if {[info exists i_data(_name)] && $i_data(_name) != ""} {
	    # multiply by width of name 
	    set width [expr $width * [bus_width [lookup_name $i_data(_name)]]]
	  }

	  set CC_IMPLICIT($current_root) $width
	}
      }
      
      if {!$range && ![info exists CC_IMPLICIT($current_root)]} {
	# special case, no output
	set width 0
	foreach id_tmp $CC_TMP {
	  # get max width of anything not a primitive
	  upvar #0 ${cur_s}_inst[find_origin $id_tmp] i_data

	  # ignore primitives -- e.g. bus_combines have outputs
	  upvar #0 icon_$i_data(type) g_data
	  if {[info exists g_data(_primitive)]} {
	    continue
	  }

	  set this_width [bus_width $TERMS($id_tmp,name)]
	  if {[info exists i_data(_name)] && $i_data(_name) != ""} {
	    # multiply by width of name 
	    set this_width \
		[expr $this_width * [bus_width [lookup_name $i_data(_name)]]]
	  }

	  if {$this_width > $width} {
	    set width $this_width
	  }
	}

	if {$width > 0} {
	  if {![info exists CC_NET(implicit,$current_root)] || \
		  $CC_NET(implicit,$current_root) < $width} {
	    set CC_NET(implicit,$current_root) $width
	  }
	}
      }

    } else {
      # concatenated bus or constant
      foreach id_tmp $CC_TMP {
	set TERMS($id_tmp,root) $current_root
      }
    }

    set CC_TMP ""
  }

  return ""
}


# assumes wires after terms

proc _cc_prop_names {coord current_name} {

  global cur_s TERM_PRIORITY CC_TRACE CC_COORDS CC_NET TERM_LIST

  if {[info exists CC_TRACE($coord)]} {
    # already been here
    return $CC_TRACE($coord)
  }
  set CC_TRACE($coord) ""

  upvar #0 TERMS_$cur_s TERMS

  set unnamed ""

  foreach pair $CC_COORDS($coord) {
#    setl {type id} $pair
    set type [lindex $pair 0]
    set id [lindex $pair 1]

    if {$type == "term"} {
      # found a terminal, does it name the net
      if {[info exists TERMS($id)]} {
	if {[info exists TERMS($id,root)] && $TERMS($id,root) != "" && \
		[cbus_root $TERMS($id)] == ""} {
	  # add root to [1] and even [1],[0] if not done yet
	  regsub -all {(^|,)} $TERMS($id) "\\0$TERMS($id,root)" TERMS($id)
	}

	set current_name $TERMS($id)
	
      } else {
	lappend unnamed $id
      }

      # check direction to see if any problems
      if {$TERMS($id,type) == $TERMS($id,dir)} {
	# this is an I/O
	if {$CC_TRACE(_dir_) == ""} {
	  set CC_TRACE(_dir_) $TERMS($id,dir)
	  set CC_TRACE(_dirid_) $id
	} elseif {$CC_TRACE(_dir_) != $TERMS($id,dir)} {
	  set CC_TRACE(_dir_) inout
	}

	if {[regexp {'(b|h|d|o)} $TERMS($id)]} {
	  # can't have a constant here
	  sue_error "NETLIST ERROR: Can't have a constant in an I/O: \"$TERMS($id)\" on $TERMS($id,type) ([find_origin $id]) in schematic \"$cur_s\"." $cur_s
	}

      } else {
	set CC_TRACE(_$TERMS($id,dir)_) 1
      }

    } else {
      # must be a wire, trace other end if haven't already traced.
      set coord2 [lindex $pair 2]
      if {![info exists CC_TRACE($coord2)]} { 
	if {[info exists CC_NET($id)]} {
	  set net_index $CC_NET($id)
	  if {[info exists CC_NET(term,$net_index)]} {
	    if {[cbus_root $CC_NET(term,$net_index)] != ""} {
	      # already contains root
	      set TERMS($id) $CC_NET(term,$net_index)
	      _cc_prop_names $coord2 $TERMS($id)

	    } else {
	      # add root to [1] and even [1],[0] if not done yet
	      regsub -all {(^|,)} $CC_NET(term,$net_index) \
		  "\\0[bus_root $current_name]" name

	      set TERMS($id) $name
	      _cc_prop_names $coord2 $name
	    }
	  } else {
	    set TERMS($id) $current_name
	    _cc_prop_names $coord2 $current_name
	  }
	  
	} else {
	  set TERMS($id) $current_name
	  _cc_prop_names $coord2 $current_name
	}
      }
    }
  }

  foreach id $unnamed {
    set TERMS($id) $current_name

    # add to terminal list
    set oid [find_origin $id]

    set net $TERMS($id)

    if {$TERMS($id,dir) == "input"} {
      set this_width [bus_width $TERMS($id,name)]
      if {$this_width > 1 && [cbus_width $TERMS($id)] == 1} {
	# duplicate this baby
	for {set i 1} {$i < $this_width} {incr i} {
	  set net "$net,$TERMS($id)"
	}
      }
    }
    lappend TERM_LIST($oid) "$TERMS($id,name) $net"

    if {$TERMS($id,dir) == "output"} {
      # check widths on outputs

      upvar #0 ${cur_s}_inst$oid i_data

      # ignore primitives -- e.g. bus_combines have outputs
      upvar #0 icon_$i_data(type) g_data
      if {[info exists g_data(_primitive)]} {
	continue
      }

      set this_width [bus_width $TERMS($id,name)]
      if {[info exists i_data(_name)] && $i_data(_name) != ""} {
	# multiply by width of name 
	set this_width \
	    [expr $this_width * [bus_width [lookup_name $i_data(_name)]]]
      }

      if {[cbus_width $current_name] != $this_width} {
	# bad
	global NETLIST
	if {!$NETLIST(ignore_connected_outputs)} {
	  sue_error "NETLIST ERROR: inconsistent width on output \"$TERMS($id,name)\" on instance $i_data(type) \"[use_first i_data(_name)]\" ($oid) and net \"$current_name\" in schematic \"$cur_s\"." $cur_s
	}
      }
    }
  }
}


# make a root name that is unique.  If there is a suggested name and
# that name is unique, use it.

proc _cc_make_root_name {ids} {

  global cur_s NET_INDEX CC_ROOTS CC_SUGGEST CC_SUGGEST_NAMES

  upvar #0 TERMS_$cur_s TERMS

  # first look for a suggested root name
  set count 0
  foreach id $ids {
    if {[info exists TERMS($id,suggest)]} {
      set root $TERMS($id,suggest)

      if {$root == "" || [info exists CC_ROOTS($root)]} {
	# skip, already used this
	continue
      }

      # got it.

      # so we know we used this one
      unset TERMS($id,suggest)

      return $root
    } else {
      incr count
    }
  }

  while {1} {
    set root net_[incr NET_INDEX]
    if {[info exists CC_SUGGEST_NAMES($root)]} {
      # already taken as a possible suggested name
      continue
    }

    # if unconnect, change name to identify
    if {$count == 1} {
      set root "uc_$root"
      if {[info exists CC_SUGGEST_NAMES($root)]} {
	# already taken as a possible suggested name
	continue
      }
    }

    if {![info exists CC_ROOTS($root)]} {
      # not used, we're done
      set CC_SUGGEST($root) $ids
      return $root
    }
  }
}


proc update_instance_names {} {

  global cur_s cur_c PROC NETLIST_TYPE

  upvar #0 TERMS_$cur_s TERMS

  upvar #0 SUE_$cur_s data
  if {$data(generator) == 1 || $data(read_only) == 1} {
    # ignore if generator or read_only
    return 0
  }

  switch $NETLIST_TYPE {
    sim - flat_spice {
      # doesn't work since flat
      return 0
    }

    spice {
      # special case, strip first character
      set start 1
    }

    default {
      # verilog, dpc, other?
      set start 0
    }
  }

  integer_scale
  set save_proc ""
  set new_ids ""
  set count 0

  foreach id [$cur_c find withtag origin] {

    if {[info exists TERMS($id)]} {
      # found a named object
      upvar #0 ${cur_s}_inst${id} i_data

      if {![info exists i_data(_name)]} {
	continue
      }

      set name [string range $TERMS($id) $start end]
      set old_name [string trimleft $i_data(_name)]

      if {[string first \[ $name] == -1 && \
	  [set i [string first \[ $old_name]] != -1} {
	      
	# special case for things like [4]
	set name "$name[string range $old_name $i end]"
      }

      if {$old_name != $name} {
	# change name to newest

	# setup for undo
	set PROC $save_proc
	write_instances inst$id 1 undo
	set save_proc $PROC

	set i_data(_name) $name
	catch {unset i_data(creator)}

	# don't do this cause it changes id and messes up TERMS
#	lappend new_ids [remake $id $id "" no_scale]
	lappend new_ids $id

	# possibly update name shown -- if default name property only
	foreach name_id [$cur_c find withtag _name_&inst$id] {
	  # got one, change name to new
	  $cur_c itemconfigure $name_id -text $name
	}

	incr count
      }
    }
  }

  # undo
  if {$count > 0} {
    setup_undo $new_ids $save_proc

    puts "Renamed $count instances."

    is_modified
  }

  unscale

  return 1
}
