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

# megacell compiler

# TODO: let the user redefine macros also for different sizes

# NOTE: ARRAY for backward compatibility to MACRO

set MC(loaded) 1

# orientation transformations

# transform from SUE orientations to MAX orientations
set MC_XFORM(R0) {}
set MC_XFORM(RY) fy
set MC_XFORM(RX) fx
set MC_XFORM(RXY) r180
set MC_XFORM(R90) r90
set MC_XFORM(R90X) fy_r90
set MC_XFORM(R90Y) fx_r90
set MC_XFORM(R270) r270

set MC_XFORM() {}
set MC_XFORM(fy) fy
set MC_XFORM(fx) fx
set MC_XFORM(r180) r180
set MC_XFORM(r90) r90
set MC_XFORM(fy_r90) fy_r90
set MC_XFORM(fx_r90) fx_r90
set MC_XFORM(r270) r270

# start orient, orient --> new orient
set MC_XFORM(,) {}
set MC_XFORM(,fx) fx
set MC_XFORM(,fy) fy
set MC_XFORM(,r180) r180
set MC_XFORM(fx,) fx
set MC_XFORM(fx,fx) {}
set MC_XFORM(fx,fy) r180
set MC_XFORM(fx,r180) fy
set MC_XFORM(fy,) fy
set MC_XFORM(fy,fx) r180
set MC_XFORM(fy,fy) {}
set MC_XFORM(fy,r180) fx
set MC_XFORM(r180,) r180
set MC_XFORM(r180,fx) fy
set MC_XFORM(r180,fy) fx
set MC_XFORM(r180,r180) {}

# TODO: Need to complete this table for other rotations
set MC_XFORM(r90,) r90
set MC_XFORM(fy_r90,) fy_r90
set MC_XFORM(fx_r90,) fx_r90
set MC_XFORM(r270,) r270
set MC_XFORM(,r90) r90
set MC_XFORM(,fy_r90) fy_r90
set MC_XFORM(,fx_r90) fx_r90
set MC_XFORM(,r270) r270

# for stretching
set MC_XFORM(,type) ""
set MC_XFORM(fx,type) ""
set MC_XFORM(fy,type) ""
set MC_XFORM(r180,type) ""
set MC_XFORM(r90,type) rotate
set MC_XFORM(fy_r90,type) rotate
set MC_XFORM(fx_r90,type) rotate
set MC_XFORM(r270,type) rotate

# info for figuring out placement/spacing from orientation
set MC_XFORM(,expand) "noflip noflip 1 2 0 1"
set MC_XFORM(fx,expand) "flip noflip 1 2 0 1"
set MC_XFORM(fy,expand) "noflip flip 1 2 0 1"
set MC_XFORM(r180,expand) "flip flip 1 2 0 1"

set MC_XFORM(r90,expand) "noflip flip 2 1 1 0"
set MC_XFORM(fx_r90,expand) "noflip noflip 2 1 1 0"
set MC_XFORM(fy_r90,expand) "flip flip 2 1 1 0"
set MC_XFORM(r270,expand) "flip noflip 2 1 1 0"


