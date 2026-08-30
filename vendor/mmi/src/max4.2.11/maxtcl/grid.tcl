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

set RCSVERSION(grid.tcl) { $Revision: 1.30 $ }

# Note: GRID variables are inputs from the tech file,
# and also used to communicate with the rest of the world.
# The IGRID variable contains all the grid menu stuff.

init_global GRID(ngrids) -default 4 -desc {
  Number of different grid definitions available to user in Grid Menu.
} -doc {
  This variable can only be set in the tech file.
}

# This is here for documentation purposes.  It should be set in the tech file.
# We can not init using [res], because it is not defined yet.
init_global GRID(mask) -default [lindex [mn_units] 1] -desc {
  Manufacturing Mask Grid.
} -doc {
  This variable can only be set in the tech file.
  It can not be changed interactively inside max.
}

init_global GRID(resolution) -default 0.1 -desc {
  Initial value of User Grid.
} -doc {
  This variable provides a way to set the initial grid
  inside the tech file.  Set it to one value for a symmetric
  grid, or to two space-separated values for an asymmetric grid.
  This variable can only be set in the tech file.
  The grid can also be changed with the GRID menu,
  and saved using "Save Options", which will over-ride
  any grid settings in the tech file.
}


init_global GRID(fine_default_size) -default 0.2 -desc {
  Initial value of the visible fine grid.
} -doc {
  This variable provides a way to set the initial grid
  inside the tech file.  Set it to one value for a symmetric
  grid, or to two space-separated values for an asymmetric grid.
  This variable can only be set in the
  tech file; to change the grid in your max.rc file,
  see the lay_grid command.  The grid can also be changed
  with the GRID menu, and saved using "Save Options",
  which will over-ride any grid settings in either the
  tech file or the max.rc file.
}

init_global GRID(coarse_default_size) -default 1 -desc {
  Initial value of the visible coarse grid.
} -doc {
  This variable provides a way to set the initial grid
  inside the tech file.  Set it to one value for a symmetric
  grid, or to two space-separated values for an asymmetric grid.
  This variable can only be set in the tech file;
  to change the grid in your max.rc file, see the lay_grid command.
  The grid can also be changed with the GRID menu, and saved
  using "Save Options", which will over-ride any grid settings in
  either the tech file or the max.rc file.
}

init_global IGRID(current) -default 1 -desc {
  Current grid in use.  Must be a number: 1, 2, ..., GRID(ngrids)
} -doc {
  internal to grid code
} -flags internal

init_global IGRID(toggle) -default 0 -desc {
  Is grid currently on or off?
} -doc {
  IGRID is the max internal data-base for current grid info.\
  It is the array that is saved to/restored from the preferences file.\
  Note: the GRID variable is for use by the user and by other modules.
  The number of grids is taken from GRID(ngrids). \
  The grid_init proc initializes IGRID, if necessary, so that grids\
  1 .. GRID(ngrids) are ready for use.\

  IGRID contains:  ($g is grid number.  $w is "fine" or "coarse")\

  IGRID(current) - the currently active grid.\

  IGRID(toggle) - Over-all grid control, hooked to g key:\
    If 1, grids will be visible depending on IGRID($g,$w,visibility)\

  IGRID($g,$w,visibility) - Controls how the grid will be displayed,\
    if visible.  Possible values: "off"  "lines"  "dots". \

  IGRID($g,prop_mode) - Controls whether the grid prop menu will\
    be long or short form.  Values: normal or detailed.\
    This also controls how the grid is initialized, because if\
    it is "normal", many of the IGRID values, eg, for assymetric grids,\
    are ignored.\

  IGRID($g,userx) IGRID($g,usery) - User grid.\
    userx used in both dirs if prop_mode==normal.\

  IGRID($g,$xx,sizex) IGRID($g,$xx,sizey) - Grid size.\
    userx used in both dirs if prop_mode==normal.\

  IGRID($g,$xx,originx) IGRID($g,$xx,originy) - Grid origin.\
    userx used in both dirs if prop_mode==normal\

  IGRID($g,$xx,dotsize) - Size of dots if in dot mode.\
} -flags internal


