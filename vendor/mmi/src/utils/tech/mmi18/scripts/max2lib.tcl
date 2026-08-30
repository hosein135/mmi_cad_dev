# Builds a lib file for the max cell
# Gets the capacitance on all top level I/O's

# Written by Lee Tavrow, 2000.

proc c {} {
  uplevel #0 source /home/tavrow/dev/max/max2lib.tcl
  puts loaded
  max2lib
}

#====================================================================#

# figures out pads from this layer -- to ignore
set PAD_LAYER pad

# clock signal
set CLOCK_SIGNAL(foo) bar
set CLOCK_SIGNAL(rx_par_clk_out) tx_ser_clk

for {set i 0} {$i < 16} {incr i} {
  for {set j 0} {$j < 8} {incr j} {
    set k [expr $i * 8 + $j]
    set CLOCK_SIGNAL(rx_pat_0\[$k\]) "rx_par_clk_in\[$i\]"
  }
}

set REF_CLOCK rx_par_clk_in\[0\]

set SETUP_RISE 0.3
set SETUP_FALL 0.5
set HOLD_RISE 0.1
set HOLD_FALL 0.1

proc max2lib {} -desc {
  get caps
} {

  global PAD_LAYER CLOCK_SIGNAL REF_CLOCK SETUP_RISE SETUP_FALL
  global HOLD_RISE HOLD_FALL

  set CLOCKS($REF_CLOCK) 1
  foreach one [array names CLOCK_SIGNAL] {
    set CLOCKS($CLOCK_SIGNAL($one)) 1
  }

  set cell [lay_rootcell]

  # find the directory
  set dir [file dirname [lindex [cell_info $cell] 1]]
  if {$dir == "."} {
    set dir [pwd]
  }

  set filename $dir/$cell.lib
  puts "Writing lib for cell $cell to $filename ..."

  # open lib file for writing
  if {[catch "open $filename w" FILE_ID]} {
    # can't write file, abort
    warning "Aborting, $FILE_ID"
    return
  }

  puts $FILE_ID "library ($cell) \{"
  puts $FILE_ID "comment : \"built from layout from max2lib.tcl\";"
  puts $FILE_ID "delay_model : table_lookup;"
  puts $FILE_ID "lu_table_template(li2X2) \{"
  puts $FILE_ID "	variable_1 : total_output_net_capacitance;"
  puts $FILE_ID "	variable_2 : input_net_transition;"
  puts $FILE_ID "	index_1 (\"0, 1\");"
  puts $FILE_ID "	index_2 (\"0, 1\");"
  puts $FILE_ID "\}"
  puts $FILE_ID "nom_process                 : 1.0;"
  puts $FILE_ID "nom_temperature             : 125.00;"
  puts $FILE_ID "nom_voltage                 : 2.25;"
  puts $FILE_ID "time_unit                   : \"1ns\";"
  puts $FILE_ID "voltage_unit                : \"1V\";"
  puts $FILE_ID "capacitive_load_unit (1.000,pf);"

  puts "Searching I/O's ..."
  
  # make sure everything is fully expanded
  :feedback clear
  eval lay_box [lay_bbox]
  lay_internals -area

  sel_labels -kind input
  sel_labels -more -kind output
  sel_labels -more -kind inout

  set fets [techinfo devices]
  set nfet [lindex $fets 0]
  setl {poly ndif} [techinfo device $nfet]
  set del [res -mask]

  # first a pass to find buses (lib choke)
  foreach label [split [sel_what labels] \n] {
    setl {layer lx1 ly1 lx2 ly2 pos text path group kind} $label

    if {$path != ""} {
      # not top level
      continue
    }

    if {[db_search paint -any_cell -area $lx1 $ly1 $lx2 $ly2 $PAD_LAYER] != ""} {
      # ignore pad i/o's
      continue
    }

    setl {name bit} [split $text \[\]]
    lappend LABELS($name) $label

    if {$bit != ""} {
      # bit of a bus
      if {![info exists BUS_MIN($name)]} {
	set BUS_MIN($name) $bit
	set BUS_MAX($name) $bit
	set BUS_DIR($name) $kind
      } else {
	set BUS_MIN($name) [min $BUS_MIN($name) $bit]
	set BUS_MAX($name) [max $BUS_MAX($name) $bit]
      }
    }
  }

  # assumes BUS_MIN is 0
  foreach name [array names BUS_MAX] {
    set max $BUS_MAX($name)

    if {![info exists BUS_TYPE($max)]} {
      set min $BUS_MIN($name)
      set BUS_TYPE($max) "bus${max}_bus${min}"

      puts $FILE_ID "type ($BUS_TYPE($max)) \{"
      puts $FILE_ID "        base_type : array;"
      puts $FILE_ID "        data_type : bit;"
      puts $FILE_ID "        bit_width : [expr $max - $min + 1];"
      puts $FILE_ID "        bit_from : $max;"
      puts $FILE_ID "        bit_to : $min;"
      puts $FILE_ID "        downto : true;"
      puts $FILE_ID "\}"
    }
  }

  puts $FILE_ID "cell ($cell) \{"

  set count 0
  foreach name [array names LABELS] {
    if {[info exists BUS_MAX($name)]} {
      # bus
      puts $FILE_ID "\tbus ($name) \{"
      puts $FILE_ID "\t\tbus_type : $BUS_TYPE($BUS_MAX($name)) ;"
      puts $FILE_ID "\t\tdirection : $BUS_DIR($name) ;"
    }

    set LABELS($name) [list [lindex $LABELS($name) 0]]

    foreach label $LABELS($name) {
      setl {layer lx1 ly1 lx2 ly2 pos text path group kind} $label

      sel_net -point $lx1 $ly1 $layer

      # assume in fF
      set cap [lindex [ext_capacitance] 0]

      # now add up gate cap at 10 fF/um2
      foreach paint [split [sel_what paint] \n] {
	if {[lsearch $fets [lindex $paint 0]] != -1} {
	  setl {player x1 y1 x2 y2} $paint
	  
	  set cap [expr $cap + ($x2 - $x1) * ($y2 - $y1) * 10.0]
	}
      }
      
      set drive 0.0
      if {$kind == "output"} {
	# compute drive strength.  Assumes no series devices
	foreach paint [split [sel_what paint] \n] {
	  if {[lindex $paint 0] == $ndif} {
	    # found a possible source drain, get gate
	    setl {player x1 y1 x2 y2} $paint
	  
	    sel_area -any_cell -layers $nfet [expr $x1 - $del] [expr $y1 - $del] \
		[expr $x2 + $del] [expr $y2 + $del]
	    
	    foreach tpaint [split [sel_what paint] \n] {
	      setl {player x1 y1 x2 y2} $tpaint
	      
	      set drive [expr $drive + ($x2 - $x1) * ($y2 - $y1) / $del]
	    }
	  }
	}
      }
      
      switch $kind {
	input {
	  if {![info exists BUS_MAX($name)]} {
	    puts $FILE_ID "\tpin ($text) \{"
	  }
	  
	  if {![info exists BUS_MAX($name)]} {
	    puts $FILE_ID "\t\tdirection : input;"
	  }

	  # convert to pF
	  puts $FILE_ID "\t\tcapacitance : [expr $cap / 1000.0];"

	  if {![info exists CLOCKS($text)]} {
	    # has a refernce clock, put in setup and hold info
	    
	    set ref [use_first CLOCK_SIGNAL($text) REF_CLOCK]
	    if {$ref != $REF_CLOCK || [info exists LABELS($REF_CLOCK)]} {
	      set ref [lindex [split $ref \[\]] 0]

	      puts $FILE_ID "\t\ttiming () \{"
	      puts $FILE_ID "\t\t\ttiming_type : setup_rising;"

	      puts $FILE_ID "\t\t\trelated_pin : \"$ref\";"
	      puts $FILE_ID "\t\t\trise_constraint(scalar) \{"
	      puts $FILE_ID "\t\t\t\tvalues(\"$SETUP_RISE\");"
	      puts $FILE_ID "\t\t\t\}"
	      puts $FILE_ID "\t\t\tfall_constraint(scalar) \{"
	      puts $FILE_ID "\t\t\t\tvalues(\"$SETUP_FALL\");"
	      puts $FILE_ID "\t\t\t\}"
	      puts $FILE_ID "\t\t\}"
	      
	      puts $FILE_ID "\t\ttiming () \{"
	      puts $FILE_ID "\t\t\ttiming_type : hold_rising;"
	      
	      puts $FILE_ID "\t\t\trelated_pin : \"$ref\";"
	      puts $FILE_ID "\t\t\trise_constraint(scalar) \{"
	      puts $FILE_ID "\t\t\t\tvalues(\"$HOLD_RISE\");"
	      puts $FILE_ID "\t\t\t\}"
	      puts $FILE_ID "\t\t\tfall_constraint(scalar) \{"
	      puts $FILE_ID "\t\t\t\tvalues(\"$HOLD_FALL\");"
	      puts $FILE_ID "\t\t\t\}"
	      puts $FILE_ID "\t\t\}"
	    }

	  } else {
	    puts $FILE_ID "\t\tclk : true;"
	  }

	  puts $FILE_ID "\t\}"
	}

	output {
	  if {![info exists BUS_MAX($name)]} {
	    puts $FILE_ID "\tpin ($text) \{"
	  }

	  if {![info exists BUS_MAX($name)]} {
	    puts $FILE_ID "\t\tdirection : output;"
	  }

	  if {[info exists CLOCK_SIGNAL($text)]} {
	    # has a refernce clock, put in setup and hold info
	    puts $FILE_ID "\t\ttiming () \{"
			  
	    foreach one "cell_fall fall_transition cell_rise rise_transition" {

	      puts $FILE_ID "\t\t\t${one}(li2X2) \{"
	      # output cap
	      puts $FILE_ID "\t\t\t\tindex_1(\"0.01,0.10\");"
	      # input slew
	      puts $FILE_ID "\t\t\t\tindex_2(\"0.1,0.2\");"

	      # relate to a B size driver (nfet = .92um)
	      set v1 [expr 0.05 / ($drive / .92)]

	      switch $one {
		cell_rise - rise_transition {
		  # rise is slower
		  set v1 [expr $v1 * 1.2]
		}
	      }

	      set v2 [expr $v1 * 1.1]
	      # linear with output cap
	      set v3 [expr $v1 * 10]
	      set v4 [expr $v3 * 1.1]

	      puts $FILE_ID "\t\t\t\tvalues(\"$v1,$v2\",\\"
	      puts $FILE_ID "\t\t\t\t       \"$v3,$v4\");"

	      puts $FILE_ID "\t\t\t\}"
	    }

	    puts $FILE_ID "\t\t\ttiming_type : rising_edge;"

	    set ref $CLOCK_SIGNAL($text)
	    set ref [lindex [split $ref \[\]] 0]

	    puts $FILE_ID "\t\t\trelated_pin : \"$ref\";"

	    puts $FILE_ID "\t\t\}"
	  }

	  puts $FILE_ID "\t\}"
	}
	
	default {
	  puts "Skipping $label"
	}
      }

      puts "$text $kind ${cap}fF $drive"
      incr count
    }

#    if {[info exists BUS_MAX($name)]} {
#      puts $FILE_ID "\t\}"
#    }
  }
 
  puts $FILE_ID "\}"
  puts $FILE_ID "\}"

  # close the file
  close $FILE_ID

  # clean up
  sel_clear

  puts "Created $count I/O's in lib file."
}

