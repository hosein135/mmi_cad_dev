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


# extracts the critical path of a circuit

# Ignores miller capacitance, especially on loads
# Possibly give the use a multiplier for load sizes to account for.

# Note, bulk terminals aren't extracted.

# Note, source/drain overlap between cells in loads is counted twice.

# TODO: add lvs() discussion to manual.

#set CP_WIRE_CAP_FACTOR 0.7
set CP_WIRE_CAP_FACTOR 1.0

set CP_TRACE_BASIC [use_first CP_TRACE_BASIC '0]

set CP_HALO [use_first CP_HALO '1]

# set CP_HALO_FAST [use_first CP_HALO_FAST '1]

# in microns
set CP_HALO_RADIUS 1

# set CP_TIE_INPUT(<cell_type>,<port>) <signal>
# set CP_TIE_INPUT(DEFAULT) <signal>

# for example,
# set CP_TIE_INPUT(sram_cell,wl) gnd
# set CP_TIE_INPUT(sram_cell,bl) vdd
# set CP_TIE_INPUT(sram_cell,bl_L) vdd
# set CP_TIE_INPUT(DEFAULT) gnd


proc _mc_cp {{type ""}} -desc {
  find the critical path attached to the selected cells and create a spice model of it
} {

  global MC max_win CP_LAST_TYPE CP_TRACE_BASIC CP_HALO CP_HALO_FAST CP_HALO_RADIUS

  if {$type == ""} {

    # get the options from the menu
    set title "Critical Path Extraction"
    set message "Critical Path:" 

    set prop_list ""

    set CP_LAST_TYPE [use_first CP_LAST_TYPE type 'netlist]
    lappend prop_list [list type CP_LAST_TYPE -radio {netlist layout menu}]

    lappend prop_list [list "" "" -separator]

    lappend prop_list [list "smaller cp" CP_TRACE_BASIC -binary -help "Creates a smaller critical path by not tracing the inputs of cells traced through their outputs.  CP_TRACE_BASIC variable."]

    lappend prop_list [list "" "" -separator]

    lappend prop_list [list halo CP_HALO -binary -help "For layout only.  Adds wires that are within a halo radius for more accurate extraction.  CP_HALO variable."]
    lappend prop_list [list "halo radius (um)" CP_HALO_RADIUS -number 0 -incr 0.2]
#    lappend prop_list [list "fast halo" CP_HALO_FAST -binary \
			   -help "Faster but less accurate halo calculation.  CP_HALO_FAST variable."]

    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
      # cancelled
      return ""
    }

    set type $CP_LAST_TYPE
  }

  switch $type {
    netlist - layout {
      # do it
      _cp_$type
    }

    menu {
      # just bring up the menu
      _cp_make_menu
    }
  }
}


proc _cp_netlist {} -desc {
  find the critical path attached to the selected cells and create a spice model of it
} {

  global CP_TRACE CP_TYPE CP_CAPS CP_ALL_NETS CONTINUATION FILE_ID CP_NAMES
  global CP_SUBCIRCUIT CP_LEVEL CP_TOP_IOS COMMENT CP_RES MC MC_VERSION PORTS
  global CP_ROUTE CP_TOP_NAMES MC_GLOBAL CP_TRACE_ARRAY

  if {[sel_what cells] == ""} {
    set message "Aborting, must select one or more cells to extract the critical path from before running."
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK

    return
  }

  set cell [lay_rootcell]
  set topcell $cell

  # figure out the filename to write this netlist to
  set file [lindex [cell_info $cell] 1]
  if {$file == ""} {
    set dir "[pwd]/"
  } else {
    set dir [file dirname $file]/
    if {$dir == "./"} {
      set dir "[pwd]/"
    }
  }
  set filename "$dir${cell}_cp.sp"

  puts "Creating spice netlist of critical path of CELL $cell ..."

  # open the spice output filename
  if {[catch {open $filename w} FILE_ID] != 0} {
    set message "Aborting, can't create file $filename: $FILE_ID"
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK

    return
  }

  catch {unset CP_TRACE}
  catch {unset CP_TRACE_ARRAY}
  catch {unset CP_TYPE}
  catch {unset PORTS}
  catch {unset CP_CAPS}
  catch {unset CP_RES}
  catch {unset CP_ALL_NETS}
  catch {unset CP_SUBCIRCUIT}
  catch {unset CP_LEVEL}
  catch {unset CP_NAMES}
  catch {unset CP_TOP_IOS}
  catch {unset CP_TOP_NAMES}
  set CP_NAMES(_unique) 0

  catch {unset MC_GLOBAL}

  set CONTINUATION "+ "
  set COMMENT "*"

  # want parasitics
  set save_parasitics [use_first MC(parasitics) '0]
  set MC(parasitics) 1

  # compute routable layers for resistance calculation
  set CP_ROUTE ""
  foreach via [techinfo vias] {
    lappend CP_ROUTE [techinfo above $via]
  }

  # get all top labels.  This insures that they will get preference
  # when making unique names for nets.
  eval lay_box [lay_bbox]
  lay_internals -area -hide
  foreach label [split [db_search labels] \n] {
    set CP_TOP_NAMES([lindex $label 6]) 1
  }

  # must insure that everything is expanded for this to work
  lay_internals -area

  ext_puts "* SPICE critical path for \"$cell\" (generated from MAX-MCC$MC_VERSION)\n"
#  ext_puts ".INCLUDE '${cell}_cp.h'\n"

  undo_disable

  # trace the entire critical path
  foreach cell [split [sel_what cells] \n] {
    setl {name instance x1 y1 x2 y2 cell_path} $cell
    puts "Finding Critical Path containing $cell_path$name ($instance)"

    _cp_trace $cell drivers
    _cp_trace $cell receivers
  }

  # write the netlist for each subcircuit
  puts "\nWriting netlist (subcircuits) ..."
  foreach cell [array names CP_TRACE] {
    if {$CP_TRACE($cell) != "load"} {
      set instance $CP_TYPE($cell)
      if {![info exists CP_SUBCIRCUIT($instance)]} {
	# haven't done this one yet
	set CP_SUBCIRCUIT($instance) 1

	:load $instance
	extract_subcircuit
      }
    }
  }

  # restore toplevel cell
  :load $topcell

  # now write the top level spice netlist
  puts "\nWriting netlist (top level) ..."
  ext_puts "* Main CELL $topcell"
  setl {ins outs} [_cp_create_spice_netlist]

  # insure that supplies are in here
  set MC_GLOBAL($MC(supply,low)) 1
  set MC_GLOBAL($MC(supply,high)) 1

  ext_puts "\n.GLOBAL [array names MC_GLOBAL]\n"
  ext_puts "*.END"

  # close the spice output file
  close $FILE_ID

  puts "\nSpice critical path netlist $filename created."

  # make a sample header file if there isn't one yet
  _cp_make_header $filename $ins $outs

  # select all of the cells in the critical path so the user can see them.
  _cp_select

  # make things look purty
  eval lay_box [lay_bbox]

  undo_enable

  # restore to what it was
  set MC(parasitics) $save_parasitics

  # bring up the menu
  _cp_make_menu

  puts "done."
}


proc _cp_select {{what ""}} -desc {
  select cells from last run of cp.  If argument is non-nil, also selects load cells.
} {

  global CP_TRACE PROBE PORTS CP_ALL_NETS

  sel_clear

  if {[string index $what 0] == "n"} {
    # highlite wires, not cells

    puts "Selecting all nets in critical path ..."

    if {[info exists PORTS(_NON_LOAD_CELLS_)]} {
      foreach net [array names CP_ALL_NETS] {
	if {[llength [eval db_search paint -cell __SELECT__ -any_cell -area [lrange $CP_ALL_NETS($net) 0 1] $CP_ALL_NETS($net)]] == 0} {

#	  puts "selecting $net ..."
	  eval sel_net -more -point $CP_ALL_NETS($net)
	} else {
#	  puts "skipping $net"
	}
      }

    } else {
      foreach net [array names PROBE] {
	setl {layer x1 y1} [lindex $net 0]
	sel_net -more -point $x1 $y1 $layer
      }
    }

    return
  }

  if {$what == ""} {
    puts "Selecting cells in critical path ..."

    if {[info exists PORTS(_NON_LOAD_CELLS_)]} {
      # special case of creating layout
      foreach cell $PORTS(_NON_LOAD_CELLS_) {
	msg_catch "sel_cell -more [lindex $cell 0]" a b c
      }
      return
    }

  } else {
    if {[info exists PORTS(_NON_LOAD_CELLS_)]} {
      puts "Aborting, all cells in the layout would be selected"
      return
    }

    puts "Selecting cells/loads in critical path ..."
  }

  foreach cell [array names CP_TRACE] {

    if {$CP_TRACE($cell) == "load" && $what == ""} {
      # only select active cells
      continue
    }

    sel_cell -more $cell
  }
}


proc _cp_trace {cell dir} -desc {
  trace cells connected to the given cell in the given direction
} {

  global CP_TRACE CP_TYPE PORTS CP_ROUTE CP_ALL_NETS CP_TRACE_BASIC
  global CP_TRACE_ARRAY

  setl {name instance x1 y1 x2 y2 cell_path} $cell
  set fullname $cell_path$name

  if {[info exists CP_TRACE($fullname)] && 
      [lsearch $CP_TRACE($fullname) $dir] != -1} {
    # been there, done that
    return
  }
  lappend CP_TRACE($fullname) $dir

  puts "  tracing cell $instance ($fullname) as a [string trimright $dir s]"

  set CP_TYPE($fullname) $instance

  # toast the old contents of this array
  upvar #0 _MC_CP_$fullname cp_array
  upvar #0 _MC_CP_KIND_$fullname cp_array_kind

  if {![info exists CP_TRACE_ARRAY($fullname)]} {
    catch {unset cp_array}
    catch {unset cp_array_kind}
    set CP_TRACE_ARRAY($fullname) 1
  }

  if {![info exists PORTS($fullname)]} {
    # get input, output, and inout ports for this cell
    set PORTS($fullname) [_mc_get_ports $fullname] 
  }

  set drivers ""
  set receivers ""

  # trace the net from every port
  foreach port $PORTS($fullname) {
    set port_name [lindex $port 6]
    if {[info exists check($port_name)]} {
      # already checked this
      continue
    }
    set check($port_name) 1

    set kind [lindex $port 9]
    if {($kind == "input" && $dir == "drivers") || \
	    ($kind == "output" && $dir == "receivers")} {
      # don't need to trace

      if {$CP_ROUTE != ""} {
	# netlist, not layout
	setl {layer x1 y1 x2 y2 pos text path group kind} $port

	# select the entire net associated with this port
	sel_net -point $x1 $y1 $layer

	set cp_array($text) ""
	set cp_array_kind($text) $kind

	foreach label [split [sel_what labels] \n] {
	  setl {_layer _x1 _y1 _x2 _y2 _pos _text _path _group _kind} $label

	  if {"$_path$_text" == "$path$text"} {
	    # we came from here
	    continue
	  }

	  if {[lsearch "input output inout" $_kind] == -1} {
	    # only look at inputs, outputs, and inouts
	    continue
	  }

	  lappend cp_array($text) $_path$_text
# these are mostly tied off -- don't show user
#	  set CP_ALL_NETS($_path$_text) [list $_x1 $_y1 $_layer]
	}
      }

    } else {
      setl {new_drivers new_receivers} [_cp_trace_net $port $cell $dir]

#      puts "---> _cp_trace_net [lindex $port 6] [lrange $cell 0 1] $dir $new_drivers, $new_receivers"

      set drivers [concat $drivers $new_drivers]
      set receivers [concat $receivers $new_receivers]
    }
  }

  # now trace drivers and receivers
  foreach cell $drivers {
    msg_catch "sel_cell $cell" "" info warn
    _cp_trace [sel_what cells] drivers
  }

  foreach cell $receivers {
    msg_catch "sel_cell $cell" "" info warn
    _cp_trace [sel_what cells] receivers
  }

  if {!$CP_TRACE_BASIC} {
    # trace these as drivers, also
    foreach cell $drivers {
      msg_catch "sel_cell $cell" "" info warn
      _cp_trace [sel_what cells] receivers
    }
  }
}


proc _cp_trace_net {port cell dir} -desc {
  trace net forwards and backwards, looking for drivers and receivers
  depending on direction.  remember loads also
} {

  global CP_TRACE CP_TYPE CP_CAPS CP_TIE CP_ALL_NETS lvs CP_LEVEL CP_TOP_IOS
  global CP_WIRE_CAP_FACTOR CP_RES CP_ROUTE PORTS

  setl {layer x1 y1 x2 y2 pos text path group kind} $port

  setl {name instance} $cell
  set fullname [lindex $cell 6]$name
  upvar #0 _MC_CP_$fullname cp_array
  upvar #0 _MC_CP_KIND_$fullname cp_array_kind

  # select the entire net associated with this port
#puts "  sel_net -point $x1 $y1 $layer"
  sel_net -point $x1 $y1 $layer
#puts traced

  # first see if this is connected to a global net
  set labels [split [sel_what labels] \n]
  foreach label $labels {
    if {[lindex $label 9] == "global"} {
      # this net is tied off to a global
      lappend cp_array($text) [lindex $label 6]
      set cp_array_kind($text) global

      return [list "" ""]
    }
  }

  if {$CP_ROUTE != ""} {
    # remember the capacitance on this net.  Remove space between number
    # and fF
    setl {value units} [ext_capacitance]
    set CP_CAPS($path$text) "[expr $value * $CP_WIRE_CAP_FACTOR]$units"
  }

  # remember all the paint associated with this net for probing
  set CP_CAPS(name,$path$text) [split [sel_what paint] \n]

  set drivers ""
  set receivers ""

  set cp_array($text) ""
  set cp_array_kind($text) $kind

  foreach label $labels {
    setl {_layer _x1 _y1 _x2 _y2 _pos _text _path _group _kind} $label

    if {"$_path$_text" == "$path$text"} {
      # we came from here
      continue
    }

    if {[lsearch "input output inout" $_kind] == -1} {
      # only look at inputs, outputs, and inouts
      continue
    }

    lappend cp_array($text) $_path$_text
    set CP_ALL_NETS($_path$_text) [list $_x1 $_y1 $_layer]

    set _path [string trimright $_path /]

    if {$_path == ""} {
      # top level net, skip
      continue
    }

    if {![info exists CP_TYPE($_path)]} {
      # need to find the type (instance) for the cell connected to this label
      msg_catch "sel_cell $_path" "" toss
      set CP_TYPE($_path) [lindex [sel_what cells] 1]
    }

    # check to make sure this is a leaf cell
    if {![info exists CP_LEVEL($CP_TYPE($_path))]} {

      set save_cell [lay_rootcell]
      :load $CP_TYPE($_path)

      eval lay_box [lay_bbox]
      lay_internals -area

      if {[_is_leaf_cell]} {
	# leaf cell
	set CP_LEVEL($CP_TYPE($_path)) leaf
      } else {
	# not leaf cell
	set CP_LEVEL($CP_TYPE($_path)) not_leaf
      }

      # return to where we were
      eval lay_box [lay_bbox]

      :load $save_cell
    }

    if {$CP_LEVEL($CP_TYPE($_path)) != "leaf"} {
      # ignore this port since it isn't connected to a leaf cell
      continue
    }

    set skip 0
    # check if this should be tied off
    if {[info exists CP_TIE($CP_TYPE($_path))]} {
      foreach pair $CP_TIE($CP_TYPE($_path)) {
	if {[lsearch -glob $_text [lindex $pair 0]] != -1} {
	  # found a match
	  if {[info exists CP_ALL_NETS($path$text)]} {
	    # already been here
	    break
	  }

	  set skip 1
	  # make this a load
	  set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]

	  if {$dir != "drivers"} {
	    # tie off
	    # TODO -- cp_array needs to know this later ----- maybe???
#	    set cp_array($text) [lindex $pair 1]
            set PORTS($path$text) [lindex $pair 1]
	  }
	}
      }
    }

    if {$skip} {
      continue
    }

#puts "checking --> $_path , $_text ($_kind) driven from $kind"

    switch $kind {
      "input" {
	# outputs drove to me, inputs are loads, inouts are loads (for now)
	switch $_kind {
	  "input" {
	    set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]
	  }

	  "inout" {
	    set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]
	  }

	  "output" {
	    lappend receivers $_path
	    _cp_compute_resistance $label $port
	  }
	}
      }
      
      "output" {
	# outputs and inouts are loads, inputs I drive to
	switch $_kind {
	  "input" {
	    lappend drivers $_path
	    _cp_compute_resistance $port $label
	  }
	  "inout" {
	    # don't follow these
	    set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]
	  }

	  "output" {
	    # shouldn't happen
	    set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]
	  }
	}
      }

      "inout" {
	# outputs are loads, inputs are receivers
	switch $_kind {
	  "input" {
	    if {$dir == "drivers"} {
	      lappend drivers $_path
	      _cp_compute_resistance $port $label
	      _cp_compute_resistance $label $port
	    } else {
	      set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]
	    }
	  }
	  "inout" {
	    # inouts are inputs if of a different type (special case)
	    # Note, looks in lvs translation table
	    if {[use_first lvs($instance) instance] == \
		    [use_first lvs($CP_TYPE($_path)) CP_TYPE($_path)]} {
	      # same kind, this is just a load
	      set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]
	    } elseif {[info exists CP_ALL_NETS($path$text)]} {
	      # this is a special case load (we've already been here)
	      set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]
            } elseif {$dir == "drivers"} {
	      # this is an input	
#puts "!!*driver* $_path $_path $_kind $_text $kind $text"
	      lappend drivers $_path
	      _cp_compute_resistance $port $label
	      _cp_compute_resistance $label $port
	    } else {
	      set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]
	    }
	  }

	  "output" {
	    if {$dir == "receivers"} {
	      lappend receivers $_path
	      _cp_compute_resistance $label $port
	      _cp_compute_resistance $port $label
	    } else {
	      set CP_TRACE($_path) [use_first CP_TRACE($_path) 'load]
	    }
	  }
	}
      }
    }
  }

  if {$kind == "input" && $receivers == ""} {
    # this must be a toplevel input
    lappend CP_TOP_IOS(input) $path$text
  }
  if {$kind == "output" && $drivers == ""} {
    # this must be a toplevel output
    lappend CP_TOP_IOS(output) $path$text
  }
  if {$kind == "inout"} {
    if {$dir == "drivers"} {
      # TODO
    } else {
      # TODO
    }
  }

