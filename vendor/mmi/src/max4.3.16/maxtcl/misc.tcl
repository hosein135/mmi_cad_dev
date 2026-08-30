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

set RCSVERSION(misc.tcl) { $Revision: 1.101 $ }


init_global OPTIONS(use_popups) \
    -type binary \
    -default 1 \
    -desc {If 1, button-3 is for popup menus. If 0, button-3 selects layer. }

init_global OPTIONS(auto_raise_window) \
    -type binary \
    -default 0 \
    -desc {If 1, menu windows are raised if you mouse click when they are not visible. }

init_global OPTIONS(warp_cursor) \
    -type binary \
    -default 1 \
    -desc {If 1, cursor warps to menu when menu is opened.}

init_global OPTIONS(editor) \
    -type string \
    -default vi \
    -desc {Default editor for cell documentation.}

init_global OPTIONS(browser) \
    -type string \
    -default netscape \
    -desc {Default html editor for cell documentation.}


init_global MAX_PROBE_DISPLAY -type STRING \
    -desc {Display on which max will attempt to bring up sue when you cross-probe. \
    If variable is unset, it uses the environment variable MAX_PROBE_DISPLAY. \
    If that is unset, uses the current X display from the DISPLAY environment variable.}

init_global OPTIONS(doc_text_suffix) -default ".doc" -desc {
  default filename suffix for cell documentation text files
} -type STRING

init_global OPTIONS(doc_html_suffix) -default ".html" -desc {
  default filename suffix for cell documentation html files
} -type STRING

init_global GDS_READ_PARTIAL \
    -type binary \
    -default 0 \
    -desc {If 0, always import entire gds file.  If 1, queries for cell to load }

# already set to be global.  Make default true.
set GDS_READ_NO_DRC 1


proc quit {} -desc {
    synonym for exit.
} {
    exit
}

proc redisplay_hook {beginning} -desc {
    called at beginning (beginning=1) and end of main layout widget redisplays
} {
    cursor_redisplay $beginning

    if { $beginning == 1 } {
	#pal_redisplay_hook
	drc_redisplay_hook
    }
}

proc delete {} -desc {
  delete the selected stuff
} {
    global MAX_NEW_SELECT
    if {[use_first MAX_NEW_SELECT] == 1} {
	db_group selected
    }
    :delete
    db_group 0
}


proc measure {{x ""} {y ""}} -desc {
  places the box in the largest area unoccupied by visible layers
} {
    set coords [measure_dist]
    if { $coords != "" } {
	eval layt_box exact $coords
    }
}

proc measure_dist {{x ""} {y ""} {any 0}} -desc {
  returns coords of the box in the largest area unoccupied by visible layers
} -doc {
  if any is 1, also find edges of paint under cursor.
} {

  if {$x == "" || $y == ""} {
    setl {x y} [layt_point exact]
  }

  # gets the visible bounding box
  setl {x1 y1 x2 y2} [dbt_frame]


  # is point outside cell bbox, place on bbox at nearest (probably not needed)
  if {$x < $x1} {
    set x $x1
  }
  if {$x > $x2} {
    set x $x2
  }
  if {$y < $y1} {
    set y $y1
  }
  if {$y > $y2} {
    set y $y2
  }

  set layers [dbt_selectable_layers]
  if { $layers == "" } {
    warning "no layers in palette are selectable"
    return
  }


  set res [res]

  setl dxplus [expr $x2 - $x]
  setl dxminus [expr $x - $x1]
  setl dyplus [expr $y2 - $y]
  setl dyminus [expr $y - $y1]

  set limit 4000

  # Look at a little strip in the x and y directions.
  set y_paintballs [db_search_l paint -any_cell -limit $limit \
      -area [expr $x-$res] $y1 [expr $x+$res] $y2 $layers]

  set x_paintballs [db_search_l paint -any_cell -limit $limit \
      -area $x1 [expr $y-$res] $x2 [expr $y+$res] $layers]

  # Now look at polygons: just use the bbox for non-wire-paths.
  set y_polys [db_search_l polygons -any_cell -limit $limit \
      -area [expr $x-$res] $y1 [expr $x+$res] $y2 $layers]

  set x_polys [db_search_l polygons -any_cell -limit $limit \
      -area $x1 [expr $y-$res] $x2 [expr $y+$res] $layers]

  # This happens if you are zoomed way out with lots of expanded
  # instances.  There is no reason to be using the measure code
  # if you are zoomed out like that.
  # db_next_edge to find.
  if {[llength $x_paintballs] + [llength $y_paintballs] + \
      [llength $x_polys] + [llength $y_polys] > $limit - 2} {
    warning "zoomed out too far to use measure function"
    return
  }

  foreach paint $x_paintballs {
    struct max_paint p $paint
    if {${p.x1} > $x} {
	set dxplus [min $dxplus [expr ${p.x1}-$x]]
    } elseif { $any } {
	set dxminus [min $dxminus [expr $x-${p.x1}]]
    }
    if {${p.x2} < $x} {
	set dxminus [min $dxminus [expr $x-${p.x2}]]	
    } elseif { $any } {
	set dxplus [min $dxplus [expr ${p.x2}-$x]]
    }
  }

  foreach paint $y_paintballs {
    struct max_paint p $paint

    # now find the closest edge
    if {${p.y1} > $y} {
	set dyplus [min $dyplus [expr ${p.y1}-$y]]
    } elseif { $any } {
	set dyminus [min $dyminus [expr $y-${p.y1}]]
    }
    if {${p.y2} < $y} {
	set dyminus [min $dyminus [expr $y-${p.y2}]]	
    } elseif { $any } {
	set dyplus [min $dyplus [expr ${p.y2}-$y]]
    }
  }

  foreach poly $x_polys {
    # MAX_STRUCT(max_polygon) "layer bbox coords attrs"
    struct max_polygon p $poly
    setl {px1 py1 px2 py2} ${p.bbox}

    if {$px1 > $x} {
	set dxplus [min $dxplus [expr $px1-$x]]
    } elseif { $any } {
	set dxminus [min $dxminus [expr $x-$px1]]
    }
    if {$px2 < $x} {
	set dxminus [min $dxminus [expr $x-$px2]]	
    } elseif { $any } {
	set dxplus [min $dxplus [expr $px2-$x]]
    }
  }

  foreach poly $y_polys {
    struct max_polygon p $poly
    setl {px1 py1 px2 py2} ${p.bbox}

    if {$py1 > $y} {
	set dyplus [min $dyplus [expr $py1-$y]]
    } elseif { $any } {
	set dyminus [min $dyminus [expr $y-$py1]]
    }
    if {$py2 < $y} {
	set dyminus [min $dyminus [expr $y-$py2]]	
    } elseif { $any } {
	set dyplus [min $dyplus [expr $py2-$y]]
    }
  }

    
  # Now what about wire paths.  What to do?
  # For now, ignore em.
  # TODO: Should find horizontal and vertical distance from point
  # to nearest edge of wire.

  return [list [expr $x - $dxminus] [expr $y - $dyminus] \
      [expr $x + $dxplus] [expr $y + $dyplus]]
}


# This version uses the measure algorithm.
proc closest_edge {x y {dirs nsew}} -desc {
    return a point on the closest edge in horiz or vert direction, or "".
} -doc {
  dirs is a string containing letters for directions,eg: nsew
} {
    setl {nx1 ny1 nx2 ny2} [measure_dist $x $y 1]
    if { $nx1 == "" } { return "" }
    set closest_dist 1e20
    set closest [list $x $y]
    if { [string first w $dirs] >= 0 && abs($nx1 - $x) < $closest_dist } {
	set closest [list $nx1 $y]
	set closest_dist [expr abs($nx1 - $x)]
    }
    if { [string first e $dirs] >= 0 && abs($nx2 - $x) < $closest_dist } {
	set closest [list $nx2 $y]
	set closest_dist [expr abs($nx2 - $x)]
    }
    if { [string first s $dirs] >= 0 && abs($ny1 - $y) < $closest_dist } {
	set closest [list $x $ny1]
	set closest_dist [expr abs($ny1 - $y)]
    }
    if { [string first n $dirs] >= 0 && abs($ny2 - $y) < $closest_dist } {
	set closest [list $x $ny2]
    }
    return $closest
}

proc gds_write {{-overwrite} {file ""}} -desc {
  write gds of current cell to cell's directory
} -doc {
  If -overwrite and the file exists, it will be over-written
  without asking. 
  
  NOTE:  A number of global variables beginning 'GDS_WRITE_' modify the
  behavior of gds_write.  Consult the 'variables' documentation for details.
} {
    global CELL

    set cell [lay_rootcell]

    if { $file == "" } {
      # find the directory
      set name [file rootname [lindex [cell_info $cell] 1]]
      if {$name == ""} {
	set name $cell
      }
      set file $name$CELL(gds_suffix)
    }
    
    if {[file exists $file] && ! $overwrite} {
      # query user before stomping on existing gds
      set message "The file \"$file\" already exists.  Overwrite?"
      set choice [tk_dialog .dialog "Export GDS" $message {} 0 \
		Yes Cancel]
      if { $choice != 0 } { 
	# user hit the cancel button
	return
      }
    }

    puts "Writing GDSII for cell $cell and descendents to $file ..."
    
    set code [msg_catch ":calma write $file" result warnings]

    #demote any warnings to info messages (sent to controling terminal)
    if { $warnings != "" } {
      msg $warnings
    }

    # report errors 
    if { $code != 0 } {
	set errors $result
	if { $errors == {} } {
	    set errors "Error writing GDSII for $cell and descendents\n"
	}
	error $errors 
    }

    puts "Done."
}

