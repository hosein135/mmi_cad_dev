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


# Set up the main window with all menus and scrollbars

proc setup_window {win} {
  global VERSION SCROLLBAR DEFAULT_GEOMETRY GEOMETRY

  # why a new top level window?  Otherwise the nst window will move on
  # the first repack once tk figures out the true banner sizes.
  toplevel $win

  if {[info exists GEOMETRY]} {
    wm geometry $win $GEOMETRY
  } else {
    wm geometry $win $DEFAULT_GEOMETRY
  }

  wm minsize $win 400 300
  # eventually we will make one of these babies.
#  wm iconbitmap $win $NST_DIR/nst_icon.xbm

  # handle delete window protocols from window manager
  wm protocol $win WM_DELETE_WINDOW exit

  # the menubar (mb) frame is at the top of the window
  frame $win.mb -relief raised -bd 2

  label $win.nst -text " $VERSION " -bd 2 -relief groove
  set WIN_DATA($win,display_msg) ""
  label $win.title -text "" -bd 2 -anchor w \
      -textvariable WIN_DATA($win,display_msg)

  menubutton $win.mb.file -text File -menu $win.mb.file.menu -padx 2 -pady 2

  menubutton $win.mb.view -text View -menu $win.mb.view.menu \
      -padx 2 -pady 2

  menubutton $win.mb.derive -text Derive -menu $win.mb.derive.menu \
      -padx 2 -pady 2

  menubutton $win.mb.print -text Print -menu $win.mb.print.menu -padx 2 -pady 2
  menubutton $win.mb.help -text Help -menu $win.mb.help.menu -padx 2 -pady 2

  pack $win.mb.file $win.mb.view $win.mb.derive $win.mb.print \
      $win.mb.help -in $win.mb -side left
  pack $win.nst -in $win.mb -side left 
  pack $win.title -in $win.mb -fill x -side left

  button $win.left -text "<" -command "nst_move_margin 4" \
      -bd 0 -padx 0 -pady 0
  button $win.right -text ">" -command "nst_move_margin -4" \
      -bd 0 -padx 0 -pady 0
  pack $win.right -in $win.mb -side right
  pack $win.left -in $win.mb -side right

  # the derive pulldown menu
  menu $win.mb.derive.menu
  menu_add -menu derive -label "New Derivation...  " \
      -command nst_new_derivation \
      -help "Prompt to create a derived signal from other signals."
  menu_add -menu derive -label separator

  # the file pulldown menu
  menu $win.mb.file.menu
  menu_add -menu file -label "Load...   " \
      -command nst_load_file_popup \
      -hotkey l -help "Prompt for the name of a data file to load into NST."

  menu_add -menu file -label separator
  menu_add -menu file -label separator
  menu_add -menu file -label "Reset NST" -command nst_reset \
      -help "Clear all loaded data as if NST were restarted."
  menu_add -menu file -label separator
  menu_add -menu file -label "Exit" -command exit \
      -hotkey "Control-c,Control-d" -help "Exit NST."

  # the panel pulldown menu
  menu $win.mb.view.menu
  menu_add -menu view -label "Add Panel" -command nst_make_graph \
      -hotkey "a" -help "Add a new panel to the display."
  menu_add -menu view -label "Remove Selected Panel   " \
      -command {nst_remove_graph [lindex $nst_graphs 0]} \
      -hotkey "r" -help "Remove the current panel from the display."
  menu_add -menu view -label separator
  menu_add -menu view -label "Clear Current Panel   " \
      -command nst_clear_panel \
      -hotkey "c" -help "Remove all of the signals from the current panel."
  menu_add -menu view -label "Erase All Panels   " \
      -command nst_erase_all \
      -hotkey "e" -help "Remove all of the signals from all of the panels and remove all but one panel."
  menu_add -menu view -label separator
  menu_add -menu view -label "Zoom to Area" \
      -hotkey "Button-1" \
      -help "Trace out a zoom region."
  menu_add -menu view -label "Measure Box" \
      -hotkey "Button-2" \
      -help "Trace out a box to measure.  Delta x/y are shown in bottom right."
  menu_add -menu view -label "Measure" \
      -hotkey "Shift-Button-2" \
      -help "Measure the difference between two signals by tracing from one to the other using a given Y coordinate."
  menu_add -menu view -label "Measure Slope" \
      -hotkey "Control-Button-2" \
      -help "Measure the slope of the nearest waveform."
  menu_add -menu view -label "Zoom to Fit" \
      -command nst_unzoom \
      -hotkey "Button-3" \
      -help "Zoom out to fit all current waveforms."
  menu_add -menu view -label "Zoom to..." -command nst_zoom_to \
      -hotkey "Z" \
      -help "Prompt to set the zoom coordinates."
  menu_add -menu view -label "Zoom To Last" \
      -command nst_unzoom_last \
      -hotkey "z" \
      -help "Return the screen zoom to where it was before the last zoom operation."
  menu_add -menu view -label "Unlock Zoom" -command nst_toggle_lock \
      -help "Unlock the X-axis between different panels so they can be different."

  menu_add -menu view -label separator
  menu_add -menu view -label "Change Measure Y Coordinate..." \
      -command nst_change_measure_ycoord \
      -hotkey "m" \
      -help "Popup to select the Y value (usually the voltage or current) for measurements."
  menu_add -menu view -label "Change Slope Percentages..." \
      -command nst_change_slope_percentages \
      -hotkey "s" \
      -help "Popup to change the min/max percentages when measuring the slope."

  menu_add -menu view -label separator
  menu_add -menu view -label "Compute Power..." \
      -command nst_power_calc \
      -help "Prompts for current and voltage waveforms to compute power in.  Interval for computation can be set by measure box."

  menu_add -menu view -label separator
  menu_add -menu view -label "Annotate..." \
      -command nst_annotate_text \
      -hotkey "t" \
      -help "Prompt for text/color/font to annotate onto graph.  Button-2 over text to move/delete it."
  menu_add -menu view -label "Clear All Annotationts" \
      -command {nst_clear_annotations} \
      -help "Clears all annotations.  Individual annotations can be cleared with Shift-Button-2 over them."
  menu_add -menu view -label separator
  menu_add -menu view -label "Toggle All X Log/Linear" \
      -command nst_toggle_log_linear \
      -hotkey "x" \
      -help "Toggle the X-axis between a linear and a logarithmic scale."
  menu_add -menu view -label "Toggle Current Y Log/Linear  " \
      -command {nst_toggle_log_linear y current} \
      -hotkey "y" \
      -help "Toggle the Y-axis between a linear and a logarithmic scale."
  menu_add -menu view -label separator
  menu_add -menu view -label "Toggle Crosshairs" \
      -command toggle_crosshairs \
      -help "Toggle the pointer between an arrow and full screen crosshairs."

  # the misc pulldown menu
  menu $win.mb.help.menu
  menu_add -menu help -label "About NST..." \
      -command about_nst \
      -help "Popup a window describing the current version of NST."
  menu_add -menu help -label separator
  menu_add -menu help -label "NST Manual" \
      -command doc \
      -help "Bring up the NST Manual in a browser."
  menu_add -menu help -label separator
  menu_add -menu help -label "MMI Documentation Guide" \
      -command "doc mmidoc" \
      -help "Bring up the MMI Documentation guid in a browser."

  # the print pulldown menu
  menu $win.mb.print.menu
  menu_add -menu print -label "Print to Default Printer" \
      -command {nst_make_ps print} \
      -help "Print the current waveforms using lpr."
  menu_add -menu print -label "Print to File" \
      -command {nst_make_ps nst.ps} \
      -help "Print the current waveforms to a postscript file."
  menu_add -menu print -label separator
  
  $win.mb.print.menu add radiobutton -label Mono \
      -variable NST_PS_MODE -value mono
  $win.mb.print.menu add radiobutton -label Gray \
-variable NST_PS_MODE -value gray
  $win.mb.print.menu add radiobutton -label Color \
-variable NST_PS_MODE -value color

  # currently doesn't change graph sizes correctly on resize
#  bind $win <Configure> {puts "help me, I'm resizing %a"}

  # setup the bindings for the hot keys
#  bind $win <Any-KeyPress-a> {nst_make_graph}
#  bind $win <Any-KeyPress-r> {nst_remove_graph [lindex $nst_graphs 0]}
#  bind $win <Any-KeyPress-e> {nst_erase_all}
#  bind $win <Any-KeyPress-c> {nst_clear_panel}
#  bind $win <Any-KeyPress-l> {nst_load_file_popup}
#  bind $win <Any-KeyPress-z> {nst_unzoom_last}
#  bind $win <Any-KeyPress-m> {nst_change_measure_ycoord}
#  bind $win <Any-KeyPress-x> {nst_toggle_log_linear}
#  bind $win <Any-KeyPress-y> {nst_toggle_log_linear y current}
#  bind $win <Control-c> {exit}
#  bind $win <Control-d> {exit}

  # so you can traverse menu sideways
  tk_menuBar $win.mb $win.mb.file $win.mb.view $win.mb.derive \
      $win.mb.print $win.mb.help

  # the data frame is at the bottom of the window
  frame $win.data
  label $win.cursor_pos 
  label $win.delta
  pack $win.cursor_pos -in $win.data -side left
  pack $win.delta -in $win.data -side right

  # pack the frames in.  Now we just need the graphs
  pack $win.mb -side top -fill x
  pack $win.data -side bottom -fill x

  if {$SCROLLBAR == "on"} {
    scrollbar $win.hscroll -orient horiz -relief sunken -command {nst_scroll} \
	-highlightthickness 0 
#    $win.hscroll set 100000 100000 0 100000
    $win.hscroll set 0.0 1.0
    pack $win.hscroll -side bottom -fill x
  }
}


