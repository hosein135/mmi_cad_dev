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

set RCSVERSION(stretch.tcl) { $Revision: 1.1 $ }



# Routines to implement stretch while preserving connectivity.
# Only wiring layers (metal, poly, etc) are stretched.
# Definition: "metal" is used generically for layers we are
#   stretching, even though it might be poly or diff.
# Definition: a "pad" is a connection between selected metal
#   and unselected metal.
# The pads are the only areas of real interest, as stretching
# only occurs around pads.
#
# Metal occuring in selected subcells is largely ignored, since
# it will be moving with the selected metal.
# Metal in unselected subcells must be treated identically
# to other unselected metal, ie, it creates pad areas.

# Stretching could occur via three interfaces: arrow keys, mouse, or 
# potentially by a stretch command.  If by arrow keys, the selection
# will be merged with existing paint after each tiny movement.
# If by mouse or command, merging does not occur until the selection is dropped.
# I can also envision a mode whereby an arrow key stretch (or move)
# is initiated by a hot-key, which locks the current selection
# into a group so that it can be moved/stretched without merging.

# A philosophical question arises:
# If selected metal crosses unselected metal, what happens?
# We dont know (without alot of effort) whether the selected
# and unselected metal are actually connected somewhere.
# In the older stretch command, it is merged.
# But I dont think thats right: a stretch should work like a move,
# and is not merged until dropped.
# Example:
#   W           W
#   WWWWWWWWWWWWW
#   W
#   W    VIAWWWWVIA
#   W
#   WXXXXXXXXXXXXXXXXXXX
#                      W
#                      W
#
# If you select the Xed wire and move it north, it should not
# merge with the unrelated VIA and wire.
# We might like it to merge with the wire that is obviously
# connected, but I am not smart enough to figure out all the possible
# conditions.

# To speed up the actual movement, we want to preprocess the
# selection so that we can move it in each direction as far as possible
# without having to stop along the way to check things.
# So we will precompute the following info for each pad:
#   1. For corners only: an area of unselected metal to be erased
#   from the direction we are moving in.
#   2. An ending location beyond which selected metal must be deleted,
#   which occurs where ever a piece of selected metal runs into
#   unselected metal.
#   3. A starting location where you have to start drawing new metal
#   behind you as you move.
#   Examples: here is the data for moving right:
#   the P/X/2/3 metal is selected, the W/1 metal is unselected.
#   The pad locations are at P, 2 and 3.
#
#          W          W    W
#   P111111W     XXXXX2    3XXXXX
#   X      W          W    W
#
# A selected wire can overlap unselected metal in a sub-cell.


