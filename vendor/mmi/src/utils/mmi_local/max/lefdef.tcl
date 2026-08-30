# Copyright (C) 1998 - 2000 Micro Magic, Inc., All Rights Reserved.

# If no lef size, use these default sizes the the cell when reading the def
set DEFAULT_HEIGHT 10
set DEFAULT_WIDTH 10


# Reads a LEF file to get pitch, row height, and cell sizes
# For now only looks for SITE and MACRO definitions

proc read_lef {{filename ""}} {

  global LEF_SIZE_HEIGHT LEF_SIZE_WIDTH LEF_SITE LEF_SITE_SIZE FP_GRID GRID

  if {$filename == ""} {
    # bring up file selection box
    set filename [fs_box -message "LEF File to Read:" -pattern "*.lef"]

    if {$filename == ""} {
      # user hit cancel key
      return ""
    }
  } else {
    if {[file extension $filename] == ""} {
      set filename "$filename.lef"
    }
  }

  # open the lef file for reading
  if {[catch "open $filename r" LEF_ID]} {
    # problem
    puts "ERROR: $LEF_ID"
    return ""
  }

  puts "Parsing $filename ..."

  # look for a lines of the form:
  # SITE <name>
  # SIZE <x> BY <y> ;
  # END <name>

  # MACRO <name>
  # ignored-- FOREIGN <name> <x> <y> <orient> ;
  # ignored-- ORIGIN <x> <y> ;
  # SIZE <x> BY <y> ;
  # SITE <site_name> ;
  # END <name>

  # #'s are comment lines

  set cell ""
  set site ""
  set line ""
  while {$line != "" || [gets $LEF_ID line] >= 0} {
    set line [string trim $line]

    set pos [string first \# $line]
    if {$pos != -1} {
      # get rid of comment
      set line [string range $line 0 [expr $pos - 1]]
    }

    if {$line == ""} {
      # remove blank lines
      continue
    }

    if {$cell == "" && [lindex $line 0] == "SITE"} {
      set site [lindex $line 1]
      set line [lrange $line 2 end]
      continue
    }

    if {$site != "" && [lindex $line 0] == "END" && [lindex $line 1] == $site} {
      set site ""
      set line ""
      continue
    }

    if {$site != "" && [lindex $line 0] == "SIZE"} {
      set w [lindex $line 1] 
      set h [lindex $line 3]

      if {![info exists FP_GRID(pitch)]} {
	set FP_GRID(pitch) $w
	set FP_GRID(row) $h
      } else {
	# use the minimum -- effectively ignores megacells
	set FP_GRID(pitch) [min $FP_GRID(pitch) $w]
	set FP_GRID(row) [min $FP_GRID(row) $h]
      }

      set LEF_SITE_SIZE($site) "$w $h"
      set line [_parse_to_semicolon $line]
      continue
    }

    if {[lindex $line 0] == "MACRO"} {
      set cell [lindex $line 1]
      set line [lrange $line 2 end]
      continue
    }

    if {[lindex $line 0] == "END" && [lindex $line 1] == $cell} {
      set cell ""
      set line ""
      continue
    }

    if {$cell != "" && [lindex $line 0] == "SITE"} {
      set LEF_SITE($cell) [lindex $line 1]
      set line [_parse_to_semicolon $line]
      continue
    }

    if {$cell != "" && [lindex $line 0] == "SIZE"} {
      set LEF_SIZE_WIDTH($cell) [lindex $line 1]
      set LEF_SIZE_HEIGHT($cell) [lindex $line 3]
      set line [_parse_to_semicolon $line]
      continue
    }

    set line [_parse_to_semicolon $line]
  }

  # close the file
  close $LEF_ID

  puts "Read sizes for [llength [array names LEF_SIZE_HEIGHT]] cells."

  # set the user grid
#  if {[info exists FP_GRID(pitch)]} {
#    set GRID(resolution) $FP_GRID(pitch)
#    set GRID($GRID(current),resolution) $FP_GRID(pitch)
#  }

  return $filename
}


proc _parse_to_semicolon {line} {

  set pos [string first \; $line]
  if {$pos != -1} {
    # get rid of to ;
    set line [string range $line [expr $pos + 1] end]
    return [string trim $line]

  } else {
    return ""
  }
}


# Reads a def netlist and places cells.
# Only read COMPONENTS for now

proc read_def {{filename ""}} -desc {
  reads in the def file and places cells in the current window
} {
  global MC LEF_SIZE_WIDTH LEF_SIZE_HEIGHT WIRE_WIDTH VIAS TRACKS

  if {$filename == ""} {
    # bring up file selection box
    set filename [fs_box -message "DEF File to Load:" -pattern "*.def"]
    if {$filename == ""} {
      # user hit cancel key
      return
    }
  } else {
    if {[file extension $filename] == ""} {
      set filename "$filename.def"
    }
  }

  if {[catch "open $filename r" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    return
  } 

  if {![info exists MC(boundary)] || [catch "lay_layer_styles $MC(boundary)"]} {
    # get a boundary layer
    if {![catch "lay_layer_styles prb"]} {
      # use the prb layer
      set MC(boundary) prb
    } else {
      # query user

      # get all the layers
      set layers ""
      foreach layer [split [db_types] \n] {
	if {$layer != "" && [lsearch [lindex $layer 4] "builtin"] == -1} {
	  lappend layers [lindex $layer 0]
	}
      }

      set prop_list ""
      set MC(boundary) [lindex [lreverse $layers] 0]
      lappend prop_list [list "bbox layer" MC(boundary) -choice $layers]

      set title "Boundary Layer"
      set message "Choose layer:"

      # create the menu
      if {![prop_menu2 -message $message -title $title $prop_list]} {
	# cancelled
	return
      }
    }
  }

  # turn this off to make max faster
  undo_disable
  undo_flush

  set cell_name [file rootname [file rootname [file tail $filename]]]

  # create a new cell if there isn't one in max of this name
  if {![fp_goto_cell $cell_name]} {
    # user said no
    return
  }

  set count 0
  set nets 0
  set line_num 0

  puts "Parsing DEF file $filename ..."

  # parses something of the form
  # UNITS DISTANCE MICRONS 1000 ;
  # DIEAREA ( 0 0 ) ( 8400 30800 ) ;

  while {[gets $FILE_ID line] >= 0} {

    switch -exact X_[lindex $line 0] {

      X_UNITS {
	set grid [expr [lindex $line 3] * 1.0]
      }

      X_DIEAREA {
	# found the bbox
	regsub -all {\(|\)} $line "" line
	setl {diearea x1 y1 x2 y2} $line

	# add a bbox for the boundary
	db_paint $MC(boundary) [expr $x1/$grid] [expr $y1/$grid] \
	    [expr $x2/$grid] [expr $y2/$grid]
      }

      X_TRACKS {
	# TRACKS Y 500 DO 84 STEP 1000 LAYER M1 M2 M3 M4 ;

	# a line must end with a semicolon, otherwise get the next line
	while {[string last \; $line] == -1} {

	  if {[gets $FILE_ID next_line] >= 0} {
	    set line "$line $next_line"
	  } else {
	    puts "Aborting, unexpected end of file.  Missing ;"
	    return
	  }
	}

	set line [string trimright $line \;]

	# save these for writing
	set d [string toupper [lindex $line 1]]
	if {$d == "X" && [info exists y2]} {
	  set TRACKS($d) "$x1 $x2 $line"
	} elseif {$d == "Y" && [info exists y2]} {
	  set TRACKS($d) "$y1 $y2 $line"
	}
      }

      X_COMPONENTS {
	# parses something of the form
	# COMPONENTS 2 ;
	# - OAI21B_ OAI21B + PLACED ( -14000 -19600 ) N ;
	# - INVA INVA + PLACED ( -12600 8400 ) N ;
	# END COMPONENTS

	# now read the components
	while {[gets $FILE_ID line] >= 0} {
	  if {[string first "END" $line] == 0} {
	    # we're done
	    break
	  }

	  # a line must end with a semicolon, otherwise get the next line
	  while {[string last \; $line] == -1} {

	    if {[gets $FILE_ID next_line] >= 0} {
	      set line "$line $next_line"
	    } else {
	      puts "Aborting, unexpected end of file.  Missing ;"
	      return
	    }
	  }

	  # setl is pretty slow
#	  setl {dash instance_name type plus place leftp x y rightp orient} $line

	  if {[lindex $line 0] != "-"} {
	    # not a component
	    continue
	  }

	  set instance_name [lindex $line 1]
	  # for now, change hierarchical delimiter
	  regsub -all / $instance_name ! instance_name

	  set type [lindex $line 2]
 
	  if { [cell_flags $type] == "__NO_SUCH_BUFFER__" } {
	    # no cell, make a bogus cell from the lef data
	    db_notify
	    make_prb_cell $type
	  }

	  set loc_key [lindex $line 4]
    
	  if {$loc_key == "PLACED" || $loc_key == "FIXED"} {
	    set x [lindex $line 6]
	    set y [lindex $line 7]
	    set orient [lindex $line 9]

	  } elseif {[lindex $line 7]=="PLACED" || [lindex $line 7]=="FIXED" } {
	    # Sometimes .def files contain '+ SOURCE TIMING + PLACED'
	    set x [lindex $line 9]
	    set y [lindex $line 10]
	    set orient [lindex $line 11]

	  } elseif {$loc_key == "UNPLACED"}  {
	    # This cell is unplaced.  Put it outside the diearea
	    puts stderr "WARNING: skipping unplaced cell $type"
	    continue

	  } else {
	    puts stderr "Ignoring COMPONENT statement: $line"
	    continue
	  }

	  switch $orient {
	    FN {
	      db_instance -id $instance_name -orient fx $type \
		  [expr $x/$grid + $LEF_SIZE_WIDTH($type)] [expr $y/$grid]
	    }
	    FS {
	      # flip this 
	      db_instance -id $instance_name -orient fy $type \
		  [expr $x/$grid] [expr $y/$grid + $LEF_SIZE_HEIGHT($type)]
	    } 
	    S {
	      db_instance -id $instance_name -orient r180 $type \
		  [expr $x/$grid + $LEF_SIZE_WIDTH($type)] [expr $y/$grid + $LEF_SIZE_HEIGHT($type)]
	    }
	    E {
	      # rotate this
	      db_instance -id $instance_name -orient r90 $type \
		  [expr $x/$grid] [expr $y/$grid + $LEF_SIZE_WIDTH($type)]
	    } 
	    FE {
	      # rotate this
	      db_instance -id $instance_name -orient fx_r90 $type \
		  [expr $x/$grid] \
		  [expr $y/$grid]
	    } 
	    FW {
	      # rotate this
	      db_instance -id $instance_name -orient fy_r90 $type \
		  [expr $x/$grid + $LEF_SIZE_HEIGHT($type)] \
		  [expr $y/$grid + $LEF_SIZE_WIDTH($type)]
	    } 
	    W {
	      # rotate this
	      db_instance -id $instance_name -orient r270 $type \
		  [expr $x/$grid + $LEF_SIZE_HEIGHT($type)] \
		  [expr $y/$grid]
	    } 
	    default {
	      # don't flip
	      db_instance -id $instance_name $type \
		  [expr $x/$grid] [expr $y/$grid]
	    }
	  }

	  incr count
	  if {[expr $count % 1000] == 0} {
	    puts "... $count ..."
	  }
	}

	db_notify

      }

      X_NETS - X_SPECIALNETS {

	# parses something of the form

	# - Cin
	# ( addimm$11$__ripple_start_H_1$1$__MUX2D  sel )
	# ( addimm$11$__ripple_start_H_2__MUX2D  sel )
	# ( exu_job_AU_decode__AOI21B  out )
	# + ROUTED
	#     M2  (  361500   485500 )  (  362500   485500 )
	# NEW  M2  (  362500   482500 )  (  362500   485500 )
	# NEW  M2  (  362500   482500 )  VIA23
	# NEW  M2  (  425500   482500 )  VIA23
	# + USE  SIGNAL
	# ;

	set ww2_default [uusnap [expr $WIRE_WIDTH / 2.0]]

	# now read the nets
	while {[gets $FILE_ID line] >= 0} {
	  if {[lindex $line 0] == "END"} {
	    # we're done
	    break
	  }

	  set netname [lindex $line 1]

	  # Skip lines until 'FIXED' or 'ROUTED' is found.
	  # We hope there is no ROUTED or FIXED in the compeonts names....
	  
	  set skipping 1
	  while {$skipping} {
	      if {[string last \; $line] != -1} {
		  set skipping 0
	      }
	      if {[string last ROUTED $line] != -1} {
		  set skipping 0
	      }
	      if {[string last FIXED $line] != -1} {
		  set skipping 0
	      }

	      if {$skipping} {
		  if {[gets $FILE_ID line] >= 0} {
		  } else {
		      puts "Aborting, unexpected end of file.  Missing ;"
		      exit
		  }
	      }
	  }

	  # a line must end with a semicolon, otherwise get the next line
	  while {[string last \; $line] == -1} {
	    if {[gets $FILE_ID next_line] >= 0} {
	      set line "$line $next_line"
		incr line_num
		if {[expr $line_num % 1000] == 0} {
		    puts "... net line $line_num ..."
		}
	    } else {
	      puts "Aborting, unexpected end of file.  Missing ;"
	      exit
	    }
	  }
	  
	  # get just the routing section
	  set pos [string last ROUTED $line]
	  if {$pos == -1} {
	      set pos [string last FIXED $line]
	  }

	  if {$pos == -1} {
	    puts "Net $netname is not routed"
	    continue
	  }

	  incr nets
	  set line [string range $line [expr $pos + 6] end]

	  # strip off + to end or ;
	  if {[set pos [string first + $line]] != -1} {
	    set line [string range $line 0 $pos]
	  }

	  set line [string trimright $line {;+}]

	  # puts "NET/SPECIALNET routing: $line"

	  while {1} {

	    set pos [string first NEW $line]
	    if {$pos == -1} {
	      if {$line == ""} {
		break
	      }
	      # last wire/via
	      set pos [expr [string length $line] + 1]
	      set wire $line

	      # puts "Last wire"

	    } else {
		set wire [string trim [string range $line 0 [expr $pos - 1]]]
	    }

	    # look for an optional wire width
	    set ppos [string first \( $wire]

	    setl {layer width} [string range $wire 0 [expr $ppos - 1]]

	    if {$width == ""} {
		# use default wire width
		set ww2 $ww2_default

		# puts "default width wire: $wire"
	    } else {
		# there is a wire width
		set ww2 [uusnap [expr $width / ( $grid * 2.0 )]]

		# puts "wire with width $ww2: $wire"
	    }
	    set wire [string range $wire $ppos end]

	    # puts "wire after stripping layername: $wire"

	    regsub -all {\(|\)} $wire " " wire
	    setl {x1 y1 x2 y2} $wire

	    if {$x1 == "*"} {
		set x1 $lastx
	    }
	    set lastx $x1

	    if {$y1 == "*"} {
		set y1 $lasty
	    } 
	    set lasty $y1

	    if {$x2 == "*"} {
		set x2 $lastx
	    }
	    set lastx $x2

	    if {$y2 == "*"} {
		set y2 $lasty
	    } 
	    set lasty $y2

	    # puts "parsed points: x1=$x1 y1=$y1 x2=$x2 y2=$y2"

	    if {$y2 == ""} {
	      # via

	      set x1 [expr $x1 / $grid] 
	      set y1 [expr $y1 / $grid]

	      foreach via $VIAS($x2) {
		setl {layer xx1 yy1 xx2 yy2} $via
		lay_box [expr $x1 + $xx1] [expr $y1 + $yy1] \
		    [expr $x1 + $xx2] [expr $y1 + $yy2]
		:paint $layer
	      }

	    } else {

	      if {$x1 == $x2} {
		set xx1 [expr $x1 / $grid - $ww2] 
		set yy1 [expr $y1 / $grid]
		set xx2 [expr $x2 / $grid + $ww2] 
		set yy2 [expr $y2 / $grid]

	      } elseif {$y1 == $y2} {
		set xx1 [expr $x1 / $grid] 
		set yy1 [expr $y1 / $grid - $ww2]
		set xx2 [expr $x2 / $grid] 
		set yy2 [expr $y2 / $grid + $ww2]

	      } else {
		set xx1 [expr $x1 / $grid] 
		set yy1 [expr $y1 / $grid]
		set xx2 [expr $x2 / $grid] 
		set yy2 [expr $y2 / $grid]

	      }
	      lay_box $xx1 $yy1 $xx2 $yy2
	      set max_layer [expr {[info exists MC(xlate,$layer)] ? $MC(xlate,$layer) : [string tolower $layer]}]
	      :paint $max_layer

	      if {$netname != ""} {
		setl {lx1 ly1} [center_coords $xx1 $yy1 $xx2 $yy2]
		lay_box $lx1 $ly1 $lx1 $ly1
		:label $netname c $max_layer

		set netname ""
	      }
	    }

	    set line [string range $line [expr $pos + 3] end]
	  }
	}
      }
    }
  }

  # close the file
  close $FILE_ID

  db_notify
  eval lay_box [lay_bbox]
  sel_clear
  :view

  undo_enable

  puts "Read $count devices and $nets nets into cell \"$cell_name\"."
  puts "done."
}






set DEF_ORIENT() N
set DEF_ORIENT(fx) FN
set DEF_ORIENT(fy) FS
set DEF_ORIENT(r180) S

set DEF_ORIENT(r90) E
set DEF_ORIENT(fx_r90) FE
set DEF_ORIENT(fy_r90) FW
set DEF_ORIENT(r270) W

proc write_def {{filename ""}} {

  global DEF_ORIENT FP_GRID TRACKS LEF_SIZE_HEIGHT

  puts "Creating DEF file $filename ..."

  if {$filename == ""} {
    # use the current cell and path
    set path [file rootname [lindex [cell_info [lay_rootcell]] 1]]
    if {[file dir $path] == "."} {
      set path [pwd]/$path
    }
    set filename $path.def
  }

  if {[file exists $filename]} {
    # query user before stomping on existing def file
    set message "The file \"$filename\" already exists.  Overwrite?"
    set choice [tk_dialog .dialog "Export DEF" $message {} 0 \
		    Yes Cancel]
    if { $choice != 0 } { 
      # user hit the cancel button
      return
    }
  }

  if {![info exists LEF_SIZE_HEIGHT]} {
    read_lef
  }

  if {[catch "open $filename w" FILE_ID]} {
    # problem
    puts "Aborting: $FILE_ID"
    return
  } 

  undo_disable

  # need to expand all hierarchy properly
  # first unexpand everything
  eval lay_box [lay_bbox]
  lay_internals -area
  lay_internals -area -hide

  # select each top level cell and expand
  eval sel_area -layers subcell [lay_bbox]
  foreach cell_info [split [sel_what cells] \n] {
    _fp_expand [lindex $cell_info 0] [lindex $cell_info 1]
  }

  puts "Expanded hierarchy."

  _fp_align

  puts "Aligned rows."

  eval lay_box [lay_bbox]
  eval sel_area -layers subcell [lay_bbox]
  :view

  # show the user that we got this far
#  update

  puts "Writing DEF file ..."

  puts $FILE_ID "DESIGN [lay_rootcell] ;\n"

  puts $FILE_ID "UNITS DISTANCE MICRONS 1000 ;"
  puts $FILE_ID ""

  set grid $FP_GRID(pitch)

  setl {x1 y1 x2 y2} [round_round_list_scale \
			  [_round_and_scale_list [lay_bbox] 1000] $FP_GRID(row)]

  puts $FILE_ID "DIEAREA ( $x1 $y1 ) ( $x2 $y2 ) ;"
  puts $FILE_ID ""

  # Add something like:
  # TRACKS Y 500 DO 84 STEP 1000 LAYER M1 M2 M3 M4 ;
  # TRACKS X 500 DO 188 STEP 1000 LAYER M1 M2 M3 M4 ;
  foreach d [array names TRACKS] {
    setl {d1 d2 tmp1 tmp2 start tmp3 num tmp4 step} $TRACKS($d)

    if {$d == "X"} {
      set new_start [expr $start - $d1 + $x1]
      set new_end [expr $x2 - ($d2 - ($start + $step * $num))]
    } else {
      set new_start [expr $start - $d1 + $y1]
      set new_end [expr $y2 - ($d2 - ($start + $step * $num))]
    }

    set new_num [expr int(($new_end - $new_start)/$step)]

    puts $FILE_ID "[lrange $TRACKS($d) 2 3] $new_start DO $new_num [lrange $TRACKS($d) 7 end] ;"
  }
  puts $FILE_ID ""

  # get all of the cells
  eval sel_area -layers subcell -any_cell [lay_bbox]

  set cells [split [sel_what cells] \n]
  set number [llength $cells]
  puts $FILE_ID "COMPONENTS $number ;"

  set count 0
  foreach cell_info [split [sel_what cells] \n] {

    setl {name type x1 y1 x2 y2 path expansion transform} $cell_info
    set x1 [expr round( round(1000.0*$x1/$grid) * $grid ) ] 
    set y1 [expr round( round(1000.0*$y1/$grid) * $grid ) ] 

    regsub -all ! $name / name

    set orient $DEF_ORIENT([orientation $transform])
    puts $FILE_ID "- $path$name $type + FIXED ( $x1 $y1 ) $orient ;"

    incr count
    if {[expr $count % 1000] == 0} {
      puts "... $count ..."
    }
  }

  puts $FILE_ID "END COMPONENTS\n"
  puts $FILE_ID "END DESIGN"

  # close the file
  close $FILE_ID

  sel_clear

  undo_enable

  puts "Wrote DEF file with $number components to \"$filename\"."
}


# expand cell below to certain amount

proc _fp_expand {cell type} {

  global LEF_SIZE_HEIGHT

  if {[info exists LEF_SIZE_HEIGHT($type)]} {
    # this is a primitive, don't select any further
    return 
  }

  sel_cell $cell

  # expand this
  lay_internals

  # get all subcells
  eval sel_area -layers subcell [lay_bbox]

  foreach cell_info [split [sel_what cells] \n] {

    setl {name type x1 y1 x2 y2 path} $cell_info

    if {$path == "$cell/"} {
      # this cell is correct, try to expand downwards
      _fp_expand $path$name $type
    }
  }
}


# align vertically through hierarchy so that non flipped rows are aligned
# to row_grid*2 and flipped rows are aligned to row_grid*2+row_grid
# Doesn't flip rows.

proc _fp_align {} {

  eval lay_box [lay_bbox]
  eval sel_area -layers subcell [lay_bbox]

  foreach cell_info [split [sel_what cells] \n] {
    # ignore rotated guys
    switch Q_[orientation [lindex $cell_info 8]] {
      Q_ - Q_fx - Q_fy - Q_r180 {
	_fp_align_internal [lindex $cell_info 0] [lindex $cell_info 1]
      }
    }
  }
}

proc _fp_align_internal {cell type} {

  global LEF_SIZE_HEIGHT FP_GRID

  if {[info exists LEF_SIZE_HEIGHT($type)]} {
    # this is a primitive, stop search
    return 
  }

  sel_cell $cell
  setl {x1 y1 x2 y2} [lay_box]

  # search for lowest row of cells
  set name ""
  set offset [expr $y1 + $FP_GRID(row) / 2.0]
  while {$name == ""} {
    lay_box $x1 $y1 $x2 $offset
    eval sel_area -layers subcell [lay_bbox]

    setl {name _type _x1 _y1 _x2 _y2 path expansion transform} [sel_what cells]
# need to check path
    set offset [expr $offset + $FP_GRID(row)]

    if {$offset > $y2} {
      # no cells, don't worry about alignment
      return
    }
  }

  # determine offset based on orientation of cell in lowest row
  switch Q_[orientation $transform] {
    Q_ - Q_fx {
      # N row
      set dy [expr $_y1 - [round_scale $_y1 [expr $FP_GRID(row) * 2]]]
    }

    Q_fy - Q_r180 {
      # S row
      set dy [expr $_y1 - $FP_GRID(row) - \
		  [round_scale [expr $_y1 - $FP_GRID(row)] [expr $FP_GRID(row) * 2]]]
    }
  }

  if {$dy != 0} {
    # now move to alignment
    sel_cell $cell
    :move s $dy
    puts "  moved $cell up by $dy"
  }

  # now need to recurse
# needs to be done as edit in place (need edit in place push/pop)
# sel_cell $cell
# push into in place
#  _fp_align
# pop out of in place
}




proc _round_and_scale_list {list scale} {

  set new ""
  foreach value $list {
    lappend new [expr int($value * $scale)]
  }

  return $new
}

# Like the system one but rounds to integer (I know,
# seems weird but it works).

proc round_round_list_scale {x scale} { 
 
  set out "" 
  foreach y $x { 
    lappend out [expr round(round(1.0*$y/$scale)*$scale)] 
  } 
 
  return $out 
} 

proc round_scale {x scale} { 
 
  return [expr round(1.0*$x/$scale) * $scale] 
} 





# Makes a boundary-only max cell

proc make_prb_cell {type} {

  global CELL LEF_SIZE_HEIGHT LEF_SIZE_WIDTH MC DEFAULT_HEIGHT DEFAULT_WIDTH
  global USE_DEFAULTS

  if {![info exists LEF_SIZE_HEIGHT($type)]} {
    if {[use_first USE_DEFAULTS] != 1} {
      # ask user for lef file
      puts "WARNING: no LEF size for cell $type."
      if {[read_lef] == ""} {
	# user gave up, just use defaults from now on
	set USE_DEFAULTS 1
      }
    }
  }

  if {![info exists LEF_SIZE_HEIGHT($type)]} {
    puts "WARNING: no LEF size for cell $type, using defaults ($DEFAULT_WIDTH x $DEFAULT_HEIGHT)."
    set LEF_SIZE_WIDTH($type) $DEFAULT_WIDTH
    set LEF_SIZE_HEIGHT($type) $DEFAULT_HEIGHT
  }

  # make a new cell
  db_cell_new $type $type$CELL(default_suffix) 

  # add prb layer
  db_paint -cell $type $MC(boundary) 0 0 \
      $LEF_SIZE_WIDTH($type) $LEF_SIZE_HEIGHT($type)

#  puts "Made cell $type."
}

# create a new cell if there isn't one in max of this name

proc fp_goto_cell {cell_name} {

  global CELL

  if {![cell_in_memory $cell_name]} {
    # create the new cell
    puts stderr "Creating cell $cell_name"
    db_cell_new $cell_name $cell_name$CELL(default_suffix)
    # goto the cell
    cell_load $cell_name

  } else {
    # goto the cell
    cell_load $cell_name

    # query user before stomping on existing def file
    set message "The cell \"$cell_name\" already exists.  Erase?"
    set choice [tk_dialog .dialog "Import DEF" $message {} 0 \
		    Yes Cancel]
    if { $choice != 0 } { 
      # user hit the cancel button
      return 0
    }

    # toast the contents of the cell
    eval sel_area [lay_bbox]
    :delete
  }

  return 1
}

# add to menu
menu_local_cmd "read lef" read_lef
menu_local_cmd "read def" read_def
menu_local_cmd "write def" write_def


# examples

#read_lef /proj/tech/mmi25/library/lef/mmi25.lef 
#read_def

