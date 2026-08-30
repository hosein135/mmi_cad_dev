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

set RCSVERSION(pal_file.tcl) { $Revision: 1.11 $ }


# procs to read/write .palette file
#
# palette/colors code broken up as follows:
#   pal.tcl             - procs to build and manipulate palette widget.
#   pal_file.tcl        - procs to read .palette file. 
#   colors.tcl          - procs to setup layout widget colors/styles 
#   color_editor.tcl    - builds widget for editing layer colors/styles

proc pal_revert_default_palette {} -desc {
  restore palette to tech file defaults by deleting private palette file
} {
  global PAL CELL
  set private_dir [file nativename ~/mmi_private]
  set filename [max_tech_path palette]
  if {[string first $private_dir $filename] == 0} {
    # User has a private palette file
    set message "Remove the custom palette file \
    $filename?"
    set choice [tk_dialog .dialog "Palette Warning" $message {} 0 \
		    Continue Cancel]
    if { $choice != 0 } {
      # user hit the cancel button
      puts "Aborting revert palette."
      return
    }
    set newfilename "$filename$CELL(backup_suffix)"
    msg "Moving custom palette file $filename to $newfilename\n"
    catch "exec \"mv\" -f $filename $newfilename"
    # And read in the default palette file
    pal_revert_palette
  } else {
    msg "No custom private palette file is installed: palette not reverted\n"
  }
}


proc pal_revert_palette {} -desc { 
  reread the palette file to restore palette to startup condition
} {
  global PAL

  # load the palette info from the tech directory

  set filename [max_tech_path palette]

  if {$filename == ""} {
    # no palette file found, can't revert
    puts "Aborting, can't revert because can't find palette file\n]"
    return
  }

  # unpack all of the layer and group layout widgets
  eval pack forget $PAL(widgets)
  eval pack forget $PAL(group_widgets)

  puts "Reverting $filename"
  pal_load_file -file $filename

  # build up the colors and styles
  _pal_colors
}


proc pal_set {type rgb {fill ""}} -desc {
  set the background, grid, label, highlite, drc, and bbox color and possibly stipple.
} -doc {
  can only be called inside of palette file
} {
  global PAL PAL_DATA

  if {!$PAL(loading)} {
    puts "Aborting, Can't execute a pal command except through the palette file."
    return
  }

  # (include "highlite" for backward compatibility)
  if {[lsearch "$PAL(special_layers) highlite" $type] == -1} {
    puts "PALETTE ERROR, type must be one of \"$PAL(special_layers)\" instead of \"$type\" in\n\t[list $type $rgb $fill]"

    return
  }

  if {![rgb_valid $rgb]} {
    puts "PALETTE ERROR, invalid rgb color \"$rgb\" in\n\t[list $type $rgb $fill]"
    return
  }

  set PAL_DATA($type) $rgb

  if {[lsearch "drc selection feedback" $type] != -1 && \
	  [lindex $fill 0] == "stipple"} {
    # stippled, save away for after pal_colors
    lappend PAL_DATA(todo) [list $type [lrange $fill 1 end]]
  }
}


proc pal_add_group {group} -desc {
  name a palette group
} -doc {
  can only be called inside of palette file
} {

  global PAL PAL_DATA

  if {!$PAL(loading)} {
    puts "Aborting, Can't execute a pal command except through the palette file."
    return
  }

  if {[info exists PAL_DATA(processed,group,$group)]} {
    # can't define a group twice
    puts "PALETTE WARNING, ignoring duplicate definition of group \"$group\"."
    return
  }
  set PAL_DATA(processed,group,$group) 1

  # this is now the active group.  All layers until the next pal
  # group command belong to this group.
  set PAL_DATA(active_group) $group
  lappend PAL_DATA(groups) $group

  # make the button
  set w $PAL(pal_widget).g_$group
  catch "destroy $w"

  _pal_build_cmd_button $w $group "_pal_group_toggle $group" -fg blue  
  bind $w <Button-2> "_pal_toggle_group_layers $group"
  bind $w <Button-3> "_pal_group_toggle $group select"
  bind $w <Any-Enter> \
      {mode_msg "Palette: BUT-1 toggles visibility, BUT-2 hides group, BUT-3 toggles selectivity of group" palette}
  #bind $w <Any-Leave> "mode_msg __RESTORE__ palette"
  pack $w -fill x

  # remember these so we can remove them later
  lappend PAL(group_widgets) $w
}