# makes a graph panel and packs it in

proc nst_make_graph {} {
  global nst_graph_id nst_graphs nst_active nst_files nst_datasets nst_axis
  global env LOG_LINEAR GRID_HIDDEN GRID_PATTERN RIGHT_MARGIN
  global X_SUBDIVISIONS Y_SUBDIVISIONS MINOR_GRID CROSSHAIRS WIN

  # make into the form graph00001, so it will be sorted before graph00010
  set graph [format "$WIN.graph%s" \
		 [string range [expr 10000 + $nst_graph_id] 1 end]]
  incr nst_graph_id
  set other_graph [lindex $nst_graphs 0]

  # figure out right margin -- changes from <>
  set existing_graph [lindex $nst_graphs 0]
  if {$existing_graph == ""} {
    set right_margin $RIGHT_MARGIN
  } else {
    set right_margin [$existing_graph cget -rightmargin]
  }

  set nst_graphs [concat $graph $nst_graphs]

  # now make the graph (blt_graph) and then pack it in
  graph $graph -title "" -topmargin 1 \
      -plotbackground black -bg LightGrey -rightmargin $right_margin

  $graph grid configure -hide $GRID_HIDDEN -dashes $GRID_PATTERN \
      -minor $MINOR_GRID

  $graph legend configure -anchor ne -foreground white -background black

  $graph pen configure activeLine -symbol "" -color white

  pack $graph -side top -fill both -expand 1

  if {$other_graph != "" && [$other_graph element show] != ""} {
    set limits [$other_graph xaxis limits]
    $graph xaxis configure -min [lindex $limits 0] -max [lindex $limits 1]
  }

  # serious hack
  if {[llength $nst_graphs] == 2} {
    set limits [$graph xaxis limits]
    $other_graph xaxis configure -min [lindex $limits 0] -max [lindex $limits 1]
  }

  if {$CROSSHAIRS != 0 && $CROSSHAIRS != "false"} {
    Blt_Crosshairs $graph
  }

  if {[info exists nst_files] == 1 && $nst_files != ""} {
    set xaxis_name $nst_axis(xaxis)
  } else {
    set xaxis_name ""
  }

  if {$other_graph == ""} {
    set log $LOG_LINEAR(x)
  } else {
    # use from a different graph
    set log [$other_graph xaxis cget -logscale]
  }

  $graph xaxis configure -subdivisions $X_SUBDIVISIONS \
      -command nst_format_label \
      -title $xaxis_name -logscale $log \
      -ticklength 0

  if {$other_graph == ""} {
    set log $LOG_LINEAR(y)
  } else {
    set log [$other_graph yaxis cget -logscale]
  }
  
  $graph yaxis configure -title " " -rotate 90.0 \
      -subdivisions $Y_SUBDIVISIONS \
      -command nst_format_label -logscale $log \
      -ticklength 0

  nst_possibly_rotate_ylabels
  
  # Set up the bindings
  #bind $graph <Motion> {nst_show_pos %W %x %y}
  bind $graph <Motion> {nst_motion_procs %W %x %y}

  bind $graph <Button-2> \
      {nst_draw_box_setup %W %x %y ; nst_mem_coord %W %x %y closest}

  bind $graph <Shift-Button-2> {nst_measure %W %x %y start}

  bind $graph <Control-Button-2> {nst_slope %W %x %y}
  
#  bind $graph <Button-1> {nst_mem_coord %W %x %y}
#  bind $graph <Button1-Motion> \
      {nst_draw_box %W %x %y ; nst_show_pos %W %x %y}
#  bind $graph <ButtonRelease-1> {nst_zoom_in %W %x %y}

  bind $graph <Button-1> {nst_button1 press %W %x %y}
  bind $graph <Button1-Motion> {nst_button1 motion %W %x %y}
  bind $graph <ButtonRelease-1> {nst_button1 release %W %x %y}

  bind $graph <Button-3> {nst_unzoom %W}

  nst_fix_xaxis

  # resize the height manually.
  set num [llength $nst_graphs]
  if {$num > 1} {
    # needs to be updated to get height
    update 

    set height 0
    foreach win $nst_graphs {
      incr height [expr [winfo height $win] - [$win cget -bottommargin]]
    }

    foreach win [lsort $nst_graphs] {
      $win configure -height [expr $height/$num + [$win cget -bottommargin]]
    }
  }

  set nst_active($graph) ""
  nst_goto_graph $graph

  return $graph
}


# Type of operation: either zoom of legend
set nst_coord(type) zoom

# Do for button-1 events

