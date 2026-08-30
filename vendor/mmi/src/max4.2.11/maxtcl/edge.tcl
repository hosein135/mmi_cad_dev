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

set RCSVERSION(edge.tcl) { $Revision: 1.25 $ }

# Implements edge stuff in max

proc edge_mode_enter {} -desc {
edit edges of paint
} -doc {
enter edge mode
} {
  mode_push edge
}

proc _edge_mode_define {} -desc {
} {
    mode_def edge _edge_gate_keeper "BUT-1 selects edge"

    mode_bind -cmd 0 -desc "show edge to stretch" \
	    edge <Any-Motion> "_find_edge show"


    mode_bind -cmd 0 -desc "select edge" \
	    edge <Any-Button-1> _find_edge
}

proc _edge_gate_keeper {event} -desc {
    called whenever edge mode is entered/exited
} -doc {
    saves box on entry, restores on exit.
} {
    global EDGE mode_abort

    if {$event == "PUSH_TO"} {
	pan_enable
	# save the box and point so we can restore it on exit
	set EDGE(box) [layt_box exact]
	set EDGE(point) [layt_point exact]
    } elseif {$event == "POP_FROM"} {
	pan_disable
	# restore the old box and point
	eval layt_box exact $EDGE(box)
	# Dont do this!  It warps the cursor off the screen
	# if you have zoomed in while moving the edge! (pat)
	#eval layt_point -warp exact $EDGE(point)

	if { $mode_abort } {
	    undo_to_delim
	    undo_flush_redo
	    msg "aborting edge!\n"
	} 

	# delimit "command"
	if {[llength [mode_stack]] == 1 } {i_cmd_between}
    }
}