proc _mc_make {args} -desc {
  run the megacell generator
} {
  
  global WH TOP_CELL max_win MACRO ARRAY STRETCH MC MC_DATA_INT MC_LEAF
  global MC_CELLS

  if {[llength $args] == 0} {
    # get the parameters from the menu
    set win $max_win.layout
    set winy [expr [winfo rooty $win] + 50]
    set winx [expr [winfo rootx $win] + 50]

    set title "megacell generator"
    set message "Make array:" 
    set prop_list [list [list name [use_first MC(default_generator)]] \
		        "program 1 binary" \
		        "propagate 1 binary" \
		      ]

    # create the menu
    set new_prop_list [prop_menu $winx $winy $message $title $prop_list]

    if {$new_prop_list == ""} {
      # empty list means the user hit cancel
      return
    }

    set name [get_assoc name $new_prop_list] 
    set program [get_assoc program $new_prop_list] 
    set propagate [get_assoc propagate $new_prop_list] 

  } else {

    # get the arguments from the command line
    set name [call_with_keyword $args {{program 1} {propagate 1}}]
  }

  # force the width/height information for the cells to be recomputed.
  catch {unset WH}
  catch {unset MC_DATA_INT}
  catch {unset MC_LEAF}
  catch {unset MC_CELLS}

  catch {unset STRETCH}

  # for create temporary cells in MAX
  set MC(tmp_cell) 0

  undo_disable

  if {![info exists MACRO($name)] && ![info exists ARRAY($name)]} {
    set message "Aborting, don't know how to build \"$name\".  Typo?  Did you source the control file?"
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK
    return
  }

  # remember this as the default generator for next time
  set MC(default_generator) $name

  # now prompt user to change generator params if they are defined
  # and the user didn't call this in batch mode
  if {[llength $args] == 0} {

    set win $max_win.layout
    set winy [expr [winfo rooty $win] + 50]
    set winx [expr [winfo rootx $win] + 50]

    set title "$name generator"
    set message "Edit Parameters:" 
    set prop_list ""

    set suffix ""
    foreach param [use_first MC($name,parameters)] {
      global $param
      lappend prop_list [list $param $param -entry]

      append suffix "_\$\{$param\}"
    }

    lappend prop_list [list "" "" -separator]

    # add in prefix, suffix, and name
    set MC(prefix) [use_first MC($name,prefix)]
    lappend prop_list [list prefix MC(prefix) -entry]

    set MC(suffix) [use_first MC($name,suffix) suffix]
    lappend prop_list [list suffix MC(suffix) -entry]

    set MC(name) [use_first MC($name,name)]
    lappend prop_list [list name MC(name) -entry -help "The name given to the top level generated cell"]

    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
      # cancelled
      return ""
    }
  }

  foreach thing "prefix suffix name" {
    set MC($thing) [uplevel #0 "concat [use_first MC($name,$thing)]"]
  }

  # call the setup procedure for this if there is one
  if {[info commands setup_$name] != ""} {
    # do it
    puts "\nSetup ..."
    if {[catch setup_$name msg]} {
      puts "ERROR: $msg while executing \"setup_$name\".\n"
    }
  } else {
    puts "\nINFO: No setup program to execute (missing \"setup_$name\" proc).\n"
  }

  # figure out the name of the top level cell
  set tmp "[use_first MC(prefix)]$name[use_first MC(suffix)]"
  set MC_DATA_INT($name) [use_first MC(name) tmp]

  # go
  puts "Building \"$MC_DATA_INT($name)\" from generator \"$name\" ..."

  # first make and goto this cell
  _mc_make_cell $MC_DATA_INT($name)

  # save where we are
  set TOP_CELL [lay_rootcell]

  setl {x1 y1 x2 y2} [_mc_make_int $name]
  puts "array size = [pp_number [expr 1.0e-6 * ($x2 - $x1)]]m wide x [pp_number [expr 1.0e-6 * ($y2 - $y1)]]m tall.\n"

#  if {[lindex $MACRO($name) 0] == "CELL"} {
#    # the user has specified that this megacell goes into it's own cell
#    # so go there
    :load [lindex $MC_DATA_INT($name) 0]
#  }

  if {$program == 1} {
    # program with the same name as the megacell
    if {[info commands program_$name] != ""} {
      # do it
      puts "Programming ..."
      if {[catch program_$name msg]} {
	puts "ERROR: $msg while executing \"program_$name\".\n"
      }

    } else {
      puts "WARNING: Programming skipped. Couldn't find \"program_$name\" proc.\n"
    }
  }

  # go to top level (programming could have changed it).
  :load [lindex $MC_DATA_INT($name) 0]

  if {$propagate == 1} {
    # propagate terms
    propagate_ports $name
  }

  sel_clear
  eval lay_box [lay_bbox]
  :view

  undo_enable

  puts "Done."
}


