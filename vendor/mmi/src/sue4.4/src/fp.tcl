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


# SUE floorplanner (fp) routines. PRELIMINARY.

# in utilities

#proc is_fp {cell} -desc {
#  Returns 1 if given cell is a fp file.
#} {
#
#  # fps have are of the form <cell>_fp
#  if {[regexp _fp$ $cell]} {
#    # yes
#    return 1
#  } else {
#    # no
#    return 0
#  }
#}



# No undo


# if 1 display, otherwise don't
set FP_DISPLAY(names) 1
set FP_DISPLAY(types) 1
set FP_DISPLAY(ports) 1
set FP_DISPLAY(flylines) 1

# default cell size in grids^2.  Must be an integer
set FP_DEFAULT_SIZE 50
set FP_DEFAULT_MODULE_SIZE 500


proc make_fp_from_verilog {name} {

  global cur_s cur_c scale DPC XFORM SUE nl_current_design XFORM FP_SIZE COLORS

  modify_setup

  set schem ${name}_fp
  if {![_fp_replace_cell $schem]} {
    # aborted
    return 0
  }
  
  scale_canvas 1

  # for select by name
  upvar #0 TERMS_$cur_s TERMS
  catch {unset TERMS}

  set nl_current_design $name

  # walk thru each cell in this hierarchy
  foreach cell [eval nl_list_cells -noassign $name] {
    set cellname $cell
    set type [nl_get_cell_reference $cellname]
    
    # is this a libcell
    if {[nl_object_type [nl_get_reference_link $type]] == "libcell"} {
      # yes, use LEF info to build an icon for it

      # for now place at origin with N orientation
      nl_set_cell_location -grids $cellname 0 0
      nl_set_cell_orientation $cellname N

      fp_draw_libcell $cellname
      
    } else {
      # this must be a block.  Make up something.
      nl_set_cell_location -grids $cellname 0 0
      nl_set_cell_orientation $cellname N

      # set from area
      set FP_SIZE($type) [fp_estimate_size $type]

      # set this as a leafcell in for nl
      nl_set_libcell $type
      nl_create_pdesign -nohierarchy $type

      # assume square
      set x [expr int(ceil( sqrt($FP_SIZE($type)) ))]
      set x2 [expr $x/2]
      nl_set_die_area -grids [list 0 0 $x $x] $cellname

      # put ports at center (origin) for now
      foreach pin [nl_get_cell_pins $cellname] {
	nl_set_port_location -grids $pin $x2 $x2
      }

      fp_draw_block $cellname
    }
  }

  # use estimate to create initial bbox
#  set type [nl_get_cell_reference $name]
  set type $name

  set FP_SIZE($type) [fp_estimate_size $type]

  set x [expr int(ceil( sqrt($FP_SIZE($type)) ))]
  set x2 [expr $x/2]
  nl_set_die_area -grids [list 0 0 $x $x] $name

  # draw the bbox
  $cur_c create line 0 0 $x 0 $x -$x 0 -$x 0 0 \
      -tags "draw_item bbox" -fill $COLORS(fore)

  # add pins
  foreach pin [nl_list_ports $name] {

    # for now place at center
    nl_set_port_location -grids $pin $x2 $x2
    nl_set_port_orientation $pin N

    set type $XFORM(nlport,[nl_get_port_direction $pin])
    set id [make $type -name $pin \
		-orient $XFORM(undef,[nl_get_port_orientation $pin]) \
		-origin [nl_get_port_location -grids $pin]]
    $cur_c scale inst$id 0 0 $scale -$scale
    set TERMS($id) $pin
  }

  zoom_to_fit
}


proc _fp_replace_cell {cell {mode ""}} {

  global cur_s cur_c SUE_DIR PROC SUE

  set PROC ""

  # if the cell already exists, see if user wants to recreate.
  if {[info commands $cell] != "" || [info exists SUE($cell)]} {
    if {$mode == "use_existing"} {
      # just use this one
      return 0
    }

    goto_schematic $cell

    set button [tk_dialog .delete "Replace Cell" \
		    "Do you want to replace $cell?" \
		    @$SUE_DIR/sue_icon.xbm 1 {replace} {cancel}]

    if {$button == 1} {
      # user hit the cancel key
      return 0
    }

    # for undo
#    write_instances all "" undo
#    write_wires all undo
#    write_draw_items all undo

    # toast contents
    foreach id [$cur_c find withtag origin] {
      # delete old icon and lose the old data structure
      $cur_c delete inst$id
      global ${cur_s}_inst$id
      catch {unset ${cur_s}_inst$id}
    }
     
    # delete anything else that might be around
    $cur_c delete all

    scale_canvas 10

    if {[is_icon $cell]} {
      make_icon_origin
    }

  } else {
    # make new cell
    if {[regsub {^ICON_} $cell "" cell_strip]} {
      # icon is different
      make_new_schematic $cell_strip I
    } else {
      make_new_schematic $cell
    }
  }

  # success
  return 1
}


