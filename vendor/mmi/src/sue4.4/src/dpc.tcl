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


# SUE data path compiler (dpc).
# Hierarchical verilog netlisting and caching.

# cells can be mirrored which flips them around their x axis
# in the SUE DPC direction.  Cells with port files can also be flipped.

set XFORM(N,mirror) FN
set XFORM(FN,mirror) N
set XFORM(S,mirror) FS
set XFORM(FS,mirror) S
set XFORM(E,mirror) FE
set XFORM(FE,mirror) E
set XFORM(W,mirror) FW
set XFORM(FW,mirror) W

set XFORM(N,flip) FS
set XFORM(FN,flip) S
set XFORM(S,flip) FN
set XFORM(FS,flip) N
set XFORM(W,flip) FE
set XFORM(FW,flip) E
set XFORM(E,flip) FW
set XFORM(FE,flip) W

set XFORM(N,R90) E
set XFORM(FN,R90) FW
set XFORM(S,R90) W
set XFORM(FS,R90) FE
set XFORM(W,R90) N
set XFORM(FW,R90) FS
set XFORM(E,R90) S
set XFORM(FE,R90) FN

# used for picking port locations out of a list based on orientation.
set XFORM(N,index) 2
set XFORM(FN,index) 3
set XFORM(S,index) 4
set XFORM(FS,index) 5
set XFORM(E,index) 6
set XFORM(FE,index) 7
set XFORM(W,index) 8
set XFORM(FW,index) 9

# used for preroutes
set XFORM(preroute,R0) H
set XFORM(preroute,RX) H
set XFORM(preroute,RY) H
set XFORM(preroute,RXY) H

set XFORM(preroute,R90) V
set XFORM(preroute,R90X) V
set XFORM(preroute,R90Y) V
set XFORM(preroute,R270) V

# used for pins
set XFORM(pin,I,R0) w
set XFORM(pin,I,RY) w
set XFORM(pin,I,RX) e
set XFORM(pin,I,RXY) e

set XFORM(pin,I,R90) n
set XFORM(pin,I,R90X) n
set XFORM(pin,I,R90Y) s
set XFORM(pin,I,R270) s

set XFORM(pin,O,R0) e
set XFORM(pin,O,RY) e
set XFORM(pin,O,RX) w
set XFORM(pin,O,RXY) w

set XFORM(pin,O,R90) s
set XFORM(pin,O,R90X) s
set XFORM(pin,O,R90Y) n
set XFORM(pin,O,R270) n

# for nl

set XFORM(nlport,input) in
set XFORM(nlport,output) out
set XFORM(nlport,inout) inout

set XFORM(nlport,in) input
set XFORM(nlport,inout) inout
set XFORM(nlport,out) output

# convert SUE orient to DEF orient and back

set XFORM(def,R0) N
set XFORM(def,RX) FS
set XFORM(def,RY) FN
set XFORM(def,RXY) S
set XFORM(def,R90) E
set XFORM(def,R90X) FW
set XFORM(def,R90Y) FE
set XFORM(def,R270) W

set XFORM(undef,N) R0
set XFORM(undef,FS) RX
set XFORM(undef,FN) RY
set XFORM(undef,S) RXY
set XFORM(undef,E) R90
set XFORM(undef,FW) R90X
set XFORM(undef,FE) R90Y
set XFORM(undef,W) R270

foreach z [array names XFORM def,*] {
  set XFORM(undef,$XFORM($z)) [string range $z 4 end]
}


set XFORM(pin,in) I
set XFORM(pin,out) O
set XFORM(pin,inout) B


# top level procedure called by menu, etc.  First calls verilog_netlist
# and then does the dpc stuff.