proc stretch_init {dir} -desc {
  Prepare selection for stretching in direction dir, preserving connectivty.
} -doc {
  Connectivity through metal layers will be preserved.
  To do this, find all intersections between selected and non-selected metal.

} {
  global _STRETCH

  set mlayers [techinfo wire_layers]
  if { $mlayers == "" } {
    msg "warning: No wiring layers defined in tech file\n"
    return
  }

  lay_line -tag stretch -clear

  set res [res]
  set orig_group [db_group]

  set paintballs [sel_what_l paint -edit_only junk]

  # We transfer the selection to another group so we can
  # select paint around it without getting it.
  # On error, this prints: "You selected paint outside the edit cell.
  # Only the paint in the edit cell was modified."
  sel_group_transfer selected

  # Delete selected cells temporarily.
  save_selection __STRETCH_TMP__

  # We must delete selected subcells, because we need to look for
  # connections from selected paint to unselected sub-cells.
  setl {bx1 by1 bx2 by2} [lay_bbox]
  sel_area -less -any_cell -layers [join [dbt_layers] ,] $bx1 $by1 $bx2 $by2
  save_selection __STRETCH_CELLS__

  # Put this all in a catch.  If anything fails,
  # the cells would remain deleted, and the group would be wrong, too.
  set catch_status [catch {

  :delete
  restore_selection __STRETCH_TMP__
  sel_area -less -any_cell -layers subcell $bx1 $by1 $bx2 $by2

  foreach pball $paintballs {
    struct max_paint p $pball
    if { [lsearch -exact $mlayers ${p.layer}] == -1} { continue }
    # Its a metal layer.  Selecting one res bigger in group 0
    # yields slivers of unselected but connected paint.
    # It might also yield paint in other cells that is connected
    # to the current paint.
    db_group 0
    sel_area -group -any_cell -layers ${p.layer} \
      [expr ${p.x1}-$res] [expr ${p.y1}-$res] \
      [expr ${p.x2}+$res] [expr ${p.y2}+$res]
    foreach sliver [sel_what_l paint] {
      struct max_paint s $sliver
      # One of these coords will be extended.
      setl {x1 y1 x2 y2} [list ${s.x1} ${s.y1} ${s.x2} ${s.y2}]


      # Width of the sliver.
      set minwidth [min [expr $y2 - $y1] [expr $x2 - $x1]]
      # Width of this wire.
      set maxwidth [max [expr $y2 - $y1] [expr $x2 - $x1]]

puts "sliver $x1 $y1 $x2 $y2 minwidth=$minwidth maxwidth=$maxwidth"
#lay_box $x1 $y2 $x2 $y2
#update;after 1000

      # Still have off-by-one problems in selection until
      # db_next_distance is fixed.  So ignore 1x1 res squares for now.
      if { [approx $maxwidth <= $res] } { continue }

      if { [approx $minwidth <= $res] } {
	# It is a one res wide sliver, meaning its a connection
	# to other paint.
	if { $x2 - $x1 > $y2 - $y1 } {
	  # Is it above or below?
	  if { ${s.y1} < ${p.y1} } {
	    # Unselected metal is below selected metal.
	    set pdir down
	    set y1 $y2
	    set y2 [expr $y1 + $maxwidth]
	  } else {
	    # Unselected metal is above selected metal.
	    set pdir up
	    set y2 $y1
	    set y1 [expr $y2 - $maxwidth]
	  }
	} else {
	  # Is it left or right?
	  if { ${s.x1} < ${p.x1} } {
	    # Unselected metal is left of selected metal.
	    set pdir left
	    set x1 $x2
	    set x2 [expr $x1 + $maxwidth]
	  } else {
	    # Unselected metal is right of selected metal.
	    set pdir right
	    set x2 $x1
	    set x1 [expr $x2 - $maxwidth]
	  }
	}
	lappend pads1(${p.layer}) [list $x1 $y1 $x2 $y2]
      } else {
	# Its wider than one res, so its not a sliver at all.
	# There is other paint in an unselected cell below this pad.
	puts "Connection to unselected sub-cell ignored for now."
      }
    }
  }

  # Find the actual pads, in selected paint.
  # We combine overlapping pads by selecting them all,
  # then looking at sel_what paint.
  set pads ""
  foreach layer [array names pads1] {
    set techwidth [techinfo width $layer opt]
    sel_clear
    db_group selected
    foreach pad $pads1($layer) {
      setl {x1 y1 x2 y2} $pad
      sel_area -more -group -layers $layer $x1 $y1 $x2 $y2
    }
    foreach ppad [eval sel_what_l paint] {
      setl {junk x1 y1 x2 y2} $ppad
      # If the pad is not wide enough, try to expand it.
      set diff [expr $techwidth - ($x2 - $x1)]
      if { [approx $diff > 0] } {
	# Try to expand left or right.
	if {[dbt_chunk -group $layer [expr $x1-$diff] $y1 $x2 $y2] !=""} {
	  set x1 [expr $x1-$diff]
	} elseif {[dbt_chunk -group $layer $x1 $y1 [expr $x2+$diff] $y2] !=""} {
	  set x2 [expr $x2+$diff]
	}
      }
      set diff [expr $techwidth - ($y2 - $y1)]
      if { [approx $diff > 0] } {
	# Try to expand down or up.
	if {[dbt_chunk -group $layer $x1 [expr $y1-$diff] $x2 $y2] !=""} {
	  set y1 [expr $y1-$diff]
	} elseif {[dbt_chunk -group $layer $x1 $y1 $x2 [expr $y2+$diff]] !=""} {
	  set y2 [expr $y2+$diff]
	}
      }

      # The wires are the selected wires.
      # An unselected wire in direction dir would have:
      # [memq $edges $dir]==0 && [memq $edges $dir]==0
      setl {edges wires} [_stretch_find_edges $layer $x1 $y1 $x2 $y2]
      lappend pads [list $layer $x1 $y1 $x2 $y2 $edges $wires]
    }
  }

  set _STRETCH(pads) ""
  foreach pad $pads {

    setl {layer x1 y1 x2 y2 edges wires} $pad

    # Determine infinity.
    setl {ix1 iy1 ix2 iy2} [lay_bbox]

    set next_edge "" ;# unselected metal area to erase
    set del 0   ;# case 2 edge: delete selection as it passes this edge.
    set add 0   ;# case 3 edge: add metal behind this edge.

    switch $dir {
      "up" {
	set rev down
	set rotl left
	set rotr right
	set px [uusnap [expr ($x1+$x2)/2.0]]
	set py $y2
	set area [list $x1 $y2 $x2 $iy2]
      }
      "down" {
	set rev up
	set rotl right
	set rotr left
	set px [uusnap [expr ($x1+$x2)/2.0]]
	set py $y1
	set area [list $x1 $iy1 $x2 $y1]
      }
      "right" {
	set rev left
	set rotl up
	set rotr down
	set px $x2
	set py [uusnap [expr ($y1+$y2)/2.0]]
	set area [list $x2 $y1 $ix2 $y2]
      }
      "left" {
	set rev right
	set rotl down
	set rotr up
	set px $x1
	set py [uusnap [expr ($y1+$y2)/2.0]]
	set area [list $ix1 $y1 $x1 $y2]
      }
      default { error "unrecognized stretch_selected dir: $dir" }
    }

puts "here dir=$dir edges=$edges wires=$wires"
    # Assume we want to add paint behind us, because the fact that it
    # is a pad means there was unselected metal on some side of us.
    # If it turns out to be a corner, we will reset this.
    # Note: This used to be if {[memq $wires $rev]}, 
    # but the memq is true if there is any paint
    # behind us anywhere.  There could be just a little
    # nick in the paint (not full width of pad), and we will
    # want to fill that in, so always set add 1.
    set add 1

    if {[memq $edges $dir]} {
      # No metal in direction dir.
      if {[memq $wires $rotl] || [memq $wires $rotr]} {
	# There is a perpendicular selected wire.
      } else {
	if { (![memq $wires $rotl] && ![memq $edges $rotl]) || \
	     (![memq $wires $rotr] && ![memq $edges $rotr]) } {
	  # There is a perpendicular unselected wire.
	  set del 1
	}
      }
    } else {
      if { ![memq $wires $dir] } {
	# There is unselected metal in direction dir.
	# Its a corner if there is no unselected metal in any other dir.
	if {([memq $edges $rev] || [memq $wires $rev]) && \
	   ([memq $edges $rotl] || [memq $wires $rotl]) && \
	   ([memq $edges $rotr] || [memq $wires $rotr]) } {
	  # Delete unselected metal from dir we are moving.
	  set next_edge [dbt_next_edge $px $py $dir $layer -area $area]
	  set add 0
	}
      }
    }

    lappend _STRETCH(pads) [list \
	$layer $x1 $y1 $x2 $y2 $add $del $next_edge]
    
    # DEBUG:
    layt_rect -tag stretch $x1 $y1 $x2 $y2

puts "l=$layer $x1 $y1 $x2 $y2 add=$add del=$del ne=$next_edge edges=$edges wires=$wires"

    #lay_box ${n.x1} ${n.y1} ${n.x2} ${n.y2}
    #update; after 1000
  }

  } error_msg]  ;# end of catch
    

  # Now that we have gathered all our info,
  # restore cells and selection
  db_cell_copy -source __STRETCH_CELLS__ [lay_editcell]
  restore_selection __STRETCH_TMP__

  if { $catch_status != 0 } {
    db_group selected
    sel_group_transfer 0
    error $error_msg
  }

  db_group 0

  # DEBUG: display pads
  if {0} {
    sel_clear
    foreach pad $_STRETCH(pads) {
      setl {l px1 py1 px2 py2} $pad
      sel_area -more -no_wp -no_poly -layers $l $px1 $py1 $px2 $py2
    }
  }
}