proc pal_layer {layer rgb fill} -desc {
  add a layer, color, and fill style to the palette
} -doc {
  can only be called inside of palette file
} {

  global PAL PAL_DATA

  if {!$PAL(loading)} {
    puts "Aborting, Can't execute a pal command except through the palette file."
    return
  }

  # check if layer is valid
  set lname [dbt_long_name $layer]
  if {$lname == ""} {
    puts "PALETTE WARNING, skipping unknown layer \"$layer\" in\n\t[list pal_layer $layer $rgb $fill].  Probably someone removed this layer from the tech file.  "
    return
  }

  if {![rgb_valid $rgb]} {
    puts "PALETTE WARNING, invalid rgb color ($rgb) for $layer"

    set $rgb { 100 200 100 } 
  }

  if {[info exists PAL_DATA(processed,layer,$layer)]} {
    # can't define a layer twice
    puts "PALETTE WARNING, ignoring duplicate definition of layer \"$layer\"."
    return
  }
  set PAL_DATA(processed,layer,$layer) 1

  # build it
  _pal_build_entry_layer $layer

  # make this layer selectable
  _pal_toggle_selectable $layer

  # this is now the active group.  All layers until the next pal
  # group command belong to this group.
  if {$PAL_DATA(active_group) != ""} {
    lappend PAL_DATA($PAL_DATA(active_group).layers) $layer
  }

  if {$fill == "solid"} {
    incr PAL_DATA(solids)
  }

  # save info so we can process it in reverse order later
  lappend PAL_DATA(colors) [list $layer $rgb $fill]
}


proc pal_compose {layer l1 l2} -desc {
  until simple layers, composes layer colors
} -doc {
  can only be called inside of palette file
} {

  global PAL PAL_DATA

  if {!$PAL(loading)} {
    puts "Aborting, Can't execute a pal command except through the palette file."
    return
  }

  # check if layer is valid
  set lname [dbt_long_name $layer]
  if {$lname == ""} {
    puts "Unknown layer \"$layer\" in line \"pal_compose $layer $l1 $l2\""
    return
  }

  if {[info exists PAL_DATA(processed,layer,$layer)]} {
    # can't define a layer twice
    puts "PALETTE WARNING, ignoring duplicate definition of layer \"$layer\"."
    return
  }
  set PAL_DATA(processed,layer,$layer) 1

  # build it
  _pal_build_entry_layer $layer

  # make this layer selectable
  _pal_toggle_selectable $layer

  # this is now the active group.  All layers until the next pal
  # group command belong to this group.
  if {$PAL_DATA(active_group) != ""} {
    lappend PAL_DATA($PAL_DATA(active_group).layers) $layer
  }

  set PAL_DATA(compose,$layer) [list $layer $l1 $l2]

  # save away for now
  lappend PAL_DATA(compose) [list $layer $l1 $l2]

  lappend PAL_DATA(colors) $layer
}