proc nst_button1 {type graph x y} {

  global nst_coord nst_graphs

  switch $nst_coord(type) {

    zoom {

      switch $type {

	press {
	  nst_mem_coord $graph $x $y
	}
	motion {
	  nst_draw_box $graph $x $y
	  nst_show_pos $graph $x $y
	}
	release {
	  nst_zoom_in $graph $x $y
	  set nst_coord(type) zoom
	}
      }
    }

    legend {

      switch $type {

	press {
	  foreach _graph $nst_graphs {
	    $_graph configure -cursor trek
	  }
	}
	motion {
	}
	release {

	  set winx [expr [winfo x $graph] + $x]
	  set winy [expr [winfo y $graph] + $y]

	  foreach _graph $nst_graphs {
	    $_graph configure -cursor ""

	    set newx [expr $winx - [winfo x $_graph]]
	    set newy [expr $winy - [winfo y $_graph]]

	    if {[$_graph inside $newx $newy]} {
	      if {$graph != $_graph} {
		# get the color
		set color [$graph element cget $nst_coord(legend) -color]

		if {$nst_coord(filename) == "__DERIVED__"} {
		  # special case for derived
		  set name $nst_coord(legend)
		  
		  # erase from old
		  nst_goto_graph $graph
		  nst_toggle_derive $name
		  
		  # add to new
		  nst_goto_graph $_graph
		  
		  if {[lsearch -exact [$_graph element show] $name] == -1} {
		    # doesn't exist, add it
		    nst_toggle_derive $name
		  }

		  # fix up color
		  $_graph element configure $name -color $color

		} else {

		  # this is where is came from
		  nst_goto_graph $graph
		  nst_unplot $nst_coord(filename) $nst_coord(legend)

		  # this is where it should go
		  nst_goto_graph $_graph
		  nst_plot $nst_coord(filename) $nst_coord(legend) "" "" $color
		}

		nst_activate_node $_graph ""
		nst_activate_node $graph ""
	      }
	    }
	  }

	  set nst_coord(type) zoom
	}
      }
    }
  }
}


# Only the bottom graph has an x-axis unless the x-axis is unlocked or
# the user has set ALWAYS_XAXIS

proc nst_fix_xaxis  {} {
  
  global nst_graphs ALWAYS_XAXIS NST_LOCK

  set graphs [lsort $nst_graphs]
  set last_graph [lindex $graphs [expr [llength $graphs] - 1]]
  
  foreach graph $graphs {
    if {$graph == $last_graph || $ALWAYS_XAXIS || !$NST_LOCK} {
      # show the xaxis stuff
      set xaxis_name [$graph xaxis cget -title]
      if {$xaxis_name == ""} {
	$graph configure -bottommargin 30
      } else {
	$graph configure -bottommargin 50
      }
    } else {
      # toast the bottommargin (or xaxis)
      $graph configure -bottommargin 1
    }
  }
}


# If the graph windows are short, rotate the yaxis label so they don't
# run into eachother.  

proc nst_possibly_rotate_ylabels {} {
  global nst_graphs LEFT_MARGIN
  
  set height [expr [winfo screenheight .]/[llength $nst_graphs]]
  # weirdness of delayed geometry management
  if {$height == 1} {
    set height 500
  }
  
  if {$height < 200} {
    foreach graph $nst_graphs {
      $graph yaxis configure -rotate 0
      $graph configure -leftmargin [expr $LEFT_MARGIN+35]
    }
  } else {
    foreach graph $nst_graphs {
      $graph yaxis configure -rotate 90
      $graph configure -leftmargin $LEFT_MARGIN
    }
  }
}


# highlite selected graph and focus on it

proc nst_goto_graph {graph} {
  global nst_graphs
  
  set graph_pos [lsearch $nst_graphs $graph]
  if {$graph_pos == -1} {
    return "Graph $graph doesn't exist"
  }
  
  set unselected_graphs [lreplace $nst_graphs $graph_pos $graph_pos]
  foreach win $unselected_graphs {
    $win configure -bg grey
  }
  
  set nst_graphs [concat $graph $unselected_graphs]
  $graph configure -bg LightGrey
}


# Finds the limits of the graph window.

proc nst_find_limits {{graph ""}} {
  global nst_graphs

  if {$graph == ""} {
    set graph [lindex $nst_graphs 0]
  }

  return "[$graph xaxis limits] [$graph yaxis limits]"
}


# Uses FSBox file selector to load files.  Replaces nst_load_file_popup above.