# draw the libcell icon using data from nl

proc fp_draw_libcell {name} {

  global cur_s cur_c scale DPC COLORS FP_DISPLAY FONT

  set type [nl_get_cell_reference $name]

  # nl name
  set libcell $DPC(lib)/$type

  # add bbox
  setl {x y} [nl_get_libcell_size -grids $libcell]

  # TODO: assumes origin at 0,0 for now
  set id [$cur_c create line 0 0 $x 0 $x $y 0 $y 0 0 \
	      -tags "origin icon icon_$type move" -fill $COLORS(fore)]
  $cur_c addtag inst$id withtag $id

  upvar #0 ${cur_s}_inst$id i_data
  set i_data(type) $type
  set i_data(_name) $name
#  set i_data(kind) libcell

  upvar #0 TERMS_$cur_s TERMS
  set TERMS($id) $name

  # add a slash showing orientation of this instance
  set orient [nl_get_cell_orientation $name]
  switch $orient {
    N {
      $cur_c create line 0 1 1 0 \
	  -tags "icon inst$id move" -fill $COLORS(fore)
    }
    FS {
      $cur_c create line 0 [expr $y - 1] 1 $y \
	  -tags "icon inst$id move" -fill $COLORS(fore)
    }
    FN {
      $cur_c create line $x 1 [expr $x - 1] 0 \
	  -tags "icon inst$id move" -fill $COLORS(fore)
    }
    S {
      $cur_c create line $x [expr $y - 1] [expr $x - 1] $y \
	  -tags "icon inst$id move" -fill $COLORS(fore)
    }
    default { 
      puts "Unrecognized orientation \"$orient\" for \"$name\"."
    }
  }

  # add name and type
  if {$FP_DISPLAY(types)} {
    if {$x > 100} { set size very-large } \
	elseif {$x > 50} { set size large } \
	elseif {$x > 25} { set size standard } \
	elseif {$x > 12} { set size small } \
	else { set size very-small }
    
    $cur_c create text [expr $x * 0.5] [expr $y * 0.75] \
	-text $type -font $FONT($size,$scale) -fill $COLORS(fore) \
	-tags "icon inst$id size_$size scaletext move" -anchor c

    if {$FP_DISPLAY(names)} {
      $cur_c create text [expr $x * 0.5] [expr $y * 0.25] \
	  -text $name -font $FONT($size,$scale) -fill $COLORS(fore) \
	  -tags "icon inst$id size_$size scaletext move" -anchor c
    }

  } elseif {$FP_DISPLAY(names)} {
    if {$x > 100} { set size very-large } \
	elseif {$x > 50} { set size large } \
	elseif {$x > 25} { set size standard } \
	elseif {$x > 12} { set size small } \
	else { set size very-small }

    $cur_c create text [expr $x * 0.5] [expr $y * 0.25] \
	-text $name -font $FONT($size,$scale) -fill $COLORS(fore) \
	-tags "icon inst$id size_$size scaletext move" -anchor c
  }

  if {$FP_DISPLAY(ports)} {
    foreach pin [nl_get_libcell_pins -nosupply $libcell] {
      set pinname [nl_get_libpin_name $pin]
      set loc [nl_get_pin_location -grids $name/$pinname]
      
      # TODO: need a port orient
      set size very-small
      switch [nl_get_libpin_direction $pin] {
	in { set kind "<" }
	out { set kind ">" }
	inout { set kind "<>" }
      }

      $cur_c create text [lindex $loc 0] [lindex $loc 1] \
	  -text $kind$pinname -font $FONT($size,$scale) -fill $COLORS(fore) \
	  -tags "icon inst$id size_$size scaletext" -anchor c
    }
  }

  # scale this and move it.
  # Note: -y since y increases downwards in tk canvas.
  $cur_c scale inst$id 0 0 $scale -$scale

  set origin [nl_get_cell_location -grids $name]
  set x [expr [lindex $origin 0] * $scale]
  set y [expr - [lindex $origin 1] * $scale]

  $cur_c move move $x $y
  $cur_c dtag move
}