proc pal_write_palette {} -desc {
  write out the current palette colors, fills, etc.
} {

  global PAL PAL_DATA CELL env MN_TECH MN_TECH_VAR

  # give the user a warning if the DRC pattern is not complete
  set incomplete 0
  for {set i 0} {$i < 8} {incr i} {
    set col($i) 0
  }
  set stipple \
      [lindex [lay_style [lindex [lay_layer_styles error_p] 0]] 4]

  foreach row $PAL_DATA(stipple,$stipple) {
    if {$row == "00000000"} {
      set incomplete 1
      break
    }

    for {set i 0} {$i < 8} {incr i} {
      set col($i) [max $col($i) [string index $row $i]]
    }
  }
  for {set i 0} {$i < 8} {incr i} {
    if {$col($i) == 0} {
      set incomplete 1
      break
    }
  }

  if {$incomplete} {
    set message "The DRC stipple pattern doesn't have at least one on pixel in every row and in every column.  This may make some DRC errors invisible on the screen.  Save anyways?"
    puts $message
    set choice [tk_dialog .dialog "DRC stipple Warning" $message {} 0 \
		    Continue Cancel]
    if { $choice != 0 } { 
      # user hit the cancel button
      puts "Aborting save palette."
      return
    }
  }

  # figure out the pathname for the palette file
  set techroot [max_local_tech_dir]

  if {![file isdir $techroot]} {
    set message "Aborting, can't create the directory \"$techroot\" to put the palette into.  Fix permissions or create yourself and then rerun this command."
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK

    return
  }

  # make the filename
  if {$MN_TECH_VAR == ""} {
    set filename $techroot/$MN_TECH.palette
  } else {
    # technology variation
    set filename $techroot/${MN_TECH}-$MN_TECH_VAR.palette
  }

  # move to a backup file
  if {[file exists $filename] && [file writable $filename]} {
    # file exists, ask user if ok to overwrite
    set message "The palette file \"$filename\" already exists.  Overwrite?"
    puts $message
    set choice [tk_dialog .dialog "Overwrite Palette" $message {} 0 \
		    Yes Cancel]
    if { $choice != 0 } { 
      # user hit the cancel button
      puts "Aborting save palette."
      return
    }

    # exec doesn't seem to do ~ expansion
    catch "exec \"mv\" -f [glob $filename] [glob $filename]$CELL(backup_suffix)"
  }

  if {[catch "open $filename w" FILE_ID]} {
    # uh, oh, error
    puts $FILE_ID
    return
  }

  # save away this default for reverting individual layers
  set PAL(save_palette) [pal_write_int]

  # generate and write the new palette
  puts $FILE_ID [join $PAL(save_palette) \n]

  close $FILE_ID

  puts "Wrote palette to file \"$filename\"."
}

proc pal_write_int {} -desc {
  return a list of the current palette colors, fills, etc.
} {

  global PAL PAL_DATA COLORMAP MAX_VERSION GR_COLOR_MAPPED

  lappend list "\# Palette setup of layer order, colors, stipples, etc."
  lappend list "\# Autogenerated by MAX $MAX_VERSION\n"

  foreach type $PAL(special_layers) {

    if {[lsearch "drc selection feedback" $type] != -1} {
      # stippled
      switch $type {
	drc {
	  set stipple \
	      [lindex [lay_style [lindex [lay_layer_styles error_p] 0]] 4]
	}
	selection {
	  set stipple [lindex [lay_style selection_stippled] 4]
	}
	feedback {
	  set stipple [lindex [lay_style feedback_pale] 4]
	}
      }

      set fill [eval format \{\{stipple\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\}\} $PAL_DATA(stipple,$stipple)]
    } else {
      set fill ""
    }

    set layer $type
    if { $GR_COLOR_MAPPED } {
      set color_number $PAL_DATA(color,$type)
    } else {
      # change to something that is in lay_style
      switch $type {
	feedback { set type feedback_dotted }
	selection { set type selection_outline }
	grid { set type grid_coarse }
	drc { set type [lindex [lay_layer_styles error_p] 0] }
	bbox { set type unexpanded_instance }
      }

      set color_number [lindex [lay_style $type] 1]
    }

    lappend list "pal_set $layer \{$COLORMAP($color_number)\} $fill"
  }

  lappend list ""

  set groups $PAL_DATA(groups)
  set group_index 0

  foreach line $PAL_DATA(colors) {
    setl {layer rgb fill} $line

    set group [lindex $PAL_DATA(groups) $group_index]
    if {$group != "" && [lsearch $PAL_DATA($group.layers) $layer] != -1} {
      # this layer is in this group
      lappend list "\npal_add_group $group"
      incr group_index
    }

    if {[info exist PAL_DATA(compose,$layer)]} {
      # special case of compose layers
      lappend list "pal_compose $PAL_DATA(compose,$layer)"
      continue
    }

    # get the colors, stipples, etc for this layer
    # Note: all layers have either one style (solid) or two styles
    # if stippled and outlined
    setl {style1 style2} [lay_layer_styles $layer]
    setl {mask color outline fill stipple} [lay_style $style1]

    # convert color to decimal
    if { $GR_COLOR_MAPPED } {
      set color [expr $color + 0]
    }

    if {$style2 != ""} {
      # the second style is either for pseudo-solid or outline
      if {[lindex [lay_style $style2] 3] == "stipple"} {
	# this layer is really solid
	set fill solid
      } else {
	# must mean stippled, outline
	set fill "stipple outline"
      }
    } elseif {[info exists PAL_DATA(pseudo,$stipple)]} {
      # this is really solid
      set fill solid
    }

    # if outlined, fill="stipple outline"
#    if { $PAL_DATA($layer,kind) == "outline" } {
#      set fill "stipple outline"
#    } 

    if {$fill != "solid"} {
      # stippled

      set fill [eval format \{\{$fill\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\}\} $PAL_DATA(stipple,$stipple)]
    }

#puts "x--> $layer -> $color"
    lappend list "pal_layer $layer \{$COLORMAP($color)\} $fill"
  }

  return $list
}