proc _find_edge {{mode select}} {

  global EDGESAVE

  lay_line -tag edge_poly -clear

  # We dont want res too small, for efficiency sake.
  # But it can not go below [res]
  set mres [res]
  set ures [max [res -userx] [res -mask]]
  # Clamp it down in case user grid is huge.
  set ures [min $ures [max 0.005 [res -mask]]]

  # find the nearest edge or if none, abort
  # We use exact here, to determine where to look for the edge,
  # in case user set a great big user grid.
  setl {x y} [layt_point exact]

  # find the closest paint
  set layer ""
  set layers [join [lremove [dbt_selectable_layers] subcell] ,]

  set max [expr 10 * $ures]
  for {set dx $ures} {$dx <= $max} {set dx [expr $dx + $ures]} {
    # The layt_box is for the user to see, not for the select.
    layt_box exact [expr $x - $dx] [expr $y - $dx] \
	[expr $x + $dx] [expr $y + $dx]
    sel_area -no_wp -layers $layers \
	[expr $x - $dx] [expr $y - $dx] [expr $x + $dx] [expr $y + $dx]

    # walk through each layer looking for an edge
    set area [expr 4 * $dx * $dx]
    foreach paint [sel_what_l paint] {
      setl {layer xx1 yy1 xx2 yy2} $paint
      # Make del a constant makes an invalid assumption about ures!
      #set del [expr $ures * .3]
      #if {[expr abs(($yy2 - $yy1) * ($xx2 - $xx1) - $area)] > $del}
      if {[approx [expr {($yy2 - $yy1) * ($xx2 - $xx1)}] < $area]} {
	# this is an edge, use it
	set EDGESAVE(type) rect
	break
      }

      # not an edge
      set layer ""
    }

    # if no rects, see if any polys here
    if {$layer == ""} {
      foreach poly [sel_what_polygons] {
	set coords [lindex $poly 2]
	# add beginning
	set coords_plus [concat $coords [lrange $coords 0 1]]
	set len [llength $coords]
	for {set i 0} {$i < $len} {incr i 2} {
	  if {[eval _line_point_distance [lrange $coords_plus $i [expr $i + 3]] \
		   $x $y] < $dx} {
	    # this is one
	    
	    # first toast it
	    set EDGESAVE(type) poly
	    set EDGESAVE(layer) [lindex $poly 0]
	    set EDGESAVE(poly) $poly
	    set EDGESAVE(coords) $coords
	    set EDGESAVE(i) $i

	    if {$mode == "show"} {
	      setl {lx1 ly1 lx2 ly2} [lrange $coords_plus $i [expr $i + 3]]
	      set done [expr 2.0 * $ures]
	      for {set dd [expr -2.0 * $ures]} {$dd <= $done} {set dd [expr $dd + $mres]} {
		lay_line -tag edge_poly [expr $lx1 + $dd] $ly1 [expr $lx2 + $dd] $ly2
		lay_line -tag edge_poly $lx1 [expr $ly1 + $dd] $lx2 [expr $ly2 + $dd]
	      }
	    } else {
	      mode_push edge_drag
	    }

	    return
	  }
	}
      }
    }

    if {$layer != ""} {
      break
    }
  }


  if {$layer == ""} {
    if {$mode == "show"} {
      # This displays a cross hair with a point at the cursor.
      layt_box exact $x $y $x $y
      return
    }

    msg "Aborting, no nearby edge to move\n"
    sel_clear
    mode_pop 
    return
  }

  # figure out edge to move
  # Subtract one res before each search in case we are right
  # on top of an edge, which is not returned otherwise.
  # db_next_edge returns clip if no edge found, so clip must beyond max.
  set clip [expr $max + 2*$mres]
  set ny [lindex [db_next_edge $x [expr $y-$mres] n $layer $clip] 1]
  set sy [lindex [db_next_edge $x [expr $y+$mres] s $layer $clip] 1]
  set ex [lindex [db_next_edge [expr $x-$mres] $y e $layer $clip] 0]
  set wx [lindex [db_next_edge [expr $x+$mres] $y w $layer $clip] 0]

  # Find closest edge.
  set min 100000
  set type ""

  if {$ny != "" && [expr abs($ny - $y)] < $min} {
    set min [expr abs($ny - $y)]
    set type n
  }
  if {$sy != "" && [expr abs($sy - $y)] < $min} {
    set min [expr abs($sy - $y)]
    set type s
  }
  if {$ex != "" && [expr abs($ex - $x)] < $min} {
    set min [expr abs($ex - $x)]
    set type e
  }
  if {$wx != "" && [expr abs($wx - $x)] < $min} {
    set min [expr abs($wx - $x)]
    set type w
  }

  if { [approx $min > $max] } {
    # Edge is not within the search radius.  This happens because
    # when we looked for paint we used sel_area, which might
    # find an edge on the corner, but db_next_edge only finds
    # edges horizontally or vertically from point x,y.
    if {$mode == "show"} {
      # This displays a cross hair with a point at the cursor.
      layt_box exact $x $y $x $y
      return
    }

    msg "Aborting, no nearby edge to move\n"
    sel_clear
    mode_pop 
    return
  }

  # Start with x,y at the current mouse point.
  # Warp either x or y to the exact edge.
  switch $type {
  "n" { set y $ny }
  "s" { set y $sy }
  "e" { set x $ex }
  "w" { set x $wx }
  }


  # Set xx,yy to a point inside the paint.
  # Set type to point to the direction from x,y to the paint.
  setl {xx yy} [list $x $y]
  switch $type {
    "s" -
    "n" {
      # Assume paint is north of ny, so to be on paint, yy must be south of ny.
      # Why didnt we just use the type?  Because we may have been exactly
      # on the edge, in which case, eg,  both ny and sy might match,
      # and so type might be either n or s, so we have to figure
      # out which side the paint is on.
      # So just always figure it out.
      set type n
      set yy [expr $y-$mres]
      # Check it out.
      if {[db_search paint -area $xx $yy $xx $yy $layer] == ""} {
	# No paint north.  Paint must be south.
	set type s
	set yy [expr $y+$mres]
      }
    }
    "e" -
    "w" {
      # Assume paint is east of x, so to be on paint, yy must be west of x.
      set type e
      set xx [expr $x-$mres]
      if {[db_search paint -area $xx $yy $xx $yy $layer] == ""} {
	# No paint to east, must be to west.
	set type w
	set xx [expr $x+$mres]
      }
    }
  }

  # 7/26: Code to use new db_next_distance syntax.
  struct rect bbox [lay_bbox]
  switch $type {
    s -
    n {
      set area [list ${bbox.x1} [expr $y-$mres] ${bbox.x2} [expr $y+$mres]]
      set le [lindex [eval db_next_distance -area $area \
	$xx $yy w $layer] 0]
      set re [lindex [eval db_next_distance -area $area \
	$xx $yy e $layer] 0]

      # Put a box around the edge we might move.
      # Box needs to be on the paint side of the edge; just guess which side.
      setl {x1 y1 x2 y2} [list $le [min $y $yy] $re [max $y $yy]]
    }

    w -
    e {
      set area [list [expr $x-$mres] ${bbox.y1} [expr $x+$mres] ${bbox.y2}]
      set te [lindex [eval db_next_distance -area $area \
	$xx $yy n $layer] 1]
      set be [lindex [eval db_next_distance -area $area \
	$xx $yy s $layer] 1]

      setl {x1 y1 x2 y2} [list [min $x $xx] $be [max $x $xx] $te]
    }
  }

if {0} {
  # Old db_next_distance syntax code.
  switch $type {
    n {
      set le [lindex [db_next_distance $xx $yy e $layer left] 0]
      set re [lindex [db_next_distance $xx $yy w $layer right] 0]

      # Put a box around the edge we might move.
      # Box needs to be on the paint side of the edge; just guess which side.
      setl {x1 y1 x2 y2} [list $le [expr $y - $mres] $re $y]
    }

    s {
      set le [lindex [db_next_distance $xx $yy e $layer right] 0]
      set re [lindex [db_next_distance $xx $yy w $layer left] 0]

      setl {x1 y1 x2 y2} [list $le $y $re [expr $y + $mres]]
    }

    e {
      set te [lindex [db_next_distance $xx $yy n $layer right] 1]
      set be [lindex [db_next_distance $xx $yy s $layer left] 1]

      setl {x1 y1 x2 y2} [list [expr $x - $mres] $be $x $te ]
    }

    w {
      set te [lindex [db_next_distance $xx $yy n $layer left] 1]
      set be [lindex [db_next_distance $xx $yy s $layer right] 1]

      setl {x1 y1 x2 y2} [list $x $be [expr $x + $mres] $te]
    }
  }
}

  layt_box exact $x1 $y1 $x2 $y2
  if {$mode == "show"} {
    return
  }
  sel_area -no_poly -no_wp -layers $layer $x1 $y1 $x2 $y2
  
  set EDGESAVE(dir) $type
  set EDGESAVE(last) "$x $y"
  set EDGESAVE(lastx) $x
  set EDGESAVE(lasty) $y
  set EDGESAVE(layer) $layer

  mode_push edge_drag
}


