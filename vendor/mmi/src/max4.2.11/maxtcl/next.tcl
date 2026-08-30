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

set RCSVERSION(next.tcl) { $Revision: 1.10 $ }
# Implements a test mode for next_edge and next_distance commands.
# 6-99: Pat took this out of max.

global NEXT_EDGE NEXT_SIDE NEXT_HORIZON
set NEXT_EDGE 1
set NEXT_SIDE left
set NEXT_HORIZON 0

proc next_mode_enter {} -desc {
test next edge
} {
  # enter "next" mode
  mode_push next
}

proc _next_mode_define {} -desc {
    test next edge
} -doc {
  This is max internal test code for db_next_edge/db_next_distance.
} {
    mode_def next _next_gate_keeper "test next edge"

    mode_bind -cmd 0 next "w" "next_walk"
    mode_bind -cmd 0 next "b" box_mode_enter
    mode_bind -cmd 0 next "B" {_next_set_box ""}

    mode_bind -cmd 0 next "e" "next e"
    mode_bind -cmd 0 next "w" "next w"
    mode_bind -cmd 0 next "n" "next n"
    mode_bind -cmd 0 next "s" "next s"
    mode_bind -cmd 0 next "E" {global NEXT_EDGE; set NEXT_EDGE 1; msg "next edge\n"}
    mode_bind -cmd 0 next "D" {global NEXT_EDGE; set NEXT_EDGE 0; msg "next distance\n"}
    mode_bind -cmd 0 next "L" {global NEXT_SIDE; set NEXT_SIDE left; msg "left-side\n" }
    mode_bind -cmd 0 next "R" {global NEXT_SIDE; set NEXT_SIDE right; msg "right-side\n"}
}

proc _next_gate_keeper {event} -desc {
    called whenever next mode is entered/exited
} {
    global mode_abort
    if {$event == "PUSH_TO" } {
      _next_set_box [lay_box]
    } elseif {$event == "POP_FROM"} {
	if { $mode_abort } {	
	    undo_to_delim
	    undo_flush_redo
	    msg "aborting next!\n"
	} 
	_next_set_box ""

	# delimit "command"
	i_cmd_between
    } elseif {$event == "POP_TO"} {
      # Get box from box mode. (redundant with above)
      _next_set_box [lay_box]
    }
}

proc _next_set_box {box} -desc {
  Set box with next_edge/next_distance occurs.  If box arg empty, no limits.
} {
    global NEXT_BOX
    lay_line -tag next_mode -clear
    set NEXT_BOX ""
    if { $box == "" } { return }
    setl {x1 y1 x2 y2} $box
    if { $x1 == $x2 && $y1 == $y2 } { return }
    set NEXT_BOX $box
    eval layt_rect -tag next_mode $NEXT_BOX
}

proc next {dir} {
    global NEXT_EDGE NEXT_SIDE NEXT_HORIZON NEXT_BOX
    set p [layt_point exact]
    setl {x y} $p

    if { $NEXT_EDGE != 0 } {
	set maxd 0
	if { $NEXT_BOX != "" } {
	  setl {x1 y1 x2 y2} $NEXT_BOX
	  switch $dir {
	  n { set maxd [expr $y2 - $y] }
	  s { set maxd [expr $y - $y1] }
	  e { set maxd [expr $x2 - $x] }
	  w { set maxd [expr $x - $x1] }
	  }
	}
	puts "db_next_edge $p $dir m1 $maxd"
	set pnew [eval db_next_edge $p $dir m1 $maxd]

    } else {
	#set pnew [eval db_next_distance $p $dir m1 $NEXT_SIDE $NEXT_HORIZON $NEXT_MAXD]
	if { $NEXT_BOX != "" } {
	  set cmd "db_next_distance -area $NEXT_BOX $p $dir m1"
	} else {
	  set cmd "db_next_distance $p $dir m1"
	}
	puts $cmd
	set pnew [eval $cmd]
    }
    if { $pnew != "" } {
      eval layt_box exact [can_rect "$p $pnew"]
    } else {
      layt_box exact 0 0 0 0
      puts "db_next_distance returned empty!!"
    }
}


