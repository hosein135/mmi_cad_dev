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

set RCSVERSION(calibre.tcl) { $Revision: 1.6 $ }

init_global CALLIBRE(command) \
	-type STRING \
	-default {} \
	-desc {Name of shell script max uses to execute calibre DRC.  If not set,\
	max uses the shell script named drc_it.calibre in the $MMI_LOCAL directory.}



set DRC_IT_PATH $MMI_LOCAL_MAX

proc calibre_setup {} {
  global CALIBRE

  global DRC_IT_PATH  ;# For backward compatibility.
  set CALIBRE(command) [use_first CALIBRE(command) '$DRC_IT_PATH/drc_it.calibre]

  set prop_list ""
  lappend prop_list [list "Calibre Shell Script:" CALIBRE(command) -entry]

  set title "Calibre DRC Setup"
  prop_menu2 -title $title $prop_list
}


proc calibre_it {{type ""}} -desc {
  Pop up window to run Calibre (a registered trademark of Mentor Graphics Corp.)
} {
  global CELL DRC_IT_PATH CALIBRE

  if {$type == "view"} {
    # just view an already run drc result
    calibre_input
    return
  }

  # No longer necessary: just push the View button.
  #global env
  #if {[use_first env(DEMO)] != ""} {
  #  # in demo mode, assume calibre already run and just view results.
  #  set type view
  #}

  setl {cell flags file} [db_cells [lay_rootcell]]
  if {$cell == "(UNNAMED)"} {
    # But it will work on UNNAMED!
    warning "Aborting, calibre won't work with an unnamed cell.\n"
    return
  }

  global DRC_IT_PATH  ;# For backward compatibility.
  set CALIBRE(command) [use_first CALIBRE(command) '$DRC_IT_PATH/drc_it.calibre]

  set action "run"

  set prop_list ""
  lappend prop_list [list "Action" action \
    -radio {{Run Calibre, view feedback} {View feedback from previous Calibre run}} \
    -values {run view}]

  lappend prop_list [list "Calibre Shell Script:" CALIBRE(command) \
       -entry]

  set title "External DRC: Calibre"
  set ret [prop_menu2 -title $title $prop_list]
  if { $ret == 0 } {
    return   ;# cancelled
  }

  if {$action == "run"} {
    calibre_run  ;# Calls calibre_input if it succeeds.
  } else {
    calibre_input
  }

  # Pop up the feedback window.
  feedback_window
}


proc calibre_run {} -desc {
  Run calibre on current cell.
} -doc {
  If -input, then do a calibre_input if calibre succeeds.  This should be the default!
} {
  global CELL MN_TECH DRC_IT_PATH CALIBRE

  # Note this will check the rootcell even in edit-in-place
  setl {cell flags file} [db_cells [lay_rootcell]]
  if {$file == ""} {
    set file [lay_rootcell]
  }
  if {$file == "(UNNAMED)"} {
    error "calibre_run: error: You must rename the editcell first"
  }

  set gds_file "[file rootname $file]$CELL(gds_suffix)"

  cursor_busy 1

  # write out the gds for the current cell
  catch "exec mv $gds_file $gds_file$CELL(backup_suffix)"
  gds_write

  set command [use_first CALIBRE(command) '$DRC_IT_PATH/drc_it.calibre]

  # run calibre
  msg "Running calibre ...\n"
  if {[catch "exec $command $gds_file $cell $MN_TECH" msg]} {
    max_error -buffer "calibre_run aborting: $msg"
  } else {
    msg "$msg\n"
    msg "calibre_run done, loading feedback from calibre....\n"

    calibre_input
  }

  cursor_busy 0
  msg_flush
}


proc calibre_input {} -desc {
  Read back calibre drc files for current cell and make into feedback.
} {

  feedback clear
  feedback_set_source calibre

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
    msg "$msg\n"
    set others 1
  }

  if {[catch "open $drc_results r" file_id]} {
    set log_file [file rootname $file].calibre_log

    set message "Aborting, can't read drc results file \"$drc_results\".  Check that calibre log file \"$log_file\" to see that it ran correctly."
    msg "$message\n"

    # This file is huge.  Dont try to view it this way!
    #catch "exec cat $log_file" msg
    #puts ""
    #puts $msg
    #puts ""

    tk_dialog .dialog Warning $message {} 0 OK

    return 0
  }

  # read the drc results file and create feedback.
  msg "parsing drc results file: $drc_results ...\n"

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
    # \{
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

	    feedback edge -text $error_type \
	      [expr 1.0 * $x / $scale] [expr 1.0 * $y / $scale] \
	      [expr 1.0 * $xx / $scale] [expr 1.0 * $yy / $scale]
	  }
	}

	p {
	  # parse a polygon rule
	  # create lines for the edges
	  set accum ""
	  catch {unset last_x}
	  for {set j 0} {$j < $error_lines} {incr j} {

	    gets $file_id line
	    setl {x y} $line
	    lappend accum [expr 1.0 * $x / $scale]
	    lappend accum [expr 1.0 * $y / $scale]
	  }
	  eval feedback poly -text {$error_type} $accum
	}

	default {
	  msg "calibre_input warning: unknown error type: $line\n"
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
    msg "DRC complete.  Cell is CLEAN!\n"
  } else {
    msg "DRC complete.  $total_errors errors in $error_types error types found.\n"
  }
}