#  puts "----- [lindex $cell 0] $dir d=$drivers r=$receivers"
  return [list $drivers $receivers]
}


proc _cp_compute_resistance {from to} -desc {
  compute the resistance between labels on the same net
} {

  global CP_RES CP_ROUTE

  if {$CP_ROUTE == ""} {
    return ""
  }

  setl {layer x1 y1 x2 y2 pos text path group kind} $from
  setl {_layer _x1 _y1 _x2 _y2 _pos _text _path _group _kind} $to

  # crude but all we got for now

  # compute the manhattan distance between the labels
  setl {from_x from_y} [center_coords $x1 $y1 $x2 $y2]
  setl {to_x to_y} [center_coords $_x1 $_y1 $_x2 $_y2]

  set dist [expr abs($from_x - $to_x) + abs($from_y - $to_y)]

  # compute the average width (choke, choke)
  sel_net -point $x1 $y1 $layer

  set geometries [split [ext_geometry] \n]
  set area 0
  set perim 0


  foreach l $CP_ROUTE {
    setl {num resistivity} [ext_layer_parameters $l]
    if {$l == [lindex $CP_ROUTE 0]} {
      # uses first metal resistance (pessimistic)
      set r_per_sq [expr 1.0e-3 * $resistivity]
    }

    setl {area1 um2 perim1 um} [lindex $geometries $num]

    set area [expr $area + $area1]
    set perim [expr $perim + $perim1]
  }

#  set length [expr ($perim + sqrt($perim*$perim - 16.0*$area))/4.0]
  set width [expr ($perim - sqrt($perim*$perim - 16.0*$area))/4.0]

  set res [expr $r_per_sq * $dist / $width]

# puts "-- $text $_text $width $dist $res  ($area $perim) $path$text"

  if {[info exists CP_RES($path$text)]} {
    # if this driver is driving multiple loads, choose the worst one
    set CP_RES($path$text) [max $CP_RES($path$text) $res]
  } else {
    set CP_RES($path$text) $res
  }

  return $res
}