# Great documentation!  What the does this do?
proc next_walk {{p ""} {last_dir ""} {layer ""}} {

  global DIRS RC_DATA
  next_init

  if {$layer == ""} {
    set layer m1
  }

  if {$p == ""} {
    # TODO: Dont know what this is doing, so dont know whether
    # it should be exact or user coords (pat)
    set p [lay_point]
    catch {unset RC_DATA}
    set RC_DATA(segments) 0
    set RC_DATA(squares) 0
  } 
  incr RC_DATA(segments)
  if {$RC_DATA(segments) > 10} {
    puts "Aborting walk, max count"
    return
  }

  # figure out the next direction to go
  set max_dist 0
  foreach d {n s e w} {
    if {$last_dir == $DIRS($d,opp)} {
      # special case since we came from this direction
      setl {x y dist} [_next_change $p $d $layer]
    } else {
      set dist [_manhattan_distance $p [eval db_next_edge $p $d $layer]]
    }

    # save this away for later to see if we have a branch
    set save($d) $dist

    if {$dist > $max_dist} {
      set max_dist $dist
      set new_dir $d
    }
  }

  # back up the point to the start of this direction
  if {$last_dir == $new_dir} {
    setl {x y} [lrange [_next_change $p $DIRS($new_dir,opp) $layer] 0 1]
    # must move forward one
    set x [expr $x + $DIRS($new_dir,dx)]
    set y [expr $y + $DIRS($new_dir,dy)]
    set new_p "$x $y"

  } else {
    # ignores corners
    if {$last_dir != ""} {
      set new_p [lrange [_next_change $p $new_dir $layer] 0 1]
    } else {
      set new_p [eval db_next_edge $p $DIRS($new_dir,opp) $layer]
    }
  }

  setl {x y dist width} [_walk_dir $new_p $new_dir $layer]

  # check for a branch
  foreach d {n s e w} {
    if {$new_dir != $d &&  $save($d) > $width} {
      if {$last_dir == "" && $new_dir == $DIRS($d,opp)} {
	# not a branch
	continue
      }

      # this is a new branch, follow it
      setl {bx by} [_next_change $p $d $layer]
      set bx [expr $bx + $DIRS($d,dx)]
      set by [expr $by + $DIRS($d,dy)]

#     puts "new --> $d ($bx $by) $save($d) $width"
      puts "**branch**"
      next_walk "$bx $by" $d $layer
      puts "**unbranch**"
    }
  }

  # doesn't find labels in corners
  set label [_walk_find_label $new_p $layer]

  set squares [expr 1.0 * ([res] + $dist) / $width]
  set RC_DATA(squares) [expr $RC_DATA(squares) + $squares]
  puts "squares = $squares, dir = $new_dir, label = [lindex $label 6]"

  # if we aren't over the layer, we're done.
  if {[lsearch [db_search touchingtypes $x $y] [dbt_long_name $layer]] == -1} {
    # osta la vista
    parray RC_DATA

    sel_clear

    puts "walk done."
    return
  }

  # this is really just tail recursion (i.e. iteration)
  next_walk "$x $y" $new_dir $layer
}


proc _manhattan_distance {p1 p2} {

  setl {x1 y1} $p1
  setl {x2 y2} $p2

  return [max [expr abs($x2 - $x1)] [expr abs($y2 - $y1)]]
}



proc _next_change {p dir layer} {

  global DIRS
  next_init

  set pr [eval db_next_distance $p $dir $layer right]
  set pl [eval db_next_distance $p $dir $layer left]

  set distr [_manhattan_distance $p $pr]
  set distl [_manhattan_distance $p $pl]

  # go shortest distance
  if {$distl < $distr} {
    set dist $distl
    set new_p $pl
  } else {
    set dist $distr
    set new_p $pr
  }

  return "$new_p $dist"
}


proc _walk_dir {p dir layer} {

  global DIRS
  next_init

  # get the shortest distance to a change in the given direction.
  setl {x y dist} [_next_change $p $dir $layer]
  set new_p "$x $y"

  # back up one grid to get the width of this section
  set x [expr $x - $DIRS($dir,dx)]
  set y [expr $y - $DIRS($dir,dy)]

  set pgl [db_next_edge $x $y $DIRS($dir,left) $layer]
  set pgr [db_next_edge $x $y $DIRS($dir,right) $layer]
  
  set width [_manhattan_distance $pgl $pgr]
  
#  puts "($p) ($new_p) dist=$dist width=$width"

  return "$new_p $dist $width"
}


proc _walk_find_label {p layer} {

  # find the bounding box of rectangle surrounding this point to the 
  # next change (different than if I just selected this).
  setl {x1} [_next_change $p w $layer]
  setl {x2} [_next_change $p e $layer]
  setl {xx y1} [_next_change $p s $layer]
  setl {xx y2} [_next_change $p n $layer]

  #lay_box $x1 $y1 $x2 $y2
  #:select area $layer
  sel_area -layers $layer $x1 $y1 $x2 $y2

# puts "$x1 $y1 $x2 $y2   $layer"
# puts "[sel_what labels]"

  # return first comment that is an i/o
  foreach label [split [sel_what labels] \n] {
    setl {layer x1 y1 x2 y2 pos text path_unused group_unused kind} $label
    if {[lsearch "input output inout" $kind] != -1} {
      return $label
    }
  }

  # no labels
  return ""
}

proc next_init {} -doc {
    called to intial next module
} {
    # 8/15/00, pat:  This proc did not define DIRS as global,
    # so I'll bet its not too useful.
    # I added the global, and left the proc in,
    # but it should probably just be removed.
    global DIRS
    set DIRS(n,opp) s
    set DIRS(s,opp) n
    set DIRS(e,opp) w
    set DIRS(w,opp) e

    set DIRS(n,left) w
    set DIRS(n,right) e
    
    set DIRS(s,left) e
    set DIRS(s,right) w

    set DIRS(e,left) n
    set DIRS(e,right) s

    set DIRS(w,left) s
    set DIRS(w,right) n

    set DIRS(n,dx) 0
    set DIRS(n,dy) [res]

    set DIRS(s,dx) 0
    set DIRS(s,dy) [expr 0 - [res]]

    set DIRS(e,dx) [res]
    set DIRS(e,dy) 0

    set DIRS(w,dx) [expr 0 - [res]]
    set DIRS(w,dy) 0
}

