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

set RCSVERSION(flyc.tcl) { $Revision$ }


# Flyline connectivity.  Capabilities only available if nl connectivity is available.

proc _fplan_flyline_ignore {net} -desc {
  return TRUE if flylines should not be drawn for this net.
} {
  global FPLAN
  foreach pat $FPLAN(flyline_ignore) {
    if {[string match $pat $net]} {return 1}
  }
  return 0
}


proc _UNUSED_fplan_show_flylines {{-all} {cellid ""} {celldef ""}} -desc {
  Draw flylines for specified cell, or -all flylines, or selected cell.
} -doc {
  Note: both id and def passed just to save us having to look up def given id.

  Action depends on FPLAN(flyline_cells)
  if FPLAN(flyline_cells) != "individual",
  we do not show individual flylines for each pin.  
  We will show a single flyline to each region (typically each side)
  of any pair of connected blocks.
  Create array: fplan_bundles, with index a pair of pins
  between blocks, and with contents the list of nets in the bundle.
} {
  global FPLAN _FPLAN_FLYLINE_CACHE DB_FLYLINES_SAVE

  # If no verilog for current edit cell, then no connectivity information,
  # and we cant draw any flylines.  abort now, because nl calls will fail.
  set topmod [fplan_db_cell module [lay_editcell]]
  if {![nl2_loaded $topmod]} {
    return
  }

  set DB_FLYLINES_SAVE 0  ;# Dont save these flylines in a file.

  set hch [nlt_hier_char]


  # This was overly restrictive:
  #if {![fplan_check_verilog -silent]} { return }

  # Link now, in case it hasnt been done yet.
  nl2_link $topmod

  #_fplan_cell2id -init
  if {$cellid == ""} {
    if {$all} {
      # Show flylines for all cells.
      foreach thing [db_search_l cells] {
	struct max_cell c $thing
	fplan_show_flylines ${c.id} ${c.def}
      }
      return
    } else {
      # Show flylines for selected cells.
      foreach thing [sel_what_l cells] {
	struct max_cell c $thing
	fplan_show_flylines ${c.id} ${c.def}
      }
      return
    }
  }

  # This stuff would be easy to cache if it is too slow:
  #set label_list [db_search_l labels -non_hier -cell $celldef]
  #set last_key [list $FPLAN(flyline_mode) $FPLAN(flyline_cells) $label_list]
  #
  #if {[use_first _FPLAN_FLYLINE_CACHE($celldef,$cellid,key)] == $last_key} {
  #  # Use cache.
  #  foreach flyline $_FPLAN_FLYLINE_CACHE($celldef,$cellid,flylines) {
  #  }
  #}

  #if {$mod == "" || ![nl2_loaded $mod]}
  set mod [fplan_db_cell module $celldef]
  if {$mod == ""} {
    max_error -buffer "fplan warning: verilog module $mod for cell: $celldef has not been read in"
    # nl2 will fail if no verilog for module, which is true for lef cells,
    # but we can keep going and just query the max data-base for port info.
    return
  }

  #if {![nl2_loaded $mod]} {
  #  if {[fplan_cell_info -is_lef $mod]} {
  #    max_error -buffer "fplan warning: can not display connectivity for lef-only cells"
  #    # TODO: We should query the max data-base for port info.
  #  } else {
  #    max_error -buffer "fplan warning: can not display connectivity for lef-only cells"
  #  }
  #  return
  #}

  set modi [fplan_db_inst celli2modi $cellid]

  if {$FPLAN(flyline_cells) == "individual"} {

    # One flyline for each individual wire.
    foreach porta [fplan_db_pin_list -cell $celldef] {
      set term1 $cellid/$porta
      set net [nl2_get_pin_net $topmod "${modi}${hch}[fplan_unfix_name -label ${porta}]"]
      if {$net == ""} {
	# The pin was defined in the verilog module but was left unconnected
	# when the verilog instance was instantiated.
	continue
      }
      if {[_fplan_flyline_ignore $net]} {continue}
      foreach pin_name [nl2_get_net_pins $topmod $net] {
	if {[string first $hch $pin_name] == -1} {
	  # It is a connection to a top-level port in the edit-cell.
	  set term2 $pin_name
	} else {
	  setl {modib pinb} [split $pin_name $hch]
	  # Skip connections from cell to itself
	  if {$modib == $modi} {continue}
	  set cellidb [fplan_db_cell modi2celli $modib]
	  set term2 $cellidb/[fplan_unfix_name -label $pinb]
	}
	db_flyline $term1 $term2
      }
    }
    return
  }

  if {[cell_flags $celldef] == ""} {
    msg "warning: cell contents not read in yet, so no flylines.\n"
    #return
  }

  #if {[lsearch -exact [nl2_list_designs] $mod] == -1} {
  #  msg "warning: no verilog file read for this module, so no flylines.\n"
  #  return
  #}

  msg "Drawing flylines for $modi\n"

  # Gather up wires from cell to all other cells in wires array.
  # Group them by the region they are in.

  foreach porta [fplan_db_pin_list -cell $celldef] {

    # This region info is not valid if the cell is a lef cell,
    # or if the ports have been placed.
    # So for now, draw all flylines to centers of cell.
    if {$FPLAN(flyline_cells) == "center"} {
      set regiona center
    } else {
      # If the port is on one of the cell sides, draw flylines to that side.
      # Have to figure out what side the port is on.
      # If not on a side, draw it to the center.
      set regiona [fplan_db_pin -cell $celldef getregion $porta]
    }
    #set cona _hidden_$regiona
    set cona "{*$regiona*}"
    # 8/24/01: We have magic flylines names now, so hidden labels do not need to exist.
    #if {[llength [db_search_l labels -cell $celldef -non_hier -exact $cona]] == 0} {
    #  # No hidden labels.  Use real port name.
    #  set cona $porta
    #}

    set net [nl2_get_pin_net $topmod "${modi}${hch}${porta}"]
    if {$net == ""} {
      # The pin was defined in the verilog module but was left unconnected
      # when the verilog instance was instantiated.
      # OR, the cell is a lef cell whose verilog model has different
      # pin names than the actual max cell.
      msg "Can not find net connected to: ${modi}${hch}${porta}\n"
      continue
    }
    if {[_fplan_flyline_ignore $net]} {continue}
    foreach pin_name [nl2_get_net_pins $topmod $net] {
      if {[string first $hch $pin_name] == -1} {
	# Its a top-level pin
	set cellidb "."
	# The pin_name is just the top level port name.
	set portb $pin_name
	if {$FPLAN(flyline_ports) == "individual"} {
	  # These are not grouped by region, so consider each pin
	  # its own unique region.
	  set conb $portb
	} elseif {$FPLAN(flyline_ports) == "center"} {
	  set regionb [fplan_db_pin -cell [lay_editcell] getregion $portb]
	  if {$regionb == "center" } {
	    msg "flylines: ignoring pin $portb, which is not placed properly\n"
	  } else {
	    #set conb _hidden_$regionb
	    set conb "{*$regionb*}"
	  }
	  # 8/24/01: We have magic flylines names now, so hidden labels do not need to exist.
	  #if {[llength [db_search_l labels -cell $celldef -non_hier -exact $conb]] == 0} {
	  #  # No hidden labels.  Use real port name.
	  #  set conb $portb
	  #}
	} else {
	  continue  ;# Not shown
	}
      } else {
	setl {modib portb} [split $pin_name $hch]
	# Skip connections from cell to itself
	if {$modib == $modi} {continue}
	if {[catch {set cellb [fplan_db_cell modi2cell $modib]}] || $cellb == ""} {
	  # This happens if the user deleted a cell that should
	  # be connected by flylines.  We dont want to error out
	  # because this code is called every time the user clicks on a cell.
	  msg "flyline warning: can not find cell corresponding to module $modib\n"
	  continue
	}
	if {[fplan_cell_info -is_lef $cellb]} {
	  set cellidb $modib
	} else {
	  set cellidb [fplan_db_cell modi2celli $modib]
	}
	if {$FPLAN(flyline_cells) == "center"} {
	  set regionb "center"
	} else {
	  set regionb [fplan_db_pin -cell $cellb getregion $portb]
	}
	# Connect to the hidden port with this name.
	#set conb _hidden_$regionb
	set conb "{*$regionb*}"
	# 8/24/01: We have magic flylines names now, so hidden labels do not need to exist.
	#if {[llength [db_search_l labels -cell $cellb -non_hier -exact $conb]] == 0} {
	#  # No hidden labels.  Use real port name.
	#  set conb $portb
	#}
      }
      set key "[list [fplan_fix_name $cellid]/$cona [fplan_fix_name $cellidb]/$conb]"
      set wirecnt [llength [nlt_bus_explode $net]]
      set bundles($key) [expr [use_first bundles($key) '0] + $wirecnt]
      #lappend wires([list $regiona $cellidb $regionb]) [list $porta $portb $net]
    }
  }


  foreach bun_info [array names bundles] {
    setl {pina pinb} $bun_info
    # Count of wires in this bundle.
    set cnt $bundles($bun_info)
    if {$cnt == 1} {
      db_flyline $pina $pinb
    } else {
      # width of flyline is proportional to number of wires in bundle.
      set divisor $FPLAN(flyline_width_divisor)
      set width [max 1 [expr int($cnt/$divisor)]]
      db_flyline -width $width -text $cnt $pina $pinb
    }
  }
}

proc flyc_sel_cell {{-all} {cell_info ""}} -desc {
  Show flylines for specified cell, or all cells.
} {
  global FPLAN
  global DB_FLYLINES_SAVE
  set DB_FLYLINES_SAVE 0  ;# Dont save these flylines in a file.

  if {$all} {
    # Show flylines for all cells.
    foreach cellinfo [db_search_cells] {
      flyc_sel_cell $cellinfo
    }
    return
  }

  set celldef [cellinfo_def $cell_info]
  set cellid [cellinfo_id $cell_info]

  # If no verilog for current edit cell, then no connectivity information,
  # and we cant draw any flylines.  abort now, because nl calls will fail.
  set topmod [fplan_db_cell module [lay_editcell]]
  if {![nl2_loaded $topmod]} {
    return
  }

  set hch [nlt_hier_char]

  # Link now, in case it hasnt been done yet.
  nl2_link $topmod

  # Will return celldef for lef cells, or if no special module is defined.
  set mod [fplan_db_cell module $celldef]
  assert {$mod != ""}
  set modi [fplan_db_inst celli2modi $cellid]
  assert {$modi != ""}

  msg "Drawing flylines for $modi\n"

  if {[use_list_path]} {
    fplan_sync_nl_hierarchy ;# Ouch!
  }

  # Gather up wires from cell to all other cells in wires array.
  # Group them by the region they are in.

  foreach porta [fplan_db_pin_list -cell $celldef] {

    if {$FPLAN(flyline_cells) == "individual"} {
      set cona $porta
    } elseif {$FPLAN(flyline_cells) == "center"} {
      set cona "{*center*}"
    } else {
      # If the port is on one of the cell sides, draw flylines to that side.
      # Have to figure out what side the port is on.
      set cona "{*[fplan_db_pin -cell $celldef getregion $porta]*}"
    }
    set terma [fplan_fix_name $cellid]/$cona

    set net [nl2_get_pin_net $topmod "${modi}${hch}${porta}"]
    if {$net == ""} {
      # The pin was defined in the verilog module but was left unconnected
      # when the verilog instance was instantiated.
      # OR, the cell is a lef cell whose verilog model has different
      # pin names than the actual max cell.
      msg "Can not find net connected to: ${modi}${hch}${porta}\n"
      continue
    }
    if {[_fplan_flyline_ignore $net]} {continue}

    #puts "net=$net pins=[nl2_get_net_pins -hier 1 $topmod $net]"
    if {[use_list_path]} {
      set pin_list [nl2_get_net_pins -hier 1 $topmod $net]
    } else {
      set pin_list [nl2_get_net_pins $topmod $net]
    }

    foreach pin_name $pin_list {

      set l [string last $hch $pin_name]
      if {$l == -1} {

	# Its a top-level pin
	# The pin_name is just the top level port name.
	if {$FPLAN(flyline_ports) == "individual"} {
	  # These are not grouped by region, so consider each pin
	  # its own unique region.
	  set termb $pin_name
	} elseif {$FPLAN(flyline_ports) == "center"} {
	  set regionb [fplan_db_pin -cell [lay_editcell] getregion $pin_name]
	  if {$regionb == "center" } {
	    msg "flylines: ignoring pin $pin_name, which is not placed properly\n"
	    continue	;# Not shown
	  } else {
	    set termb "{*$regionb*}"
	  }
	} else {
	  continue  ;# Not shown
	}

      } else {

	set pinb [string range $pin_name [expr $l+1] end]
	set modib [string range $pin_name 0 [expr $l-1]]

	# Skip connections from cell to itself
	if {$modib == $modi} {continue}
	set cellib [fplan_fix_name $modib]
	regsub {\.} $cellib / cellib
	set cell_info [dbt_find_cell -fast 1 $cellib]
	if {$cell_info == ""} {
	  msg "flyline warning: can not find cell corresponding to module $modib\n"
	}

	set cellb [cellinfo_def $cell_info]
	set cellidb [cellinfo_name $cell_info]
	#puts "pin_name=$pin_name modib=$modib cellidb=$cellidb"

	if {0} {
	if {[catch {set cellb [fplan_db_cell modi2cell $modib]}] || $cellb == ""} {
	  # This happens if the user deleted a cell that should
	  # be connected by flylines.  We dont want to error out
	  # because this code is called every time the user clicks on a cell.
	  msg "flyline warning: can not find cell corresponding to module $modib\n"
	  continue
	}
	if {[fplan_cell_info -is_lef $cellb]} {
	  set cellidb $modib
	} else {
	  set cellidb [fplan_db_cell modi2celli $modib]
	}
	}

	if {$FPLAN(flyline_cells) == "individual"} {
	  set conb $pinb
	} elseif {$FPLAN(flyline_cells) == "center"} {
	  set conb "{*center*}"
	} else {
	  set conb "{*[fplan_db_pin -cell $cellb getregion $pinb]*}"
	}
	set termb [fplan_fix_name $cellidb]/$conb
      }

      set key [list $terma $termb]
      set wirecnt [llength [nlt_bus_explode $net]]
      set bundles($key) [expr [use_first bundles($key) '0] + $wirecnt]
    }
  }

  foreach bun_info [array names bundles] {
    setl {pina pinb} $bun_info
    if {[use_list_path]} {
      set pinpatha [dbt_listize_pin_path $pina]
      set pinpathb [dbt_listize_pin_path $pinb]
    } else {
      set pinpatha $pina
      set pinpathb $pinb
    }
    # Count of wires in this bundle.
    set cnt $bundles($bun_info)
    if {$cnt == 1} {
      db_flyline $pinpatha $pinpathb
    } else {
      # width of flyline is proportional to number of wires in bundle.
      set divisor $FPLAN(flyline_width_divisor)
      set width [max 1 [expr int($cnt/$divisor)]]
      db_flyline -width $width -text $cnt $pinpatha $pinpathb
    }
  }
}


proc _flyc_select {} -desc {
  Draw flylines for cell or labels at cursor.
} {
  global _FLYC
  set old_cell_list [use_first FLYC(cell_list)]

  setl {x y} [layt_point exact]
  set cell_list [db_search_cells -area $x $y $x $y]

  if {[llength $cell_list] == 0} {
    return
  }

  set ind 0	;# Default use first cell at these coords.
  if {$old_cell_list == $cell_list} {
    # Same point location as previous.
    # If multipe cells at these coords, pick next cell from list.
    set ind [expr $FLYC(cell_index)+1]
    if {$ind >= [llength $cell_list]} {
      set ind 0
    }
  }
  set cell_info [lindex $cell_list 0]
  _flyc_sel_cell $cell_info
}


proc _flyc_mode_define {} {
  mode_def flyline_connectivity _flyc_gate_keeper "BUT-1 selects; BUT-2 ends"

  mode_bind -cmd 0 flyline_connectivity <Any-Button-1> _flyline_vertex
  mode_bind -cmd 0 flyline_connectivity <Any-Motion> _flyline_motion
  mode_bind -cmd 0 flyline_connectivity <Delete> _flyline_delete_selected
  mode_bind -cmd 0 flyline_connectivity <Any-Button-2> mode_pop
  mode_bind -cmd 0 flyline_connectivity <Any-Button-3> _flyline_delete_selected
}

# These _mode_enter functions exist primarily just to provide a desc
# that is viewable from the menu_bar.
proc flyc_mode_enter {} -desc {
    Edit Flylines
} {
    mode_push flyline_connectivity
}



proc _flyc_gate_keeper {event} -desc {
    called whenever flyline mode is entered/exited
} {
    global FLYC mode_abort

    if {$event == "PUSH_TO"} {
    } elseif {$event == "POP_FROM"} {

	if { $mode_abort } {
	    # The flyc mode doesnt do anything, so dont do an undo.
	    #undo_to_delim
	    #undo_flush_redo
	    #msg "aborting flylines!\n"
	}

	i_cmd_between
    }
}


proc _fplan_lab_dist {x1 y1 label_info} -desc {
  distance between label and point.
} {
  struct max_label l $label_info
  return [expr sqrt( (${l.x1}-$x1)*(${l.x1}-$x1)+(${l.y1}-$y1)*(${l.y1}-$y1) )]
}


proc _UNUSED_nlt_get_hier_net_pins {{-path ""} mod net} -desc {
  Given a net in the current design, return all hierarchical pin names.
} -doc {
  Does not use nl -hierarchy, as that requires an idesign to be created.
} {
  set result ""
  set hch [nlt_hier_char]
  # There are three cases:
  #	1.  Top level pin.
  #	2.  Pin on lef cell or unflattened hierarchical cell.
  #	3.  Pin on flatteneed hierarchical cell - requires recursion.
  foreach pin_name [nl2_get_net_pins $mod $net] {
    #puts "pin_name=$pin_name"
    if {[string first $hch $pin_name] == -1} {
      # It is a top level pin
      # It goes in the pin list only for the top level cell.
      if {$path == ""} {
	lappend result $pin_name
      }
    } else {
      setl {modib portb} [split $pin_name $hch]
      set cellb [fplan_db_cell modi2cell $modib]
      set cellib [fplan_db_cell modi2celli $modib]
      puts "modib=$modib cellb=$cellb"
      if {[fplan_cell_info -is_lef $cellb]} {
	lappend result $pin_name
      } elseif {[fplan_db_inst getprop $cellib place] != "flatten"} {
	lappend result $pin_name
      } else {
	if {$path == ""} {
	  set tmp $modib
	} else {
	  set tmp ${path}/${modib}
	}
	set result [concat $result [nlt_get_hier_net_pins -path $tmp [fplan_db_cell module $cellb] $portb]]
      }
    }
  }
  return $result
}


proc fplan_sel_net {{-more} net} -desc {
  Highlight the named verilog net somehow.  Currently makes a flyline.
} {
  global _FPLAN_SEL_NET_MESSAGE

  set cell [lay_editcell]
  set mod [fplan_db_cell module $cell]
  if {![nl2_loaded $mod]} {
    if {[use_first _FPLAN_SEL_NET_MESSAGE($mod)] == ""} {
      msg "fplan_sel_net: No verilog loaded; aborting\n"
      set _FPLAN_SEL_NET_MESSAGE($mod) 1   ;# Dont want a ton of these messages.
    }
    return
  }

  if {!$more} {
    db_flyline -delete
    sel_clear
  }

  set hch [nlt_hier_char]
  set verilog_net $net

  if {[use_list_path]} {
    # This isnt entirely a list-path dependent thing,
    # but we are also starting to use iconized hierarchical blocks at the same time.

    fplan_sync_nl_hierarchy

    # The -hierarchy option fails if an idesign has not been created, and even if it
    # has, the top of the tree returned will currently (2/1/02) be whatever
    # was the current_design when create_idesign occurred.
    # Maybe I should just take this out.
    #nlt_log {set nlobj [nl_find_inets -exact $verilog_net $mod]}
    #if {$nlobj == ""} {
    #  msg "Net $verilog_net not found (1)\n"
    #  return
    #}
    set result ""
    if {[catch {nl2_get_net_pins -hier 1 $mod $verilog_net} result]} {
      # Turn off the warning for the demo, which is generated all the time
      # because we have not called nl_create_idesign.
      # I dont know to do about this long term.
      msg "nl2_get_net_pins -hierarchy warning: $result\n"
      set pins ""
    } else {
      set pins $result
    }

  } else {

    # If you say nl2_get_net_pins -hierarchy, you do not get the non-leaf cell ports.
    # So call it with and without -hierarchy, and draw nets for all.
    if {[catch {nl2_get_net_pins $mod $verilog_net} result]} {
      # Net not found in mod.
      msg "nl2_get_net_pins warning: $result\n"
      return
    } else {
      set pins $result
    }
  }

    if {[llength $pins]==0} {
      return
    }

    set labels ""
    foreach pin_name $pins {
      set lab_path [_flyc_pin2label $pin_name "individual"]
      if {$lab_path != ""} {
	lappend labels $lab_path
      }
    }
    #msg "Selected net $net pins=$labels\n"

    # If the original net was a label, draw all flylines to that label.
    if {[db_search_l labels -exact -non_hier $net] == ""} {
      # Draw flylines in any order.
      for {set i 1} {$i < [llength $labels]} {incr i} {
	set lab1 [lindex $labels $i]
	set lab2 [lindex $labels [expr $i-1]]
	db_flyline $lab1 $lab2
      }
    } else {
      catch {sel_labels -more -text $net}
      for {set i 0} {$i < [llength $labels]} {incr i} {
	set lab1 [lindex $labels $i]
	if {$lab1 == $net} {continue}
	#puts "db_flyline $net $lab1"
	db_flyline $net $lab1
      }
    }
}


proc fplan_sel_net_point {x y} -desc {
  Try to find a label at x,y and select the attached verilog net.
} -doc {
  Called from select_cursed_net when there is no paint under the cursor,
  to see if maybe there is a label under the cursor with verilog
  to tell us what it is hooked to.

  TODO: Should only look in visible cells, but if sub-cell ports are visible,
  then also needs to look in those.
} {

  set near [nearby_dist]
  set ax1 [expr $x-$near]
  set ax2 [expr $x+$near]
  set ay1 [expr $y-$near]
  set ay2 [expr $y+$near]

  # This is an interface choke:  If you specify -cell, then it descends into
  # all loaded cells, not all expanded cells.
  set label_list [db_search_l labels -cell [lay_editcell] -any_cell -area $ax1 $ay1 $ax2 $ay2]

  # Find the nearest label to the point location.
  set nearest_lab_info [lindex $label_list 0]
  if {$nearest_lab_info == ""} {
    # No labels nearby the point.
    return
  }

  set nearest_dist [_fplan_lab_dist $x $y $nearest_lab_info]
  for {set i 1} {$i < [llength $label_list]} {incr i} {
    set this_dist [_fplan_lab_dist $x $y [lindex $label_list $i]]
    if {$nearest_dist > [_fplan_lab_dist $x $y [lindex $label_list $i]]} {
      set nearest_dist $this_dist
      set nearest_lab_info [lindex $label_list $i]
    }
  }

  struct max_label l $nearest_lab_info

  fplan_sel_net ${l.path}${l.text}
}


proc _flyc_pin2label {{-skip_mod ""} pin_name control} {

  set hch [nlt_hier_char]
  set dot [string last $hch $pin_name]
  if {$dot == -1} {
    # Its a top-level pin
    set cellidb "."
    # The pin_name is just the top level port name.
    set portb $pin_name
    if {$control == "individual"} {
      # These are not grouped by region, so consider each pin
      # its own unique region.
      set conb $portb
    } elseif {$control == "center"} {
      set regionb [fplan_db_pin -cell [lay_editcell] getregion $portb]
      if {$regionb == "center" } {
	msg "flylines: ignoring pin $portb, which is not placed properly\n"
      } else {
	#set conb _hidden_[fplan_db_pin -cell [lay_editcell] getregion $portb]
	set conb "{*$regionb*}"
      }
      if {[llength [db_search_l labels -cell $celldef -non_hier -exact $conb]] == 0} {
	# No hidden labels.  Use real port name.
	set conb $portb
      }
    } else {
      return "" ;# Not shown
    }
  } else {
    set modib [string range $pin_name 0 [expr $dot-1]]
    set portb [string range $pin_name [expr $dot+1] end]
    regsub -all {\.} $modib / modib
    # Skip connections from cell to itself
    if {$modib == $skip_mod} {continue}

    set cellib [fplan_fix_name $modib]
    set cellinfo [lindex [dbt_find_cell -fast 1 $cellib] 0]
    if {$cellinfo == ""} {
      msg "flyline warning: can not find cell corresponding to module $modib\n"
      return ""
    }
    set cellidb [cellinfo_name $cellinfo]

    if {0} {
      if {[catch {set cellb [fplan_db_cell modi2cell $modib]}] || $cellb == ""} {
	# This happens if the user deleted a cell that should
	# be connected by flylines.  We dont want to error out
	# because this code is called every time the user clicks on a cell.
	msg "flyline warning: can not find cell corresponding to module $modib\n"
	return ""
      }
      #if {[fplan_cell_info -is_lef $cellb]} {
      #  set cellidb $modib
      #} else {
      #  set cellidb [fplan_db_cell modi2celli $modib]
      #}

      set cellidb [fplan_db_cell modi2celli $modib]
    }

    if {$control == "individual"} {
      if {[use_list_path]} {
	set conb [concat ${cellidb} ${portb}]
      } else {
	set conb ${cellidb}/${portb}
      }
    } else {
      if {$control == "center"} {
	set regionb "center"
      } else {
	set regionb [fplan_db_pin -cell $cellb getregion $portb]
      }
      # Connect to the hidden port with this name.
      set conb "{*$regionb*}"
      if {[llength [db_search_l labels -cell $cellb -non_hier -exact $conb]] == 0} {
	# No hidden labels.  Use real port name.
	set conb $portb
      }
    }
  }

  return $conb
}