proc nst_load_file_popup {} {
  global nst_new_file nst_command SUFFIX FSBOX

  set nst_new_file [fs_box -message "Load File:" \
		-pattern [use_first FSBOX(pattern) SUFFIX(default) '*.*]]

  # need to take the focus back since FSBox doesn't give it back automatically
#  focus .
  if {$nst_new_file != ""} {
    busy
    set result [nst_load $nst_new_file]
    if {$result != 1} {
      puts "Error: $result"
    }
    ready
  }
}


# nst_load reads in a spice data file and sets up the appropriate
# structures.  Must be done before any plotting.

proc nst_load {full_filename} {
  global nst_datasets nst_id nst_files nst_graphs nst_axis WIN DERIVE
  global nst_nodes_$nst_id nst_node_types_$nst_id nst_derived_nodes
  
  busy
  if {[catch {nst_read_tr0 $full_filename $nst_id} msg] == 1} {
    ready
    return $msg
  }
  
  # strip off directory 
  set filename [file tail $full_filename]

  # if you see the title, you know the file was read successfully
  wm title $WIN "nst:$filename"
  wm iconname $WIN "nst:$filename"
  msg_window [string trim $nst_datasets($filename,title)] default
  
  # windows can't have "." and can't start with uppercase letters
  regsub -all {\.} $filename * nst_datasets($filename,menu) 
  set nst_datasets($filename,menu) "n_$nst_datasets($filename,menu)"
  
  if {[lsearch $nst_files $filename] != -1} {
    # already present, nuke it
    nst_remove_file $filename
    # must also erase all panes since data is cached in them
    nst_erase_all
  }
  
  set nst_datasets($filename,id) $nst_id
  incr nst_id

  set xaxis $nst_datasets($filename,xdefault)
  set nst_datasets($filename,xaxis) $xaxis

  set nst_datasets($filename,suffix) [compute_suffix $filename]
  set nst_datasets($filename,canfree) 1
  
  lappend nst_files $filename
  
  # Add the entry for this file into .mb.file.menu
  set position [expr [lsearch $nst_files $filename] + 3]
  menu_add -menu file -position $position -label $filename \
      -command "nst_make_node_listbox $filename" \
      -help "Loaded data file.  Bring up popup of node names for plotting."
  
  # pick up the current window
  set graph [lindex $nst_graphs 0]

  set nst_axis(xaxis) [nst_xaxis_name $xaxis $filename]
  $graph xaxis configure -title $nst_axis(xaxis)

  if {$nst_axis(xaxis) == ""} {
    $graph configure -bottommargin 30
  } else {
    $graph configure -bottommargin 50
  }
  
  set ps_file "[file root $full_filename].ps"

  # assume that this is the second entry in this menu
  $WIN.mb.print.menu entryconfigure 2 \
      -label "Print to File \"$ps_file\"" -command "nst_make_ps $ps_file"

  nst_forget_vectors
  
  nst_remove_markers

  # put in the default derives if any
  if {[info exists DERIVE]} {
    foreach derive $DERIVE {
      nst_derive_node $derive just_derive
    }
  }

  ready
  return 1
}


# nst_plot loads node data into a vector if it isn't already there and
# then tells the window to plot the data.  nst_plot will switch to
# or create a window with the correct type (either Current or Voltage)
# unless told not to.

proc nst_plot {filename node {switch 1} {graph ""} {color ""}} {
  global nst_datasets nst_graphs

  if {![info exists nst_datasets($filename,id)]} {
    puts "Aborting, Can't find file \"$filename\" to plot in."
    return 0
  }

  set id $nst_datasets($filename,id)
  global nst_nodes_$id nst_node_types_$id
  
  if {[string last $nst_datasets($filename,suffix) $node] == -1} {
    set node_name [bltify_node_name $node$nst_datasets($filename,suffix)]
    set node_legend "$node$nst_datasets($filename,suffix)"

  } else {
    set node_name [bltify_node_name $node]
    set node_legend $node
  }
  
  if {![info exists nst_nodes_${id}($node)]} {
    if {[string toupper [string range $node 0 1]] == "I("} {
      return [nst_plot $filename [string range $node 2 end] $switch $graph $color]
    }

    puts "Aborting, Can't find node \"$node\" in file \"$filename\"."
    return 0
  }
  
  if {$switch == 1} {
    set node_type [set nst_node_types_${id}($node)]
    nst_find_graph $node_type
  }
  
  if {$graph == ""} {
    # use the current graph window for plotting
    set graph [lindex $nst_graphs 0]
  }

  if {$color == ""} {
    # get the next color
    set color [nst_next_color]
  } else {
    # change to next color if this is the current color
    nst_next_color $color
  }

  if {[lsearch -exact [$graph element names] $node_legend] == -1} {
    # if this node doesn't exist, load it
    # xaxis
    set xdata $nst_datasets($filename,xaxis)$nst_datasets($filename,suffix)
    set xdata [bltify_node_name $xdata]
    nst_get_node_if_needed $filename $nst_datasets($filename,xaxis) $xdata
	
    # yaxis
    nst_get_node_if_needed $filename $node $node_name

    $graph element create $node_legend -pixels 0 -symbol "" \
        -xdata $xdata -ydata $node_name -linewidth 1

    # add a command to the legend.  For moving waveforms.
    $graph legend bind $node_legend <ButtonPress-1> \
	"set nst_coord(legend) \{$node_legend\} ; set nst_coord(type) legend ; set nst_coord(filename) $filename"
    $graph legend bind $node_legend <ButtonPress-2> \
	"set nst_coord(filename) $filename"

    # BLT appears to have a bug when activating a legend with [] in the name

#    $graph legend bind $node_legend <Enter> \
	"puts \{enter_\{$node_legend\}\} ; $graph legend configure -raised 1 ; $graph legend activate \{$node_legend\}"
#    $graph legend bind $node_legend <Leave> \
	"puts \{leave_\{$node_legend\}\} ; $graph legend deactivate \{$node_legend\}"

    # Insure that the whole legend is raised
    $graph legend bind $node_legend <Enter> \
	"$graph legend configure -raised 1"

  } elseif {[lsearch -exact [$graph element show] $node_legend] == -1} {
    $graph element show [concat [$graph element show] $node_legend]
  }

  $graph element configure $node_legend -color $color
  
  return 1
}


# load data for a node into a vector if not already done.

proc nst_get_node_if_needed {filename node {node_name ""}} {

  if {$node_name == ""} {
    set node_name [bltify_node_name $node]
  }

#puts "$node --> $node_name"

  # is there a vector for this node name
  if {[lsearch -exact [vector names] $node_name] != -1} {
    # already exists
    return $node_name
  }

  # otherwise load it

  global nst_datasets
  set id $nst_datasets($filename,id)
  global nst_nodes_$id

  if {[info exists nst_nodes_${id}($node)]} {
    set node_id [set nst_nodes_${id}($node)]
  } else {
    # doesn't exist
    return Unknown
  }

  # make the vector (must be global)
  global $node_name
  vector $node_name

  nst_get_node $nst_datasets($filename,ptr) $node_name $node_id

  return $node_name
}


# find a graph window that has the correct type of the node to be
# drawn (either Voltage or Current) and if none exists, makes one

proc nst_find_graph {type} {
  global nst_graphs nst_axis
  
  foreach win $nst_graphs {
    set win_type [$win yaxis cget -title]
    if {[string trim $win_type] == ""} {
      $win yaxis configure -title $nst_axis($type)
      nst_goto_graph $win
      return
    }
    if {$win_type == $nst_axis($type)} {
      nst_goto_graph $win
      return
    }
  }
  # no windows of desired type.  Make a new one
  nst_make_graph
  [lindex $nst_graphs 0] yaxis configure -title $nst_axis($type)
}


# nst_unplot tells the window to stop plotting the node.  

proc nst_unplot {filename node {mode ""} {win ""}} {
  global nst_datasets nst_graphs
  
#  set node [bltify_node_name $node]

  if {![info exists nst_datasets($filename,id)]} {
    puts "Aborting, Can't find file \"$filename\" to unplot in."
    return 0
  }

  if {[string last $nst_datasets($filename,suffix) $node] == -1 && \
	$mode == ""} {
    set node_name "$node$nst_datasets($filename,suffix)"
  } else {
    set node_name $node
  }

  if {$win == ""} {
    # pick up the current window if not given
    set win [lindex $nst_graphs 0]
  }
  
  set display_nodes [$win element show]
  set node_pos [lsearch -exact $display_nodes $node_name]

  if {$node_pos == -1} {
    if {[regsub {(\(I\()|(I\()} $node_name "" node_name]} {
      # try without I(
      set node_pos [lsearch -exact $display_nodes $node_name]
    }
  }

  if {$node_pos == -1} {
    return "Aborting, Node \"$node_name\" in file \"$filename\" isn't being plotted."
  }
  $win element show [lreplace $display_nodes $node_pos $node_pos]
  
  if {[$win element show] == ""} {
    $win yaxis configure -title ""
  }
}


# moves data structures around for use with plotting old nodes.
# nst_copy also resets the graph window and frees up old data structures
# Technically this renames, not copies.

proc nst_copy {filename new_filename} {
  global nst_datasets nst_graphs nst_files WIN
  
  nst_lose_node_menus
  
  # free up the data structure for the file, if it exists, that you
  # are copying over.
  if {[info exists nst_datasets($new_filename,id)]} {
    nst_remove_file $new_filename
  }
  
  set nst_derived_nodes {}
  
  set nst_datasets($new_filename,ptr) $nst_datasets($filename,ptr)
  set nst_datasets($new_filename,id) $nst_datasets($filename,id)
  set nst_datasets($new_filename,xaxis) $nst_datasets($filename,xaxis)
  set nst_datasets($new_filename,menu) \
      [format "%s~" $nst_datasets($filename,menu)]
  set nst_datasets($new_filename,suffix) "~"
  set nst_datasets($new_filename,canfree) 1
  
  lappend nst_files $new_filename
  # Add the entry for this file into $win.mb.file.menu
  set position [expr [lsearch $nst_files $new_filename] + 3]
  menu_add -menu file -position $position -label $new_filename \
      -command "nst_make_node_listbox $new_filename" \
      -help "Copied data file.  Bring up popup of node names for plotting."
  
  # Since we don't actually copy the data structure, we now have
  # two pointers to the same data structure and we have to insure
  # that we don't accidentally free up through the wrong pointer
  set nst_datasets($filename,canfree) 0
  
  nst_erase_all

  nst_forget_vectors
}


# nst_free frees up everything having to do with an unwanted filename

proc nst_free {filename} {
  global nst_datasets
  
  if {[info exists nst_datasets($filename,id)] == 1} {
    set id $nst_datasets($filename,id)
    global nst_nodes_$id nst_node_types_$id
    
    catch {unset nst_nodes_$id}
    catch {unset nst_node_types_$id}
    
    nst_free_struct nst_datasets(filename,ptr)
  }
}


# Clear current panel

proc nst_clear_panel {} {
  global nst_graphs
  
  set graph [lindex $nst_graphs 0] 

  $graph element show {}
  
  nst_remove_markers

  nst_clear_annotations $graph

  nst_possibly_rotate_ylabels
}	


# Erase all graphs and leave one empty graph pane

proc nst_erase_all {} {
  global nst_graphs
  
  nst_remove_markers

  foreach win $nst_graphs {
    pack forget $win
  }
  
  set nst_graphs ""
  
#  nst_possibly_rotate_ylabels
  
  nst_clear_annotations

  # now make a new graph
  nst_make_graph
}	


# reset frees all data files and erases all windows

proc nst_reset {} {
  global nst_files nst_derived_nodes nst_datasets WIN
  
  nst_lose_node_menus
  
  foreach file $nst_files {
    nst_remove_file $file
  }
  
  foreach dummy $nst_derived_nodes {
    $WIN.mb.derive.menu delete 3
  }
  set nst_derived_nodes {}
  
  nst_erase_all

  nst_forget_vectors
}


# forgets all vectors so they will be recomputed

proc nst_forget_vectors {} {

  global nst_graphs

  foreach graph $nst_graphs {
    foreach name [$graph element names] {
      $graph element delete $name
    }
  }

  foreach v [vector names] {
    # toast it
    vector destroy $v
  }
}


# Removes file information from internal data structures and frees them

proc nst_remove_file {file} {
  global nst_datasets nst_files WIN
  
  set menu_name $WIN.mb.file.menu.$nst_datasets($file,menu)
  if {[winfo exists $menu_name] == 1} {
    destroy $menu_name
  }
  
  $WIN.mb.file.menu delete [expr [lsearch $nst_files $file] + 3]
  
  if {$nst_datasets($file,canfree) == 1} {
    set id $nst_datasets($file,id)
    global nst_nodes_$id 
    
    nst_free $file
  }
  
  set pos [lsearch $nst_files $file]
  set nst_files [lreplace $nst_files $pos $pos] 
}


# Produces a new color by cycling through NST_COLORS

proc nst_next_color {{this ""}} {
  global NST_COLORS
  
  set new_color [lindex $NST_COLORS 0]

  if {$this != "" && $new_color != $this} {
    return
  }

  set cdr [lrange $NST_COLORS 1 end] 
  set NST_COLORS [concat $cdr $new_color]
  
  return $new_color
}



# Removes a graph from the window

proc nst_remove_graph {graph} {
  global nst_graphs
  
  if {[llength $nst_graphs] < 2} {
    return "Can't remove only graph."
  }
  
  set graph_pos [lsearch $nst_graphs $graph]
  if {$graph_pos == -1} {
    return "Graph $graph doesn't exist."
  }
  
  pack forget $graph
  
  set nst_graphs [lreplace $nst_graphs $graph_pos $graph_pos]
  nst_possibly_rotate_ylabels
  
  nst_goto_graph [lindex $nst_graphs 0]

  nst_fix_xaxis
}


# Creates a postscript file of the entire graph window
# Gross Hack:
#	appends postscript files for each graph using an awk file
#	to comment out each showpage but the last one.

proc nst_make_ps {mode} {
  global nst_graphs NST_PS_MODE nst_colormap nst_files PRINT_COMMAND
  global GRID_PATTERN GRID_PRINT_PATTERN COLOR_LINEWIDTH
  
  busy

  set num_graphs [llength $nst_graphs]
  set index 0
  
  if {$mode == "print"} {
    set ps_file [format ".tmp%s" [pid]]
  } else {
    set ps_file $mode
  }
  
  # erase the file (-n only works in the /usr/ucb version)
  exec /usr/ucb/echo -n > $ps_file
  
  # plot them in the order on the screen
  set graphs [lsort $nst_graphs]
  set last_graph [lindex $graphs [expr [llength $graphs] - 1]]

  # put the title into the top of the first graph
  set graph [lindex $graphs 0]
  setl {xmin xmax ymin ymax} [nst_find_limits $graph]
  if {[$graph xaxis cget -logscale] != 1} {
    set x [expr ($xmax + $xmin) / 2.0]
  } else {
    set x [expr sqrt($xmax * $xmin)]
  }
  set tp 0.9
  set y [expr $tp*$ymax + (1.0-$tp)*$ymin]
  set filename [nst_last $nst_files]
  set marker [$graph marker create text -text $filename -coords "$x $y" \
		  -foreground black -fill ""]

  set height 0
  foreach win $graphs {
    incr height [winfo height $win]
  }

  # used as height since in landscape mode
  set page_width 7.5
  
  set pos 0.5
  foreach win $graphs {
    if {$NST_PS_MODE == "mono"} {
      # if mono set dashes on lines
      set i 0
      foreach element [$win element show] {
	$win element configure $element -dashes $i
	incr i 2
      }

      # set grid to be scattered points
      $win grid configure -dashes $GRID_PRINT_PATTERN

      # must reverse video on x and y axis labels
      $win configure -fg white
    } elseif {$NST_PS_MODE == "color"} {
      # color lines sometimes need to be thicker to show up on a color printer
      foreach element [$win element show] {
	$win element configure $element -linewidth $COLOR_LINEWIDTH
      }
    }

    # need to set these to black or they don't show
    $win legend configure -foreground black
    catch "$win marker configure nst_dx -foreground black"

    set gr_extent [expr $page_width * [winfo height $win]/$height]

#    set ps [$win postscript output \
		-center 0 \
		-height ${gr_extent}i \
		-width 10i \
		-pady 0.5i \
		-padx "${pos}i [expr $page_width - $pos - $gr_extent + 1.0]i" \
		-landscape true \
	        -colormode $NST_PS_MODE \
		-colormap nst_colormap \
       ]

# colormap breaks postscript !!!

    set ps [$win postscript output \
		-center 0 \
		-height ${gr_extent}i \
		-width 10i \
		-padx "${pos}i [expr $page_width - $pos - $gr_extent + 1.0]i" \
		-pady 0.5i \
		-landscape true \
	        -colormode $NST_PS_MODE \
		-decorations 0 \
	    ]

    set pos [expr $pos + $gr_extent]

    # reset
    $win legend configure -foreground white
    catch "$win marker configure nst_dx -foreground white"

    if {$NST_PS_MODE == "mono"} {
      # if mono set dashes off (solid lines)
      foreach element [$win element show] {
	$win element configure $element -dashes 0
      }

      # restore grid
      $win grid configure -dashes $GRID_PATTERN

      # restore black x and y axis labels
      # ???
    } elseif {$NST_PS_MODE == "color"} {
      # restore linewidth
      foreach element [$win element show] {
	$win element configure $element -linewidth 1
      }
    }

    incr index
    
    if {$win == $last_graph} {
      exec cat >> $ps_file << $ps
    } else {
      exec awk \
	  {($1 == "showpage") {print "%showpage"; next}; {print $0};} \
	  - >> $ps_file << $ps
    }
  }

  # clean up
  [lindex $graphs 0] marker delete $marker
  
  if {$mode == "print"} {
    puts "Sent postscript of display to default printer."
    catch {eval exec $PRINT_COMMAND $ps_file &}
  } else {
    puts "Wrote postscipt to file \"$ps_file\""
  }

  ready
}


# Creates a toplevel window with a listbox containing all the nodes
# in a particular file.

proc nst_make_node_listbox {file} {
  global nst_datasets WIN
  set id $nst_datasets($file,id)
  global nst_nodes_$id
  
  set win [format ".%s" $nst_datasets($file,menu)]
  
  if {[winfo exists $win] == 1} {
    raise $win
    return
  }
  
  busy

  set width 130

  set x [max 0 [expr [winfo x $WIN] - $width - 10]]
  set y [expr [winfo y $WIN] + 25]

  toplevel $win 
  wm geometry $win "=${width}x180+$x+$y"
  wm title $win "$file nodes"
  wm min $win 0 0
  
  frame $win.buttons -bd 0 -highlightthickness 0
  button $win.plot -text "Plot" -padx 0 -pady 0 -bd 2 -relief raised \
      -command "nst_plot_from_menu $win.nodes nst_plot $file" \
      -highlightthickness 0
  button $win.unplot -text "Unplot" -padx 0 -pady 0 -bd 2 -relief raised \
      -command "nst_plot_from_menu $win.nodes nst_unplot $file" \
      -highlightthickness 0

  # add a way to change the xaxis.
  button $win.xaxis -text " X" -padx 0 -pady 0 -bd 2 -relief raised \
      -command "nst_change_xaxis $file $win.nodes" \
      -highlightthickness 0

  button $win.quit -text "Close" -padx 0 -pady 0 -bd 2 -relief raised \
      -command "destroy $win" -highlightthickness 0

  pack $win.plot $win.unplot -in $win.buttons -side left 
  pack $win.quit $win.xaxis -in $win.buttons -side right
  pack $win.buttons -side top -fill x

  scrollbar $win.scroll -command "$win.nodes yview" -highlightthickness 0 
  pack $win.scroll -side right -fill y
  listbox $win.nodes -yscrollcommand "$win.scroll set" \
      -highlightthickness 0 -exportselection 0

  pack $win.nodes -side left -fill both -expand 1
  
  bind $win.nodes <Double-Button-1> \
      "nst_plot $file \[$win.nodes get \[$win.nodes curselection\]\]"

  # Now put the node list into it
  global nst_nodes_id
  set nst_nodes_id nst_nodes_$id

  set node_list [lsort -command nst_lsort_command [array names nst_nodes_$id]]
#  set node_list [lsort [array names nst_nodes_$id]]
  foreach node $node_list {
    $win.nodes insert end $node
  }
  ready
}


# nst_lsort_command is used by the lsort function to resort the node
# names list.  This sorting is only required since I didn't feel
# like making a list from c of the names when I read in the binary file.

proc nst_lsort_command {a b} {
  global nst_nodes_id
  global $nst_nodes_id
  
  if {[set "$nst_nodes_id\($a\)"] < [set "$nst_nodes_id\($b\)"]} {
    return 0
  }
  return 1
}


# Plots or unplots depending on input from menu.  The WHOLE purpose
# of this is because the curselection gives "" if nothing is selected.

proc nst_plot_from_menu {win command file} {
  set index [$win curselection]
  if {$index != ""} {
    $command $file [$win get $index]
  }
}


# Deletes all node menus

proc nst_lose_node_menus {} {
  global nst_files nst_datasets
  
  foreach file $nst_files {
    set win [format ".%s" $nst_datasets($file,menu)]
    if {[winfo exists $win] == 1} {
      destroy $win
    }
  }
}


# Changes the xaxis to the selected node and then Erases everything

proc nst_change_xaxis {filename win} {
  global nst_datasets nst_axis
  
  set index [$win curselection]
  if {$index == ""} {
    return
  }
  
  set new_xaxis [$win get $index]
  if {$new_xaxis == $nst_datasets($filename,xaxis)} {
    return
  }
  
  set nst_datasets($filename,xaxis) $new_xaxis
  set nst_axis(xaxis) [nst_xaxis_name $new_xaxis $filename]

  nst_erase_all
}


# returns the name to show up on the xaxis.

proc nst_xaxis_name {name filename} {

  # TIME is obvious and the default
  if {[string tolower $name] == "time"} {
    return ""
  }

  global nst_datasets nst_axis
  set id $nst_datasets($filename,id)
  global nst_nodes_$id nst_node_types_$id

  set node_type [set nst_node_types_${id}($name)]
  if {[use_first nst_axis($node_type)] == "Voltage"} {
    set name [format "V(%s)" $name]
  }

  return $name
}


# toggles graphs from log to linear

proc nst_toggle_log_linear {{axis x} {graph all}} {
  global nst_graphs

  if {$nst_graphs == ""} {
    return
  }

  if {$graph == "all"} {
    # toglle all graphs
    set graphs $nst_graphs
  } else {
    # only toggle current
    set graphs [lindex $nst_graphs 0]
  }

  set graph [lindex $graphs 0]
  set log [expr 1 - [lindex [$graph ${axis}axis configure -logscale] 4]]

  foreach graph $graphs {
    # be sure that the minimum is not negative (assume the max is positive)
    if {[lindex [$graph xaxis limits] 0] <= 0 && $log == 1 && $axis == "x"} {
      # make the minimum a small random number greater than 0
      set max [lindex [$graph xaxis limits] 1]
      $graph xaxis configure -min [min 1.0e-3 [expr $max/1.0e3]]
      $graph xaxis configure -logscale $log	
      $graph xaxis configure -min {}
    } else {
      $graph ${axis}axis configure -logscale $log	
    }
  }
}


# Tries to compute a reasonable file suffix for labels

proc compute_suffix {filename} {
  global nst_files
  
  if {[llength $nst_files] == 0} {
    # no files yet, no suffix needed for nodes
    return ""
  }
  
  # there is one file.  If it's the same, probably did a copy
  if {[llength $nst_files] == 1} {
    if {[lsearch $nst_files ${filename}*] != -1} {
      return ""
    }
  }

  set prefix [lindex [split $filename "."] 0]
  # use the prefix unless it might be ambiguous like in foo.tr0, foo.tr1
  if {[lsearch $nst_files ${prefix}.*] != -1} {
    # there are files with the same prefix
    regsub -all {\.} $filename _ filename
    return "_$filename"
  } else {
    regsub -all {\.} $prefix _ prefix
    return "_$prefix"
  }
}


# blt can only handle alphanumeric and underscore

proc bltify_node_name {name} {

  # Convert all "([]!." to underscores. 
  if {[regsub -all {[^a-zA-Z0-9_]} $name _ name] > 0} {
    # add underscores to front of modified for uniqueness
    set name _$name
  }

  if {![catch "expr 1 + $name"]} {
    # add underscores to front of pure numeric also
    set name _$name
  }

  return $name
}


proc toggle_crosshairs {} {

  global CROSSHAIRS nst_graphs

  if {$CROSSHAIRS != 0 && $CROSSHAIRS != "false"} {
    # turn off crosshairs
    set CROSSHAIRS 0

    foreach graph $nst_graphs {
      bind $graph <Leave> ""
      bind $graph <Enter> ""
      $graph crosshairs off
    }

  } else {
    # turn on crosshairs
    set CROSSHAIRS 1

    foreach graph $nst_graphs {
      Blt_Crosshairs $graph
    }
  }
}


proc doc {{type manual}} {

  global DEFAULT_BROWSER env

  set browser [use_first env(MMI_BROWSER) env(BROWSER) DEFAULT_BROWSER]

  if {$type == "manual"} {
    set file $env(MMI_TOOLS)/nst/doc/nst_manual/nst_manual.html
  } elseif {$type == "mmidoc"} {
    set file $env(MMI_TOOLS)/mmidoc/mmi.html
  }

  puts "Opening $file in $browser browser..."

  # if netscape, get fancy and try popping up file in an existing browser    
  if {$browser == "netscape"} {
    # openFile($file)" doesn't seem to work
    if {[catch "exec $browser -remote openURL($file)" msg] == 0} {
      return
    }
  }
	
  # fancy stuff didn't work, so just start up a browser on the file!
  if {[catch "exec $browser $file &" msg]} {
    # error, just give the user the ascii version
    puts "Aborting, $msg"
  }
}


proc nst_move_margin {delta} {

  global nst_graphs

  foreach graph $nst_graphs {
    $graph configure -rightmargin \
	[max 50 [expr [$graph cget -rightmargin] + $delta]]
  }
}



# Creates a little notice to amuse users

proc about_nst {} {

  global VERSION COMPILE_TIME

  set message ""
  if {[info exists COMPILE_TIME]} {
    lappend message "Version $VERSION Compiled $COMPILE_TIME"
  } else {
    lappend message "Version $VERSION"
  }

  set button [tk_dialog .about_sue "About NST" \
		  [join $message \n] \
		  "" 0 {ok}]
}


proc menu_add {args} -type user -desc {

Adds a menu item to the bottom of the given NST menu.

Usage:

        menu_add [-menu (file|view|print|derive|help)] -label <name> 
                 -command <command> [-hotkey <hotkey>] [-help <string>]
                 [-position <line>]

<command> is executed when the user clicks on this <name> menu option
or hits the optional hotkey.  The <string> help line will be displayed
in the message window when the user has the cursor over the menu
item.  If the label <name> is "separator", then a separator line
will be added to the menu.

If no menu is specified, the menu defaults to the view menu.  By
default, the new menu option will be placed at the bottom of the
specified menu.  To place it in another location, specify the <line>
position, and it will try to place it at that line number.

For example:

        menu_add -label separator
        menu_add -label foo -command "puts foo" -help "yippee!"

NOTE: don't add anything to the top of the files menu or to the derive menu.
} {

  global WIN KEYS MENU_HELP MENUS

  if {[catch [list call_by_keyword $args {{menu view} {label ""} {command ""} {hotkey ""} {help ""} {position ""}}] msg]} {
    puts "Error: $msg"
    return
  }

  if {$position != "" && [catch "expr $position"]} {
    puts "Error: Illegal menu position, must be an integer: menu_add $args"
    return
  }

  if {[lsearch "file view derive print help" $menu] == -1} {
    puts "Error: Illegal menu in line: menu_add $args"
    return
  }

  if {$label == ""} {
    puts "Error: Must provide a label to a menu in line: menu_add $args"
    return
  }

  set trimlabel [string trim $label]
  regsub -all {\.} $trimlabel "" trimlabel

  if {$trimlabel == "separator"} {
    if {$position != ""} {
      $WIN.mb.$menu.menu insert $position separator
    } else {
      $WIN.mb.$menu.menu add separator
    }
    return
  }

#  if {$command == ""} {
#    puts "Error: Must provide a command to a menu in line: menu_add $args"
#    return
#  }

  # look for a hotkey defined through the KEYS global array if not given
  set hotkey [use_first hotkey KEYS([string tolower [join $trimlabel _]])]

  if {[info exists MENUS($trimlabel)] && $MENUS($trimlabel) != $menu} {
    # move a menu item to another menu.
    set _menu $MENUS($trimlabel)
    if {![catch {$WIN.mb.$_menu.menu index $label} index]} {
      $WIN.mb.$_menu.menu delete $index
    }
  }
  set MENUS($trimlabel) $menu

  if {[catch {$WIN.mb.$menu.menu index $label} index]} {
    # new label, add
    if {$position == ""} {
      $WIN.mb.$menu.menu add command -label $label \
	  -command $command -accelerator [abbrev $hotkey]
    } else {
      $WIN.mb.$menu.menu insert $position command -label $label \
	  -command $command -accelerator [abbrev $hotkey]
    }

  } else {
    # replace existing
    $WIN.mb.$menu.menu delete $index
    if {$position == ""} {
      # replace in same position
      $WIN.mb.$menu.menu insert $index command -label $label \
	  -command $command -accelerator [abbrev $hotkey]
    } else {
      $WIN.mb.$menu.menu insert $position command -label $label \
	  -command $command -accelerator [abbrev $hotkey]
    }
  }

  # NOTE: Doesn't delete hotkeys
  # add hotkey
  foreach h [split $hotkey ,] {
    bind $WIN "<$h>" $command
  }

  # add help entry
  if {$help != ""} {
    set MENU_HELP([join $trimlabel _]) $help
    set MENU_HELP($hotkey) $help
  }
}

# abbreviates keystrings so they are nicer.

proc abbrev {list} {

  set control "Ctrl-"

  set return ""
  foreach string [split $list ,] {

    if {[lsearch -exact "space delete" [string tolower $string]] != -1} {
      # make delete and space upper case
      lappend return [string toupper $string]
      continue
    }

    if {[string length $string] == 1 && [string tolower $string] != $string} {
      # turn G into Shift-g, etc.
      set string "Shift-[string tolower $string]"
    }

    if {[string range $string 0 7] == "Control-"} {
      lappend return "$control[string range $string 8 end]"
    } else {
      lappend return $string
    }
  }

  return [join $return ,]
}



# tk8.0 specific
# taken out of menu.tcl in the tk library and modified to show help 

proc tkGenerateMenuSelect {menu} {

  global tkPriv LAST_MENU_ITEM

  if {([string compare $tkPriv(activeMenu) $menu] == 0) \
	  && ([string compare $tkPriv(activeItem) [$menu index active]] == 0)} {
    return
  }

  set index [$menu index active]

  if {$index != "none" && [$menu type $index] != "tearoff"} {
    set name [$menu entrycget $index -label]
    if {[use_first LAST_MENU_ITEM] != $name} {
      set LAST_MENU_ITEM $name
      msg_window $name
    }
  }

  set tkPriv(activeMenu) $menu
  set tkPriv(activeItem) $index
  event generate $menu <<MenuSelect>>
}


# tkMenuLeave --
# This procedure is invoked to handle Leave events for a menu.  It
# deactivates everything unless the active element is a cascade element
# and the mouse is now over the submenu.
#
# Arguments:
# menu -		The menu window.
# rootx, rooty -	Root coordinates of mouse.
# state -		Modifier state.

proc tkMenuLeave {menu rootx rooty state} {

    global tkPriv LAST_MENU_ITEM

    # added for nst
    msg_window __DEFAULT__
    set LAST_MENU_ITEM ""

    set tkPriv(window) {}
    if {[$menu index active] == "none"} {
	return
    }
    if {([$menu type active] == "cascade")
	    && ([winfo containing $rootx $rooty]
	    == [$menu entrycget active -menu])} {
	return
    }
    $menu activate none
    tkGenerateMenuSelect $menu
}


proc msg_window {name {type ""}} {

  global WIN WIN_DATA MENU_HELP

  if {$type == "default"} {
    # set the default
    set WIN_DATA($WIN,default) $name
    set WIN_DATA($WIN,display_msg) $name

  } elseif {$name == "__DEFAULT__"} {
    # use the default
    set WIN_DATA($WIN,display_msg) [use_first WIN_DATA($WIN,default)]

  } elseif {$type == "message"} {
    set WIN_DATA($WIN,display_msg) $name

  } else {
    # replace spaces with underscores and clean up
    regsub -all {\.} [string trim $name] "" name
    set name [join $name _]

    if {[string first "Print_to_File" $name] == 0} {
      # special case
      set name "Print_to_File"
    }

    # lookup
    set WIN_DATA($WIN,display_msg) \
	[use_first MENU_HELP($name) WIN_DATA($WIN,default)]
  }
}


# popup a menu for user to modify signal

proc nst_modify_signal {graph name x y} {

  global NST_ORIG_COLORS nst_coord

  set w .signal_popup

  catch {destroy $w}

  menu $w -tearoff false

  # special case for derived
  if {$nst_coord(filename) == "__DERIVED__"} {

    $w add command -label "unplot" \
	-command "nst_toggle_derive $name ; nst_activate_node $graph {}"

    $w add separator

    foreach color $NST_ORIG_COLORS {
      $w add command -label $color \
	  -command "$graph element configure $name -color $color ; nst_activate_node $graph {}"
    }

  } else {

    regsub -all {\[|\]} $name {\\&} name

    $w add command -label "unplot" \
	-command "nst_unplot $nst_coord(filename) $name ; nst_activate_node $graph {}"

    $w add separator

    foreach color $NST_ORIG_COLORS {
      $w add command -label $color \
	  -command "nst_plot $nst_coord(filename) $name {} {} $color ; nst_activate_node $graph {}"

    }
  }

  # post it
  tk_popup $w [expr [winfo rootx $graph] + $x] \
      [expr [winfo rooty $graph] + $y + 10]

}


set nst_text_index 1

proc nst_annotate_text {} {

  global NST_ORIG_COLORS nst_text_index nst_graphs

  # hack for now
  global cur_c
  set cur_c .nst

  set graph [lindex $nst_graphs 0]

  set title "NST Annotate Text"
  set message "Enter Text info:    "

  set prop_list ""

  set text ""
  lappend prop_list [list "Text" text]

  set color [lindex $NST_ORIG_COLORS 0]
  lappend prop_list [list "Color" color -popup $NST_ORIG_COLORS]

  set fonts "*-Helvetica-Bold-R-Normal-*-120-* *-Helvetica-Bold-R-Normal-*-140-* *-Helvetica-Bold-R-Normal-*-180-*"
  set font [lindex $fonts 0]
  lappend prop_list [list "Font" font -popup $fonts]

  set rotate 0
  lappend prop_list \
      [list "Rotation angle (degrees)" rotate -number 0 360 -incr 45]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  set xmin [$graph xaxis cget -min]
  set xmax [$graph xaxis cget -max]
  set ymin [$graph yaxis cget -min]
  set ymax [$graph yaxis cget -max]

  if {$xmin == "" || $xmax == "" || $ymin == "" || $ymax == ""} {
    # zoomed all the way out. 
    setl {xmin xmax ymin ymax} [nst_find_limits $graph]
  }

  set x [expr ($xmax + $xmin) / 2.0]
  set y [expr ($ymax + $ymin) / 2.0]

  set name "nst_text[incr nst_text_index]"

  $graph marker create text -coords "$x $y" \
      -text $text -name $name \
      -bindtags $name -font $font \
      -foreground $color -fill "" -rotate $rotate

  $graph marker bind $name <Enter> "msg_window \"Button-2 moves text, Shift-Button-2 deletes text.\" message"
  $graph marker bind $name <Leave> "msg_window __DEFAULT__"

  $graph marker bind $name <ButtonPress-2> "nst_move_marker %W $name %x %y init"
  $graph marker bind $name <Button2-Motion> "nst_move_marker %W $name %x %y"
  $graph marker bind $name <ButtonRelease-2> \
      "catch \"unset _NST_TEXT_MARKER_(motion)\""

  $graph marker bind $name <Shift-ButtonPress-2> \
      "nst_move_marker %W $name %x %y delete_setup"

  $graph marker bind $name <Shift-ButtonRelease-2> \
      "nst_move_marker %W $name %x %y delete"
}


proc nst_move_marker {graph name x y {mode ""}} {

  global _NST_TEXT_MARKER_ nst_graphs

  if {![$graph marker exists $name]} {
    return
  }

  if {$mode == "delete"} {
    catch "$graph marker delete $name"

    catch "unset _NST_TEXT_MARKER_(motion)"

    # clear message
    msg_window __DEFAULT__

    return
  }

  if {$mode == "delete_setup"} {
    foreach _graph $nst_graphs {
      bind $_graph <Button2-Motion> ""
      bind $_graph <ButtonRelease-2> ""
    }

    set _NST_TEXT_MARKER_(motion) 1

    return
  }

  setl {x y} [$graph invtransform $x $y]

  if {$mode != "init"} {
    set dx [expr $x - $_NST_TEXT_MARKER_(x)]
    set dy [expr $y - $_NST_TEXT_MARKER_(y)]
    
    setl {xo yo} [$graph marker cget $name -coords]

    $graph marker configure $name -coords "[expr $xo + $dx] [expr $yo + $dy]"
  } else {
    foreach _graph $nst_graphs {
      bind $_graph <Button2-Motion> ""
      bind $_graph <ButtonRelease-2> ""
    }
  }
    
  set _NST_TEXT_MARKER_(x) $x
  set _NST_TEXT_MARKER_(y) $y

  set _NST_TEXT_MARKER_(motion) 1
}


proc nst_clear_annotations {{graph ""}} {

  global nst_graphs

  if {$graph != ""} {
    foreach marker [$graph marker names] {
      $graph marker delete $marker
    }

  } else {
    foreach graph $nst_graphs {
      foreach marker [$graph marker names] {
	$graph marker delete $marker
      }
    }
  }
}