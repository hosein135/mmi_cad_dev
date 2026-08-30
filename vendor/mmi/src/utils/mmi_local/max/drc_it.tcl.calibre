# Runs calibre remotely on the current max cell and annotates problems.

# drc_it.tcl.calibre

# linked to drc_it.tcl to run calibre

# needs auxiliary shell script: drc_it.calibre
# This script should be in the path pointed to below
set DRC_IT_PATH $MMI_LOCAL_MAX

# To view previous results without rerunning calibre, type (in max 
# command window):
#
#       drc_it view
#


proc drc_it {{type ""}} -desc {
  runs calibre drc on the current cell and displays output as feedback
} {

  global env CELL MMI_LOCAL MN_TECH DRC_IT_PATH

  if {[use_first env(DEMO)] != ""} {
    # in demo mode, assume calibre already run and just view results.
    set type view
  }

  # Note this will check the rootcell even in edit-in-place
  setl {cell flags file} [db_cells [lay_rootcell]]
  set gds_file "[file rootname $file]$CELL(gds_suffix)"

  if {$cell == "(UNNAMED)"} {
    warning "Aborting, drc_it won't work with an unnamed cell.\n"
    return
  }

  # Clear all previous feedback
  :feedback clear
  lay_line -clear -tag drc

  if {$type == "view"} {
    # just view an already run drc result
    input_calibre
    return
  }

  # write out the gds for the current cell
  catch "exec mv $gds_file $gds_file$CELL(backup_suffix)"
  gds_write

  # run calibre
  puts "Running calibre ..."
  if {[catch "exec $DRC_IT_PATH/drc_it.calibre $gds_file $cell $MN_TECH" msg]} {
    puts "drc_it aborting: $msg"
    return
  }

  # read the drc_results file and create cells with errors in it.
  puts "parsing drc results file ..."

  # view results as feedback
  input_calibre

  puts "done."
}


