## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
## LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
## CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
## DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
## INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
## 
## JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
## DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
## PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************



# Controls vcd probe

# make sure this is set
set SUFFIX(vcd) [use_first SUFFIX(vcd) .vcd]


# initialize -- main entry point to use

proc init_vcd_probe {} {

  global cur_s SUFFIX NETLIST VERILOG_PROBE_TYPE VERILOG_PROBE_CMD 

  # compute the filename for the verilog file
  upvar #0 SUE_$NETLIST(root) data
  set filename "$data(dir)$NETLIST(root)$SUFFIX(vcd)"

  if {![file readable $filename]} {
    # try verilog.dump
    set file1 $filename
    set filename "$data(dir)verilog.dump"
    if {![file readable $filename]} {
      warning "Aborting vcd probe: Can't find file \"$file1\" or \"$filename\" to read.  Must first create these running verilog with \$dumpfile(\[<file_name>\]); and \$dumpvars."
      return
    }
  }

  # should be this
  set VERILOG_PROBE_TYPE interactive

  set save $VERILOG_PROBE_CMD(interactive)

  # fool init_probe into running this
  set VERILOG_PROBE_CMD(interactive) "vcd_verilog $filename"
#  set VERILOG_PROBE_CMD(interactive) "/home/tavrow/dev/tcl/vcd_verilog $filename"
  init_probe

  # restore
  set VERILOG_PROBE_CMD(interactive) $save

# ask vcd_verilog for end time using a special syntax???

  verilog_update_flags

  # bring up happy menu
  vcd_time_control $filename

  return
}


# build probe control window

proc vcd_time_control {filename} {

  global VCD VERILOG_STEP WIN

  set VCD(time) [use_first VCD(time) '0]
  set VCD(incr) [use_first VERILOG_STEP '10]
#  set VCD(from) [use_first VCD(from) '0]
  set VCD(from) 0

  # get the ending time from the vcd file
  catch "exec grep ^# $filename | tail -1" VCD(to)
  if {[string index $VCD(to) 0] == "#"} {
    # success
    set VCD(to) [string range $VCD(to) 1 end]
  } else {
    set VCD(to) 1000
  }

  # build toplevel window
  set win .vcd

  # Just in case there is an old one around
  if {![catch "winfo rootx $win" x]} {
    set y [winfo rooty $win]

    # hack to account for borders
    incr x -3
    incr y -25

    catch "destroy $win"

  } else {
    set x [max 0 [expr [winfo rootx $WIN] - 100]]
    set y [expr [winfo rooty $WIN] + 100]
  }

  toplevel $win 

  wm geometry $win "+$x+$y"
  wm title $win "SUE VCD Control"

  # don't let user resize this
  wm resizable $win 0 0

  # row 1
  set f .vcd.row1
  frame $f

  label $f.ltime -text "time:"
  entry $f.time -textvariable VCD(time) -width 7
  bind $f.time <Return> {vcd_incr_by 0}
  label $f.space -text "      "

  button $f.back -text " < " -command {vcd_incr_by [expr -$VCD(incr)]} \
      -padx 0 -pady 0
  button $f.step -text " > " -command {vcd_incr_by $VCD(incr)} \
      -padx 0 -pady 0

  label $f.lincr -text "    increment:"
  entry $f.incr -textvariable VCD(incr) -width 7
  bind $f.incr <Return> \
      {.vcd.row2.slide configure -resolution [.vcd.row1.incr get]}

  pack $f.ltime $f.time $f.space -side left -fill x
  pack $f.incr $f.lincr $f.step $f.back -side right -fill x

  # row 2
  set f .vcd.row2
  frame $f

  label $f.lstart -text "start:"
  entry $f.start -textvariable VCD(from) -width 7
  bind $f.start <Return> {.vcd.row2.slide configure -from [.vcd.row2.start get]}

  scale $f.slide -from $VCD(from) -to $VCD(to) -orient horizontal \
      -command {set VCD(time)} -showvalue 0 -length 2i -resolution $VCD(incr)
  bind $f.slide <B1-ButtonRelease> {vcd_slide_action}

  label $f.lend -text "end:"
  entry $f.end -textvariable VCD(to) -width 7
  bind $f.end <Return> {.vcd.row2.slide configure -to [.vcd.row2.end get]}
  
  pack $f.lstart $f.start $f.slide $f.lend $f.end -side left

  # row 3
  frame .vcd.row3
  button .vcd.row3.close -text "Close VCD Probe" \
      -command {catch "destroy .vcd" ; close_probe}
  pack .vcd.row3.close
  
  # pack the rows
  pack .vcd.row1 .vcd.row2 .vcd.row3 -side top

  # do it
  vcd_incr_by 0
}


proc vcd_slide_action {} {

  # display new values at this time
  vcd_incr_by 0
}


# increment time by given and update flags

proc vcd_incr_by {delta} {

  global VCD

  incr VCD(time) $delta

  # don't go negative
  set VCD(time) [max $VCD(time) 0]

  .vcd.row2.slide set $VCD(time)

  # call "verilog"
  v "@$VCD(time)"

  verilog_update_flags
}


# If you have no header with a $finish statement, this will generate something

proc generate_vcd {} {

  global VERILOG_CMD vcd_stop_time

  # get the stop time from user with a popup
  set title "Generate VCD"
  set message "Enter Stop Time:" 

  set prop_list ""

  set vcd_stop_time [use_first vcd_stop_time '500]
  lappend prop_list [list time $vcd_stop_time]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  set cell [api_current_cell]
  set dir [file dirname [get_assoc filename [api_cell_info]]]

  # open vcd setup file
  set filename $dir/$cell.vcd_setup
  if {[catch {open $filename w} WRITE_FILE_ID] != 0} {
    warning "Aborting generated_vcd, could not create file $filename"
    return
  }

  # write vcd setup file
  puts $WRITE_FILE_ID {`timescale 1ps / 1ps}
  puts $WRITE_FILE_ID "module ${cell}_vcd_setup;"
  puts $WRITE_FILE_ID {initial begin}
  puts $WRITE_FILE_ID "\$dumpfile(\"$dir/$cell.vcd\");"
  puts $WRITE_FILE_ID {$dumpvars;}
  puts $WRITE_FILE_ID {$display("begin vcd dump");}
  puts $WRITE_FILE_ID "#$vcd_stop_time;"
  puts $WRITE_FILE_ID {$display("end vcd dump");}
  puts $WRITE_FILE_ID {$finish;}
  puts $WRITE_FILE_ID {end}
  puts $WRITE_FILE_ID {endmodule}

  # close vcd setup file
  close $WRITE_FILE_ID

  # run verilog
  set save $VERILOG_CMD
  set VERILOG_CMD "$VERILOG_CMD $filename"
  verilog_it
  set VERILOG_CMD $save
}