proc _new_gds_export_setup {} -desc {
  popup menu of GDSII export options
} {
  global max_win  
  global GDS_WRITE_SCALE_FACTOR
  global GDS_WRITE_RESTRICT_CHARACTER_SET 
  global GDS_WRITE_RESTRICT_CELL_NAME_LENGTH
  global GDS_WRITE_MIXED_CASE_LABELS
  global GDS_WRITE_LABELS
  global GDS_WRITE_ARRAYS
  global GDS_WRITE_REPORT_ROUNDING_ERRORS 
  global GDS_WRITE_REPORT_EXTENDED_CHARACTER_SET 
  global GDS_WRITE_REPORT_EXTENDED_CELL_NAME_LENGTH 

  # setup popup window location 
  set win $max_win.layout
  set winy [expr [winfo rooty $win] + 50]
  set winx [expr [winfo rootx $win] + 50]

  # setup prop menu       
  set title "GDSII Export Setup"
  set message "GDSII Export Options:" 
  set prop_list [list \
	  "output_style [cif_ostyle] choice \"[cif_ostyle -list]\"\
	  -help {layer map etc. (defined in tech file)}"\
	  "scale_factor $GDS_WRITE_SCALE_FACTOR number 0 -validate -separator\
	  -help {scale size by this factor (normally 1.0)}"\
	  "STRICT_GDSII: {} label"\
	  "restrict_character_set $GDS_WRITE_RESTRICT_CHARACTER_SET binary\
          -help {map strings to GDSII character set}"\
	  "restrict_cell_name_length $GDS_WRITE_RESTRICT_CELL_NAME_LENGTH binary -separator\
          -help {map cell names to not exceed GDSII 32 character maximum}"\
	  "SPECIAL_RESTRICTIONS: {} label"\
	  "no_lowercase [expr !$GDS_WRITE_MIXED_CASE_LABELS] binary\
	  -help {map strings to all upper case (ANCIENT COMPATIBILITY MODE)}"\
	  "no_labels [expr !$GDS_WRITE_LABELS] binary\
	  -help {Don't output labels}"\
	  "no_arrays [expr !$GDS_WRITE_ARRAYS] binary -separator\
	  -help {output arrays flat (as set of simple instances)}"\
	  "WARNINGS: {} label"\
	  "report_rounding_errors $GDS_WRITE_REPORT_ROUNDING_ERRORS binary\
	  -help {warn on coordinates that didn't export exactly}"\
	  "report_extended_character_set $GDS_WRITE_REPORT_EXTENDED_CHARACTER_SET binary\
	  -help {warn on characters outside GDSII character set }"\
	  "report_extended_cell_name_length $GDS_WRITE_REPORT_EXTENDED_CELL_NAME_LENGTH binary\
	  -help {warn on cellnames that exceed GDSII limit}"\
	  ]

  # popup menu
  set new_prop_list [prop_menu $winx $winy $message $title $prop_list]

  if {$new_prop_list == "" || $new_prop_list == $prop_list} {
    # user hit cancel or didn't change anything
    return
  }

  cif_ostyle [get_assoc output_style $new_prop_list]

  set GDS_WRITE_SCALE_FACTOR \
	  [get_assoc scale_factor $new_prop_list]
  if { $GDS_WRITE_SCALE_FACTOR == 0 } {
      warning "GDS_WRITE_SCALE_FACTOR must be positive, resetting to 1.0\n"
      set GDS_WRITE_SCALE_FACTOR 1.0
  }

  set GDS_WRITE_RESTRICT_CHARACTER_SET \
	  [get_assoc restrict_character_set $new_prop_list]
  set GDS_WRITE_RESTRICT_CELL_NAME_LENGTH \
	  [get_assoc restrict_cell_name_length $new_prop_list]

  set GDS_WRITE_MIXED_CASE_LABELS \
	  [expr ![get_assoc no_lowercase $new_prop_list]]

  set GDS_WRITE_LABELS \
	  [expr ![get_assoc no_labels $new_prop_list]]

  set GDS_WRITE_ARRAYS \
	  [expr ![get_assoc no_arrays $new_prop_list]]

  set GDS_WRITE_REPORT_ROUNDING_ERRORS \
	  [get_assoc report_rounding_errors $new_prop_list]
  set GDS_WRITE_REPORT_EXTENDED_CHARACTER_SET \
	  [get_assoc report_extended_character_set $new_prop_list]
  set GDS_WRITE_REPORT_EXTENDED_CELL_NAME_LENGTH \
	  [get_assoc report_extended_cell_name_length $new_prop_list]
}


# Partial.  Mha's version is above but not fully implemented yet
# so not used yet.

proc gds_export_setup {} -desc {
  popup menu of GDSII export options
} {

  global GDS_WRITE_PROCESS_INTERACTIONS GDS_WRITE_FLATTEN_GCELLS

  # setup prop menu       
  set title "GDSII Export Setup"
  set message "GDSII Export Options:" 

  set prop_list ""

  set cif_ostyle [cif_ostyle]
  lappend prop_list [list output_style cif_ostyle choice [cif_ostyle -list]]

  lappend prop_list [list "Process hierarchical interactions" \
			 GDS_WRITE_PROCESS_INTERACTIONS binary \
			 -help "Mainly for gap filling between cells.  Note: slows down GDS exporting by >100x."]

  lappend prop_list [list "Flatten gcells" \
			 GDS_WRITE_FLATTEN_GCELLS binary \
			 -help "Gcells are written out as if you first flattened them."]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return
  }

  cif_ostyle $cif_ostyle
}


# Not fully implemented yet

