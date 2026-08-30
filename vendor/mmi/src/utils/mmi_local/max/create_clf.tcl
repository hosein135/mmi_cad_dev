# Creates a clf file for a cell/macro which includes the total fet area
# attached to each I/O.

# Written by Lee Tavrow, 2000.

# The next two lines go into the .maxrc
#source $local_dir/create_clf.tcl
#menu_tool_cmd "create clf" create_clf

proc c {} {
  uplevel #0 source /home/tavrow/dev/max/create_clf.tcl
  puts loaded
  create_clf
}

#====================================================================#

proc create_clf {} -desc {
   Creates a clf file for a cell/macro which includes the total fet area attached to each I/O.
} {

  # make sure everything is fully expanded
  eval lay_box [lay_bbox]
  lay_internals -area

  set cell [lay_rootcell]

  # find the directory
  set dir [file dirname [lindex [cell_info $cell] 1]]
  if {$dir == "."} {
    set dir [pwd]
  }

  set filename $dir/$cell.clf
  puts "Creating clf for cell $cell to $filename ..."

  # open clf file for writing
  if {[catch "open $filename w" FILE_ID]} {
    # can't write file, abort
    warning "Aborting, $FILE_ID"
    return
  }

  sel_labels -kind input
  sel_labels -more -kind inout

  # probably no fet gates but what the hey
  sel_labels -more -kind output

  set fets [techinfo devices]
  set areas 1

  foreach label [split [sel_what labels] \n] {
    setl {layer lx1 ly1 lx2 ly2 pos text path group kind} $label

    if {[info exists TRACE($text)]} {
      # already got this
      continue
    }
    set TRACE($text) 1


    sel_net -no_labels -point $lx1 $ly1 $layer

    set area 0
    foreach paint [split [sel_what paint] \n] {

      if {[lsearch $fets [lindex $paint 0]] != -1} {
	# found a fet, add it up
	setl {player px1 py1 px2 py2} $paint

	set this_area [expr ($px2 - $px1) * ($py2 - $py1)]

	set area [expr $area + $this_area]
      }
    }

    if {$area > 0} {
      puts $FILE_ID "defineGateSize \"$cell\" \"$text\" $area"
      incr areas
    }
  }
 
  # close the file
  close $FILE_ID

  # clean up
  sel_clear

  puts "Wrote $areas areas."
}

