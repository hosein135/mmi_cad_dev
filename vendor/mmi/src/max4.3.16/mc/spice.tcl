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

# Extracts the spice netlist of the block.  All cells with transistors in
# them become subcircuits.  Everything else is done flat.

# Note, bulk terminals aren't extracted.

# Note, source/drain overlap between cells in loads is counted twice.
# TODO: fix by looking at bounding box and clip

# for scaling
set CP_WIRE_CAP_FACTOR 1.0


# top level procedure called from menu

proc _mc_netlist {args} -desc {
  create a spice netlist for an entire block with subckt calls for leafcells.
} {

  global MC max_win

  if {$args == ""} {

    # get the options from the menu
    set win $max_win.layout
    set winy [expr [winfo rooty $win] + 50]
    set winx [expr [winfo rootx $win] + 50]

    set title "megacell generator"
    set message "Netlist Options:" 
    set prop_list [list \
       "type [use_first type MC(type) 'spice] radio {spice verilog}" \
       "parasitics [use_first MC(parasitics) '0] binary" \
       "verbose [use_first MC(verbose) '0] binary" \
      ]

    # create the menu
    set new_prop_list [prop_menu $winx $winy $message $title $prop_list]

    if {$new_prop_list == ""} {
      # empty list means the user hit cancel
      return
    }

    set type [get_assoc type $new_prop_list] 
    set parasitics [get_assoc parasitics $new_prop_list] 
    set verbose [get_assoc verbose $new_prop_list] 

  } else {

    # get the arguments from the command line
    set type [call_with_keyword $args {{parasitics 0} {verbose 0}}]
  }

  set MC(type) [use_first type 'spice]
  set MC(parasitics) [use_first parasitics '0]
  set MC(verbose) [use_first verbose '0]

  switch $type {
    spice {
      _mc_spice_netlist
    }

    verilog {
      _mc_verilog_netlist
    }
    default {
      puts "Aborting, illegal netlist type \"$type\"."
    }
  }
}


proc _mc_spice_netlist {} -desc {
  create a spice netlist for an entire block with subckt calls for leafcells.
} {

  global MC_SPICE_INST SEPARATOR CP_NAMES FILE_ID CONTINUATION
  global MC_SPICE_TOP_NETS COMMENT SPICE_CAPS MC MC_VERSION
  global MC_SPICE_CELL MC_SPICE_TRACE MC_GLOBAL CP_TOP_NAMES

  # must insure that everything is expanded for this to work
  eval lay_box [lay_bbox]
  lay_internals -area

  set cell [lay_rootcell]

  # compute directory for netlist
  set file [lindex [cell_info $cell] 1]
  if {$file == ""} {
    set dir "[pwd]/"
  } else {
    set dir [file dirname $file]/
    if {$dir == "./"} {
      set dir "[pwd]/"
    }
  }
  set filename "$dir$cell.sp"

  puts "Creating spice netlist from CELL $cell ..."

  # open the spice output filename $cell.sp
  if {[catch {open $filename w} FILE_ID]} {
    puts "Aborting, can't create file $filename"
    return
  }

  catch {unset MC_SPICE_TRACE}
  catch {unset MC_SPICE_CELL}
  catch {unset MC_SPICE_INST}
  catch {unset MC_GLOBAL}

  # unset this stuff
  foreach var [uplevel #0 "info vars _MC_CP_*"] {
    global $var
    unset $var
  }

  catch {unset SPICE_CAPS}
  catch {unset MC_SPICE_TOP_NETS}
  set MC_SPICE_TOP_NETS ""

  catch {unset CP_NAMES}
  set CP_NAMES(_unique) 0
  catch {unset CP_TOP_NAMES}

  # save all top level labels
  sel_labels -kind input
  sel_labels -more -kind output
  sel_labels -more -kind inout
  foreach label [split [sel_what labels] \n] {
    set CP_TOP_NAMES([string tolower [lindex $label 6]]) 1
  }
  sel_clear

  set CONTINUATION "+ "
  set COMMENT "*"

  set SEPARATOR "/"

  ext_puts "* SPICE netlist for \"$cell\" (generated from MAX-MCC$MC_VERSION)\n"
#  ext_puts ".INCLUDE '$cell.h'\n"

  undo_disable

  # find all leaf cells
  _spice_find_leafcells

  # restore toplevel cell
  :load $cell

  puts "Tracing all nets ..."
  _spice_trace_nets

  # write the netlist for each subcircuit
  puts "Writing netlist (subcircuits) ..."
  foreach instance [array names MC_SPICE_CELL] {
    :load $instance
    extract_subcircuit
  }

  # restore toplevel cell
  :load $cell

  # now write the top level spice netlist
  puts "Writing netlist (top level) ..."
  ext_puts "* Main CELL $cell"
#  ext_puts "* .SUBCKT $cell [lsort $MC_SPICE_TOP_NETS]"
  ext_puts ".SUBCKT $cell [lsort $MC_SPICE_TOP_NETS]"
  ext_puts " "

  _spice_create_spice_netlist

  ext_puts ".ENDS\t\$ $cell"

  # added low and high supply to any other globals
  set MC_GLOBAL([string tolower $MC(supply,low)]) 1
  set MC_GLOBAL([string tolower $MC(supply,high)]) 1

  ext_puts "\n.GLOBAL [array names MC_GLOBAL]\n"
  ext_puts ".END"

  # close the output file
  close $FILE_ID

  # make things look purty
  sel_clear
  eval lay_box [lay_bbox]

  undo_enable

  puts "Spice netlist $filename created."
}


proc _spice_find_leafcells {{mode spice}} -desc {
  find leafcells of current cell
} {

  global MC_SPICE_CELL MC_SPICE_TRACE lvs

  # select all of the subcells of this cell
  eval sel_area -layers subcell [lay_bbox]

  if {[sel_what cells] == ""} {
    return
  }

  foreach line [split [sel_what cells] \n] {

    setl {name instance x1 y1 x2 y2 cell_path} $line

    if {[info exists MC_SPICE_TRACE($instance)]} {
      # already been here
      continue
    }
    set MC_SPICE_TRACE($instance) 1

    :load $instance

    # is this a leaf cell
    if {[_is_leaf_cell]} {
      # leaf cell
      set MC_SPICE_CELL($instance) 1
      if {$mode == "verilog"} {
	if {[info exists lvs($instance)]} {
	  # there is a translation
	  puts "  $instance --> $lvs($instance) ... leafcell"
	} else {
	  puts "  $instance ... leafcell"
	}
      }
    
    } else {
      # not leaf cell, search recursively
#    puts "Skipping $instance, not leaf cell"
      _spice_find_leafcells $mode
    }
  }
}


proc _spice_trace_nets {} -desc {
  trace all nets that are connected to leafcells.
} {

  global MC_SPICE_INST SPICE_CAPS CP_WIRE_CAP_FACTOR MC_SPICE_TOP_NETS
  global NET_EQUIV MC MC_SPICE_CELL

  set NET_EQUIV ""

  set count 0

  # walk thru all leafcells
  foreach leafcell [array names MC_SPICE_CELL] {

    foreach path [_mc_find_paths $leafcell] {
      set MC_SPICE_INST($path) $leafcell

      upvar #0 _MC_CP_$path cp_array

      # TODO: check for multiple ports in same cell of same name
      foreach port [_mc_get_ports $path] {
	setl {layer x1 y1 x2 y2 pos text path group kind} $port

	# trace attached wire
	if {![info exists cp_array($text)]} {
	  # haven't traced this net yet
	  
	  incr count
	  if {$count > 10} {
	    set count 0
	    puts -nonewline "."
	    flush stdout
	  }

	  # select the entire net associated with this port
	  sel_net -point $x1 $y1 $layer
	  
	  # find a name for this net.  Choose net name with least hierarchy
	  set min_len 10000
	  set tie_off 0
	  foreach label [split [sel_what labels] \n] {
#	    setl {_layer _x1 _y1 _x2 _y2 _pos _text _path _group _kind} $label
	    set _text [lindex $label 6]
	    set _path [lindex $label 7]
	    set _kind [lindex $label 9]

	    if {$_kind == "global"} {
	      # this net is tied off
	      set net_name $_text
	      set tie_off 1
	      break
	    }

	    set len [llength [split $_path /]]
	    if {$len < $min_len} {
	      set min_len $len
#	      set net_name $_path$_text
	      set net_name $_text
	    }
	  }
	
	  if {!$tie_off} {
	    # make a unique name
	    set net_name [_cp_unique_name $net_name "" net [expr $min_len + 1]]
	    
	    # remember the capacitance on this net.  Remove space between 
	    # number and fF
	    if {$MC(parasitics)} {
	      setl {value units} [ext_capacitance]
	      set SPICE_CAPS($net_name) \
		  "[expr $value * $CP_WIRE_CAP_FACTOR]$units"
	    }
	  }
	
	  if {$MC(verbose)} {
	    lappend NET_EQUIV "* $net_name ="
	  }

	  # add this net to all labels of leaf cells
	  foreach label [split [sel_what labels] \n] {
#	    setl {_layer _x1 _y1 _x2 _y2 _pos _text _path _group _kind} $label
	    set _text [lindex $label 6]
	    set _path [string trimright [lindex $label 7] /]
	    set _kind [lindex $label 9]

	    if {[lsearch "input output inout" $_kind] != -1} {
	      if {$_path == ""} {
		# top level net
		# it doesn't have the same name as net_name then
		# layout has a problem
		if {$_text != $net_name} {
		  puts "ERROR, multiple unconnected top-level ports called $_text."
		}
	      
		if {[lsearch $MC_SPICE_TOP_NETS $net_name] == -1} {
		  # remember this net name
		  lappend MC_SPICE_TOP_NETS $net_name
		}
	      
	      } else {
		# remember net name associated with this port
	      
		upvar #0 _MC_CP_$_path cp_new
		set cp_new($_text) $net_name
	      }
	      
	      if {$MC(verbose)} {
		lappend NET_EQUIV "*   $_path/$_text"
	      }
	    }
	  }
	}
      }
    }
  }

  puts ""
}


proc _spice_create_spice_netlist {} -desc {
  create the spice netlist of the main cell (excluding leafcell subcircuit definitions)
} {

  global MC_SPICE_INST SPICE_CAPS NET_EQUIV MC

  if {$MC(verbose)} {
    foreach line $NET_EQUIV {
      ext_puts $line
    }

    ext_puts " "
  }

  foreach cell [array names MC_SPICE_INST] {
    upvar #0 _MC_CP_$cell cp_array

    set ports ""
    foreach net [lsort [array names cp_array]] {
      lappend ports $cp_array($net)
    }

    # write the spice instance cell.  Nets are in alphabetical order
    ext_puts "* $cell"
    ext_puts "[_cp_unique_name $cell X] $ports $MC_SPICE_INST($cell)"
  }

  ext_puts " "

  # now put in the net capacitances
  foreach net [array names SPICE_CAPS] {
    ext_puts "[_cp_unique_name "" C] $net $MC(supply,low) $SPICE_CAPS($net)"
  }
}


proc _mc_get_ports {path} -desc {
  returns the ports (inputs, outputs, and inouts) on the given instance.
  also saves global nets.
} {

  global MC_GLOBAL
  
  # edit this cell in place
  sel_cell $path
  edit_push in_place

  # save globals
  sel_labels -kind global
  foreach label [split [sel_what labels] \n] {
    set text [string tolower [lindex $label 6]]
    set MC_GLOBAL([string tolower $text]) 1
  }

  # get i/o's
  sel_labels -kind input
  sel_labels -more -kind output
  sel_labels -more -kind inout

  # can't just use sel_what labels since overlapping labels 
  # through hierarchy show up.  ChOkE

  set return ""
  foreach label [split [sel_what labels] \n] {
    set text [lindex $label 6]
    if {[info exists ios($text)]} {
      # duplicate, take longer name
      if {[llength [split [lindex $label 7] /]] > \
	      [llength [split [lindex $ios($text) 7] /]]} {
	set ios($text) $label
      }
    } else {
      set ios($text) $label
    }
  }

  foreach text [array names ios] {
    lappend return $ios($text)
  }

  edit_pop

  return $return
}
