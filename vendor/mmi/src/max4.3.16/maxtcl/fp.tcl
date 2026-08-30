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

set RCSVERSION(fp.tcl) { $Revision: 1.1 $ }


proc fp_kill {} {
  global max_win
  fp_on 0
  win_pack
  destroy $max_win.fp
  destroy $max_win.fpxscroll
  destroy $max_win.fpyscroll
}



proc fp_init {} {
  global max_win
  set cc $max_win.fp

  if {![winfo exists $cc]} {
    scrollbar $max_win.fpxscroll \
	    -orient horiz \
	    -relief sunken \
            -highlightthickness 0 \
	    -command "$max_win.fp xview"
    scrollbar $max_win.fpyscroll \
	    -relief sunken \
            -highlightthickness 0 \
	    -command "$max_win.fp yview"

    canvas $cc -background grey -xscrollcommand "$max_win.fpxscroll set" \
      -yscrollcommand "$max_win.fpyscroll set"
    

    # Do the button bindings right now.
    bind $cc <Button-1> "_fp_but1 canvas %x %y"
  }

  return $cc
}

proc fp_test_rect {} -doc {
  As a test, draw a rectangle for every cell bbbox.
} {
  set cell [lay_editcell]
  foreach cell_info [db_search_l cells -cell $cell] {
    set id [cellinfo_id $cell_info]
    set def [cellinfo_def $cell_info]
    setl {x1 y1 x2 y2} [fplan_bbox -parent -cellid $id]
    layt_rect $x1 $y1 $x2 $y2
  }
}

proc fp_scale {args} -desc {
  Scale args, which consists of x y ...
} {
  global _FP_SCALE
  set scale $_FP_SCALE(scale)
  set result ""
  for {set i 0} {$i < [llength $args]} {incr i 2} {
    set x [lindex $args $i]
    set y [lindex $args [expr $i+1]]
    lappend result \
      [expr $_FP_SCALE(xoff) + ($x - $_FP_SCALE(xorigin)) * $scale] \
      [expr $_FP_SCALE(yoff) + ($_FP_SCALE(yorigin) - $y) * $scale]
  }
  return $result
}

proc fp_fill {} -desc {
  Draw current max fplan file on a canvas.
} {
  global _FP_SCALE
  set cell [lay_editcell]
  set cc [fp_init]

  $cc delete all

  # Set up the coord transform.
  set viewscale 0.9  ;# How much of the canvas is taken up by the contents
  setl {bx1 by1 bx2 by2} [db_bbox -cell $cell]

  set ccwidth [winfo width $cc]
  set ccheight [winfo height $cc]
  set xscale [expr $ccwidth / ($bx2 - $bx1)]
  set yscale [expr $ccheight / ($by2 - $by1)]

  #puts "SCALES: $xscale $yscale $ccwidth $ccheight"

  set scale [expr $viewscale * [min $xscale $yscale]]

  set _FP_SCALE(xorigin) [expr $bx1]
  set _FP_SCALE(yorigin) [expr $by2]
  set _FP_SCALE(scale) $scale
  #set _FP_SCALE(xoff) 0; set _FP_SCALE(yoff) 0
  set _FP_SCALE(xoff) [expr ($ccwidth - $scale*($bx2 - $bx1))/2.0]
  set _FP_SCALE(yoff) [expr ($ccheight - $scale*($by2 - $by1))/2.0]

  foreach cell_info [db_search_l cells -cell $cell] {
    set id [cellinfo_id $cell_info]
    set def [cellinfo_def $cell_info]
    setl {x1 y1 x2 y2} [fplan_bbox -parent -cellid $id]

    setl {sx1 sy1 sx2 sy2} [fp_scale $x1 $y1 $x2 $y2]
    $cc create rectangle $sx1 $sy1 $sx2 $sy2 \
      -fill grey -outline black \
      -tags [list selectable CELL_$id]

    # TODO: Figure out which corner is the real origin.
    set tickwidth [expr 0.3 * [min [expr $x2 - $x1] [expr $y2 - $y1]]]
    setl {sx1 sy1 sx2 sy2} [fp_scale $x1 [expr $y1 + $tickwidth] [expr $x1 + $tickwidth] $y1]
    $cc create line $sx1 $sy1 $sx2 $sy2 -tags [list CELL_$id]
  }

  foreach lab_info [db_search_l labels -non_hier -cell $cell] {
    struct max_label l $lab_info
    if {${l.kind} == "hidden"} {continue}
    setl {sx sy} [fp_scale ${l.x1} ${l.y1}]
    set len [expr $scale * 3]
    $cc create line [expr $sx - $len] $sy [expr $sx + $len] $sy -fill yellow \
      -tags [list LABEL_${l.text} selectable]
    $cc create line $sx [expr $sy - $len] $sx [expr $sy + $len] -fill yellow \
      -tags [list LABEL_${l.text} selectable]
    $cc create text [expr $sx+$len] [expr $sy-$len] -text ${l.text} -anchor w -fill yellow \
      -tags [list LABEL_${l.text}]
  }


  # Create mouse bindings.
  $cc bind selectable <Any-Button-1> "_fp_but1 press %x %y"
}