proc _cp_create_spice_netlist {} -desc {
  create a spice netlist of the cp
} {

  global CP_TRACE CP_TYPE PORTS CP_CAPS CP_NAMES CP_TOP_IOS PROBE CP_RES MC

  set CP_NAMES(c) 0
  set CP_NAMES(m) 0
  set CP_NAMES(mload) 0

  catch {unset PROBE}

  set lines ""

  foreach cell [array names CP_TRACE] {
    upvar #0 _MC_CP_$cell cp_array
    upvar #0 _MC_CP_KIND_$cell cp_array_kind

    if {$CP_TRACE($cell) == "load"} {
      # don't process loads until later
      continue
    }

    set ports ""

    foreach net [lsort [array names cp_array]] {
      set fullnet $cell/$net

      if {![info exists nets($fullnet)]} {
	# need to come up with a name for this net
	set this_net ""
	set depth 1000
	set not_driven 1

	# pick name that is closest to the top level
	foreach port "$fullnet $cp_array($net)" {
	  set list [split $port /]
	  set len [llength $list]
	  if {$len < $depth} {
	    set depth $len
	    set this_net [lindex $list [expr $len - 1]]
	  }

	  if {[info exists CP_RES($port)]} {
	    set not_driven 0
	  }
	}

	if {$not_driven} {
	  lappend CP_TOP_IOS($cp_array_kind($net)) $this_net
	}

	set nets($fullnet,depth) $depth

	if {[lsearch [string tolower "$MC(supply,high) $MC(supply,low)"] [string tolower $this_net]] != -1} {
	  # don't uniqueify the supplies
	  set nets($fullnet) $this_net
	} else {
	  # make a unique name for this net
	  set nets($fullnet) [_cp_unique_name $this_net "" net $depth]
	}

	# put in the capacitance of this net if not done yet
	set add_cap 0
	if {[info exists CP_CAPS($fullnet)]} {
	  lappend lines "[_cp_unique_name "" C] $nets($fullnet) $MC(supply,low) $CP_CAPS($fullnet)"

	  # remember the name of this net for probing
	  set PROBE($CP_CAPS(name,$fullnet)) $nets($fullnet)

	  # unset so we won't put this in again.
	  unset CP_CAPS($fullnet)

	  set add_cap 1
	}

	foreach port $cp_array($net) {
	  if {[info exists CP_CAPS($port)] && !$add_cap} {
	    lappend lines "[_cp_unique_name "" C] $nets($fullnet) $MC(supply,low) $CP_CAPS($port)"

	    # remember the name of this net for probing
	    set PROBE($CP_CAPS(name,$port)) $nets($fullnet)

	    unset CP_CAPS($port)

	    set add_cap 1
	  }

	  set nets($port) $nets($fullnet)
	  set nets($port,depth) $nets($fullnet,depth)
	}
      }

      if {[info exists CP_RES($fullnet)]} {
	# this must be a driver since there is a resistance, add a resistor
	set new_net [_cp_unique_name net "" net] 
	# put in half the resistance since it is at one end only
	lappend lines "[_cp_unique_name "" R] $nets($fullnet) $new_net [expr $CP_RES($fullnet)/2.0]"
	lappend ports $new_net

      } else {
	lappend ports $nets($fullnet)
      }
    }

    # write the spice line.  Nets are in alphabetical order
    lappend lines "* $cell"
    lappend lines "[_cp_unique_name $CP_TYPE($cell) X] $ports $CP_TYPE($cell)"
  }

  # now put in the loads.  This is done afterwards so we only put in
  # loads for nets actually used
  set top_cell [lay_rootcell]

  foreach cell [array names CP_TRACE] {

    if {$CP_TRACE($cell) != "load"} {
      # skip all but loads now
      continue
    }

#    puts -nonewline .

    lappend lines "* $cell"

    set instance $CP_TYPE($cell)
    if {![info exists loads($instance)]} {
      set loads($instance) ""

      # goto this cell
      :load $instance
      
      sel_labels -kind input
      sel_labels -more -kind output
      sel_labels -more -kind inout

      catch {unset dups}
      foreach port [split [sel_what labels] \n] {
	set text [lindex $port 6]

	set loads($instance,$text) [_cp_find_load $port]
	lappend loads($instance) $text
      }
    }

    catch {unset dups}
    foreach text $loads($instance) {

      if {[info exists nets($cell/$text)]} {
	# this is a load

	# check to make sure there are duplicate net names on the same net.
	if {[info exists dups($nets($cell/$text))]} {
	  # ignore multiple net name
	  continue
	}
	set dups($nets($cell/$text)) 1

	# write the spice load devices
	foreach load $loads($instance,$text) {
	  lappend lines [format $load [_cp_unique_name $text M] $nets($cell/$text)]
	}
      }
    }
  }

  # restore the top level cell
  :load $top_cell
  
  # tell the user what top level ios we found

  set ins ""
  set other_ins ""
  foreach net [use_first CP_TOP_IOS(input)] {
    if {[use_first nets($net,depth)] == 1} {
      # top level net
      if {[lsearch -exact $ins $nets($net)] == -1} {
	lappend ins $nets($net)
      }
    } else {
      # not top level net
      set this_net [use_first nets($net) net]
      if {[lsearch -exact $other_ins $this_net] == -1} {
	lappend other_ins $this_net
      }
    }
  }
  regsub -all {\{|\}} [lsort $ins] "" ins
  puts "\nInputs: $ins"

  if {$other_ins != ""} {
    regsub -all {\{|\}} [lsort $other_ins] "" other_ins
    puts "Other Inputs: $other_ins"
  }

  set outs ""
  set other_outs ""
  foreach net [use_first CP_TOP_IOS(output)] {
    if {[use_first nets($net,depth)] == 1} {
      # top level net
      if {[lsearch -exact $outs $nets($net)] == -1} {
	lappend outs $nets($net)
      }
    } else {
      # not a top level net
      set this_net [use_first nets($net) net]
      if {[lsearch -exact $other_outs $this_net] == -1} {
	lappend other_outs $this_net
      }
    }
  }

  regsub -all {\{|\}} [lsort $outs] "" outs
  puts "\nOutputs: $outs"

  if {$other_outs != ""} {
    regsub -all {\{|\}} [lsort $other_outs] "" other_outs
    puts "Other Outputs: $other_outs"
  }

  regsub -all {\{|\}} [lsort [concat $ins $outs]] "" all
  ext_puts "* .SUBCKT $top_cell $all"

  foreach line $lines {
    ext_puts $line
  }

  ext_puts "* .ENDS\t$ $top_cell"

  return [list $ins $outs]
}