proc stretch_end {} -desc {
  To stretch, use: stretch_init, stretch_cont, stretch_end
} {
  db_group selected
  sel_group_transfer 0
}

proc _stretch_erase {pass l x1 y1 x2 y2} -desc {
  erase specified paint
} {
  if { $pass == 0 } {
    layt_box exact $x1 $y1 $x2 $y2
    :erase $l
  } else {
    sel_area -any_cell -no_poly -no_wp -less -layers $l $x1 $y1 $x2 $y2
  }
}


proc stretch_cont {dir amt} -desc {
  continue stretch started with stretch_init
} -doc {
  Assumes selection is in group selected.
} {
  global _STRETCH
puts "stretch $dir $amt"

  if { $amt == 0 } { return }

  set dir [string tolower $dir]
  switch $dir {
    "n" { set dir up }
    "s" { set dir down }
    "e" { set dir right }
    "w" { set dir left }
  }

  if { $amt < 0 } {
    # This code only works with positive amt.
    set amt [expr abs($amt)]
    switch $dir {
      "up" { set dir down }
      "down" { set dir up }
      "left" { set dir right }
      "right" { set dir left }
    }
  }

  save_selection __STRETCH_TMP__

  # Optionally erase unselected metal from the direction we are going.
  db_group 0
  foreach pad $_STRETCH(pads) {
    setl {l x1 y1 x2 y2 add del next_edge} $pad
    if { $next_edge != "" } {
      setl {ax1 ay1 ax2 ay2} [list $x1 $y1 $x2 $y2]
      switch $dir {
	"right" {
	  set ax1 $x2
	  set ax2 [min $next_edge [expr $x2+$amt]]
	}
	"left" {
	  set ax1 [max $next_edge [expr $x1-$amt]]
	  set ax2 $x1
	}
	"up" {
	  set ay1 $y2
	  set ay2 [min $next_edge [expr $y2+$amt]]
	}
	"down" {
	  set ay1 [max $next_edge [expr $y1-$amt]]
	  set ay2 $y1
	}
      }
      if { $ax2 > $ax1 && $ay2 > $ay1 } {
	set save_box [lay_box]
	lay_box $ax1 $ay1 $ax2 $ay2
	:erase $l
	eval layt_box exact $save_box
      }
    }
  }

  restore_selection __STRETCH_TMP__
  db_group selected
  :move $dir $amt

  # Erase selected metal from direction we are going.
  for {set pass 0} {$pass <= 1} {incr pass} {

    if {$pass == 0} { save_selection __STRETCH_TMP__ }

    # erase wiring from the direction we are moving.
    # Only do this for corners!  Can tell if its a corner from the edges.
    foreach pad $_STRETCH(pads) {
      setl {l x1 y1 x2 y2 add del next_edge} $pad
      if { $del } {
	switch $dir {
	  "up" {
	    _stretch_erase $pass $l $x1 $y2 $x2 [expr $y2 + $amt]
	  }
	  "down" {
	    _stretch_erase $pass $l $x1 [expr $y1-$amt] $x2 $y1
	  }
	  "right" {
	    _stretch_erase $pass $l $x2 $y1 [expr $x2+$amt] $y2
	  }
	  "left" {
	    _stretch_erase $pass $l [expr $x1-$amt] $y1 $x1 $y2
	  }
	  default { error "unrecognized stretch_selected dir: $dir" }
	}
      }
    }
    if {$pass == 0} { restore_selection __STRETCH_TMP__ }
  }

  # Pass 2: add in wiring behind us.
  # Newly added material goes into group 0
  db_group 0

  # BUG: db_paint does a sel_clear!!!
  # So must save/restore selection
  save_selection __STRETCH_TMP__

  foreach pad $_STRETCH(pads) {
    setl {l x1 y1 x2 y2 add del next_edge} $pad
    if { $add } {
      switch $dir {
	"up" {
	  db_paint $l $x1 $y1 $x2 [expr $y1 + $amt]
	}
	"down" {
	  db_paint $l $x1 [expr $y2-$amt] $x2 $y2
	}
	"right" {
	  db_paint $l $x1 $y1 [expr $x1+$amt] $y2
	}
	"left" {
	  db_paint $l [expr $x2-$amt] $y1 $x2 $y2
	}
      }
    }
  }

  restore_selection __STRETCH_TMP__
  db_group 0
}



