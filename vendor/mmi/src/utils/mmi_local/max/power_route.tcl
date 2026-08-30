# OLD

proc power_route {label1 dir label2 {switch down} {via_height 10}
  {spacing 2}} -desc {
  routes power wires
} {

  global ROUTE

  sel_attached_wire $label1
  setl {layer1 x1_1 y1_1 x1_2 y1_2} [sel_what paint]
  if {$layer1 == ""} {
    # can't find this label (or it isn't attached to a wire)
    msg "Power route failure, can't find label $label1.\n"
    return 0
  }

  sel_attached_wire $label2
  setl {layer2 x2_1 y2_1 x2_2 y2_2} [sel_what paint]
  if {$layer2 == ""} {
    # can't find this label (or it isn't attached to a wire)
    msg "Power route failure, can't find label $label2.\n"
    return 0
  }

  # puts box in area between two wires
  _proute_box $x1_1 $y1_1 $x1_2 $y1_2 $dir $x2_1 $y2_1 $x2_2 $y2_2

  if {$layer1 == $layer2} {
    eval sel_area -layers $layer1 [lay_box]
    set paint [sel_what paint]
    if {$paint == ""} {
      # clear sailing, wire it up
      :paint $layer1
      return 1
    }

    # need to route down then back up or visa-versa

    set p1 "$x1_1 $y1_1 $x1_2 $y1_2"

    # find furthest away paint on this layer
    switch $dir {
      s - south {
	set ymax $y2_2
	foreach this_paint [split $paint \n] {
	  setl {tmp xx1 yy1 xx2 yy2} $this_paint
	  set ymax [max $ymax $yy2]
	}
	set y1_1 [expr $ymax + $spacing]
	set p2 "$x2_1 $y2_1 $x2_2 $y1_1"
      }
      n - north {
	set ymin $y2_1
	foreach this_paint [split $paint \n] {
	  setl {tmp xx1 yy1 xx2 yy2} $this_paint
	  set ymin [min $ymin $yy1]
	}
	set y1_2 [expr $ymin - $spacing] 
	set p2 "$x2_1 $y1_2 $x2_2 $y2_2"
      }
      e - east {
	set xmin $x2_1
	foreach this_paint [split $paint \n] {
	  setl {tmp xx1 yy1 xx2 yy2} $this_paint
	  set xmin [min $xmin $xx1]
	}
	set x1_2 [expr $xmin - $spacing] 
	set p2 "$x1_2 $y2_1 $x2_2 $y2_2"
      }
      w - west {
	set xmax $x2_2
	foreach this_paint [split $paint \n] {
	  setl {tmp xx1 yy1 xx2 yy2} $this_paint
	  set xmax [max $xmax $xx2]
	}
	set x1_1 [expr $xmax + $spacing]
	set p2 "$x2_1 $y2_1 $x1_1 $y2_2"
      }
    }

    # find bbox of other layer route
    _proute_box $x1_1 $y1_1 $x1_2 $y1_2 $dir $x2_1 $y2_1 $x2_2 $y2_2 \
	  $via_height $via_height

    set other_layer $ROUTE($layer1,$switch)

    eval sel_area -layers $other_layer [lay_box]
    set paint2 [sel_what paint]
    if {$paint2 == ""} {
      # clear sailing, wire it up with two layers and vias
      set other_layer_bbox [lay_box]
      :paint $other_layer

      eval _proute_box $p1 $dir $p2
      set layer1_bbox [lay_box]
      :paint $layer1

      # get via overlap
      global VIA
      set via_name $VIA($layer1,$other_layer)
      set overlap $VIA($via_name,overlap)

      # put in the vias
      set box [_program_overlap_box $other_layer_bbox "$x2_1 $y2_1 $x2_2 $y2_2"]
      eval lay_box [_proute_shrink_box $box $overlap]
      :paint $via_name

      set box [_program_overlap_box $other_layer_bbox $layer1_bbox]
      eval lay_box [_proute_shrink_box $box $overlap]
      :paint $via_name

      return 1
    } else {
      # might still be possible with skinnier wire but punt for now
      msg "Power route failure, $other_layer in the way when routing between label $label1 and $label2.\n"

      # add a flyline so the use can hook it up
      setl {xx1 yy1} [center_bbox $p1]
      set label [unique_label]
      lay_box $xx1 $yy1 [expr $xx1 + [res]] [expr $yy1 + [res]]
      :paint $layer1
      :label -kind hidden $label n $layer1

      setl {xx1 yy1} [center_bbox "$x2_1 $y2_1 $x2_2 $y2_2"]
      set label2 [unique_label]
      lay_box $xx1 $yy1 [expr $xx1 + [res]] [expr $yy1 + [res]]
      :paint $layer1
      :label -kind hidden $label2 n $layer1

      db_flyline $label $label2

      return 0
    }

  } else {
    # different layers not implemented yet
    msg "Power route failure, $label1 and $label2 are on different layers, not implemented yet.\n"

    # add a flyline so the use can hook it up
    setl {xx1 yy1} [center_bbox "$x1_1 $y1_1 $x1_2 $y1_2"]
    set label [unique_label]
    lay_box $xx1 $yy1 [expr $xx1 + [res]] [expr $yy1 + [res]]
    :paint $layer1
    :label -kind hidden $label n $layer1

    setl {xx1 yy1} [center_bbox "$x2_1 $y2_1 $x2_2 $y2_2"]
    set label2 [unique_label]
    lay_box $xx1 $yy1 [expr $xx1 + [res]] [expr $yy1 + [res]]
    :paint $layer1
    :label -kind hidden $label2 n $layer1

    db_flyline $label $label2

    return 0
  }
}