proc _line_point_distance {x1 y1 x2 y2 x y} -desc {
  return the distance from the line (x1 y1 x2 y2) to the point (x y)
} {

  set line_len [expr sqrt(($x2 - $x1)*($x2 - $x1) + ($y2 - $y1)*($y2 - $y1))]
  set len1 [expr sqrt(($x1 - $x)*($x1 - $x) + ($y1 - $y)*($y1 - $y))]
  set len2 [expr sqrt(($x2 - $x)*($x2 - $x) + ($y2 - $y)*($y2 - $y))]

  return [expr $len1 + $len2 - $line_len]
}


proc _edge_drag_mode_define {} -desc {
    edge_drag mode is active after button depressed
} {
    mode_def edge_drag _edge_drag_gate_keeper {}

    mode_bind -cmd 0 -desc "drag edge" \
	    edge_drag <Any-B1-Motion> _edge_drag
    mode_bind -cmd 0 -desc "finish on button release" \
	    edge_drag <Any-B1-ButtonRelease> _edge_drag_end
}


proc _edge_drag_gate_keeper {event} -desc {
} -doc {
} {

  if {$event == "POP_FROM"} {
    sel_clear
  }
}


proc _edge_drag {} {

  global EDGESAVE

  pan_auto _edge_drag

  if {$EDGESAVE(type) == "poly"} {
    _edge_drag_poly
    return
  }

  set resx [res -userx]
  set resy [res -usery]

  setl {lastx lasty} $EDGESAVE(last)
  setl {x y} [layt_point user]
  
  set error 0

  setl {x1 y1 x2 y2} [layt_box exact]

  switch $EDGESAVE(dir) {

    n {
      if {$y < $lasty} {
	# collapsing edge
	lay_box $x1 [expr $y - 2*$resy] $x2 $lasty
	sel_area -no_poly -no_wp -layers $EDGESAVE(layer) \
	    $x1 [expr $y - 2*$resy] $x2 $lasty

	# We are testing to see if the box above was completely full of paint.
	setl {bogus xx1 yy1 xx2 yy2} [sel_what paint]
	if {$xx1 == "" || [expr ($yy2 - $yy1) * ($xx2 - $xx1)] < \
		[expr ($lasty - $y + 1.9*$resy) * ($x2 - $x1)]} {
	  # out of room, try moving one grid
	  set y [expr $lasty - $resy]
	  lay_box $x1 [expr $y - 2*$resy] $x2 $lasty
	  sel_area -no_poly -no_wp -layers $EDGESAVE(layer) \
	      $x1 [expr $y - 2*$resy] $x2 $lasty
	
	  setl {bogus xx1 yy1 xx2 yy2} [sel_what paint]
	  if {$xx1 == "" || [expr ($yy2 - $yy1) * ($xx2 - $xx1)] < \
		  [expr ($lasty - $y + 1.9*$resy) * ($x2 - $x1)]} {
	    # still out of room
	    if {$yy2 != ""} {
	      set EDGESAVE(last) "$x $yy2"
	    } else {
	      set EDGESAVE(last) "$x $EDGESAVE(lasty)"
	    }

	    set error 1
	  }
	}

	# restore selection
	eval lay_box $x1 $y1 $x2 $y2
	sel_area -no_poly -no_wp -layers $EDGESAVE(layer) $x1 $y1 $x2 $y2

	if {$error} {
	  return
	}
      }

      # save the last "good" one
      set EDGESAVE(lasty) $lasty

      :stretch n [expr $y - $lasty]
    }

    s {
      if {$y > $lasty} {
	# collapsing edge
	lay_box $x1 $lasty $x2 [expr $y + 2*$resy]
	sel_area -no_poly -no_wp -layers $EDGESAVE(layer) \
	    $x1 $lasty $x2 [expr $y + 2*$resy]
	
	setl {bogus xx1 yy1 xx2 yy2} [sel_what paint]
	if {$xx1 == "" || [expr ($yy2 - $yy1) * ($xx2 - $xx1)] < \
		[expr ($y + 1.9*$resy - $lasty) * ($x2 - $x1)]} {
	  # out of room, try moving one grid
	  set y [expr $lasty + $resy]
	  lay_box $x1 $lasty $x2 [expr $y + 2*$resy]
	  sel_area -no_poly -no_wp -layers $EDGESAVE(layer) \
	      $x1 $lasty $x2 [expr $y + 2*$resy]
	
	  setl {bogus xx1 yy1 xx2 yy2} [sel_what paint]
	  if {$xx1 == "" || [expr ($yy2 - $yy1) * ($xx2 - $xx1)] < \
		  [expr ($y + 1.9*$resy - $lasty) * ($x2 - $x1)]} {
	    # still out of room
	    if {$yy1 != ""} {
	      set EDGESAVE(last) "$x $yy1"
	    } else {
	      set EDGESAVE(last) "$x $EDGESAVE(lasty)"
	    }

	    set error 1
	  }
	}

	# restore selection
	eval lay_box $x1 $y1 $x2 $y2
	sel_area -no_poly -no_wp -layers $EDGESAVE(layer) $x1 $y1 $x2 $y2

	if {$error} {
	  return
	}
      }

      # save the last "good" one
      set EDGESAVE(lasty) $lasty

      :stretch n [expr $y - $lasty]
    }

    e {
      if {$x < $lastx} {
	# collapsing edge
	lay_box [expr $x - 2*$resx] $y1 $lastx $y2
	sel_area -no_poly -no_wp -layers $EDGESAVE(layer) \
	    [expr $x - 2*$resx] $y1 $lastx $y2

	setl {bogus xx1 yy1 xx2 yy2} [sel_what paint]
	if {$xx1 == "" || [expr ($yy2 - $yy1) * ($xx2 - $xx1)] < \
		[expr ($y2 - $y1) * ($lastx - $x + 1.9*$resx)]} {
	  # out of room, move one grid
	  set x [expr $lastx - $resx]
	  lay_box [expr $x - 2*$resx] $y1 $lastx $y2
	  sel_area -no_poly -no_wp -layers $EDGESAVE(layer) \
	      [expr $x - 2*$resx] $y1 $lastx $y2
	
	  setl {bogus xx1 yy1 xx2 yy2} [sel_what paint]
	  if {$xx1 == "" || [expr ($yy2 - $yy1) * ($xx2 - $xx1)] < \
		  [expr ($y2 - $y1) * ($lastx - $x + 1.9*$resx)]} {
	    # still out of room
	    if {$xx2 != ""} {
	      set EDGESAVE(last) "$xx2 $y"
	    } else {
	      set EDGESAVE(last) "$EDGESAVE(lastx) $y"
	    }

	    set error 1
	  }
	}

	# restore selection
	eval lay_box $x1 $y1 $x2 $y2
	sel_area -no_poly -no_wp -layers $EDGESAVE(layer) $x1 $y1 $x2 $y2

	if {$error} {
	  return
	}
      }

      # save the last "good" one
      set EDGESAVE(lastx) $lastx

      :stretch e [expr $x - $lastx]
    }

    w {
      if {$x > $lastx} {
	# collapsing edge
	lay_box $lastx $y1 [expr $x + 2*$resx] $y2
	sel_area -no_poly -no_wp -layers $EDGESAVE(layer) \
	    $lastx $y1 [expr $x + 2*$resx] $y2
	
	setl {bogus xx1 yy1 xx2 yy2} [sel_what paint]
	if {$xx1 == "" || [expr ($yy2 - $yy1) * ($xx2 - $xx1)] < \
		[expr ($y2 - $y1) * ($x + 1.9*$resx - $lastx)]} {
	  # out of room, try moving one grid
	  set x [expr $lastx + $resx]
	  lay_box $lastx $y1 [expr $x + 2*$resx] $y2
	  sel_area -no_poly -no_wp -layers $EDGESAVE(layer) \
	      $lastx $y1 [expr $x + 2*$resx] $y2
	
	  setl {bogus xx1 yy1 xx2 yy2} [sel_what paint]
	  if {$xx1 == "" || [expr ($yy2 - $yy1) * ($xx2 - $xx1)] < \
		  [expr ($y2 - $y1) * ($x + 1.9*$resx - $lastx)]} {
	    # still out of room
	    if {$xx1 != ""} {
	      set EDGESAVE(last) "$xx1 $y"
	    } else {
	      set EDGESAVE(last) "$EDGESAVE(lastx) $y"
	    }
	    
	    set error 1
	  }
	}

	# restore selection
	eval lay_box $x1 $y1 $x2 $y2
	sel_area -no_poly -no_wp -layers $EDGESAVE(layer) $x1 $y1 $x2 $y2

	if {$error} {
	  return
	}
      }

      # save the last "good" one
      set EDGESAVE(lastx) $lastx

      :stretch e [expr $x - $lastx]
    }
  }

  set EDGESAVE(last) "$x $y"
}