proc stretch_selected {dir amt} {
  if { $amt == 0 } { return }
  set dir [string tolower $dir]

  switch $dir {
    "n" { set dir up }
    "s" { set dir down }
    "e" { set dir right }
    "w" { set dir left }
  }

  if { $amt < 0 } {
    # This code only works with positive amt.
    set amt [expr abs($amt)]
    switch $dir {
      "up" { set dir down }
      "down" { set dir up }
      "left" { set dir right }
      "right" { set dir left }
    }
  }

  stretch_init $dir
  stretch_cont $dir $amt
  stretch_end
}


proc _stretch_find_edges {l x1 y1 x2 y2} {
  # Assume there is paint inside x1 y1 x2 y2.
  # Return a list of each edge for which there is no paint outside
  # that side of the box.
  # If there is selected paint on a side, add in sleft, sright, sup, sdown.
  set edges ""
  set wires ""
  set res [res]
  set x1r [expr $x1-$res]
  if {[db_search paint -area $x1r $y1 $x1r $y2 $l]==""} {
    lappend edges left
  }
  # db_search paint is buggy, and returns TRUE unless we move over another res.
  set x1r [expr $x1-2*$res]
  if {[db_search paint -cell __STRETCH_TMP__ -area $x1r $y1 $x1r $y2 $l]!=""} {
    lappend wires left
  }
  set x2r [expr $x2+$res]
  if {[db_search paint -area $x2r $y1 $x2r $y2 $l]==""} {
    lappend edges right
  }
  set x2r [expr $x2+2*$res]
  if {[db_search paint -cell __STRETCH_TMP__ -area $x2r $y1 $x2r $y2 $l]!=""} {
    lappend wires right
  }
  set y1r [expr $y1-$res]
  if {[db_search paint -area $x1 $y1r $x2 $y1r $l]==""} {
    lappend edges down
  }
  set y1r [expr $y1-2*$res]
  if {[db_search paint -cell __STRETCH_TMP__ -area $x1 $y1r $x2 $y1r $l]!=""} {
    lappend wires down
  }
  set y2r [expr $y2+$res]
  if {[db_search paint -area $x1 $y2r $x2 $y2r $l]==""} {
    lappend edges up
  }
  set y2r [expr $y2+2*$res]
  if {[db_search paint -cell __STRETCH_TMP__ -area $x1 $y2r $x2 $y2r $l]!=""} {
    lappend wires up
  }
  return [list $edges $wires]
}