# draw the block icon using data from nl

proc fp_draw_block {name} {

  global cur_s cur_c scale DPC COLORS FP_DISPLAY FONT

  set type [nl_get_cell_reference $name]

  # add bbox
  setl {x1 y1 x2 y2} [nl_get_die_area -grids $type]
  set x [expr $x2 - $x1]
  set y [expr $y2 - $y1]

  set id [$cur_c create line $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 $x1 $y1 \
	      -tags "origin icon icon_$type" -fill $COLORS(fore)]
  $cur_c addtag inst$id withtag $id

  upvar #0 ${cur_s}_inst$id i_data
  set i_data(type) $type
  set i_data(_name) $name
#  set i_data(kind) block

  upvar #0 TERMS_$cur_s TERMS
  set TERMS($id) $name

  # add an H showing orientation of this instance
  set orient [nl_get_cell_orientation $name]
  set size standard
  switch $orient {
    N {
      $cur_c create text $x1 $y1 \
	  -text H -font $FONT($size,$scale) -fill $COLORS(fore) \
	  -tags "icon inst$id size_$size scaletext" -anchor sw
    }
    FS {
      $cur_c create text $x1 $y2 \
	  -text H -font $FONT($size,$scale) -fill $COLORS(fore) \
	  -tags "icon inst$id size_$size scaletext" -anchor nw
    }
    FN {
      $cur_c create text $x2 $y1 \
	  -text H -font $FONT($size,$scale) -fill $COLORS(fore) \
	  -tags "icon inst$id size_$size scaletext" -anchor se
    }
    S {
      $cur_c create text $x2 $y2 \
	  -text H -font $FONT($size,$scale) -fill $COLORS(fore) \
	  -tags "icon inst$id size_$size scaletext" -anchor ne
    }
    default { 
      puts "Unrecognized orientation \"$orient\" for \"$name\"."
    }
  }

  # add name and type
  if {$FP_DISPLAY(types)} {
    if {$x > 100} { set size very-large } \
	elseif {$x > 50} { set size large } \
	elseif {$x > 25} { set size standard } \
	elseif {$x > 12} { set size small } \
	else { set size very-small }
    
    $cur_c create text [expr $x * 0.5] [expr $y * 0.75] \
	-text $type -font $FONT($size,$scale) -fill $COLORS(fore) \
	-tags "icon inst$id size_$size scaletext" -anchor c

    if {$FP_DISPLAY(names)} {
      $cur_c create text [expr $x * 0.5] [expr $y * 0.25] \
	  -text $name -font $FONT($size,$scale) -fill $COLORS(fore) \
	  -tags "icon inst$id size_$size scaletext" -anchor c
    }

  } elseif {$FP_DISPLAY(names)} {
    if {$x > 100} { set size very-large } \
	elseif {$x > 50} { set size large } \
	elseif {$x > 25} { set size standard } \
	elseif {$x > 12} { set size small } \
	else { set size very-small }

    $cur_c create text [expr $x * 0.5] [expr $y * 0.25] \
	-text $name -font $FONT($size,$scale) -fill $COLORS(fore) \
	-tags "icon inst$id size_$size scaletext" -anchor c
  }

  if {$FP_DISPLAY(ports)} {
    foreach pin [nl_get_cell_pins $name] {
      set loc [nl_get_port_location -grids $pin]
      set pinname [nl_get_port_name $pin]
      
      # TODO: need a port orient
      set size very-small
      switch [nl_get_port_direction $pin] {
	in { set kind "<" }
	out { set kind ">" }
	inout { set kind "<>" }
      }

      $cur_c create text [lindex $loc 0] [lindex $loc 1] \
	  -text $kind$pinname -font $FONT($size,$scale) -fill $COLORS(fore) \
	  -tags "icon inst$id size_$size scaletext" -anchor c
    }
  }

  # scale this and move it.
  # Note: -y since y increases downwards in tk canvas.
  $cur_c scale inst$id 0 0 $scale -$scale

  # TODO: some of this needs to move and most doesn't!

  set origin [nl_get_cell_location -grids $name]
  $cur_c move inst$id [lindex $origin 0] [expr - [lindex $origin 1]]
}


# rebuild canvas drawing, for example after turning on/off port names