proc sel_attached_wire {label} -desc {
  selects the wires attached to the given label.  Label may be in a subcell.
} {

  global max_win

  set index [string last / $label]
  if {$index == -1} {
    # label is in top level cell
    sel_labels -text label
    setl {layer x y} [sel_what labels]
    
  } else {
    # not in top level cell
    set text [string range $label [expr $index + 1] end]
    set cell [string range $label 0 [expr $index - 1]]

    # get information about the cell that the label is in
    sel_cell $cell
    if {[sel_what cells] == ""} {
      # couldn't select cell
      msg "  Skipping, couldn't find cell $cell.\n"
      return 0
    }
    setl {name type x1 y1} [sel_what cells]

    # goto the cell
    edit_push in_place

    sel_labels -text $text
    setl {layer x y} [sel_what labels]

    # go back to the top most cell
    edit_pop
  }

  # select the wire attached to this label
  sel_net -point $x $y $layer
}


proc _proute_box {x1_1 y1_1 x1_2 y1_2 dir x2_1 y2_1 x2_2 y2_2 
  {del1 0} {del2 0}} -desc {
  puts box in area between two wires
} {

  switch $dir {
    s - south - n - north {
      set x1 [max $x1_1 $x2_1]
      set x2 [min $x1_2 $x2_2]
      if {$x1 >= $x2} {
	# no overlap
	return 0
      }
    }
      
    e - east {
      set x1 [expr $x1_2 - $del1]
      set x2 [expr $x2_1 + $del2]
    }

    w - west {
      set x1 [expr $x2_2 - $del2]
      set x2 [expr $x1_1 + $del1]
    }
  }

  switch $dir {
    e - east - w - west {
      set y1 [max $y1_1 $y2_1]
      set y2 [min $y1_2 $y2_2]
      if {$y1 >= $y2} {
	# no overlap
	return 0
      }
    }
      
    n - north {
      set y1 [expr $y1_2 - $del1]
      set y2 [expr $y2_1 + $del2]
    }

    s - south {
      set y1 [expr $y2_2 - $del2]
      set y2 [expr $y1_1 + $del1]
    }
  }

  lay_box $x1 $y1 $x2 $y2
}


proc _proute_shrink_box {box value} -desc {
  returns a box that is shrunk by value
} {

  setl {x1 y1 x2 y2} $box

  return [list [expr $x1 + $value] [expr $y1 + $value] \
	      [expr $x2 - $value] [expr $y2 - $value]]
}


proc _proute_mark_supplies {cell dir labels {exclude xyzzy}} -desc {
  marks supply rails for power routing
} {

  set doit ""

  # goto the cell
  sel_cell $cell
  if {[sel_what cells] == ""} {
    # couldn't select cell
    msg "  Skipping, couldn't find cell $cell.\n"
    return 0
  }
  edit_push in_place

  foreach text $labels {
    switch $dir {
      n - north { set yy 1000000 }
      s - south { set yy -1000000 }
      w - west { set xx -1000000 }
      e - east { set xx 1000000 }
    }
    eval lay_box [lay_bbox]
    sel_labels
    foreach label [split [sel_what labels] \n] {
      if {[lindex $label 6] != $text} {
	# not the correct label
	continue
      }
      if {[lindex [split [lindex $label 7] /] 0] != $cell} {
	# not the correct cell
	continue
      }
      if {[string first $exclude [lindex $label 7]] != -1} {
	# not the correct cell
	continue
      }

      setl {layer x y} $label

      switch $dir {
	n - north {
	  if {$yy > $y} {
	    set xx $x
	    set yy $y
	    set this_layer $layer
	  }
	}
	s - south {
	  if {$yy < $y} {
	    set xx $x
	    set yy $y
	    set this_layer $layer
	  }
	}
	w - west {
	  if {$xx < $x} {
	    set xx $x
	    set yy $y
	    set this_layer $layer
	  }
	}
	e - east {
	  if {$xx > $x} {
	    set xx $x
	    set yy $y
	    set this_layer $layer
	  }
	}
      }
    }

    lappend doit "lay_box $xx $yy [expr $xx + [res]] [expr $yy + [res]]"
    lappend doit ":paint $this_layer"
    lappend doit "lay_box $xx $yy $xx $yy"
    lappend doit ":label ${text}_$dir"
  }

  # go back to where we were
  edit_pop

  foreach thing $doit {
    eval $thing
  }
}