proc _edge_drag_poly {} {

  global EDGESAVE

  lay_line -tag edge_poly -clear

  setl {x y} [layt_point user]

  # first toast it
  if {$EDGESAVE(poly) != ""} {
    # hack to find and select it
    sel_clear
    _bad_delete_polygon $EDGESAVE(poly)
    set EDGESAVE(poly) ""

  } else {
    # otherwise first on list -- HACK
    db_polygon -delete 0
  }

  # compute new coords for this guy
  set coords $EDGESAVE(coords)

  # unwrap coords
  set i $EDGESAVE(i)
  set len [llength $coords]
  set coords_plus [concat [lrange $coords [expr $len - 2] end] \
		       $coords [lrange $coords 0 3]]

  # now how to modify?

  # look at the slope edge to move AND the adjacent.
  # if the same slope, remove coord.
  # want to move point so all slopes stay the same.

  setl {x0 y0 x1 y1 x2 y2 x3 y3} [lrange $coords_plus $i end]

  set m01 [_slope $x0 $y0 $x1 $y1]
  set m12 [_slope $x1 $y1 $x2 $y2]
  set m23 [_slope $x2 $y2 $x3 $y3]

#  puts "$m01 $m12 $m23     i=$i"

  if {$m01 != "x" && $m12 != "x" && [approx $m01 == $m12]} {
    # colinear, lose point
    set new [lreplace $coords $i [expr $i + 1]]

    set i [expr $i - 2]
    if {$i < 0} {
      set i [expr $i + $len - 2]
    }

  } elseif {$m12 != "x" && $m23 != "x" && [approx $m12 == $m23]} {
    # colinear, lose point
    set j [expr ($i + 2) % $len]
    set new [lreplace $coords $j [expr $j + 1]]

    set i [expr $j - 2]
    if {$i < 0} {
      set i [expr $i + $len - 2]
    }

  } else {

    if {$m12 == "x"} {
      # use mouse coords for this
      # vertical edge

      if {$m01 != "x"} {
	set b01 [expr $y1 - $m01 * $x1]
      
	set nx1 $x
	set ny1 [uusnap [expr $m01 * $nx1 + $b01]]
      }

      if {$m23 != "x"} {
	set b23 [expr $y3 - $m23 * $x3]

	set nx2 $x
	set ny2 [uusnap [expr $m23 * $nx2 + $b23]]
      }

    } else {
      set b12 [expr $y - $m12 * $x]

      if {$m01 == "x"} {
	# previous edge is vertical
	set nx1 $x1
	set ny1 [expr $m12 * $x0 + $b12]

      } else {
	set b01 [expr $y1 - $m01 * $x1]

	set nx1 [uusnap [expr ($b12 - $b01) / ($m01 - $m12)]]
	set ny1 [uusnap [expr $m01 * $nx1 + $b01]]
      }

      if {$m23 == "x"} {
	# next edge is vertical
	set nx2 $x2
	set ny2 [expr $m12 * $x2 + $b12]

      } else {
	set b23 [expr $y3 - $m23 * $x3]
	
	set nx2 [uusnap [expr ($b23 - $b12) / ($m12 - $m23)]]
	set ny2 [uusnap [expr $m23 * $nx2 + $b23]]
      }
    }

    # TODO: test if i+3 > len then fix wrap
    set new [lreplace $coords $i [expr $i + 3] $nx1 $ny1 $nx2 $ny2]
  }

#puts "\n$coords\n$new"

  # save coords
  set EDGESAVE(coords) $new
  set EDGESAVE(i) $i

  # make a new one
  eval db_polygon $EDGESAVE(layer) $coords
}


proc _slope {x1 y1 x2 y2} {

  if {[approx $x2 != $x1]} {
    return [expr ($y2 - $y1) / ($x2 - $x1)]
  } else {
    return x
  }
}


proc _bad_delete_polygon {poly} -desc {
  deletes polygon in a very kludgy way
} {

#  db_polygon -delete [lsearch [split [db_search polygons] \n] ${poly}*]
# requires maxz
  db_polygon -delete [lsearch [db_search_polygons] ${poly}*]
}


proc _edge_drag_end {} -desc {
    called when button released at end of edge drag.
} {
    # pop out of edge_drag, then edge mode.
    mode_pop 
    mode_pop
}