proc fp_on {{on 1}} {
  global max_win
  upvar #0 win_$max_win win_cur
  if {$on == "on" || $on == "1"} {
    set win_cur(patvas) 1
    win_pack
  } else {
    set win_cur(patvas) 0
    win_pack
    :view
  }
}


proc fplan_gate_keeper {event} {
  global max_win
  upvar #0 win_$max_win win_cur

  if {$event == "PUSH_TO"} {
    set win_cur(patvas) 1
    fp_init
    win_pack
    fp_fill
    # Dont use the "mode" type cursor (a hand).  Use normal cursor.
    cursor_mode 0
    cursor_busy 0
  } elseif {$event == "POP_FROM"} {
    set win_cur(patvas) 0
    win_pack
  }
}


proc _fplan_mode_define {} -desc {
    drag ruler (leaves box and point undisturbed)
} {
    mode_def fplan fplan_gate_keeper "Floorplan description goes here"
    mode_bind fplan -cmd 0 -desc "Zoom in on mouse cursor" j "_fp_view zoom_in"
    mode_bind fplan -cmd 0 -desc "Zoom in on mouse cursor" <Control-z> "_fp_view zoom_in"
    mode_bind fplan -cmd 0 -desc "Zoom out" Z "_fp_view zoom_out"
    mode_bind fplan -cmd 0 -desc "Adjst view so current cell fills screen" v "_fp_view view"
}

proc _fp_view {subcmd} {
puts "view $subcmd"
  switch -- $subcmd {
    zoom_in {
    }
    zoom_out {
    }
    view {
    }
  }
}

proc fp_sel_clear {{-all}} {
  global _FP_SELECTED
  set cc [fp_init]
  if {$all} {
    puts HELP
  }
  foreach tag [use_first _FP_SELECTED] {
    fp_tag_color $tag black
  }
}

proc fp_id_color {list color} {
  set cc [fp_init]
  foreach id $list {
    switch [$cc type $id] {
      rectangle {
	$cc itemconfigure $id -outline $color
      }
      line {
	$cc itemconfigure $id -fill $color
      }
    }
    $cc raise $id
  }
}

proc fp_tag_color {tag color} {
  set cc [fp_init]
  fp_id_color [$cc find withtag $tag] $color
}


proc fp_select {{-more} list} {
  global _FP_SELECTED
  set cc [fp_init]
  if {!$more} {
    fp_sel_clear
  }
  foreach id $list {
    foreach tag [$cc gettags $id] {
      if {[string match CELL_* $tag] || [string match LABEL_* $tag]} {
	set tags($tag) 1
      }
    }
  }
  # This is the list of selected tags.
  set _FP_SELECTED [array names tags]

  foreach tag [array names tags] {
    fp_tag_color $tag white
  }
}

proc _fp_but1 {action x y} {
  set cc [fp_init]
  $cc select clear
puts "action=$action"
  if {$action == "press"} {
    set list [$cc find overlapping [expr $x-1] [expr $y-1] [expr $x+1] [expr $y+1]]
    set list [$cc find closest $x $y -halo 1]
  #puts list=$list
    fp_select $list
  }
}