proc _cp_find_load {port} -desc {
  trace gates and source/drains to compute caps
} {

  global cp_sd MC

  catch {unset cp_sd}

  setl {layer x1 y1} $port

  # select the entire net associated with this port
  sel_net -no_labels -point $x1 $y1 $layer

  set devices [techinfo devices]
  set sd ""
  foreach device $devices {
    set layer [lindex [techinfo device $device] 1]
    lappend sd $layer
    set device_of($layer) $device
  }

  # look for fets
  foreach paint [split [sel_what paint] \n] {
    set layer [lindex $paint 0]
    
    if {[lsearch $devices $layer] != -1} {
      # fet gate

      # assume the long dimension in the width 
      setl {layer x1 y1 x2 y2} $paint
      set dx [expr $x2 - $x1]
      set dy [expr $y2 - $y1]
      
      set l [min $dx $dy]
      if {![info exists fets($layer,$l)]} {
	set fets($layer,$l) 0
      }
      
      set fets($layer,$l) [expr $fets($layer,$l) + [max $dx $dy]]

    } elseif {[lsearch $sd $layer] != -1} {
      # fet source/drain

      # look for fets by oversizing and searching for devices
      _cp_extract_sd $paint $layer $device_of($layer)
    }
  }

  set result ""
  # add fets connect to cp at gate
  if {[info exists fets]} {
    foreach type [array names fets] {
      setl {kind l} [split $type ,]

      set term [use_first MC($kind,bulk)]
      set model [use_first MC($kind,model)]

      # source/drain capacitances don't matter here
      lappend result "%s $term %s $term $term $model W=[set fets($type)]U L=${l}U"
    }
  }

  # add fets connect to cp at source/drain
  foreach kind $devices {
    if {[info exists cp_sd($kind,l)]} {
      # yes there is a source drain here

      set term [use_first MC($kind,bulk)]
      set model [use_first MC($kind,model)]

      lappend result "%s %s $term $term $term $model W=[set cp_sd($kind,w)]U L=[set cp_sd($kind,l)]U ad=[set cp_sd($kind,area)]P pd=[set cp_sd($kind,perim)]U"
    }
  }

  return $result
}