proc dpc_netlist {schem dir} {

  global cur_c cur_s scale NETLIST SUFFIX DPC PROBE_TYPE
  global DPC_DATA PLACEMENT_DATA DPC_AREA DPC_FROM_DEF
  global SPACERS DPC_REL DPC_ABS DPC_SIZE DPC_CAP DPC_PREROUTES

  # close probe if open
  if {$PROBE_TYPE == "interactive" && [check_probe //]} {
    interactive_close_probe
  }

  # don't run from a placement file
  if {[is_placement $cur_s]} {
    # we are in a placement file
    sue_error "Aborting, can't netlist from a placement file."
    sue_error flush
    return
  }

  upvar #0 SUE_${cur_s}_placement data
  if {[info exists data]} {
    # if there is a placement file, flag as needing to be updated
    set data(_UPDATE_ME_) 1
  }

  # allows for different grid sizes in x and y
  setl {xscale yscale} $DPC(SCALE)
  if {$yscale == ""} {
    set yscale $xscale
  }
  set DPC(xscale) [expr round($xscale * $DPC(UNITS))]
  set DPC(yscale) [expr round($yscale * $DPC(UNITS))]

  # gates that we don't have size info for
  catch {unset DPC_DATA}

  catch {unset DPC_REL}
  catch {unset DPC_ABS}
  catch {unset DPC_AREA}
  catch {unset DPC_PREROUTES}
  catch {unset DPC_FROM_DEF}

  set DPC(CELLS) 0
  set DPC(COUNT) 0

  # used for writing pin info
  catch {unset SPACERS}

  # get gate size information
  _get_gate_sizes

  # first do a verilog netlist
  set schematic_list [verilog_netlist $schem $dir]

  # can't wait to close the netlist file (needed for nl)
  catch {close $NETLIST(file_id)}

  check_interrupt

  # busy gets reset so we must do it again
  busy

  puts "DPC relative placement:"

  # save where we are
  set save_cur_c $cur_c
  set save_cur_s $cur_s
  set save_scale $scale

  # now relative place all of the cell types from the bottom up
  foreach schematic $schematic_list {
    dpc_relative_place $schematic
    check_interrupt
  }

  # restore
  set cur_c $save_cur_c
  set cur_s $save_cur_s
  set scale $save_scale

  # stuff verilog into nl
  nl_read

  check_interrupt

  puts "DPC final placement ..."

  catch "unset PLACEMENT_DATA($cur_s,preroutes)"

  # do absolute placement starting from top level schematic
  dpc_absolute_place $cur_s

  setl {cols rows} $DPC_SIZE($cur_s)
  set PLACEMENT_DATA($cur_s) "GENERATE_ME"
  set PLACEMENT_DATA($cur_s,size) "$rows $cols"
  set PLACEMENT_DATA($cur_s,parasitics) 0

  puts "Data Path is [expr round(ceil(1.0*$rows/$DPC(DEFAULT_ROW_HEIGHT)))] rows ($rows grids) of [expr round(ceil(1.0 * $cols/$DPC(PITCH)))] bit pitches ($cols grids)."

  if {$rows != 0 && $cols != 0} {
    # compute area  for cell utilization
    set area 0.0
    foreach count [array names DPC_AREA *,count] {
      set type [lindex [split $count ,] 0]
      set area [expr $area + $DPC_AREA($count) * $DPC_AREA($type)]
    }

    puts "[format %.1f [expr 100.0 * $area / ($rows * $cols)]]% cell utilization with $DPC(CELLS) cell instances."
  }

  check_interrupt

  # put the component locations/orientations into nl
  _add_defs_to_nl

  if {[info_proc ppp] != ""} {
    puts "Executing ppp proc ..."
    if {[catch ppp msg]} {
      puts "PPP ERROR: $msg"
    }
  }

  # add top-level pins if specified by DPC(PINS)
  dpc_place_pins

#puts "-->adding preroutes"
  _add_preroutes

  check_interrupt

  puts "Creating DEF placement file ..."
  create_placement_file $rows $cols
}


# need to invalidate the NETLIST_CACHE of a cell in dpc mode if any 
# subcells changed, not just if their icons changed.  Note that we
# also need to re-verilog netlist these since there is data that
# is not cached that we need.

proc dpc_subcell_cache_invalidate {} {

  global NETLIST_CACHE SCHEMS DPC_SIZE DPC DPC_DATA

  foreach cell $SCHEMS(_LIST_) {
    if {[use_first NETLIST_CACHE($cell)] != "" && \
	    [use_first NETLIST_CACHE($cell,cache_type)] == "disk cached"} {
      # disk cached, remember date
      set date($cell) $NETLIST_CACHE($cell,date)
    } else {
      set date($cell) ""
    }
  }
    
  foreach cell $SCHEMS(_LIST_) {
    foreach parent [use_first SCHEMS(dpc,$cell)] {
      if {$date($cell) == "" && $date($parent) != ""} {
	set NETLIST_CACHE($parent) ""
	set NETLIST_CACHE($parent,invalid) "no date for $cell"
	set date($parent) "invalid"
	continue
      }

      if {$date($cell) == "invalid"} {
	set NETLIST_CACHE($parent) ""
	set NETLIST_CACHE($parent,invalid) "invalid date for $cell"
	set date($parent) "invalid"
	continue
      }

      if {$date($parent) == ""} {
	continue
      }

      if {$date($parent) < $date($cell)} {
	# parent is out of date
	set NETLIST_CACHE($parent) ""
	set NETLIST_CACHE($parent,invalid) "out of date for $cell"
	set date($parent) "invalid"
      }
    }
  }

  foreach cell $SCHEMS(_LIST_) {
    if {[use_first NETLIST_CACHE($cell)] == ""} {
      # already invalid, skip
      continue
    }

    foreach list [use_first NETLIST_CACHE($cell,dpc_size)] {
#      puts "check $cell -> $list"
      set instance [lindex $list 0]
      set type [lindex $list 1]

      if {![info exists DPC_SIZE($instance,file)]} {
	# look in the file <cell>.ports for cell size and port locations
	lookup_size $instance $type
      }

      if {![info exists DPC_SIZE($type)]} {
	# no size information for this gate, use the defaults
	if {[lindex $list 2] != \
		"$DPC(DEFAULT_COLUMN_WIDTH) $DPC(DEFAULT_ROW_HEIGHT) 1"} {
	  # invalidate, someone changed the defaults.
	  set NETLIST_CACHE($cell) ""
	  set NETLIST_CACHE($cell,invalid) "default size changed"
	  break
	}

      } elseif {[lindex $list 2] != $DPC_SIZE($type)} {
	# invalidate
	set NETLIST_CACHE($cell,invalid) "size changed"
	set NETLIST_CACHE($cell) ""
	break
      }

      # valid, remember port locations
      foreach pin [lindex $list 3] {
	set pin_name [lindex $pin 0]
	set DPC_DATA($type,$pin_name) [lrange $pin 1 end]
      }
    }
  }
}


# get gate size infomation
# NOTE: always assumes flip is one

proc _get_gate_sizes {} {

  global DPC DPC_SIZE

  catch {unset DPC_SIZE}

  # first read any lef data for cell sizes (this overrides all)
  _nl_read_lef

  foreach filename $DPC(PATH) {
    if {[catch "open $filename r" FILE_ID]} {
      # problem
      puts "DPC WARNING: $FILE_ID"
    } else {
      # now read in the table
      while {[gets $FILE_ID line] >= 0} {
	set pos [string first "\#" $line]
	if {$pos != -1} {
	  # remove comment
	  set line [string range $line 0 [expr $pos - 1]]
	}

	setl {name row col} $line
	if {![catch {nl_get_libcell_size $DPC(lib)/$name}]} {
	  # lef overrides
	  continue
	}

	if {$row != ""} {
	  # this row has data
	  # convert numbers to integer grids (bad for megacells, but ??? TODO)
	  set DPC_SIZE($name) [expr round($row)]
	  if {$col != ""} {
	    set col [expr int(round($col))]
	  } else {
	    set col $DPC(DEFAULT_ROW_HEIGHT)
	  }

	  if {($col / $DPC(DEFAULT_ROW_HEIGHT)) % 2 == 1} {
	    set flip 1
	  } else {
	    set flip 0
	  }

	  lappend DPC_SIZE($name) $col $flip
	}
      }
      # close the file
      close $FILE_ID
    }
  }
}


# look in the file <cell>.ports for cell size and port locations

proc lookup_size {cell type} {

  global DPC DPC_SIZE SUE auto_index SUFFIX

  set dir [find_dir_of_cell $cell]

  set flip ""

  set DPC_SIZE($cell,dir) $dir

  set filename $dir/$type$SUFFIX(dpc_ports)
  if {![file exists $filename]} {
    # try the mapped name
    set filename $dir/$cell$SUFFIX(dpc_ports)
  }

  if {[file exists $filename]} {
    # read the file
    if {[catch "open $filename r" FILE_ID]} {
      # problem
      puts "DPC WARNING: $FILE_ID"
      set DPC_SIZE($cell,file) 0
      return
    } 

    if {![catch {nl_get_libcell_size $DPC(lib)/$type}]} {
      # lef overrides
      set use_lef 1
    } else {
      set use_lef 0
    }

    # parses

    # bbox width [height]
    # port <port-name> x y 

    while {[gets $FILE_ID line] >= 0} {

      set pos [string first "\#" $line]
      if {$pos != -1} {
	# remove comment
	set line [string range $line 0 [expr $pos - 1]]
      }

      set line [string trim $line]

      if {$line == ""} {
	# comment or blank line, skip
	continue
      }

      switch [string tolower [lindex $line 0]] {

	"port" {
	  if {$use_lef} {
	    continue
	  }

	  set DPC_SIZE($type,port,[lindex $line 1]) [lrange $line 2 end]
	}

	"bbox" {
	  if {$use_lef} {
	    continue
	  }

	  # bounding box of cell, really width and height
	  setl {width height} [round_list [lrange $line 1 end]]
	  if {$width != ""} {
	    set DPC_SIZE($type) $width
	    if {$height != ""} {
	      lappend DPC_SIZE($type) [expr round($height)]
	    } else {
	      lappend DPC_SIZE($type) $DPC(DEFAULT_ROW_HEIGHT)
	    }
	  }
	}

	"flip" {
	  set flip [lrange $line 1 end]
	}

	"orient" {
	  set DPC_SIZE($type,orient) [lrange $line 1 end]
	}

	"xhalo" {
	  set DPC_SIZE($type,xhalo) [lrange $line 1 end]
	}

	default {
	  puts "DPC WARNING, syntax error in file $filename: $line"
	}
      }
    }

    if {![info exists DPC_SIZE($type)]} {
      sue_warning "DPC WARNING: No size data in ports file for gate: $type.  Using default width and height of $DPC(DEFAULT_COLUMN_WIDTH), $DPC(DEFAULT_ROW_HEIGHT) grids." DPC_REL
      set DPC_SIZE($type) \
	  "$DPC(DEFAULT_COLUMN_WIDTH) $DPC(DEFAULT_ROW_HEIGHT)"
    }

    if {$flip == ""} {
      # flip if an odd number of rows
      set flip [expr ([lindex $DPC_SIZE($type) 1] % \
			  (2 * $DPC(DEFAULT_ROW_HEIGHT))) > 0]
    }

    # add flip
    if {$use_lef} {
      # replace bogus flip
      set DPC_SIZE($type) [lreplace $DPC_SIZE($type) 2 2 $flip]
    } else {
      lappend DPC_SIZE($type) $flip
    }

    if {[use_first DPC_SIZE($type,orient)] != ""} {
      # place orientation at end if there is one
      lappend DPC_SIZE($type) $DPC_SIZE($type,orient)
    }

    # close the file
    close $FILE_ID

    # set this so we won't look up this type again
    set DPC_SIZE($cell,file) 1

  } else {
    # set this so we won't look up this type again
    set DPC_SIZE($cell,file) 0
  }
}



# first pass relative placement for this schematic

proc dpc_relative_place {schematic} {

  global cur_c cur_s scale DPC DPC_SIZE DPC_DATA DPC_REL NETLIST_CACHE
  global SUE_$schematic DPC_CACHE NONEWLINE GLOBALS VERILOG_TYPE XFORM

  puts -nonewline "    $schematic ... "
  flush stdout
  set NONEWLINE 1

  # check if we have cached this data.  If so, use it and we're done.
  if {[use_first NETLIST_CACHE($schematic,dpc)] != ""} {
    # need to check if any subcells have changed
    foreach pair [use_first NETLIST_CACHE($schematic,cells)] {
      setl {type cell} $pair

      if {[info exists DPC_CACHE($cell)]} {
	if {![info exists DPC_CACHE($schematic,$cell)] || \
		$DPC_CACHE($schematic,$cell) < $DPC_CACHE($cell)} {
	  # modified, flush cache
	  set NETLIST_CACHE($schematic,dpc) ""
	  set NETLIST_CACHE($schematic,invalid) "dpc: modified $cell"
	  break
	}
      }
    }
  }

  if {[use_first NETLIST_CACHE($schematic,dpc)] != ""} {
    # use the cache data
    setl [list DPC_REL($schematic) \
	      DPC_SIZE($schematic) \
	      DPC_REL($schematic,warnings) DPC_REL($schematic,preroutes)] \
	$NETLIST_CACHE($schematic,dpc)

    # show the user any warnings that were cached
    if {$DPC_REL($schematic,warnings) != ""} {
      puts "\n[join $DPC_REL($schematic,warnings) \n]"
      puts -nonewline "    $schematic ... "
    }

    puts $NETLIST_CACHE($schematic,cache_type)
    set NONEWLINE 0

    return
  }

  set DPC_REL($schematic,warnings) ""
  set DPC_REL($schematic) ""
  set unsized ""

  set NETLIST_CACHE($schematic,dpc_size) ""

  # increment this every time dpc netlisted so others can see if they
  # have an up-to-date version
  if {[info exists DPC_CACHE($schematic)]} {
    incr DPC_CACHE($schematic)
  } else {
    set DPC_CACHE($schematic) 1
  }

  # goto this schematic
  goto_schematic $schematic
#  set cur_c [set SUE_${schematic}(canvas)]
#  set cur_s $schematic
#  set scale [set SUE_${schematic}(scale)]

  upvar #0 TERMS_$cur_s TERMS

  # very relative row
  set row 0
  set max_row $row

  # maximum bit position in this schematic
  set max_bit 0

  # get the pitch and bit_slice from the schematic
  # in the special dpc_control icon if there is one.
  set id [$cur_c find withtag icon_dpc_control]
  upvar #0 ${cur_s}_inst$id i_data
  set pitch [use_first i_data(_pitch) DPC(PITCH)]
  set dpc_mode [use_first i_data(_mode) DPC(MODE)]
  set bit_slice [string match $dpc_mode "bit_slice"]

  if {[string match $dpc_mode "from_placement"]} {
#AAA --- REMOVE??? TODO
    # get everything from the placement file instead of generating
    # from the schematic.  Assumes placement is in-sync with schematic.

    # goto placement file
    if {[goto_schematic ${cur_s}_placement] == ""} {
      sue_error "ERROR, can't find placement file for cell \"$cur_s\".  Computing from schematic instead."
    } else {
      # read it
      read_placement_from_dpc

      # must return to schematic to write netlist cache
      goto_schematic $schematic

      # write out the netlist cache to a file if it is valid
      write_netlist_cache

      if {$NONEWLINE} {
	puts "done"
	set NONEWLINE 0
      } else {
	puts "    $schematic ... done"
      }

      return
    }
  }

  set save_scale $scale
  scale_canvas 10

  # get ordered instance list of icons in schematic
  set ordered_rows [order_icons]

  foreach row_ids $ordered_rows {

    set bit 10000
    upvar 0 REL_PLACE_$row REL_POS
    set this_row_inc 0

    foreach id $row_ids {

      # setup array with icon property values
      upvar #0 ${cur_s}_inst$id i_data

      # get the name of this instance
# can't use this since single bits stripped like [3]
#      set name [use_first TERMS($id)]
      set name [lookup_name [use_first i_data(_name) TERMS($id)]]
      if {$name == ""} {
	if {$i_data(type) == "spacer"} {
	  # very special case for spacer (name not in TERMS)
	  set name $i_data(_name)

	} else {
	  # not relevant -- like a row spanner
	  continue
	}
      }

      set dpc [use_first i_data(_dpc)]

      # is this a bused instance
      if {[is_bus $name] || [regexp {(\[\-*[0-9]+\])} $dpc tmp name]} {
	# bused instance

	# place this and then store lowest bit position for the next 
	# unplaced goes in bit
	set bit [dpc_compute_bit_positions $dpc \
		     $name $id $i_data(type) $row]

	if {$i_data(type) != "spacer" || $i_data(_rows) != "0"} {
	  set this_row_inc 1
	}

      } else {
	# not a bused index
	# look in dpc property first for where to put these icons
	# else check name to see if there is a bit specifier
	if {[regexp {\[(\-*[0-9]+)\]} $dpc tmp bit]} {
	  # use this property
	  lappend REL_POS($bit) "$id $i_data(type)"

	} elseif {[regexp {p=([0-9]+)} $dpc tmp bit]} {
	  # use this property
	  lappend REL_POS($bit) "$id $i_data(type)"

	} elseif {[regexp {\[(\-*[0-9]+)\]} [use_first i_data(_name)] tmp bit]} {
	  # use this property
	  lappend REL_POS($bit) "$id $i_data(type)"

	} else {
	  # place at the current bit location (no bit slice)
	  lappend REL_POS($bit) "$id $i_data(type) {} unp"
	}

	if {$bit != 10000 && $max_bit < $bit} {
	  set max_bit $bit
	}

	# special case of a spacer in a row by itself
	if {$i_data(type) != "spacer" || $i_data(_rows) != "0"} {
	  set this_row_inc 1
	}
      }
    }

    if {$max_row > $row || [info exists REL_POS]} {
      # if doesn't exist, probably a spanner by itself
      set row [expr [max $max_row $row] + $this_row_inc]
    }
  }

  # second pass relative placement.  The placement is absolute inside
  # this block but only relative to the rest of the world.
  
  set rows $row

  # these are relative
  set row 0
  set max_column 0
  set flip 0
  set last_max_delta_row $DPC(DEFAULT_ROW_HEIGHT)

  # restore scale
  scale_canvas $save_scale

  # walk thru each row from left to right
  for {set row_index 0} \
      {[info exists REL_PLACE_$row_index] || [info exists slice] \
	   || $row_index <= $max_row} \
      {incr row_index} {

    # add overflows from bit slice, if any
    foreach extra [array names slice] {
      set REL_PLACE_${row_index}($extra) \
	  [concat $slice($extra) [use_first REL_PLACE_${row_index}($extra)]]
    }
    catch {unset slice}

    # corresponds to highest bit position
    set column 0

    set max_delta_row 0
    set max_flip 1

    # walk thru each column from top to bottom
    foreach position \
	[lsort -integer -decreasing [array names REL_PLACE_$row_index]] {

      if {$position != "10000"} {
	# figure out column location based on max_bit and pitch
	set this_bit_slice [expr $pitch * ($max_bit - $position)]
	# find next available position
	set column [max $this_bit_slice $column]
      }

      foreach inst [set REL_PLACE_${row_index}($position)] {
	
# slow
#	setl {id cell_name bit type} $inst
	set id [lindex $inst 0]
	set cell_name [lindex $inst 1]
	set bit [lindex $inst 2]
	set type [lindex $inst 3]

	# The type in verilog is based on the verilog property and
	# may be different than the cell name.
	set instance_type [use_first VERILOG_TYPE($cell_name) cell_name]

	# TODO: should this be after bit_slice???
	# modify column if necessary based on dpc field
	# setup array with icon property values
	upvar #0 ${cur_s}_inst$id i_data
	set dpc [use_first i_data(_dpc)]
	if {[lsearch -exact $dpc "newbit"] != -1 || \
		[lsearch -exact $dpc "--"] != -1} {
	  # start at new pitch
	  set column [expr $pitch * round(ceil(1.0 * $column / $pitch))]
	}
	if {[regexp {(^| )(\+|\-)[0-9]+($| )} $dpc next]} {
	  # add/subtract space before this icon
	  # TODO: somehow if column goes negative deal with it for bbox
	  incr column $next
	}

	if {$cell_name == "spacer"} {
	  # very special case for spacer

	  # setup array with icon property values
	  upvar #0 ${cur_s}_inst$id i_data

	  # increment column
	  set delta_col [string trim [use_first i_data(_columns) '0]]
	  if {[regexp {(p|pi|pit|pitch|pitches)$} $delta_col]} {
	    # number is in terms of pitches
	    set no_pitches [lindex [split $delta_col p] 0]
	    if {[catch "expr $no_pitches"]} {
	      sue_warning "DPC WARNING: bad column value \"$delta_col\" in dpc spacer (\#$id).  Set to 0." DPC_REL
	      set no_pitches 0
	    }
	    set delta_col [expr int($no_pitches * $pitch)]
	  }
	  if {[catch "expr $delta_col"]} {
	    sue_warning "DPC WARNING: bad column value \"$delta_col\" in dpc spacer (\#$id).  Set to 0." DPC_REL
	    set delta_col 0
	  }

	  set column [expr $column + $delta_col]

	  # increment row
	  set delta_row [string trim [use_first i_data(_rows) '0]]
	  if {[regexp {(r|ro|row|rows)$} $delta_row]} {
	    # number is in terms of row
	    set no_rows [lindex [split $delta_row r] 0]
	    if {[catch "expr $no_rows"]} {
	      sue_warning "DPC WARNING: bad row value \"$delta_row\" in dpc spacer (\#$id).  Set to 0." DPC_REL
	      set no_rows 0
	    }
	    set delta_row [expr int($no_rows * $DPC(DEFAULT_ROW_HEIGHT))]
	  }
	  if {[catch "expr $delta_row"]} {
	    sue_warning "DPC WARNING: bad row value \"$delta_row\" in dpc spacer (\#$id).  Set to 0." DPC_REL
	    set delta_row 0
	  }

	  if {$delta_row > $max_delta_row} {
	    set max_delta_row $delta_row

	    # flip depends on how much spacing
	    if {[expr (int($delta_row) + $DPC(DEFAULT_ROW_HEIGHT)) \
		     % (2 * $DPC(DEFAULT_ROW_HEIGHT))] == 0} {
	      # flip if an odd number of pitches (not grids)
	      set max_flip 1
	    } else {
	      set max_flip 0
	    }
	  }

	  continue
	  # end of spacer stuff
	}

	if {![info exists DPC_SIZE($cell_name,file)] \
		&& ![info exists DPC_REL($instance_type)]} {
	  # look in the file <cell>.ports for cell size and port locations
	  lookup_size $cell_name $instance_type

	  # check that ports file has correct ports, warning otherwise
	  if {[llength [array names DPC_SIZE $instance_type,port,*]] != 0} {
	    # some ports are defined, see if all are.
	    catch {unset port_names}
	    foreach port_name [array names DPC_SIZE $instance_type,port,*] {
	      set port_names([lindex [split $port_name ,] 2]) 1
	    }

	    set missing ""
	    foreach term_id [$cur_c find withtag inst$id&term] {
	      foreach bit_name [bus_expand $TERMS($term_id,name)] {
		if {[info exists port_names($bit_name)]} {
		  # remove from list
		  unset port_names($bit_name)
		} else {
		  # not in list
		  lappend missing $bit_name
		}
	      }
	    }

	    if {[llength $missing] != 0} {
	      sue_warning "DPC WARNING: Missing ports in ports file for cell $cell_name (\#$id): [join $missing ,]." DPC_REL
	    }
	    if {[llength [array names port_names]] != 0} {
	      sue_warning "DPC WARNING: Extra ports in ports file for cell $cell_name (\#$id): [join [array names port_names] ,]." DPC_REL
	    }
	  }
	}

	if {![info exists DPC_SIZE($instance_type)]} {

	  # no size information for this gate, use the defaults
	  set DPC_SIZE($instance_type) \
	      "$DPC(DEFAULT_COLUMN_WIDTH) $DPC(DEFAULT_ROW_HEIGHT) 1"

	  # remember that we used this gate
	  if {[lsearch $unsized $instance_type] == -1} {
	    lappend unsized $instance_type
	  }
	}

	if {[lsearch -exact $dpc "def"] != -1 && \
		[info exists DPC_REL($instance_type)]} {
	  # hierarchical -- someone forgot the verilog property
	  sue_warning "DPC WARNING: can't have a def property on a hierarchical cell.  Must add a verilog property to icon \"$cell_name\" ($id).  Ignored." DPC_REL
	}

	# use the size data for this gate
#	setl {delta_col delta_row this_flip} $DPC_SIZE($instance_type)
	set delta_col [lindex $DPC_SIZE($instance_type) 0]
	set delta_row [lindex $DPC_SIZE($instance_type) 1]
	set this_flip [lindex $DPC_SIZE($instance_type) 2]
	set orient [lindex $DPC_SIZE($instance_type) 3]

	set save_orient $orient
	if {$orient != "" && [lsearch -exact $dpc "R90"] != -1} {
	  set orient $XFORM($orient,R90)
	}

	if {[regexp {E|W} $orient]} {
	  # rotated, flip delta_col and delta_row
	  set d_col $delta_row
	  set d_row $delta_col
	} else {
	  set d_col $delta_col
	  set d_row $delta_row
	}

	if {$bit_slice && $type == "" && \
		[expr $column + $d_col - $pitch] > $this_bit_slice && \
		$column != $this_bit_slice} {
	  # violates bit_slice, defer to next row
	  lappend slice($position) $inst

	  continue
	}

        if {[info exists DPC_REL($instance_type)]} {
	  # this is a hierarchical instance, hooray

	  # remember cell index for caching
	  if {[info exists DPC_CACHE($cell_name)]} {
	    set DPC_CACHE($schematic,$cell_name) $DPC_CACHE($cell_name)
	  }

	} else {
	  # base cell

	  # check if in nl from lef or already got this
	  if !{[info exists sizes($cell_name)]} {
	    set pins ""

	    set libcell $DPC(lib)/$cell_name
	    if {![catch {nl_get_libcell_size $libcell}]} {
	      # in nl, probably from lef, must save for cache
	      foreach pin [nl_get_libcell_pins -nosupply $libcell] {
		set loc [nl_get_libpin_location -grids $pin]
		lappend pins [list [nl_get_libpin_name $pin] \
			  $XFORM(nlport,[nl_get_libpin_direction $pin]) \
				  [lindex $loc 1] [lindex $loc 0]]
	      }

	    } else {
	      # save this size and port info for later and the cache

	      set delta_row2 [expr $delta_row / 2.0]
	      set delta_col2 [expr $delta_col / 2.0]

	      # cache data on port locations
	      foreach term_id [get_intersect_tag inst$id term] {
		set pin_names $TERMS($term_id,name)

		if {[info exists VERILOG_TYPE($cell_name,$pin_names)]} {
		  # translate based on verilog line
		  set pin_names $VERILOG_TYPE($cell_name,$pin_names)
		}

		foreach pin_name [bus_expand $pin_names] {
		  if {[info exists DPC_SIZE($instance_type,port,$pin_name)]} {
		    # use port location specified by .ports file
		    setl {dx dy} $DPC_SIZE($instance_type,port,$pin_name)
		    set DPC_DATA($instance_type,$pin_name) \
			[list $TERMS($term_id,dir) $dy $dx]
		    
		  } else {
		    # use center of cell as default
		    set DPC_DATA($instance_type,$pin_name) \
			[list $TERMS($term_id,dir) $delta_row2 $delta_col2]
		  }

		  # for the cache
		  lappend pins [concat $pin_name $DPC_DATA($instance_type,$pin_name)]
		}
	      }
	    }

	    lappend NETLIST_CACHE($cur_s,dpc_size) \
		[list $cell_name $instance_type $DPC_SIZE($instance_type) $pins]
	    set sizes($cell_name) 1
	  }
	}

        if {![info exists TERMS(bus,$id,$bit)]} {
	  set name $TERMS($id)
	} else {
	  set name $TERMS(bus,$id,$bit)
	}

	# save column/row/flip position and icon info
	lappend DPC_REL($cur_s) [list $row $column $flip $name $instance_type \
				     $d_row $d_col $dpc $orient]
	# increment column by width
	set column [expr $column + $d_col]

	# save maximum height of cell
	if {$d_row > $max_delta_row} {
	  set max_delta_row $d_row
	  set max_flip $this_flip
	}
      }
    }

    set max_column [max $max_column $column]

    if {$max_delta_row > 0} {
      set row [expr $row + $max_delta_row]
# TODO: By commenting out this next line, always uses default row height
#      set last_max_delta_row $max_delta_row
    } else {
      set row [expr $row + $last_max_delta_row]
    }

    set flip [expr ($flip + $max_flip) % 2]
  }

  # look for any preroutes
  set DPC_REL($schematic,preroutes) ""
  foreach id [$cur_c find withtag icon_preroute] {
    # save net, orient, info
    upvar #0 ${cur_s}_inst$id i_data

    # get the net name of this preroute
    set net $TERMS([$cur_c find withtag term&inst$id])

    # get other
    lappend DPC_REL($schematic,preroutes) \
	[list $net $XFORM(preroute,$i_data(orient)) $i_data(_layer) \
	     $i_data(_track) $i_data(_bit_increment)]
  }

  # save this size for higher level placements
  # NOTE: DPC_SIZE is column row while everything else is row column.
  set DPC_SIZE($cur_s) "$max_column $row $flip"

  if {$unsized != ""} {
    # added warnings for unsized icons
    sue_warning "DPC WARNING: No size data for gates: $unsized.  Using default width and height of $DPC(DEFAULT_COLUMN_WIDTH), $DPC(DEFAULT_ROW_HEIGHT) grids." DPC_REL
  }

  # save data in cache
  set NETLIST_CACHE($schematic,dpc) \
      [list $DPC_REL($schematic) \
	   $DPC_SIZE($schematic) $DPC_REL($schematic,warnings) \
	   $DPC_REL($schematic,preroutes)]

  # write out the netlist cache to a file if it is valid
  write_netlist_cache

  global CACHE_STATUS

  if {[info exists CACHE_STATUS] && \
	  [info exists NETLIST_CACHE($schematic,invalid)]} {
    set msg "($NETLIST_CACHE($schematic,invalid))"
    unset NETLIST_CACHE($schematic,invalid)

  } else {
    set msg ""
  }
  
  if {$NONEWLINE == 1} {
    puts "done $msg"
    set NONEWLINE 0
  } else {
    puts "    $schematic ... done $msg"
  }
}


# do the absolute placement.  Also propagate net names down thru hierarchy

proc dpc_absolute_place {schematic {prefix ""} {row 0} {col 0} {flip 0} {this_orient ""}} {

  global cur_s DPC_REL DPC_ABS DPC_AREA DPC XFORM
  global DPC_TIMING DPC_CAP DPC_SIZE NETLIST DPC_FROM_DEF DPC_PREROUTES

  # if flipped, reverse order of rows
  if {[lsearch $this_orient "flip"] != -1} {
    # flipped

    set this_flip 1
    set width [lindex $DPC_SIZE($schematic) 1]
    set block_flip 1
    set max_delta 0
    set max_flip 0
    set this_row 0
    foreach cell_info $DPC_REL($schematic) {
      set rel_row [lindex $cell_info 0]
      set delta_row [lindex $cell_info 5]

      set new_row [expr $width - $rel_row - $delta_row]
      lappend rel_flipped($new_row) [lreplace $cell_info 0 0 $new_row]

      # for flipping, figure out if every row in block gets flipped
      if {$this_row != $rel_row} {
	incr block_flip $max_flip
	set max_delta 0
	set max_flip 0
	set this_row $rel_row
      }

      if {$delta_row > $max_delta} {
	set max_delta $delta_row
	set max_flip [lindex $DPC_SIZE([lindex $cell_info 4]) 2]
      }
    }
    incr block_flip $max_flip

    # if last row flipped, must flip everything
    incr flip $block_flip
    set flip [expr $flip % 2]

    # put rows back together
    set dpc_rel ""
    foreach one [lsort -integer [array names rel_flipped]] {
      foreach line $rel_flipped($one) {
	lappend dpc_rel $line
      }
    }

  } else {
    # not flipped
    set this_flip 0
    set dpc_rel $DPC_REL($schematic)
  }

  if {[lsearch $this_orient "mirror"] != -1} {
    # mirrored
    set this_mirror 1
    set this_height [lindex $DPC_SIZE($schematic) 0]

    set dpc_rel2 ""
    foreach cell_info $dpc_rel {
      set rel_col [lindex $cell_info 1]
      set delta_col [lindex $cell_info 6]

      set new_col [expr $this_height - $rel_col - $delta_col]
      lappend dpc_rel2 [lreplace $cell_info 1 1 $new_col]
    }
    set dpc_rel $dpc_rel2

  } else {
    # not mirrored
    set this_mirror 0
  } 

  # walk through each cell and place
  foreach cell_info $dpc_rel {
# slow
#    setl {rel_row rel_col rel_flip name type delta_row delta_col mirror orient} $cell_info
    set rel_row [lindex $cell_info 0]
    set rel_col [lindex $cell_info 1]
    set rel_flip [lindex $cell_info 2]
    set name [lindex $cell_info 3]
    set type [lindex $cell_info 4]
    set delta_row [lindex $cell_info 5]
    set delta_col [lindex $cell_info 6]
    set mirror [lindex $cell_info 7]
    set orient [lindex $cell_info 8]

    set abs_row [expr $row + $rel_row] 
    set abs_col [expr $col + $rel_col]
    set abs_flip [expr ($flip + $rel_flip) % 2]
#puts "+++ $type $flip + $rel_flip -> $abs_flip"

    # is this a hierarchical cell?
    if {[info exists DPC_REL($type)]} {
      if {$this_flip} {
	# need to flip or unflip descendents
	if {[set pos [lsearch $mirror "flip"]] != -1} {
	  # unflip descendents
	  set mirror [lreplace $mirror $pos $pos]

	} else {
	  # flip descendents
	  lappend mirror flip
	}

	# also need to propagate flip downwards
	incr abs_flip 1
	incr abs_flip [lindex $DPC_SIZE($type) 2]
      }	

      if {$this_mirror} {
	# need to flip or unflip descendents
	if {[set pos [lsearch $mirror "mirror"]] != -1} {
	  # unmirror descendents
	  set mirror [lreplace $mirror $pos $pos]

	} else {
	  # mirror descendents
	  lappend mirror mirror
	}
      }	

      set new_prefix "$prefix${name}/"

      # hierarchical, recurse
      check_interrupt
      dpc_absolute_place $type $new_prefix $abs_row $abs_col $abs_flip $mirror

      # save this position/orientation
      if {[set pos [lsearch -exact $mirror "flip"]] != -1} {
	set orient [lindex $DPC(FLIP) 1]  
      } else {
	set orient [lindex $DPC(FLIP) 0]  
      }
      if {[set pos [lsearch -exact $mirror "mirror"]] != -1} {
	set orient $XFORM($orient,mirror)
      }

      set DPC_ABS($prefix$name) \
	  [list HIER $type $abs_row $abs_col $delta_row $delta_col $orient]

    } else {
      # base cell, place it
      if {$this_flip} {
	# need to flip or unflip this
	if {[set pos [lsearch -exact $mirror "flip"]] != -1} {
	  # unflip descendents
	  set mirror [lreplace $mirror $pos $pos]

	} else {
	  # flip descendents
	  lappend mirror flip
	}
      }
      if {$this_mirror} {
	# need to mirror or unmirror this
	if {[set pos [lsearch -exact $mirror "mirror"]] != -1} {
	  # unmirror descendents
	  set mirror [lreplace $mirror $pos $pos]

	} else {
	  # mirror descendents
	  lappend mirror mirror
	}
      }


      if {[set pos [lsearch $mirror "def*"]] != -1} {
#AAA
	# neither a base cell nor a hier cell but a previously
	# placed cell in def format
	# Remove def= from string
	lappend DPC_FROM_DEF($type) \
	    [list $prefix/$name [string range [lindex $mirror $pos] 4 end]]
      }

      place_instance $prefix$name $type $abs_flip $abs_row $abs_col \
	  $mirror $orient

      # remember areas for cell utilization
      if {[info exists DPC_AREA($type)]} {
	incr DPC_AREA($type,count)
      } else {
	set DPC_AREA($type,count) 1
	set DPC_AREA($type) [expr $delta_row * $delta_col]
      }

      # count the cells placed
      incr DPC(CELLS)

      incr DPC(COUNT)
      if {$DPC(COUNT) == 10000} {
	puts "    ...$DPC(CELLS)..."
	set DPC(COUNT) 0
      }
    }
  }

  # remember preroutes associated with net
  foreach preroute $DPC_REL($schematic,preroutes) {
    set inc [lindex $preroute 4]
    foreach bit [cbus_expand [lindex $preroute 0]] {
      set net $prefix$bit
      # Note: will later change net to be highest in hierarchy
      lappend DPC_PREROUTES($net) [lrange $preroute 1 end]
      set preroute [lreplace $preroute 3 3 [expr [lindex $preroute 3] + $inc]]
    }
  }
}


# Returns all the net names that are equivalent, including through assigns.
# Includes the original net in the list.
# If optional highest is true (1), returns only highest net in hierarchy.

proc get_net_equiv {net {highest 0}} {

  # must get all the pins and then find the nets from there
  if {[catch {nl_get_net_nets -hierarchy -noassign $net} nets]} {
    # this is not a valid net
    return $net
  }

  if {$highest} {
    # find the highest -- fewest /
    set min_depth 100000
    foreach net $nets {
      set depth [llength [split $net /]]
      if {$depth < $min_depth} {
	set hnet $net
	set min_depth $depth
      }
    }
    return $hnet

  } else {
    # return all equivalent
    return $nets
  }
}


# create the placement line for a base cell.

# example placement line in def format
# - TEST1 TEST + PLACED ( 0 14000 ) N ;

proc place_instance {instance_name instance_type flip row col mirror orient} {

  global DPC DPC_SIZE XFORM

  if {[lsearch $mirror mirror] == -1} {
    # use the default placement (either PLACE or FIXED)
    set place $DPC(PLACE)
  } else {
    # don't let the router mirror this cell
    set place FIXED
  }

  if {$orient != ""} {
    # using orientation from ports file
    set place FIXED

    # can only flip special cells with orientations -- others follow
    # row flipping
    if {[lsearch $mirror flip] != -1} {
      # flip orientation
      set orient $XFORM($orient,flip)
    }

  } else {
    set orient [lindex $DPC(FLIP) $flip]  
  }

  if {[lsearch $mirror mirror] != -1} {
    # mirror orientation
    set orient $XFORM($orient,mirror)
  }

  # stuff component into nl
  nl_set_cell_location -type $place $instance_name \
      [expr round($col * $DPC(xscale))] [expr round($row * $DPC(yscale))]
  nl_set_cell_orientation $instance_name $orient
}


# expands buses into bit positions using the dpc properties and names

proc dpc_compute_bit_positions {dpc name id type row} {

  upvar max_bit max_bit
  upvar max_row max_row

  set orig_name $name

  # look for an override of the name in the dpc
  if {[regexp {(^| )(\[[0-9:-]+\])( |$)} $dpc tmp tmp2 size]} {  
    # got one, replace name
    set name [lindex [split $name \[] 0]$size
  }

  # look for override of the bit positions in the name
  if {![regexp {(\$b)|([pr][^ ]*=)} $dpc]} {
    # nothing appropriate, just use the name
    setl {min max} [lsort -integer [bus_range $name]]

    if {$max == ""} {
      sue_warning "DPC WARNING: bad name \"$name\" in instance \"$orig_name\".  Ignored." DPC_REL
      return 0
    }
    
    upvar REL_POS REL_POS

    # place the icons in relative order based on name
    for {set index $max} {$index >= $min} {incr index -1} {
      lappend REL_POS($index) "$id $type $index"
    }

    set max_bit [max $max_bit $max]

    return $min
  }

  # search for any row specifiers
  foreach item $dpc {
    if {[regexp {r(\[[0-9]+(:[0-9]+)?\])?=(.*)} $item match range tmp exp]} {
      # found a row expression
      if {$range == ""} {
	# applies to all
	setl {min max} [lsort -integer [bus_range $name]]
      } else {
	# only applies to these bits
	setl {min max} [lsort -integer [bus_range $range]]
      }

      # determine row offset based on expression.  Note $b is bit number
      for {set b $max} {$b >= $min} {incr b -1} {
	if {[catch "expr $exp" value]} {
	  # error, just use the index
	  if {![info exists trace($orig_name)]} {
	    sue_warning "DPC WARNING: bad expression \"$exp\" in dpc property in instance \"$orig_name\".  Ignored." DPC_REL
	    set trace($orig_name) 1
	  }
	} else {
	  # don't allow negative numbers or non-integers here
	  set row_offset($b) [expr int([max 0 $value])]
	}
      }
    }
  }

  # search through expressions, separated by spaces from left to right
  # TODO: check for duplicates
  foreach item $dpc {
    set range ""
    if {[regexp {p(\[[0-9]+(:[0-9]+)?\])?=(.*)} $item match range tmp exp] || \
	    [regexp {^([^r]*\$b.*)} $item match exp]} {
      # found an expression
      if {$range == ""} {
	# applies to all
	setl {min max} [lsort -integer [bus_range $name]]
      } else {
	# only applies to these bits
	setl {min max} [lsort -integer [bus_range $range]]
      }

      # determine bit positions based on expression.  Note $b is bit number
      for {set b $max} {$b >= $min} {incr b -1} {
	if {[catch "expr $exp" value]} {
	  # error, just use the index
	  if {![info exists trace($orig_name)]} {
	    sue_warning "DPC WARNING: bad expression \"$exp\" in dpc property in instance \"$orig_name\".  Ignored." DPC_REL
	    set trace($orig_name) 1
	  }
	  set bit_pos($b) $b
	} else {
	  set bit_pos($b) $value
	}
      }
    }
  }

  # now place the instances
  setl {min max} [lsort -integer [bus_range $name]]

  set min_bit 10000

  for {set index $max} {$index >= $min} {incr index -1} {
    set position [use_first bit_pos($index) index]
    set this_row [expr [use_first row_offset($index) '0] + $row]
    upvar REL_PLACE_$this_row REL_POS
    lappend REL_POS($position) "$id $type $index"

    set max_row [max $this_row $max_row]

    set min_bit [min $position $min_bit]
    set max_bit [max $position $max_bit]
  }

  # TODO: probably need to save a min bit position for each row
  return $min_bit
}


# order id's by position on canvas

proc order_icons {} {

  global cur_c cur_s scale DPC SUE NETLIST_PROPS

  set ids ""
  $cur_c delete tmp

  set aligners ""
  set data_list ""

  # get bbox coords of all objects (ignore text and unplaced)
  foreach id [$cur_c find withtag origin] {
    upvar #0 ${cur_s}_inst$id i_data
    # the type is really the instance name
    set type $i_data(type)
    upvar #0 icon_$type g_data
    set real_type [use_first g_data(generator) type]
    if {[lsearch [use_first DPC(UNPLACED)] $real_type] != -1} {
      lappend unplace_ids $id
      continue
    }
    if {$type == $cur_s} {
      # recursive comment, ignore
      continue
    }

    if {[info exists cache($type)]} {
      # already cached this type

    } elseif {$type == "spacer" || [string first row_spanner $type] == 0 \
		  || [string first spanner $type] == 0} {
      # always keep these
      set cache($type) no_skip

    } else {
      # if this has a schematic, keep it
      set genname [lindex [split_filename [use_first g_data(generator)]] 1]
      if {[info exists SUE($type)] || \
	      [info commands SCHEMATIC_$type] != "" || \
	      [info commands SCHEMATIC_$genname] != ""} {
	# schematic, don't skip
	# NOTE: if there is nothing placable in this schematic
	# then it needs to be in the DPC(UNPLACED) list to work correctly
	set cache($type) no_skip
      } else {
	# no schematic, if no active property, toss is
	set cache($type) skip
	foreach prop $NETLIST_PROPS {
	  if {[use_first g_data(_$prop)] != ""} {
	    set cache($type) no_skip
	    break
	  }
	}
      }
    }

    if {$cache($type) == "skip"} {
      continue
    }

    # get the bbox of the icon
    # TODO: this could be cached -- needs orientation
    $cur_c addtag tmp withtag inst$id
    $cur_c dtag scaletext tmp
    setl {x1 y1 x2 y2} [round_list [$cur_c bbox tmp]]
    $cur_c dtag tmp

    # the bbox command tends to overestimate by 2 which is bad
    # when zoomed way out (serious hack).
    incr x1 2
    incr x2 -2

    # hack for lsort brokenness
    set sort_num [expr 500000 + $x1]
    lappend data_list "$sort_num $x1 $y1 $x2 $y2 $id"
  }

  # sort icons
  set data_list [lsort $data_list]

  while {$data_list != ""} {
    lappend ids [compute_first_region]
  }

  return $ids
}


proc compute_first_region {} {

  global cur_s scale

  # hack for dynamic scoping
  upvar data_list data_list
  upvar aligners aligners

  setl {bogus xmin y1 xmax y2 id} [lindex $data_list 0]
  set index 0

  foreach list $data_list {
    setl {bogus x1 y1 x2 y2 id} $list

    if {$x1 > $xmax} {
      # new range
      break

    } else {
      set xmax [max $x2 $xmax]
      incr index

      # remember y coords and ids
      lappend column($y1) $id
      if {[lindex $column($y1) 1] == ""} {
	lappend columns $y1
      }
    }
  }

  # this might be too slow an operation
  set data_list [lrange $data_list $index end]

#  if {$data_list != "" && [expr $x1 - (2 * $scale)] < $xmax} {
#    upvar #0 ${cur_s}_inst$id i_data
#    # the type is the really the instance name
#    set type $i_data(type)

#    sue_warning "DPC WARNING: icon $type ($id) is too close to previous row in cell \"$cur_s\".  Might cause problems."
#  }

  foreach pair $aligners {
    setl {id y1} $pair

    lappend column($y1) $id
    if {[lindex $column($y1) 1] == ""} {
      lappend columns $y1
    }
  }

  set ids ""
  foreach num [lsort -real $columns] {
    foreach id $column($num) {
      lappend ids $id
    }
  }

  return $ids
}


# create the DEF placement file for silicone ensemble

proc create_placement_file {row col} {

  global NETLIST DPC PLACEMENT_DATA

  upvar #0 SUE_$NETLIST(root) data
  set filename "$NETLIST(dir)$NETLIST(root).place.def"

  setl {xhalo yhalo} $DPC(HALO)
  if {$yhalo == ""} {
    set yhalo $xhalo
  }

  set maxx [expr round(($col+$xhalo) * $DPC(xscale))]
  set minx [expr round((0-$xhalo) * $DPC(xscale))]
  set maxy [expr round(($row+$yhalo) * $DPC(yscale))]
  set miny [expr round((0-$yhalo) * $DPC(yscale))]

  nl_set_distance_units MICRONS 1000

  # so a - doesn't look like a switch
  nl_set_die_area -- "$minx $miny $maxx $maxy"

  setl {xoffset yoffset} $DPC(TRACK_OFFSET)
  if {$yoffset == ""} {
    set yoffset $xoffset
  }

  foreach track $DPC(TRACKS) {
    if {[lindex $track 0] == "Y"} {
      set num [expr $row + 2*$yhalo]
      set grid_units [expr round($DPC(yscale))]
      set offset [expr int($grid_units * ($yoffset - $yhalo))]

    } else {
      set num [expr $col + 2*$xhalo]
      set grid_units [expr round($DPC(xscale))]
      set offset [expr int($grid_units * ($xoffset - $xhalo))]
    }

    nl_add_[string tolower [lindex $track 0]]_tracks -- $offset \
	$num $grid_units [lrange $track 1 end]
  }

  # what to put in the def file
  set what "-header -components"
  if {$DPC(PINS)} {
    lappend what -pins
  }

  if {[llength [use_first PLACEMENT_DATA($NETLIST(root),preroutes)]] != 0} {
    lappend what -net_routes
  }

  if {[catch "nl_write_def $what $filename" msg]} {
    # problem
    puts "DPC ERROR: $msg"
    return
  } 

  puts "Wrote placement file to $filename"
}


# if in a schematic, run show placement (if not up-to-date) on toplevel
# cell.  Otherwise just go to toplevel cell placement.  If in a
# placement file, goto toplevel cell schematic (eventually could go
# to actual place you toggled from which may be in the hierarchy)

proc toggle_show_placement {} {

  global cur_s SUE HIERARCHY PLACEMENT_DATA _SAVE_HIERARCHY_ NETLIST

  if {[is_placement $cur_s]} {
    # we are in a placement file, goto schematic
    regsub "_placement$" $cur_s "" schematic
    if {[info exists SUE($schematic)]} {
      if {[use_first _SAVE_HIERARCHY_] == ""} {
	# got here by illicit means
	set HIERARCHY ""
	goto_schematic $schematic
      } else {
	setl {schem HIERARCHY} $_SAVE_HIERARCHY_
	goto_schematic $schem
      }

    } else {
      sue_warning "Aborting, cell \"$schematic\" doesn't exist."
      set _SAVE_HIERARCHY_ ""
      return 0
    }

  } else {
    # we are in a schematic

    # save hierarchy so we can return here
    set _SAVE_HIERARCHY_ [list $cur_s $HIERARCHY]

    # get toplevel schematic name
    if {![info exists NETLIST(root)]} {
      sue_error "Aborting, must dpc netlist first before showing placement."
      sue_error flush
      return 0
    }

    set topcell $NETLIST(root)

    upvar #0 SUE_${topcell}_placement data
    if {[info exists data] && [use_first data(_UPDATE_ME_)] == ""} {
      # just goto the placement file
      goto_schematic ${topcell}_placement

    } else {
      # do a show_placement from the topcell
      if {[use_first PLACEMENT_DATA($topcell)] == ""} {
	# ignore this command
	return 0
      }

      goto_schematic $topcell
      show_placement

      # make up-to-date
      catch {unset data(_UPDATE_ME_)}
    }
  }

  return 1
}


# show the placement for the current schematic in a different canvas

proc show_placement {{name ""}} {

  global cur_c cur_s DPC PLACEMENT_DATA SUE auto_index CONGESTION NETLIST
  global XFORM

  set setup_only 1
  if {$name == ""} {
    set setup_only 0
    set name $cur_s

    if {[use_first PLACEMENT_DATA($name)] == ""} {
      puts "Aborting show placement. Must run dpc first on $cur_s."
      return
    }

    busy

    # generate placement data now
    if {[use_first DPC(placement)] != "flat"} {
      # hierarchical placement
      set PLACEMENT_DATA($name) [dpc_show_place $name]

      if {$PLACEMENT_DATA($name) == ""} {
	# can't show
	ready
	return
      }

    } else {
      # flat placement
      set PLACEMENT_DATA($name) ""
      dpc_flat_show_place $name
    }

    # reset congestion array
    catch {unset CONGESTION}
  }

  set placement_name "${name}_placement"

  upvar #0 SUE_$name data
  if {![info exists data(dir)]} {
    # get form auto_index
    set dir [file dirname [lindex $auto_index(ICON_$name) 1]]/
    
  } else {
    set dir $data(dir)
  }

  if {![info exists SUE($placement_name)]} {
    # otherwise we will load this when we do goto_schematic
    catch {rename SCHEMATIC_$placement_name ""}
    catch {unset auto_index(SCHEMATIC_$placement_name)}
  }
  goto_schematic $placement_name

  if {$cur_s == $placement_name} {
    puts "Creating replacement of cell \"$cur_s\" ..."

    # schematic already exists, just erase everything in it
    foreach id [$cur_c find withtag origin] {
      # delete old icon and lose the old data structure
      $cur_c delete inst$id
      global ${cur_s}_inst$id
      catch {unset ${cur_s}_inst$id}
    }
     
    # delete anything else that might be around
    $cur_c delete all

    scale_canvas 10

    global SUE_$placement_name GRID_SPACING
    if {[use_first SUE_${placement_name}(grid)] == 1} {
      # grid was on before, turn it on again
      make_grid $GRID_SPACING
    }

  } else {
    puts "Creating new placement of cell \"$cur_s\" ..."

    # make a new schematic
    make_new_schematic $dir$placement_name
  }

  if {$setup_only} {
    return
  }

  # put a nice box around the placement and put a text label nearby 
  setl {xhalo yhalo} $DPC(HALO)
  if {$yhalo == ""} {
    set yhalo $xhalo
  }

  setl {rows cols} $PLACEMENT_DATA($name,size) 

  set maxx [expr 10 * ($cols+$xhalo)]
  set minx [expr 10 * (0-$xhalo)]
  set maxy [expr 10 * ($rows+$yhalo)]
  set miny [expr 10 * (0-$yhalo)]
  make_line $miny $minx $maxy $minx $maxy $maxx $miny $maxx $miny $minx
  make_text -origin "0 [expr $minx - 40]" -text "$name placement" -size large

  foreach command $PLACEMENT_DATA($name) {
    if {[catch $command msg]} {
      sue_error "$msg in command \"$command\""
    }
  }

  # set up the TERMS array for this placement file for select by name
  upvar #0 TERMS_$cur_s TERMS
  catch {unset TERMS}
  upvar #0 RTERMS_$cur_s RTERMS
  catch {unset RTERMS}
  foreach id [$cur_c find withtag origin] {
    upvar #0 ${cur_s}_inst${id} i_data
    if {[info exists i_data(_instance)]} {
      set TERMS($id) $i_data(_instance)
    }
  }

  # add any preroutes
  if {$name == $NETLIST(root) && \
	  [info exists PLACEMENT_DATA($name,preroutes)]} {
    foreach preroute $PLACEMENT_DATA($name,preroutes) {
      set wire_name [lrange $preroute 0 1]
      regsub -all {\{|\}} $wire_name "" wire_name

      set id [eval make_wire [lrange $preroute 3 6]]
      set TERMS($id) [lindex $wire_name 0]
      if {[lindex $preroute 2] == "H"} {
	set orient R0
      } else {
	set orient R90
      }
      set id [make name_net_s -orient $orient -name $wire_name \
		  -origin [lrange $preroute 3 4]]
      set TERMS($id) [lindex $wire_name 0]
    }
  }

  # add any pins
  if {$name == $NETLIST(root) && $DPC(PINS)} {
    foreach pin [nl_find_ports *] {

      set orient [nl_get_port_orientation $pin]
      if {$orient == "none"} {
	# not defined, ignore
	continue
      }

      setl {y x} [nl_get_port_location $pin]

      switch [nl_get_port_direction $pin] {
	in { set type input }
	out { set type output }
	default { set type inout }
      }

      set orient $XFORM(undef,$orient)

      set id [make $type -name $pin -orient $orient \
		  -origin [list [expr $x * 10/$DPC(yscale)] \
			        [expr $y * 10/$DPC(xscale)]]]
      set TERMS($id) $pin
    }
  }

  # make this modified
  # this is really a temporary buffer so don't make modified
#  is_modified

  zoom_to_fit

  sue_error flush

  puts "done."

  ready
}


# expand selected hierarchical cells one level

proc dpc_expand_hier_place {} {

  global cur_s cur_c scale DPC_ABS
     
  busy

  # need to add stuff at scale 10
  set save_scale $scale
  scale_canvas 10

  set ids ""

  foreach id [get_intersect_tag selected origin] {

    if {![is_tagged $id icon__place_*]} {
      # not a component
      continue
    }

    # setup array with icon property values
    upvar #0 ${cur_s}_inst$id i_data

    # I know, this seems screwy
    set name $i_data(_instance)
    set type $i_data(_name)

    if {![info exists DPC_ABS($name)]} {
      # can't expand non-hier cells
      continue
    }

    # delete this cell
    $cur_c delete inst$id

    # now add subcells
    foreach command [dpc_show_place $type $name/] {
      if {[catch $command msg]} {
	sue_error "$msg in command \"$command\""
      } else {
	lappend ids $msg
      }
    }
  }

  select_ids $ids add no_display

  # scale us back to where we were
  scale_canvas $save_scale

  # set up the TERMS array for this placement file for select by name
  upvar #0 TERMS_$cur_s TERMS
  catch {unset TERMS}
  upvar #0 RTERMS_$cur_s RTERMS
  catch {unset RTERMS}
  foreach id [$cur_c find withtag origin] {
    upvar #0 ${cur_s}_inst${id} i_data
    if {[info exists i_data(_instance)]} {
      set TERMS($id) $i_data(_instance)
    }
  }

  sue_error flush

  ready
}


# unexpand selected hierarchical cells one level

proc dpc_unexpand_hier_place {} {

  global cur_s cur_c scale DPC_ABS
     
  busy

  # need to add stuff at scale 10
  set save_scale $scale
  scale_canvas 10

  set ids ""

  upvar #0 RTERMS_$cur_s RTERMS

  foreach id [get_intersect_tag selected origin] {

    # setup array with icon property values
    upvar #0 ${cur_s}_inst$id i_data

    # I know, this seems screwy
    set name $i_data(_instance)

    # find path of hierarchical cell if there is one
    if {[set pos [string last / $name]] == -1} {
      # not a subcell, skip
      continue
    }

    set hier_name [string range $name 0 [incr pos -1]]
    if {[info exists trace($hier_name)]} {
      # already done this one
      continue
    }
    set trace($hier_name) 1

    # delete all subcells

    # to insure that the RTERMS array is setup
    find_by_name ""

    foreach cell [array names RTERMS $hier_name/*] {
      $cur_c delete inst$RTERMS($cell)
    }
  }

  # now add the hier cell, checking that it isn't a subcell of something
  # else that has been unexpanded at a higher level
  foreach hier_name [array names trace] {
    foreach skip [array names trace $hier_name/*] {
      unset trace($skip)
    }
  }

  foreach hier_name [array names trace] {
    foreach command [dpc_show_place "" "" $hier_name] {
      if {[catch $command msg]} {
	sue_error "$msg in command \"$command\""
      } else {
	lappend ids $msg
      }
    }
  }

  select_ids $ids add no_display

  # scale us back to where we were
  scale_canvas $save_scale

  # set up the TERMS array for this placement file for select by name
  upvar #0 TERMS_$cur_s TERMS
  catch {unset TERMS}
  catch {unset RTERMS}
  foreach id [$cur_c find withtag origin] {
    upvar #0 ${cur_s}_inst${id} i_data
    if {[info exists i_data(_instance)]} {
      set TERMS($id) $i_data(_instance)
    }
  }

  sue_error flush

  ready
}


# create placement info without looking into hierarchy

proc dpc_show_place {schematic {prefix ""} {hier_cell ""}} {

  global DPC_ABS DPC DPC_SIZE

  if {$hier_cell == ""} {
    # get cells for just this level of hierarchy
    if {[catch {nl_list_cells -noassign $schematic} cells]} {
      warning "Aborting, can't show placement for cell \"$schematic\".  Must rerun DPC to see placement."
      return ""
    }

  } else {
    # put in this hierarchical cell only
    set cells $hier_cell
  }

  set placement ""
  foreach rel_cell $cells {

    set cell $prefix$rel_cell
    set type [nl_get_reference_name [nl_get_cell_reference $cell]]
#    set type [nl_get_cell_reference $cell]

    if {[info exists DPC_ABS($cell)]} {
      # hierarchical cell

      # get absolute data on this
      setl {kind type abs_row abs_col delta_row delta_col orient} \
	  $DPC_ABS($cell)

      # setup placement data
      set place_name _place_${delta_row}_${delta_col}_H

      if {![info exists trace($place_name)]} {
	lappend placement \
	    "generate place $place_name -width $delta_row -height $delta_col -hier 1"
	set trace($place_name) 1
      }

    } else {
      # base cell

      # get absolute data from nl
      set orient [nl_get_cell_orientation $cell]
      setl {abs_col abs_row} [nl_get_cell_location $cell]

      if {$abs_row == ""} {
	# no location, flatten
#AAA
	foreach line [dpc_show_place $type $cell/] {
	  lappend placement $line
	}
	continue
      }

      set abs_col [expr $abs_col / $DPC(xscale)]
      set abs_row [expr $abs_row / $DPC(yscale)]

      setl {delta_col delta_row} $DPC_SIZE($type)

      # setup placement data
      set place_name _place_${delta_row}_$delta_col

      if {![info exists trace($place_name)]} {
	lappend placement \
	    "generate place $place_name -width $delta_row -height $delta_col"
	set trace($place_name) 1
      }
    }

    # determine placement orientation
    switch $orient {
      N {
	set position "-origin [list [list [expr $abs_row * 10] [expr $abs_col * 10]]]"
      }
      FS {
	set position "-origin [list [list [expr ($abs_row + $delta_row) * 10] [expr $abs_col * 10]]] -orient RX"
      }
      FN {
	set position "-origin [list [list [expr $abs_row * 10] [expr ($abs_col + $delta_col) * 10]]] -orient RY"
      }
      S {
	set position "-origin [list [list [expr ($abs_row + $delta_row) * 10] [expr ($abs_col + $delta_col) * 10]]] -orient RXY"
      }
      E {
	set position "-origin [list [list [expr ($abs_row + $delta_col) * 10] [expr $abs_col * 10]]] -orient R90"
      }
      FE {
	set position "-origin [list [list [expr $abs_row * 10] [expr $abs_col * 10]]] -orient R90X"
      }
      W {
	set position "-origin [list [list [expr $abs_row * 10] [expr ($abs_col + $delta_row) * 10]]] -orient R270"
      }
      FW {
	set position "-origin [list [list [expr ($abs_row + $delta_col) * 10] [expr ($abs_col + $delta_row) * 10]]] -orient R90Y"
      }
    }

    lappend placement \
	"make $place_name -name $type -instance \{$cell\} $position"
  }

  return $placement
}


# Create the flat placement file for SUE placement

proc dpc_flat_show_place {schematic} {
  
  global PLACEMENT_DATA DPC_SIZE DPC

  # walk through each placed cell
  foreach cell [nl_list_cells -recursive -library] {

#    set type [nl_get_reference_name [nl_get_cell_reference $cell]]
    set type [nl_get_cell_reference $cell]

    set orient [nl_get_cell_orientation $cell]
    setl {abs_col abs_row} [nl_get_cell_location $cell]

    set abs_col [expr $abs_col / $DPC(xscale)]
    set abs_row [expr $abs_row / $DPC(yscale)]

    setl {delta_col delta_row} $DPC_SIZE($type)

    # setup placement data
    set place_name _place_${delta_row}_$delta_col

    if {![info exists trace($place_name)]} {
      lappend PLACEMENT_DATA($schematic) \
	  "generate place $place_name -width $delta_row -height $delta_col"
      set trace($place_name) 1
    }

    # determine placement orientation
    switch $orient {
      N {
	set position "-origin [list [list [expr $abs_row * 10] [expr $abs_col * 10]]]"
      }
      FS {
	set position "-origin [list [list [expr ($abs_row + $delta_row) * 10] [expr $abs_col * 10]]] -orient RX"
      }
      FN {
	set position "-origin [list [list [expr $abs_row * 10] [expr ($abs_col + $delta_col) * 10]]] -orient RY"
      }
      S {
	set position "-origin [list [list [expr ($abs_row + $delta_row) * 10] [expr ($abs_col + $delta_col) * 10]]] -orient RXY"
      }
    }

    lappend PLACEMENT_DATA($schematic) \
	"make $place_name -name $type -instance \{$cell\} $position"
  }
}


proc dpc_change_parasitic_mode {} {

  global DPC DPC_TIMING

  set title "DPC Parasitics"
  set message "Estimated Parasitic Control"

  set prop_list ""
  lappend prop_list [list "DSPF (RC)" DPC(dspf) binary -help \
			 "If DSPF not selected, DPC creates a capacitance wire load estimate for each net, otherwise it creates an RC network.  NOTE: must using 2000.11 release of primetime."]
  lappend prop_list [list "min RC" DPC(MIN_RC) -entry -help \
			 "If DSPF is selected and \"min RC\" is greater than zero (0), only nets with RC time constants greater than the minimum RC value given will get complete RC networks.  The others will have capacitances only since the R's are unimportant."]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  # clean this up so the user won't get the wrong cap file default
  foreach one [array names DPC_TIMING ->parasitic_file,*] {
    unset DPC_TIMING($one)
  }

  if {$DPC(dspf)} {
    puts "Set to create a DSPF file (DPC(dspf)=1) with RC's for all nets with wire delays greater than $DPC(MIN_RC) (DPC(MIN_RC)=$DPC(MIN_RC))."
  } else {
    puts "Set to create a capacitance-only file (DPC(dspf)=0)."
  }
}


proc dpc_place_pins {} {

  global cur_c cur_s NETLIST XFORM DPC_SIZE DPC XFORM

  if {!$DPC(PINS)} {
    # turned off
    return
  }

  puts "Placing pins ..."

  # make the pin size
  set pin_size [list [expr round([lindex $DPC(PIN_SIZE) 0] * $DPC(xscale))] \
		    [expr round([lindex $DPC(PIN_SIZE) 1] * $DPC(yscale))] \
		    [expr round([lindex $DPC(PIN_SIZE) 2] * $DPC(xscale))] \
		    [expr round([lindex $DPC(PIN_SIZE) 3] * $DPC(yscale))]]

  # get bbox
  setl {cols rows} $DPC_SIZE($cur_s)

  setl {xoffset yoffset} $DPC(TRACK_OFFSET)
  if {$yoffset == ""} {
    set yoffset $xoffset
  }

  set pitch [use_first PREROUTE(row_pitch) DPC(PITCH)]
  set row [use_first PREROUTE(column_pitch) DPC(DEFAULT_ROW_HEIGHT)]

  setl {xhalo yhalo} $DPC(HALO)
  if {$yhalo == ""} {
    set yhalo $xhalo
  }

  set maxx [expr $cols+$xhalo]
  set minx [expr 0-$xhalo]
  set maxy [expr $rows+$yhalo]
  set miny [expr 0-$yhalo]

  # get all I/O's
  foreach id [concat [$cur_c find withtag origin&icon_input] \
		  [$cur_c find withtag origin&icon_output] \
		  [$cur_c find withtag origin&icon_inout]] {
    upvar #0 ${cur_s}_inst$id i_data
    # the type is really the instance name
    set type $i_data(type)

    if {$type == "input"} {
      set i I
    } else {
      set i O
    }

    # get the name and orientation
    set side $XFORM(pin,$i,$i_data(orient))

    if {[use_first i_data(_name)] == ""} {
      # unnamed, skip
      continue
    }

    foreach io [bus_expand [lookup_name $i_data(_name)]] {

      if {[info exists placed_ios($io)]} {
	# already got this one
	continue
      }
      set placed_ios($io) 1

      # find a home for
      if {[catch {nl_get_net_pins -recursive -noassign $io} pins]} {
	# this is not a valid net
	return ""
      }

      set pairs ""
      # get the coords of each non I/O pin
      foreach pin $pins {
	set owner [nl_get_pin_owner $pin]

	if {[nl_object_type $owner] == "port"} {
	  # top level I/O, ignore
	  continue
	}

	lappend pairs [_pin_location $pin]
      }

      if {[llength $pairs] == 0} {
	puts "DPC WARNING: No net associated with pin $io.  Not placed."
	continue
      }

      set xdir 1
      set ydir 1

      # find closest pin to side (round to row) and use that
      # for coord.  If multiple, use average.
      switch $side {
	w {
	  set min 1000000
	  set avg ""

	  foreach pair $pairs {
	    setl {x y} $pair
	
	    set x [expr int(round($x/$row)*$row)]

	    if {$x == $min} {
	      lappend avg $y
	      continue
	    }

	    if {$x < $min} {
	      set min $x
	      set avg $y
	    }
	  }

	  set yloc 0
	  foreach y $avg {
	    set yloc [expr $yloc + $y]
	  }

	  set xt $miny
	  set yt [expr $yloc/[llength $avg]]
	}

	e {
	  set max -1000000
	  set avg ""
	  foreach pair $pairs {
	    setl {x y} $pair
	
	    set x [expr int(round($x/$row)*$row)]

	    if {$x == $max} {
	      lappend avg $y
	      continue
	    }

	    if {$x > $max} {
	      set max $x
	      set avg $y
	    }
	  }

	  set yloc 0
	  foreach y $avg {
	    set yloc [expr $yloc + $y]
	  }

	  set xt $maxy
	  set yt [expr $yloc/[llength $avg]]
	  set xdir -1
	}

	n {
	  set min 1000000
	  set avg ""
	  foreach pair $pairs {
	    setl {y x} $pair
	
	    set x [expr int(round($x/$row)*$row)]

	    if {$x == $min} {
	      lappend avg $y
	      continue
	    }

	    if {$x < $min} {
	      set min $x
	      set avg $y
	    }
	  }

	  set yloc 0
	  foreach y $avg {
	    set yloc [expr $yloc + $y]
	  }

	  set yt $minx
	  set xt [expr $yloc/[llength $avg]]
	}

	s {
	  set max -1000000
	  set avg ""

	  foreach pair $pairs {
	    setl {y x} $pair
	
	    set x [expr int(round($x/$row)*$row)]

	    if {$x == $max} {
	      lappend avg $y
	      continue
	    }

	    if {$x > $max} {
	      set max $x
	      set avg $y
	    }
	  }

	  set yloc 0
	  foreach y $avg {
	    set yloc [expr $yloc + $y]
	  }

	  set yt $maxx
	  set xt [expr $yloc/[llength $avg]]
	  set ydir -1
	}
      }

      # normalize and put on a grid
      set xt [expr int((int(floor($xt)) + $xdir*$yoffset) * $DPC(yscale))]
      set yt [expr int((int(floor($yt)) + $ydir*$xoffset) * $DPC(xscale))]

      while {[info exists pin_coords($xt,$yt)]} {
	# uh oh, overlap
	switch $side {
	  w - e {
	    incr yt $DPC(xscale)
	  }
	  n - s {
	    incr xt $DPC(yscale)
	  }
	}
      }
      set pin_coords($xt,$yt) 1

      # add pin location to nl for writing to def
      # - A[31] + NET A[31] + PLACED ( 1500 -1000 ) N ;
      nl_set_port_location $io $yt $xt
      nl_set_port_orientation $io $XFORM(def,$i_data(orient))
      nl_set_port_geometry $io $DPC(PIN,$side) $pin_size
    }
  }
}


proc api_reset_library {} -type user -desc {

Resets the DPC leaf cell library read from LEF files.  The first time
DPC netlist is run, the LEF files get read.  If the LEF changes and
you want to see the new values (e.g. sizes, port locations) without
exiting SUE and reentering, call this function before running DPC
netlist.

} {

  global DPC

  catch {nl_remove_library -silent $DPC(lib)}

  return 1
}


# nl stuff
# nl linked at compile time or loaded in site .suerc

proc _nl_read_lef {} {

  global DPC DPC_SIZE nl_x_grid_size nl_y_grid_size

  # unless multiple libraries, this is fine
  set DPC(lib) dpc

  # set up grid size in nl
  set nl_x_grid_size $DPC(xscale)
  set nl_y_grid_size $DPC(yscale)

  # toast old library if exists
  # TODO: possibly special function to remove so not duplicated
#  catch {nl_remove_library -silent $DPC(lib)}

  if {![catch {nl_create_library $DPC(lib)}]} {
    puts "Creating $DPC(lib) library in nl ..."
    nl_create_plibrary $DPC(lib)

    # allows wildcards like /proj/tech/mmi25/stdcell/lef/*.lef
    # load LEF's if there are any
    if {[use_first DPC(LEF_PATH)] != ""} {
      puts "Loading LEF libraries ..."
  
      foreach lib $DPC(LEF_PATH) {
	puts "Reading $lib into nl ..."
	set is_file 0
	foreach file [glob -nocomplain -- $lib] {
	  set is_file 1
	  if {[catch {nl_read_lef $file $DPC(lib)} msg]} {
	    puts "DPC Warning: $msg"
	  }
	}
	if {!$is_file} {
	  puts "DPC Warning: couldn't find LEF file matching \"$lib\"."
	}
      }
      # fix up any buses
      nl_infer_libpin_buses $DPC(lib)
    }
  }

  # setup sizes in DPC_SIZE matrix
  # NOTE: flip must be fixed by reading ports files
  foreach libcell [nl_list_libcells $DPC(lib)] {
    if {![catch {nl_get_libcell_size -grids $libcell} msg]} {

# is this right??? TODO
      set height [expr int(round([lindex $msg 1]))]
      if {($height / $DPC(DEFAULT_ROW_HEIGHT)) % 2 == 1} {
	set flip 1
      } else {
	set flip 0
      }

      set DPC_SIZE([nl_get_libcell_name $libcell]) [concat $msg $flip]
    }
  }
}


proc nl_read {} {

  global NETLIST SUFFIX DPC

  # reset the nl database
  catch "nl_remove_design -all -silent"

  # read the verilog and link it
#  puts "nl_read_verilog $NETLIST(dir)$NETLIST(root)$SUFFIX(dpc)"
  nl_read_verilog "$NETLIST(dir)$NETLIST(root)$SUFFIX(dpc)"
  nl_link -silent -libraries $DPC(lib) $NETLIST(root)

  # fixes up unknown ones
  _link_unknown

  # initialize
  nl_create_pdesign
}


# links any unknown cells -- cells not read from LEF

proc _link_unknown {} {

  global DPC DPC_DATA XFORM NETLIST DPC_SIZE

  set relink_needed 0

  # find any lib cells that weren't read from LEF and add to nl
  foreach cell [nl_find_unlinked_references -recursive] {

    # note: can have duplicates here
    if {[info exists linked($cell)]} {
      # already did this one
      continue
    }
    set linked($cell) 1

    if {[string first *assignment $cell] == 0} {
#      puts "Skipping assignment $type"
      # skip assignment buffers
      continue
    }

#    puts "Linking $cell ..."

    # create it and add size, ports/directions/locations to nl
    set libcell [nl_create_libcell $cell $DPC(lib)]
    set relink_needed 1

    if {![info exists DPC_SIZE($cell)]} {
      set DPC_SIZE($cell) \
	  [list $DPC(DEFAULT_COLUMN_WIDTH) $DPC(DEFAULT_ROW_HEIGHT) 1]
    }

    nl_set_libcell_size -grids $libcell \
	[lindex $DPC_SIZE($cell) 0] [lindex $DPC_SIZE($cell) 1]

    catch {unset pin_bus}

    foreach cell_pin [array names DPC_DATA $cell,*] {
      set pin [lindex [split $cell_pin ,] 1]

      if {[is_bus $pin]} {
	# special for bused pins -- note buses are exploded here
	setl {pin_name pin_bit} [split $pin \[\]]

	if {[info exists pin_bus(max,$pin_name)]} {
	  set pin_bus(max,$pin_name) [max $pin_bus(max,$pin_name) $pin_bit]
	  set pin_bus(min,$pin_name) [min $pin_bus(min,$pin_name) $pin_bit]
	} else {
	  set pin_bus(max,$pin_name) $pin_bit
	  set pin_bus(min,$pin_name) $pin_bit
	}

	set pin_bus(dir,$pin_name) [lindex $DPC_DATA($cell_pin) 0]
	lappend pin_bus(name,$pin_name) $pin

      } else {
	# scalar
	nl_create_libpin $pin $XFORM(nlport,[lindex $DPC_DATA($cell_pin) 0]) \
	    $libcell

	nl_set_libpin_location -grids $libcell/$pin \
	    [lindex $DPC_DATA($cell_pin) 2] [lindex $DPC_DATA($cell_pin) 1]
      }
    }

    # now add the bused pins
    foreach dir_pin [array names pin_bus dir,*] {
      set pin [lindex [split $dir_pin ,] 1]

      nl_create_libpin_bus $pin \
	  $XFORM(nlport,$pin_bus($dir_pin)) \
	  $pin_bus(max,$pin) $pin_bus(min,$pin) $libcell

      foreach bit $pin_bus(name,$pin) {
	nl_set_libpin_location -grids $libcell/$bit \
	    [lindex $DPC_DATA($cell,$bit) 2] [lindex $DPC_DATA($cell,$bit) 1]
      }
    }
  }

  # relink if needed 
  if {$relink_needed} {
    # set current design back
    nl_link -silent -libraries $DPC(lib) $NETLIST(root)
  }
}


# put the included def locations/orientations and verilog into nl

proc _add_defs_to_nl {} {

  global DPC_FROM_DEF DPC DPC_SIZE DPC_ABS SUFFIX nl_current_design

  # first must get locations of stuff

  # add any relative defs with prefix, offset and flip (row N vs FS)
  # TODO eventually must allow mirroring and flipping of whole block
  foreach type [array names DPC_FROM_DEF] {

    # first remember this stuff since nl_read will toast
    foreach pair $DPC_FROM_DEF($type) {
      set instance [string trimleft [lindex $pair 0] /]
      set coords($instance) [nl_get_cell_location $instance]
      set orient($instance) [nl_get_cell_orientation $instance]
    }

    # read verilog for this
    set file $DPC_SIZE($type,dir)/$type$SUFFIX(dpc)
    puts "Reading (for DEF inclusion) $file ..."
    set save_current_design $nl_current_design
    nl_read_verilog $file
    set nl_current_design $save_current_design

    nl_link -silent

    # fixes up unknown ones
    _link_unknown

    nl_create_pdesign

    foreach pair $DPC_FROM_DEF($type) {
#AAA
      set instance [string trimleft [lindex $pair 0] /]
      set def_file [lindex $pair 1]

      if {$def_file == "" } {
	# not specified, use default
	set def_file $DPC_SIZE($type,dir)/$type.place.def
      } elseif {[string index $def_file 0] == "/"} {
	# absolute path, do nothing
      } else {
	# relative path
	set def_file $DPC_SIZE($type,dir)/$def_file
      }

      # TODO: offset of def file, too (assumes def file origin 0,0)
      nl_read_def -offset $coords($instance) -translate $orient($instance) \
	  $def_file $instance

      # now tell DPC that it is a hierarchical cell
      setl {x y} $coords($instance)
      set x [expr $x/$DPC(xscale)]
      set y [expr $y/$DPC(yscale)]

      set DPC_ABS($instance) [list HIER $type $y $x \
	     [lindex $DPC_SIZE($type) 1] [lindex $DPC_SIZE($type) 0] \
				  $orient($instance)]
    }
  }
}


# Setup steiner routing.
# If DPC(dspf), write RC, otherwise just C.

proc create_parasitics {{option ""}} {

  global DPC_CAP DPC SUFFIX NETLIST DPC_TIMING VERSION DPC_NET_ADD
  global _STEINER_BEGIN_NET_ _STEINER_END_NET_ _STEINER_ADD_POINT_

  # compute the filename for the parasitic file
  upvar #0 SUE_$NETLIST(root) data

  if {$DPC(dspf)} {
    # dspf
    set DPC_CAP(filename) "$NETLIST(dir)$NETLIST(root)$SUFFIX(dpc_est_dspf)"
  } else {
    # cap
    set DPC_CAP(filename) "$NETLIST(dir)$NETLIST(root)$SUFFIX(dpc_est_cap)"
  }

  if {$option == "filename"} {
    # just create filename
    return
  }

  puts "Creating parasitic file ..."

  # reset but the filename
  set filename $DPC_CAP(filename)
  catch {unset DPC_CAP}
  set DPC_CAP(filename) $filename

  catch {unset DPC_NET_ADD}

  # setup the command -- different for speedy
  if {$DPC_TIMING(simulator) == "speedy"} {
    set output_file_cmd speedy_steiner_output_file
    set _STEINER_BEGIN_NET_ speedy_steiner_begin_net
    set _STEINER_END_NET_ speedy_steiner_end_net
    set _STEINER_ADD_POINT_ speedy_steiner_add_point

  } else {
    set output_file_cmd steiner_output_file
    set _STEINER_BEGIN_NET_ steiner_begin_net
    set _STEINER_END_NET_ steiner_end_net
    set _STEINER_ADD_POINT_ steiner_add_point
  }

  if {$DPC(dspf) == 1} {
    # dspf
    set DPC_CAP(DSPF) 1
  } else {
    set DPC_CAP(DSPF) 0
  }

  # open file to write the parasitic data
  if {[catch "open $DPC_CAP(filename) w" DPC_CAP(FILE_ID)]} {
    # error
    sue_error "DPC ERROR: $DPC_CAP(FILE_ID)"
    return
  }

  # compute capacitance and resistance scaling factors

  # allows for different grid sizes in x and y
  # NOTE: switched for mask coords
  setl {yscale xscale} $DPC(SCALE)
  if {$xscale == ""} {
    set xscale $yscale
  }

  setl {yfactor xfactor} $DPC(MICRON_CAP_FACTOR)
  if {$xfactor == ""} {
    set xfactor $yfactor
  }
  set cap_xscale [expr $xscale * $xfactor]
  set cap_yscale [expr $yscale * $yfactor]

  setl {xfactor yfactor} $DPC(MICRON_RES_FACTOR)
  if {$yfactor == ""} {
    set yfactor $xfactor
  }
  set res_xscale [expr $xscale * $xfactor]
  set res_yscale [expr $yscale * $yfactor]

  # create array for added capacitance on ports
  foreach pair [use_first DPC(PORT_ADD_CAP)] {
    setl {name_port value} $pair
    set DPC_NET_ADD($name_port) $value
  }

  set DPC_CAP(CAP_PORT_FUDGE) $DPC(CAP_PORT_FUDGE)

  if {$DPC_CAP(DSPF)} {
    # dspf generation header
    puts $DPC_CAP(FILE_ID) "*|DSPF 1.5"
    puts $DPC_CAP(FILE_ID) "*|DESIGN \"$NETLIST(root)\""
    puts $DPC_CAP(FILE_ID) "*|DATE \"[exec date]\""
    puts $DPC_CAP(FILE_ID) "*|VENDOR \"Micro Magic Tools\""
    puts $DPC_CAP(FILE_ID) "*|PROGRAM \"$VERSION DPC\""
    puts $DPC_CAP(FILE_ID) "*|DIVIDER /"
    puts $DPC_CAP(FILE_ID) "*|DELIMITER :"
    puts $DPC_CAP(FILE_ID) "*|BUSBIT \[\]\n"

    puts $DPC_CAP(FILE_ID) ".SUBCKT $NETLIST(root)\n"

    puts $DPC_CAP(FILE_ID) "*|GROUND_NET VSS"
    flush $DPC_CAP(FILE_ID)

    # initial c routines
    $output_file_cmd $DPC_CAP(FILE_ID) -rconstx $res_xscale \
	-rconsty $res_yscale -cconstx $cap_xscale -cconsty $cap_yscale \
	-min_rc [parse_pp_number $DPC(MIN_RC)]

  } else {
    # cap only
    switch $DPC_TIMING(simulator) {
      pearl {
	# values in fF
	$output_file_cmd $DPC_CAP(FILE_ID) \
	    -cconstx $cap_xscale -cconsty $cap_yscale -string ""
      }

      primetime {
	# values in units given by DPC_TIMING(db_cap_units)
	# convert from fF to db_cap_units
	set mult [expr 1.0e-15 / [parse_pp_number $DPC_TIMING(db_cap_units)]]
	$output_file_cmd $DPC_CAP(FILE_ID) \
	    -cconstx [expr $mult * $cap_xscale] \
	    -cconsty [expr $mult * $cap_yscale] \
	    -string "set_capacitance " -pt 1

	# need to scale this
	set DPC_CAP(CAP_PORT_FUDGE) [expr $mult * $DPC(CAP_PORT_FUDGE)]
	set DPC_CAP(mult) $mult
      }

      pathmill {
	# values in fF
	$output_file_cmd $DPC_CAP(FILE_ID) \
	    -cconstx $cap_xscale -cconsty $cap_yscale \
	    -string "node_capacitance "
      }
    }
  }

  # now do the work
  create_parasitics_int
  create_parasitics_end
}


# Walk through each net, create the steiner route, and write the
# dspf section for it.
# Use net names that are highest in hierarchy

proc create_parasitics_int {} {

  global DPC DPC_CAP XFORM DPC_NET_ADD
  global _STEINER_BEGIN_NET_ _STEINER_END_NET_ _STEINER_ADD_POINT_

  set count 0

  # walk thru each net in the design
  foreach net [nl_list_nets -hier -noassign -noconstant] {

    set port_add 0

    incr count
    if {[expr $count % 10000] == 0} {
      puts "    ...$count..."
    }

    set num_points 0

    # walk thru each pin on each net.
    foreach pin [nl_get_net_pins -recursive -noassign $net] {

      # just got a pin like: adder_1/MUX2B_4/in1
      set cell [nl_get_pin_owner $pin]

      if {[nl_object_type $cell] == "port"} {
	# top level I/O
	if {!$DPC(PINS)} {
	  # ignore
	  continue
	}

	set pin_type [nl_get_port_direction $pin]
	set cell ""
	set pin_name $pin

      } else {
	set pin_type [nl_get_pin_direction $pin]
 	# just the pin, like "in1"
 	set pin_name [nl_get_pin_name $pin]
      }

      if {[catch {nl_get_pin_location -grids $pin} xy]} {
	# not defined -- maybe a top leve I/O, ignore
	continue
      }

      # dspf likes a certain abbrev.
      switch $pin_type {
	in { set pin_abbrev I }
	out { set pin_abbrev O }
	inout { set pin_abbrev B }
# steiner doesn't like X
#	default { set pin_abbrev X }
	default { set pin_abbrev B }
      }

      # TODO: replace above  -- what is default
#      set pin_abbrev $XFORM(pin,$pin_type)

      if { $num_points == 0 } {
	$_STEINER_BEGIN_NET_ $net
      }

      # NOTE: coords need to be integers
      $_STEINER_ADD_POINT_ $cell $pin_name $pin_abbrev \
	  [lindex $xy 0] [lindex $xy 1]

      incr num_points
    }

    if { $num_points > 0 } {

      # finish net with extras
      if {$port_add != 0} {
	if {!$DPC_CAP(DSPF) && $DPC_TIMING(simulator) == "primetime"} {
	  # special for primetime and capacitance file
	  set add [expr ($DPC_CAP(mult) * $port_add) + $DPC_CAP(CAP_PORT_FUDGE)]
	} else {
	  set add [expr $port_add + $DPC_CAP(CAP_PORT_FUDGE)]
	}

      } else {
	set add $DPC_CAP(CAP_PORT_FUDGE)
      }

      # do the steiner route.  Supposed to start from an output.
      $_STEINER_END_NET_ $add
    }
  }
}


# close the parasitic file

proc create_parasitics_end {} {

  global DPC_CAP

  if {$DPC_CAP(DSPF)} {
    # dspf generation
    puts $DPC_CAP(FILE_ID) "\n.ENDS\n"
    puts $DPC_CAP(FILE_ID) ".END"
  }

  # close the tempfile
  close $DPC_CAP(FILE_ID)

  puts "Wrote estimated parasitics to $DPC_CAP(filename)"
}


# add preroutes

proc _add_preroutes {} {

  global DPC_PREROUTES PLACEMENT_DATA PREROUTE DPC NETLIST

  setl {xoffset yoffset} $DPC(TRACK_OFFSET)
  if {$yoffset == ""} {
    set yoffset $xoffset
  }

  setl {xpd ypd} $PREROUTE(pin_distance)
  if {$ypd == ""} {
    set ypd $xpd
  }

  set pitch [use_first PREROUTE(row_pitch) DPC(PITCH)]
  set row [use_first PREROUTE(column_pitch) DPC(DEFAULT_ROW_HEIGHT)]

  # process the preroutes
  foreach net [array names DPC_PREROUTES] {
    # get highest net in hierarchy
    set hnet [get_net_equiv $net 1]

    if {[catch {nl_get_net_pins -recursive -noassign $hnet} pins]} {
      # this is not a valid net
      continue
    }

    foreach preroute $DPC_PREROUTES($net) {
      setl {dir layer track} $preroute

      set min 1000000
      set max -1000000
      set driver 0
      if {$dir == "H"} {
	# horizontal
	foreach pin $pins {
	  set cell [nl_get_pin_owner $pin]
	  if {[nl_object_type $cell] == "port"} {
	    # top level I/O
	    if {!$DPC(PINS)} {
	      # ignore
	      continue
	    }

	    # use this pin
	    setl {y x} [nl_get_port_location $pin]

	    set pair [list [expr 1.0 * $x / $DPC(UNITS)] \
			  [expr 1.0 * $y / $DPC(UNITS)]]

	  } else {
	    # pin on an instance
	    set pair [_pin_location $pin]
	    if {$pair == ""} {
	      # who knows
	      continue
	    }
	  }

	  set x [expr int([lindex $pair 0])]
	  set min [min $x $min]
	  set max [max $x $max]

	  # find the direction of this 
	  if {[nl_get_pin_direction $pin] == "out"} {
 	    # this is the driver
	    set y1 [expr int((int(floor([lindex $pair 1]))/$pitch*$pitch + $xoffset + $track) * $DPC(xscale))]
	    set driver 1
	  }
	}

	if {!$driver || $min == $max} {
	  # point line, punt -- probably only one connection or no driver
	  continue
	}

	set x1 [expr int(($min + $yoffset + $ypd) * $DPC(yscale))]
	set x2 [expr int(($max - $yoffset - $ypd) * $DPC(yscale))]
	set y2 $y1

	# put in nl database
#	nl_add_net_route $hnet [list [list $layer [list $y1 $x1] [list * $x2]]]
	nl_add_net_route -type $PREROUTE(ROUTE_TYPE) $hnet \
	    [list [list $layer [list $y1 $x1] [list * $x2]]]
	
      } else {
	# vertical
	foreach pin $pins {
	  set cell [nl_get_pin_owner $pin]
	  if {[nl_object_type $cell] == "port"} {
	    # top level I/O
	    if {!$DPC(PINS)} {
	      # ignore
	      continue
	    }

	    # use this pin
	    setl {y x} [nl_get_port_location $pin]

	    set pair [list [expr 1.0 * $x / $DPC(UNITS)] \
			  [expr 1.0 * $y / $DPC(UNITS)]]

	  } else {
	    # pin on an instance
	    set pair [_pin_location $pin]
	    if {$pair == ""} {
	      # who knows
	      continue
	    }
	  }

	  set y [expr int([lindex $pair 1])]
	  set min [min $y $min]
	  set max [max $y $max]
	  if {[nl_get_pin_direction $pin] == "out"} {
	    # this is the driver
	    set x1 [expr int((int(floor([lindex $pair 0]))/$row*$row + $xoffset + $track) * $DPC(yscale))]
	    set driver 1
	  }
	}

	if {!$driver || $min == $max} {
	  # point line, punt -- probably only one connection or no driver
	  continue
	}

	set y1 [expr int(($min + $xoffset + $xpd) * $DPC(xscale))]
	set y2 [expr int(($max - $xoffset - $xpd) * $DPC(xscale))]
	set x2 $x1

	# put in nl database
#	nl_add_net_route $hnet [list [list $layer [list $y1 $x1] [list $y2 *]]]
	nl_add_net_route -type $PREROUTE(ROUTE_TYPE) $hnet \
	    [list [list $layer [list $y1 $x1] [list $y2 *]]]

      }

      lappend PLACEMENT_DATA($NETLIST(root),preroutes) \
	  "$hnet $layer $dir [expr $x1 * 10/$DPC(yscale)] [expr $y1 * 10/$DPC(xscale)] [expr $x2 * 10/$DPC(yscale)] [expr $y2 * 10/$DPC(xscale)]"
    
      # don't need anymore
      unset DPC_PREROUTES($net)
    }
  }

  set missed [array names DPC_PREROUTES]
  if {[llength $missed] > 0} {
    puts "WARNING: Preroutes attached to the following nets were skipped: [join $missed ,]"
  }
}


# returns the pin location of the given pin in grids unless
# multiplier specified other than 1.

#  nl_get_pin_location {MMI_BUFB$2$/in}

proc _pin_location {pin {mult 1}} {

  if {[catch {nl_get_pin_location -grids $pin} xy]} {
    # not defined -- maybe a top leve I/O, ignore
    return
  }

  return [list [expr $mult * [lindex $xy 1]] [expr $mult * [lindex $xy 0]]]
}


# for now uses flylines instead of steiner routes
# displays on selected

proc display_connections_on_placement {} {

  global cur_c cur_s scale COLORS DPC

  if {![is_placement $cur_s]} {
    warning "Aborting, can only be run on a placement."
    return
  }

  busy

  foreach id [$cur_c find withtag selected&origin] {
    if {![is_tagged $id icon__place*]} {

      if {![is_tagged $id icon_input] && ![is_tagged $id icon_output] && \
	      ![is_tagged $id icon_inout]} {
	# skip since not a placed instance
	continue
      }

      # I/O
      upvar #0 ${cur_s}_inst$id i_data

      set name $i_data(_name)
      set io 1

    } else {

      # get the full name of this instance
      upvar #0 ${cur_s}_inst$id i_data

      set name $i_data(_instance)
      set io 0
    }

    # get all of the pins connected to this guy
    foreach pin [nl_get_cell_or_port_pins $name] {
      set pin_name [nl_get_pin_name $pin]

# why did I once do this?
#      set from_pin $name/$pin_name
      set from_pin $pin

      set net [nl_get_pin_net $from_pin]

      # special case if hierarchical cell (not a base cell)
      if {!$io && [nl_find_designs -exact [nl_get_cell_reference $name]] != ""} {

	# must find a pin inside of this to use
	# if an output, find all outputs -- should be only one
	# if no output, find all inputs.
	set from_pin ""
	set in_pins ""
	set hier 1

	foreach to_pin [nl_get_net_pins -recursive -noassign $net] {	
	  set owner [nl_get_pin_owner $to_pin]	  
	  
	  if {[string first $name/ $owner] == 0} {
	    # this pin comes from this hier
	    if {[nl_get_pin_direction $to_pin] == "out"} {
	      # and is an output
	      lappend from_pin $to_pin
	    } else {
	      # a non-output
	      lappend in_pins $to_pin
	    }
	  }
	}

	if {[llength $from_pin] > 0} {
	  # pin is an output
	  set arrow "last"
	} elseif {[llength $in_pins] > 0} {
	  # not out output
	  set from_pin $in_pins
	  set arrow "none"
	} else {
	  # couldn't find a pin, ignore
	  puts "WARNING, couldn't find a connection to pin $from_pin in cell $name"
	  continue
	}

      } else {
	# not a hier cell
	set hier 0

	set arrow "none"
	if {[nl_get_pin_direction $from_pin] == "out"} {
	  set arrow "last"
	}
      }

      set coords ""
      foreach to_pin $from_pin {
	lappend coords [_pin_location $to_pin $scale]
      }

      # now get the net connected to this pin
      foreach to_pin [nl_get_net_pins -recursive -noassign $net] {
	set owner [nl_get_pin_owner $to_pin]

	if {(!$hier && $to_pin == $from_pin) || \
		($hier && [string first $name/ $owner] == 0)} {
	  # came from here, ignore
	  continue
	}

	if {[nl_get_pin_direction $to_pin] == "out"} {
	  set arrow "first"
	} elseif {[nl_get_pin_direction $to_pin] == "inout" && \
		      $arrow != "last"} {
	  set arrow "first"
	} elseif {$arrow == "none"} {
	  # don't show unless one end is an output
	  continue
	}

	if {[nl_object_type $owner] == "port"} {
	  # top level I/O
	  if {!$DPC(PINS)} {
	    # user doesn't want to see these
	    continue
	  }
	}
	setl {xt yt} [_pin_location $to_pin $scale]

	foreach coord $coords {
	  eval $cur_c create line $coord $xt $yt -tags "tmp" \
	      -fill $COLORS(stroke_box) -arrow $arrow
	}

	if {$arrow == "first"} {
	  set arrow "none"
	}
      }
    }
  }

  ready
}