proc _mc_make_int {type {x ""} {y ""} {top_orient {}} {hiername ""}
  {side bottom} {offset 0}} -desc {
Either calls the macro placer or the cell placer.  The macro placer
then recursively calls this back.
} {

  global MACRO MC_XFORM ARRAY MC_DATA DATA MC_CELLS

  if {$x == "" || $y == ""} {
    setl {x y} [lay_box]
    if {$x == "" || $y == ""} {
      setl {x y} {0 0}
    }
  }

  setl {name orient instname} $type

  # transform to MAX orientation
  set orient $MC_XFORM($orient)

  set args [lrange $type 3 end]
  if {$hiername != ""} {
    if {$instname == ""} {
      set instname "$hiername.$name"
    } else {
      set instname "$hiername.$instname"
    }
  }

  if {$orient == ""} {
    set orient $top_orient
  } else {
    set orient $MC_XFORM($orient,$top_orient)
  }

  if {[info exists MACRO($name)] || [info exists ARRAY($name)]} {
    # this is a macro
    # backward compatibility
    set MACRO($name) [use_first MACRO($name) ARRAY($name)]

    if {[lindex $MACRO($name) 0] == "CELL"} {
      # this will be placed like a cell
      return [_mc_place_cell $name $orient $instname $args $x $y $side $offset macro]
    }
    if {[info exists MC_DATA($name)] || [info exists DATA($name)]} {
      # uh oh, it's also a cell name
      puts "WARNING, \"$type\" shouldn't be defined in MC_DATA array."
    }

    if {$side == "top"} {
      # TODO: use sel_transform instead -- preserves names
      # special case.  Must place as a cell and then flatten.
      global MC MC_DATA_INT CELL

      if {[info exists MC_DATA_INT($name)]} {
	# use existing temporary cell
	set tmp_name [lindex $MC_DATA_INT($name) 0]
      } else {
	# make a new temporary cell
	set tmp_name _MC_TMP_[incr MC(tmp_cell)]_
	set MC_DATA_INT($name) $tmp_name

	set flags [cell_flags $tmp_name]
	if { $flags == "__NO_SUCH_BUFFER__" } {
	  # create the new internal cell
	  db_cell_new -internal $tmp_name $tmp_name$CELL(default_suffix)
	}
      }

      set return \
	  [_mc_place_cell $name $orient $instname $args $x $y $side $offset macro]
      # now flatten
      # TODO: Hack, this is how max labels stuff
      _mc_flatten "${tmp_name}_0"
      sel_clear

      return $return
    }

# source ~/dev/mc2.0/mc.tcl ; mc_build test

    set save [use_first MC_CELLS([lay_rootcell])]
    set MC_CELLS([lay_rootcell]) ""

    # we will do the orienting later
#    set return [_mc_make_macro $name $orient $instname $x $y $side $offset]
    set return [_mc_make_macro $name "" $instname $x $y $side $offset]

    if {$orient != ""} {
      # select the appropriate cells and reorient them
      sel_clear
      foreach cell $MC_CELLS([lay_rootcell]) {
	sel_cell -more $cell
      }

      eval sel_transform -fix [eval center_coords $return] $orient
    }

    # restore complete for potential calling macro
    set MC_CELLS([lay_rootcell]) [concat $save $MC_CELLS([lay_rootcell])]

    return $return

  } else {
    return [_mc_place_cell $name $orient $instname $args $x $y $side $offset]
  }
}


