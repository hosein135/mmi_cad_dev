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

set RCSVERSION(lef.tcl) { $Revision: 1.2 $ }

proc lef_parse_skip {fd origline} {
  # Figure out what section name is that we will be ENDing.
  regsub {#.*} $origline "" newline  ;# Remove comments
  if {[llength $newline] == 1} {
    set thing [lindex $newline 0]
  } else {
    set thing [lindex $newline 1]
  }

  while {[gets $fd line] != -1} {
    if {[lindex $line 0] == "END" && [lindex $line 1] == $thing} {
      return
    }
  }
  error "read_lef: unexpected end of file, last section started at: $origline"
}

proc lef_parse_site {fd line} -desc {
  parse the SITE info from the lef file.  Warn if site is redefined.
} -doc {
  For parsing, there must not be any newlines in the directives.

  The SITE info is left in global LEF_SITES as an assoc list.
} {
  global LEF_SITES
  set corename [lindex $line 1]

  set core_props ""

  while {[gets $fd line] != -1} {
    #puts "line=$line, lindex=[lindex $line 0]"

    regsub {;.*} $line "" line  ; # strip off semi-colon
    regsub {#.*} $line "" line  ; # remove comments

    # Skip comments and blank lines
    set line [string trimleft $line]
    if {[string length $line] == 0} {continue}

    set line [string toupper $line]
    switch -- [lindex $line 0] {
      "SIZE" {
	if {[lindex $line 2] != "BY"} {
	  max_error -buffer  "read_lef: error: unrecognized \"SIZE\" inside SITE $corename"
	} else {
	  lappend core_props [list SIZE "[lindex $line 1] [lindex $line 3]"]
	}
      }
      "CLASS" {
	lappend core_props [list CLASS [lindex $line 1]]
      }
      "SYMMETRY" {
	lappend core_props [list SYMMETRY [lindex $line 1]]
      }
      "END" {
	if {[lindex $line 1] != $corename} {
	  error "read_lef: error: reading SITE $corename: unexpected: $line"
	}
	break ;# done reading this SITE section.
      }
      default {
	max_error -buffer "read_lef: warning: unrecognized line in SITE: $line"
      }
    }
  }

  # Detect redefinition of a SITE that is not the same.
  if {[info exists LEF_SITES($corename)]} {
    set old $LEF_SITES($corename)
    foreach prop "SIZE SYMMETRY CLASS" {
      if {[get_assoc $prop $old] != [get_assoc $prop $core_props]} {
	max_error -buffer "read_lef: warning: Redefinition of SITE $corename conflicts with previous definition"
	break
      }
    }
  }

  msg_put_log "Reading LEF SITE $corename\n"

  set LEF_SITES($corename) $core_props
}

proc lef_parse_layer {fd line} -desc {
  parse the LAYER info from a lef file.
} {
    global WIRE

    set leflayer [lindex $line 1]
    set layer [string tolower $leflayer]

    set wire_layers [techinfo wire_layers]

    if {[lsearch $wire_layers $layer] == -1} {
      # Print this message if the layer we are ignoring
      # is genuinely unrecognized; ignore vias.
      set via_layers [techinfo layers via]
      if {[lsearch $via_layers $layer] == -1} {
	# Last ditch:  Layer might have been defined in the tech file,
	# but if it is not a wiring or via layer, reading in the
	# LEF info will do nothing.
	set all_layers [techinfo layer_order]
	if {[lsearch $all_layers $layer] == -1} {
	  msg "Ignoring LEF info for unrecognized layer $layer\n"
	} else {
	  msg "Ignoring LEF info for non-wiring/via layer $layer\n"
	}
	lef_parse_skip $fd $line
	return
      }
    }

    set offset ""

    msg "Reading LEF LAYER $layer\n"
    while {[gets $fd line] != -1} {
      regsub {;.*} $line "" line  ; # strip off semi-colon
      regsub {#.*} $line "" line  ; # remove comments

      switch -- [lindex $line 0] {
	OFFSET {
	  set offset [lindex $line 1]
	}
	PITCH {
	  set WIRE($layer,snap) [uusnap -mask [lindex $line 1]]
	}
	DIRECTION {
	  set WIRE($layer,direction) [string tolower [lindex $line 1]]
	}
	WIDTH {
	  set WIRE($layer,width) [uusnap -mask [lindex $line 1]]
	}
	RESISTANCE {
	  if {[lindex $line 1] != "RPERSQ"} {
	    msg "Unrecognized LEF line: $line\n"
	  } else {
	    set WIRE($layer,rpersq) [lindex $line 2]
	  }
	}
	CAPACITANCE {
	  if {[lindex $line 1] != "CPERSQDIST"} {
	    msg "Unrecognized LEF line: $line\n"
	  } else {
	    # In pF.
	    set WIRE($layer,cpersq) [lindex $line 2]
	  }
	}
	EDGECAPACITANCE {
	    # In pF.
	    set WIRE($layer,cedge) [lindex $line 1]
	}
	END {
	  if {[lindex $line 1] != $leflayer} {
	    error "read_lef: unrecognized END statement in: $line"
	  }
	  break
	}
      }
    }

    # LEF documentation says explicitly that default OFFSET is PITCH/2.
    if {$offset == ""} {
      set WIRE($layer,offset) [uusnap -mask [expr [use_first WIRE($layer,snap) '0]/2.0]]
    } else {
      set WIRE($layer,offset) [uusnap -mask $offset]
    }
}


proc fplan_read_lef {{-menu} {-create_cells 0} {-create_pins pins_only} \
  {-overwrite 0} {-read_nl 1} {-create_obs no} {-watch_cells 0} \
  {-read_layers 1} {-read_macros 1} {-ignore_power_pins 0} {leffile ""}} -desc {
  Read a lef file for cell sizes and pin names.
} -doc {
  OPTIONS:
  -create_cells [0 | 1]
  -create_pins [no | pins_only | pins+geometry]
  -read_nl [0 | 1]         if 0, does not read the LEF into NL data-base.
  -read_layers [0 | 1]
  -read_macros [0 | 1]
  -overwrite [0 | 1]       if 1, any existing cell is deleted from memory (but not from disk).
  -create_obs [no | use_specified_layers | use_obs_layers]
} {
  global FPLAN _FPLAN_CELL_INFO
  global _FPLAN_READ_LEF_MENU ;# persistent data in menu.

  fplan_init

  if {! $menu && $leffile == ""} {
    max_error -buffer "fplan_read_lef: Dont know the default lef file!"
    return
  }

  if {$menu} {
    # Interactive mode.  Load _FPLAN_READ_LEF_MENU from defaults first time through.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      use_init _FPLAN_READ_LEF_MENU($option) [set $option]
    }

    set _FPLAN_READ_LEF_MENU(leffile) [use_first leffile _FPLAN_READ_LEF_MENU(leffile) FPLAN(DEFAULT_LEF_FILE)]

    set prop_list ""
    set fs_box_props [list -message "LEF file to read" -pattern "*.lef"]
    if {$_FPLAN_READ_LEF_MENU(leffile) != ""} {
      lappend fs_box_props -filename $_FPLAN_READ_LEF_MENU(leffile)
    }
    lappend prop_list [list "LEF File" _FPLAN_READ_LEF_MENU(leffile) -filename $fs_box_props]
    lappend prop_list [list "Read MACRO sizes+pins" _FPLAN_READ_LEF_MENU(read_macros) -binary]
    lappend prop_list [list "Read LAYER info" _FPLAN_READ_LEF_MENU(read_layers) -binary]
    lappend prop_list [list "Create blank cells" _FPLAN_READ_LEF_MENU(create_cells) -binary]
    lappend prop_list [list "Watch as cells created" _FPLAN_READ_LEF_MENU(watch_cells) -binary]
    lappend prop_list [list "Overwrite existing cells" _FPLAN_READ_LEF_MENU(overwrite) -binary]
    lappend prop_list [list "Create pins in cells" _FPLAN_READ_LEF_MENU(create_pins) -choice {no pins_only pins+geometry}]
    lappend prop_list [list "Create obstructions " _FPLAN_READ_LEF_MENU(create_obs) \
      -choice {no use_specified_layers use_obs_layers}]
    lappend prop_list [list "Ignore vss,vdd,gnd pins" _FPLAN_READ_LEF_MENU(ignore_power_pins) -binary]
    lappend prop_list [list "Read LEF into NL database" _FPLAN_READ_LEF_MENU(read_nl) -binary]
    lappend prop_list [list "Note: always reads UNITS and SITE" "" -label]
    if {[prop_menu2 -title "Read LEF" $prop_list] == 0} {
      return ;# cancelled
    }
    set leffile $_FPLAN_READ_LEF_MENU(leffile)

  } else {
    # Load _FPLAN_READ_LEF_MENU with defaults from proc def, above.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      set _FPLAN_READ_LEF_MENU($option) [set $option]
    }
  }

  if {! $_FPLAN_READ_LEF_MENU(create_cells)} {
    set _FPLAN_READ_LEF_MENU(create_pins) "no"
  }

  if {![file readable $leffile]} {
    error "Can not read file: $leffile"
  }


  # Suck lef the file into nl
  if {$_FPLAN_READ_LEF_MENU(read_nl) && $FPLAN(use_nl_shell)} {
    nl2_read_lef $leffile
  }

  # To make it fast, run it through sed to get just what we need.
  # We want the LAYER info, which is everything inside LAYER,END pairs,
  # and the SIZE and PIN and DIRECTION lines inside MACRO,END pairs.
  # NOTE: I took this out.  Can preprocess the LEF file, if you want to speed it up.
  #set sedcmd {^[ 	]*LAYER/,/^[ 	]*END/p;/^[ 	]*MACRO /p;/^[ 	]*SIZE /p;/^[ 	]*END/p;/^[ 	]*PIN/p;/^[ 	]*DIRECTION/p}
  #set sedcmd {s/^[ 	]*//;/^LAYER/,/^END/p;/^MACRO /p;/^SIZE /p;/^END/p;/^PIN/p;/^DIRECTION/p}
  #set cmd [list |sed -n $sedcmd $leffile]
  #set fd [open $cmd "r"]

  set fd [open $leffile "r"]

  unwind_catch {

  msg "Loading .lef into Chipper from file: $leffile\n"

  #set lefcell ""
  #set pinlist ""
  #set pinname ""
  #set width 0; set height 0
  set macro_count 0
  while {[gets $fd line] != -1} {
    #puts "line=$line, lindex=[lindex $line 0]"

    # Skip comments
    set line [string trimleft $line]
    if {[string index $line 0] == "#"} {continue}

    if {[string length $line] == 0} {continue}

    switch -exact -- [lindex $line 0] {
      UNITS {
	# We look at the units just to make sure it is 1000.
	# If not, give up.
	while {[gets $fd line] != -1} {
	  regsub {;.*} $line "" line  ; # strip off semi-colon
	  regsub {#.*} $line "" line  ; # remove comments
	  switch -- [lindex $line 0] {
	    DATABASE {
	      # This is screwy, but you specify 1000 to mean that the
	      # LEF units are in microns.  I think the 1000 is what they
	      # have to multiply by to get into DEF units.  If you omit
	      # this, they use 100 instead of 1000, so it is required.
	      if {[lindex $line 1] != "MICRONS" || \
	          [lindex $line 2] != 1000} {
		error "read_lef: error: unsupported UNITS specified: $line"
	      }
	    }
	    END {
	      if {[lindex $line 1] != "UNITS"} {
		error "read_lef: error: unexpected END reading UNITS: $line"
	      }
	      break
	    }
	    default {
	      msg "read_lef: warning: unsupported UNITS specified: $line\n"
	    }
	  }
	}
      }
      VIA {
	lef_parse_skip $fd $line
      }
      VIARULE {
	lef_parse_skip $fd $line
      }
      SPACING {
	lef_parse_skip $fd $line
      }
      NONDEFAULTRULE {
	lef_parse_skip $fd $line
      }
      SITE {
	lef_parse_site $fd $line
      }

      MACRO {
	if {! $_FPLAN_READ_LEF_MENU(read_macros)} {
	  lef_parse_skip $fd $line
	  continue
	}

	set lefcell [lindex $line 1]
	if {$_FPLAN_READ_LEF_MENU(create_cells) && $_FPLAN_READ_LEF_MENU(overwrite)} {
	  catch {db_cell_delete [fplan_fix_name $lefcell]}
	}
	# Unfortunately, starting logging in the max.rc file does not get these
	# messages from the project file, because max.rc has not been read yet at that point.
	msg_put_log "Reading LEF MACRO for $lefcell\n"

	set pinlist ""
	set fullpinlist ""	;# Used if we are creating geometry for pins
	set pinname ""
	set width 0; set height 0
	set obs ""
	set in_obs 0
	set in_port 0
	set end_macro 0
	set origin_x 0; set origin_y 0

	while {!$end_macro && [gets $fd multiline] != -1} {
	  foreach line [split $multiline ";"] {
	    regsub {#.*} $line "" line  ; # remove comments
	    switch -- [lindex $line 0] {
	      SIZE {
		if {$lefcell != ""} {
		  set width [lindex $line 1]
		  set height [lindex $line 3]
		  incr macro_count
		}
	      }
	      OBS {
		if {$_FPLAN_READ_LEF_MENU(create_obs) == "no"} {
		  lef_parse_skip $fd ""
		} else {
		  if {[lindex $line 1] == "LAYER"} {
		    set curlayer [lindex $line 2]
		  }
		  set in_obs 1
		}
	      }
	      PIN {
		if {$pinname != ""} {
		  msg "Error: no matching END found for PIN $pinname\n"
		}
		set pinname [lindex $line 1]
		set pindir ""	;# In case DIRECTION is unspecified.
		set pinrects ""
		set curlayer space
		if {$_FPLAN_READ_LEF_MENU(ignore_power_pins) && \
			[regexp -nocase {^(vdd|vss|gnd)$} $pinname]} { set pinname "" }
	      }
	      DIRECTION {
		set line [string trimright $line ";"]
		set pindir [string tolower [lindex $line 1]]
	      }
	      LAYER {
		# The layers may or may not be inside a "PORT" clause.
		# Doesnt really matter.
		set curlayer [lindex $line 1]
	      }
	      RECT {
		if {$in_obs} {
		  lappend obs [concat $curlayer [lrange $line 1 4]]
		} elseif {$_FPLAN_READ_LEF_MENU(create_pins) == "pins+geometry" && $pinname != ""} {
		  # It is a paint rectangle of a pin.
		  lappend pinrects [concat $curlayer [lrange $line 1 4]]
		}
	      }
	      PORT {
		set in_port 1
	      }
	      POLYGON {
		# TODO: implement these!
		if {![info exists polygon_err_msg($lefcell)]} {
		  msg "Warning: Cell $lefcell contaings POLYGONs, ignored\n"
		  set polygon_err_msg($lefcell) 1
		}
	      }
	      FOREIGN {
		set for_name [lindex $line 1]
		if {$for_name != $lefcell} {
		  msg "Warning in MACRO $lefcell: FOREIGN name ignored: $for_name\n"
		}
		set origin_x [expr $origin_x - [lindex $line 2]]
		set origin_y [expr $origin_y - [lindex $line 3]]
	      }
	      ORIGIN {
		set origin_x [expr $origin_x + [lindex $line 1]]
		set origin_y [expr $origin_y + [lindex $line 2]]
	      }
	      END {
		if {$in_obs} {
		  set in_obs 0
		} elseif {$in_port} {
		  set in_port 0
		} elseif {$pinname != "" && [lindex $line 1] == $pinname} {
		  lappend pinlist [list $pinname $pindir]
		  lappend fullpinlist [list $pinname $pindir $pinrects]
		  set pinname ""
		} elseif {[lindex $line 1] == $lefcell} {
		  set end_macro 1
		  break
		} else {
		  msg "Warning in cell $lefcell: unexpected END\n"
		}
	      }
	    }
	  }
	}

	set _FPLAN_CELL_INFO($lefcell) [list lef $width $height $pinlist]
	if {$_FPLAN_READ_LEF_MENU(create_cells)} {
	  if {$_FPLAN_READ_LEF_MENU(create_pins) == "no"} {
	    # Just create the cell.
	    set fullpinlist ""
	  }
	  set use_obs_layers [expr {$_FPLAN_READ_LEF_MENU(create_obs)=="use_obs_layers"}]
	  lef_create_blank_cell -x_offset $origin_x -y_offset $origin_y \
		-use_obs_layers $use_obs_layers $lefcell $width $height $fullpinlist $obs
	  if {$_FPLAN_READ_LEF_MENU(watch_cells)} {
	    catch {:load $lefcell}
	    update idletasks
	  }
	}
      }

      LAYER {

	if {! $_FPLAN_READ_LEF_MENU(read_layers)} {
	  lef_parse_skip $fd $line
	} else {
	  lef_parse_layer $fd $line
	}
      }

      VERSION {}
      NAMESCASESENSITIVE {}
      "#" {}
      INPUTPINANTENNASIZE {}
      OUTPUTPINANTENNASIZE {}
      INOUTPINANTENNASIZE {}
      MINFEATURE {}
      PROPERTYDEFINITIONS { lef_parse_skip $fd PROPERTYDEFINITIONS }

      END {
	if {[lindex $line 1] != "LIBRARY"} {
	  msg "read_lef: unexpected: $line\n"
	}
      }


      default {
	msg "read_lef: ignoring lef line: $line\n"
	#error "unrecognized lef line: $line"
      }
    }
  }

  } always {
    close $fd
  }

  # Init the block grid from the default CORE SITE specified in LEF.
  _fplan_set_core_grid

  msg "LEF done, loaded $macro_count MACROs from this LEF, [llength [array names _FPLAN_CELL_INFO]] total MACROs loaded\n"
}

proc lef_label_remove_dups {cellname} -desc {
  Remove duplicate identical label names from nets.
} {
  edit_push_direct $cellname

  # Create hash whose index is the label name and whose
  # contents is a list of labels with that name.
  foreach labinfo [db_search_labels -non_hier -cell $cellname] {
    lappend hash([labinfo_text $labinfo]) $labinfo
  }

  foreach label [array names hash] {
    if {[llength $hash($label)] > 1} {

      # Process each label with this name.
      foreach labinfo $hash($label) {
	# Does this label still exist?
	label_select $labinfo
	if {[llength [sel_what_l labels]] == 0} {
	  # This label was already deleted by this loop.
	  continue
	}


	setl {x1 y1 x2 y2} [labinfo_loc $labinfo]
	sel_net -point $x1 $y1 [labinfo_layer $labinfo]
	set sel_labels [sel_what_l labels]
	# Delete all selected labels but the first.
	for {set i 1} {$i < [llength $sel_labels]} {incr i} {
	  # Delete this_label
	  label_select [lindex $sel_labels $i]
	  :delete
	}
      }
    }
  }
  edit_pop_direct
}


# TODO: Preprocess with sed to change ; to \n; then remove the multline hack below.
# This is not quite trivial because there is probably an escape char for ; in names.
proc lef_create_blank_cell {{-x_offset 0} {-y_offset 0} {-use_obs_layers 1} lefcell width height pinlist obslist} -desc {
  Create blank cells (prb only) from LEF files that have been read into chipper using fplan_read_lef
} -doc {
  If -use_obs_layers 1  create obstructions using obstruction layers (eg m1_obs) if defined
  in the current technology.
  The -x_offset and -y_offset are added to all created geometries, but not the
  prb layer location; this mimics how the ORIGIN is defined in lef.
} {
  global LEF_LAYER
  # Cell_empty returns 0 if the cell has a disk file attached,
  # regardless of its contents, which is what we want here.
  set cellname [fplan_fix_name $lefcell]

  setl {centerx centery} [uusnap [expr $width/2.0] [expr $height/2.0]]

  if {[cell_empty $cellname]} {
    unwind_catch {
      msg "Creating MAX cell for LEF cell: $cellname\n"
      undo_disable
      catch {db_cell_new $cellname}

      # Note: the prb layer is NOT offset by the lef ORIGIN.
      db_paint -no_notify -cell $cellname [techinfo layer prb] 0 0 $width $height
      #fplan_set_bbox -cell $cellname 0 0 $width $height

      # There could be multiple disconnected nets for each net, each of which must be labeled.
      # The strategy is: foreach net: draw the paint into a temp cell, select any paint,
      # label it in the main cell, delete it from the temp cell, and repeat.
      # Note: we could not bother with this and just call lef_label_remove_dups later,
      # but lef_label_remove_dups is more expensive than this.
      set tmpcell __READ_LEF_TMP__
      catch {db_cell_new -internal -no_undo $tmpcell}
      edit_push_direct $tmpcell  ;# Must edit it so :delete will work.
      foreach pin_info $pinlist {
	db_cell_clear $tmpcell
	setl {pin_name pin_dir pin_rects} $pin_info
	# Draw the paint
	foreach rect $pin_rects {
	  setl {layer x1 y1 x2 y2} $rect
	  set x1 [expr $x1 + $x_offset]
	  set x2 [expr $x2 + $x_offset]
	  set y1 [expr $y1 + $y_offset]
	  set y2 [expr $y2 + $y_offset]

	  # Figure out what the max layer is for the specified LEF layer.
	  # The techinfo call is slow as molasses, so we cache result in LEF_LAYER
	  if {! [info exists LEF_LAYER($layer)]} {
	    set LEF_LAYER($layer) [techinfo layer $layer "" opt]
	    if {$LEF_LAYER($layer) == ""} {
		msg "error: unrecognized layer in lef file ignored: $layer\n"
	    }
	  }
	  set maxlayer $LEF_LAYER($layer)

	  if {$maxlayer != ""} {
	    db_paint -no_notify -cell $tmpcell $maxlayer $x1 $y1 $x2 $y2
	  }
	}

	# Copy paint for this net from tmpcell to main cell.
	db_cell_copy -source $tmpcell $lefcell

	# Foreach connected net in tmpcell, label it in the main cell.
	# TODO: Should probably prefer paint on a metal layer, not a via!
	set did_label 0
	while {1} {
	  set paintballs [db_search_paint -cell $tmpcell -limit 1]
	  if {[llength $paintballs] == 0} {
	    # All done
	    break
	  }
	  struct max_paint p [lindex $paintballs 0]

	  # Label the paint.
	  setl {cx cy} [uusnap [expr (${p.x1}+${p.x2})/2.0] [expr (${p.y1}+${p.y2})/2.0]]
	  # If direction was not specified in the lef file, what to do?  Make a local label.
	  if {$pin_dir == ""} {set pin_dir local}
	  db_label -no_notify -cell $cellname -kind $pin_dir ${p.layer} $pin_name $cx $cy
	  set did_label 1

	  # Select and delete this connected net.
	  sel_net -point ${p.x1} ${p.y1} ${p.layer}
	  :delete
	}

	# There were no rectangles in the cell.  Put label in the center of the cell.
	if {!$did_label} {
	    db_label -no_notify -cell $cellname -kind $pin_dir space $pin_name $centerx $centery
	    # 12/10/01 bug fix: labels are *much* faster if they are not in exactly the same spot
	    set centerx [uusnap [expr $centerx + 0.001]]
	}
      }

      edit_pop_direct
      db_cell_delete $tmpcell


      foreach rect $obslist {
	setl {layer x1 y1 x2 y2} $rect
	  set x1 [expr $x1 + $x_offset]
	  set x2 [expr $x2 + $x_offset]
	  set y1 [expr $y1 + $y_offset]
	  set y2 [expr $y2 + $y_offset]

	# Figure out what the max layer is for the specified LEF layer.
	set maxlayer ""
	if {$use_obs_layers} {
	  set obs_layer ${layer}_obs
	  if {! [info exists LEF_LAYER($obs_layer)]} {
	    set LEF_LAYER($obs_layer) [techinfo layer $obs_layer "" opt]
	  }
	  set maxlayer $LEF_LAYER($obs_layer)
	}

	if {$maxlayer == ""} {
	  if {! [info exists LEF_LAYER($layer)]} {
	    set LEF_LAYER($layer) [techinfo layer $layer "" opt]
	    if {$LEF_LAYER($layer) == ""} {
		msg "error: unrecognized layer in lef file ignored: $layer\n"
	    }
	  }
	  set maxlayer $LEF_LAYER($layer)
	}

	if {$maxlayer != ""} {
	  db_paint -no_notify -cell $cellname $maxlayer $x1 $y1 $x2 $y2
	}
      }

      db_prop -def $cellname cell_type lef

      # The IBM cells drop vias in as obstructions.  This results in multiple
      # labels on the same net.  Fix that now.
      db_notify -cell $cellname
      lef_label_remove_dups $cellname

    } always {
      db_notify -cell $cellname
      undo_enable
    }
  }
}




###############################################################
### WRITE LEF
###############################################################


proc _fplan_write_lef_macro {fd cell} -desc {
  Write lef for a floorplan block.  Does NOT work for stdcells.
} {
  global _FPLAN_WRITE_LEF_OPTS

  set mod [fplan_unfix_name $cell]

  # Lef header
  puts $fd "MACRO $mod"
  puts $fd "\tCLASS BLOCK ;"
  puts $fd "\tFOREIGN $mod 0 0 ;"   ;# uh, what is this?
  setl {bx1 by1 bx2 by2} [fplan_bbox -cell $cell]
  puts $fd "\tSIZE [expr $bx2 - $bx1] BY [expr $by2 - $by1] ;"
  puts $fd "\tSYMMETRY X Y ;"
  puts $fd "\tSITE CORE1 ;"

  # Output I/O pins.
  foreach lab_info [db_search_l labels -cell $cell -non_hier] {
    struct max_label l $lab_info
    switch -- ${l.kind} {
      input -
      output -
      inout {
	set layer ${l.layer}
	if {$layer == "space"} {
	  max_error -buffer "write_lef: warning: no layer specified for cell $cell pin ${l.text}, using m1"
	  set layer m1
	}
	set lap [uusnap -mask [expr [techinfo min_width $layer] / 2.0]]
	set pinname [fplan_unfix_name -label ${l.text}]

	puts $fd "\tPIN $pinname"
	puts $fd "\t\tDIRECTION [string toupper ${l.kind}] ;"
	puts $fd "\t\tUSE SIGNAL ;"
	puts $fd "\t\tPORT"
	puts $fd "\t\t\tLAYER [string toupper $layer] ;"
	puts $fd "\t\t\tRECT [expr ${l.x1} - $lap] [expr ${l.y1} - $lap] [expr ${l.x1} + $lap] [expr ${l.y1} + $lap] ;"
	puts $fd "\t\tEND"
	puts $fd "\tEND $pinname"
      }
    }
  }

  # Gather up all obstructions into an array obstructions().


  # Cover the cell with obstructions on these layers
  # to prevent anything from being placed or routed over it.
  foreach layer $_FPLAN_WRITE_LEF_OPTS(cover_obs) {
    setl {snapa(x) snapa(y) offseta(x) offseta(y)} [wire_get_grid $layer]
    if {$snapa(x) == ""} {
      set tmp [expr [techinfo min_width $layer] + [techinfo spacing $layer $layer]]
      setl {snapa(x) snapa(y) offseta(x) offseta(y)} [list $tmp $tmp 0 0]
    }

    # Move the cover obstruction one grid from the ports, which may already in by the offset,
    # which is typically 1/2 grid.  So the obstruction is typically 1.5 grids from cell edge.
    set sepx [expr $snapa(x) + $offseta(x)]
    set sepy [expr $snapa(y) + $offseta(y)]

    # Shrink the obstruction a little so it does not cover ports on the edge.
    lappend obstructions($layer) [list [expr $bx1+$sepx] [expr $by1+$sepy] [expr $bx2-$sepx] [expr $by2-$sepy]]
  }

  # Look for obstruction layers
  foreach mlayer [techinfo layers metal] {
    if {[msg_catch {db_search_l paint -cell $cell ${mlayer}_obs} paintballs junk junk]} {
      # This obstruction layer was not defined in the tech file.  Ignore it.
      continue
    }

    foreach paint_info $paintballs {
      struct max_paint p $paint_info
      lappend obstructions($mlayer) [list ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
    }
  }

  # Output obstructions array.
  set obslayers [array names obstructions]

  if {[llength $obslayers] != 0} {
    puts $fd "\tOBS"
    foreach layer $obslayers {
      puts $fd "\t\tLAYER [string toupper $layer] ;"
      foreach thing $obstructions($layer) {
	setl {x1 y1 x2 y2} $thing
	puts $fd "\t\tRECT $x1 $y1 $x2 $y2 ;"
      }
    }
    puts $fd "\tEND" ;# end of obstructions.
  }

  puts $fd "END $mod"
}

proc load_options {array_name interactive} -desc {
  If ! $interactive, load specified array with proc options.
  If $interactive, init the array only on the first call.
} {
  # The __proc_options in the caller are set transparently when the proc
  # is invoked to the options of the proc.  Its done by the replacement
  # "proc" function defined in doc0.tcl
  upvar __proc_options proc_options
  global $array_name

  foreach thingy $proc_options {
    # The format of proc_options is [list {option default} ...]
    set option [lindex $thingy 0]  ;# Get the option name.
    upvar $option this_option
    if {$interactive} {
      # For interactive use in menus, the array_name is persistent.
      # Init the array to the default values, only if not doen previously.
      use_init [set array_name]($option) $this_option
    } else {
      # Non-interactive.  No persistent options.
      # Set all elements of array_name to the options
      # specified on the command line.
      set [set array_name]($option) $this_option
    }
  }
}


proc fplan_write_lef {{-obstructions 1} {-cover_obs "m1 m2"} {cell ""}} -desc {
  Write a LEF for the specified cell.
} -doc {
  If -obstructions 1, the LEF file will contain obstructions.
  If -cover_obs specified, it is a space separated list of layers.
	Will place LEF obstructions over the entire cell on these layers,
	less a sliver around the edge to avoid covering ports.
} {
  global FPLAN _FPLAN_WRITE_LEF_OPTS

  # Note: This is an experimental way to convert proc -options
  # into an array of options.  The __proc_options is set when
  # the proc starts to the list of options and their defaults.
  load_options _FPLAN_WRITE_LEF_OPTS [expr {$cell == ""}]

  if {0} {
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      if {$cell == ""} {
	# Show interactive menu.  Init options to defaults on first pass.
	use_init _FPLAN_WRITE_LEF_OPTS($option) [lindex $thingy 1]
      } else {
	# Cell specified.  Do not use persistent options;
	# set all options to those given on command line.
	set _FPLAN_WRITE_LEF_OPTS($option) [set $option]
      }
    }
  }

  if {$cell == ""} {
    set cellid [_fplan_ask_cell "write lef"]
    if {$cellid == ""} {return}
    set cell [expr {$cellid == "." ? [lay_editcell] : [cell_id2cell $cellid]}]

    set prop_list ""
    set leffile $cell.lef
    set fs_box_props [list -message "LEF file to write" -pattern "*.lef"]
    lappend fs_box_props -filename $leffile

    lappend prop_list [list "LEF File" leffile -filename $fs_box_props]

    lappend prop_list [list "Write obstructions" _FPLAN_WRITE_LEF_OPTS(obstructions) -binary]

    lappend prop_list [list "Full obstruction layers"  _FPLAN_WRITE_LEF_OPTS(cover_obs) \
	-entry -help {Will place LEF obstructions over the entire cell on these layers,\
	less a sliver around the edge to avoid covering ports.}]

    if {[prop_menu2 -title "Write LEF" $prop_list] == 0} {
      return ;# cancelled
    }
  } else {
    set leffile $cell.lef
  }

  set fd [open $leffile "w"]

  unwind_catch {

    _fplan_write_lef_macro $fd $cell

    puts $fd "\nEND LIBRARY"

  } always {
    close $fd
  }
}