proc fp_redraw {} {

  global scale cur_c cur_s XFORM COLORS
  
  set save_scale $scale
  scale_canvas 1

  # for select by name
  upvar #0 TERMS_$cur_s TERMS
  catch {unset TERMS}

  # toast icons
  $cur_c delete icon
  $cur_c delete flyline
  # TODO: delete i_data stuff

  regsub {_fp$} $cur_s "" name

  # rebuild
  foreach cell [eval nl_list_cells -noassign $name] {
    set cellname $cell
    
    # is this a libcell
    if {[nl_object_type [nl_get_reference_link \
			     [nl_get_cell_reference $cellname]]] == "libcell"} {
      # yes, use LEF info to build an icon for it
      fp_draw_libcell $cellname
      
    } else {
      # this must be a block.  Make up something.
      fp_draw_block $cellname
    }
  }

  # draw bounding box
  setl {x1 y1 x2 y2} [nl_get_die_area -grids $name]

  $cur_c delete bbox

  # draw the bbox
  set y1 [expr 0 - $y1]
  set y2 [expr 0 - $y2]

  $cur_c create line $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 $x1 $y1 \
      -tags "draw_item bbox" -fill $COLORS(fore)

  # add pins
  foreach pin [nl_list_ports $name] {
    set type $XFORM(nlport,[nl_get_port_direction $pin])
    set id [make $type -name $pin \
		-orient $XFORM(undef,[nl_get_port_orientation $pin]) \
		-origin [nl_get_port_location -grids $pin]]
    $cur_c scale inst$id 0 0 $scale -$scale
    set TERMS($id) $pin
  }

  scale_canvas $save_scale
}


# update nl with new positions/orientations of cells

proc fp_update_nl {{what ""}} {

  global cur_s cur_c scale
  
  set save_scale $scale
  scale_canvas 1

  if {$what == "selected"} {
    # selected only
    set ids [$cur_c find withtag origin&selected]
  } else {
    # all
    set ids [$cur_c find withtag origin]
  }

  foreach id $ids {
    upvar #0 ${cur_s}_inst$id i_data
    set cellname $i_data(_name)

    set coords [$cur_c coords $id]
    if {[lsearch "input output inout" $i_data(type)] != -1} {
      # top-level pin
      # TODO: might add half a grid to
      nl_set_port_location -grids $cellname \
	  [expr int(round([lindex $coords 0]))] \
	  [expr int(round(-[lindex $coords 1]))]

      # TODO update orientation
      # nl_set_port_orientation $cellname N

    } else {
      nl_set_cell_location -grids $cellname \
	  [expr int(round([lindex $coords 0]))] \
	  [expr int(round(-[lindex $coords 1]))]

      # TODO update orientation
      # nl_set_cell_orientation $cellname N
    }
  }

  scale_canvas $save_scale
}


# display flylines to selected cells

proc fp_display_flylines {} {

  global cur_c cur_s scale FP_DISPLAY

  # toast existing
  $cur_c delete flyline

  if {!$FP_DISPLAY(flylines)} {
    # user has turned them off
    return
  }

  foreach id [$cur_c find withtag origin&selected] {
    upvar #0 ${cur_s}_inst$id i_data

    _fp_display_flyline $i_data(_name)
  }

  $cur_c scale flyline 0 0 $scale -$scale
}


# display flylines to a given cell