proc input_calibre {} -desc {
  read back calibre drc files for current cell and make into feedback.
} {

  setl {cell flags file} [db_cells [lay_rootcell]]
  if {$file == ""} {
    set file [lay_rootcell]
  }

  set drc_results "[file rootname $file].drc_maskdb"
  set drc_sum "[file rootname $file].drc_sum"

  # display any offgrid or other errors
  set others 0
#  if {![catch "exec grep ^OFFGRID $drc_sum" msg]} {
#    puts $msg
#    set others 1
#  }

  # display all
  if {![catch "exec csh -cf \"nawk '  \
         /^---------/  \{ count++ \}  \
         /^-/ \{ next \}              \
         /^Maximum/ { next }        \
         count == 1 { print } ' < $drc_sum\"" msg]} {
    puts $msg
    set others 1
  }

  if {[catch "open $drc_results r" file_id]} {
    set log_file [file rootname $file].calibre_log

    set message "Aborting, can't read drc results file \"$drc_results\".  Check that calibre log file \"$log_file\" to see that it ran correctly."
    puts $message

    catch "exec cat $log_file" msg
    puts ""
    puts $msg
    puts ""

    tk_dialog .dialog Warning $message {} 0 OK

    return 0
  }

  # read the drc results file and create feedback.
  puts "parsing drc results file: $drc_results ..."

  gets $file_id line
  set scale [expr [lindex $line 1] + 0.0]

  set error_types 0
  set total_errors 0

  set del [res]

  while {[gets $file_id line] >= 0} {
    if {[llength $line] != 1} {
	# Ignore irrelevant lines
	continue
    }

    set this_line [string trim $line]
    if {[string index $this_line 0] == "\}" || \
	    [string index $this_line 0] == "/"} {
      continue
    }

    # llength == 1 only occurs when starting a new error cell
    set error_type $line

    # next line says how many errors
    gets $file_id line
    set errors [lindex $line 0]
    incr total_errors $errors

    # ignore next bogus line
    gets $file_id line

    if {$errors == 0} {
      # no errors, go on to next error cell
      continue
    }

    # skip through the bogus lines
    while {[gets $file_id line] >= 0} {
      switch [lindex $line 0] {
	e - p {
	  # got to the locations
	  set start 1
	  break
	}
	Rule {
	  # useless info
	}
	default {
	  set error_type "${error_type}: \[$errors\] $line"
	}
      }
    }

    incr error_types
    puts "  $error_type"

    # we have errors, collect them up
    for {set i 0} {$i < $errors} {incr i} {
      if {$start} {
	# already on the status line of this error
	set start 0
      } else {
	# get the status line of this error
	gets $file_id line
      }

      setl {error_kind error_num error_lines} $line

      switch $error_kind {
	e {
	  # parse an edge rule. 
	  # create lines for the edges
	  catch {unset last_x}
	  for {set j 0} {$j < $error_lines} {incr j} {

	    gets $file_id line
	    setl {x y xx yy} $line

	    # draw a line for this edge
	    boxify $x $y $xx $yy $scale
	    
	    set x [uusnap [expr $x / $scale]]
	    set y [uusnap [expr $y / $scale]]
	    lay_box $x $y [expr $x + $del] [expr $y + $del]
	    :feedback add $error_type pale
	  }
	}

	p {
	  # parse a polygon rule
	  # create lines for the edges
	  catch {unset last_x}
	  for {set j 0} {$j < $error_lines} {incr j} {

	    gets $file_id line
	    setl {x y} $line

	    if {[info exists last_x]} {
	      # draw a line for this edge
	      boxify $x $y $last_x $last_y $scale
	    } else {
	      set first_x $x
	      set first_y $y
	    }

	    set last_x $x
	    set last_y $y
	  }

	  # draw a line for this edge
	  boxify $first_x $first_y $last_x $last_y $scale

	  set x [uusnap [expr $x / $scale]]
	  set y [uusnap [expr $y / $scale]]
	  lay_box $x $y [expr $x + $del] [expr $y + $del]	
	  :feedback add $error_type pale
	}

	old_p {
	  # parse a polygon rule
	  # create rectangle that includes all points
	  catch {unset xmin}
	  for {set j 0} {$j < $error_lines} {incr j} {

	    gets $file_id line
	    setl {x y} $line

	    if {[info exists xmin]} {
	      set xmin [min $xmin $x]
	      set xmax [max $xmax $x]
	      set ymin [min $ymin $y]
	      set ymax [max $ymax $y]
	    } else {
	      set xmin $x
	      set xmax $x
	      set ymin $y
	      set ymax $y
	    }
	  }

	  set x1 [uusnap [expr $xmin / $scale]]
	  set x2 [uusnap [expr $xmax / $scale]]
	  set y1 [uusnap [expr $ymin / $scale]]
	  set y2 [uusnap [expr $ymax / $scale]]

	  lay_box $x1 $y1 [expr $x2 + $del] [expr $y2 + $del]
	  :feedback add $error_type pale
	}

	default {
	  puts "input_calibre warning: unknown error type: $line"
	}
      }
    }
  }

  # clean up
  sel_clear
  eval lay_box [lay_bbox]
  :view

  # close the files
  close $file_id

  if {$error_types == 0 && !$others} {
    puts "DRC complete.  Cell is CLEAN!"
  } else {
    puts "DRC complete.  $total_errors errors in $error_types error types found."
  }
}


proc boxify {x1 y1 x2 y2 scale} -desc {
  make an annotated box around the line given by the coords
} {

  # just a line
#  lay_line [expr $x1 / $scale] [expr $y1 / $scale] \
      [expr $x2 / $scale] [expr $y2 / $scale]


  # rect (assumes x1 < x2, y1 < y2)
  set d [expr 2 * [res] * $scale]

  lay_line -tag drc [expr ($x1 - 0) / $scale] [expr ($y1 - 0) / $scale] \
      [expr ($x2 - 0) / $scale] [expr ($y2 + 0)/ $scale]
  lay_line -tag drc [expr ($x1 + 0) / $scale] [expr ($y1 - 0) / $scale] \
      [expr ($x2 + 0) / $scale] [expr ($y2 + 0)/ $scale]

  lay_line -tag drc [expr ($x1 - $d) / $scale] [expr ($y1 - 0) / $scale] \
      [expr ($x2 - $d) / $scale] [expr ($y2 + 0)/ $scale]
  lay_line -tag drc [expr ($x1 + $d) / $scale] [expr ($y1 - 0) / $scale] \
      [expr ($x2 + $d) / $scale] [expr ($y2 + 0)/ $scale]

  lay_line -tag drc [expr ($x1 - 0) / $scale] [expr ($y1 - $d) / $scale] \
      [expr ($x2 + 0) / $scale] [expr ($y2 - $d)/ $scale]
  lay_line -tag drc [expr ($x1 - 0) / $scale] [expr ($y1 + $d) / $scale] \
      [expr ($x2 + 0) / $scale] [expr ($y2 + $d)/ $scale]
}