proc toggle_grid {{value ""}} -desc {
  toggle grid on or off
} -doc {
    If value is "off" or "on", set grid visibility accordingly.
} {

  global IGRID
  set g $IGRID(current)

  switch -- $value {
    off { set IGRID(toggle) 0 }
    on  { set IGRID(toggle) 1 }
    default { set IGRID(toggle) [expr ! $IGRID(toggle)] }
  }

  if { $IGRID(toggle) } {
    # Turn on if visible
    msg "grid now on\n"
    if {$IGRID($g,fine,visibility) != "off"} {
      lay_grid fine visibility 1
    }
    if {$IGRID($g,coarse,visibility) != "off"} {
      lay_grid coarse visibility 1
    }
  } else {
    # Turn off
    lay_grid fine visibility 0
    lay_grid coarse visibility 0
    msg "grid now off\n"
  }
}

proc grid_init {} -desc {
  Init the max grid from the GRID variables set in the tech file.
} -doc {
  Called once at start-up.
  Note: GRID(userx) and GRID(usery) are outputs used
  by uusnap and res procs, and GRID(mask) is set, it it is not already.
  Other GRID variables are inputs from the tech file.
  The grid initialization sequence is kind of tricky, because
  the grid can be set in several ways:
  in the tech file using the GRID variables defined in the documentation; 
  in the preferences file (IGRID variables);
  in the max.rc file using the lay_grid command.
} {
  global IGRID GRID

  global _GRID_TMP
  #if { [info exists _GRID_TMP(grid_inited)] } {
  #  max_error "error: grid_init again"
  #  return
  #}
  #set _GRID_TMP(grid_inited) 1

  set minres [lindex [mn_units] 1]

  # This statement duplicates the init_global at the top of this file,
  # but is here to be extra safe.
  set GRID(ngrids) [use_first GRID(ngrids) '4]

  # default the mask grid to the resolution if not set
  set GRID(mask) [use_first GRID(mask) '$minres]

  # Validate the mask grid.  It must be larger than minres
  # and an exact multiple of the maximum internal resolution.
  set ongrid [max $minres [expr round($GRID(mask) / $minres) * $minres]]
  if { [approx $ongrid != $GRID(mask)] } {
    set GRID(mask) $ongrid
    msg "GRID(mask) mask grid specified in tech file is not divisible\
      by $minres, setting to $ongrid\n"
  }

  # Set user grid.  GRID(resolution) is input from the tech file;
  # GRID(userx) and GRID(usery) are the outputs to res and uusnap.
  # GRID(resolution) can be one value (symmetric grid)
  # or two values (asymmetric grid).
  setl {x y} [use_first GRID(resolution) '$minres]

  set GRID(userx) $x
  if { $y != "" } {
    set GRID(usery) $y
  } else {
    set GRID(usery) $x
  }

  # Validate user grid
  foreach name [list userx usery] {
    # Make sure user design grid is greater than mask grid
    # and an exact multiple of the mask grid.
    set ongrid [max $GRID(mask) \
      [expr round($GRID($name) / $GRID(mask)) * $GRID(mask)]]
    if { [approx $ongrid != $GRID($name)] } {
      set GRID($name) $ongrid
      msg "user grid specified in tech file is not divisible by Mask Grid,\
	setting to $ongrid\n"
    }
  }

  # Init the visible grids.
  setl {coarse_x coarse_y} [use_first GRID(coarse_default_size) '1]
  if { $coarse_y == "" } { set coarse_y $coarse_x }
  set coarse_x [max $minres $coarse_x]
  set coarse_y [max $minres $coarse_y]
  lay_grid coarse rect 0 0 $coarse_x $coarse_y

  setl {fine_x fine_y} [use_first GRID(fine_default_size) '0.2]
  if { $fine_y == "" } { set fine_y $fine_x }
  set fine_x [max $minres $fine_x]
  set fine_y [max $minres $fine_y]
  lay_grid fine rect 0 0 $fine_x $fine_y


  # Init the IGRID array.
  # This is done before loading the preferences file,
  # so these values will be over-ridden by the preferences file.

  set IGRID(current) [use_first IGRID(current) '1]
  set IGRID(toggle) [use_first IGRID(toggle) '0]

  for {set g 1} {$g <= $GRID(ngrids)} {incr g} {
    set IGRID($g,name) [use_first IGRID($g,name)]
    set IGRID($g,prop_mode) [use_first IGRID($g,prop_mode) 'normal]
    set IGRID($g,userx) [use_first IGRID($g,userx) GRID(userx)]
    set IGRID($g,usery) [use_first IGRID($g,usery) GRID(usery)]

    # visibility can be: off, lines, dots.
    set IGRID($g,coarse,visibility) \
	    [use_first IGRID($g,coarse,visibility) 'lines]
    set IGRID($g,fine,visibility) \
	    [use_first IGRID($g,fine,visibility) 'lines]

    foreach xx {fine coarse} {
      set IGRID($g,$xx,sizex) [use_first IGRID($g,$xx,sizex) \
	    IGRID(1,$xx,sizex) ${xx}_x '1]
      set IGRID($g,$xx,sizey) [use_first IGRID($g,$xx,sizey) \
	    IGRID(1,$xx,sizey) ${xx}_y '1]
      set IGRID($g,$xx,originx) [use_first IGRID($g,$xx,originx) \
	    IGRID(1,$xx,originx) '0]
      set IGRID($g,$xx,originy) [use_first IGRID($g,$xx,originy) \
	    IGRID(1,$xx,originy) '0]
      set IGRID($g,$xx,dotsize) [use_first IGRID($g,$xx,dotsize) '2]
    }
  }
}

proc _grid_update_var {var val} {
  global $var
  if { [set $var] != $val } {
    set $var $val
    lay_changed
  }
}


proc grid_update {} -desc {
  set max grid from the IGRID array; IGRID is created by Grid Menu or preferences file.
} {
  global GRID IGRID
  global LAY_GRID_POINT_DIAMETER_FINE
  global LAY_GRID_POINT_DIAMETER_COARSE
  global LAY_GRID_MIN_PIXEL_PITCH_COARSE
  global LAY_GRID_MIN_PIXEL_PITCH_FINE

  set g $IGRID(current)

  foreach xx {coarse fine} {
    if { $IGRID($g,prop_mode) == "detailed" } {
      set x1 $IGRID($g,$xx,originx)
      set y1 $IGRID($g,$xx,originy)
      set x2 [expr $IGRID($g,$xx,originx) + $IGRID($g,$xx,sizex)]
      set y2 [expr $IGRID($g,$xx,originy) + $IGRID($g,$xx,sizey)]
    } else {
      # sizex contains the size for both x and y directions, and origin 0,0.
      set x1 0
      set y1 0
      set x2 $IGRID($g,$xx,sizex)
      set y2 $IGRID($g,$xx,sizex)
    }

    # Dont do it unless needed, or a redraw will be forced.
    if {[lay_grid $xx rect] != "$x1 $y1 $x2 $y2" } {
      lay_grid $xx rect $x1 $y1 $x2 $y2
    }

    set dotsize 0
    if { $IGRID($g,$xx,visibility) == "dots" } {
	set dotsize $IGRID($g,$xx,dotsize)
    }
    if { $xx == "coarse" } {
	_grid_update_var LAY_GRID_POINT_DIAMETER_COARSE $dotsize
	_grid_update_var LAY_GRID_MIN_PIXEL_PITCH_COARSE [expr 6 + 2 * $dotsize]
    } else {
	_grid_update_var LAY_GRID_POINT_DIAMETER_FINE $dotsize
	_grid_update_var LAY_GRID_MIN_PIXEL_PITCH_FINE [expr 6 + 2 * $dotsize]
    }

    # Dont call lay_grid unless necessary, or a redraw will be forced.
    set oldvis [lay_grid $xx visibility]
    if { $IGRID($g,$xx,visibility) == "off" || $IGRID(toggle) == 0 } {
	if { $oldvis != 0 } { lay_grid $xx visibility 0 }
    } else  {
	if { $oldvis != 1 } { lay_grid $xx visibility 1 }
    }
  }

  # Communicate current user grid resolution to the rest of the world.
  set GRID(userx) $IGRID($g,userx)
  if { $IGRID($g,prop_mode) == "detailed" } {
    set GRID(usery) $IGRID($g,usery)
  } else {
    # User x grid specifies both x and y grids.
    set GRID(usery) $IGRID($g,userx)
  }
}

proc grid_select {num} -desc {
  Activate the specified grid.
} {
  global IGRID GRID
  if { $num < 0 || $num > $GRID(ngrids) } {
    max_error "grid_select: error: grid_select $num is greater than GRID(ngrids) ($GRID(ngrids)) -\
      GRID(ngrids) may be set in your technology file"
    return
  }
  set IGRID(current) $num
  grid_update
  if { $IGRID(toggle) == 0 } {
    set msg "Selected grid $num.  Note: grid visibility is currently off\n"
  } else {
    set msg "Selected grid $num.\n"
  }
  msg $msg
}

proc grid_find_named {name} -desc {
  deprecated.  see grid_get
} {
  global GRID IGRID
  if {[regexp {^[0-9]+$} $name]} {
    return [grid_get -number $name]
  } else {
    return [grid_get -name $name]
  }
}

proc grid_get {{-name ""} {-number ""}} -doc {
  Return value is {userx usery 0 0}
  The two zeros are reserved for offsets, which are not currently supported.
  Return "" if not found.
} {
  global GRID IGRID
  # If no -name or -number, set current grid.
  set gridno $IGRID(current)

  if {$number != ""} {
    set gridno $number
    if {$name != ""} {
      error "grid_get: error: -name and -number are mutually exclusive"
    }
  }

  if {$name != ""} {
    set fndgrid -1
    for {set g 1} {$g <= $GRID(ngrids)} {incr g} {
      if {$IGRID($g,name) == $name} {
	set fndgrid $g
	break
      }
    }
    if {$fndgrid == -1} {
      return ""
    }
    set gridno $fndgrid
  }

  # Check if named grid was found.
  if {![info exists IGRID($gridno,userx)]} { return "" }

  # Note: originx/originy not supported yet.
  #foreach thing "userx usery originx originy"
  foreach thing "userx usery" {
    set $thing $IGRID($gridno,$thing)
  }

  if { $IGRID($gridno,prop_mode) != "detailed" } {
    set usery $userx
    #set originy $originx
  }
  return [list $userx $usery 0 0]
}

proc grid_set {{-name ""} {-number ""} gridx gridy {offsetx 0} {offsety 0}} {
  global IGRID GRID
  # If no -name or -number, set current grid.
  set gridno $IGRID(current)
  if {$number != ""} {
    set gridno $number
    if {$name != ""} {
      error "grid_set: error: -name and -number are mutually exclusive"
    }
  }

  if {$name != ""} {
    set fndgrid -1
    for {set g 1} {$g <= $GRID(ngrids)} {incr g} {
      if {$IGRID($g,name) == $name} {
	set fndgrid $g
	break
      }
    }
    if {$fndgrid == -1} {
      error "grid_set: error: grid named \"$name\" not found"
    }
    set gridno $fndgrid
  }
  set IGRID($gridno,userx) $gridx
  set IGRID($gridno,usery) $gridy
  if {$gridx != $gridy} {
    set IGRID($gridno,prop_mode) "detailed"
  }
}

proc _grid_save {} -desc {
  Called from grid menu to save options.
} {
  set filename [max_local_pref_file_name]
  set message "Save Grid Setup options to file: $filename ?"
  set choice [tk_dialog .dialog "WARNING" $message {} 0 \
	      Yes Cancel]
  if { $choice != 0 } { return }
  misc_save_config IGRID
}

proc _grid_load {} -desc {
  Called from grid menu to load options.
} {
  set message "Revert Grid Setup to factory default options?"
  set choice [tk_dialog .dialog "WARNING" $message {} 0 \
	      Yes Cancel]
  if { $choice != 0 } { return }
  global IGRID
  unset IGRID
  grid_init
}



proc grid_menu {} -desc {
  prompt for grid spacing and visibility
} {
  global GRID IGRID

  set g $IGRID(current)

  # Removed 9/29
  #toggle_grid on

  foreach name [array names IGRID] {
    set save_grid($name) $IGRID($name)
  }

  # Prop_mode controls the kind of prop menu displayed.
  # Legal values are "normal" and "detailed".
  set IGRID($g,prop_mode) [use_first IGRID($g,prop_mode) 'normal]

  # Sync up the current grid with any changes entered via
  # lay_grid commands.  This also indirectly retrieves
  # GRID(fine_default_size) and GRID(coarse_default_size), which
  # are used to init the grid at start up.
  # Note that the current grid visibility is ignored: it must not
  # affect the menu settings, which specify what you want when you say "g".
  foreach xx {fine coarse} {
      setl {fx1 fy1 fx2 fy2} [lay_grid $xx rect]
      # If the grid is non-rectangular, or with non-zero origin,
      # must use detailed mode.  This happens if user moved grid manually.
      if { $fx1 != 0 || $fy1 != 0 || \
	 $fy2 - $fy1 != $fx2 - $fx1 } { set IGRID($g,prop_mode) detailed }
      set IGRID($g,$xx,originx) $fx1
      set IGRID($g,$xx,originy) $fy1
      set IGRID($g,$xx,sizex)   [expr $fx2 - $fx1]
      set IGRID($g,$xx,sizey)   [expr $fy2 - $fy1]
  }

  while {1} {
      set g $IGRID(current)
      set prop_list ""

      set gridnames ""
      set gridnums ""
      for {set i 1} {$i <= $GRID(ngrids)} {incr i} {
	set name $IGRID($i,name)
	if {$name != ""} {
	  append gridnames "{Grid $i: $name} "
	} else {
	  append gridnames "{Grid $i:} "
	}
	append gridnums "$i "
      }
      lappend prop_list \
	  [list {Grid Number} IGRID(current) -radio "$gridnames" \
	      -values "$gridnums" -return 2 \
	      -help {Max maintains information for several different grids. \
	      This option controls which grid is the current grid. \
	      The information on the current grid is\
	      displayed in this menu.  You can set up the grids differently\
	      and then switch between them rapidly\
	      using this menu, or using hot-keys.\
	      (The default hot-keys are: 1, 2, 3, 4.)}]

      lappend prop_list \
	  [list {Grid visibility:} IGRID(toggle) \
	    -enum {off on} \
	    -help {Determines if visible grid is currently on or off.\
	    Can be changed by the "Toggle Grid" command in the View menu.}]

      lappend prop_list \
	  [list {Specify Grid Set Up ...}  IGRID($g,prop_mode) \
	      -choice {normal detailed} -reload \
	      -help {If set to "normal", only basic grid options are\
	      displayed in this menu. \
	      If set to "detailed", all available grid options are displayed.}]

      lappend prop_list "{} {} -separator"

      lappend prop_list \
	  [list {Grid Name:} IGRID($g,name) -entry \
	    -help {Grid name is for user convenience.  If a cell has\
	    a grid property, the named grid is used when moving the cell.}]

      # The user grid can not be validated by prop_menu,
      # because the -incr GRID(mask) can be changed in the
      # same prop menu.  It is validated below.
      set user_grid_prop "-number [res -mask] -incr [res -mask] \
	  -snap [max .01 [res -mask]]"
      set size_prop "-number [res] -incr [res] \
	  -snap [max .1 [res -mask]] -validate"
      set offset_prop "-number -incr [res] \
	  -snap [max .1 [res -mask]] -validate"

      lappend prop_list "{USER DESIGN GRID NUMBER $g} {} -label"

      lappend prop_list \
	  "{User Design Grid X} IGRID($g,userx) $user_grid_prop \
	  -when {\$IGRID($g,prop_mode) == {detailed}} \
	  -help {points and rectangles entered by the mouse will\
	      snap to this resolution in the X direction}"
      lappend prop_list \
	  "{User Design Grid Y} IGRID($g,usery) $user_grid_prop \
	  -when {\$IGRID($g,prop_mode) == {detailed}} \
	  -help {points and rectangles entered by the mouse will \
	      snap to this resolution in the Y direction}"
      lappend prop_list \
	  "{User Design Grid} IGRID($g,userx) $user_grid_prop \
	  -when {\$IGRID($g,prop_mode) == {normal}} \
	  -help {points and rectangles entered by the mouse will \
	      snap to this resolution}"

      lappend prop_list "{} {} -separator"

      lappend prop_list "{VISIBLE GRID NUMBER $g} {} -label"

      foreach xx {coarse fine} {
	lappend prop_list \
	      "{$xx visibility} IGRID($g,$xx,visibility) \
	      -choice {off lines dots} \
	      -help {show a $xx grid when grid is on and zoomed in far enough}"

	lappend prop_list \
	      "{$xx grid size X} IGRID($g,$xx,sizex) $size_prop \
	      -when {\$IGRID($g,prop_mode) == {detailed}} \
	      -help {size of $xx grid in X direction, if visible}"
	lappend prop_list \
	      "{$xx grid size Y} IGRID($g,$xx,sizey) $size_prop \
	      -when {\$IGRID($g,prop_mode) == {detailed}} \
	      -help {size of $xx grid in Y direction, if visible}"
	lappend prop_list \
	      "{$xx grid origin X} IGRID($g,$xx,originx) $offset_prop \
	      -when {\$IGRID($g,prop_mode) == {detailed}} \
	      -help {origin of $xx grid in X direction}"
	lappend prop_list \
	      "{$xx grid origin Y} IGRID($g,$xx,originy) $offset_prop \
	      -when {\$IGRID($g,prop_mode) == {detailed}} \
	      -help {origin of $xx grid in Y direction}"
	lappend prop_list \
	      "{$xx dot size} IGRID($g,$xx,dotsize) \
	      -number 1 1000 -incr 1 -validate \
	      -when {\$IGRID($g,prop_mode) == {detailed}} \
	      -help {size of grid dots if grid type is dots}"
	# If prop_mode==normal, its a square grid:
	# use sizex for the size in both directions.
	lappend prop_list \
	      "{$xx grid size} IGRID($g,$xx,sizex) $size_prop \
	      -when {\$IGRID($g,prop_mode) == {normal}} \
	      -help {size of $xx grid, if visible}"
      }

      lappend prop_list "{} {} -separator"
      lappend prop_list "{OTHER GRID PARAMETERS}  {} -label"

      # Cant do this yet in normal version of max because
      # prop_menu does not support -label with args
      lappend prop_list \
	"{Manufacturing Mask Grid} GRID(mask) -label \
	-help {the minimum feature size determined by the\
	manufacturing process; this value \
	is set in the tech file.}"


      lappend prop_list [list "Edit Wiring Grid ..." {} \
	      -button wire_grid_menu]
      
      #lappend prop_list [list " Save Options... " {} -button _grid_save \
      #	-options {-expand 0 -side left -ipady 1 -padx 3m} -align center]
      #lappend prop_list [list " Revert Options... " {} -button _grid_load \
      #	-return 2 \
      #	-beside -options {-expand 0 -side left -ipady 1 -padx 3m} -align center]

      # create the menu
      set title "Grid Setup"
      #set buttons "Done=0=default Apply==apply Save...==_grid_save \
      #	Load...==_grid_load Cancel=0=cancel"
      set ret [prop_menu2 -title $title -apply grid_update $prop_list]
      # If user hit cancel.
      if { $ret == 0 } {
	# The prop menu undid all changes to the current grid.
	#foreach name [array names IGRID] {}
	#  set IGRID($name) $save_grid($name)
	#{}
	return
      }

      # Make sure the user grid is divisible by mask grid.
      # Comment obsolete: The -validate in prop_menu does not work because
      # what we are validating against (the mask grid) can be
      # changed in the same menu.
      set bad_grid 0
      if {$IGRID($g,prop_mode) == "detailed"} {
	set list [list userx usery]
      } else {
	set list [list userx]
      }
      foreach name $list {
	set ongrid [max $GRID(mask) \
	  [expr round(1.0 * $IGRID($g,$name)/$GRID(mask)) * $GRID(mask)]]
	if { [approx $ongrid != $IGRID($g,$name)]} {
	  set message "User Grid not divisible by Manufacturing Mask Grid. \
	    This will allow creation of unmanufacturable features. \
	    Are you sure you want to set the grid this small?"
	  set choice [tk_dialog .dialog "WARNING" $message {} 0 \
	      Yes Cancel]
	  if { $choice != 0 } {
	    # user hit the cancel button.  Let them try again.
	    set bad_grid 1
	    # Keep editing the same grid until they get it right.
	    set IGRID(current) $g
	  }
	  break
	}
      }
      if { $bad_grid } { continue }

      if { $ret == 2 } { grid_update; continue }

      break
  }

  if {0} {
    # No longer allow people to change the mask grid.
    if { $GRID(mask) != $save_grid(mask) } {
      set message "WARNING:  You have asked to change the\
      Manufacturing Mask grid. \
      Changing the Mask grid may result in manufacturing DRC violations.\
      If you later save the grid setup, this change will be permanent!\
      Are you SURE you want to change the Manufacturing Mask Grid?"
      set choice [tk_dialog .dialog "warning " $message {} 0 \
	      Yes Cancel]
      if { $choice != 0 } {
	# user hit the cancel button. Restore all main grids, just in case.
	foreach name [array names IGRID] {
	  set IGRID($name) $save_grid($name)
	}
	set GRID(mask) "Need to save this on entry to this function???"
	msg "Restoring Manufacturing Mask Grid\n"
      } else {
	msg "Manufacturing Mask Grid Changed!\n"
      }
    }
  }


  grid_update
}


proc grid_move_enter {} -desc {
  move grid origin with mouse
} {
  # ignore if there is already a button down, or recursive entry
  if { [button_down] != {} || [mode_current] == "grid_move" } { 
      return
  }
  mode_push grid_move
}


proc _grid_move_define {} -desc {
  move grid origin
} {
    mode_def grid_move _grid_move_gate_keeper \
	"BUT-1 drags grid origin"

    mode_bind -cmd 0 grid_move <Any-Button-1> _grid_move_origin_setup
    mode_bind -cmd 0 grid_move <Any-B1-Motion> _grid_move_origin
    mode_bind -cmd 0 grid_move <Any-ButtonRelease> mode_pop
}


proc _grid_move_gate_keeper {event} -desc {
    called whenever grid_move mode is entered/exited
} {
  global mode_abort GRID_MOVE

  if {$event == "PUSH_TO"} {
    pan_enable
      
    # save the grid so we can restore if aborted
    set GRID_MOVE(fine,save) [lay_grid fine rect]
    set GRID_MOVE(coarse,save) [lay_grid coarse rect]

  } elseif {$event == "POP_FROM"} {
    pan_disable

    if { $mode_abort } {
      # reset the grid
      eval lay_grid fine rect $GRID_MOVE(fine,save)
      eval lay_grid coarse rect $GRID_MOVE(coarse,save)
    }
    # If user types Control-C during move grid, we want to
    # abort the move-grid, but not the submode that called it, if any.
    set mode_abort 0

    # Update screen, but do not add an undo delimiter: there
    # is nothing to undo!
    i_cmd_between_undos
  }
}


proc _grid_move_origin_setup {} -desc {
  move grid from cursor position
} {
  global GRID_MOVE

  setl {GRID_MOVE(x) GRID_MOVE(y)} [layt_point user]
}


proc _grid_move_origin {} -desc {
  move grid
} {
  global GRID_MOVE

  # 4/16: Dont want pan for grid move!
  #pan_auto _grid_move_origin

  setl {x y} [layt_point user]

  set dx [expr $x - $GRID_MOVE(x)]
  set dy [expr $y - $GRID_MOVE(y)]

  #set GRID_MOVE(x) $x
  #set GRID_MOVE(y) $y

  foreach type "fine coarse" {
    setl {x1 y1 x2 y2} $GRID_MOVE($type,save)
    setl {x1 y1} [uusnap -user [expr $x1 + $dx] [expr $y1 + $dy]]
    setl {x2 y2} [uusnap -user [expr $x2 + $dx] [expr $y2 + $dy]]
    lay_grid $type rect $x1 $y1 $x2 $y2
  }
}