proc _pal_toggle_group_layers {group} -desc {
  hide or display the palette widgets of a group of layers
} {

  global PAL PAL_DATA

  # rootname of widgets
  set w $PAL(pal_widget)

  if {[info exists PAL_DATA($group.hide)]} {
    # layers are hidden, show them

    # restore group widget
    pack $w.g_$group -fill x -after $PAL_DATA($group.hide)
    catch {destroy $PAL_DATA($group.hide)}
    unset PAL_DATA($group.hide)

    foreach layer [lreverse $PAL_DATA($group.layers)] {
      pack $w.l_$layer -fill x -after $w.g_$group
    }

  } else {
    # hide layers in this group
    foreach layer $PAL_DATA($group.layers) {
      pack forget $w.l_$layer
    }

    # change so user knows there is something here
    set PAL_DATA($group.hide) $w.h_$group

    catch {destroy $PAL_DATA($group.hide)}
    _pal_build_cmd_button $PAL_DATA($group.hide) "\[$group\]" \
	"_pal_toggle_group_layers $group" 
    pack $PAL_DATA($group.hide) -fill x -after $w.g_$group
    bind $PAL_DATA($group.hide) <Button-2> "_pal_toggle_group_layers $group" 
    bind $PAL_DATA($group.hide) <Any-Enter> \
	{mode_msg "Palette: BUT-1/2 unhides group" palette}
    #bind $PAL_DATA($group.hide) <Any-Leave> "mode_msg __RESTORE__ palette"

    # hide the other for now
    pack forget $w.g_$group
  }

  # adjust/add/subtract scrollbar
  pal_scrollbar update
}


# TODO: remove and change reference to lreverse.  Fixed lreverse

proc lreverse_list {list} -desc {
  special to reverse lists of lists -- bug in lreverse
} {

  set new_list ""

  foreach element $list {
    set new_list [concat [list $element] $new_list]
  }

  return $new_list
}


proc rgb_valid {rgb} -desc {
  checks if an rgb triplet is valid
} {

  if {[llength $rgb] != 3} {
    return 0
  }

  foreach color $rgb {
    if {[catch "expr $color + 0"]} {
      # not a number
      return 0
    }

    if {$color < 0 || $color > 255 || [expr int($color)] != $color} {
      # not in range
      return 0
    }
  }

  # happiness!
  return 1
}