# spice only allows a maximum name length of 13 characters
set NETLIST_MAX_NAME_LENGTH [use_first NETLIST_MAX_NAME_LENGTH '13]

proc _cp_unique_name {name {prefix ""} {alt ""} {depth ""}} -desc {
  creates a unique name suitable for spice
} {

  global CP_NAMES NETLIST_MAX_NAME_LENGTH CP_TOP_NAMES

  set name $prefix$name

  set lower_name [string tolower $name]

  if {[info exists CP_NAMES($lower_name)]} {
    # if depth 1, use it, otherwise make up a new name
    if {$depth != 1} {
      set name ${name}_[incr CP_NAMES($lower_name)]
    }
  } else {
    # check depth
    if {$depth != 1 && [info exists CP_TOP_NAMES($lower_name)]} {
      # not a top level but there is a name of that at top level
      # make up a new name
      set CP_NAMES($lower_name) 0
      set name ${name}_[incr CP_NAMES($lower_name)]
    } else {
      # name is unique, just save it
      set CP_NAMES($lower_name) 0
    }
  }

  # Mostly for spice netlisting
  if {[string length $name] > $NETLIST_MAX_NAME_LENGTH} {
    if {$alt != ""} {
      return [_cp_unique_name net]
    } else {
      # just retain the first letter
      set name $prefix[incr CP_NAMES(_unique)]
    }
  }

  return $name
}


# ok, there are a lot of ways in which this can be pessimistic

proc _cp_extract_sd {paint diff gate} -desc {
  tries to extract source/drain capacitances
} {

  global max_win cp_sd

  # oversize diffusion to find attached gates
  setl {layer x1 y1 x2 y2} $paint
  set dx [expr $x2 - $x1]
  set dy [expr $y2 - $y1]

  set area [expr $dx * $dy]
  set perim [expr 2.0 * ($dx+$dy)]

  # get any attached gates
  sel_area -any_cell -layers $gate \
      [expr $x1 - [res]] [expr $y1 - [res]] \
      [expr $x2 + [res]] [expr $y2 + [res]]

  set gates [split [sel_what paint] \n]
  set no_gates [llength $gates]

  # walk thru each gate
  foreach tran $gates {
    setl {layer x1 y1 x2 y2} $tran

    # this is to get the gate length
    sel_chunk -any_cell $gate $x1 $y1 $x2 $y2
    setl {layer x1 y1 x2 y2} [sel_what paint]

    set dx_g [expr $x2 - $x1]
    set dy_g [expr $y2 - $y1]

    set w [max $dx_g $dy_g]
    if {$w == $dx} {
      set sdd $dy
    } else {
      set sdd $dx
    }

    if {![info exists cp_sd($gate,w)]} {
      set cp_sd($gate,w) 0.0
      set cp_sd($gate,area) 0.0
      set cp_sd($gate,perim) 0.0
    }

    set cp_sd($gate,l) [min $dx_g $dy_g]
    set cp_sd($gate,w) [expr $cp_sd($gate,w) + $w]
    set cp_sd($gate,area) [expr $cp_sd($gate,area) + $w*$sdd/$no_gates]
    set cp_sd($gate,perim) [expr $cp_sd($gate,perim)+2.0*($w + $sdd)/$no_gates]
  }

  if {$no_gates == 0} {
    # this diffusion is not directly attached to a gate
    if {![info exists cp_sd($gate,l)]} {
      # no transistors yet
      set cp_sd($gate,w) 0.0
      set cp_sd($gate,area) 0.0
      set cp_sd($gate,perim) 0.0
    }

    set cp_sd($gate,area) [expr $cp_sd($gate,area) + $dx * $dy]
    set cp_sd($gate,perim) [expr $cp_sd($gate,perim) + 2.0*($dx + $dy)]
  }
} 


proc _cp_make_header {filename ins outs} -desc {
  make a sample header file if there isn't one yet
} {

  set header "[file rootname $filename].h"

  if {[file exists $header]} {
    puts "\nFile \"$header\" already exists.  No header file created.\n"
    
    return
  }

  # create the header
  if {[catch {open $header w} FILE_ID] != 0} {
    puts "Skipping, can't create header file $header: $FILE_ID"

    return
  }

  puts $FILE_ID "* Header for Critical Path of [lay_rootcell]."

  puts $FILE_ID "\n* <Insert spice models, options, and conditions>"

  puts $FILE_ID "\n.INCLUDE '$filename'\n"

  puts $FILE_ID "* Input stimulus"
  foreach in $ins {
    puts $FILE_ID "V$in $in gnd 0V"
  }

  puts $FILE_ID "\n* Output loads"
  foreach out $outs {
    puts $FILE_ID "C$out $out gnd 100fF"
  }

  puts $FILE_ID ""

  puts $FILE_ID ".END"

  # close the header file
  close $FILE_ID

  puts "\nCreated sample header file \"$header\".\n"
}


proc _cp_probe {{unplot ""} {type .xp}} {

  global PROBE MC

  # get suffix for this simulation
  set type [use_first MC(cp_suffix)]

  # insure that the entire net is selected.
  setl {layer x1 y1 x2 y2} [sel_what paint]
  if {$y2 == ""} {
    puts "Aborting, must select a net first."
    return
  }
  # select the entire net
  eval sel_net -point [center_coords $x1 $y1 $x2 $y2] $layer

  set paint [split [sel_what paint] \n]

  if {![info exists PROBE($paint)]} {
    # might be a local net or global
    puts "Skipping, unknown net."
    return
  }

  # look for a waveform viewer

  set net $PROBE($paint)
  puts "Plotting $net"

  set filename "[lay_rootcell]_cp$type"

  if {$unplot != ""} {
    set unplot un
  }

  # hide brackets
  regsub -all {\[|\]} $net \\\\& foo

  if {$type == ".xp"} {
    set foo [string toupper $foo]
  } else {
    set foo [string tolower $foo]
  }

  # plot it
  send nst "nst_${unplot}plot $filename $foo"
}


proc _cp_make_menu {} {

  global max_win

  set win .cp

  # Just in case there is an old one around
  catch {destroy $win}

  toplevel $win 

  set x [max 0 [expr [winfo rootx $max_win] - 100]]
  set y [expr [winfo rooty $max_win] + 100]

  wm geometry $win "+$x+$y"
  wm resizable $win 0 0
  wm title $win "MCC CP"
    
  label $win.note -text "Options:"
  pack $win.note -side top

  button $win.select -text "select CP\n cells" -padx 1 -pady 1 \
    -command "_cp_select" -width 10
  pack $win.select -side top -ipadx 2m

  button $win.select_all -text "select CP\ncells/loads" -padx 1 -pady 1 \
    -command "_cp_select all" -width 10
  pack $win.select_all -side top -ipadx 2m

  button $win.select_nets -text "select CP\nnets" -padx 1 -pady 1 \
    -command "_cp_select nets" -width 10
  pack $win.select_nets -side top -ipadx 2m

  button $win.plot -text "plot net" -padx 1 -pady 1 \
    -command "_cp_probe" -width 10
  pack $win.plot -side top -ipadx 2m

  button $win.unplot -text "unplot net" -padx 1 -pady 1 \
    -command "_cp_probe unplot" -width 10
  pack $win.unplot -side top -ipadx 2m

  button $win.cancel -text "Close" -padx 1 -pady 1 \
    -command "catch \"destroy $win\"" -width 10
  pack $win.cancel -side top -ipadx 2m

  bind $win <Control-c> "catch \"destroy $win\""
}



proc _cp_layout {} -desc {
  find the critical path attached to the selected cells and create a layout of it for extraction.
} {

  global CP_TRACE CP_TYPE CP_ALL_NETS CONTINUATION FILE_ID CP_NAMES CP_TRACE_ARRAY
  global CP_SUBCIRCUIT CP_LEVEL CP_TOP_IOS COMMENT MC MC_VERSION PORTS
  global CP_ROUTE CP_TOP_NAMES MC_GLOBAL CPCELL CP_HALO_PAINT CP_HALO

  set cells [split [sel_what cells] \n]
  if {$cells == ""} {
    set message "Aborting, must select one or more cells to extract the critical path from before running."
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK

    return
  }

  set cell [lay_rootcell]
  set topcell $cell

  # figure out the cell for this layout
  set CPCELL "${cell}_cp"

  puts "Creating layout of critical path of CELL \"$cell\" in \"$CPCELL\" ..."
  # create a new cell or replace if exists
  _mc_make_cell $CPCELL

  # return to starting cell
  :load $cell
  eval lay_box [lay_bbox]

  catch {unset CP_TRACE_ARRAY}
  catch {unset CP_TRACE}
  catch {unset CP_TYPE}
  catch {unset PORTS}
  catch {unset CP_ALL_NETS}
  catch {unset CP_SUBCIRCUIT}
  catch {unset CP_LEVEL}
  catch {unset CP_NAMES}
  catch {unset CP_TOP_IOS}
  catch {unset CP_TOP_NAMES}
  set CP_NAMES(_unique) 0

  catch {unset MC_GLOBAL}

  set CP_HALO_PAINT ""

  # so no resistance calculation
  set CP_ROUTE ""

  # get all top labels.  This insures that they will get preference
  # when making unique names for nets.
  foreach label [split [db_search labels -non_hier] \n] {
    set CP_TOP_NAMES([lindex $label 6]) 1
  }

  # must insure that everything is expanded for this to work
  lay_internals -area

  undo_disable

  # trace the entire critical path
  foreach cell $cells {
    setl {name instance x1 y1 x2 y2 cell_path} $cell
    puts "Finding Critical Path containing $cell_path$name ($instance)"

    _cp_trace $cell drivers
    _cp_trace $cell receivers
  }

  # restore toplevel cell
  :load $topcell

  # put in the cells
  puts "\nAdding cells/loads ..."

  sel_clear
  foreach cell [array names CP_TRACE] {
    if {$CP_TRACE($cell) != "load"} {
      sel_cell -more $cell
#      set save($cell) 1
    }
  }

  db_cell_copy -source __SELECT__ $CPCELL
  # got all of the non loads
  set PORTS(_NON_LOAD_CELLS_) [split [db_search cells -cell $CPCELL] \n]

  sel_clear
  foreach cell [array names CP_TRACE] {
    if {$CP_TRACE($cell) == "load"} {
#      if {[info exists save($cell)]} {
#	puts "----> FOUND dup $cell"
#	continue
#      }

      sel_cell -more $cell
    }
  }

  db_cell_copy -source __SELECT__ $CPCELL

  # put in the nets
  puts "\nAdding nets and labels ..."
  _cp_create_layout_nets

  if {$CP_HALO} {
    _cp_add_halo
  }

  # make things look purty
  eval lay_box [lay_bbox]

  # goto the new cell
  :load $CPCELL

  eval lay_box [lay_bbox]

  # remove lower layers from routes -- should all be in cells
  # this will remove poly,pfet,nfet,ndif,pdif,nwc,pwc
  set ct [techinfo above [lindex [techinfo device \
				      [lindex [techinfo devices] 0]] 0]]
  set layers [concat [techinfo devices] [techinfo below $ct]]
  eval sel_area -no_labels -layers [join $layers ,] [lay_bbox]
  :delete

  # select the cells that are in the critical path as opposed to the loads.
  sel_clear
  foreach cell $PORTS(_NON_LOAD_CELLS_) {
    sel_cell -more [lindex $cell 0]
  }

  undo_enable

  # bring up the menu
  _cp_make_menu

  puts "done."
}


proc _cp_create_layout_nets {} -desc {
  creates the layout nets for cp_layout
} {

  global CP_TRACE CP_TYPE PORTS CP_NAMES CP_TOP_IOS PROBE MC PORTS
  global CPCELL CP_TIE_INPUT CP_HALO CP_HALO_PAINT

  set CP_NAMES(c) 0
  set CP_NAMES(m) 0
  set CP_NAMES(mload) 0

  catch {unset PROBE}

  set lines ""

  foreach cell [array names CP_TRACE] {
    upvar #0 _MC_CP_$cell cp_array

    if {$CP_TRACE($cell) == "load"} {
      # don't process loads until later
      continue
    }

    foreach net [lsort [array names cp_array]] {
      set fullnet $cell/$net

      if {[info exists nets($fullnet)]} {
	# already got this one
	continue
      }

      # get the net attached to this port
      sel_cell $cell
      edit_push in_place

      # TODO use db_search labels
      sel_labels -text $net
      set labels [split [sel_what labels] \n]
      sel_clear

      # NOTE: only use first label -- assume all are connected
      foreach label $labels {
	sel_net -more -point [lindex $label 1] [lindex $label 2] \
	    [lindex $label 0] 
	break
      }

      set global 0

      # only want the topmost name on this net
      set depth 2000
      set this_net ""
      foreach label [split [sel_what labels] \n] {
	if {[lindex $label 9] == "hidden"} {
	  continue
	}

	if {[lindex $label 9] == "global"} {
	  # this guy is tied off
	  set global 1

	  # add tie off
	  # do to all since we don't know if they're connected
	  foreach _label $labels {
	    db_label -cell $CPCELL -kind global [lindex $_label 0] \
		[lindex $label 6] [lindex $_label 1] [lindex $_label 2]
	  }

          break
	}

	set path [lindex $label 7]
	set text [lindex $label 6]
	if {[info exists PORTS($path$text)]} {
	  # from a tie off
	  set this_net $PORTS($path$text)
	  set this_label $label
	  set depth 1
	  break

	} else {
	  set len [llength [split $path /]]
	  if {$len < $depth} {
	    set depth $len
	    set this_net $text
	    set this_label $label
	  }
	}
      }

      # depth should never be zero
      set depth [max $depth 1]

      if {$global} {
	continue
      }

      # make this label in the new layout
      if {$this_net != ""} {
	if {[lsearch [string tolower "$MC(supply,high) $MC(supply,low)"] [string tolower $this_net]] != -1} {
	  # don't uniqueify the supplies
	  set nets($fullnet) $this_net
	} else {
	  # make a unique name for this net
	  set nets($fullnet) [_cp_unique_name $this_net "" net $depth]
	}

	db_label -cell $CPCELL -kind [lindex $this_label 9] \
            [lindex $this_label 0] $nets($fullnet) \
            [lindex $this_label 1] [lindex $this_label 2]

      } else {
        set nets($fullnet) *NONE*
      }

      # save wires for a halo
      if {$CP_HALO} {
	lappend CP_HALO_PAINT [split [sel_what paint] \n]
      }

      # now get it without any labels so we only put the top one in
      sel_clear
      # NOTE: only use first label -- assume all are connected
      foreach label $labels {
	sel_net -more -no_labels -point [lindex $label 1] [lindex $label 2] \
	    [lindex $label 0] 
	break
      }

      db_cell_copy -source __SELECT__ $CPCELL

      edit_pop

      set nets($fullnet,depth) $depth

      foreach port $cp_array($net) {
	set nets($port) $nets($fullnet)
	set nets($port,depth) $nets($fullnet,depth)
      }
    } 
  }

  # now put in the loads.  This is done afterwards so we only tie off
  # inputs/inouts that aren't connected
  foreach cell [array names CP_TRACE] {

    # push (in_place) into this cell
    sel_cell $cell
    edit_push in_place
      
    sel_labels -kind input
    sel_labels -more -kind inout

    # TODO: check if any outputs -- could have been connected to
    # something else off the critical path

    foreach label [split [sel_what labels] \n] {
      set text [lindex $label 6]

      # check to see if this is already connected to something
      # usually only for inouts.
      if {[info exists nets($cell/$text)]} {
	# already got this one
	continue
      }

      # tie this baby off
      set tie [use_first CP_TIE_INPUT($CP_TYPE($cell),$text) \
                         CP_TIE_INPUT(DEFAULT) 'gnd]

      db_label -cell $CPCELL -kind global [lindex $label 0] \
	  $tie [lindex $label 1] [lindex $label 2]
    }
    
    # pop back
    edit_pop
  }
  
  # tell the user what top level ios we found

  set ins ""
  set other_ins ""
  foreach net [use_first CP_TOP_IOS(input)] {
    if {$nets($net,depth) == 1} {
      # top level net
      if {[lsearch -exact $ins $nets($net)] == -1} {
	lappend ins $nets($net)
      }
    } else {
      # not top level net
      if {[lsearch -exact $other_ins $nets($net)] == -1} {
	lappend other_ins $nets($net)
      }
    }
  }
  regsub -all {\{|\}} [lsort $ins] "" ins
  puts "\nInputs: $ins"

  if {$other_ins != ""} {
    regsub -all {\{|\}} [lsort $other_ins] "" other_ins
    puts "Other Inputs: $other_ins"
  }

  set outs ""
  set other_outs ""
  foreach net [use_first CP_TOP_IOS(output)] {
    if {$nets($net,depth) == 1} {
      # top level net
      if {[lsearch -exact $outs $nets($net)] == -1} {
	lappend outs $nets($net)
      }
    } else {
      # not a top level net
      if {[lsearch -exact $other_outs $nets($net)] == -1} {
	lappend other_outs $nets($net)
      }
    }
  }

  regsub -all {\{|\}} [lsort $outs] "" outs
  puts "Outputs: $outs"

  if {$other_outs != ""} {
    regsub -all {\{|\}} [lsort $other_outs] "" other_outs
    puts "Other Outputs: $other_outs"
  }

  return [list $ins $outs]
}


proc _cp_add_halo {} -desc {
  add halos aournd all critical nets for accurate extraction -- but no
  millering 
} {

  global CP_HALO_PAINT CP_HALO_RADIUS CPCELL CP_HALO_FAST

  set metals [techinfo layers metal]

  set count 0
  puts "\nAdding halo nets (radius $CP_HALO_RADIUS) ..."

  foreach net $CP_HALO_PAINT {
    incr count
    if {[expr $count % 10] == 0} {
      puts -nonewline "."
      flush stdout
    }

    foreach paint $net {
      setl {layer x1 y1 x2 y2} $paint
      
      if {[lsearch $metals $layer] == -1} {
	# skip this layer
	continue
      }

      sel_area -any_cell -layers $layer [expr $x1 - $CP_HALO_RADIUS] \
	  [expr $y1 - $CP_HALO_RADIUS] [expr $x2 + $CP_HALO_RADIUS] \
	  [expr $y2 + $CP_HALO_RADIUS]

      foreach _paint [split [sel_what paint] \n] {
	setl {_layer _x1 _y1 _x2 _y2} $_paint

#	if {!$CP_HALO_FAST || [llength [db_search paint -cell $CPCELL -area $_x1 $_y1 $_x2 $_y2 $_layer]] == 0} {
#	}

	if {[llength [db_search paint -cell $CPCELL -area $_x1 $_y1 $_x2 $_y2 $_layer]] == 0} {
	  # not already added, add
	  sel_region -point $_x1 $_y1 $_layer
	  db_cell_copy -source __SELECT__ $CPCELL      
	}
      }
    }
  }

  puts "\n"
}