proc _mc_make_macro {name orient instname start_x start_y side offset} -desc {
  places a macro which is a group of other macros/cells
} {

  global MACRO

  set y $start_y
  set max_x $start_x

  foreach line [_mc_expand $MACRO($name)] {

    if {$line == "CELL"} {
      continue
    }
    if {[lindex $line 0] == "SPACE"} {
      # this produces a vertical space between rows
      set dy [uplevel \#0 "expr [lrange $line 1 end]"]
      set y [expr $y + $dy]
      continue
    }

    # deprecated
    if {[lindex $line 0] == "PLACE"} {
      set line [list [lrange $line 1 end]]
    }

    set x $start_x
    set max_dy 0
    # the side is reset for each line for now
    set side bottom
    set offset 0

    # NOTE that TOP or BOTTOM alignment can only be changed at beginning 
    # of line.  TOP is only useful for first row since it builds down.

    foreach type $line {
      switch [lindex $type 0] {
	SPACE {
	  # this produces a horizontal space between macros/cells
	  if {[catch "uplevel #0 expr [lrange $type 1 end]" msg]} {
	    puts "ERROR, ignoring illegal distance in command: $type\n\t$msg"
	  } else {
	    set x [expr $x + $msg]
	  }
	  continue
	}

	TOP {
	  set side top
	  continue
	}

	BOTTOM {
	  set side bottom
	  set offset 0
	  continue
	}

	default {
	  # place it (returns bbox)
	  setl {x1 y1 x2 y2} \
	     [_mc_make_int $type $x $y $orient $instname $side $offset]
	  if {$y2 == ""} {
	    # bug somewhere
	    return ""
	  }

	  # compute max height to figure out where to start the next row
	  if {$side == "top"} {
	    # special case, height determined by first cell
	    if {$max_dy == 0} {
	      set max_dy [expr $y2 - $y1]
	    }

	  } else {
	    set max_dy [max $max_dy [expr $y2 - $y1]]
	  }

	  if {$side == "top" && $offset == 0} {
	    # align to top of first cell in line
	    set offset [expr $y2 - $y1]
	  }
	}
      }

      # increment x for next cell/macro
      set x [expr $x + ($x2 - $x1)]
    }

    set max_x [max $x $max_x]

    # this row of cells/macros is placed, now increment y
    set y [expr $y + $max_dy]
  }

  return "$start_x $start_y $max_x $y"
}


proc _mc_place_cell {name orient instname args x y side offset {macro ""}} -desc {
  places a given cell at the given coordinates with the given orientation.
} {

  global MC_DATA_INT MC_DATA MC_XFORM WH TOP_CELL CELL MC MC_LEAF DATA MC_CELLS

  # if we don't know the width and height of this cell, get it
  # also generate the name for any macros
  if {![info exists WH($name)]} {
    if {[use_first MC_DATA_INT($name)] == ""} {
      if {$macro != ""} {
	# macro
	set MC_DATA_INT($name) \
	    "[use_first MC(prefix)]$name[use_first MC(suffix)]"
      } else {
	# leaf cell
	# Note: this will copy the MC_DATA array also
	# DATA for backwards compatibility
	set MC_DATA_INT($name) [use_first MC_DATA($name) DATA($name) name]
      }
    }

    set cell_name [lindex $MC_DATA_INT($name) 0]

    if {$macro != ""} {
      # create a new cell if there isn't one in max of this name
      _mc_make_cell $cell_name

      # remember the old top cell
      set save_top_cell $TOP_CELL
      set TOP_CELL $cell_name

      # make the macro in the new cell
      setl {bx1 by1 bx2 by2} \
	  [_mc_make_macro $name {} $instname 0 0 $side $offset]

      # save dimensions of macro
      set MC_DATA_INT($name) \
	  [list [lindex $MC_DATA_INT($name) 0] $bx1 $by1 $bx2 $by2]

      # cache width and height of cell
      set WH($name) "[expr $bx2 - $bx1] [expr $by2 - $by1]"

      # restore the old top cell
      set TOP_CELL $save_top_cell
    
    } else {
      # not a macro (i.e. a cell)

#      set MC_LEAF($cell_name) 1

      # goto the cell
      :load $cell_name

      if {![msg_catch "sel_area -layers $MC(boundary) [lay_bbox]" a b] && \
	      [sel_what paint] != ""} {
	# there is a layer of this type, use it for boundary.
	# overwrite any existing bbox data in the MC_DATA_INT array
	set bx1 1.0e8
	set by1 1.0e8
	set bx2 -1.0e8
	set by2 -1.0e8
	# get the smallest rectangle that includes all paint on this layer
	foreach paint [split [sel_what paint] \n] {
	  setl {layer _x1 _y1 _x2 _y2} $paint
	  set bx1 [min $bx1 $_x1]
	  set by1 [min $by1 $_y1]
	  set bx2 [max $bx2 $_x2]
	  set by2 [max $by2 $_y2]
	}

      } else {
	set bbox [lindex [split [db_search labels bbox] \n] 0]
	if {$bbox != ""} {
	  # there is a bbox label in the cell.
	  # overwrite any existing bbox data in the MC_DATA_INT array
	  setl {bogus bx1 by1 bx2 by2} $bbox

	} else {
	  # no bbox.  Just use the max bbox of the cell if not specified
	  # by the user.
	  if {[llength $MC_DATA_INT($name)] < 5} {
	    setl {bx1 by1 bx2 by2} [lay_bbox]
	  } else {
	    setl {bx1 by1 bx2 by2} [lrange $MC_DATA_INT($name) 1 5]
	  }
	}
      }

      set MC_DATA_INT($name) \
	  [list [lindex $MC_DATA_INT($name) 0] $bx1 $by1 $bx2 $by2]

      # cache width and height of cell
      set WH($name) "[expr $bx2 - $bx1] [expr $by2 - $by1]"
    }

    # go back to the top most cell
    :load $TOP_CELL
  }

  # look for stretches
  set left 0
  set right 0
  if {[lindex $args 0] == "STRETCH"} {
    setl {stretch left right} $args
    set left [uplevel \#0 "expr $left"]
    if {$right == ""} {
      set right 0
    } elseif {$right == "center"} {
      # make sure these numbers are on grid
      set right [uusnap [expr $left / 2.0]]
      set left [expr $left - $right]
    } else {
      set right [uplevel \#0 "expr $right"]
    }
  }

  # place the cell (referenced to origin in cell)
  setl {xflip yflip xi yi dxi dyi} $MC_XFORM($orient,expand)
  if {$xflip == "flip"} {
    set this_x [expr $x + [lindex $MC_DATA_INT($name) $xi] + \
		    [lindex $WH($name) $dxi] + $left]

  } else {
    set this_x [expr $x - [lindex $MC_DATA_INT($name) $xi] + $left]
  }

  if {$yflip == "flip"} {
    set this_y [expr $y + [lindex $MC_DATA_INT($name) $yi] + \
		    [lindex $WH($name) $dyi]]
  } else {
    set this_y [expr $y - [lindex $MC_DATA_INT($name) $yi]]
  }

  if {$side == "top"} {
    # if there is an offset, this is not the first cell.  Line up to first.
    if {$offset != 0} {
      set this_y [expr $this_y + $offset - [lindex $WH($name) 1]]
    }
  }

#puts "--> $MC_DATA_INT($name), $WH($name)"
#puts "$name ($x $y) $this_x $this_y $orient"

  set cell [lindex $MC_DATA_INT($name) 0]
  # place it with the correct orientation
  if {[msg_catch [list db_instance -orientation $orient $cell $this_x $this_y] \
	   return info warn]} {
    # error
    if {$cell != [lay_rootcell]} {
      puts "Aborting, $return $info $warn"
    }
    return "0 0 0 0"
  }

  # did the user specify a name for this?
  if {$instname != ""} {
    # give this instance a name if not a duplicate
    sel_cell $return
    set return $instname
    if {[msg_catch ":identify $instname"]} {
      # failed, must be a duplicate name
      regsub {_[0-9]+$} $instname "" root
      for {set i 0} {1} {incr i} {
	if {![msg_catch ":identify ${root}_$i"]} {
	  # found a unique name
	  set return "${root}_$i"
	  break
	}
      }
    }
  }

  # save this away
  lappend MC_CELLS([lay_rootcell]) $return

  setl {width height} $WH($name)

  if {$left != 0 || $right != 0} {
    sel_cell $return
    _mc_stretch $orient \
	$y [expr $y + $height] \
	[expr $x] [expr $x + $left] \
	[expr $x + $left + $width] [expr $x + $left + $width + $right]
  }

  # NOTE: stretching only works left and right
  if {$MC_XFORM($orient,type) == "rotate"} {
    return "$x $y [expr $x + $height] [expr $y + $width]"
  } else {
    return "$x $y [expr $x + $width + $left + $right] [expr $y + $height]"
  }
}


proc _mc_expand {array {depth 1}} -desc {
  expands macros
} {

  if {$depth < 0} {
    return $array
  }
  incr depth -1

  set result ""
  foreach line $array {
    if {[lindex $line 0] == "REPEAT"} {
      # calls _mc_REPEAT with args from $line
      set result "$result [uplevel \#0 _mc_$line]"
    } else {
      lappend result [_mc_expand $line $depth]
    }
  }

  return $result
}


proc _mc_REPEAT {number thing {prefix ""} {start 0} {increment 1}} -desc {
  expands REPEAT statements in macros.  called by _mc_expand.
} {

  global MACRO

  # expand contents of repeated thing.
  set thing [_mc_expand $thing]

  set result ""
  for {set i 0} {$i < $number} {incr i; incr start $increment} {
    if {$prefix == ""} {
      lappend result $thing
    } elseif {[info exists MACRO([lindex $thing 0])]} {
      # TODO is this required -- maybe needs another set of parens???
      lappend result [list PLACE \
			  [lindex $thing 0] [lindex $thing 1] "$prefix$start"]
    } else {
      lappend result [list [lindex $thing 0] [lindex $thing 1] "$prefix$start"]
    }
  }

  return $result
}


proc _mc_make_cell {cell_name} -desc {
  makes a new cell or if one exists, deletes contents.  Also goes to cell.
} {

  global CELL

  set flags [cell_flags $cell_name]
  if { $flags == "__NO_SUCH_BUFFER__" } {
    # create the new cell
    puts "Creating cell $cell_name"
    db_cell_new $cell_name $cell_name$CELL(default_suffix)

    # goto the cell
    :load $cell_name

  } else {
    # exists, goto the cell
    :load $cell_name

    # toast the contents of the cell
    # It's faster to delete any paint with :erase first
    eval lay_box [lay_bbox]
    :erase

    eval sel_area [lay_bbox]
    :delete
  }
}


# NOT USED

proc _mc_compute_stretch {cell} -desc {
  compute what metal layers need to be added to stretch this cell
} {

  global STRETCH

  if {[info exists STRETCH($cell,left)]} {
    # already computed this
    return
  }

  # save where we are
  set save_cell [lay_rootcell]

  # goto this cell
  :load $cell

  # find bbox of cell
  sel_clear
  sel_labels -text bbox

  set label [sel_what labels]
  if {$label == ""} {
    # no bbox, just use the bbox of the cell
    setl {x1 y1 x2 y2} [lay_bbox]
  } else {
    # get the bbox from the label
    setl {layer x1 y1 x2 y2} $label
  }

  set STRETCH($cell,left) ""

  # only know how to stretch metal layers
  set metals ""
  foreach via [techinfo vias] {
    lappend metals [techinfo above $via]
  }

  # find wires along left edge
  sel_area -any_cell -layers [join $metals ,] \
      [expr $x1 - [res]] $y1 [expr $x1 + [res]] $y2

  foreach paint [split [sel_what paint] \n] {
    setl {layer x1p y1p x2p y2p} $paint
    lappend STRETCH($cell,left) "$layer [expr $y1p - $y1] [expr $y2p - $y1]"
  }

  set STRETCH($cell,right) ""

  # find wires along right edge
  sel_area -any_cell -layers [join $metals ,] \
      lay_box [expr $x2 - [res]] $y1 [expr $x2 + [res]] $y2

  foreach paint [split [sel_what paint] \n] {
    setl {layer x1p y1p x2p y2p} $paint
    lappend STRETCH($cell,right) "$layer [expr $y1p - $y1] [expr $y2p - $y1]"
  }

  # return to where we were
  :load $save_cell
}


proc _mc_stretch {orient y1 y2 x1l x2l x1r x2r} -desc {
  stretch paint that intersects the cell bbox
} {

  # TODO: BUG: IGNORES ORIENT FOR NOW!!!!

  # only stretch metal layers
  set metals ""
  foreach via [techinfo vias] {
    lappend metals [techinfo above $via]
  }

  set save_box [lay_box]
  lay_internals

  # fill left
  lay_box $x1l $y1 $x2l $y2
  :fill left [join $metals ,]

  # fill right
  lay_box $x1r $y1 $x2r $y2
  :fill right [join $metals ,]

  eval lay_box $save_box
  lay_internals -hide
}


proc propagate_ports {name} -desc {
  propagate ports (labels) to the current cell
} {

  global MC

  puts "\nPropagating ports in cell \"[lay_rootcell]\" ..."

  # must be completely expanded
  eval lay_box [lay_bbox]
  lay_internals -area

  if {![info exists MC($name,propagate)]} {
    puts "WARNING, MC($name,propagate) not defined.  No ports propagated."
    return
  }
    
  set count 0
  foreach command $MC($name,propagate) {
    switch [string tolower [lindex $command 0]] {
      count {
	foreach list [lrange $command 1 end] {
	  setl {from to kind direction} $list

	  if {$to == ""} {
	    # use default
	    setl {cell port} [split $from /]
	    set to "$port\[%d\]"
	  }

	  # left | right | up | down (defaults to left if not defined)
	  set direction \
	      [use_first direction MC(default_propagate_direction) 'left]

	  switch $direction {
	    up { 
	      set index 1
	      set dir -increasing
	    }
	    down { 
	      set index 1
	      set dir -decreasing
	    }
	    left { 
	      set index 0
	      set dir -decreasing
	    }
	    right { 
	      set index 0
	      set dir -increasing
	    }
	  }

	  set i 0
	  foreach port_list [lsort -index $index -real $dir \
				 [_mc_find_ports $from]] {
	    
	    if {$kind == ""} {
	      set kind [lindex $port_list 3]
	    }

	    setl {x y layer} $port_list

	    # see if there is already a top level label here
	    sel_net -point $x $y $layer
	    if {[sel_what labels -edit_only tmp] != ""} {
	      # already a top level label here
	      continue
	    }

	    if {[catch [list db_label -kind $kind $layer [format $to $i] $x $y] msg]} {
	      # error
	      puts "ERROR, $msg"
	      continue
	    }

	    incr i
	    incr count
	  }

	  puts "\t$i ports: $from --> $to"
	}
      }

      prop - propagate {
	foreach list [lrange $command 1 end] {
	  setl {from to kind} $list

	  if {$to == ""} {
	    # use default
	    set to [lindex [lreverse [split $from /]] 0]
	  }

	  set i 0

	  foreach port_list [_mc_find_ports $from] {

	    if {$kind == ""} {
	      set kind [lindex $port_list 3]
	    }

	    setl {x y layer} $port_list

	    # see if there is already a top level label here (except globals)
	    if {$kind != "global"} {
	      sel_net -point $x $y $layer
	      if {[sel_what labels -edit_only tmp] != ""} {
		# already a top level label here
		continue
	      }
	    }

	    if {[catch [list db_label -kind $kind $layer $to $x $y] msg]} {
	      # error
	      puts "ERROR, $msg"
	      continue
	    }

	    incr i
	    incr count
	  }

	  puts "\t$i ports: $from --> $to"
	}
      }

      default {
	puts "ERROR, illegal propagation command: $command"
      }
    }
  }

  eval lay_box [lay_bbox]

  puts "propagated $count ports.\n"
}


proc _mc_find_ports {name} -desc {
  find the port locations
} {

  set ports ""

  set list [split $name /]
  set len [llength $list]

  set port [lindex $list [incr len -1]]
  set cell [join [lrange $list 0 [incr len -1]] /]

  # first check to see if this is an absolute path
  if {![msg_catch "sel_cell $cell" "" info warn]} {
    # this is an absolute path
    edit_push in_place
    sel_labels -text $port

    set label [sel_what labels]

    # pop back to top level
    edit_pop

    setl {layer x y} $label
    if {$layer == ""} {
      # something went wrong
      return ""
    }

    # got it
    return [list "$x $y $layer [lindex $label 9]"]
  }

  foreach path [_mc_find_paths $cell] {
    if {[info exists trace($path)]} {
      # already got this one
      continue
    }

    # need to push into cell (in place) to select label
    sel_cell $path
    edit_push in_place
    sel_labels -text $port

    set label [sel_what labels]

    # pop back to top level
    edit_pop

    setl {layer x y} $label
    if {$layer == ""} {
      # something went wrong
      continue
    }

    set kind [lindex $label 9]
    lappend ports "$x $y $layer $kind"

    if {$kind != "global"} {
      # see if there are any other labels attached to this
      sel_net -point $x $y $layer

      foreach label [split [sel_what labels] \n] {
	set trace([lindex $label 7]) 1
      }
    }
  }

  sel_clear
  return $ports
}


proc _mc_find_paths {name} -desc {
  find the paths to all cells of the given name from the current cell
} {

  set return ""
  foreach path [_mc_find_cells $name] {

    set current_cell [lay_rootcell]

    set paths ""
    foreach cell $path {
      
      set instnames ""
      foreach list [split [db_search cells -cell $current_cell] \n] {
	if {[lindex $list 1] == $cell} {
	  lappend instnames [lindex $list 0]
	}
      }

      lappend paths $instnames

      set current_cell $cell
    }

    # now build up all of the paths
    set results ""
    foreach list [lreverse $paths] {
      if {$results == ""} {
	set results $list
      } else {
	set new ""
	foreach instname $list {
	  foreach result $results {
	    lappend new "$instname/$result"
	  }
	}
	set results $new
      }
    }

    foreach result $results {
      lappend return $result
    }
  }

  return $return
}


proc _mc_find_cells {name {current_cell ""}} -desc {
  find the list to all cells of the given name from the current cell
} {

  global MC_LEAF

  set current_cell [use_first current_cell '[lay_rootcell]]
  set results ""

  foreach cell [db_kids $current_cell] {

    if {![info exists MC_LEAF($cell)]} {
      set save_cell [lay_rootcell]
      :load $cell

      # is this a leaf cell
      set MC_LEAF($cell) [_is_leaf_cell]

      :load $save_cell
    }

    if {$MC_LEAF($cell) == 1} {
      # found a leaf cell, does this match the name
      # allows * wildcarding
      if {[lsearch $cell $name] == 0} {
	lappend results $cell
      }

    } elseif {$cell == $name} {
      # not a leaf cell but exact match
      lappend results $cell

    } else {
      # descend
      set return [_mc_find_cells $name $cell]
      if {$return != ""} {
	foreach path $return {
	  lappend results "$cell $path"
	}
      }
    }
  }

  return $results
}


# NOT USED

# add labels to top level.  Normally for labels that aren't propagated
# like power supplies.

proc add_globals {filename} {

  if {[catch "open $filename r" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    return
  } 

  puts stderr "parsing $filename ..."
  # parses something of the form

  # center x y
  # bbox x1 y1 x2 y2
  # metal3 952.28 390.26 952.28 390.26 CENTER VSS {} 0 global

  set labels ""
  while {[gets $FILE_ID line] >= 0} {

    switch [lindex $line 0] {

      center {
	setl {center x y} $line
      }

      bbox {
	setl {bbox bx1 by1 bx2 by2} $line
      }

      default {
	setl {layer} $line

	if {$layer == "" || [string index $layer 0] == "\#"} {
	  # skip blank lines and comments
	  continue
	}

	if {[lsearch "metal1 metal2 metal3 metal4" $layer] == -1} {
	  puts "Syntax Error: $line"
	  continue
	}

	lappend labels $line
      }
    }
  }

  # close the file
  close $FILE_ID

  # get the new bbox
  setl {nbx1 nby1 nbx2 nby2} [lay_bbox]

  set count 0
  foreach label $labels {
    setl {layer x1 y1 x2 y2 pos text path group kind} $label

    if {$x1 < $x && $y1 < $y} {
      # this is referenced to the lower left edge of the design
      set nx [expr $x1 - $bx1 + $nbx1]
      set ny [expr $y1 - $by1 + $nby1]
    } elseif {$x1 > $x && $y1 < $y} {
      # this is referenced to the lower right edge of the design
      set nx [expr $x1 - $bx2 + $nbx2]
      set ny [expr $y1 - $by1 + $nby1]
    } elseif {$x1 > $x && $y1 > $y} {
      # this is referenced to the upper right edge of the design
      set nx [expr $x1 - $bx2 + $nbx2]
      set ny [expr $y1 - $by2 + $nby2]
    } else {
      # this is referenced to the upper left edge of the design
      set nx [expr $x1 - $bx1 + $nbx1]
      set ny [expr $y1 - $by2 + $nby2]
    }

    # put in a happy piece of metal
    lay_box [expr $nx - [res]] [expr $ny - [res]] \
	[expr $nx + [res]] [expr $ny + [res]]
    :paint $layer

    # now put in the nice label
    lay_box $nx $ny $nx $ny
    :label -kind $kind $text $pos $layer

    incr count
  }

  puts "Added $count labels."
}


# NOT USED

proc move_to_origin {} -desc {
  move the current cell so that the bounding box origin is at 0,0
} {

  update

  eval lay_box [lay_bbox]

  setl {x y} [lay_box]

  if {$x == 0 && $y == 0} {
    # already at origin
    return
  }

  eval sel_area [lay_bbox]
  
  :move w $x
  :move s $y

  sel_clear

  puts "Moved bounding box origin to 0,0."
}


proc _mc_flatten {name} -desc {
  simple flatten of only a single cell
} {

  sel_cell $name

  struct max_cell cell [sel_what cells]

  # toast old instance
  sel_cell ${cell.id}
  :delete

  layt_box exact ${cell.x1} ${cell.y1} ${cell.x1} ${cell.y1}

  # dump copy of cell
  :dump ${cell.def}
    
  # orient
  set orient [orientation ${cell.transform}]
  switch $orient {
    "r90" {
      :clockwise
    }
    "r180" {
      :clockwise 180
    }
    "r270" {
      :clockwise 270
    }
    "fx" {
      :sideways
    }
    "fy" {
      :upsidedown
    }
    "fx_r90" {
      :sideways
      :clockwise
    }
    "fy_r90" {
      :upsidedown
      :clockwise
    }
  }
}


# returns the wdith a the given cell.  The cell needs to have already been
# used.  Useful in {SPACE [mc_width <cell>]}

proc mc_width {cell} {

  global MC_DATA_INT

  if {![info exists MC_DATA_INT($cell)]} {
    puts "ERROR: can't find cell named \"$cell\" in mc_width.  Might not be defined yet.  Using width of 0."
    return 0
  }

  setl {name x1 y1 x2 y2} $MC_DATA_INT($cell)

  if {$y2 == ""} {
    # ???
    return 0
  }

  return [expr $x2 - $x1]
}


# same as mc_width but for height

proc mc_height {cell} {

  global MC_DATA_INT

  if {![info exists MC_DATA_INT($cell)]} {
    puts "ERROR: can't find cell named \"$cell\" in mc_height.  Might not be defined yet.  Using height of 0."
    return 0
  }

  setl {name x1 y1 x2 y2} $MC_DATA_INT($cell)

  if {$y2 == ""} {
    # ???
    return 0
  }

  return [expr $y2 - $y1]
}
