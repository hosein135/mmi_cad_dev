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


# Programs cells with contacts for decoding and the like

# Note, there are certain limitations in the programming:
#   1. Labels must be attached to the layer that will be connected
#      to the contact/via.

# program_setup not used

proc program_setup {{name ""}} -desc {
  program cells with vias for decoding and the like
} {

  global max_win

  if {$name == ""} {
    # get the parameters from the menu
    set win $max_win.layout
    set winy [expr [winfo rooty $win] + 50]
    set winx [expr [winfo rootx $win] + 50]

    set title "program vias"
    set message "Enter program name:" 
    set prop_list [list [list name [lay_rootcell]]]

    # create the menu
    set new_prop_list [prop_menu $winx $winy $message $title $prop_list]

    if {$new_prop_list == ""} {
      # empty list means the user hit cancel
      return
    }

    set name [get_assoc name $new_prop_list]

    update
  }
  
  # run the program entititled program_<name>
  puts "programming $name ..."
  if {[info commands program_$name] != ""} {
    # do it
    program_$name
    msg "Done."
  } else {
    warning "Aborting, Couldn't find $name program."
  }
}


# does the work

proc program {feedthrus connect format end {feedinc 1}} -desc {
  programs a set of feedthrus to internal nets by adding vias
} {

  set feeds [llength $feedthrus]
  set feedno 0
  set feedincno $feedinc

  set vias 0
  set errors 0

  for {set i 0} {$i < $end} {incr i} {
    
    if {[llength $format] > 1} {
      # complex format
      set instname [eval format $format]
    } else {
      # simple format string
      set instname [format $format $i]
    }

    set feed [lindex $feedthrus $feedno]

    # Select cell will place the box on the bounding box of the cell
    if {[msg_catch "sel_cell $instname" code msg]} {
      # couldn't select cell
      incr errors
      if {![info exists error_cells($instname)]} {
	puts "ERROR, couldn't find cell \"$instname\" to program."
	# so we only print this message once
	set error_cells($instname) 1
      }
      continue
    }

    set cell [lindex [sel_what cells] 1]
    set xform [lindex [sel_what cells] 8]

    # do we need to trace this cell?
    if {![info exists PROGRAM($feed,$cell)]} {

      # push into this cell
      edit_push 

      # get all the paint on the connect label, same layer
      sel_labels -text $connect

      # if multiple labels, assume they are connected on both on correct layer
      setl {clayer cx cy} [sel_what labels]
      if {$cy == ""} {
	puts "ERROR, couldn't find \"$connect\" in cell \"$instname\" to program."
	edit_pop

	set PROGRAM($feed,$cell) ""
	return
      }

      set clayer [dbt_short_name $clayer]

      # get paint on this layer
      sel_region -point $cx $cy $clayer

      set cpaint [split [sel_what paint] \n]

      # do the same for the feed layer
      sel_labels -text $feed

      # if multiple labels, assume they are connected on both on correct layer
      setl {flayer fx fy} [sel_what labels]
      set flayer [dbt_short_name $flayer]
      if {$fy == ""} {
	incr errors
	if {![info exists error_cells($instname,$feed)]} {
	  puts "ERROR, couldn't find \"$feed\" in cell \"$instname\" to program."
	  set error_cells($instname,$feed) 1
	}
	edit_pop

	set PROGRAM($feed,$cell) ""
	continue
      }

      # get paint on this layer
      sel_region -point $fx $fy $flayer

      set fpaint [split [sel_what paint] \n]

      # are the layers adjacent
      set via [techinfo above $clayer "" opt]
      if {$via != 0} {
	set l [techinfo above $via "" opt]
	if {$l != 0} {
	  if {$l != $flayer} {
	    # not right
	    set via 0
	  }
	}
      }

      if {$via == 0} {
	set via [techinfo above $flayer "" opt]
	if {$via != 0} {
	  set l [techinfo above $via "" opt]
	  if {$l != 0} {
	    if {$l != $clayer} {
	      # not right
	      set via 0
	    }
	  }
	}
      }

      if {$via == 0} {
	incr errors
	if {![info exists error_cells($instname,$clayer)]} {
	  puts "ERROR, \"$feed\" and \"$connect\" in cell \"$instname\" are not connectable by a via ($flayer, $clayer) for programming.  Label (text) must be attached to layer to program."
	  set error_cells($instname,$clayer) 1
	}
	edit_pop

	set PROGRAM($feed,$cell) ""
	continue
      }

      # now find the maximum overlaps
      # TODO: this is very slow
      set max_area 0
      set max_box ""
      foreach cbox $cpaint {
	foreach fbox $fpaint {
	  set box [_program_overlap_box $cbox $fbox]
	  if {$box == ""} {
	    continue
	  }

	  # found one, is it the largest
	  setl {x1 y1 x2 y2} $box
	  set area [expr ($x2 - $x1) * ($y2 - $y1)]
	  if {$area > $max_area} {
	    # largest, save
	    set max_box $box
	    set max_area $area
	  }
	}
      }

      if {$max_box == ""} {
	incr errors
	if {![info exists error_cells($instname,$feed)]} {
	  puts "ERROR, \"$feed\" and \"$connect\" in cell \"$instname\" don't overlap between layers $flayer and $clayer."
	  set error_cells($instname,$feed) 1
	}
	edit_pop
	set PROGRAM($feed,$cell) ""
	continue
      }

      # save this away
      set PROGRAM($feed,$cell) $max_box

      # return to upper cell
      edit_pop
    }

    if {$PROGRAM($feed,$cell) == ""} {
      # problem
      incr errors
      continue
    }

    # transform coords for this instance
    set max_box [concat [transform_coords $xform \
			     [lindex $PROGRAM($feed,$cell) 0] \
			     [lindex $PROGRAM($feed,$cell) 1]] \
		        [transform_coords $xform \
			     [lindex $PROGRAM($feed,$cell) 2] \
		 	     [lindex $PROGRAM($feed,$cell) 3]]]

    setl {x y} [eval center_coords $max_box]
    if {[msg_catch [list place_gcell via "$x $y" -type $via \
			-_BBOX_ $max_box]]} {
      # via gcell failed

      # place paint
      # place one via at center of intersection
      set width [techinfo width $via "" opt]
      set w2 [expr $width / 2.0]

      set fenc [techinfo enclose $flayer $via opt]
      set cenc [techinfo enclose $clayer $via opt]

      if {$width == 0 || $fenc == 0 || $cenc == 0} {
	incr errors
	if {![info exists error_cells($instname,$via)]} {
	  puts "ERROR, can't place a \"$via\" via.  No gcell and insufficient tech info ($via width $width, $flayer enc $via $fenc, $clayer enc $via $cenc)."
	set error_cells($instname,$via) 1
	}
	continue
      }

      db_paint $via [expr ($x - $w2)] [expr ($y - $w2)] \
	  [expr ($x + $w2)] [expr ($y + $w2)]
      db_paint $flayer [expr ($x - $w2 - $fenc)] [expr ($y - $w2 - $fenc)] \
	  [expr ($x + $w2 + $fenc)] [expr ($y + $w2 + $fenc)]
      db_paint $clayer [expr ($x - $w2 - $cenc)] [expr ($y - $w2 - $cenc)] \
	  [expr ($x + $w2 + $cenc)] [expr ($y + $w2 + $cenc)]
    }

    incr vias

    incr feedincno -1
    if {$feedincno == 0} {
      set feedno [expr ($feedno + 1)%$feeds]
      set feedincno $feedinc
    }
  }

  regsub {_[0-9]+$} $instname "" instname
  puts "Programmed $vias vias ([lay_rootcell]/$instname/$connect); $errors errors."
}


proc _program_overlap_box {box1 box2} -desc {
  returns the overlap of two boxes.  Note boxes are {layer x1 y1 x2 y2}.
} {

  set x1 [max [lindex $box1 1] [lindex $box2 1]]
  set y1 [max [lindex $box1 2] [lindex $box2 2]]
  set x2 [min [lindex $box1 3] [lindex $box2 3]]
  set y2 [min [lindex $box1 4] [lindex $box2 4]]

  if {$x1 < $x2 && $y1 < $y2} {
    return "$x1 $y1 $x2 $y2"
  } else {
    # no overlap
    return ""
  }
}


proc program_cell {name} -desc {
  MC program the given cell
} {

  global MC_DATA_INT TOP_CELL

  if {$name == "_TOP_"} {
    :load $TOP_CELL

  } else {
    set cellname [lindex [use_first MC_DATA_INT($name)] 0]

    if {$cellname == ""} {
      puts "ERROR: can't find cell \"$name\" to program."
      
      # put back into top cell
      :load $TOP_CELL
      
      return
    }

    cell_load $cellname
  }

  # make sure everything is visible
  eval lay_box [lay_bbox]
  lay_internals -area
}

