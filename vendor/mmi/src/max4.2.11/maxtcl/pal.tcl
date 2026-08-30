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

set RCSVERSION(pal.tcl) { $Revision: 1.60 $ }

# procs to build and manipulate palette widget.
#
# palette/colors code broken up as follows:
#   pal.tcl             - procs to build and manipulate palette widget.
#   pal_file.tcl        - procs to read/write .palette file. 
#   colors.tcl          - procs to setup layout widget colors/styles 
#   color_editor.tcl    - builds widget for editing layer colors/styles

# TODO document with init_global
global PAL
set PAL(font_entry) {-*-helvetica-bold-r-normal--*-100-*}
set PAL(single_pixel_threshold_slow) 4
set PAL(single_pixel_threshold_fast) 10
set PAL(disabled_color) #e0e0e0
set PAL(special_layers) "annotation background bbox box drc feedback flyline grid label selection"

# set when too many layers for transparency (solid layers)
set PAL(stipple_only) 0

# the PAL_DATA global array gets unset on revert or whenever and
# other major change is made to the colors.

proc pal_layers {} -desc {
    Return a list of the layers in the palette.
} {
    global PAL
    return $PAL(layers)
}

proc pal_update {} -desc {
  update display of palette to reflect current state
} -doc {
    should be called inside max_periodic_update so that updates will be
    made several times per second.
} {
  global max_win PAL
    
  setl {x y} [layt_point exact]
  set vis [dbt_visible_layers]
  set sel [sel_what types]
  set touched [db_search touchingtypes $x $y]

  foreach entry $PAL(layers) {
    set lname [dbt_long_name $entry]

    # only consider current layers in palette
    if {![info exists PAL(widget.$entry)] || \
	    [lsearch $PAL(widgets) $PAL(widget.$entry)] == -1} {
      continue
    }

    set widget $PAL(widget.$entry)

    # visible?
    set index [lsearch $vis $lname]
    if {$index != -1} {
      #VISIBLE
      pack $widget.lf.l
    } else {
      #NOT VISIBLE
      pack forget $widget.lf.l
    }
      
    # touched?
    set index [lsearch $touched $lname]
    if {$index != -1} {
      #TOUCHED BY CURSOR
      $widget.cursed configure -bg red
      set i_am_touched 1
    } else {
      # NOT TOUCHED BY CURSOR
      $widget.cursed configure -bg bisque
      set i_am_touched 0
    }

    # selected?
    set index [lsearch $sel $lname]
    if {$index != -1} {
      #SELECTED
      $widget.b configure -fg red -activeforeground red
    } else {
      #NOT SELECTED
      $widget.b configure -fg black -activeforeground black
    }
  }

  set widget $PAL(pal_widget).cbut
  if {[sel_what cells -boolean]} {
    # SELECTED cells
    $widget configure -fg red -activeforeground red
  } else {
    #NOT SELECTED
    $widget configure -fg black -activeforeground black
  }
}

### visibility toggles

proc pal_visible {layer} -desc {
check if layer is visible
} {
    global max_win
    set lname [dbt_long_name $layer]
    return [memq  [$max_win.layout visible] $lname]
}
    
proc _pal_toggle {layer} -desc {
    toggle visibility of layer
} {
    set vis [pal_visible $layer]
    if {$vis} {
	:see no $layer
    } else {
	:see $layer
    }

    # update is somewhat redundant here (since doing periodic updates)
    # but might as well make it snappy!
    pal_update
}


