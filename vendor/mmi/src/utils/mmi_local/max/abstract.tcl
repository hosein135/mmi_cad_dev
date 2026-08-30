# OLD should be rewritten

# script to create abstracts of large blocks suitable for write_lef

proc abstract {{halo 1.0}} {

  global CELL

  set layers "m1 m2 m3"
  # if set, extends opening for label to border
  set extend 1

  puts "Creating abstract for cell \"[lay_rootcell]\"..."

  setl {x1 y1 x2 y2} [lay_bbox]

  lay_box $x1 $y1 $x2 $y2

  # get toplevel labels only
  sel_labels
  set labels [split [sel_what labels] \n]

  lay_internals -area

  # save all pertinent data
  set save ""
  foreach label $labels {
    setl {layer} $label

    if {[lsearch $layers $layer] == -1} {
      puts "Warning, ignoring label \"[lindex $label 7][lindex $label 6]\".  Layer \"$layer\" not in layers \"$layers\"."
      continue
    }

    eval sel_chunk -any_cell [lrange $label 0 4]
    
    lappend save [list $label [lay_box]]
  }

  # now make a new abstract cell
  set cell_name [lay_rootcell]_abstract

  set flags [cell_flags $cell_name] 
  if { $flags == "__NO_SUCH_BUFFER__" } { 
    # create the new cell 
    puts "Creating cell $cell_name" 
    db_cell_new $cell_name $cell_name$CELL(default_suffix) 
    # goto the cell 
    :load $cell_name 
 
  } else { 
    # goto the cell 
    :load $cell_name 
 
    # otherwise toast the contents of the cell 
    eval sel_area [lay_bbox]
    :delete
  }

  # add blocking planes
  lay_box $x1 $y1 $x2 $y2
  foreach layer $layers {
    :paint $layer
  }

  set dx8 [expr ($x2 - $x1)/8]
  set dy8 [expr ($y2 - $y1)/8]

  # add all top level labels with associated metal, after cutting
  # them out of the blocking planes
  foreach thing $save {
    setl {label metal} $thing

    setl {layer lx1 ly1 lx2 ly2 pos text path group kind} $label

    setl {mx1 my1 mx2 my2} $metal

    # cut out where label goes
    if {$extend} {
      # extend to nearest edge
      set dx1 [expr $mx1 - $x1]
      set dy1 [expr $my1 - $y1]
      set dx2 [expr $x2 - $mx2]
      set dy2 [expr $y2 - $my2]

      set halox1 $halo
      set haloy1 $halo
      set halox2 $halo
      set haloy2 $halo

      if {[expr $mx2 - $mx1] > [expr $my2 - $my1]} {
	if {$dx1 < $dx8} {
	  set halox1 $dx1
	}
      } else {
	if {$dy1 < $dy8} {
	  set haloy1 $dy1
	}
      }

      if {[expr $mx2 - $mx1] > [expr $my2 - $my1]} {
	if {$dx2 < $dx8} {
	  set halox2 $dx2
	}
      } else {
	if {$dy2 < $dy8} {
	  set haloy2 $dy2
	}
      }

      lay_box [expr $mx1 - $halox1] [expr $my1 - $haloy1] \
	  [expr $mx2 + $halox2] [expr $my2 + $haloy2]

    } else {
      lay_box [expr $mx1 - $halo] [expr $my1 - $halo] \
	  [expr $mx2 + $halo] [expr $my2 + $halo]
    }

    :erase $layer

#    if {[string first out $text] != -1} {
#      set kind output
#    } elseif {[lsearch "vdd gnd" $text] != -1} {
#      set kind global
#    } else {
#      set kind input
#    }

    # now add the label and paint
    lay_box $mx1 $my1 $mx2 $my2
    :paint $layer
    lay_box $lx1 $ly1 $lx1 $ly1
    :label -kind $kind $text c $layer
  }

  eval lay_box [lay_bbox]
  :view

  puts "Abstract cell \"$cell_name\" created."
}