proc gds_import_setup {} -desc {
  popup menu of GDSII import options
} {
  global GDS_READ_SCALE_FACTOR
  global GDS_READ_PARTIAL
  global GDS_READ_SNAP_TO
  global GDS_READ_UNMAPPED_LAYERS
  global GDS_READ_CELLNAME_TO_LOWER
  global GDS_READ_CELLNAME_TO_UPPER
  global GDS_READ_NO_DRC
  global GDS_READ_REPORT_ROUNDING_ERRORS
  global GDS_READ_REPORT_UNMAPPED_LAYERS    
  global GDS_READ_REPORT_DUPLICATE_INSTANCES

  if { [use_first GDS_READ_CELLNAME_TO_LOWER] == 1 } {
    set convert_case "lower"
  } elseif { [use_first GDS_READ_CELLNAME_TO_UPPER] == 1 } {
    set convert_case "upper"
  } else {
    set convert_case "no"
  }

  # setup prop menu       
  set title "GDSII Import Setup"
  set message "GDSII Import Options:" 
  set prop_list ""

  set istyle [cif_istyle]
  lappend prop_list [list \
    "input style" istyle -choice [cif_istyle -list]\
    -help {layer map etc. (defined in tech file)}]

  lappend prop_list [list \
    "scale factor" GDS_READ_SCALE_FACTOR -number 0 -validate -separator \
    -help {scale size by this factor (normally 1.0)}]

  lappend prop_list [list \
    "read only specified cells" GDS_READ_PARTIAL -binary \
    -help {query the user for the cell name to read instead\
	   of reading the entire gds file}]

  lappend prop_list [list \
    "set to drc clean" GDS_READ_NO_DRC -binary \
    -help {imported cells are considered DRC clean and not checked for errors. \
	   Subsequent changes to them will be checked for DRC errors.}]

  if { $GDS_READ_SNAP_TO == 0 } {
    # Max inits it to 0, we will re-init it to that mask grid from tech file.
    set GDS_READ_SNAP_TO [res -mask]
  }
  lappend prop_list [list \
    "snap to grid:" GDS_READ_SNAP_TO -number 0 -validate -incr [res -mask] \
    -help {round all numbers to this design grid.  If 0, no rounding occurs.}]

  #8/00: mha says GDS_READ_UNMAPPED_LAYERS not yet implemented
  #lappend prop_list [list \
    "import unmapped layers" GDS_READ_UNMAPPED_LAYERS -binary \
    -help {import layers even if not defined in input style}]

  lappend prop_list [list \
    "convert cellname case" convert_case -choice {no upper lower} -separator\
    -help {convert case of cell names to upper or lower case}]

  lappend prop_list [list WARNINGS: {} -label]

  lappend prop_list [list \
    "report rounding errors" GDS_READ_REPORT_ROUNDING_ERRORS -binary \
    -help {warn on coordinates that didn't import exactly}]

  lappend prop_list [list \
    "report unmapped layers" GDS_READ_REPORT_UNMAPPED_LAYERS -binary \
    -help {warn on undefined layers in input} ]

  lappend prop_list [list \
    "report duplicate instances" GDS_READ_REPORT_DUPLICATE_INSTANCES -binary \
    -help {warn on duplicate identical cell instances} ]

  # popup it up  (isnt this comment redundant? (pat))
  if {! [prop_menu2 -message $message -title $title $prop_list] } {
    # user hit cancel
    return
  }

  cif_istyle $istyle

  if { $GDS_READ_SCALE_FACTOR == 0 } {
      warning "GDS_READ_SCALE_FACTOR must be positive, resetting to 1.0\n"
      set GDS_READ_SCALE_FACTOR 1.0
  }

  switch $convert_case {
  "no" {
      set GDS_READ_CELLNAME_TO_LOWER 0
      set GDS_READ_CELLNAME_TO_UPPER 0
    }
  "upper" {
      set GDS_READ_CELLNAME_TO_LOWER 0
      set GDS_READ_CELLNAME_TO_UPPER 1
    }
  "lower" {
      set GDS_READ_CELLNAME_TO_LOWER 1
      set GDS_READ_CELLNAME_TO_UPPER 0
    }
  }
}

proc browser_open {file} -desc {
    Display an html file using the browser defined by the
    MMI_BROWSER or BROWSER environment variable.
} -doc {
    The file name must not contain tcl special chars: $ "" {}
} {
    global OPTIONS env

    set browser [use_first OPTIONS(browser) env(MMI_BROWSER) env(BROWSER)]

    msg "Opening $file in $browser browser ...\n"

    # if netscape, get fancy and try popping up file in an existing browser    
    if { 
	$browser == "netscape" && 
	[catch "exec $browser -remote openURL($file)" msg] == 0 
    } { return }
	
    # fancy stuff didn't work, so just start up a browser on the file!
    # If $file or $browser has tcl special chars, they might be evaluated!
    eval exec $browser $file &
}

set SOURCE(last) "misc"
proc source_max_tcl {} -desc {
    prompt user for tcl filename, then source from maxtcl directories in system path
} {
  global max_win SOURCE

  # window pos    
  set win $max_win.layout
  set winy [expr [winfo rooty $win] + 50]
  set winx [expr [winfo rootx $win] + 50]

  set title "Max tcl file to source"
  set message "Enter filename:" 
  set prop_list [list [list file $SOURCE(last)]]

  # prompt user for file name
  set new_prop_list [prop_menu $winx $winy $message $title $prop_list]

  if {$new_prop_list == ""} {
    # empty list means the user hit cancel
    return
  }

  set SOURCE(last) [get_assoc file $new_prop_list]
  max_tcl_source [file rootname $SOURCE(last)].tcl
}
    
proc max_auto_load {dir} -desc {
  load a library (i.e. directory) of cells automatically (usually on start up)
} {

  global _LIST_BOX_ max_win
	
  # remove final / if there is one
  set dir [string trimright $dir /]

  set cell [lay_rootcell]

  cell_load_files [lsort -decreasing [glob -nocomplain $dir/*.max]]

  cell_load $cell

  # setup the bottom listbox to point to this
  _list_box_fill [lindex $_LIST_BOX_($max_win) 0] $dir
}


proc reload {args} {

  global env MAX_TCL_DIR
  set dir [use_first MAX_TCL_DIR '~/mmi_private/max/maxtcl]

  set sharedtcl [use_first env(MMI_UTILS)]/sharedtcl

  foreach file $args {
    set found ""
    foreach trydir [list $dir $dir/sharedtcl $sharedtcl] {
      if {[file readable $trydir/$file]} {
	set found $trydir/$file
	break
      } elseif {[file readable $trydir/$file.tcl]} {
	set found $trydir/$file.tcl
	break
      }
    }

    if {$found == ""} {
      puts "error: file $file not found"
    } else {
      puts "Sourcing $found"
      # need to source this file in the top level context
      uplevel #0 "source $found"
    }
  }
}


# Dont use PROBE_DISPLAY, which is used by sue, because you might want
# max and sue on different displays.
proc _misc_get_probe_display {} {
  global env MAX_PROBE_DISPLAY
  set probe [use_first MAX_PROBE_DISPLAY env(MAX_PROBE_DISPLAY) env(DISPLAY) ':0]

  # Remove leading "-display", if any.
  if {[string range $probe 0 7] == "-display"} {
    set probe [string range $probe 8 end]
  }
  set probe [string trim $probe]

  if {$probe == "other"} {
    # deals with dots in the computer name, e.g.: mmi21.foo.com:0.1
    regexp {^(.*):(.*)$} [winfo screen .] junk display screen
    set parts [split $screen .]
    return " $display:[lindex $parts 0].[expr 1 - [lindex $parts 1]]"
  }

  return $probe
}

proc from_sue_cross_probe_init {sue_win type} -desc {
  Called from sue to init cross probe.
} {
  global global SUE_DATA SUE_CROSS_PROBE_ID
  puts "cross_probe_init $sue_win $type"
  # Sue is telling us its window id.
  set SUE_CROSS_PROBE_ID $sue_win
  set SUE_DATA(type) $type
  # TODO: Should init the correspondence file, if using gemini.
}

proc sue_cross_probe_init {{lvs_tool ""} {sue_win ""}} -desc {
  Setup cross probing to SUE from the current layout
} {
  global CELL FPLAN SUE_DATA SUE_CROSS_PROBE_ID

  # For release, if fplan is not there, skip all the new stuff,
  # because the necessary support is not in the release version of sue.
  if {[use_first FPLAN(exists) '0] == 0} {
    set lvs_tool gemini
  }

  if {$lvs_tool == ""} {
    set prop_list ""
    if {[use_first FPLAN(exists)] == 1} {
      use_init SUE_DATA(type) "by_name"
    } else {
      use_init SUE_DATA(type) "gemini"
    }
    lappend prop_list [list "Netlist Type:" SUE_DATA(type) \
	-radio {"Correspondence by Name" "LVS using gemini"} -values {by_name gemini}]
    if {![prop_menu2 -title "Cross Probe Type" $prop_list]} {
      return
    }
  } else {
    set SUE_DATA(type) $lvs_tool
  }

  # If sue_win was specified, we were called from inside sue.
  if {$sue_win == ""} {
    set SUE_CROSS_PROBE_ID ""
    set sue_win [misc_check_sue -start]
    if {$sue_win == "*CANCEL*"} {
      # User cancelled prop_menu in misc_check_sue.  Give up quietly.
      return
    }
    set SUE_CROSS_PROBE_ID $sue_win
    if {$sue_win == ""} {
      max_error "sue_cross_probe_init: Aborting, can't bring up SUE.  Check SUE setup or if SUE comes up, just rerun SUE Cross Probe Init."
      return 0
    }
    # sue exists, make sure correct cell is loaded
    if {[lay_editcell] != "$CELL(UNNAMED)"} {
      send $sue_win api_goto_cell [lay_editcell]
    }
  }

  if {$SUE_DATA(type) == "by_name"} {
    # Dont need to run LVS.
    # Send sue our window name and the cross probe type.
    # The [list] is needed because winfo name may contain a space.
    send $sue_win from_max_cross_probe_init [list [winfo name .]] by_name
    return
  } else {
    set lvs_tool "gemini"
  }

  # this means that sue must be able to find this cell
  set cell [lay_rootcell]

  if {$lvs_tool != "gemini"} {
    max_error "sue_cross_probe_init: Aborting, don't know how to use lvs tool: $lvs_tool.\n"
    return
  } elseif {![executable_exists gemini]} {
    max_error "sue_cross_probe_init: Aborting, can find gemini executable.\n"
    return
  } elseif { $cell == "$CELL(UNNAMED)" } {
    max_error "sue_cross_probe_init: Aborting, must rename root cell first"
    return
  }

  # make sure SUE's sim netlist is up-to-date
  # The from_max_cross_probe_init does not exist in the release version of sue!
  if {[send $sue_win {info commands from_max_cross_probe_init}] == "from_max_cross_probe_init"} {
    set sim_file [send $sue_win from_max_cross_probe_init [list [winfo name .]] gemini]
  } else {
    set sim_file [send $sue_win cross_probe_setup]
  }

  # gemini mode.  First run gemini on sim netlist vs. back annotate
  # netlist to find net name equivalences.

  # run lvs on cell
  puts "Running lvs on sue cell to get node correspondance..."
  lvs_it_max

  puts "\nInitializing SUE cross probe..."

  # Try to find the back annotation file.
  set dir [file dirname [lindex [cell_info [lay_rootcell]] 1]]
  if {$dir == ""} {
    set dir [pwd]
  }

  if {[file readable $dir/${cell}_lay.sim] && \
	  [file readable $dir/$cell.ext]} {
    set back_file "$dir/${cell}_lay.sim"
    set ext_file "$dir/$cell.ext"

  } else {
    # can't find a back annotation file
    max_error "sue_cross_probe_init: Aborting, Can't find/read max files $dir/${cell}_lay.sim and $dir/${cell}_lay.ext.\n"
    return
  }

  # now run gemini and write name equivalence file
  puts "Running gemini to determine node equivalents ..."
  set tmp_file tmp[pid]
  catch "exec gemini -c -D $tmp_file $back_file $sim_file"

  # deselect all
  sel_clear
  send $sue_win select_id {{}}

  # set up node correpondences
  set matches [_create_cross_probe_correspondence $tmp_file]

  # set up sue's cross probe corresponence so we don't have to run it there
  send $sue_win create_cross_probe_correspondence $tmp_file

  # now delete the tmp file
  catch {exec rm -f $tmp_file}

  # now show matching wires in max
  sel_clear
  foreach net $matches {
    if {[info exists SUE_DATA(equiv,$net)]} {
      _cross_probe_net $net "no_zoom quiet more"
    }
  }

  puts "Done."
}


proc _create_cross_probe_correspondence {file} -desc {
  setup cross probing correspondence data
} {
  global SUE_DATA

  set matches ""
  catch {unset SUE_DATA}
  set SUE_DATA(type) gemini

  # create an equivalence array
  if {[catch "open $file r" tmp_id] != 1} {
    # good, file exists
    while {[gets $tmp_id line] >= 0} {
      setl {op max_name sue_name} $line
      if {$op == "="} {
	set SUE_DATA(equiv,$max_name) $sue_name
	set SUE_DATA(equivr,$sue_name) $max_name
	lappend matches $max_name
      }
    }
    # close the file
    close $tmp_id
  }

  # save all the labels for later use in probing
  sel_labels
  foreach label [sel_what_l labels] {
    setl {layer x1 y1 x2 y2 dir name} $label
    lappend SUE_DATA(label,$name) "$x1 $y1 $layer"
    set SUE_DATA([list $layer $x1 $y1]) $name
  }

  # Read in .ext file to figure out node locations in the layout
  # needed for nets with no non-hidden labels
  setl {dir file} [split_file_name [lindex [db_cells [lay_editcell]] 2]]
  set ext_file $dir/$file.ext
  set tmp_id [open $ext_file r]

  # get multiplier.  Note: ext file in centimicrons.
  set mult 0.01

  while {[gets $tmp_id line] >= 0} {
    if {[string tolower [lindex $line 0]] == "node"} {
      setl {bogus name tmp1 tmp2 x y layer} $line
      if {![info exists SUE_DATA(label,$name)]} {
	# this gives us the location from the net
	lappend SUE_DATA(label,$name) \
	    "[expr $x * $mult] [expr $y * $mult] $layer"

	# this gives us the net from the paint
	eval sel_net -point [lindex $SUE_DATA(label,$name) 0]

	if {[sel_what paint] == ""} {
	  # try offset by res
	  setl {x y layer} [lindex $SUE_DATA(label,$name) 0]
	  sel_net -point [expr $x + [res]] [expr $y + [res]] $layer

	  if {[sel_what paint] == ""} {
	    # try offset by -res
	    sel_net -point [expr $x - [res]] [expr $y - [res]] $layer
	  }
	}

	set SUE_DATA([lrange [sel_what paint] 0 2]) $name
      }
    }
  }

  # close the file
  close $tmp_id

  return $matches
}


proc _cross_probe_cell {{-cell ""} {-more} cellid} -desc {
  called from SUE to cross probe a cell.  Select cell in max.
} {
puts "_cross_probe_cell $cell $cellid"
  global CELL

  if {$cell != ""} {
    if {[lay_editcell] != $cell} {
      if {[lay_editcell] == "$CELL(UNNAMED)"} {
	cell_load_cell $cell
      } else {
	edit_push -cell $cell
      }
    }
  }

  if {! $more} {sel_clear}

  if {[string first {[} $cellid] > 0} {
    # If the cell was something like FF[7:0], the sue netlist
    # will call it FF$0$ FF$1$ ... FF$7$, so try for that:
    foreach bit [nlt_bus_explode $cellid] {
      regsub {\[} $bit {$} bit
      regsub {\]} $bit {$} bit
      catch {sel_cell2 -more $bit} msg
    }
    if {![sel_what cells -boolean]} {
      msg "$msg\n"  ;# Failed to select anything
      set ret 0
    } else {
      set ret 1  ;# Dont know if we got em all, but we got something.
      # The box is left around the last cell selected.  Make it do something reasonable.
      eval lay_box [db_bbox -cell __SELECT__]
    }
  } else {
    if {[catch {sel_cell2 -more $cellid} msg]} {
      # Failed.  Now lets try a terrible hack.
      msg "$msg\n"  ;# Failed
      set ret 0
    } else {
      set ret 1  ;# Success
    }
  }

  # Since this is called from sue, the display is not automatically updated the
  # way it is for all wrapped max commands, so update manually.
  i_cmd_update
  return $ret
}


proc _cross_probe_net {{-cell ""} {-more} net {options ""}} -desc {
  called from SUE to cross probe.  Select net in max.
  possible options are "no_zoom more quiet"
} {
puts "_cross_probe_net $cell $net $options"

  global CELL SUE_DATA

  if {![info exists SUE_DATA(type)]} {
    max_error "Must run sue_cross_probe_init before cross probing"
    return 0
  }

  if {$cell != ""} {
    if {[lay_editcell] != $cell} {
      if {[lay_editcell] == "$CELL(UNNAMED)"} {
	cell_load_cell $cell
      } else {
	edit_push -cell $cell
      }
    }
  }

  if {!($more || [memq $options more])} {
    db_flyline -delete
    sel_clear
  }

  if {$SUE_DATA(type) == "by_name"} {
    foreach bit [nlt_bus_explode $net] {
      # These two functions duplicate effort a little bit.
      select_net_by_name -hier vis -more $bit
      fplan_sel_net -more $bit
    }
    i_cmd_update
    return
  }

  if {![info exists SUE_DATA(label,$net)]} {
    puts "Aborting, can't find net \"$net\" in max."
    i_cmd_update
    return
  }

  foreach one $SUE_DATA(label,$net) {
    setl {x y layer} $one
    sel_net -more -point [expr $x + [res]] [expr $y + [res]] $layer
  }
  sel_vias
  i_cmd_update
  return 1
}

proc _sue_goto_cell {sue} -desc {
  Make sue edit the same cell max is editing.
} {
  set maxcell [lay_editcell]
  set suecell [send $sue api_current_cell]
  if {$suecell != $maxcell} {
    send $sue api_goto_cell $maxcell
  }
}


proc sue_cross_probe_cell {} -desc {
  Send a request to sue to highlight the cell that is selected in max.
  Must have alread run sue_cross_probe_init.
  Return 1 on success, 0 on failure, -1 on error.
} {
  global SUE_DATA
  if {$SUE_DATA(type) == "by_name"} {
    set sue [misc_check_sue]
    if {$sue == ""} {
      msg "Aborting, couldn't find SUE.\n"
      return -1
    }
    # _sue_goto_cell $sue

    # Try to find a non-via.
    foreach cell_info [sel_what_l cells -limit 500] {
      set celltype [string tolower [cellinfo_def $cell_info]]
      if {[string match {#via*} $celltype] ||
	  [string match {via*} $celltype]} { continue }
      set cellid [cellinfo_id $cell_info]

      # If the cell in sue was a bus, the [] are replaced with $$.
      # Check for this special case.
      if {[regexp {^(.*)\$([0-9]+)\$$} $cellid junk part1 part2]} {
	set cellid "${part1}\[${part2}\]"
      }

      send $sue from_max_cross_probe_cell [list [lay_editcell]] [list $cellid]
      return 1;
    }
    # Message removed 12/20/01, because we now always try to cross_probe_cell
    # before trying for nets.
    # msg "Aborting, nothing selected to cross probe.\n"
  }
  return 0	;# Failed to find anything.

  # Removed 12/20/01
  #max_error "Can not cross probe cells using this type of cross-probing"
}


proc sue_cross_probe {} -desc {
  Send a request to sue to highlight whatever is selected.
  Must have alread run sue_cross_probe_init.
} {
  global SUE_DATA
  if {![info exists SUE_DATA(type)]} {
    max_error "Must run sue_cross_probe_init before cross probing"
    return
  }
  if {[sue_cross_probe_cell] == 0} {
    sue_cross_probe_net
  }
}


proc sue_cross_probe_net {} -desc {
  Send a request to sue to highlight the net that is selected in max.
  Must have alread run sue_cross_probe_init.
} {

  global SUE_DATA

  set sue [misc_check_sue]
  if {$sue == ""} {
    msg "Aborting, couldn't find SUE.\n"
    return
  }

  if {$SUE_DATA(type) == "by_name"} {
    # _sue_goto_cell $sue

    set lab_info [lindex [sel_what_l labels -limit 1] 0]
    if {$lab_info != ""} {
      set net [labinfo_text $lab_info]
    } else {
      msg "Aborting, must select a net before cross probing.\n"
      return
    }
    if {![send $sue from_max_cross_probe_net [list [lay_editcell]] [list $net]]} {
      msg "sue_cross_probe_net: Aborting, couldn't find net \"$net\" in SUE.\n"
    }
    return
  }

  # try to figure out net name in max
  set selection [sel_what paint]
  if {$selection == ""} {
    msg "Aborting, must select a net before cross probing.\n"
    return
  }

  # make sure we have the entire net
  setl {layer x y} $selection
  sel_net -point $x $y $layer 

  set net ""
  # first see if there is non-hidden label here
  foreach label [split [sel_what labels] \n] {
    if {[lindex $label 9] != "hidden"} {
      # got one
      set net [lindex $label 6]
      break
    }
  }

  if {$net == ""} {
    # no label, use paint
    set selection [lrange [sel_what paint] 0 2]

    if {[info exists SUE_DATA($selection)]} {
      set net $SUE_DATA($selection)

    } else {
      msg "sue_cross_probe_net: Aborting, can't find correspondence to selected net in MAX.\n"
      return
    }
  }
    
  # translate to SUE name
  if {![info exists SUE_DATA(equiv,$net)]} {
    max_error "sue_cross_probe_net: Aborting, no correspondence to selected net \"$net\" in SUE.\n"
    return
  }
  set net $SUE_DATA(equiv,$net)

  # now select net in SUE

  if {[send $sue {info commands from_max_cross_probe_net}] == "from_max_cross_probe_net"} {
    if {![send $sue from_max_cross_probe_net [list [lay_editcell]] [list $net]]} {
      max_error "sue_cross_probe_net: Aborting, couldn't find net \"$net\" in SUE.\n"
    }
  } else {
    if {![send $sue select_wire_by_name $net]} {
      max_error "sue_cross_probe_net: Aborting, couldn't find net \"$net\" in SUE.\n"
    }
  }
}


proc OLD_check_sue {} -desc {
  check that sue is up and running
} {

  # If you start two sues, then kill one, the new sue
  # is called "sue #2", and etc.
  foreach sue [list sue sue.exe "sue #2" "sue.exe #2" "sue #3" "sue.exe #3"] {
    if {![catch [list send $sue {#}]]} {
      # found sue!
      return $sue
    }
  }

  # no sue could be found
  return ""
}

proc misc_check_sue {{-start}} -doc {
  Version of check_sue that looks for all running sues,
  pops up window to ask which one.
  If -start, forget old sue we were using, query user
  which sue to use.
  Return name of sue window, or *CANCEL* if cancelled by user, or "" on failure
  to find or bring up a sue.
  sets SUE_CROSS_PROBE_ID with the sue tied to this max for cross-probing
} {
  global CELL SUE_CROSS_PROBE_ID

  if {! $start} {
    if {[use_first SUE_CROSS_PROBE_ID] == ""} {
      error "Cross probing has not been initialized yet"
    }

    # See if this sue window is still running.
    if {[catch {send $SUE_CROSS_PROBE_ID {#}}]} {
      return ""
    } else {
      return $SUE_CROSS_PROBE_ID  ;# Still running
    }
  }

  # Forget previous cross-probe sue.
  set SUE_CROSS_PROBE_ID ""

  set possible_sues ""
  foreach interp [winfo interps] {
    if {[string match sue* $interp]} {
      lappend possible_sues $interp
    }
  }
  set sue_list $possible_sues

  # We will give the user the option to start a new sue.
  set use_sue "Start a new copy of sue"
  set prop_list ""

  lappend sue_list "Start a new copy of sue"
  set use_sue [lindex $sue_list 0]
  lappend prop_list [list "Which sue" use_sue -radio $sue_list]

  global env
  set display [_misc_get_probe_display]
  lappend prop_list [list "X display for new sue" display -entry ]
  set sue_exe "sue"  ;# Might need to make it suex.
  lappend prop_list [list "Sue executable for new sue" sue_exe -entry]

  if {![prop_menu2 -title "Cross Probe sue" $prop_list]} {
    msg "cross_probe_init cancelled\n"
    return "*CANCEL*"  ;# cancelled
  }

  if {$use_sue == "Start a new copy of sue"} {
    global env

    if {0} {
      # Note: this code does not work yet because of a bug in the sue csh script.
      # Try again when sue is fixed.
  
      # Fire up a new sue.
      set cmd "xterm -ls -sb -sl 1000 -display $display -T \"Sue Terminal\""
      append cmd " -e $sue_exe"

      # Carefully quote for shell because winfo name may contain spaces.
      append cmd " -SET \"MAX_CROSS_PROBE_ID=[winfo name .]\""

      # Not needed any more because xterm -ls option passes current environment to sue.
      #set project [use_first PROJECT env(PROJECT)]
      #if {$project != ""} {append cmd " -SET PROJECT=$project"}

      # Carefully quote for shell because winfo name may contain spaces.
      # Ain't tcl grand!
      # append cmd " -CMD \"send \{[winfo name .]\} \\\"set SUE_CROSS_PROBE_ID \\\{\\\[winfo name .\\\]\\\}\\\"\""
      set my_win [list [winfo name .]]
      #append cmd " -CMD \\\"send $my_win \\\{set SUE_CROSS_PROBE_ID $my_win\\\}\\\""
      append cmd " -CMD \"send $my_win \\\{puts hi\\\}\""

      # Tell sue to try to load this cell.
      if {[lay_editcell] != "$CELL(UNNAMED)"} { append cmd " [lay_editcell]" }

      msg "Starting a new sue on display $display\n"
      global MAX_DEVELOPER
      if {[use_first MAX_DEVELOPER] == "1"} {
	puts "$cmd"
      }
      if {[catch "exec $cmd &" msg]} {
	msg "exec sue failed: $msg\n"
	return ""
      }

      for {set i 0} {$i < 10} {incr i} {
	# set by max using send
	if {$SUE_CROSS_PROBE_ID != ""} {
	  # we're there
	  puts "done."
	  break
	}
	after 1000
	update
      }

      if {$SUE_CROSS_PROBE_ID == ""} {
	error "Error: Timeout waiting for sue to start"
      }

    } else {
      # OLD code, but works:
      set cmd "xterm -sb -sl 1000 -display $display -T \"Sue Terminal\""
      append cmd " -e $sue_exe"
      # Carefully quote for shell because winfo name may contain spaces.
      append cmd " -SET \"MAX_CROSS_PROBE_ID=[winfo name .]\""

      # Tell sue to try to load this cell.
      if {[lay_editcell] != "$CELL(UNNAMED)"} { append cmd " [lay_editcell]" }

      puts "$cmd"
      eval exec $cmd &


      # Now we wait for sue to start.
      # It will be a sue interpreter that was not in the possible_sues list. 
      # If it doesnt start in 10 seconds, give up.
      # Note: the timeout is waiting for sue to exist.
      # After sue exists, the send will wait until its initialization is
      # complete before starting.
      set sue ""
      cursor_busy 1
      for {set i 0} {$sue=="" && $i < 10} {incr i} {
	foreach trysue [winfo interps] {
	  if {! [string match sue* $trysue]} {continue}
	  if {[lsearch -exact $possible_sues $trysue] != -1} {continue}
	  if {![catch {send $trysue "use_first MAX_CROSS_PROBE_ID"} result]} {
	    if {$result == [winfo name .]} {
	      set sue $trysue  ;# Found it
	      break
	    }
	  }
	}
	after 1000 ;# Wait a second.
      }
      cursor_busy 0

      if {$sue == ""} {
	error "Error: Timeout waiting for sue to start"
      }

    }

  } else {
    set sue $use_sue
  }

  set SUE_CROSS_PROBE_ID $sue
  return $SUE_CROSS_PROBE_ID
}


proc format_gds_layers {filename {outfile ""}} -desc {
  runs gds_info on filename and formats output for make_tech.  If optional outfile given then write output also to that file
} {

  global _CELLS_ _SUBCELLS_

  catch {unset _CELLS_}
  catch {unset _SUBCELLS_}

  # get rid of ~
  set filename [file nativename $filename]

  puts "Searching GDS file \"$filename\" for layers ..."

  if {[catch "gds_info $filename" info]} {
    puts "Aborting: $info"
    return
  }

  puts "Analyzing layers ..."

  # need to remove return chars from this
  regsub -all \n [lindex $info 0] "" info

  # get cells
  foreach cell [get_assoc cell_defs $info] {
    set name [get_assoc name $cell]
    foreach list [get_assoc subcells $cell] {
      setl {cellname count} $list
      lappend _CELLS_($name) "$cellname $count"
      set _SUBCELLS_($cellname) 0
    }
  }

  # find top most cells
  set topcells ""
  foreach cell [array names _CELLS_] {
    if {![info exists _SUBCELLS_($cell)]} {
      # this is one
      lappend topcells $cell
    }
  }
  set topcells [use_first topcells name]

  # figure out how many total instances of each cell
  foreach cell $topcells {
    _prop_cell_count $cell 1
    set _SUBCELLS_($cell) 1
  }

  foreach cell [get_assoc cell_defs $info] {
    set name [get_assoc name $cell]
    foreach list [get_assoc layers $cell] {
      setl {layer datatype boxes} $list

      if {![info exists LAYERS($layer)]} {
	set LAYERS($layer) 0
      }
      incr LAYERS($layer) [expr $boxes * [use_first _SUBCELLS_($name) '1]]

      set DATATYPES_${layer}($datatype) 1
    }
  }

  # try to make a guess at metal, contact, etc. layers
  set max 0
  set contact 0
  foreach layer [array names LAYERS] {
    if {$LAYERS($layer) > $max} {
      set contact $layer
      set max $LAYERS($layer)
    }
    set TYPES($layer) "-"
  }

  set max 0
  set poly 0
  set max_metal 6
  set metals 0

  set TYPES($contact) via
  set next_type ""
  foreach layer [lsort -integer [array names LAYERS]] {
    if {$layer == $contact} {
      set next_type metal
    } elseif {$next_type == "metal" && $LAYERS($layer) > 2} {
      set TYPES($layer) $next_type
      incr metals
      if {$metals >= $max_metal} {
	set next_type ""
      } else {
	set next_type via
      }
    } elseif {$next_type == "via" && $LAYERS($layer) > 2} {
      set TYPES($layer) $next_type
      set next_type metal
    } elseif {$next_type == ""} {
      # poly should have most boxes before contact
      if {$LAYERS($layer) > $max} {
	set poly $layer
	set max $LAYERS($layer)
      }
    }
  }

  set TYPES($poly) poly

  # can't have via as last layer
  foreach layer [lsort -integer -decreasing [array names LAYERS]] {
    if {$TYPES($layer) == "metal"} {
      # ok
      break
    } elseif {$TYPES($layer) == "via"} {
      set TYPES($layer) "-"
      break
    }
  }

  # now print them
  set lines ""
  lappend lines "\#layer  gds:dt txt:dt   type    width   space   color"
  lappend lines "\#====== ====== ====== ======== ======= ======= ======="

  set count 1
  foreach layer [lsort -integer [array names LAYERS]] {
    set datatypes [array names DATATYPES_$layer]
    if {[llength $datatypes] > 1 || $datatypes == 0} {
      set gds $layer
      set name L$layer
    } else {
      set gds $layer:$datatypes
      set name L${layer}_$datatypes
    }
    lappend lines "$name\t$gds\t-\t$TYPES($layer)\t-\t-"
#puts "$layer --> $LAYERS($layer)"
    incr count
  }

  foreach line $lines {
    puts $line
  }

  if {$outfile != ""} {
    exec echo [join $lines \n] > $outfile
    puts "Wrote to file \"$outfile\"."
  }

  puts "done"
}


proc _prop_cell_count {cell count} -desc {
  internal proc to format_gds_layers
} {

  global _CELLS_ _SUBCELLS_

  foreach list [use_first _CELLS_($cell)] {
    setl {subcell num} $list
    incr _SUBCELLS_($subcell) [expr $count * $num]
    _prop_cell_count $subcell [expr $count * $num]
  }
}


proc _relative_origin {} -desc {
  returns the relative origin for window placements.  for use in wm geometry statments.
} {

  global max_win

  set win $max_win.layout

  set winx [expr [winfo rootx $win] + 50]
  set winy [expr [winfo rooty $win] + 50]

  return "+$winx+$winy"
}



# Note (pat): This is a replacement for lay_box, which is now deprecated.
# I made the exact/user flag required, because every time you
# call layt_box, from now on, you must think about whether you
# wanted an exact location or a location snapped to user specified units.
# Exact locations should be used to save/restore box, or when manipulating
# pre-existing objects with exact placement (eg, laying a box on
# an existing piece of paint) or if the caller has its own grid mechanism
# that does not use the global mouse grid, for example, the wiring tool.
proc layt_box {args} -desc {
  Set box location to nearest legal units.  Replaces lay_box, which is deprecated.
} -doc {
  Usage: layt_box type [x1 y1 x2 y2]
  If coordinates are specified, sets the visible box location.
  No warning is issued if the coodinates are not on grid.
  Returns location of old box, or empty string if no box up.
  The type field must be one of:
  "user" : rounds box location to nearest mouse resolution as
		specified in the Grid Setup Menu.
  "mask"  : rounds box to nearest foundry mask grid coordinate.
  "exact" :  rounds box to nearest possible coordinate.
  "dontcare" :  Dont care what grid it rounds to.  (Mostly used just
		as a convenient way to document when the code really
		doesnt care what grid is used.)
} {
    set type [lindex $args 0]
    switch -- "$type" {
      "dontcare" -
      "exact" { set what "-internal" }
      "mask"  { set what "-mask" }
      "user"  { set what "-user" }
      default {
	error "lay_box syntax: lay_box type x1 y1 x2 y2;\
	       type must be one of: exact, user, dontcare"
      }
    }
    set args [lrange $args 1 end]
    set old_position [lay_box]  ;# Might be an empty string if no box up.
    if {[llength $args] != 0} {
	setl {x1 y1 x2 y2} $args
	eval lay_box [uusnap $what $x1 $y1 $x2 $y2]
    }
    return [eval uusnap $what $old_position]
}

# Note (pat): This is a replacement for lay_point, which is now deprecated.
# I made the exact/user flag required, because every time
# you call layt_point, from now on, you must think about whether you
# wanted an exact location or a location snapped to user specified units.
# Exact locations should be used to save/restore cursor position,
# or when laying a point to try to find paint, etc, or if the caller has
# its own grid mechanism that does not use the global mouse grid,
# for example, the wiring tool, which uses exact all the time, then rounds
# to its own user-specified grid.
proc layt_point {args} -desc {
  Set cursor location to nearest legal units.  Replaces lay_point, which is deprecated.
} -doc {
  Usage: layt_point [-options] type [x y]
  If coordinates are specified, the current cursor position is changed.
  No warning is issued if the coordinates are not on grid.
  Returns previous location of cursor.
  The type field must be one of:
  "user" : rounds point location to nearest mouse resolution as
		specified in the Grid Setup Menu.
  "mask"  : rounds point to nearest foundry mask grid coordinate.
  "exact" :  rounds point to nearest possible coordinate.
  "dontcare" :  Dont care what grid it rounds to.  (Mostly used just
		as a convenient way to document when the code really
		doesnt care what grid is used.)
  The possible options are:
    -no_clip  cursor location is not clipped to window.
    -warp     the mouse cursor is moved to the new location.
} {
    # Gather up any -options to lay_point in options.
    set options ""
    while { [regexp -- {-[a-zA-Z_]+} $args opt] } {
	set options "$opt $options"
	regsub -- $opt $args "" args
    }
    setl {what x y} $args
    switch -- "$what" {
      "dontcare" -
      "exact" { set what "" }
      "user"  { set what "-user" }
      "mask"  { set what "-mask" }
      default {
	error "layt_point syntax: layt_point -options type x y; \
	       type must be one of: exact, user, dontcare"
      }
    }
    set old_point [eval lay_point $options]
    if { $x != "" } {
	eval lay_point $options [eval uusnap $what $x $y]
	if { [string first -warp $options] >= 0 } {
	    cursor_msg_update
	}
    }
    return [eval uusnap $what $old_point]
}


proc layt_cross {{-tag ""} x y} -desc {
  Draw a cross to mark a point.
} {
  if { $tag != "" } { set tag "-tag $tag" }

  # Compute tick mark len.
  setl {fx1 fy1 fx2 fy2} [dbt_frame]
  # How many microns are showing in the window
  set frame_microns [expr [min [expr $fx2 - $fx1] [expr $fy2 - $fy1]]]
  # Tick len is 1% of frame size.
  set tlen [expr $frame_microns * 0.01]

  eval lay_line $tag [expr $x - $tlen] $y [expr $x + $tlen] $y
  eval lay_line $tag $x [expr $y - $tlen] $x [expr $y + $tlen]
}


proc layt_arrow {args} -desc {
  Draw an arrow.
} -doc {
  USAGE:
    layt_arrow [-tag tag] x1 y1 x2 y2
} {
  setl {x1 y1 x2 y2} [call_keyword $args [list {tag ""}]]
  if { $tag != "" } { set tag "-tag $tag" }
  if { $y2 == "" } { error "layt_arrow syntax error" }

  # Compute arrow head len.
  setl {fx1 fy1 fx2 fy2} [dbt_frame]
  # How many microns are showing in the window
  set frame_microns [expr [min [expr $fx2 - $fx1] [expr $fy2 - $fy1]]]
  # Arrow head marks are 3% of frame size.
  set tlen [expr $frame_microns * 0.03]

  # Compute angle from x2,y2 to x1,y1.
  set dx [expr $x1 - $x2]
  set dy [expr $y1 - $y2]

  # atan2 cant take (x,y) == (0,0) argument, and there is nothing
  # to draw in that case, anyway.
  if { $dx == 0 && $dy == 0 } { return }

  set llen [expr sqrt( $dx * $dx + $dy * $dy)]
  #set tlen [min $tlen $llen]

  set angle [expr atan2($dy,$dx)]
  eval lay_line $tag $x2 $y2 $x1 $y1
  eval lay_line $tag $x2 $y2 \
	[expr $x2 + $tlen * cos($angle + 0.5)] [expr $y2 + $tlen * sin($angle + 0.5)]
  eval lay_line $tag $x2 $y2 \
	[expr $x2 + $tlen * cos($angle - 0.5)] [expr $y2 + $tlen * sin($angle - 0.5)]
}


proc layt_rect {{-tag ""} x1 y1 x2 y2} -desc {
  Draw a temporary rectangle with lines.
} -doc {
  USAGE:
    layt_rect [-tag tag] x1 y1 x2 y2

  Erase using: lay_line [-tag tag] -clear
} {
  if { $tag != "" } { set tag "-tag $tag" }
  eval lay_line $tag $x1 $y1 $x1 $y2
  eval lay_line $tag $x1 $y2 $x2 $y2
  eval lay_line $tag $x2 $y2 $x2 $y1
  eval lay_line $tag $x2 $y1 $x1 $y1
}

proc layt_line_box {tag x1 y1 x2 y2 width sep} -desc {
    Draw a visible box using lines.  Any angle.
} -doc {
  Box is drawn around wire from x1,y1 to x2,y2 with specified width.
  Width may be 0.  Sep is an additional distance from the
  outline of the wire to where the box is drawn.
} {
	# Draw a visible box to aid wire placement.
	# Have to use lay_line, because lay_box can not go at angles.
	set dx [expr $x2 - $x1]
	set dy [expr $y2 - $y1]
	set angle [expr ($dy==0 && $dx==0) ? 0 : atan2($dy,$dx)]

	# wbs is length of diagonal across a rectangle of this size.
	set wbs [expr $sep * sqrt(2)]
	set pi 3.14149
	# Determine the bounding box of the wire itself.
	# This has to be done in this routine because we have to take
	# into account the wire endcaps calculated above.
	set wx1 [expr $x1 + $width/2.0 * cos($angle - $pi/2)]
	set wy1 [expr $y1 + $width/2.0 * sin($angle - $pi/2)]
	set wx2 [expr $x1 + $width/2.0 * cos($angle + $pi/2)]
	set wy2 [expr $y1 + $width/2.0 * sin($angle + $pi/2)]
	set wx3 [expr $x2 + $width/2.0 * cos($angle + $pi/2)]
	set wy3 [expr $y2 + $width/2.0 * sin($angle + $pi/2)]
	set wx4 [expr $x2 + $width/2.0 * cos($angle - $pi/2)]
	set wy4 [expr $y2 + $width/2.0 * sin($angle - $pi/2)]
	# Determine the coords of the four corners of the box.
	set bx1 [expr $wx1 + $wbs * cos($angle + $pi*1.25)]
	set by1 [expr $wy1 + $wbs * sin($angle + $pi*1.25)]
	set bx2 [expr $wx2 + $wbs * cos($angle + $pi*0.75)]
	set by2 [expr $wy2 + $wbs * sin($angle + $pi*0.75)]
	set bx3 [expr $wx3 + $wbs * cos($angle + $pi*0.25)]
	set by3 [expr $wy3 + $wbs * sin($angle + $pi*0.25)]
	set bx4 [expr $wx4 + $wbs * cos($angle - $pi*0.25)]
	set by4 [expr $wy4 + $wbs * sin($angle - $pi*0.25)]
	lay_line -tag $tag $bx1 $by1 $bx2 $by2
	lay_line -tag $tag $bx2 $by2 $bx3 $by3
	lay_line -tag $tag $bx3 $by3 $bx4 $by4
	lay_line -tag $tag $bx4 $by4 $bx1 $by1
}

proc file_grep {pat file} -desc {
  search file for regexp pattern, return 1 or 0
} {
    if {[catch {set fd [open $file "r"]}]} { return 0 }
    set result 0
    while {! [eof $fd]} {
	if {[regexp $pat [gets $fd]]} {
	    set result 1
	    break
	}
    }
    close $fd
    return $result
}



proc misc_save_config {{save_vars ""}} -desc {
  save configuration options to disk
} -doc {
  options are saved in the file <tech>.pref, where <tech> is the
  current technology, in the users local mmi_private directory.
  If the list: save_vars is specified, save those variables.
  Otherwise prompt for what to save.
} {
   global _MISC_SAVE

    # This is the data-base of config options to save.
    # The "Save Options" command uses this data-base to generate
    # the menu.
    # The index to each _misc_save_data is the name of a global variable
    # to save (or a dummy name if functions are specified).
    # The entry list contains: text description for menu,
    # function to call to save variable (or empty), and function called
    # to restore variable (or empty).  If no function is specified,
    # the index is the name of a global variable to save, eg "WIRE".
    # _misc_save_data is not a global variable, doesnt need to be.
    # Notes: We should save the GDS setups, too.
    set _misc_save_data(WIRE)      [list {Wire Setup} "" ""]
    set _misc_save_data(IGRID)      [list {Grid Setup} "" ""]
    set _misc_save_data(FLATTEN_SETUP) [list {Flatten Setup} "" ""]
    set _misc_save_data(RULER)     [list {Ruler Setup} "" ""]
    #set _misc_save_data(SEL_NET_SETUP)  [list {Select Net Setup} "" ""]
    set _misc_save_data(LAYINFO)   [list {Layout Generator Setup} "" ""]
    #set _misc_save_data(DRC)       [list {DRC Setup} "" ""]
    set _misc_save_data(OPTIONS)  [list {General Setup} "" ""]
    set _misc_save_data(_COLORS_)  [list {Color Editor Setup} \
		pal_write_palette pal_revert_default_palette]

    global VERSION_CONTROL_ENABLE
    if {[use_first VERSION_CONTROL_ENABLE '0]} {
      set _misc_save_data(VC_OPTIONS)      [list {Version Control Setup} "" ""]
    }

    # global _MISC_SAVE controls whether we save this array variable or not.
    catch { unset _MISC_SAVE }

    # This creates the directory if necessary.
    set techroot [max_local_tech_dir]
 
    if {![file isdir $techroot]} {
      set message "Aborting, can't create the directory \"$techroot\" to put the options into.  Fix permissions or create yourself and then rerun this command."
      warning $message

      return
    }

    set filename [max_local_pref_file_name]

    # Read the old file, if any.
    set old ""
    if { ! [catch {open $filename "r"} fd] } {
      while { [gets $fd line] >= 0 } {
	  if { $line != ""  && ! [string match {#*} $line] } {
	      lappend old $line
	  }
      }
      close $fd
    }

    if { $save_vars == "" } {

      set prop_list ""
      foreach var [array names _misc_save_data] {
	  set _MISC_SAVE($var) "ignore"
	  setl {desc} $_misc_save_data($var)
	  lappend prop_list [list $desc _MISC_SAVE($var) \
		-choice {ignore save revert_to_default}]
      }
      # Sort the options on the description so they appear in the
      # same order as in the File->User Preferences menu.
      set prop_list [lsort -index 0 $prop_list]

      lappend prop_list [list "" "" -help {\
	For each item, you can choose how to handle the configuration \
	item in future max sessions.  The options are: \
	Case "ignore": this function will not save the config item at \
	this time, although any previously saved info is left alone. \
	Case "save": the current state of the configuration item \
	is saved from the current max session for future max sessions. \
	Case "revert_to_default": any saved configuration info \
	for this config item is deleted, so the NEXT max session \
	will use start-up defaults.  However, the CURRENT max \
	session is unaffected (except for the palette, which \
	reverts instantly).}]

      # create the menu
      set title "Save Configuration"
      set message "Select items to save"

      if {![prop_menu2 -message $message -title $title $prop_list]} {
	  # cancelled
	  puts "Aborting Save configuration."
	  return
      }
    } else {
      foreach var $save_vars {
	if { ! [info exists _misc_save_data($var)] } {
	    # This variable is not in the data-base: its an error.
	    # Note: to use this function, you must put the variable
	    # you want to be able to save in the _misc_save_data, above.
	    max_error "misc_save_config: internal error: unrecognized option variable: $var"
	    return
	}
	set _MISC_SAVE($var) "save"
      }
    }

    if {[file exists $filename] && [file writable $filename]} {
      # get rid of ~
      set filename [file nativename $filename]
      # move old to a backup file, although I dont know why I bother,
      # we dont support reverting it.
      catch "exec \"mv\" -f $filename $filename$CELL(backup_suffix)"
    }

    set fd [open $filename "w"]
    global env
    set created_by ""
    if {[info exists env(USER)]} {
	set created_by "by $env(USER)"
    }
    puts $fd "# Saved $created_by [clock format [clock seconds]]"

    # Rewrite old values that we are not planning to save.
    foreach line $old {
      if { ! [regexp {^set [^(]+} $line varname] ||
	  [use_first _MISC_SAVE([lindex $varname 1])] == "ignore" } {
	  puts $fd $line
      }
    }

    # Save each of the specified arrays to the $filename file.
    set fnd_any 0
    foreach gvar [array names _MISC_SAVE] {
	setl {desc save_func revert_func} $_misc_save_data($gvar)
	if { $_MISC_SAVE($gvar) == "ignore" } {
	    # Nothing needed
	} elseif { $_MISC_SAVE($gvar) == "save" } {
	  if { $save_func == "" } {
	      set fnd_any 1
	      global $gvar
	      foreach x [array names $gvar] {
		  set element_name "${gvar}($x)"
		  puts $fd "set ${gvar}($x) \{[set $element_name]\}"
	      }
	      puts $fd ""   ;# Add a blank line for clarity
	  } else {
	      # Call the external function
	      eval $save_func
	  }
	} else {
	  assert { $_MISC_SAVE($gvar) == "revert_to_default" }
	  if { $revert_func == "" } {
	    set fnd_any 1
	  } else {
	      # Call the external function
	      eval $revert_func
	  }
	}
    }
    close $fd

    if { $fnd_any } {
	puts "Wrote options to file \"$filename\"."
    } else {
	puts "No options written to file \"$filename\"."
    }
}


proc misc_setup {} {
  global OPTIONS SEL_NET_SETUP

  set prop_list ""
  lappend prop_list [list \
    {Warp Cursor to Menu} OPTIONS(warp_cursor) -binary\
    -help {if set, the mouse cursor will be moved automatically (warped)\
    to somewhere within most pop up menus.}]
  lappend prop_list [list \
    {Raise Menus on Mouse Click} OPTIONS(auto_raise_window) -binary \
    -help {if set, and a prop menu or dialog box is obscured by the main\
    max window, that is, if it gets behind the main max window in the window\
    stacking order and is no longer visible, then clicking the mouse\
    anywhere in the max window will automatically raise\
    and make visible the current prop menu or dialog box.}]

  # Not needed.
  # lappend prop_list [list {Use Popup Menus on Mouse BUT-3} \
  #	OPTIONS(use_popups) -binary]

  lappend prop_list [list ":" "" -separator]
  lappend prop_list [list "SELECT NET OPTIONS:" "" -label]
  lappend prop_list [list \
    "Display selected text" SEL_NET_SETUP(display_labels) -binary \
    -help {When you select a net, displays all unique text on the net,\
    which can be a very long list.}]
  lappend prop_list [list \
    "Display hierarchical paths for text" \
    SEL_NET_SETUP(display_label_path) -binary \
    -help {When you select a net, use hierarchical text names in the\
    list of selected text}]

  lappend prop_list [list ":" "" -separator]
  lappend prop_list [list "DOCUMENTATION OPTIONS:" "" -label]
  lappend prop_list [list \
    "Text editor:" OPTIONS(editor) -entry \
    -help {Default text file editor for "Display Cell Doc" in View menu}]
  lappend prop_list [list \
    "Default text file suffix:" OPTIONS(doc_text_suffix) -entry \
    -help {Default text file suffix for "Display Cell Doc" in View menu}]
  lappend prop_list [list \
    "Html browser:" OPTIONS(browser) -entry \
    -help {Default html file browser for "Display Cell Doc" in View menu}]
  lappend prop_list [list \
    "Default html file suffix:" OPTIONS(doc_html_suffix) -entry \
    -help {Default html file suffix for "Display Cell Doc" in View menu}]

  global MAX_DEVELOPER
  if { $MAX_DEVELOPER } {
    # Max developer options are in OPTIONS(dev,*)
    lappend prop_list [list {} {} -separator]
    lappend prop_list [list {MAX DEVELOPER OPTIONS} {} -label]
    foreach ind [array names OPTIONS dev,*] {
      regsub {dev,} $ind "" name
      lappend prop_list [list $name OPTIONS($ind) -entry]
    }
  }

  prop_menu2 -title "General Options" $prop_list
}


proc make_from_feedback {{mode interactive}} -desc {
  convert the feedback layer into a real layer.  Useful for nplus, pplus, nw.
} {

  set msg "0 0 0"
  msg_catch ":feedback count" tmp msg
  set num [lindex $msg 2]

  if {$num == 0} {
    if {$mode != "batch"} {
      tk_dialog .dialog "No Feedback" \
	  "Aborting, must do a Mask see of desired layer first" {} 0 OK
    }
    return
  }

  msg_catch ":feedback find 1" tmp msg
  set layer ""
  regexp {"([a-zA-Z0-9-_.]+)"} $msg tmp layer

  if {[string first GDS_ $layer] == 0} {
    # lose the GDS_
    set layer [string range $layer 4 end]
  }

  if {[msg_catch "lay_layer_styles $layer"]} {
    # not a valid layer
    tk_dialog .dialog "Not Valid" \
	"Aborting, feedback for layer \"$layer\" is not a valid paint layer" \
	{} 0 OK
    return
  }

  for {set i 1} {$i <= $num} {incr i} {
    msg_catch ":feedback find $i" tmp tmp2
    :paint $layer
  }

  :feedback clear
  puts "Generated layer \"$layer\"."
}


proc generate_layers {{can_layers {nplus pplus nwell}}} -desc {
  generate the given layers
} {

  set title "Generate Layers"
  set message "Options:" 

  set prop_list ""

  # Translate canonical layer names to actual layer names
  # in the current technology.
  set layers ""
  foreach layer $can_layers {
    lappend layers [techinfo layer $layer]
  }

  foreach layer $layers {
    set use_$layer 1
    lappend prop_list [list "Generate $layer" use_$layer binary]
  }

  lappend prop_list [list {} {} -separator]

  set clear 0
  lappend prop_list [list "Delete then Generate" clear binary]

  lappend prop_list [list {} {} -help {Generate the specified\
    layers by using DRC rules from the current\
    technology file to surround existing geometry in the current cell.}]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return
  }

  view_cell

#  set ostyle [cif_ostyle]
#  if {$ostyle == "no_derive"} {
#    # switch to derive style
#    foreach style [cif_ostyle -list] {
#      if {$style != "no_derive"} {
#	cif_ostyle $style
#	break
#      }
#    }
#  }

  foreach layer $layers {

    if {[set use_$layer]} {

      if {$clear} {
	# first delete this layer
	eval sel_area -layers $layer [lay_bbox]
	:delete
      }

      if {[msg_catch "cif_see $layer"]} {
	# try GDS_
	if {[msg_catch "cif_see GDS_$layer"]} {
	  puts "Skipping layer \"$layer\".  Can't see it"
	  continue
	}
      }
    }

    make_from_feedback batch
  }

  # restore ostyle
#  cif_ostyle $ostyle

  view_cell
}


proc clear_annotations {} -desc {
  clear feedback and text and line annotations from current cell
} {

  :feedback clear 
  lay_text -clear 
  lay_line -clear
}

proc quote_glob {pattern} -desc {
  Quote a literal string that will be used where a glob-pattern is expected.
} {
    # Quote initial "-" so result can be used as an argument without danger
    # of being misinterpreted as an option.
    regsub -all {(^-)|([][\*?])} $pattern {\\&} pattern
    return $pattern
}

proc quote_string {val} -desc {
  Quote tcl string characters
} -doc {
    Pats note: Dont use this!!  Just use: [list $val]
} {
    # pats note: This is sub-optimal, but dont think this func is even used.
    # Use list instead of quote_string.
    regsub -all {\\} $val {\\\\} val
    regsub -all {\[} $val {\\[} val
    regsub -all {\]} $val {\\]} val
    regsub -all {\$} $val {\\$} val
    return $val
}

proc assert {expression} -desc {
  if expression is not TRUE, print error message.
} {
    uplevel 1 "if { !($expression) } { error {assertion failed: $expression} }"
}

init_global DRC(PRIORITY,zoom_in) \
	-default 10 \
	-desc { Default DRC_PRIORITY when display is zoomed out }

init_global DRC(PRIORITY,zoom_out) \
	-default 100 \
	-desc { Default DRC_PRIORITY when display is zoomed out }

init_global DRC(STEP_SIZE,zoom_in) \
	-default 50 \
	-desc { Default DRC_STEP_SIZE when display is zoomed in }

init_global DRC(STEP_SIZE,zoom_out) \
	-default 50 \
	-desc { Default DRC_STEP_SIZE when display is zoomed out }


proc drc_setup_menu {} -desc {
  Popup menu to set drc priority.
} {
  # We do NOT change the scheduling priority, just the step (chunk) size,
  # which has a large affect on both drc speed and interactive response.
  global DRC

  # Set these to the min/max step size we will allow the user to set.
  set min(PRIORITY) 10
  set max(PRIORITY) 300
  set min(STEP_SIZE) 10
  set max(STEP_SIZE) 300

  # Make sure nothing was manually set out of bounds.
  foreach var [list PRIORITY STEP_SIZE] {
    foreach z [list zoom_in zoom_out] {
      if { $DRC($var,$z) < $min($var) } { set DRC($var,$z) $min($var) }
      if { $DRC($var,$z) > $max($var) } { set DRC($var,$z) $max($var) }
    }
  }

  # We are currently scaling it, just let the user see it ?
  #set factor [expr 0.01 * ($max_step_size - $min_step_size)]
  #set drc_scale [expr round((1.0 * $DRC_STEP_SIZE - $min_step_size)/$factor)]

  set prop_list [list \
	[list "Note: lower user priority = faster DRC, slower interactive response" "" -label] \
	[list "User priority during DRC when zoomed in" DRC(PRIORITY,zoom_in)\
	   -scale $min(PRIORITY) $max(PRIORITY) -incr 1 -validate] \
	[list "User priority during DRC when zoomed out" DRC(PRIORITY,zoom_out)\
	   -scale $min(PRIORITY) $max(PRIORITY) -incr 1 -validate] \
	[list {} {} -separator] \
	[list "Note: bigger step size = faster DRC, slower interactive response" "" -label] \
	[list "DRC Step Size when zoomed in" DRC(STEP_SIZE,zoom_in)\
	   -scale $min(STEP_SIZE) $max(STEP_SIZE) -incr 1 -validate] \
	[list "DRC Step Size when zoomed out" DRC(STEP_SIZE,zoom_out)\
	   -scale $min(STEP_SIZE) $max(STEP_SIZE) -incr 1 -validate] \
	]
  
  global LAY_DB_UNITS_PER_PIXEL LAY_PAINT_ZOT
  if { $LAY_DB_UNITS_PER_PIXEL >= $LAY_PAINT_ZOT } {
    set zot "Zoomed Out"
  } else {
    set zot "Zoomed In"
  }
  lappend prop_list [list {} {} -separator]
  lappend prop_list [list {You are currently:} zot -label]

  set title "DRC Speed Control"
  if {![prop_menu2 -message $title -title $title $prop_list]} {
    # cancelled
    return
  }
  drc_redisplay_hook
  return
}


proc drc_redisplay_hook {} -desc {
  Set drc speed controls based on current zoom factor.
} -doc {
  This is called before each max redisplay.
} {
  global DRC LAY_DB_UNITS_PER_PIXEL LAY_PAINT_ZOT
  global DRC_STEP_SIZE DRC_PRIORITY
  global PAL STATUS
  
  foreach var [list STEP_SIZE PRIOIRTY] {
    if { $LAY_DB_UNITS_PER_PIXEL >= $LAY_PAINT_ZOT } {
	# We are zoomed out
	if { [info exists DRC($var,zoom_out)] } {
	  eval set DRC_$var $DRC($var,zoom_out)
	  $STATUS(widget.drc) configure -background $PAL(disabled_color)
	}
      } else {
	# We are zoomed in
	if { [info exists DRC($var,zoom_in)] } {
	  set DRC_$var $DRC($var,zoom_in)
	  $STATUS(widget.drc) configure -background bisque
	}
    }
  }
}


proc drc_status_update {} -desc {
  Set the STATUS drc variables (displayed in the bottom bar) based on current drc info
} -doc {
  This is called periodically by max.
} {
    global drc_on drc_busy STATUS

    if { !$drc_on } {
	set STATUS(drc_msg) "drc off"
    } elseif { $drc_busy } {
	set STATUS(drc_msg) "drc busy"
    } else {
	set error_cnt [llength [split [db_search paint -limit 11 error_p,error_s,error_ps] \n]]
	if { $error_cnt == 0 } {
	  set STATUS(drc_msg) "drc clean"
	} elseif { $error_cnt >= 10 } {
	  set STATUS(drc_msg) "drc >10 errors"
	} else {
	  set STATUS(drc_msg) "drc $error_cnt errors"
	}
    }
}


proc undo {} {
  cursor_busy 1 
  set old_cell [lay_editcell]
  msg_catch {:undo} a b
  if { [string first "Nothing more" $b] == 0 } {
    # Nothing more to undo
    mode_tmp_msg $b
    cursor_busy 0
    return
  }
  if { $b != "" } {
    msg $b  ;# Dont know what it might be, but better print it.
  }

  set new_cell [lay_editcell]
  if { $old_cell != $new_cell } {
    :redo
    set message "No more changes to this cell, switch to cell $new_cell ?"
    set choice [tk_dialog .dialog "Undo" $message {} 0 \
		Yes Cancel]
    if { $choice == 0 } { 
	# user hit Yes button
	:undo
    }
  }
  i_cmd_between 1
  cursor_busy 0
}

proc redo {} {
  cursor_busy 1
  set old_cell [lay_editcell]
  msg_catch {:redo} a b
  if { [string first "Nothing more" $b] == 0 } {
    # Nothing more to redo
    mode_tmp_msg $b
    cursor_busy 0
    return
  }
  if { $b != "" } {
    msg $b  ;# Dont know what it might be, but better print it.
  }

  set new_cell [lay_editcell]
  if { $old_cell != $new_cell } {
    :undo
    set message "No more changes to undo in this cell, switch to cell $new_cell ?"
    set choice [tk_dialog .dialog "Undo" $message {} 0 \
		Yes Cancel]
    if { $choice == 0 } { 
	# user hit Yes button
	:redo
    }
  }
  i_cmd_between 1
  cursor_busy 0
}


proc align_objects {} -desc {
  Called by align objects menu command.
} {
  set save_box [lay_box]
  set cells  [sel_what_l cells -edit_only bad1]
  set labels [sel_what_l labels -edit_only bad2]
  set types  [sel_what_l types] ;# Includes both paint and polygons
  set len_cells  [llength $cells]
  set len_labels [llength $labels]
  set len_types  [llength $types]

  if { $bad1 || $bad2 } {
    max_error "align_objects: error: There are selected objects that are not in the edit cell \
      - only objects in the current edit cell can be aligned."
    return
  }

  if { $len_types != 0 } {
    # If you try to align paint, the individual paint rectangles are
    # aligned, and they all end up in a jumble.
    # You could maybe do it based on connectivity:  copy selection
    # to a temp cell, and then start sel_net-ing the paints
    # to group into connected units, but sounds hard.
    max_error "align_objects: error: Only cells and labels can be aligned; no paint, wires, or polygons"
    return
  }

  if { $len_cells == 0 && $len_labels == 0 } {
    max_error "align_objects: error: Must first select objects to be aligned."
    return
  }


  set align_type "left"
  set f_use_origin 0
  set prop_list ""
  lappend prop_list [list "Align Objects:" align_type -radio \
    {{left sides} {right sides} tops bottoms {Individually to User Grid}} \
    -values {left right tops bottoms usergrid} \
    -help {If you select left, right, tops or bottoms, the specified\
    side of each object is aligned with the specified side of the current box.\
    Usually the box is over the last object selected, so other objects\
    are aligned with the last object selected.\
    Alternatively, you can place a box with the b command, to which\
    the objects will be aligned.\
    If you select "Individually to Grid", all selected objects are\
    nudged until their lower left corners are aligned on the current\
    User Grid, as specified in the Grid Menu.}]
  
  lappend prop_list [list "Align cells using:" f_use_origin -enum \
    {{cell bounding box} {cell origin}} \
    -help {If you select "cell bounding box", the cells are aligned using\
    the edges of their bounding boxes.\
    If you select "cell origin" the cells are aligned such\
    that the cell origin inside the cell is aligned in the current cell.}]
  
  if {![prop_menu2 -title "Align Objects" $prop_list]} {
    # cancelled
    return
  }


  # We select the labels based on their location, among other things,
  # and we are moving them.  Newlabels is built up identical to labels
  # but has the updated locations.
  set updatedlabels ""

  if { $align_type == "usergrid" } {

    foreach cell $cells {
      struct max_cell c $cell
      if {[msg_catch {sel_cell2 ${c.id}} junk1 junk2 junk3]} {
	continue
      }
      if { $f_use_origin } {
	setl {ox oy} [cell_origin]
      } else {
	set ox ${c.x1}; set oy ${c.y1}
      }
      setl {nx ny} [uusnap -user $ox $oy]
      sel_move [uusnap [expr $nx - $ox]] [uusnap [expr $ny - $oy]]
    }

    foreach lab $labels {
      struct max_label l $lab
      sel_labels -layer ${l.layer} -text ${l.text} -pos ${l.pos} \
	-rect ${l.x1} ${l.y1} ${l.x2} ${l.y2} -kind ${l.kind}
      setl {nx ny} [uusnap -user ${l.x1} ${l.y1}]
      sel_move [uusnap [expr $nx - ${l.x1}]] [uusnap [expr $ny - ${l.y1}]]

      lappend updatedlabels [lindex [sel_what_l labels] 0]
    }

  } else {

    # We are aligning multiple objects to the box.
    struct rect box $save_box

    foreach cell $cells {
      struct max_cell c $cell
      if {[msg_catch {sel_cell2 ${c.id}} junk1 junk2 junk3]} {
	# The cell has disappeared, because one of the other
	# cells landed right on top of it, and poof!
	continue
      }
      if { $f_use_origin } {
	setl {ox1 oy1} [cell_origin]
	set ox2 $ox1; set oy2 $oy1
      } else {
	set ox1 ${c.x1}; set oy1 ${c.y1}
	set ox2 ${c.x2}; set oy2 ${c.y2}
      }
      switch $align_type {
      "left"    { :move W [expr $ox1 - ${box.x1}] }
      "right"   { :move W [expr $ox2 - ${box.x2}] }
      "bottoms" { :move S [expr $oy1 - ${box.y1}] }
      "tops"    { :move S [expr $oy2 - ${box.y2}] }
      }
    }

    foreach lab $labels {
      struct max_label l $lab
      sel_labels -layer ${l.layer} -text ${l.text} -pos ${l.pos} \
	-rect ${l.x1} ${l.y1} ${l.x2} ${l.y2} -kind ${l.kind}
      switch $align_type {
      "left"    { :move W [expr ${l.x1} - ${box.x1}] }
      "right"   { :move W [expr ${l.x2} - ${box.x2}] }
      "bottoms" { :move S [expr ${l.y1} - ${box.y1}] }
      "tops"    { :move S [expr ${l.y2} - ${box.y2}] }
      }
      # Save up the new label locations for later selection.
      lappend updatedlabels [lindex [sel_what_l labels] 0]
    }

  }

  # Attempt to restore the selected items.
  # The save_selection/restore_selection procedures only work
  # if nothing has changed, and we have moved things, so go through
  # the lists and individually reselect each thing.
  # we moved things, and they only work if nothing has changed.
  sel_clear
  foreach cell $cells {
    struct max_cell c $cell
    msg_catch {sel_cell2 -more ${c.id}} junk1 junk2 junk3
  }
  foreach lab $updatedlabels {
    struct max_label l $lab
    sel_labels -more -layer ${l.layer} -text ${l.text} -pos ${l.pos} \
      -rect ${l.x1} ${l.y1} ${l.x2} ${l.y2} -kind ${l.kind}
  }

  # Restore the box
  eval layt_box exact $save_box
}

proc misc_display_doc_file {} {

  global OPTIONS env

  set editor [use_first env(EDITOR) OPTIONS(editor) 'vi]
  # special case for vi, need to put into a window
  if {[regexp -nocase {([a-z/._-]*vi[a-z/._-]*)} $editor match]} {
    set editor "xterm -e $match"
  }

  set file_paths ""
  set html_paths ""

  set name [lay_editcell]

  # first look for default paths
  set dir [file dirname [cell_file [lay_editcell]]]

  set file [clean_dir $name$OPTIONS(doc_html_suffix) $dir]
  if {[file exists $file]} {
    set html_paths $file
  } else {
    set file [clean_dir $name$OPTIONS(doc_text_suffix) $dir]
    if {[file exists $file]} {
      set file_paths $file
    }
  }

  if {0} {
    # Max comments can not contain /, so this code is worthless;
    # there is no reason to look in comments for a path name.

    # search for text that might contain paths
    set labels [db_search_l labels -non_hier -cell [lay_editcell]]
    foreach label_info $labels {
      struct max_label l $label_info
      # Only look at comment labels
      if { ${l.kind} != "comment" } { continue }
      set text ${l.text}

      set index [string first "file:" $text]
      # \{\{  
      if {$index != -1} {
	set path [lindex [split [string range $text [expr $index + 5] \
					       end] " )\}\]"] 0]
	lappend file_paths [clean_dir $path $dir]
      }
      set index [string first "html:" $text]
      if {$index != -1} {
	set path [lindex [split [string range $text [expr $index + 5] \
					       end] " )\}\]"] 0]
	lappend html_paths [clean_dir $path $dir]
      }
    }
  }

  if {$file_paths == "" && $html_paths == ""} {
    # create a doc file
    set title "Can't find doc file"
    set message "Create new doc file for \"$name\" using"
    set prop_list [list [list path file]]

    # create the menu
    set ret [prop_menu2 -message $message -title $title $prop_list]
    if {$ret == 0} {
      # empty list means the user hit cancel
      return
    }

    if {[file exists $file]} {
      # Uh Oh, this file already esists, query user.
      set button [tk_dialog .edit_doc "Edit documentation" \
		      "File $file already exists." \
		      "" 0 {Use} {overwrite} {cancel}]
      
      if {$button == 2} {
	# user hit the cancel key
	return
      }
      if {$button == 0} {
	# use the existing file
	puts "running \"$editor\" with $file ..."
	eval exec $editor $file &
	return
      }
    }

    if {[file extension $file] == $OPTIONS(doc_html_suffix)} {
      # for html, simple stuff to get you going
      set header "Documentation for $name\n\n"
#      set header "<title> Documentation $name \</title\>\\\n\\\n\<h2\>Add Heading Here \</h2\>\\\n\<pre\>\\\nadd text here\\\n\</pre\>"
      set html_paths $file
    } else {
      set header "Documentation for $name\n\n"
      set file_paths $file
    }

    # create the file
    if {[catch "exec echo \"$header\" > $file" msg] != 0} {
      # error, probably can't write to directory
      max_error "misc_display_doc_file: Aborting. $msg"
      return
    }
  }

  if {$file_paths != ""} {

    puts "running \"$editor\" with $file_paths ..."
    eval exec $editor $file_paths &
  }

  if {$html_paths != ""} {
    foreach file [lreverse $html_paths] {
      if {[string range $file 0 0] == "~"} {
        # netscape doesn't seem to understand ~user, replace 
        # with /home/user.  This is a hack.
        set list [split $file /]
        set user [string range [lindex $list 0] 1 end]
        set file [join "/home $user [lrange $list 1 end]" /]
      }

      # call the browser on this file	
      browser_open $file
    }
  }
}