proc _pal_toggle_selectable {layer} -desc {
  toggle selectability of layer
} {
  global PAL

  if {$layer == "subcell"} {
    # special case
    set widget $PAL(pal_widget).cbut
    if {[set pos [lsearch $PAL(selectable) $layer]] == -1} {
      #MAKE SELECTABLE
      $widget configure -fg black -bg bisque -activeforeground black \
	  -activebackground PeachPuff
      lappend PAL(selectable) $layer
    } else {
      #MAKE NOT SELECTABLE
      $widget configure -fg black -bg grey -activeforeground black \
	  -activebackground LightGrey
      set PAL(selectable) [lreplace $PAL(selectable) $pos $pos]
    } 

  } else {
    set widget $PAL(widget.$layer)
    set lname [dbt_long_name $layer]

    # selectable
    if {[set pos [lsearch $PAL(selectable) $lname]] == -1} {
      #MAKE SELECTABLE
      $widget.b configure -fg black -bg bisque -activeforeground black \
	  -activebackground PeachPuff
      lappend PAL(selectable) $lname

    } else {
      #MAKE NOT SELECTABLE
      $widget.b configure -fg black -bg grey -activeforeground black \
	  -activebackground LightGrey
      set PAL(selectable) [lreplace $PAL(selectable) $pos $pos]
    } 
  }
}

    
proc _pal_group_toggle {group {type visible}} -desc {
  "toggle" visibility/selectability of group
} {
  global PAL PAL_DATA

  if {$group == "all"} {
    if {$type == "visible"} {
      set layers $PAL(layers)
    } else {
      # slightly different for selectable, only layers that are in
      # the palette
      set layers ""
      foreach layer $PAL(layers) {
	if {[info exists PAL(widget.$layer)] && \
		[lsearch $PAL(widgets) $PAL(widget.$layer)] != -1} {
	  lappend layers $layer
	}
      }
    }
  } else {
    set layers [use_first PAL_DATA($group.layers)]
  }

  switch $type {

    visible {

      # check if all on
      set allon no
      foreach layer $layers {
	if {[pal_visible $layer] == 0} {
	  set allon ""
	}
      }

      # if allon turn all off, otherwise turn all on
      foreach layer $layers {
	eval :see $allon $layer 
      }
    }

    select {

      # check if all selectable
      set allon 1
      foreach layer $layers {
	set lname [dbt_long_name $layer]
	if {[lsearch $PAL(selectable) $lname] == -1} {
	  set allon 0
	}
      }

      # if allon turn all off, otherwise turn all on
      if {$allon} {
	foreach layer $layers {
	  _pal_toggle_selectable $layer
	}
      } else {
	foreach layer $layers {
	  set lname [dbt_long_name $layer]
	  if {[lsearch $PAL(selectable) $lname] == -1} {
	    _pal_toggle_selectable $layer
	  }
	}
      }
    }
  }

  pal_update
}


proc _pal_button2 {layer} -desc { 
  executes the button-2 command for the given mode based on PAL(button2).
} {

  global PAL

  if {[mode_current] == "main" || ![info exists PAL(button2)]} {
    # main mode, edit color
    edit_color $layer

    catch {unset PAL(button2)}
    return
  }

  setl {command mode} $PAL(button2)

  # only execute this command if we are still in this mode
  if {[mode_current] == $mode} {
    # do it
    $command $layer

  } else {
    # reset 
    unset PAL(button2)
  }
}


proc _pal_button3 {layer} -desc { 
  executes the button-3 command for the given mode based on PAL(button3).
} {

  global PAL

  if {[mode_current] == "main" || ![info exists PAL(button3)]} {
    # main mode
    i_cmd_eval ":paint $layer"

    catch {unset PAL(button3)}
    return
  }

  setl {command mode} $PAL(button3)

  # only execute this command if we are still in this mode
  if {[mode_current] == $mode} {
    # do it
    $command $layer

  } else {
    # reset 
    unset PAL(button3)
  }
}


###
### ROUTINES TO PAINT PALETTE CELL

proc _pal_paint {} -desc {
paint __PALETTE__ and frame icons on appropriate samples.
} {
  global PAL

  :load __PALETTE__
#  select_q cell
#  :edit
#  select_q clear

  set PAL(x) 0
  set PAL(y) 0

  foreach layer $PAL(layers) {
    _pal_paint_entry $layer
  }
}

proc _pal_paint_entry {entry} { 
    global PAL

    layt_box exact [expr $PAL(x) - $PAL(radius)] [expr $PAL(y) - $PAL(radius)] \
	    [expr $PAL(x) + $PAL(radius)] [expr $PAL(y) + $PAL(radius)]
    :paint $entry
#    $PAL(widget.$entry).lf.l \
	    frame $PAL(x) $PAL(y) \
	    [expr $PAL(x) + $PAL(radius)/2] [expr $PAL(y) + $PAL(radius)/2]

    # Remember the location of this blob of paint so it can be
    # displayed in the Tool Bar layer indicator.
    set PAL([dbt_long_name $entry],loc) "$PAL(x) $PAL(y)"

    set PAL(x) [expr $PAL(x) + 3*$PAL(radius)]
}

###
### ROUTINES TO BUILD PALETTE WIDGET
###

