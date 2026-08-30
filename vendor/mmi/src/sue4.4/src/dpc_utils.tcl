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


# Utility/Other procs for SUE DPC.


# simple proc to read and parse verilog and add I/O to current design.

proc parse_verilog {} {

  global cur_c cur_s scale SUE SUFFIX

  modify_setup

  set schematic [get_rootname $cur_s]
  global SUE_${schematic}

  # if there is no schematic, then look in the icon
  if {[info exists SUE_${schematic}(canvas)] != 1} {
    set schematic $cur_s
    global SUE_${schematic}
  }

  set dir [set SUE_${schematic}(dir)]
  if {$dir == ""} {
    set dir "[pwd]/"
  }

  # Prompt for a file name
  set filename [fs_box -message "Enter Verilog File:" \
		    -filename "$dir${schematic}.v" -pattern *.v*]

  # if nil, file selector box cancelled -- do nothing
  if {$filename == ""} { 
    return 
  }

  puts "Searching file \"$filename\" for module \"$schematic\" ..."

  # open the verilog file to parse
  if {[catch "open $filename r" FILE_ID]} {
    # error
    warning "Bad File: $FILE_ID"
    return
  } 

  busy

  set ids ""
  
  # place new I/Os on the left side in a column
  $cur_c delete tmp
  $cur_c addtag tmp withtag all
  $cur_c dtag grid tmp
  setl {x y} [round_list_scale [$cur_c bbox all] $scale]
  if {$x == "" || $y == ""} {
    set x 0
    set y 0
  }

  $cur_c dtag tmp

  set x [expr $x -30 * $scale]
  set dy [expr $scale * 4]

  # get a list of existing I/O terminal names
  set term_names ""
  set io_ids "[$cur_c find withtag icon_input] [$cur_c find withtag icon_output] [$cur_c find withtag icon_inout]"
  foreach id $io_ids {
    global ${cur_s}_inst$id
    set name [set ${cur_s}_inst${id}(_name)]
    # need to quote brackets
#    regsub -all {\[|\]} $name \\\\& name
    # We have a winner
#    regsub -all {\\\$} $name {\\\\\$} name

    if {$name != ""} {
      lappend term_names $name
    }
  }

  # now read it
  set in_module 0
  set count 0
  while {[gets $FILE_ID line] >= 0} {

    # can't do the obvious because these aren't well formed lists
    # set type [lindex $line 0]

    # toast tab characters and leading spaces
    regsub -all \t $line " " line
    set line [string trimleft $line]

    regexp {^([^ ]*)} $line tmp type

    if {!$in_module} {
      if {$type == "module" &&\
	      [lindex [split [lindex $line 1] \(] 0] == $schematic} {
	# found the module corresponding to this schematic
	set in_module 1
	set in_task 0
      }
      continue
    }

    if {$in_module && $type == "endmodule"} {
      # end of module
      break
    }

    if {$in_module && $type == "task"} {
      # special case of a task, ignore stuff inside
      set in_task 1
      continue
    }

    if {$in_task} {
      if {$type == "endtask"} {
	# task done
	set in_task 0
      }
      continue
    }

    if {[lsearch -exact "input output inout wire reg" $type] != -1} {
      # found an I/O declaration (or internal)
      # strip off = to end of line if there is one
      set index [string first = $line]
      set index2 [string first \; $line]
      if {$index != -1 && \
	      ($index2 == -1 || ($index2 != -1 && $index < $index2))} {
	set line [string range $line 0 [expr $index - 1]]
      } else {
	regsub {,([ \t]*)//(.*)$} $line , line
	set index [string first \; $line]
	if {$index == -1} {
	  # line not complete, get next line
	  while {[gets $FILE_ID line2] >= 0} {
	    set index [string first \; $line2]
	    regsub {,([ \t]*)//(.*)$} $line2 , line2
	    set line [concat $line $line2]
	    if {$index != -1} {
	      break
	    }
	  }
	}
      }
      # strip off ; to end of line
      regsub {;(.*)$} $line "" line

      # determine if this is a vector or a scalar
      set tmp [string index [lindex $line 1] 0]
      if {$tmp == "`" || $tmp == "\["} {
	# vector

	# get rid of whitespace in bus info.
	regsub {\[(\ |\t)+} $line \[ line
	regsub {(\ |\t)+\]} $line \] line
	regsub {(\ |\t)*\:(\ |\t)*} $line \: line

	set size [lindex $line 1]
	set names [lrange $line 2 end]
      } else {
	# scaler
	set size ""
	set names [lrange $line 1 end]
      }

      if {$type == "wire" || $type == "reg"} {
	set type name_net_s
      }

      foreach name [split $names ,] {
	if {$name == ""} {
	  continue
	}

	set name [string trim $name]

	# now add the icon if it isn't already there
	if {$size == ""} {
	  if {[lsearch -exact $term_names $name] == -1} {
	    lappend ids [make $type -origin "$x $y" -name $name]
	    incr count
	    set y [expr $y + $dy]
	  }
	} else {
	  # bus
#	  regsub -all ` $name$size \\\$` bus_name
	  set bus_name $name$size
	  if {[lsearch -exact $term_names $bus_name] == -1} {
	    lappend ids [make $type -origin "$x $y" -name $bus_name]
	    incr count
	    set y [expr $y + $dy]
	  }
	}
      }
    }
  }
  # close the file
  close $FILE_ID
    
  if {!$in_module} {
    puts "Aborting, Couldn't find module \"$schematic\"."
    ready
    return ""
  }

  is_modified

  zoom_to_fit

  select_ids $ids

  # save undo information
  setup_undo $ids ""

  puts "Added $count I/O's."

  ready

  return ""
}


# read a def file with placement and connection info and place
# and wire up (by name) icons in a sue schematic to correspond to.
# NOTE that if you have leading | in your def file you need to
# remove them with sed or similar.

proc make_cell_from_def {{filename ""}} {

  global cur_s cur_c scale DPC DPC_SIZE SEPARATOR

  set SEPARATOR __

  set ignore_cells [use_first DPC(ignore_cells)]

  # Prompt for a file name
  if {$filename == ""} {
    set filename [fs_box -message "Enter def File:" -pattern *.def]
    
    # if nil, file selector box cancelled -- do nothing
    if {$filename == ""} { 
      return 
    }
  }

  if {[catch "open $filename r" FILE_ID]} {
    # error
    warning "Bad File: $FILE_ID"
    return
  } 

  busy

  setl {dir cell_name suffix} [split_filename $filename]
  if {$dir == ""} {
    set dir "[pwd]/"
  }

  goto_new_schematic $cell_name $dir

  # set up the TERMS array with names of instances
  upvar #0 TERMS_$cur_s TERMS

  # parses something of the form
  puts "placing components ..."

  #COMPONENTS 2 ;
  #- OAI21B_ OAI21B + PLACED ( -14000 -19600 ) N ;
  #- INVA INVA + PLACED ( -12600 8400 ) N ;
  #END COMPONENTS

  while {[gets $FILE_ID line] >= 0} {
    if {[string first COMPONENTS [string trimleft $line]] == 0} {
      # found the components
      set components [lindex $line 1]
      break
    }
  }

  # now read the components
  set count 0
  while {[gets $FILE_ID line] >= 0} {
    if {[lindex $line 0] == "END"} {
      # we're done
      break
    }

    # check for continuation lines (i.e. no ; termination)
    while {[string first \; $line] == -1} {
      if {[gets $FILE_ID line2] == 0} {
	puts "Aborting, EOF found prematurely."

	ready
	return
      }
      
      set line "$line $line2"
    }

    setl {dash name type plus place leftp x y rightp orient} $line

    if {$x == ""} {
      puts "Aborting, cell $name of type $type is not placed"

      ready
      return
    }

    # hierarchical divider can't be / since this is really flat
    regsub -all {\/} $name $SEPARATOR name
    regsub -all {\[|\]} $name $SEPARATOR name
    
    set rows($y) 1
    set rows_${y}($x) "$type $name $x $y"
  }

  # get gate size information
  get_gate_sizes

  set div [expr int(round($DPC(SCALE) * $DPC(UNITS)))]

  # now place them
  foreach row [array names rows] {

    set last_coord 0
    set last_width 0

    foreach coord [lsort -increasing -integer [array names rows_$row]] {
      setl {type name x y} [set rows_${row}($coord)]

      if {[lsearch $ignore_cells $type] != -1} {
	# ignore this cell
	set last_coord $coord
	set last_width 0
	continue
      }

      set width [lindex [use_first DPC_SIZE($type) '0] 0]

      set x [round_list_scale [expr $x / 30] $scale]
      set y [round_list_scale [expr $y / 15] $scale]

      set next [expr int(($coord - $last_coord) / $div - $last_width)]
      if {$next != 0} {
	set id [make $type -name $name -origin "$y $x" \
		    -dpc [format "%+d" $next]]
      } else {
	set id [make $type -name $name -origin "$y $x"]
      }

      set TERMS($id) $name
      # cache this away for use when adding nets
      set names($name) $id
      set names($name,type) $type

      # cache the terminal information
      if {![info exists names(terms,$type)]} {
	set names(terms,$type) cached

	foreach term_id [get_intersect_tag inst$id term] {
	  set tags [$cur_c gettags $term_id]
	  set term_name [lindex [lindex $tags [lsearch $tags "name*"]] 3]

	  # save away the increment of the id for this terminal
	  set names($type,$term_name) [expr $term_id - $id]
	}
      }

      set last_coord $coord
      set last_width $width
      incr count
    }
  }

  puts "placed $count components."

  # place the pins
  #PINS 23 ;
  #- uge + NET uge + DIRECTION OUTPUT + USE SIGNAL ;
  #- b(10) + NET b(10) + DIRECTION INPUT + USE SIGNAL ;
  #END PINS

  # first figure out where to put the pins
  $cur_c addtag object all
  $cur_c dtag grid object

  setl {x1 y1 x2 y2} [round_list_scale [$cur_c bbox object] $scale]
  $cur_c dtag object

  set inx [expr $x1 - 200]
  set outx [expr $x2 + 200]

  set iny $y1
  set outy $y1


  while {[gets $FILE_ID line] >= 0} {
    if {[lindex $line 0] == "PINS"} {
      # found the pins
      break
    }
  }

  # now read the pins
  set count 0
  while {[gets $FILE_ID line] >= 0} {
    if {[lindex $line 0] == "END"} {
      # we're done
      break
    }

    # check for continuation lines (i.e. no ; termination)
    while {[string first \; $line] == -1} {
      if {[gets $FILE_ID line2] == 0} {
	puts "Aborting, EOF found prematurely."

	ready
	return
      }
      
      set line "$line $line2"
    }

    setl {dash pin plus net pin2 plus2 direction type} $line
    regsub -all {\(} $pin \[ pin
    regsub -all {\)} $pin \] pin

    switch [string toupper $pin] {
      VDD - GND {
	# ignore these
	continue
      }
    }

    set root [bus_root $pin]

    set pin_types($root) [string tolower $type]
    if {[is_bus $pin]} {
      lappend pin_names($root) [lindex [bus_range $pin] 0]
    } else {
      set pin_names($root) scalar
    }
  }

  foreach pin [array names pin_names] {
    if {$pin_names($pin) == "scalar"} {
      set pin_name $pin
    } else {
      # combine the bus
      if {[llength $pin_names($pin)] == 1} {
	# one bit bus ?
	set pin_name "$pin\[$pin_names($pin)\]"
      } else {
	# real bus
	set sort [lsort -real $pin_names($pin)]
	set min [lindex $sort 0]
	set max [lindex [lreverse $sort] 0]

	set pin_name "$pin\[$max:$min\]"
      }
    }

    # place the pin (inputs on left, outputs on right)
    if {$pin_types($pin) == "input"} {
      # input
      set x $inx
      set y $iny
      incr iny 50

    } else {
      # output
      set x $outx
      set y $outy
      incr outy 50
    }

    make $pin_types($pin) -name $pin_name -origin "$x $y"
  }


  # show the user what we've got so far.
  zoom_to_fit
  update

  puts "placing nets ..."
  busy

  # now read the nets which look like the following

  # need to start from top again

  # close the file
  close $FILE_ID

  if {[catch "open $filename r" msg]} {
    puts "Aborting, $msg"
    ready
    return
  }

  #NETS 56 ;
  #- b(0) ( INVA in ) ;
  #- a(0) ( NOR2B in1 ) ;
  #- net_1 ( INVA out ) ( NOR2B in0 ) ;
  #END NETS

  while {[gets $FILE_ID line] >= 0} {
    if {[string first NETS [string trimleft $line]] == 0} {
      # found the nets
      break
    }
  }

  # now read the nets
  while {[gets $FILE_ID line] >= 0} {
    set line [string trim $line]

    if {[lindex $line 0] == "END"} {
      # we're done
      break
    }

    if {[lindex $line 0] != "-"} {
      # skip this
      continue
    }

    set net [lindex $line 1]
    regsub -all {\(} $net \[ net
    regsub -all {\)} $net \] net

    set nets [lrange $line 2 end]
    while {1} {
      if {[lindex $nets 0] == ""} {
	# must be a continuation line, get the next one.
	gets $FILE_ID nets
      }

      setl {lparen inst_name port rparen} $nets
      if {$lparen == ";" || $lparen == "+"} {
	# done with this net
	break
      }

      _add_net_to_instance $net $inst_name $port

      set nets [lrange $nets 4 end]
    }
  }

  # close the file
  close $FILE_ID

  # show connection info
  scale_canvas 10
  show_connects "" fast
  zoom_to_fit

  is_modified

  ready

  puts "done."
}


# used by make_cell_from_def

proc _add_net_to_instance {net inst_name port} {

  global cur_s cur_c SEPARATOR
  upvar names names
  upvar TERMS TERMS

  if {$inst_name == "PIN"} {
    # ignore pins, got them already
    return
  }

  regsub -all {\/} $inst_name $SEPARATOR inst_name
  regsub -all {\[|\]} $inst_name $SEPARATOR inst_name

  regsub -all {\/} $net $SEPARATOR net

  if {![info exists names($inst_name)]} {
    puts "ERROR: can't find instance $inst_name to attach net $net to."
    return
  }
  set id $names($inst_name)
  set type $names($inst_name,type)

  # now find the terminal on this instance
  if {[info exists names($type,$port)]} {
    set term_id [expr $id + $names($type,$port)]

    setl {x y} [center $term_id]
    # make the net
    if {[lsearch "VDD GND" $net] != -1} {
      # put in a global for these
      make global -name $net -origin "$x $y"
    } else {
      make name_net_s -name $net -origin "$x $y"
    }

    set TERMS($term_id) $net

  } else {
    puts "ERROR: can't find port \"$port\" on instance \"$inst_name\" to attach net \"$net\" to."
  }
}


# Uses a simple algorithm based on the bounding box of the
# entire net (doesn't care about input or outputs) to compute
# the congestion.

proc simple_compute_congestion {} {

  global cur_s DPC_NETS CONGESTION DPC_CONGESTION

  if {![is_placement $cur_s] && ![is_fp $cur_s]} {
    # must run from placement
    warning "Aborting, must run congestion from a placement view."
    return ""
  }

  puts "Computing congestion ..."

  setl {x1 y1 x2 y2} [nl_get_die_area -grids]
  set bbox "$y1 $x1 $y2 $x2"

  # rest the congestion array
  catch {unset CONGESTION}

  set xcg [expr round($DPC_CONGESTION(tracks_per_xgrid))]
  set ycg [expr round($DPC_CONGESTION(tracks_per_ygrid))]
#  set xcg2 [expr $xcg/2]
#  set ycg2 [expr $ycg/2]
  set xcg2 0
  set ycg2 0

  # zero congestion array
  setl {xmin ymin xmax ymax} $bbox
  set xmin [expr (round($xmin)/$xcg)*$xcg + $xcg2]
  set xmax [expr (round($xmax)/$xcg)*$xcg + $xcg2]
  set ymin [expr (round($ymin)/$ycg)*$ycg + $ycg2]
  set ymax [expr (round($ymax)/$ycg)*$ycg + $ycg2]

  for {set i $xmin} {$i <= $xmax} {incr i $xcg} {
    for {set j $ymin} {$j <= $ymax} {incr j $ycg} {
      set CONGESTION($i,$j,x) 0
      set CONGESTION($i,$j,y) 0
    }
  }

  # now fill congestion array
  foreach net [nl_list_nets -hier -noassign -noconstant] {

    catch {unset xmin}

    # walk thru each pin on each net.
    foreach pin [nl_get_net_pins -recursive -noassign $net] {

      if {[catch {nl_get_pin_location -grids $pin} xy]} {
	# not defined -- maybe a top leve I/O, ignore
	continue
      }

      set y [lindex $xy 0]
      set x [lindex $xy 1]

      if {[info exists xmin]} {
	set xmin [min $x $xmin]
	set xmax [max $x $xmax]
	set ymin [min $y $ymin]
	set ymax [max $y $ymax]

      } else {
	set xmin $x
	set xmax $x
	set ymin $y
	set ymax $y
      }
    }

    if {![info exists xmin] || ($xmin == $xmax && $ymin == $ymax)} {
      # probably a top-level I/O
      continue
    }

    set xmin [expr (round($xmin)/$xcg)*$xcg + $xcg2]
    set xmax [expr (round($xmax)/$xcg)*$xcg + $xcg2]
    set ymin [expr (round($ymin)/$ycg)*$ycg + $ycg2]
    set ymax [expr (round($ymax)/$ycg)*$ycg + $ycg2]

    set xinc [expr 1.0*$xcg/($xcg + $xmax - $xmin)]
    set yinc [expr 1.0*$ycg/($ycg + $ymax - $ymin)]

    for {set i $xmin} {$i <= $xmax} {incr i $xcg} {
      for {set j $ymin} {$j <= $ymax} {incr j $ycg} {
	set CONGESTION($i,$j,x) [expr $CONGESTION($i,$j,x) + $yinc]
	set CONGESTION($i,$j,y) [expr $CONGESTION($i,$j,y) + $xinc]
      }
    }
  }

  puts "done."
}


# Colors per half resource limit (i.e. 2 colors like green and yellow
# till you get to limit)
set DPC_CONGESTION(display,colors) "green yellow red violet pink white"

proc display_congestion {{-scale 0.6} {-histogram}} {

  global cur_s

  if {[is_fp $cur_s]} {
    display_congestion_no_rotate $scale $histogram

  } else {
    display_congestion_rotate $scale $histogram
  }
}


proc display_congestion_rotate {scale histogram} {

  global DPC_CONGESTION cur_c

  api_clear_annotations gr

  puts "Displaying Congestion ..."

  set miny [expr int($DPC_CONGESTION(display,ythreshold) * \
		$DPC_CONGESTION(tracks_per_ygrid) * \
		$DPC_CONGESTION(resources_per_ytrack))]
  set minx [expr int( $DPC_CONGESTION(display,xthreshold) * \
		$DPC_CONGESTION(tracks_per_xgrid) * \
		$DPC_CONGESTION(resources_per_xtrack))]

  set limitx [expr int(ceil($DPC_CONGESTION(resources_per_xtrack) * \
		 $DPC_CONGESTION(tracks_per_xgrid) / 2.0))]
  set limity [expr int(ceil($DPC_CONGESTION(resources_per_ytrack) * \
		 $DPC_CONGESTION(tracks_per_ygrid) / 2.0))]

  #puts "min: h=$minx v=$miny, limit: h=$limitx v=$limity"

  if {[use_first DPC_CONGESTION(display,histogram)] == 1 || $histogram} {
    set histogram 1
  }

  if {$histogram} {
    # get all for histogram
    gr_grid 0 0
  } else {
    gr_grid $miny $minx
  }

  # scale is 10
  set xgg [expr $DPC_CONGESTION(tracks_per_ygrid) * 10]
  set ygg [expr $DPC_CONGESTION(tracks_per_xgrid) * 10]

  api_zoom setup

  set minnx [max [expr $minx - 0.5] 0.5]
  set minny [max [expr $miny - 0.5] 0.5]

  set maxhist [expr [max $DPC_CONGESTION(tracks_per_xgrid) $DPC_CONGESTION(tracks_per_ygrid)] * 20]

  # build color array, init histogram
  set colors $DPC_CONGESTION(display,colors)
  set max_colors [expr [llength $colors] - 1]
  for {set i 0} {$i < $maxhist} {incr i} {
    set colorx($i) [lindex $colors [min $max_colors [expr ($i-1) / $limitx]]]
    set colory($i) [lindex $colors [min $max_colors [expr ($i-1) / $limity]]]
    set hist_h($i) 0
    set hist_v($i) 0
  }
  # this one isn't right
  set colorx(0) [lindex $colors 0]
  set colory(0) [lindex $colors 0]

#  global CONGESTION
#  foreach s [array names CONGESTION] {}
#    setl {x y dir} [split $s ,]
#    set a "[expr $y/10] [expr $x/10] $CONGESTION($x,$y,y) $CONGESTION($x,$y,x)"

  while {1} {
    # too slow
    #setl {x y v h} [gr_grid_iter]
    set a [gr_grid_iter]

    set x [lindex $a 0]
    set y [lindex $a 1]

    if {$x == ""} {
      # done
      break
    }

    set v [lindex $a 2]
    set h [lindex $a 3]

    if {$v < 0 || $h < 0} {
      puts "GR ERROR: $a"
      continue
    }

    incr hist_h($h)
    incr hist_v($v)

    #puts "$x $y $v $h"

#   reload dpc_utils; time display_congestion

    # TODO: scale tmp__gr by xgg and ygg

    if {$h > $minnx} {

      set color $colorx($h)
      set yy [expr $y * $xgg]
      set xx [expr ($x + 0.5)*$ygg]
      set hh [expr $h * $scale]

      $cur_c create rectangle $yy [expr $xx - $hh] \
	  [expr $yy + $xgg] [expr $xx + $hh] \
	  -tags "tmp__gr tmp_all" -fill $color -outline $color

#      api_annotate_filled_rect -coords \
	  [list $yy [expr $xx - $hh] \
	       [expr $yy + $xgg] [expr $xx + $hh] ] \
	  -fill $color -outline $color -tags gr
    }

    if {$v > $minny} {

      set color $colory($v)
      set xx [expr $x * $ygg]
      set yy [expr ($y + 0.5)*$xgg]
      set vv [expr $v * $scale]

      $cur_c create rectangle [expr $yy - $vv] $xx \
	  [expr $yy + $vv] [expr $xx + $ygg] \
	  -tags "tmp__gr tmp_all" -fill $color -outline $color

#      api_annotate_filled_rect -coords \
	  [list [expr ($y+0.5)*$xgg-$v*$scale] [expr $x*$ygg] \
	       [expr ($y+0.5)*$xgg+$v*$scale] [expr ($x+1)*$ygg] ] \
	  -fill $color -outline $color -tags gr
    }
  }

  if {$histogram} {
    # add histogram
    setl {x1 y1 x2 y2} [api_bbox]

    set x [expr $x1 - 80]
    set yt [expr $y1 + 120]

    set mhist [max [expr abs($y2-$y1)/2] 1000]
  
    for {set i 0} {$i < $maxhist} {incr i} {
      if {$hist_h($i) > 0} {
	set color $colorx($i)

	api_annotate_filled_rect -coords \
	    [list $x [expr $yt + $i*40 - 5] \
		 [expr $x - [min $hist_h($i) $mhist]] [expr $yt + $i*40 + 5]] \
	    -fill $color -outline $color -tags gr
      }
    }

    set y [expr $y2 - 40]
    for {set i 0} {$i < $maxhist} {incr i} {
      if {$hist_v($i) > 0} {
	set color $colory($i)

	api_annotate_filled_rect -coords \
	    [list [expr $x - $i*40 - 5] $y \
		 [expr $x - $i*40 + 5] [expr $y - [min $hist_v($i) $mhist]]] \
	    -fill $color -outline $color -tags gr
      }
    }
  }

  api_zoom restore
  puts "done."
}


proc display_congestion_no_rotate {scale histogram} {

  global DPC_CONGESTION

  api_clear_annotations gr

  puts "Displaying Congestion ..."

  set miny [expr int($DPC_CONGESTION(display,ythreshold) * \
		$DPC_CONGESTION(tracks_per_ygrid) * \
		$DPC_CONGESTION(resources_per_ytrack))]
  set minx [expr int( $DPC_CONGESTION(display,xthreshold) * \
		$DPC_CONGESTION(tracks_per_xgrid) * \
		$DPC_CONGESTION(resources_per_xtrack))]

  set limitx [expr int(ceil($DPC_CONGESTION(resources_per_xtrack) * \
		 $DPC_CONGESTION(tracks_per_xgrid) / 2.0))]
  set limity [expr int(ceil($DPC_CONGESTION(resources_per_ytrack) * \
		 $DPC_CONGESTION(tracks_per_ygrid) / 2.0))]

  #puts "min: h=$minx v=$miny, limit: h=$limitx v=$limity"

  if {[use_first DPC_CONGESTION(display,histogram)] == 1 || $histogram} {
    set histogram 1
  }

  if {$histogram} {
    # get all for histogram
    gr_grid 0 0
  } else {
    gr_grid $miny $minx
  }

  # scale is 10
  set xgg [expr $DPC_CONGESTION(tracks_per_xgrid) * 10]
  set ygg [expr $DPC_CONGESTION(tracks_per_ygrid) * 10]

  api_zoom setup

  set minnx [max [expr $minx - 0.5] 0.5]
  set minny [max [expr $miny - 0.5] 0.5]

  set maxh $minnx
  set maxv $minny

  # build color array, init histogram
  set colors $DPC_CONGESTION(display,colors)
  set max_colors [expr [llength $colors] - 1]
  for {set i 0} {$i < 500} {incr i} {
    set colorx($i) [lindex $colors [min $max_colors [expr ($i-1) / $limitx]]]
    set colory($i) [lindex $colors [min $max_colors [expr ($i-1) / $limity]]]
    set hist_h($i) 0
    set hist_v($i) 0
  }
  # this one isn't right
  set colorx(0) [lindex $colors 0]
  set colory(0) [lindex $colors 0]

    while {1} {
    # too slow
    #setl {x y v h} [gr_grid_iter]
    set a [gr_grid_iter]

    set x [lindex $a 0]
    set y [lindex $a 1]

    if {$x == ""} {
      # done
      break
    }

    if {[lindex $a 2] < -0.01 || [lindex $a 3] < -0.01} {
      puts "GR ERROR: $a"
      continue
    }

    set h [expr int(ceil([lindex $a 2]))]
    set v [expr int(ceil([lindex $a 3]))]

    incr hist_h($h)
    incr hist_v($v)

    #puts "$x $y $h $v"

    if {$h > $minnx} {

      set maxh [max $maxh $h]
      set color $colorx($h)

      api_annotate_filled_rect -coords \
	  [list [expr $x*$xgg] [expr (-0.5-$y)*$ygg-$h*$scale] \
	       [expr ($x+1)*$xgg] [expr (-0.5-$y)*$ygg+$h*$scale] ] \
	  -fill $color -outline $color -tags gr
    }

    if {$v > $minny} {

      set maxv [max $maxv $v]
      set color $colory($v)

      api_annotate_filled_rect -coords \
	  [list [expr ($x+0.5)*$xgg-$v*$scale] [expr -$y*$ygg] \
	       [expr ($x+0.5)*$xgg+$v*$scale] [expr (-1-$y)*$ygg] ] \
	  -fill $color -outline $color -tags gr
    }
  }

  if {$histogram} {
    # add histogram
    setl {x1 y1 x2 y2} [api_bbox]

    set x [expr $x1 - 80]
    set yt [expr $y1 + 120]

    set mhist [max [expr abs($y2-$y1)/2] 1000]
  
    for {set i 0} {$i <= $maxh} {incr i} {
      if {$hist_h($i) > 0} {
	set color $colorx($i)

	api_annotate_filled_rect -coords \
	    [list $x [expr $yt + $i*40 - 5] \
		 [expr $x - [min $hist_h($i) $mhist]] [expr $yt + $i*40 + 5]] \
	    -fill $color -outline $color -tags gr
      }
    }

    set y [expr $y2 - 40]
    for {set i 0} {$i <= $maxv} {incr i} {
      if {$hist_v($i) > 0} {
	set color $colory($i)

	api_annotate_filled_rect -coords \
	    [list [expr $x - $i*40 - 5] $y \
		 [expr $x - $i*40 + 5] [expr $y - [min $hist_v($i) $mhist]]] \
	    -fill $color -outline $color -tags gr
      }
    }
  }

  api_zoom restore
#  puts "$maxh $maxv"
  puts "done."
}


# If one, shows grid
set DPC_CONGESTION_DEBUG [use_first DPC_CONGESTION_DEBUG '0]

# Pops up a menu to control viewing the congestion
# then runs

proc compute_congestion {{-nomenu}} {

  global cur_s cur_c DPC_CONGESTION NETLIST DPC DPC_CONGESTION_DEBUG

  if {![is_placement $cur_s] && ![is_fp $cur_s]} {
    # must run from placement
    warning "Aborting, must run congestion from a placement view."
    return ""
  }

  regsub "_placement$" $cur_s "" schematic
  regsub "_fp$" $schematic "" schematic
  if {$schematic != $NETLIST(root)} {
    warning "Aborting, must run from placement view of last dpc schematic ($NETLIST(root))."
    return ""
  }

  set DPC_CONGESTION(tracks_per_xgrid) \
      [use_first DPC_CONGESTION(tracks_per_xgrid) DPC(PITCH) '10]
  set DPC_CONGESTION(tracks_per_ygrid) \
      [use_first DPC_CONGESTION(tracks_per_ygrid) DPC(DEFAULT_ROW_HEIGHT) '10]

  set DPC_CONGESTION(resources_per_xtrack) \
      [use_first DPC_CONGESTION(resources_per_xtrack) '2]
  set DPC_CONGESTION(resources_per_ytrack) \
      [use_first DPC_CONGESTION(resources_per_ytrack) '2]

  # In percentage of resources per grid
  set DPC_CONGESTION(display,xthreshold) \
      [use_first DPC_CONGESTION(display,xthreshold) '0.25]
  set DPC_CONGESTION(display,ythreshold) \
      [use_first DPC_CONGESTION(display,ythreshold) '0.25]

  set DPC_CONGESTION(display,histogram) \
      [use_first DPC_CONGESTION(display,histogram) '1]

  set save_tracks_per_xgrid $DPC_CONGESTION(tracks_per_xgrid)
  set save_tracks_per_ygrid $DPC_CONGESTION(tracks_per_ygrid)
  set save_resources_per_xtrack $DPC_CONGESTION(resources_per_xtrack)
  set save_resources_per_ytrack $DPC_CONGESTION(resources_per_ytrack)

  set redisplay_only 0
  set clear_congestion_only 0
  set set_grid 0

  if {!$nomenu} {
    # Menu

    set title "Congestion Setup:"
    set message "Options (DPC orientation):"

    set prop_list ""

    lappend prop_list [list "horizontal tracks per global grid" \
			   DPC_CONGESTION(tracks_per_xgrid) \
			   -number 1 -incr 1 -validate -entry \
			   -help "Size of horizontal global grid (rotated from def/layout orientation)."]

    lappend prop_list [list "vertical tracks per global grid" \
			   DPC_CONGESTION(tracks_per_ygrid) \
			   -number 1 -incr 1 -validate -entry \
			   -help "Size of vertical global grid (rotated from def/layout orientation)."]

    lappend prop_list [list "set sue grid to global grid" \
			     set_grid -binary \
			   -help "Sets the SUE grid to be the same as the global grid to aid in display."]

    lappend prop_list [list "horizontal routing resources per track" \
			   DPC_CONGESTION(resources_per_xtrack) \
			   -number 0.1 -incr 0.1 -entry \
			   -help "Metal tracks available for routing in the horizontal direction (rotated from def/layout orientation).  Typically, the number of vertical metal layers minus overhead for power, clock, etc."]

    lappend prop_list [list "vertical routing resources per track" \
			   DPC_CONGESTION(resources_per_ytrack) \
			   -number 0.1 -incr 0.1 -entry \
			   -help "Metal tracks available for routing in the vertical direction (rotated from def/layout orientation).  Typically, the number horizontal metal layers minus overhead for power, clock, etc."]

    lappend prop_list [list "" "" -separator]

    lappend prop_list [list "display horizontal threshold percent" \
			   DPC_CONGESTION(display,xthreshold) \
			   -number 0.0 -incr 0.1 -entry \
			   -help "When displaying horizontal congestion, don't display anything if the congestion is below this threshold.  The threshold in the percentage (/100) of the resources.  Making this number greater than 0, makes the display much faster and, sometimes, makes the output more readable."]

    lappend prop_list [list "display vertical threshold percent" \
			   DPC_CONGESTION(display,ythreshold) \
			   -number 0.0 -incr 0.1 -entry \
			   -help "When displaying vertical congestion, don't display anything if the congestion is below this threshold.  The threshold in the percentage (/100) of the resources.  Making this number greater than 0, makes the display much faster and, sometimes, makes the output more readable."]

    lappend prop_list [list "display histogram of congestion" \
			     DPC_CONGESTION(display,histogram) -binary \
			   -help "Displays a histogram of horizontal congestion and vetical congestion to the left of the design."]

    if {[use_first DPC_CONGESTION(computed)] == $NETLIST(root)} {
      lappend prop_list [list "redisplay congestion only" \
			     redisplay_only -binary \
			   -help "Redisplay already computed results with different display parameters."]
    }

    if {[llength [$cur_c find withtag tmp__gr]] > 0} {
      lappend prop_list [list "clear congestion only" \
			     clear_congestion_only -binary \
			   -help "Clear congestion from placement only."]
    }

    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
      # cancelled
      return ""
    }
  }

  if {$clear_congestion_only} {
    api_clear_annotations gr
    return ""
  }

  if {$redisplay_only} {
    # restore these to previous run
    set DPC_CONGESTION(tracks_per_xgrid) $save_tracks_per_xgrid
    set DPC_CONGESTION(tracks_per_ygrid) $save_tracks_per_ygrid
    set DPC_CONGESTION(resources_per_xtrack) $save_resources_per_xtrack
    set DPC_CONGESTION(resources_per_ytrack) $save_resources_per_ytrack

  } else {
    # now call the global router
    gr_command [lindex [nl_find_designs -exact $NETLIST(root)] 0] \
	$DPC_CONGESTION(tracks_per_xgrid) $DPC_CONGESTION(tracks_per_ygrid) \
	$DPC_CONGESTION(resources_per_xtrack) \
	$DPC_CONGESTION(resources_per_ytrack) $DPC_CONGESTION_DEBUG


    if {$set_grid} {
      global GRID_SPACING
      set GRID_SPACING "$DPC_CONGESTION(tracks_per_ygrid) $DPC_CONGESTION(tracks_per_xgrid)"

      global SUE_${cur_s}

      if {[info exists SUE_${cur_s}(grid)] == 1 && \
	      [set SUE_${cur_s}(grid)] != 0} {
	$cur_c delete grid
	make_grid $GRID_SPACING
      }
    }
  }

  # finally, display results
  display_congestion

  set DPC_CONGESTION(computed) $NETLIST(root)
}


proc display_utilization {} -desc {
  places a solid temporary annotation over each leaf cell in a 
dpc placement view, independent of expansion so one can easily
see where there is unused space.
} {

  global cur_s cur_c scale DPC DPC_SIZE COLORS

  if {![is_placement $cur_s]} {
    warning "Aborting, must be run from a placement."
    return -1
  }

  set save_scale $scale

  scale_canvas 1

  # walk thru each leaf cell
  foreach name [nl_list_cells -recursive -noassign -library] {

    setl {col row} [nl_get_cell_location $name]

    set col [expr $col / $DPC(xscale)]
    set row [expr $row / $DPC(yscale)]

    set type [nl_get_reference_name [nl_get_cell_reference $name]]
    setl {delta_col delta_row} $DPC_SIZE($type)

    # make a solid temporary annotation over cell area
    $cur_c create rect $row $col \
	[expr $row + $delta_row] [expr $col + $delta_col] \
	-tags "tmp" -fill $COLORS(anchor) -stipple gray50
  }

  # restore scale
  scale_canvas $save_scale
}


# serious hack to make really big things look better, go faster

proc remove_text {{all ""}} {

  global cur_s cur_c

  if {[string first placement $cur_s] == -1} {
    puts "Aborting, must be in placement file to remove text."
    return
  }

  # removes all instance names from placement view
  $cur_c delete size_small

  if {$all != ""} {
    # removes all instance types from placement view
    $cur_c delete size_standard
  }

  puts "Text removed.  Must renetlist and show placement again to see them."
}


proc is_placement {cell} -desc {
  Returns 1 if given cell is a placement file.
} {

  # placements have are of the form <cell>_placement
  if {[regexp _placement$ $cell]} {
    # yes
    return 1
  } else {
    # no
    return 0
  }
}


# For automatic cell placement

proc _bbox_of_placement {{units millimicrons}} -desc {
  compute the bounding box from a placement view

} {

  global cur_c scale DPC

  setl {xscale yscale} [concat $DPC(SCALE) $DPC(SCALE)]
  set DPC(xscale) [expr round($xscale * $DPC(UNITS))]
  set DPC(yscale) [expr round($yscale * $DPC(UNITS))]

  # remove tmp, annotations
  $cur_c delete tmp

  set save_scale $scale
  if {$save_scale != 1} {
    scale_canvas 1
  }

  # start with everything
  $cur_c addtag bbox all

  # ignore text, grid, wire
  $cur_c dtag scaletext bbox
  $cur_c dtag grid bbox
  $cur_c dtag wire bbox
  $cur_c dtag open bbox
  $cur_c dtag dot bbox

  # ignore I/O's and name nets
  foreach toss "input output inout name_net name_net_s name_net_sw" {
    foreach id [$cur_c find withtag icon_$toss] {
      $cur_c dtag inst$id bbox
    }
  }

  # now get bounding box of remaining
  setl {x1 y1 x2 y2} [round_list [$cur_c bbox bbox]]
  $cur_c dtag bbox

  if {$y2 == ""} {
    # empty
    return [scale_list "0 0 1 1" $mult]
  }

  # bbox adds 2 in all directions -- remove it
  if {$units == "grids"} {
    set bbox [round_list [list [expr ($y1 + 2)] [expr ($x1 + 2)] \
			      [expr ($y2 - 2)] [expr ($x2 - 2)]]]
  } else {
    set bbox [round_list [list [expr ($y1 + 2) * $DPC(xscale)] \
			      [expr ($x1 + 2) * $DPC(yscale)] \
			      [expr ($y2 - 2) * $DPC(xscale)] \
			      [expr ($x2 - 2) * $DPC(yscale)]]]
  }

  if {$save_scale != 1} {
    scale_canvas $save_scale
  }

  return $bbox
}



proc _write_port_file_from_placement {} -desc {
  create a ports file from a dpc placement.

  includes bbox and pins

} {

  global cur_s cur_c scale DPC XFORM VERSION SUFFIX

  # strip off placement from the cell name
  regsub {_placement$} $cur_s "" cell

  upvar #0 SUE_$cur_s data
  set filename "$data(dir)$cell$SUFFIX(dpc_ports)"

  # move old one if there is one to .BAK
  if {![catch "file rename -force -- $filename $filename$SUFFIX(backup)"]} {
    # success
  }

  if {[catch "open $filename w" FILE_ID]} {
    # problem
    puts "DPC ERROR: $FILE_ID"
    return
  } 

  puts $FILE_ID "\# Created by $VERSION from placement of $cell\n"

  set save_scale $scale
  scale_canvas 1

  setl {x1 y1 x2 y2} [_bbox_of_placement grids]

  # need to remove any halo
  setl {xhalo yhalo} [concat $DPC(HALO) $DPC(HALO)]
  set x1 [expr $x1 + $xhalo]
  set y1 [expr $y1 + $yhalo]
  set x2 [expr $x2 - $xhalo]
  set y2 [expr $y2 - $yhalo]

  puts $FILE_ID "bbox [expr $x2 - $x1] [expr $y2 - $y1]\n"

  # TODO HALO
  foreach id [concat [$cur_c find withtag icon_input] \
		  [$cur_c find withtag icon_output] \
		  [$cur_c find withtag icon_inout]] {

      upvar #0 ${cur_s}_inst$id i_data
      setl {x y} [$cur_c coords $id]

      puts $FILE_ID "port $i_data(_name) [format %.1f $y] [format %.1f $x]"
    }

  # close the file
  close $FILE_ID

  scale_canvas $save_scale

  puts "Wrote ports file $filename"
}


proc _write_def_from_placement {} -desc {
  write a def file from a dpc placement (i.e. export DEF).

  NOTE: adds rows statements

} {

  global cur_s cur_c scale DPC XFORM VERSION SUFFIX SUE_DIR

  setl {xscale yscale} [concat $DPC(SCALE) $DPC(SCALE)]
  set DPC(xscale) [expr round($xscale * $DPC(UNITS))]
  set DPC(yscale) [expr round($yscale * $DPC(UNITS))]

  # strip off placement from the cell name
  regsub {_placement$} $cur_s "" cell

  upvar #0 SUE_$cur_s data
  set filename "$data(dir)$cell.place.def"

  if {[catch "open $filename w" FILE_ID]} {
    # problem
    puts "DPC ERROR: $FILE_ID"
    return
  } 

  set save_scale $scale
  scale_canvas 1

  set units 1000

  puts $FILE_ID "DESIGN $cell ;\n"

  puts $FILE_ID "HISTORY Created by $VERSION from $data(dir)$cur_s$SUFFIX(default) ;\n"

  puts $FILE_ID "UNITS DISTANCE MICRONS $units ;\n"

  setl {minx miny maxx maxy} [_bbox_of_placement]
  puts $FILE_ID "DIEAREA ( $minx $miny ) ( $maxx $maxy ) ;\n"

  setl {xoffset yoffset} [concat $DPC(TRACK_OFFSET) $DPC(TRACK_OFFSET)]

  foreach track $DPC(TRACKS) {
    if {[lindex $track 0] == "Y"} {
      # a Y (vertical) routing track
      set num [expr round( ($maxy - $miny) / $DPC(yscale) )]
      set grid_units $DPC(xscale)
      set offset [expr round( $yoffset * $DPC(yscale) + $miny )]

    } else {
      # a X (horizontal) routing track
      set num [expr round( ($maxx - $minx) / $DPC(xscale) )]
      set grid_units $DPC(yscale)
      set offset [expr round( $xoffset * $DPC(xscale) + $minx )]
    }

    puts $FILE_ID "TRACKS [lindex $track 0] $offset DO $num STEP $grid_units LAYER [lrange $track 1 end] ;"
  }

  # rows are the default cell height
  set count 0

  set delta_row [expr $DPC(DEFAULT_ROW_HEIGHT)*$DPC(xscale)]
  set row [expr round(ceil(1.0*$miny/$delta_row)) * $delta_row]

  # ROW ROW_01 CORE1 0 0 N DO 192 BY 1 STEP 1000 10000 ;
  # TODO: add to .suerc, globals
  set row_type [use_first DPC(row_type) 'CORE1]

  # subtract the DPC(HALO) from rows
  setl {xhalo yhalo} [concat $DPC(HALO) $DPC(HALO)]

  set minx [expr $minx + $xhalo * $DPC(xscale)]
  set miny [expr $miny + $yhalo * $DPC(yscale)]
  set maxx [expr $maxx - $xhalo * $DPC(xscale)]
  set maxy [expr $maxy - $yhalo * $DPC(yscale)]

  puts $FILE_ID ""

  # want N,S not N,FS
  regsub -all {[fF]} $DPC(FLIP) "" flips

  set xtracks [expr ($maxx - $minx) / $DPC(xscale)]
  for {set count 0} {[expr $row + $delta_row] <= $maxy } \
      {incr count ; incr row $delta_row} {
    set flip [lindex $flips [expr $count % 2]]
    puts $FILE_ID "ROW ROW_$count $row_type $minx $row $flip DO $xtracks BY 1 STEP $DPC(xscale) $delta_row ;"
  }

  puts $FILE_ID ""

  set comps ""
  set hier 0
  foreach id [$cur_c find withtag origin] {
    if {[is_tagged $id icon__place_*]} {
      lappend comps $id

      # check if hierarchical
      upvar #0 ${cur_s}_inst$id i_data
      if {[regexp _H$ $i_data(type)]} {
	set hier 1
      }
    }
  }

  if {$hier} {
    set button [tk_dialog .prompt "Hierarchcical Cells" \
		    "Warning: the placement contains hierarchical cells.  Typically you should remove by Selecting and Push Into." \
		    @$SUE_DIR/sue_icon.xbm 0 {Cancel} {Continue}]

    if {$button == 0} {
      # user hit the cancel key

      # restore scale
      scale_canvas $save_scale

      return
    }
  }

  if {[llength $comps] != 0} {
    puts $FILE_ID "COMPONENTS [llength $comps] ;"

    # - MMI_FFCB$7$ MMI_FFCB + PLACED ( 22000 90000 ) FS ;
    foreach id $comps {
      upvar #0 ${cur_s}_inst$id i_data
      setl {y x} [round_list [$cur_c coords $id]]

      # must unrotate to get origin
      setl {tmp1 tmp2 dy dx} [split $i_data(type) _]

      switch $i_data(orient) {
	R0 {
	  # correct orientation
	}
	RX {
	  set y [expr $y - $dy]
	}
	RY {
	  set x [expr $x - $dx]
	}
	RXY {
	  set x [expr $x - $dx]
	  set y [expr $y - $dy]
	}
      }

      puts $FILE_ID "- $i_data(_instance) $i_data(_name) + $DPC(PLACE) ( [expr $x * $DPC(xscale)] [expr $y * $DPC(yscale)] ) $XFORM(def,$i_data(orient)) ;"
    }

    puts $FILE_ID "END COMPONENTS\n"
  }

  # adds any I/O's as pins like:
  # - A[31] + NET A[31] + PLACED ( 1500 -1000 ) N ;

  # TODO: add USE SIGNAL and pin size/layer

  set ios [concat [$cur_c find withtag icon_input] \
	       [$cur_c find withtag icon_output] \
	       [$cur_c find withtag icon_inout]]

  if {[llength $ios] != 0} {
    # got pins
    puts $FILE_ID "PINS [llength $ios] ;"

    foreach id $ios {
      upvar #0 ${cur_s}_inst$id i_data

      setl {y x} [$cur_c coords $id]

      set x [expr round($x * $DPC(xscale))]
      set y [expr round($y * $DPC(yscale))]

      puts $FILE_ID "- $i_data(_name) + NET $i_data(_name) + DIRECTION [string toupper $i_data(type)] + PLACED ( $x $y ) $XFORM(def,$i_data(orient)) ;"
    }

    puts $FILE_ID "END PINS\n"
  }

  puts $FILE_ID "END DESIGN"

  # restore scale
  scale_canvas $save_scale

  # close the file
  close $FILE_ID

  puts "Wrote placement file to $filename"
}


proc _build_filename {type} -desc {

  called from _build_bbox_ports.  computes a new filename.

} {

  global DPC_BUILD

  if {$DPC_BUILD(file,from) != $DPC_BUILD(type)} {
    # user changed, so recompute
    set dir [find_dir_of_cell $type]

    switch $DPC_BUILD(type) {
      "def file" {
	set DPC_BUILD(file) $dir/$type.place.def
	set DPC_BUILD(file,from) $DPC_BUILD(type)
      }
      "verilog gate area" {
	set DPC_BUILD(file) $dir/$type.vg
	set DPC_BUILD(file,from) $DPC_BUILD(type)
      }
    }
  }
}  


proc _build_bbox_ports {} -desc {

  starts with selected instance and tries to build best bbox/ports 
  for autoplace.  

  choice of bbox from
    1. placement
    2. ports file
    3. def file
    4. add up gate areas in verilog

  NOT RIGHT

  choice of pins from
    1. connected port locations
    2. icon port locations
    3. schematic port locations if there is one

  

  uses surrounding net connections if possible otherwise, port
  orientation and bit pitch.


} {

  global cur_s cur_c scale NETLIST DPC DPC_BUILD DPC_SIZE DPC_ABS

  # only one at a time
  set id [$cur_c find withtag selected&origin]

  if {[llength $id] != 1} {
    warning "Aborting, must select one icon to build ports for."
    return
  }

  upvar #0 ${cur_s}_inst$id i_data
  set type $i_data(type)

  # save away terminal directions for later
  # TODO: save orientation of ports for placement file
  foreach term_id [get_intersect_tag inst$id term] {
    set tags [$cur_c gettags $term_id]
    set term_list [lindex $tags [lsearch $tags "name*"]]
    set term_name [lindex [split [lindex $term_list 3] \[] 0]
    set term_dirs($term_name) [lindex $term_list 2]
  }

  # MAYBE add
  # If icon has a bused port of size x on both left and right sides,
  # Use this as number of bit pitches for the height

  set title "Bounding Box"
  set message "Get Bounding Box from:"

  set prop_list ""

  if {[use_first DPC_BUILD(cell)] != $type} {
    # new cell, reset
    set DPC_BUILD(file,from) ""
  }

  set default "dpc placement"
  set DPC_BUILD(type) [use_first DPC_BUILD(bbox_type) DPC_BUILD(type) default]
  set DPC_BUILD(file) [use_first DPC_BUILD(file)]
  set DPC_BUILD(file,from) [use_first DPC_BUILD(file,from)]
  _build_filename $type

  set DPC_BUILD(cell) $type

  set DPC_BUILD(pattern,verilog\ gate\ area) *.v*
  set DPC_BUILD(pattern,def\ file) *.def

  # TODO: helps
  lappend prop_list [list "what" DPC_BUILD(type) \
			 -radio {"dpc placement" "ports file" "def file" "verilog gate area"} \
			 -reload -command "_build_filename $type" \
			 -help "foo."]

  set DPC_BUILD(subtract_halo) [use_first DPC_BUILD(subtract_halo) DPC(HALO)]
  lappend prop_list [list "subtract halo" DPC_BUILD(subtract_halo) -entry \
			 -when {$DPC_BUILD(type) != "verilog gate area"} \
			 -help "Subtract this halo from bbox."]

  set DPC_BUILD(add_halo) [use_first DPC_BUILD(add_halo) DPC(HALO)]
  lappend prop_list [list "add halo" DPC_BUILD(add_halo) -entry \
			 -help "Add this halo to the bbox."]

  lappend prop_list [list "file" DPC_BUILD(file) \
			 -filename "-pattern $DPC_BUILD(pattern,def\ file)" \
			 -when {$DPC_BUILD(type) == "def file"}]

  lappend prop_list [list "file" DPC_BUILD(file) \
			 -filename "-pattern $DPC_BUILD(pattern,verilog\ gate\ area)" \
			 -when {$DPC_BUILD(type) == "verilog gate area"} \
			 -help "Verilog file to read to compute gate area."]

  set DPC_BUILD(utilization) [use_first DPC_BUILD(utilization) '0.8]
  lappend prop_list [list "utilization" DPC_BUILD(utilization) \
			 -number 0.1 1.0 -incr 0.1 \
			 -when {$DPC_BUILD(type) == "verilog gate area"} \
			 -help "bar."]

  set DPC_BUILD(pitches) [use_first DPC_BUILD(pitches) '10]
  lappend prop_list [list "pitches tall" DPC_BUILD(pitches) \
			 -number 1 -incr 1 \
			 -when {$DPC_BUILD(type) == "verilog gate area"} \
			 -help "baz."]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }
  
  set save_dpc_size [use_first DPC_SIZE($type)]

  # get the bbox -- put into DPC_SIZE
  switch $DPC_BUILD(type) {
    "dpc placement" {
      set save_cur_s $cur_s
      goto_schematic ${type}_placement
      if {$cur_s != "${type}_placement"} {
	warning "Aborting, couldn't find cell ${type}_placement"
	return 
      }

      # now get the bbox out of this
      setl {x1 y1 x2 y2} [_bbox_of_placement]
      set width [expr round(ceil( ($y2 - $y1) /$DPC(yscale)))]

      # compute flip -- odd number of rows
      set flip [expr ($width % (2 * $DPC(DEFAULT_ROW_HEIGHT))) > 0]

      set DPC_SIZE($type) [list [expr round(ceil( ($x2 - $x1) /$DPC(xscale)))] \
			       $width $flip]

      # return to where we were
      goto_schematic $save_cur_s
    }

    "ports file" {
      if {![lookup_size $type $type]} {
	# couldn't find a file
	if {![info exists DPC_SIZE $type]} {
	  # toast
	  # TODO
	  xxx
	}
      }
    }

    "def file" {
      set filename $DPC_BUILD(file)
      puts "Parsing $filename ..."
      if {[catch "open $filename r" FILE_ID]} {
	warning $FILE_ID
	return
      }

      # look for DIEAREA line
      # DIEAREA ( -2000 -2000 ) ( 200000 102000 ) ;

      set dx -1
      while {[gets $FILE_ID line] >= 0} {
	if {[string first DIEAREA [string trimleft $line]] == 0} {
	  # found it
	  set dx [expr [lindex $line 6] - [lindex $line 2]]
	  set dy [expr [lindex $line 7] - [lindex $line 3]]

	  break
	}
      }

      # close the file
      close $FILE_ID

      if {$dx == -1} {
	warning "Aborting, can't find the die area in file $filename"
	return
      }

      set width [expr round(ceil($dy/$DPC(yscale)))]

      # compute flip -- odd number of rows
      set flip [expr ($width % (2 * $DPC(DEFAULT_ROW_HEIGHT))) > 0]

      set DPC_SIZE($type) [list [expr round(ceil($dx/$DPC(xscale)))] \
			       $width $flip]
    }

    "verilog gate area" {
      # read with nl
      global current_design

      if {[info exists current_design]} {
	set save_current_design $current_design
      } else {
	set save_current_design ""
      }

      # reset the nl database
      catch "nl_remove_design -silent $type"

      if {[catch {nl_read_verilog $DPC_BUILD(file)} msg]} {
	puts "Aborting, $msg"

	set current_design $save_current_design
	return 
      }
      
      nl_link -silent

      # get gate size information
      get_gate_sizes

      # add up the areas
      set area 0
      # NOTE: unlinked possibility
      foreach cell [nl_list_cells -recursive -library -noassign -unlinked] {

	set ref [nl_get_cell_reference $cell]

	if {![info exists DPC_SIZE($ref,file)]} {
	  # look in the file <cell>.ports for cell size and port locations
	  lookup_size $ref $ref

	  if {![info exists DPC_SIZE($ref)]} {
	    puts "DPC BUILD WARNING: can't find a size for cell $ref, skipping."
	    continue
	  }
	}

#	puts "$cell ($ref) --> [use_first DPC_SIZE($ref)]"

	# NOTE: in grids^2
	incr area [expr [lindex $DPC_SIZE($ref) 0] * [lindex $DPC_SIZE($ref) 1]]
      }

      if {$save_current_design != ""} {
	set current_design $save_current_design
      }

      # compute width and height (SUE orient)
      set height [expr $DPC_BUILD(pitches) * $DPC(PITCH)]
      set width [expr round(ceil(1.0 * ($area / $DPC_BUILD(utilization)) / \
				     $height))]
      # round up to row height
      set width [expr round(ceil($width / $DPC(DEFAULT_ROW_HEIGHT))) * \
		     $DPC(DEFAULT_ROW_HEIGHT)]

      # compute flip -- odd number of rows
      set flip [expr ($width % (2 * $DPC(DEFAULT_ROW_HEIGHT))) > 0]

      set DPC_SIZE($type) [list $height $width $flip]
    }
  }

  # save this type 
  set DPC_BUILD(bbox_type) $DPC_BUILD(type) 

  if {$DPC_BUILD(type) != "verilog gate area"} {
    # subtract halo
    setl {height width flip} $DPC_SIZE($type)

    setl {x y} [concat $DPC_BUILD(subtract_halo) $DPC_BUILD(subtract_halo)]

    set height [expr $height - 2 * $y]
    set width [expr $width - 2 * $x]

    set DPC_SIZE($type) [list $height $width $flip]
  }

#  puts "$type --> $DPC_SIZE($type)"

  # now to find where to get the pins from

  set title "Top Level Pins"
  set message "Get Pins from:"

  set prop_list ""

  # TODO: helps
#  lappend prop_list [list "what" DPC_BUILD(type) \
			 -radio {"dpc placement" "ports file" "def file" "icon" "pin optimize"} \
			 -reload -command "_build_filename $type" \
			 -help "foo."]

  lappend prop_list [list "what" DPC_BUILD(type) \
			 -radio {"ports file" "icon" "pin optimize"} \
			 -reload -command "_build_filename $type" \
			 -help "foo."]

  lappend prop_list [list "file" DPC_BUILD(file) \
			 -filename "-pattern $DPC_BUILD(pattern,def\ file)" \
			 -when {$DPC_BUILD(type) == "def file"}]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  # put ports into DPC_SIZE like lookup_size
  # set DPC_SIZE($type,port,<port_name>) <coords>

  setl {xoffset yoffset} [concat $DPC(TRACK_OFFSET) $DPC(TRACK_OFFSET)]
  setl {xhalo yhalo} [concat $DPC_BUILD(add_halo) $DPC_BUILD(add_halo)]

  switch $DPC_BUILD(type) {
    "dpc placement" {
      # TODO: put into DPC_SIZE ???
      # TODO move pins based on add halo and pin offset ???
    }

    "ports file" {
      # already done unless didn't choose ports file for bbox
      # TODO move pins based on add halo and pin offset ???
      lookup_size $type $type
    }

    "def file" {
      # TODO: parse
      
    }

    "icon" {
      # get pin orientations and locations from the icon.  Spread out
      # bused pins

      # goto the icon
      set save_cur_s $cur_s
      goto_schematic ICON_$type

      set save_scale $scale
      scale_canvas 10

# NOT USED???
      # get the bbox of icon for relative locations
#      $cur_c delete tmp
#      $cur_c addtag tmp withtag draw_item
#      $cur_c dtag scaletext tmp
#      setl {x1 y1 x2 y2} [$cur_c bbox tmp]
#      $cur_c dtag tmp


      # the bbox command tends to overestimate by 2 which is bad
#      set x1 [expr $x1 + 2]
#      set y1 [expr $y1 + 2]
#      set x2 [expr $x2 - 2]
#      set y2 [expr $y2 - 2]

#      set bit_pitches [expr round(ceil(1.0 * [lindex $DPC_SIZE($type) 0] / \
					   $DPC(PITCH)))]
# TILL HERE

      set max_pitch 1

      # sort from top to bottom, left to right
      foreach id [concat [$cur_c find withtag icon_input] \
		      [$cur_c find withtag icon_output] \
		      [$cur_c find withtag icon_inout]] {
	setl {x y} [round_list [$cur_c coords $id]]

	lappend sort($x) [list $y $id]
      }

      scale_canvas $save_scale		     

      # sort first in x then y
      foreach x [lsort -integer [array names sort]] {
	set current_pitch 0

	foreach pair [lsort -decreasing -integer -index 0 $sort($x)] {
	  set id [lindex $pair 1]

	  upvar #0 ${cur_s}_inst$id i_data
	  set name $i_data(_name)

	  # what edge? -- based on pin orientation only
	  if {[lsearch "R0 RY RX RXY" $i_data(orient)] != -1} {
	    if {($i_data(type) == "input" && \
		     [lsearch "R0 RY" $i_data(orient)] != -1) || \
		    ($i_data(type) != "input" && \
			 [lsearch "RX RXY" $i_data(orient)] != -1)} {
	      # left side
	      set side left

	    } else {
	      # right side
	      set side right
	    }

	  } else {
	    # vertical
	    if {($i_data(type) == "input" && \
		     [lsearch "R90 R90X" $i_data(orient)] != -1) || \
		    ($i_data(type) != "input" && \
			 [lsearch "R90Y R270" $i_data(orient)] != -1)} {
	      # top
	      set side top

	    } else {
	      # bottom side
	      set side bottom
	    }
	  }

	  if {[is_bus $name]} {
	    # bus, split across pitches if horizontal
	    if {[lsearch "R0 RY RX RXY" $i_data(orient)] != -1} {
	      # horizontal

	      foreach bit [bus_expand $name] {
		# add to pitch
		set pitch [lindex [split $bit \[\]] 1]
		set max_pitch [max $pitch $max_pitch]

		lappend pitches($side,$pitch) \
		    [list $bit $i_data(type) $i_data(orient)]
	      }
	      set current_pitch $pitch

	    } else {
	      # vertical
	      foreach bit [lreverse [bus_expand $name]] {
		lappend pitches($side,0) \
		    [list $bit $i_data(type) $i_data(orient)]
	      }
	    }
	    
	  } else {
	    # scalar, place relative to position on bbox
	    if {[lsearch "R0 RY RX RXY" $i_data(orient)] != -1} {
	      # horizontal
	      set pitch $current_pitch
	      lappend pitches($side,$pitch) \
		  [list $name $i_data(type) $i_data(orient)]

	    } else {
	      lappend pitches($side,0) \
		  [list $name $i_data(type) $i_data(orient)]
	    }
	  }
	}
      }

      # now place evenly inside of each pit pitch
      foreach pair [array names pitches] {
	setl {side pitch} [split $pair ,]
	
	if {[lsearch "right left" $side] != -1} {

	  set no_pitch 0
	  switch $side {
	    left {
	      set x [expr $xoffset - $xhalo]

	      if {[llength [array names pitches left,*]] == 1} {
		# no pitches
		set no_pitch 1
	      }

	    } 
	    right {
	      set x [expr [lindex $DPC_SIZE($type) 1] - $xoffset + $xhalo]

	      if {[llength [array names pitches right,*]] == 1} {
		# no pitches
		set no_pitch 1
	      }
	    }
	  }
	  
	  set length [expr 1 + [llength $pitches($pair)]]

	  set i 1
	  foreach list $pitches($pair) {
	    setl {bit dir orient} $list

	    if {$no_pitch} {
	      # no bit pitches, use entire edge
	      set dy [expr 1.0 * [lindex $DPC_SIZE($type) 0] / $length]
	      set y [expr [lindex $DPC_SIZE($type) 0] - \
			 round(1.0 * $i * $dy) + $yoffset]

	    } else {
	      set y [expr $DPC(PITCH) * ($max_pitch + 1 - $pitch) - \
			 round(1.0 * $i * $DPC(PITCH)/$length) + $yoffset]
	    }

	    set DPC_SIZE($type,port,$bit) [list $y $x]
	    
	    incr i
	  }

	} else {
	  # top/bottom -- no bit pitches

	  switch $side {
	    top {
	      set y [expr $yoffset - $yhalo]
	    } 
	    bottom {
	      set y [expr [lindex $DPC_SIZE($type) 0] - $yoffset + $yhalo]
	    }
	  }
	  
	  set length [expr 1 + [llength $pitches($pair)]]
	  set dx [expr 1.0 * [lindex $DPC_SIZE($type) 1] / $length]
	  set i 1

	  foreach list $pitches($pair) {
	    setl {bit dir orient} $list

	    set x [expr round(1.0 * $i * $dx) + $xoffset]
	    
	    set DPC_SIZE($type,port,$bit) [list $y $x]
	    
	    incr i
	  }
	}
      }

      # return to where we were
      goto_schematic $save_cur_s
    }

    "pin optimize" {

      if {![info exists NETLIST(root)]} {
	warning "Aborting, must netlist first."
	return
      }
  
      # get all of the ports of this guy
      upvar #0 TERMS_$cur_s TERMS

      if {![info exists TERMS($id)]} {
	warning "Aborting, must netlist first."
	return
      }

      # get netlist name of this icon
      set name $TERMS($id)

      # NOTE: ignore orient (assume N)
      if {[info exists DPC_ABS($name)]} {
	setl {tmp tmp2 abs_row abs_col delta_row delta_col orient} \
	    $DPC_ABS($name)
      } else {
	# base cell
	setl {abs_col abs_row} [nl_get_cell_location $name]
	set abs_row [expr $abs_row / $DPC(yscale)]
	set abs_col [expr $abs_col / $DPC(xscale)]

	set orient [nl_get_cell_orientation $name]

	setl {delta_col delta_row} [use_first save_dpc_size DPC_SIZE($type)]
      }

      # walk thru each pin of
      foreach pin [nl_get_cell_or_port_pins $name] {
	set pin_name [nl_get_pin_name $pin]
	set locs ""

	set net [nl_get_pin_net $pin]
	
	foreach to_pin [nl_get_net_pins -recursive -noassign $net] {	

	  set owner [nl_get_pin_owner $to_pin]	  
	  
	  if {[nl_object_type $owner] == "port"} {
	    # top level I/O
	    if {!$DPC(PINS)} {
	      # ignore
	      puts "WARNING: ignoring pin $owner.  Not connected to anything else."
	      continue
	    }

	    # add this pin
	    setl {y x} [nl_get_port_location $owner]
	    set x [expr 1.0 * $x / $DPC(xscale)]
	    set y [expr 1.0 * $y / $DPC(yscale)]

	    lappend locs [list $x $y]
	    continue
	  }
	  
	  if {[string first $name/ $owner/] == 0} {
	    # this pin comes from here, ignore
	    continue
	  }

	  lappend locs [_pin_location $to_pin]
	}

	if {[llength $locs] == 0} {
	  # TODO: need to do something else to figure this out
	  puts "Warning: Skipping pin $pin_name.  No data."
	  continue

	} else {
	  # got it
	  # TODO -- if multiple do something smarter
	  setl {x y} [lindex $locs 0]
	}

	# compute closest edge to existing bbox
	set x [expr $x - $abs_row]
	set y [expr $y - $abs_col]

	if {$x > 0 && $x < $delta_row} {
	  # above/below
	  if {$y < 0} {
	    # below
	    set DPC_SIZE($type,port,$pin_name) \
		[list [expr $yoffset - $yhalo] $x]
	  } else {
	    set DPC_SIZE($type,port,$pin_name) \
		[list [expr [lindex $DPC_SIZE($type) 0] - $yoffset + $yhalo] $x]
	  }

	} elseif {$y > 0 && $y < $delta_col} {
	  # left/right
	  if {$x < 0} {
	    # left
	    set DPC_SIZE($type,port,$pin_name) \
		[list $y [expr $xoffset - $xhalo]]

	  } else {
	    # right
	    set DPC_SIZE($type,port,$pin_name) \
		[list $y [expr [lindex $DPC_SIZE($type) 1] - $xoffset + $xhalo]]
	  }

	} else {
	  # put in corner
	  if {$x < 0} {
	    if {$y < 0} {
	      set DPC_SIZE($type,port,$pin_name) \
		  [list [expr $xoffset - $xhalo] [expr $yoffset - $yhalo]]
	    } else {
	      set DPC_SIZE($type,port,$pin_name) \
		  [list [expr [lindex $DPC_SIZE($type) 0] - $xoffset + $xhalo] \
		       [expr $yoffset - $yhalo]]
	    }
	  } else {
	    if {$y < 0} {
	      set DPC_SIZE($type,port,$pin_name) \
		  [list [expr $xoffset - $xhalo] \
		       [expr [lindex $DPC_SIZE($type) 1] - $yoffset + $yhalo]]
	    } else {
	      set DPC_SIZE($type,port,$pin_name) \
		  [list [expr [lindex $DPC_SIZE($type) 0] - $xoffset + $xhalo] \
		       [expr [lindex $DPC_SIZE($type) 1] - $yoffset + $yhalo]]
	    }
	  }
	}
      }
    }
  }

  # build placement cell
  show_placement $type

  # add the bbox and name
  # NOTE: scale is 10

  setl {cols rows flip} $DPC_SIZE($type)

  set maxx [expr 10 * ($cols+$xhalo)]
  set minx [expr 10 * (0-$xhalo)]
  set maxy [expr 10 * ($rows+$yhalo)]
  set miny [expr 10 * (0-$yhalo)]
  make_line $miny $minx $maxy $minx $maxy $maxx $miny $maxx $miny $minx
  make_text -origin "0 [expr $minx - 40]" -text "$type placement" -size large

  # add ports
  foreach port [array names DPC_SIZE $type,port,*] {
    set pin_name [lindex [split $port ,] 2]
    set term_name [lindex [split $pin_name \[] 0]
    set dir $term_dirs($term_name)

    setl {y x} $DPC_SIZE($port)
    set x [expr round(10 * $x)]
    set y [expr round(10 * $y)]

    # TODO
    set orient R0

    make $dir -name $pin_name -origin [list $x $y] -orient $orient
  }

  is_modified

  zoom_to_fit

  sue_error flush

  puts "done."

#   reload dpc_utils ;  _build_bbox_ports

}


proc make_placement_from_def {{filename ""}} -desc {

  Creates a placement view from a def file.

  NOTE: assumes millimicrons
} {

  global cur_s cur_c scale DPC DPC_SIZE XFORM

  set ignore_cells [use_first DPC(ignore_cells)]

  # Prompt for a file name
  if {$filename == ""} {
    set filename [fs_box -message "Enter DEF File:" -pattern *.def]
    
    # if nil, file selector box cancelled -- do nothing
    if {$filename == ""} { 
      return 
    }
  }

  if {[catch "open $filename r" FILE_ID]} {
    # error
    warning "Bad File: $FILE_ID"
    return
  } 

  busy

  setl {dir cell_name suffix} [split_filename $filename]
  if {$dir == ""} {
    set dir "[pwd]/"
  }

  goto_new_schematic ${cell_name}_placement $dir

  # get gate size information
  get_gate_sizes

  setl {xscale yscale} [concat $DPC(SCALE) $DPC(SCALE)]
  set DPC(xscale) [expr round($xscale * $DPC(UNITS))]
  set DPC(yscale) [expr round($yscale * $DPC(UNITS))]

  # set up the TERMS array with names of instances
  upvar #0 TERMS_$cur_s TERMS

  puts "Parsing $filename ..."

  # parses something of the form
  # DIEAREA ( -2000 -2000 ) ( 190000 22000 ) ;
  #
  # COMPONENTS 2 ;
  # - OAI21B_ OAI21B + PLACED ( -14000 -19600 ) N ;
  # - INVA INVA + PLACED ( -12600 8400 ) N ;
  # END COMPONENTS
  #
  # PINS 26 ;
  # - cin + NET cin + DIRECTION INPUT + USE SIGNAL
  # + PLACED ( 187500 -1500 ) N
  # + LAYER M2 ( -250 -250 ) ( 250 250 ) ;
  # - a[0] + NET a[0] + DIRECTION INPUT + USE SIGNAL
  # + PLACED ( 175500 -1500 ) N
  # + LAYER M2 ( -250 -250 ) ( 250 250 ) ;
  # END PINS

  set components 0
  while {[gets $FILE_ID line] >= 0} {
    set line [string trimleft $line]

    if {[string first DIEAREA $line] == 0} {
      setl {tmp tmp2 x1 y1 tmp3 tmp4 x2 y2} $line
      
      set x1 [expr round(10.0 * $x1 / $DPC(xscale))]
      set y1 [expr round(10.0 * $y1 / $DPC(yscale))]
      set x2 [expr round(10.0 * $x2 / $DPC(xscale))]
      set y2 [expr round(10.0 * $y2 / $DPC(yscale))]

      # create the bbox and label
      make_line $y1 $x1 $y2 $x1 $y2 $x2 $y1 $x2 $y1 $x1
      make_text -origin "0 [expr $x1 - 40]" -text "$cell_name placement" \
	  -size large
    }

    if {[string first COMPONENTS $line] == 0} {
      # found the components
      break
    }
  }

  # now read the components
  while {[gets $FILE_ID line] >= 0} {
    if {[lindex $line 0] == "END"} {
      # we're done
      break
    }

    # check for continuation lines (i.e. no ; termination)
    while {[string first \; $line] == -1} {
      if {[gets $FILE_ID line2] == 0} {
	puts "Aborting, EOF found prematurely."

	ready
	return
      }
      
      set line "$line $line2"
    }

    setl {dash name type plus place leftp x y rightp orient} $line
    
    # ignore filler cells and the like
    if {[lsearch $ignore_cells $type] != -1} {
      # ignore these
      continue
    }

    if {$x == ""} {
      puts "Aborting, cell $name of type $type is not placed"

      ready
      return
    }

    incr components

    # place the component
    set x [expr round(1.0 * $x / $DPC(xscale))]
    set y [expr round(1.0 * $y / $DPC(yscale))]

    setl {delta_col delta_row} $DPC_SIZE($type)

    # setup placement data
    set place_name _place_${delta_row}_$delta_col
    generate place $place_name -width $delta_row -height $delta_col

    # determine placement orientation
    switch $orient {
      N {
	set position "-origin [list [list [expr $y * 10] [expr $x * 10]]]"
      }
      FS {
	set position "-origin [list [list [expr ($y + $delta_row) * 10] [expr $x * 10]]] -orient RX"
      }
      FN {
	set position "-origin [list [list [expr $y * 10] [expr ($x + $delta_col) * 10]]] -orient RY"
      }
      S {
	set position "-origin [list [list [expr ($y + $delta_row) * 10] [expr ($x + $delta_col) * 10]]] -orient RXY"
      }
    }

    eval make $place_name -name \{$type\} -instance \{$name\} $position
  }

  # Now read the pins if there are any
  set pins 0
  set in_pins 0

  while {[gets $FILE_ID line] >= 0} {
    set line [string trimleft $line]

    if {[string first PINS $line] == 0} {
      # found the pins
      set in_pins 1
      break
    }
  }

  if {$in_pins} {
    while {[gets $FILE_ID line] >= 0} {
      if {[lindex $line 0] == "END"} {
	# we're done
	break
      }

      # check for continuation lines (i.e. no ; termination)
      while {[string first \; $line] == -1} {
	if {[gets $FILE_ID line2] == 0} {
	  puts "Aborting, EOF found prematurely."

	  ready
	  return
	}
      
	set line "$line $line2"
      }

      set name [lindex $line 1]

      set line [string tolower $line]

      # get the pin direction
      if {[set pos [lsearch $line direction]] != -1} {
	set dir [lindex $line [expr $pos + 1]]
      } else {
	set dir inout
      }

      # get the pin location/orientation
      if {[set pos [lsearch $line placed]] != -1 || \
	      [set pos [lsearch $line fixed]] != -1} {
	set x [lindex $line [expr $pos + 2]]
	set y [lindex $line [expr $pos + 3]]
	set orient [string toupper [lindex $line [expr $pos + 5]]]
      } else {
	# not placed, skip
	puts "Warning: skipping unplaced pin $name"
	continue
      }
      
      incr pins

      set x [expr round(10.0 * $x / $DPC(xscale))]
      set y [expr round(10.0 * $y / $DPC(yscale))]

      make $dir -name $name -origin [list $y $x] -orient $XFORM(undef,$orient)
    }
  }

  # close the file
  close $FILE_ID

  zoom_to_fit

  ready
  puts "Placed $components components and $pins pins."
  puts "done."
}


proc _TODO_1 {} {

  # find average but closest to side (dir)
  switch $dir {
    w - e {
      set i 0
      if {$dir == "w"} {
	set pairs [lsort -real -index 0 $_SAVE_($port)]
      } else {
	set pairs [lsort -real -decreasing -index 0 $_SAVE_($port)]
      }

      foreach pair $pairs {
	setl {x y} $pair
	    
	if {$i == 0} {
	  set xx $x
	  set yy 0
	}

	if {$x != $xx} {
	  # done
	  break
	}

	set yy [expr $yy + $y]
	incr i
      }

      if {$dir == "w"} {
	lappend list "$port $xx [expr 1.0*$yy/$i]"
      } else {
	# reference from right edge of bbox
	lappend list "$port [expr $row - $xx] [expr 1.0*$yy/$i]"
      }
    }

    s - n {
      set i 0
      if {$dir == "n"} {
	set pairs [lsort -real -index 1 $_SAVE_($port)]
      } else {
	set pairs [lsort -real -decreasing -index 1 $_SAVE_($port)]
      }

      foreach pair $pairs {
	setl {x y} $pair
	    
	if {$i == 0} {
	  set xx 0
	  set yy $y
	}

	if {$yy != $y} {
	  # done
	  break
	}

	set xx [expr $xx + $x]
	incr i
      }

      if {$dir == "n"} {
	lappend list "$port [expr 1.0*$xx/$i] $yy"
      } else {
	# reference from bottom edge of bbox
	lappend list "$port [expr 1.0*$xx/$i] [expr $col - $yy]"
      }
    }
  }

  return $list
}



# error works well as a stipple

proc stipple_it {{stipple ""}} {

  global cur_c

  $cur_c addtag stipple withtag icon
  $cur_c dtag term stipple
  $cur_c dtag arc stipple
  $cur_c dtag scaletext stipple

  $cur_c itemconfigure stipple -stipple $stipple
  $cur_c dtag stipple

  $cur_c itemconfigure icon&arc -outlinestipple $stipple
}


# warning if preroutes intersect

# assumes x1=x2
# assumes y1<y2

# example wire

#set list {
#  {net_1 10 100 10 200}
#  {net_2 20 110 20 300}
#  {net_3 10 190 10 250}
#}

proc intersect_wire {list} {

  set existing ""
  foreach wire $list {

    # get the next wire
    setl {name x1 y1 x2 y2} $wire

    # see if it conflicts
    foreach exist $existing {
      # see if wire conflicts with exist
      setl {ename ex1 ey1 ex2 ey2} $exist

      if {$x1 == $ex1} {
	if {($y1 >= $ey1 && $y1 <= $ey2) || \
		($y2 >= $ey1 && $y2 <= $ey2) || \
		($y1 < $ey1 && $y2 > $ey2)} {
	  # we have a conflict
	  puts "WARNING: net $name ($x1 $y1 $x2 $y2) conflicts with $ename ($ex1 $ey1 $ex2 $ey2)."
	}
      }
    }

    lappend existing $wire
  }

  puts "Checked [llength $list] wires."
}


# computes net weights for the physical compiler placer

proc weights {} {

  global cur_s cur_c

  # strip off placement from the cell name
  regsub {_placement$} $cur_s "" cell

  upvar #0 SUE_$cur_s data
  set filename "$data(dir)$cell.weights"

  puts "Creating weights for design $cur_s ..."

  set_timing_weights $filename
  puts "Wrote file $filename"
}


proc set_timing_weights {{file -}} {
    if { $file == "-" } {
	set ofp stdout
    } else {
	set ofp [open $file "w"]
    }

    unwind_protect {
	set cells [nl_list_cells]

	foreach cell $cells {
	    set ref_name [nl_get_reference_name [nl_get_cell_reference $cell]]
	    set len [string length $ref_name]
	    set gate_size [string index $ref_name [expr $len - 1]]

	    switch $gate_size {
		A { set weight ultra }
		B { set weight high }
		C { set weight medium }
		D { set weight low }
		default { set weight {}}
	    }

	    if { $weight != {} } {
		set out_pins [nl_get_cell_pins -output $cell]
		foreach out_pin $out_pins {
		    set out_net [nl_get_pin_net $out_pin]

		    if { $out_net != {} } {
			puts $ofp "set_timing_weights -effort $weight {$out_net}"
		    }
		}
	    }
	}
    } {
	if { $ofp != "stdout" } {
	    close $ofp
	}
    }
}