proc _fp_display_flyline {name} {

  global cur_c cur_s COLORS

  # get all of the pins connected to this guy
  foreach from_pin [nl_get_cell_or_port_pins $name] {
    set arrow "none"
    if {[nl_get_pin_direction $from_pin] == "out"} {
      set arrow "last"
    }

    set fcoord [nl_get_pin_location -grids $from_pin]

    # now get the net connected to this pin
    set net [nl_get_pin_net $from_pin]
    foreach to_pin [nl_get_net_pins -noassign $net] {
      if {$to_pin == $from_pin} {
	# we came from here
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

      set tcoord [nl_get_pin_location -grids $to_pin]

      # remove duplicates
      if {$arrow == "first"} {
	if {[info exists dup($fcoord,$tcoord)]} {
	  continue
	}
	set dup($fcoord,$tcoord) 1
      } else {
	if {[info exists dup($tcoord,$fcoord)]} {
	  continue
	}
	set dup($tcoord,$fcoord) 1
      }

      if {$fcoord == $tcoord} {
	# don't add zero length
	continue
      }

#      puts "$from_pin $fcoord --> $to_pin $tcoord"

      $cur_c create line [lindex $fcoord 0] [lindex $fcoord 1] \
	  [lindex $tcoord 0] [lindex $tcoord 1] \
	  -tags "flyline" -fill $COLORS(stroke_box) -arrow $arrow

      if {$arrow == "first"} {
	set arrow "none"
      }
    }
  }
}


proc fp_initialize {{verilog_file ""}} {

  global DPC nl_x_grid_size nl_y_grid_size FP_SIZE

  catch {unset FP_SIZE}

  # name not important
  set DPC(lib) dpc

  # clean up nl
  catch {nl_remove_library -silent $DPC(lib)}

  # allows for different grid sizes in x and y
  setl {xscale yscale} $DPC(SCALE)
  if {$yscale == ""} {
    set yscale $xscale
  }
  set DPC(xscale) [expr round($xscale * $DPC(UNITS))]
  set DPC(yscale) [expr round($yscale * $DPC(UNITS))]

  # set up grid size in nl
  set nl_x_grid_size $DPC(xscale)
  set nl_y_grid_size $DPC(yscale)

  # load lefs
  nl_create_library $DPC(lib)
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
	  puts "WARNING: $msg"
	}
      }
      if {!$is_file} {
	puts "WARNING: couldn't find LEF file matching \"$lib\"."
      }
    }

    # fix up any buses
    nl_infer_libpin_buses $DPC(lib)
  }

  if {$verilog_file == ""} {
    # query user 


  }

  # load verilog 

  # reset the nl database
  catch "nl_remove_design -all -silent"

  # read the verilog and link it
  puts "Reading verilog $verilog_file ..."
  nl_read_verilog $verilog_file

  set root [file tail [file rootname $verilog_file]]
  nl_link -silent -libraries $DPC(lib) $root

  # initialize
  nl_create_pdesign

#  if {$estimate_size} {
#  }
}


proc fp_estimate_size {name {utilization 0.7}} -desc {
  Add up the sizes of the underlying cells then divide by the utilization.
  LEF's must be loaded.

  TODO: possibly ignore megacells when adding utilization
} {

  global FP_SIZE DPC FP_DEFAULT_SIZE FP_DEFAULT_MODULE_SIZE

  # add up the areas
  set area 0

  # NOTE: unlinked possibility???
  foreach cell [nl_list_cells -recursive -library -noassign -unlinked $name] {

    set type [nl_get_cell_reference $cell]

    if {[info exists FP_SIZE($type)]} {
      # already computed this, just add
      incr area $FP_SIZE($type)
      continue
    }

    if {[nl_object_type [nl_get_reference_link $type]] == "libcell"} {
      # add bbox of libcell
      set libcell $DPC(lib)/$type

      if {[catch {nl_get_libcell_size -grids $libcell} xy]} {
	# doesn't exist, use default
	puts "FP WARNING: no size for libcell $type, using default area: $FP_DEFAULT_SIZE"
	set FP_SIZE($type) $FP_DEFAULT_SIZE

      } else {
	set FP_SIZE($type) [expr [lindex $xy 0] * [lindex $xy 1]]
      }

    } else {
      # not a libcell -- verilog module
      if {[catch {nl_get_die_area -grids $type} xyxy] || [llength $xyxy] == 0} {
	# doesn't exist, use default
	puts "FP WARNING: no size for verilog module $type, using default area: $FP_DEFAULT_MODULE_SIZE"
	set FP_SIZE($type) $FP_DEFAULT_MODULE_SIZE

      } else {
	set FP_SIZE($type) [expr ([lindex $xyxy 2] - [lindex $xyxy 0]) * \
				([lindex $xyxy 3] - [lindex $xyxy 1])]
      }
    }

    incr area $FP_SIZE($type)
  }

  return [expr int(ceil($area / $utilization))]
}





#  reload fp ; launch "make_fp_from_verilog alu8" 


# TODO:
#  goto cell --> set nl_current_design, goto_schematic, redraw

#  port opt -- from pat.
#  change orient (flip, mirror)
#  Deselect --> remove flylines
#  Flyline -- add tag with net name
#  Move should be limited to row heights in y
#  Autosave disable
#  Congestion display should not rotate
#  when reading DEF, orient pins to closest side


# reload fp ; fp_initialize alu8.vg


# nl_read_def alu8.hier.def ; fp_redraw