proc _pal_build_entry_layer {layer} -desc {
  build (and pack) palette entry for given layer in palette
} {
  global PAL

  set topf $PAL(pal_widget).l_${layer} 

  lappend PAL(widgets) $topf

  if {[info exists PAL(widget.$layer)]} {
    # already exists just use it
    pack $topf -fill x -pady 0 -side top
    return
  }

  # build it
  set PAL(widget.$layer) $topf

  # ENTRY FRAME
  frame $topf -borderwidth 0
  pack $topf -fill x -pady 0 -side top

  #INDICATOR 
  # (inicates cursor over layer)
  pack [_pal_build_indicate_cursed $topf] -side left

  #LAYOUT WIDGET
  pack [_pal_build_framed_layout $topf $layer] -side left

  #TOGGLE BUTTON for selectable
  set b [_pal_build_cmd_button $topf.b $layer \
	     "_pal_toggle_selectable $layer" \
	     -font $PAL(font_entry) -border 1 -pady 0]
  pack $b -side left -fill both -expand 1

  # button-2 in main mode edits the color
  bind $b <Any-Button-2> "_pal_button2 $layer"
  bind $b <Button-3> "_pal_button3 $layer"
  i_cmd_bind $b <Control-Button-3> ":erase $layer"
  bind $b <Any-Enter> \
      {mode_msg "Palette: BUT-1 toggles selectivity, BUT-2 edit colors/stipples, (Control) BUT-3 paints (erase) this layer" palette"}
  #bind $b <Any-Leave> "mode_msg __RESTORE__ palette"
}


proc _pal_build_indicate_cursed {w} -desc {
  build cursor indicator frame for palette entry  w
} -doc {
  returns new widget
} {
  set f $w.cursed

  frame $f -borderwidth 1 -relief sunken -height 16 -width 5
  
  bind $f <Any-Enter> \
      {mode_msg "Palette: if RED, cursor is over this layer in layout, independent of visibility" palette"}
  #bind $f <Any-Leave> "mode_msg __RESTORE__ palette"

  return $f
}

proc _pal_build_framed_layout {w layer} -desc {
  build layout widget with frame (for sunken relief) under w
} -doc {
  returns new layout widget

  Actually builds frame, and drops layout widget in frame to provide sunken relief.
} {
  global PAL

  set lf $w.lf
  set l $w.lf.l

  frame $lf -borderwidth 1 -relief sunken -height 16 -width 16
  layout $l -special -height 15 -width 15 

  pack $l

  # zoom in on appropriate layer in the palette cell
  set pos [lsearch $PAL(layers) $PAL(name,[dbt_long_name $layer])]
  if {$pos == -1} {
    max_error "INTERNAL PALETTE ERROR, can't find layer $layer."
    return $lf
  }

  set x [expr 3 * $PAL(radius) * $pos]
  set y 0

  set v 0.8
  $l frame \
      [expr $x - $PAL(radius)*$v] [expr $y - $PAL(radius)*$v] \
      [expr $x + $PAL(radius)*$v] [expr $y + $PAL(radius)*$v]

  # bindings 
  bind $l <Enter> "$w.b configure -state active"
  bind $lf <Enter> "$w.b configure -state active"
  bind $l <Leave> "$w.b configure -state normal"
  bind $lf <Leave> "$w.b configure -state normal"

  bind $l <Any-Button-1> "_pal_toggle $layer"
  bind $lf <Any-Button-1> "_pal_toggle $layer"

  bind $l <Any-Button-2> "_pal_button2 $layer"
  bind $l <Button-3> "_pal_button3 $layer"
  i_cmd_bind $l <Control-Button-3> ":erase $layer"
  
  bind $lf <Any-Enter> \
      {mode_msg "Palette: BUT-1 toggles visibility, BUT-2 edit colors/stipples, (Control) BUT-3 paints (erase) this layer" palette"}
  #bind $lf <Any-Leave> "mode_msg __RESTORE__ palette"

  return $lf
}


proc _pal_build_cmd_button {wbut text cmd args} -desc {
  build button with command wrapper and widget name w
} {

  eval {button $wbut \
	    -text $text \
	    -command $cmd \
	    -highlightthickness 0 \
	    -padx 1 -pady 0 \
	  } $args

  return $wbut
}

# Note: pal_special_on/pal_special_off retained for backward
# compatibility for people who used these in their .maxrc files.
proc pal_special_on {entry} -desc {
  Controls display options.
} -doc {
  The option can be one of:
  subcellcommentlabels labels instancenames instanceports flylines
  dimne (Dim Non-Edit Cells) fastdraw drc
} {
    view_state_change $entry 1
}

proc pal_special_off {entry} -desc {
  Controls display options.  See pal_special_on.
} {
    view_state_change $entry 0
}


proc _pal_build_init {} -desc {
  initialize PAL and PAL_DATA array
} {
  global PAL PAL_DATA

  set PAL(radius) [expr 100*[res]]

  set PAL(selectable) subcell

  set PAL(widgets) ""
  set PAL(group_widgets) ""

  # need to save the hidden groups so they can be restored as hidden
  set hidden_groups ""
  foreach hidden [array names PAL_DATA *.hide] {
    regsub {.hide$} $hidden "" hidden
    lappend hidden_groups $hidden
  }

  catch {unset PAL_DATA}

  set PAL_DATA(hidden_groups) $hidden_groups

  set PAL_DATA(compose) ""
  set PAL_DATA(solids) 0
  set PAL_DATA(active_group) ""
  set PAL_DATA(groups) ""
  set PAL_DATA(todo) ""
}


proc pal_load_file {{-string ""} {-file ""}} -desc {
  Load the specified palette file.
} -doc {
  If -string, load palette from specified data.
  If -file, source specified filename.

  Make sure that the palette file has the same layers as the technology file.
  If someone saves a palette and then changes the technology file,
  they will differ.
} {
  global PAL PAL_DATA

  _pal_build_init

  # set this variable so only allow pal commands here
  set PAL(loading) 1

  if {$string == "" && $file == ""} { error "pal_load_file syntax" }

  unwind_catch {

    # execute palette commands
    if {$string != ""} {
      foreach line $string {
	eval $line
      }
    } else {
      source $file
    }

  } always {

    # loading done
    set PAL(loading) 0

  }


  # These layers came from db_types, ie, direct from the technology.
  # Save them in hash.
  foreach layer $PAL(layers) {
    set hash($layer) 1
  }

  # This is a list of the layers specified in the palette file.
  set extra_layers ""
  foreach thing [array names PAL_DATA processed,layer,*] {
    regsub {^processed,layer,} $thing "" layer
    if {[info exists hash($layer)]} {
      unset hash($layer)
    } else {
      lappend extra_layers $layer
    }
  }

  # Now layers in extra_layers were in the palette but not the tech file.
  # Things left over in has were in the tech file but not the palette.

  set errmsg ""
  set missing_layers [array names hash]
  if {[llength $missing_layers] != 0} {
    append errmsg "missing layers = $missing_layers "
  }
  if {[llength $extra_layers] != 0} {
    append errmsg "extra layers = $extra_layers "
  }

  if {$errmsg != ""} {
    set msg "PALETTE ERROR: layers in saved palette file differ from technology file.\n\
      ($errmsg)\n\
      You will not see all layers in the palette until you Revert your palette\n\
      To Revert the palette, start the color editor (press Button-2 over the palette),\
      select \"Revert\", then choose \"System Defaults\""
    
    # 5/01: This should really be a popup, but none of the other palette errors
    # are popups, and what we really want to do is aggregate all the errors
    # into one popup, which there is no facility to do, currently.
    max_error $msg
  }
}

proc pal_build {master} -desc {
  creates palette.  Called at startup.
} {
  global PAL PAL_DATA

  # init PAL array first time.
  # Must be called first to get the PAL(radius) set.
  _pal_build_init

  # figure out the layers to go into the palette
  set PAL(layers) ""
  foreach types [split [db_types] \n] {
    setl {lname layer other_names plane flags} $types
    if {[memq $flags selectable] && ![memq $flags builtin]} {

      # this is a valid layer, put it into the palette cell
      lappend PAL(layers) $layer

      # put in a translation to get to official short name
      set PAL(name,$lname) $layer
    }
  }

  # paint the palette cell!
  _pal_paint

  # create toplevel frame for palette
  set palf ${master}.pal 
  catch "destroy $palf"
  frame $palf -relief flat

  ### column frames
  _pal_build_column_frame $palf

  # Build the actual palette of layers

  # cells button
  set cbut $PAL(pal_widget).cbut
  catch "destroy $cbut"
  _pal_build_cmd_button $cbut "-cells-" "_pal_toggle_selectable subcell"
  bind $cbut <Any-Enter> \
      {mode_msg "Palette: BUT-1 toggles cell selectivity" palette}
  #bind $cbut <Any-Leave> "mode_msg __RESTORE__ palette"
  pack $cbut -fill x -pady 0

  # all button
  set allbut $PAL(pal_widget).allbut
  catch "destroy $allbut"
  _pal_build_cmd_button $allbut "-all-" "_pal_group_toggle all" -fg blue  
  # Pat removed for consistency with other buttons:
  #bind $allbut <Button-2> "_pal_group_toggle all select"
  bind $allbut <Button-3> "_pal_group_toggle all select"
  bind $allbut <Any-Enter> \
      {mode_msg "Palette: BUT-1 toggles all layer visibility, BUT-2/3 toggles all layer selectivity" palette}
  #bind $allbut <Any-Leave> "mode_msg __RESTORE__ palette"
  pack $allbut -fill x -pady 0
  
  # load the palette info from the tech directory
  set filename [max_tech_path palette]

  if {$filename == ""} {
    # no palette file, alert user and bolt
    puts "Aborting, no palette file found\n]"
    mn_exit -nobackup
  }

  puts "Sourcing $filename"
  pal_load_file -file $filename

  # older palette.tcl files have single 'highlite', instead of 'box' etc.
  # If 'highlite' exists, split it out for backward compatibility.
  if {[info exists PAL_DATA(highlite)]} {
      set PAL_DATA(annotation) $PAL_DATA(highlite)
      set PAL_DATA(box) $PAL_DATA(highlite)
      set PAL_DATA(feedback) $PAL_DATA(highlite)
      set PAL_DATA(flyline) $PAL_DATA(highlite)
      set PAL_DATA(selection) $PAL_DATA(highlite)
  }

  # build up the colors and styles
  _pal_colors

  # save away this default for reverting individual layers
  set PAL(save_palette) [pal_write_int]
}


proc pal_scrollbar {{update ""}} -desc {
  possibly add a scrollbar to palette if larger than screen.  Also
fixes up width of palette which has just guessed at before.
} {

  global PAL max_win

  if {$update != ""} {
    # first do an update to make sure we have new sizes
    update idletasks
  }

  set c $PAL(pal_pal)
  set canvas $c.c

  # get size of area for palette
  set avail_height [expr [winfo height $max_win.leftsidebar] - \
			[winfo height $max_win.tool_bar]]

  # get height of actual palette
  setl {x y width height} [$canvas bbox all]

#puts "$height > $avail_height"

  $canvas config -width $width -height $height

  if {$height > $avail_height} {
    # not enough room for all of palette, add a scrollbar
    if {![winfo exists $c.vscroll]} {
      scrollbar $c.vscroll -relief sunken -command "$canvas yview" \
	  -highlightthickness 0 -width 10
    }
    pack $c.vscroll -side left -fill y
    
    set incr [winfo height [lindex $PAL(widgets) 0]]
    $canvas config -yscrollincrement $incr

    $canvas config -scrollregion "0 0 $width $height"
    $canvas config -yscrollcommand "$c.vscroll set"

  } else {
    # remove if not needed any more
    pack forget $c.vscroll

    # make sure the scrollbar is set to the top
    $canvas yview moveto 0
  }
}


proc _pal_build_column_frame {palf} -desc {
  build a palette column frame
} {

  global PAL

  set col 1

  set c $palf.col$col
  catch "destroy $c"
  frame $c -borderwidth 2 -background blue -relief groove
  pack $c -side left -fill y

  set PAL(pal_widget) $c.c.pal

  # frame around the palette
#  frame $PAL(pal_widget) -borderwidth 2 -background blue -relief groove
#  pack $PAL(pal_widget) -side left -fill x

  # to get scrollbars, need to put palette into a canvas

  set PAL(pal_pal) $c
  set canvas $c.c

  # note: width and height are just guesses.  Fix later in pal_scrollbar
  canvas $canvas -highlightthickness 0 -width 55 -height 2000
  pack $canvas -side left -expand 1 -fill y

  set f [frame $canvas.pal]
  $canvas create window 0 0 -window $f -anchor nw
}


proc _pal_regenerate_palette {{layer ""}} -desc { 
  regenerate the palette and load it.  Used when change from solid to stipple or adding/subtracting outlines.  Also used to revert an individual layer.
} {
  global PAL PAL_DATA

  # unpack all of the layer and group layout widgets
  eval pack forget $PAL(widgets)
  eval pack forget $PAL(group_widgets)

  foreach one [array names PAL_DATA *.hide] {
    pack forget $PAL_DATA($one)
  }

  # save the palette
  set lines [pal_write_int]

  if {$layer != ""} {
    # special case.  Regenerate but revert this layer only from
    # the last saved
    foreach line $PAL(save_palette) {
      if {[lsearch "pal_layer pal_set" [lindex $line 0]] != -1 \
	      && [lindex $line 1] == $layer} {
	# found the saved one, replace with current one
	set save $line
	
	# not very efficient but it works
	set new ""
	foreach line $lines {
	  if {[lsearch "pal_layer pal_set" [lindex $line 0]] != -1 \
		  && [lindex $line 1] == $layer} {
	    # this is it, replace
	    lappend new $save
	  } else {
	    lappend new $line
	  }
	}
	set lines $new

	break
      }
    }
  }

  # initialize palette
  pal_load_file -string $lines

  # build up the colors and styles
  _pal_colors

  # hide any groups that were hidden before
  foreach group $PAL_DATA(hidden_groups) {
    # hide this
    _pal_toggle_group_layers $group
  }
}

