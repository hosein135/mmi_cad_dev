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

set RCSVERSION(stdcell.tcl) { $Revision: 1.40 $ }
# BUG:
#  On multi-input gates, one of the input pads is not getting a contact.
#  Try nand4c
#  When moving fets to make room for outer preroutes, when marking
#     fets to move, if the adjoining fet is much larger, its not moved;
#     if its the same size, its moved correctly;  if it is intermediate
#     sized, it is moved improperly: it is moved the entire amount
#     needed, when it should be moved just enough to align the inner edges.
# TODO:
# Add option in per-cell options to over-ride schematic LayGen settings.
#In stdcell:
#- Router should print warning if there are any pads in the channel.
#- Dont reduce contacts below some set ratio.
#- make wiring tracks above/below be a float, to specify
#  just how much room you may want.
#- If you have an outer poly preroute, the gates of folded
#  fets should be connected by it, not a poly wire in the inner channel.
#- sideways fets.
#- determine pre-route location by examining the crossing graph.
#- reverse fets if it eliminates flyline crossings.
#
#	Given two fets together and hooked in parallel (happens alot
#       with folded fets) share the contact that is NOT connected
#       to vdd/gnd, to reduce capacitance on net connected to other contact.
#
#	Use constraint chains to determine routing tracks, and thereby
#	reduce total number of tracks.  See AO22B, which has 2 tracks
#	more than needed.
#
#	Currently, a special inner route is only attempted over one
#	intermediate contact and only when the intermediate contact
#	is gnd/vdd.  Both constraints could be relaxed, if the intermediate
#	contacts are routed in the outer channel.  But you should
#	check to make sure that nothing else needs to connect
#	to them in the center channel.
#
#	In the greedy router, can often eliminate metal2 by routing
#	another horizontal wire over to catch the net we want.  See XOR2B.
#	To really do a good job with this, you should leave
#	the disconnects in, and fix them at the end, so that
#	you can look both right and left for the desired net.
#
#	DONE: Add contacts to nets that are ports and appear only in poly.
#
#	Route output ports in metal.  Route metal verticals in metal.
#
#	DONE: Route special metal over/under fets.
#	If max fet height is less than some value, must move
#	the fets to route the special metal outside the fets.
#	Dont route through fets less than some size.
#
# 	DONE: Provide an option to provide on-grid connection pads (with labels)
# 	but no routing.
#
#	DONE: Add option not to share different size contacts.

proc STDCELL_ROUTER {} -desc {
    return 1 if router should be enabled
} {
    global env MAX_DEVELOPER
    if { $MAX_DEVELOPER } {
	# [string match {mmi.*} [use_first env(DISPLAY)]]
	return 1
    } else {
	return 0
    }
}

# Return true if we should generate the specified layer.
proc _stdcell_layer {layername} {
    global LAYINFO STDCELL
    return [expr $STDCELL(stdcell_layers) && $LAYINFO(layers:$layername)]
}


# The fet_info data-base has all x,y coords where the fet belongs
# in the current cell.  Offset it so the 0,0 coord is at gate lower left.
if {0} { ;# NOT USED
proc _stdcell_paint_fet {id x y {parent_cell ""}} {
    global LAYINFO fet_info

    # Draw fet with paint.
    set type $fet_info($id,type)
    # If different size fets abut, the shorter must not have a contact.
    set share_right [expr $fet_info($id,share_diff_right) || \
	    $fet_info($id,long_cont_right) ]
    set share_left [expr $fet_info($id,share_diff_left) || \
	    $fet_info($id,long_cont_left) ]

    set xoffset [expr $x - $fet_info($id,x)]
    set yoffset [expr $y - $fet_info($id,y)]

    lay_box $fet_info($id,x) $fet_info($id,y) \
	    [expr $fet_info($id,x) + $fet_info($id,fetlen)] \
	    [expr $fet_info($id,y) + $fet_info($id,w)]
    :paint [techinfo2 layer ${type}diff]

    setl {x1 y1 x2 y2} $fet_info($id,g_pos)
    set x1 [expr $x1 + $xoffset]
    set x2 [expr $x2 + $xoffset]
    set y1 [expr $y1 + $yoffset]
    set y2 [expr $y2 + $yoffset]
    lay_box $x1 $y1 $x2 $y2
    :paint [techinfo2 layer poly]

    set overlap [techinfo2 overlap m1 v0]
    if {! $share_left } {
	setl {x1 y1 x2 y2} $fet_info($id,s_pos)
	set x1 [expr $x1 + $xoffset]
	set x2 [expr $x2 + $xoffset]
	set y1 [expr $y1 + $yoffset]
	set y2 [expr $y2 + $yoffset]
	lay_box $x1 $y1 $x2 $y2
	:paint [techinfo2 layer m1]
	lay_box [expr $x1 + $overlap] [expr $y1 + $overlap] \
	    [expr $x2 - $overlap] [expr $y2 - $overlap]
	:paint [techinfo2 layer contact]
	#puts "drawing $id s: $fet_info($id,s_pos)"
    }
    if {! $share_right } {
	setl {x1 y1 x2 y2} $fet_info($id,d_pos)
	set x1 [expr $x1 + $xoffset]
	set x2 [expr $x2 + $xoffset]
	set y1 [expr $y1 + $yoffset]
	set y2 [expr $y2 + $yoffset]
	lay_box $x1 $y1 $x2 $y2
	:paint [techinfo2 layer m1]
	lay_box [expr $x1 + $overlap] [expr $y1 + $overlap] \
	    [expr $x2 - $overlap] [expr $y2 - $overlap]
	:paint [techinfo2 layer contact]
	#puts "drawing $id d: $fet_info($id,d_pos)"
    }

    # Add labels to a painted fet.
    if { $LAYINFO(option:flylines) } {
	foreach gsd "g s d" {
	    switch "$gsd" {
	    "g" {
		setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
		# Make the gate (g) connections to the exposed end of
		# the poly, not into the middle of the gate.
		if { $type == "p" } {
		    set y2 [expr $y1 + [techinfo2 extend poly pfet]]
		} else {
		    set y1 [expr $y2 - [techinfo2 extend poly nfet]]
		}
	      }
	    "s" {
		if { $share_left } { continue }
		setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
	      }
	    "d" {
		if { $share_right } { continue }
		setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
	      }
	    }
	    set x1 [expr $x1 + $xoffset]
	    set x2 [expr $x2 + $xoffset]
	    set y1 [expr $y1 + $yoffset]
	    set y2 [expr $y2 + $yoffset]
	    set label_name [_stdcell_unique_label]
	    db_label space $label_name $x1 $y1 $x2 $y2
	    set net $fet_info($id,$gsd)
	    if { $parent_cell != "" } {
		set label_name "$parent_cell/$label_name"
	    }
	    lappend fet_net_labels($net) "$x1 $y1 $x2 $y2 $id $gsd $label_name"
	}
    }
}
}


# Note: when we draw a sub-cell, we use the parent coordinate system
# to simplify things.  Ie, paint in the lower left corner of the sub-cell
# is not at 0,0, it has the sub-cell position in the parent already 
# added in.  Then when putting the sub-cell in the parent, no
# translation is required.
proc _stdcell_draw_fet {id method {parent_cell ""}} {
    global fet_info LAYINFO STDCELL fet_net_labels
    set type $fet_info($id,type)
    # If different size fets abut, the shorter must not have a contact.
    set share_right [expr $fet_info($id,share_diff_right) || \
	    $fet_info($id,long_cont_right) ]
    set share_left [expr $fet_info($id,share_diff_left) || \
	    $fet_info($id,long_cont_left) ]

    if { $method == "gcells" } {
	set gcell_props ""
	set fettype "${type}fet"
	append gcell_props "-type $fettype "
	append gcell_props "-width $fet_info($id,w) "
	append gcell_props "-length $fet_info($id,l) "
	append gcell_props "-fingers 1 "
	# Fets exactly the same size can share contacts.
	switch "$share_left$share_right" {
	    "00" { set stacked "both" }
	    "10" { set stacked "right" }
	    "01" { set stacked "left" }
	    "11" { set stacked "none" }
	}
	append gcell_props "-contacts $stacked "
	# Fet gcell uses origin for lower left corner of gate,
	# so get gate position, which is actually the poly location,
	# then add poly_gate_overlap to get the actual gate location.
	setl {x1 y1 x2 y2} $fet_info($id,g_pos)
	set y1 [expr $y1 + [techinfo2 extend poly $fettype]]
	# Deal with resized contact areas.
	foreach gsd [list s d] {
	  if { $fet_info($id,${gsd},resized) != "" } {
	    if { $gsd == "s" } {
	      set prop "left_contacts"
	    } else {
	      set prop "right_contacts"
	    }
	    append gcell_props "-$prop $fet_info($id,$gsd,resized) "
	  }
	}
	#DEBUG: puts "place_gcell fet {$x1 $y1} $gcell_props"
	eval place_gcell fet "{$x1 $y1}" $gcell_props

	# Save the gcell labels for later use.  The new gcell is selected.
	set stuff [sel_what cells]
	setl fet_id $stuff  ; # First item in list is instance id.
	foreach gsd "g s d" {
	    switch "$gsd" {
	    "g" {
		# Fet generator places two labels on gate:
		# gn on north side and gs on south side.  Choose one.
		if { $type == "p" } {
		    set label_name "$fet_id/gs"
		} else {
		    set label_name "$fet_id/gn"
		}
	      }
	    "s" {
		if { $share_left } { continue }
		set label_name "$fet_id/s"
	      }
	    "d" {
		if { $share_right } { continue }
		set label_name "$fet_id/d"
	      }
	    }
	    setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
	    set net $fet_info($id,$gsd)
	    # The x,y is not quite correct for the gate label, but
	    # it is used only as a sort key, and does not need to be exact.
	    lappend fet_net_labels($net) "$x1 $y1 $x2 $y2 $id $gsd $label_name"
	    set fet_info($id,$gsd,label) $label_name
	}
    } elseif { $method == "subcells" } {
	# Create a sub-cell, and recur to draw fet using paint in the sub_cell.
	set rootcell [lay_rootcell]
	# Create a unique name.
	if {! [info exists fet_info(unique_id)] } {
	    set fet_info(unique_id) 0
	}
	set cell_name ${id}
	while {[cell_in_memory $cell_name]} {
	    set fet_info(unique_id) [expr $fet_info(unique_id) + 1]
	    set cell_name ${id}_$fet_info(unique_id)
	}
	db_cell_new $cell_name
	cell_load $cell_name
	lay_box 0 0 10 10
	# TODO: FIX KLUDGE: Get real name, dont just append _0
	_stdcell_draw_fet $id paint "${cell_name}_0"
	cell_load $rootcell
	:getcell $cell_name child 0 0 parent 0 0
	# Do not put labels in parent cell: they were added in subcell.
    } else {
	# Draw fet with paint.
	# Does not work with dog-bone fets.
	#_stdcell_paint_fet $id $fet_info($id,x) $fet_info($id,y) $parent_cell
	#return
	setl {x1 y1 x2 y2} [list $fet_info($id,x) $fet_info($id,y) \
	    [expr $fet_info($id,x) + $fet_info($id,fetlen)] \
	    [expr $fet_info($id,y) + $fet_info($id,w)]]
	# To avoid a drc error on the diffusion for fets with only
	# one contact, extend it.
	set amt [expr [techinfo2 spacing ${type}fet]/2.0]
	if { $share_left } {
	    set x1 [expr $x1 - $amt]
	}
	if { $share_right } {
	    set x2 [expr $x2 + $amt]
	}
	lay_box $x1 $y1 $x2 $y2
	:paint [techinfo2 layer ${type}diff]
	eval lay_box $fet_info($id,g_pos)
	:paint [techinfo2 layer poly]

	set overlap [techinfo2 overlap m1 v0]
	if {! $share_left } {
	    setl {x1 y1 x2 y2} $fet_info($id,s_pos)
	    lay_box $x1 $y1 $x2 $y2
	    :paint [techinfo2 layer m1]
	    lay_box [expr $x1 + $overlap] [expr $y1 + $overlap] \
		[expr $x2 - $overlap] [expr $y2 - $overlap]
	    :paint [techinfo2 layer contact]
	    #puts "drawing $id s: $fet_info($id,s_pos)"
	}
	if {! $share_right } {
	    setl {x1 y1 x2 y2} $fet_info($id,d_pos)
	    lay_box $x1 $y1 $x2 $y2
	    :paint [techinfo2 layer m1]
	    lay_box [expr $x1 + $overlap] [expr $y1 + $overlap] \
		[expr $x2 - $overlap] [expr $y2 - $overlap]
	    :paint [techinfo2 layer contact]
	    #puts "drawing $id d: $fet_info($id,d_pos)"
	}

	# Add labels to a painted fet.
	if { $LAYINFO(option:flylines) } {
	    foreach gsd "g s d" {
		switch "$gsd" {
		"g" {
		    setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
		    # Make the gate (g) connections to the exposed end of
		    # the poly, not into the middle of the gate.
		    if { $type == "p" } {
			set y2 [expr $y1 + [techinfo2 extend poly pfet]]
		    } else {
			set y1 [expr $y2 - [techinfo2 extend poly nfet]]
		    }
		  }
		"s" {
		    if { $share_left } { continue }
		    setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
		  }
		"d" {
		    if { $share_right } { continue }
		    setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
		  }
		}
		set label_name [_stdcell_unique_label]
		lay_box $x1 $y1 $x2 $y2
		:label -kind hidden $label_name
		set net $fet_info($id,$gsd)
		if { $parent_cell != "" } {
		    set label_name "$parent_cell/$label_name"
		}
		lappend fet_net_labels($net) "$x1 $y1 $x2 $y2 $id $gsd $label_name"
		set fet_info($id,$gsd,label) $label_name
	    }
	}
    }
}


# Place the fet using info in $fet_info(id,...)
# Return the total length (ie, x dimension) of the fet.
# Fill in the fet_info($id,g/s/d_pos) locations and return the total length.
proc _stdcell_locate_fet {id} {
    global fet_info STDCELL
    set type $fet_info($id,type)
    set fettype ${type}fet   ;# nfet of pfet
    set x $fet_info($id,x)
    set y $fet_info($id,y)
    set l $fet_info($id,l)
    set w $fet_info($id,w)
    if { $STDCELL(debug) } {
	puts "stdcell_fet id=$id type=$type x=$x y=$y w=$w l=$l"
    }

    # If two fets with different width share a contact, one of the
    # fets may need to be pushed over a little because its poly
    # will be too close to the diffusion of the other fet.
    # This may or may not be necessary, depending on the process
    # parameters, so if its negative, ignore it.
    set add_space [expr [techinfo2 sep poly diff] + \
	[techinfo2 overlap diff v0] - [techinfo2 sep v0 gate] ]
    if { $add_space < 0 } {
	set add_space 0
    }

    # Determine if it is a dog-bone fet.
    # Min_width is min before we have to create a dog-bone.
    # In this case, we will center the diffusion, for no good reason.
    # Set dy1 and dy2 to top and bottom of gate.
    set mres [res -mask]
    set diff_enc_contact [max [techinfo2 enclose diff v0 opt] $mres]
    set contact_space_to_gate [max [techinfo2 sep v0 $fettype] $mres]
    set cw [techinfo2 width v0]
    set min_width [uusnap -mask [expr 2.0 * $diff_enc_contact + $cw]]
    set dy1 0
    set dog_bone 0
    if {[approx $w < $min_width]} {
      # It is a dog-bone.
      set dog_bone 1
      # Dont need any add_space.
      set add_space 0
      set dy1 [uusnap -mask [expr ($min_width - $w)/2.0]]
      set dog_bone_sp [expr $diff_enc_contact + [techinfo2 sep diff poly]]
      if { $dog_bone_sp > $contact_space_to_gate } {
	 set contact_space_to_gate $dog_bone_sp
      }
    }
    set dy2 [expr $dy1 + $w]

    # Only the gcells know how to draw a dog-bone fet.
    # The fet paint routine in this file was not updated.
    # So check and print warning.
    if { $dog_bone } {
      set method [_layinfo draw_fets_using]
      if { $method == "paint" || $method == "subcells" } {
	# One message for each bad fet, oh well.
	msg "error: Must use gcells to layout fets smaller than $min_width\n"
      }
    }

    # Determine length of total fet structure.
    # This code mostly duplicates code in make_fet, which also
    # knows how long the fet is going to be.
    # First add in up through gate.
    if { $fet_info($id,share_diff_left) } {
	set fetlen [expr [techinfo2 spacing $fettype] / 2 + $l]
    } else {
        set fetlen [expr [techinfo2 overlap diff v0] + \
	[techinfo2 width v0] + $contact_space_to_gate + $l ]
	if { $fet_info($id,long_cont_left) } {
	    set fetlen [expr $fetlen + $add_space]
	}
    }

    # Place either diffusion or another contact to the right.
    if { $fet_info($id,share_diff_right) } {
        set fetlen [expr $fetlen + [techinfo2 spacing $fettype] / 2]
    } else {
        set fetlen [expr $fetlen + $contact_space_to_gate + \
	  [techinfo2 width v0] + [techinfo2 overlap diff v0]]
	if { $fet_info($id,long_cont_right) } {
	    set fetlen [expr $fetlen + $add_space]
	}
    }

    set fet_info($id,fetlen) $fetlen

    # Amount diffusion overlaps metal around d or s fet contact.
    set cont_dm_overlap [expr [techinfo2 overlap diff v0] - \
		[techinfo2 overlap m1 v0]]
    # Width of metal area over d or s fet contact.
    set cont_m_width [expr [techinfo2 width v0] + \
		2 * [techinfo2 overlap m1 v0]]

    # Determine fet source terminal location, if any.
    if { 1|| ! $fet_info($id,share_diff_left) } {
	# Left/right edge of metal contact.
	set x1 [expr $x + $cont_dm_overlap]
	set y1 [expr $y + $cont_dm_overlap]
	set x2 [expr $x1 + $cont_m_width ]
	set y2 [expr $y + $fet_info($id,w) - $cont_dm_overlap ]
	set fet_info($id,s_pos) "$x1 $y1 $x2 $y2"
	#DEBUG:
	#eval lay_box $fet_info($id,s_pos)
	#puts "s_pos=$fet_info($id,s_pos)"
	#:label source n space
    }


    # Determine fet gate location.
    if { $fet_info($id,share_diff_left) } {
	set gx1 [expr $x + [techinfo2 spacing $fettype] / 2]
    } else {
	set gx1 [expr $x + [techinfo2 overlap diff v0] + \
	    [techinfo2 width v0] + $contact_space_to_gate]
    }
    if { $fet_info($id,long_cont_left) } {
	set gx1 [expr $gx1 + $add_space]
    }
    #set gy1 [expr $y - [techinfo2 extend poly $fettype]]
    set gy1 [expr $y + $dy1 - [techinfo2 extend poly $fettype]]
    set gx2 [expr $gx1 + $fet_info($id,l)]
    #set gy2 [expr $y + $fet_info($id,w) + [techinfo2 extend poly $fettype]]
    set gy2 [expr $y + $dy2 + [techinfo2 extend poly $fettype]]
    set fet_info($id,g_pos) "$gx1 $gy1 $gx2 $gy2"

    #DEBUG:
    #eval lay_box $fet_info($id,g_pos)
    #puts "g_pos=$fet_info($id,g_pos)"
    #:label gate n space

    # Determine fet drain terminal location, if any.
    # Now we always determine location, even if there is none.
    if { 1|| ! $fet_info($id,share_diff_right) } {
	# Left/right edge of metal contact.
	if {0} {
	  set x1 [expr $gx2 + [techinfo2 sep v0 $fettype] - \
		  [techinfo2 overlap m1 v0]]
	  if { $fet_info($id,long_cont_right) } {
	      set x1 [expr $x1 + $add_space]
	  }
	  set x2 [expr $x1 + $cont_m_width ]
	} else {
	  set x2 [expr $x + $fetlen - $cont_dm_overlap]
	  set x1 [expr $x2 - $cont_m_width]
	}
	set y1 [expr $y + $cont_dm_overlap]
	set y2 [expr $y + $fet_info($id,w) - $cont_dm_overlap ]
	set fet_info($id,d_pos) "$x1 $y1 $x2 $y2"
	#DEBUG:
	#eval lay_box $fet_info($id,d_pos)
	#puts "d_pos=$fet_info($id,d_pos)"
	#:label drain n space
    }

    # We used to paint the fets right here...
    if {0} {
	# switch "$fet_info($id,long_cont_left)$fet_info($id,long_cont_right)" {
	#     "00" { set big_side 0 }
	#     "10" { set big_side "left" }
	#     "01" { set big_side "right" }
	#     "11" { set big_side "both" }
	# }
	# switch "$fet_info($id,share_diff_left)$fet_info($id,share_diff_right)" {
	#     "00" { set stacked 0 }
	#     "10" { set stacked "right" }
	#     "01" { set stacked "left" }
	#     "11" { set stacked "center" }
	# }

	# # Option puts each fet in its own sub-cell
	# # TODO: Right now, each fet goes into a new cell type,
	# # even if it is identical with some other fet.
	# # TODO: flylines dont work in sub-cells.
	# if { $LAYINFO(stdcell:draw_fets_using) == "subcells" } {
	#     set rootcell [lay_rootcell]
	#     # Create a unique name.
	#     if {! [info exists fet_info(unique_id)] } {
	# 	set fet_info(unique_id) 0
	#     }
	#     set cell_name ${id}
	#     while {[cell_in_memory $cell_name]} {
	# 	set fet_info(unique_id) [expr $fet_info(unique_id) + 1]
	# 	set cell_name ${id}_$fet_info(unique_id)
	#     }
	#     db_cell_new $cell_name
	#     cell_load $cell_name
	#     lay_box 0 0 10 10
	#     #make_fet $type $w 1 $stacked $l 2 $big_side
	#     _stdcell_draw_fet $id
	#     cell_load $rootcell
	#     :getcell $cell_name child 0 0 parent $x $y
	# } else {
	#     lay_box $x $y [expr $x + 10] [expr $y + 10]
	#     #make_fet $type $w 1 $stacked $l 2 $big_side
	#     _stdcell_draw_fet $id
	# }

	# # Remember labels.  Remember, fet is still selected.
	# foreach label_info [split [sel_what labels] \n] {
	#     set label [lindex $label_info 6]
	#     # toast the label (the user doesn't need to see it)
	#     eval sel_labels -rect [lrange $label_info 1 4] -text $label
	#     :delete

	#     # The make_fet generator labels the source and drain of
	#     # stacked fets with a zero-width label.  Forget it.
	#     setl {x1 y1 x2 y2} [lrange $label_info 1 4]
	#     if { $x1 == $x2 } { continue }

	#     set net $fet_info($id,$label)
	#     #set fet_info($id,${label}_pos) [lrange $label_info 1 4]

	#     # Wire vdd/gnd to power rails.
	#     # vdd or gnd could be hooked to an input, so check
	#     # to make sure it is really power to a fet d or s.
	#     if { [_stdcell_layer power_strap] &&
	# 	 ($label == "d" || $label == "s") &&
	# 	 (($type == "p" && $net == "vdd") ||
	# 	  ($type == "n" && $net == "gnd")) } {
	# 	setl {x1 y1 x2 y2} [lrange $label_info 1 4]
	# 	if { $net == "vdd" } {
	# 	    lay_box $x1 $y2 $x2 $LAYINFO(stdcell:cell_height)
	# 	    :paint m1
	# 	} else {
	# 	    lay_box $x1 0 $x2 $y1
	# 	    :paint m1
	# 	}
	#     } else {
	# 	# Fets with shared contacts get two labels.
	# 	# Remove one of them.
	# 	if { !($fet_info($id,share_contact_left) && $label == "s") } {
	# 	    lappend fet_net_labels($net) [lrange $label_info 1 4]
	# 	}
	#     }
	# }
    }
    return $fetlen
}

proc _stdcell_spread_fets {stype} -desc {
  spread fets out, stype is the shorter row of fets, p or n.
} {
    global STDCELL fet_info fet_order
    if { $stype == "p" } {
	set ltype "n"   ;# ltype is the longer row of fets, p or n.
    } else {
	set ltype "p"
    }

    # Process fets from left to right.
    # si is index into shorter row of fets, li into longer row.
    set si [expr [llength $fet_order($stype)] - 1]
    set li [expr [llength $fet_order($ltype)] - 1]
    for {} {$si > 0 && $li > 0} {incr si -1} {

	# Gather up all fets that share diff into sgroup.
	# Si2 is index of rightmost fet in sgroup.
	# Exit loop with si being the leftmost fet in the group.
	set sid [lindex $fet_order($stype) $si]
	set si2 $si	;# index of rightmost fet in sgroup
	set sgroup $sid
	set flag [_layinfo spread_fets]
	while { $si > 0 } {
	    if { $flag == "larger" } {
		# If the next fet to the left is smaller, stop here.
		# This also groups fets that share diff, since we
		# only share diff with same size fets.
		set tmpid [lindex $fet_order($stype) [expr $si-1]]
		if {[approx $fet_info($tmpid,w) < $fet_info($sid,w)]} {
		    break
		}
	    } elseif { $flag == "best" } {
		# Group fets based on size, but also split fets
		# at vdd/gnd contacts.  We should probably check that
		# there are no poly connections that cross the contact,
		# to avoid making very long poly preroutes.
		set tmpid [lindex $fet_order($stype) [expr $si-1]]
		if {[approx $fet_info($tmpid,w) < $fet_info($sid,w)]} {
		    break
		}
		set sid [lindex $fet_order($stype) $si]
		if { ( $stype == "p" && $fet_info($sid,s) == $STDCELL(vdd) ) ||\
		     ( $stype == "n" && $fet_info($sid,s) == $STDCELL(gnd) ) } {
		    break
		}
	    } else {
		# Stop at first fet that doesnt share diffusion.
		if { ! $fet_info($sid,share_diff_left) } {
		    break
		}
	    }
	    incr si -1
	    set sid [lindex $fet_order($stype) $si]
	    lappend sgroup [lindex $fet_order($stype) $si]
	}
	if { $si == 0 } {
	    # All fets share diff, ie, it is one gigantic
	    # multi-fingered fet.  Dont move anybody.
	    return
	}
	# Find the fet in the longer row that has the same net
	# connected to the gate as the rightmost fet in the
	# group of fets from the shorter row: sgroup.
	# We do this to try to align gates with the same net connections.
	set lid [lindex $fet_order($ltype) $li]
	set sid2 [lindex $fet_order($stype) $si2]
	while { $li > 0 && $fet_info($lid,g) != $fet_info($sid2,g) } {
	  incr li -1
	  set lid [lindex $fet_order($ltype) $li]
	}
	# Either we hit the last fet, or we found a fet with
	# the same gate node as on the other side.
	# There might be multiple gates with the same net,
	# especially for folded fets.  Since we are moving
	# things to the right, we want to find the leftmost gate
	# with this net, so keep going while the gate node is the same.
	set lidtmp [lindex $fet_order($ltype) [expr $li - 1]]
	while { $li > 0 && $fet_info($lidtmp,g) == $fet_info($sid2,g) } {
	  set lid $lidtmp
	  incr li -1
	  set lidtmp [lindex $fet_order($ltype) [expr $li - 1]]
	}

	# Figure out the max that we can move the group of fets
	# without running into the fet to the right, if any.
	set maxdx 10000
	if { [expr $si2+1] < [llength $fet_order($stype)] } {
	    # idr is id of fet to right of sgroup
	    set idr [lindex $fet_order($stype) [expr $si2+1]]
	    # r is right border of sid2 in its current position
	    setl {rx1 ry1 rx2 ry2} $fet_info($sid2,d_pos)
	    set r [expr $rx2 + $STDCELL(diff,m1,overlap)]
	    set maxdx [expr $fet_info($idr,x) - [techinfo2 sep diff diff] - $r]
	}
	# We want to align the gates:
	setl lx $fet_info($lid,g_pos)
	setl sx $fet_info($sid2,g_pos)
	set dx [min $maxdx [expr $lx - $sx]]
	if { $dx < 0 } {
	    continue
	}
	if { $fet_info($sid,share_contact_left) } {
	    set sidleft [lindex $fet_order($stype) [expr $si-1]]
	    # is dx enough to unshare the contact?
	    # If so, if we unshare the contact, will sid be in a 
	    # better position than if we dont?
	    set amt [expr [techinfo2 width v0] + \
		2.0 * [techinfo2 overlap diff v0] + \
		[techinfo2 sep diff diff]]
	    if { $dx < $amt } {
		# Not enough to split them apart.
		# TODO: We might still be able to move the whole group.
		continue
	    }
	    # Unshare this contact.
	    set fet_info($sid,share_contact_left) 0
	    set fet_info($sid,long_cont_left) 0
	    set fet_info($sidleft,share_contact_right) 0
	    set fet_info($sidleft,long_cont_right) 0
	    _stdcell_locate_fet $sid
	    _stdcell_locate_fet $sidleft
	}
	if { $STDCELL(debug) } {
	    puts "moving $dx sgroup=$sgroup"
	}
	foreach id $sgroup {
	    _stdcell_move_fet $id $dx 0
	}
	incr li -1
    }
}

# Determine tentative x,y locations for all fets,
# save in fet_info($id,x) and fet_info($id,y).
# Return total width of row of fets.
proc _stdcell_locate_fets {type} {
    global fet_info STDCELL LAYINFO fet_order
    set fetcnt [llength $fet_order($type)]
    set fet_x $STDCELL(fet_xmin)
    set lastx $fet_x
    for {set i 1} {$i <= $fetcnt} {incr i} {
        set id [lindex $fet_order($type) [expr $i-1]]
        set fet_info($id,x) $fet_x
	if { $LAYINFO(option:align_fets) == "outer" } {
	  if {$type == "p"} {
	    set fet_info($id,y) [expr $STDCELL(pfet_ymax) - $fet_info($id,w)]
	  } else {
	    set fet_info($id,y) $STDCELL(nfet_ymin)
	  }
	} else {
	  if {$type == "p"} {
	    set fet_info($id,y) [expr $STDCELL(pfet_ymax) - \
		$STDCELL(fet_max_width,p)]
	  } else {
	    set fet_info($id,y) [expr $STDCELL(nfet_ymin) + \
		$STDCELL(fet_max_width,n) - $fet_info($id,w)]
	  }
	}
  
        # Place fet and move fet_x past the fet.
	set fetlen [_stdcell_locate_fet $id]
        set fet_x [expr $fet_x + $fetlen]
	set lastx $fet_x
  
	if { $i < $fetcnt } {
	    # Now move fet_x backwards if shared contact or diff.
	    if { $fet_info($id,share_diff_right) } {
		# No move necessary, diff is cut in half between two fets.
	    } elseif { $fet_info($id,share_contact_right) } {
		# move left so new contact overlaps old.
		set fet_x [expr $fet_x - [techinfo2 width v0] - \
		      2 * [techinfo2 overlap diff v0]]
	    } else {
		# Unrelated fets.  Leave a space between them.
		set fet_x [expr $fet_x + [techinfo2 sep diff diff]]
	    }
	}
    }
    return [expr $lastx + $STDCELL(fet_xmin)]
}

# Draw fets using saved x,y location in fet_info
proc _stdcell_draw_fets {type} {
    global fet_info STDCELL LAYINFO fet_order
    set fetcnt [llength $fet_order($type)]
    for {set i 0} {$i < $fetcnt} {incr i} {
        set id [lindex $fet_order($type) $i]
	_stdcell_draw_fet $id $LAYINFO(stdcell:draw_fets_using)

	# Wire vdd/gnd to power rails.
	# vdd or gnd could be hooked to an input, so check
	# to make sure it is really power to a fet d or s.
	set type $fet_info($id,type)
	if { [_stdcell_layer power_strap] } {
	    foreach gsd "s d" {
	       if { ($type == "p" && $fet_info($id,$gsd) == $STDCELL(vdd)) ||
		      ($type == "n" && $fet_info($id,$gsd) == $STDCELL(gnd)) } {
		    setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
		    if { $type == "p" } {
			lay_box $x1 $y2 $x2 $LAYINFO(stdcell:cell_height)
			:paint [techinfo2 layer m1]
		    } else {
			lay_box $x1 0 $x2 $y1
			:paint [techinfo2 layer m1]
		    }
		}
	    }
	}
    }
    #set id [lindex $fet_order($type) [expr $fetcnt-1]]
    #return [expr $fet_info($id,x) + $fet_info($id,fetlen) + $STDCELL(fet_xmin)]
}


# Swap fet source and drain connections
proc _stdcell_flip_fet {id} {
    global fet_info
    set tmp $fet_info($id,s)
    set fet_info($id,s) $fet_info($id,d)
    set fet_info($id,d) $tmp
    set tmp $fet_info($id,s,buried_contact)
    set fet_info($id,s,buried_contact) $fet_info($id,d,buried_contact)
    set fet_info($id,d,buried_contact) $tmp
    # The s_pos/d_pos and label are not filled in until the fet is drawn,
    # and we dont flip fets after that, so we do not need
    # to bother swapping s_pos and d_pos.
    set fet_info($id,ori) [expr ($fet_info($id,ori) == 1) ? -1 : 1]
}

# Is this fet a single fet, ie, does not share diff or contacts.
proc _stdcell_is_single_fet {id} {
    global fet_info
    if { $fet_info($id,share_contact_left) } { return 0 }
    if { $fet_info($id,share_contact_right) } { return 0 }
    if { $fet_info($id,share_diff_left) } { return 0 }
    if { $fet_info($id,share_diff_right) } { return 0 }
    return 1
}


# Determine optimal fet orientations!
# Even though we allowed the user to determine the transistor placement,
# we may be able to flip source and drain to share some contacts.
# Note that we do NOT flip transistors with shared diffusions.
# TODO: If there are two possible flippings with an equal number
# of shared contacts, but one requires putting together different size
# fets and the other doesnt, it would be nice to choose the one that doesnt.
# A nice recursive algorithm would do it.
proc _stdcell_determine_orientation1 {type forder} {
    global fet_info fet_net_uses STDCELL LAYINFO
    set fetcnt [llength $forder]

    if { $LAYINFO(option:share_contacts) == "no" } {
	return
    }

    # First, if the transistors can share diffusion, determine which
    # way they need to be flipped to share it.
    for {set i 2} {$i <= $fetcnt} {incr i} {
	set id1 [lindex $forder [expr $i-2]]
	set id2 [lindex $forder [expr $i-1]]

	# Only fets with same width can share diffusion, for now.
	if { $fet_info($id1,w) != $fet_info($id2,w) } { continue; }

	set fnd 0

	# Do id1 and id2 share a common diffusion that no other node uses?
	# If so, lock their orientation so as to share the diffusion.
	if { $fet_net_uses($fet_info($id1,d)) == 2 } {
	    if {$fet_info($id1,d) == $fet_info($id2,s)} {
		setl "fnd ori1 ori2" "1 1 1"
	    } elseif {$fet_info($id1,d) == $fet_info($id2,d)} {
		setl "fnd ori1 ori2" "1 1 -1"
	    }
	} elseif { $fet_net_uses($fet_info($id1,s)) == 2 && \
		$fet_info($id1,flipok) } {
	    if { $fet_info($id1,s) == $fet_info($id2,s) } {
		setl "fnd ori1 ori2" "1 -1 1"
	    } elseif { $fet_info($id1,s) == $fet_info($id2,d) } {
		setl "fnd ori1 ori2" "1 -1 -1"
	    }
	}
	if { $fnd } {
	    set fet_info($id1,flipok) 0
	    set fet_info($id1,share_diff_right) 1
	    set fet_info($id2,flipok) 0
	    set fet_info($id2,share_diff_left) 1
	    if { $ori1 < 0 } { _stdcell_flip_fet $id1 }
	    if { $ori2 < 0 } { _stdcell_flip_fet $id2 }
	}
    }

if {1} {  ;# New fast flip method
    # March across fets from left to right.  At each location,
    # determine a maximal run of fets that can share contacts,
    # then flip whatever fets necessary to get the maximal run, and loop.
    for {set ifirst 0} {$ifirst < [expr $fetcnt-1]} {set ifirst $inext} {
	set id_left [lindex $forder $ifirst]
	if { $fet_info($id_left,share_diff_right) } {
	    # A fet that shares diff on right cant share contact on right.
	    set inext [expr $ifirst+1]
	    continue
	}
	# Try flipping the first fet (id_left) both ways, see which is better.
	# Keep track of which way fets are flipped in flipit().
        foreach dir "0 1" {
	    set shared_contacts($dir) 0
	    set id_left [lindex $forder $ifirst] ;# Dont remove this
	    # If the id_left cant be flipped (BTW: it cant be flipped
	    # if it shares diff on left), then dont try flipping it.
	    if { $dir == 1 && $fet_info($id_left,flipok) == 0} {
		break
	    }
	    set flipit($id_left,$dir) $dir

	    for {set j [expr $ifirst+1]} {$j < $fetcnt} {incr j} {
		set id_right [lindex $forder $j]
		# Determine net connected to right contact of id_left
		if { $flipit($id_left,$dir) } {
		    set net $fet_info($id_left,s)
		} else {
		    set net $fet_info($id_left,d)
		}
		if { $LAYINFO(option:share_contacts) == "same_size" &&\
			$fet_info($id_left,w) != $fet_info($id_right,w) } {
		    break
		}
		# Can id_right share net in either orientation?
		if {$net == $fet_info($id_right,s)} {
		    set flipit($id_right,$dir) 0
		} elseif {$fet_info($id_right,flipok) && \
		    $net == $fet_info($id_right,d)} {
		    set flipit($id_right,$dir) 1
		} else {
		    # Right hand fet cannot share contact with left.
		    break
		}
		set id_left $id_right
	    }
	    set shared_contacts($dir) [expr $j - $ifirst - 1]
	    set ilast($dir) [expr $j - 1]
	}
	# Now flip fets if it results in shared contacts.
	if { $shared_contacts(0) > 0 || $shared_contacts(1) > 0 } {
	    if { $shared_contacts(0) > $shared_contacts(1) } {
		set dir 0
	    } else {
		set dir 1
	    }

	    # 3-22: Special case.  If the number of fets is even,
	    # and they all have the same source and drain, and one
	    # of them is vss/vdd/gnd, then flip them so the vss/vdd/gnd
	    # is on the outside, to minimize capacitance on the other node.
	    set id1 [lindex $forder $ifirst]
	    if { $shared_contacts(0) == $shared_contacts(1) && \
	      [expr ($ilast(0) - $ifirst + 1) % 2 == 0] && \
	      ($fet_info($id1,s) == $STDCELL(vdd) || \
	        $fet_info($id1,s) == $STDCELL(gnd)) \
	      } {
	      # The first fet has power on the left, so it might
	      # be a problem.  See if all the other fets have the
	      # same source and drain connections.
	      set its_a_problem 1
	      set netname1 $fet_info($id1,s)
	      set netname2 $fet_info($id1,d)
	      # Could use ilast(0) or ilast(1), since they are the same.
	      for {set i [expr $ifirst+1]} {$i <= $ilast(0)} {incr i} {
		set id2 [lindex $forder $i]
		set s $fet_info($id2,s)
		set d $fet_info($id2,d)
		if { ($s != $netname1 && $s != $netname2) || \
		     ($d != $netname1 && $d != $netname2) } {
		  # Some other net is connected, so its not the special case.
		  set its_a_problem 0
		  break
		}
	      }
	      if { $its_a_problem } {
		# Must flip to minimize capacitance.
		set dir 0
	      }
	    }

	    for {set i $ifirst} {$i <= $ilast($dir)} {incr i} {
		set id [lindex $forder $i]
		if {$flipit($id,$dir)} {
		    _stdcell_flip_fet $id
		}
	    }
	    set inext [expr $ilast($dir) + 1]
	} else {
	    set inext [expr $ifirst + 1]
	}
    }
}

if {0} { ;# Old slow flip method

    # Count how many flippable fets.
    set flipable 0
    for {set i 1} {$i <= $fetcnt} {incr i} {
	set id [lindex $forder [expr $i-1]]
	if {$fet_info($id,flipok) == 0} { continue }
	# We want to minimize the flippable fets to consider.
	# So remove from consideration any fets that will never
	# be flipped.  We could do this check better: if the id_left
	# is not flipable, we neednt check one of its terminals;
	# but it doesnt matter because if it not flipable then it
	# is a shared diffusion, and this fet cant possibly be
	# connected to it anyway, because the shared diffusion is
	# shared by only the two shared diffusion contacts.
	set flipok 0
	if {$i > 1} {
	    set id_left [lindex $forder [expr $i-2]]
	    if { $fet_info($id,s) == $fet_info($id_left,s) || \
		$fet_info($id,s) == $fet_info($id_left,d) || \
		$fet_info($id,d) == $fet_info($id_left,s) || \
		$fet_info($id,d) == $fet_info($id_left,d) } {
		set flipok 1
	    }
	}
	if {$flipok == 0 && $i < $fetcnt} {
	    set id_right [lindex $forder [expr $i]]
	    if { $fet_info($id,s) == $fet_info($id_right,s) || \
		$fet_info($id,s) == $fet_info($id_right,d) || \
		$fet_info($id,d) == $fet_info($id_right,s) || \
		$fet_info($id,d) == $fet_info($id_right,d) } {
		set flipok 1
	    }
	}
	set fet_info($id,flipok) $flipok

	if { $flipok } { incr flipable }
	#DEBUG:
	if {$STDCELL(debug) } { _stdcell_fet_dump $id }
    }

    puts "Determining best fet orientation for $flipable of $fetcnt $type fets"
    if { $flipable > 10 } {
	puts "WARNING: Too many fets.  Skipping fet shared contacts: \
		contact pat, this code needs to be fixed"
	return
    }
    if { $flipable != 0 } {

	# Brute force: try all possible orientations, keep the best.
	# TODO: break this up - do runs of flipable fets.
	set experiments [expr pow(2,$flipable)]
	set bestmask 0
	set bestshared 0
	# For perfect sharing, would $allshared shared contacts.
	set allshared [expr $flipable - 1]
	for {set mask 0} {$mask < $experiments} {incr mask} {
	    # Set the fet orientations from mask
	    set j 0
	    for {set i 1} {$i <= $fetcnt} {incr i} {
		set id [lindex $forder [expr $i-1]]
		set flipit($id) 0
		if { ! $fet_info($id,flipok) } { continue; }
		# Set fet orientation from jth bit of $mask
		if { $mask & (1 << $j) } { set flipit($id) 1 }
		incr j
	    }
	    # Count how many shared contacts
	    set shared 0
	    for {set i 2} {$i <= $fetcnt} {incr i} {
		set id_left [lindex $forder [expr $i-2]]
		set id_right [lindex $forder [expr $i-1]]
		if { $flipit($id_left) } {
		    set d $fet_info($id_left,s)
		} else {
		    set d $fet_info($id_left,d)
		}
		if { $flipit($id_right) } {
		    set s $fet_info($id_right,d)
		} else {
		    set s $fet_info($id_right,s)
		}
		if { $s == $d } {
		    incr shared
		}
	    }
	    if { $shared > $bestshared } {
		set bestshared $shared
		set bestmask $mask
	    }
	    if { $shared == $allshared } {
		# An optimization that helps with the D and E size
		# buffers and inverters.  If we have already found
		# a perfect solution, we can stop now.
		break
	    }
	}

	# Set final orientation from bestmask.
	set j 0
	for {set i 1} {$i <= $fetcnt} {incr i} {
	    set id [lindex $forder [expr $i-1]]
	    if {! $fet_info($id,flipok)} { continue }
	    if { $bestmask & (1 << $j) } {
		_stdcell_flip_fet $id
	    }
	    incr j
	}
    }
}

    # Mark fets with shared contacts.
    for {set i 2} {$i <= $fetcnt} {incr i} {
	set id_left [lindex $forder [expr $i-2]]
	set id_right [lindex $forder [expr $i-1]]
	# Does this fet share contact with its neighbors?
	if { $fet_info($id_left,d) == $fet_info($id_right,s) && \
	    ! $fet_info($id_left,share_diff_right) } {
	    # shared contact.
	    if { $LAYINFO(option:share_contacts) == "same_size" && \
		$fet_info($id_left,w) != $fet_info($id_right,w) } {
		continue
	    }
	    set fet_info($id_left,share_contact_right) 1
	    set fet_info($id_right,share_contact_left) 1
	    set net $fet_info($id_left,d)
	    incr fet_net_uses($net) -1
	    if { $fet_info($id_left,w) > $fet_info($id_right,w) } {
		set fet_info($id_right,long_cont_left) 1
	    }
	    if { $fet_info($id_left,w) < $fet_info($id_right,w) } {
		set fet_info($id_left,long_cont_right) 1
	    }
	}
    }
}

proc _stdcell_determine_orientation2 {type forder} {
    global fet_info fet_net_uses STDCELL
    set fetcnt [llength $forder]

    # Flip singletons.  We want the metal connections to line up
    # between the n and p fets, so put all power on the left
    # for all singleton fets.
    for {set i 0} {$i < $fetcnt} {incr i} {
	set id [lindex $forder $i]
	if { ! [_stdcell_is_single_fet $id] } { continue }
	if { $type == "p" } {
	    if { $fet_info($id,d) == $STDCELL(vdd) } {
		_stdcell_flip_fet $id
	    }
	} else {
	    if { $fet_info($id,d) == $STDCELL(gnd) } {
		_stdcell_flip_fet $id
	    }
	}
    }
}


proc _stdcell_route_draw_solution {solution_n} {

  global LAYINFO STDCELL ROUTE_SOLUTION ROUTE_OPTION

  set cell_width $STDCELL(cell_width)
  set cell_height [_layinfo cell_height]

    # Attempt to erase previous routing, if any.
    # KLUDGE!!!! Just guess where the routing is by looking at the fets.
    set miny 0
    set maxy $cell_height
    # Extend pdiff/ndiff the amount needed for the poly preroutes.
    # Assume pdiff/ndiff have similar tech rules.
    set amt [max [techinfo2 extend poly pfet] \
	[expr [techinfo2 sep poly pdiff] + [techinfo2 width poly]]]
    sel_area -any_cell -layers [techinfo2 layer pdiff] 0 $miny [expr $cell_width + 2] $maxy
    foreach paintball [split [sel_what paint] \n] {
	struct max_paint p $paintball
	set maxy [min [expr ${p.y1} - $amt] $maxy]
    }
    sel_area -any_cell -layers [techinfo2 layer ndiff] 0 $miny [expr $cell_width + 2] $maxy
    foreach paintball [split [sel_what paint] \n] {
	struct max_paint p $paintball
	set miny [max [expr ${p.y2} + $amt] $miny]
    }

    lay_box 0 $miny [expr $cell_width + 2] $maxy
    :erase [techinfo2 layer poly]
    :erase [techinfo2 layer m1]
    :erase [techinfo2 layer contact]
    :erase [techinfo2 layer m2]
    :erase [techinfo2 layer v12]

    # Remove labels
    sel_labels -inside 0 0 $cell_width $cell_height -text Failed
    :delete

    puts "Drawing solution number $solution_n"

    # Must save via and pad locations until last to do notch fill.
    # Cant notch fill until all the other paint is in place.
    set save_vias ""
    set save_rects ""

    setl {padx junk pady} $LAYINFO(stdcell:m1,router_pad_size)

    foreach item [split $ROUTE_SOLUTION($solution_n) "\n"] {
	setl {type layer x1 y1 x2 y2} $item
	if { [string match "segment*" $type] } {
	    set width [techinfo2 min_width ${layer}]
	    lay_box $x1 $y1 $x2 $y2
	    :paint $layer
	    #set maxx [max $x1 $x2 $maxx]
	    #set maxy [max $y1 $y2 $maxy]
	    #set minx [min $x1 $x2 $minx]
	    #set miny [min $y1 $y2 $miny]
	}
	if { $type == "via" } {
	    setl {type layer1 layer2 x1 y1} $item
	    _stdcell_draw_via $x1 $y1 $layer1 $layer2
	    # Remember where the router drops vias.
	    if { $layer1 == "poly" } {
	      lappend save_vias [list contact $x1 $y1]
	    }
	}
	if { $type == "port" } {
	  setl {type name layer iotype x1 y1} $item
	  db_label -kind $iotype -pos nw $layer $name $x1 $y1
	  set px1 [expr $x1 - $padx/2.0]
	  set py1 [expr $y1 - $pady/2.0]
	  set px2 [expr $x1 + $padx/2.0]
	  set py2 [expr $y1 + $pady/2.0]
	  db_paint $layer $px1 $py1 $px2 $py2
	  lappend save_rects [list $layer $px1 $py1 $px2 $py2]
	}
	if { $type == "label" } {
	    setl {type layer kind x1 y1 x2 y2 text} $item
	    if { $layer != "space" } {
	      set layer [techinfo2 layer $layer]
	    }
	    db_label -kind $kind -pos n $layer $text $x1 $y1 $x2 $y2
	}
    }

    if { $ROUTE_OPTION(notch_fill) } {
	puts "filling notches..."
	foreach item $save_vias {
	  eval _stdcell_notch_fill_via $item
	}
	foreach item $save_rects {
	  eval _stdcell_notch_fill_rect $item
	}
    }
}

proc stdcell_show_route {{n ""}} -desc {
  show specified, or all, route solutions, for debugging
} {
    global ROUTE_SOLUTION
    if { $n != "" } {
	_stdcell_route_draw_solution $n
	return
    }
    set solution_n 1
    while {1} {
	:drc catchup
	# create the prop menu
	set prop_list [list [list "Pick solution number" solution_n \
		-number 1 $ROUTE_SOLUTION(cnt) -incr 1]]
	set title "Standard Cell Generator Routing Solutions"
	set message "There were $ROUTE_SOLUTION(cnt) routing solutions."
	set result [prop_menu2 -message $message -title $title $prop_list]

	if { $result == 0 } break  ;# User hit cancel
	_stdcell_route_draw_solution $solution_n
    }
}


proc _stdcell_route_obs {} -desc {
  Generate router obstruction list.
} -doc {
  The generated obstructions already include the separation.
} {
    global fet_route fet_ports fet_info STDCELL LAYINFO ROUTE_DATA

    # Remove old obstruction data, if any.
    catch { unset ROUTE_DATA }

    # db_search only works on expanded subcells!  So expand first.
    set x2 $STDCELL(cell_width)
    set y2 [_layinfo cell_height]
    lay_box 0 0 $x2 $y2
    :expand

    # For poly obstructions, look at diffusion, which is the limiting factor.
    set layers [techinfo2 layer pdiff]
    append layers ,[techinfo2 layer ndiff]
    append layers ,[techinfo2 layer nfet]
    append layers ,[techinfo2 layer pfet]

    set sep [max [techinfo2 sep poly pdiff] [techinfo2 sep poly ndiff]]

    set paintballs [db_search paint -any_cell -area 0 0 $x2 $y2 $layers]
    set n 1
    foreach pball [split [string trim $paintballs "\n"] "\n"] {
	struct max_paint p $pball
	set x1 [expr ${p.x1} - $sep]
	set x2 [expr ${p.x2} + $sep]
	set y1 [expr ${p.y1} - $sep]
	set y2 [expr ${p.y1} + $sep]
	set ROUTE_DATA(obs,poly,$n) "$x1 $x2 $y1 $y2"
	incr n
    }

    # Now m1 obstructions
    set sep [techinfo2 sep m1]
    set layers [techinfo2 layer m1]
    set paintballs [db_search paint -any_cell -area 0 0 $x2 $y2 $layers]
    foreach pball [split [string trim $paintballs "\n"] "\n"] {
	struct max_paint p $pball
	set x1 [expr ${p.x1} - $sep]
	set x2 [expr ${p.x2} + $sep]
	set y1 [expr ${p.y1} - $sep]
	set y2 [expr ${p.y1} + $sep]
	set ROUTE_DATA(obs,m1,$n) "$x1 $x2 $y1 $y2"
	incr n
    }
}


proc _stdcell_init_route_option {} {
    _stdcell_init ROUTE_OPTION(debug) 0
    _stdcell_init ROUTE_OPTION(debug_from_x) 0
    _stdcell_init ROUTE_OPTION(debug_to_x) 999999
    _stdcell_init ROUTE_OPTION(read_file) 0
    _stdcell_init ROUTE_OPTION(keep_avail) 0
    _stdcell_init ROUTE_OPTION(aflag) 0
    _stdcell_init ROUTE_OPTION(fflag) "good"
    _stdcell_init ROUTE_OPTION(all_solutions) 0
    _stdcell_init ROUTE_OPTION(add_pads) 1
    _stdcell_init ROUTE_OPTION(vertical_metal) 0
    _stdcell_init ROUTE_OPTION(least_cost) 1
    #_stdcell_init ROUTE_OPTION(extra_tracks_above) 0
    #_stdcell_init ROUTE_OPTION(extra_tracks_below) 0
    _stdcell_init ROUTE_OPTION(MaxViaTracks) 3
    _stdcell_init ROUTE_OPTION(logfile) "router.log"
    _stdcell_init ROUTE_OPTION(Optimize) 1
    _stdcell_init ROUTE_OPTION(VarChannel) 1
    _stdcell_init ROUTE_OPTION(router) "router"
    _stdcell_init ROUTE_OPTION(notch_fill) 1
    _stdcell_init ROUTE_OPTION(PadSearchDistance) 0.5
    _stdcell_init ROUTE_OPTION(SlimTracks) 0

    #set ROUTE_OPTION(tracks_above) \
    #	[use_first ROUTE_OPTION(tracks_above) STDCELL(tracks_above)]
    #set ROUTE_OPTION(tracks_below) \
    #	[use_first ROUTE_OPTION(tracks_below) STDCELL(tracks_below)]
}


# Call external router.
# pat_route
proc stdcell_route {} {
    global env fet_route fet_ports fet_info STDCELL LAYINFO
    global ROUTE_OPTION ROUTE_SOLUTION MAX_DEVELOPER

    # TODO: for now, you can only route the cell that was just 
    # previously created, so check.
    if { [use_first STDCELL(edit_cell)] != [lay_editcell] } {
      max_error "stdcell_route: error: Can only call Layout Router immediately after \
	running Layout Generator"
      # If max developer, go ahead so we can preset router options.
      if { ! $MAX_DEVELOPER } { return 0 }
    }

    _stdcell_init_route_option

	# Not used:
	#[list "Tracks below center" ROUTE_OPTION(tracks_below) -number 0 -incr 1]
	#[list "Tracks above center" ROUTE_OPTION(tracks_above) -number 0 -incr 1]
	#[list "Extra tracks below" ROUTE_OPTION(extra_tracks_below) -number 0 -incr 1]
	#[list "Extra tracks above" ROUTE_OPTION(extra_tracks_above) -number 0 -incr 1]

    set prop_list [list \
	[list "Fast or Good" ROUTE_OPTION(fflag) -choice {fast good}] \
	[list "Use vertical metal" ROUTE_OPTION(vertical_metal) -binary] \
	[list "Least Cost" ROUTE_OPTION(least_cost) -binary] \
	[list "Add Pads" ROUTE_OPTION(add_pads) -binary] \
	[list "Log file:" ROUTE_OPTION(logfile) -entry] \
	[list "Show All Routes (debug)" ROUTE_OPTION(all_solutions) -binary] \
	[list "Alternate algorithm (debug)" ROUTE_OPTION(aflag) -binary] \
	[list "Keep all avail info (debug)" ROUTE_OPTION(keep_avail) -binary] \
	[list "Debug level" ROUTE_OPTION(debug) -number] \
	[list "Debug from X:"  ROUTE_OPTION(debug_from_x) -number] \
	[list "Debug to X:"  ROUTE_OPTION(debug_to_x) -number] \
	[list "Route from file (debug)" ROUTE_OPTION(read_file) -binary] \
	[list "Optimizer (debug)" ROUTE_OPTION(Optimize) -binary] \
	[list "Variable Channel width (debug)" ROUTE_OPTION(VarChannel) -binary] \
	[list "Notch Fill:" ROUTE_OPTION(notch_fill) -binary] \
	[list "Max Via Tracks" ROUTE_OPTION(MaxViaTracks) -number] \
	[list "Use non-via tracks:" ROUTE_OPTION(SlimTracks) -binary] \
	[list "Pad Search Distance:" ROUTE_OPTION(PadSearchDistance) -number] \
	[list "Router executable:" ROUTE_OPTION(router) -entry] \
	  ]
    set title "Layout Router"
    set result [prop_menu2 -title $title $prop_list]
    if { $result == 0 } {
      # user pressed Cancel
      return 0
    }

    # Call the router.
    set message [stdcell_route_direct]

    if { $message != "" } {
	update
	tk_dialog .dialog {Router Information} $message "" 0 OK
    }

    if { $ROUTE_OPTION(all_solutions) } {
      stdcell_show_route
    }
    return 1
}

proc _stdcell_fet_extension {fetid dir} -desc {
  How far can poly of fetid extend in $dir?
} -doc {
  type is "p" for pfets, "n" for nfets.
  dir is -1 for left extension, 1 for right extension.
} {
  global STDCELL fet_order fet_info
  set type $fet_info($fetid,type)
  set fetcnt [llength $fet_order($type)]

  # Get location of poly gate, including extensions.
  setl {gx1 gy1 gx2 gy2} $fet_info($fetid,g_pos)

  set polysep [techinfo2 sep poly]
  set polywidth [techinfo2 width poly]
  set polydiffsep [techinfo2 sep poly ${type}diff]
  # Compute yext, the distance beyond the end of a fet's poly extension
  # that a wire connected to that poly must be.  It is usually
  # determined by sep from poly to diff, but also check that
  # or poly extension will not stick out beyond the wire.
  set yext [max  \
      [techinfo2 extend poly ${type}fet] \
      [expr $polydiffsep + $polywidth]]

  set fi [lsearch -exact $fet_order($type) $fetid]
  assert {$fi >= 0}

  # li is the index in fet_order of fets to left/right of fetid.
  for {set li [expr $fi + $dir]} {$li >= 0 && $li < $fetcnt} {incr li $dir} {
    set id2 [lindex $fet_order($type) $li]

    # If fetid and id2 are the same net, keep going.
    if { $fet_info($fetid,g) == $fet_info($id2,g) } { continue }

    setl {lx1 ly1 lx2 ly2} $fet_info($id2,g_pos)
    if { $type == "p" } {
      # Invert the y coords so we can use the same code as nfets.
      set height [_layinfo cell_height]
      set fety [expr $height - $fet_info($fetid,y)]
      set id2y [expr $height - $fet_info($id2,y)]
      set gy2 [expr $height - $gy1]
      set ly2 [expr $height - $ly1]
    } else {
      # Top of diffusion of the two fets.
      set fety [expr $fet_info($fetid,y) + $fet_info($fetid,w)]
      set id2y [expr $fet_info($id2,y) + $fet_info($id2,w)]
    }

    # Ymin is the bottom (outside) of the poly wire from $fetid
    set ymin [expr $fety + $yext - $polywidth]

    # There are three cases:
    # If id2 is small enough, we can extend poly wire
    # from fetid completely over the top of it, over any poly wire
    # attached to id2, which, in this case, would also have to
    # extend to the left until it got clear of the poly from from fetid;
    # we are being overly pessimistic in this calculation by assuming
    # that there is a wire connected to id2's gate: there might
    # not be if it was already pre-routed in the outer channel.
    # If id2 is intermediate sized, we might be able
    # to wire above its diffusion, but not over its poly.
    # If the two fets are near the same size, or id2 is bigger,
    # we can wire only up to its diffusion boundary.

    if {[approx [expr $id2y + $yext + $polysep] <= $ymin]} {
	  # We made it over the top of fet id2.  Look at the next fet.
	  continue
    } elseif { [approx [expr $id2y + $polydiffsep] <= $ymin] } {
	  # Made it over the diffusion: can wire up to the id2 poly gate.
	  return [expr $dir < 0 ? $lx2 + $polysep : $lx1 - $polysep]
    } else {
      # Fet id2 is wider.  Stop at diffusion boundary.
      return [expr $dir < 0 ? \
	$fet_info($id2,x) + $fet_info($id2,fetlen) + $polydiffsep : \
	$fet_info($id2,x) - $polydiffsep]
    }
  }

  # We ran into the left or right wall.
  # maintain 1/2 poly sep from wall.
  return [expr $dir < 0 ? $polysep/2.0 : $STDCELL(cell_width) - $polysep/2.0]
}


proc _stdcell_route_data {} -desc {
  Get the route data: terminals and ports
} {
    global ROUTE_DATA STDCELL LAYINFO
    global fet_order fet_info fet_route fet_ports

    set ymid $LAYINFO(stdcell:cell_height)/2.0

    set ROUTE_DATA(cell_height) [_layinfo cell_height]
    set ROUTE_DATA(cell_width) $STDCELL(cell_width)

    # The router will place pads for each port in ROUTE_DATA(ports).

    set ROUTE_DATA(ports) ""
    set ROUTE_DATA(terms,p) ""
    set ROUTE_DATA(terms,n) ""

    # Generate a list of all the gates for the router to
    # determine obstructions.  Gates that were prerouted
    # have been removed from the fet_route(terms,...),
    # and we need them all.
    foreach type {p n} {
      set ROUTE_DATA(allgates,$type) ""
      foreach id $fet_order($type) {
	  lappend ROUTE_DATA(allgates,$type) \
	      $fet_info($id,g_pos)
	  }
    }

    if {0} {

	# Get the connection data from flylines.
	# We will need to look for ports and copy them.

	setl {bx1 by2 bx2 by2} [layt_box exact]
	foreach flyline [db_flylines] {
	    setl {junk labname1 labname2} $flyline
	    foreach labname "$labname1 $labname2" {
		set lab_info [db_search labels $labname]
		if { $lab_info == "" } {
		    msg "Flyline label $labname not found!\n"
		}
		struct max_label lab $lab_info
		set x [expr (${lab.x1} + ${lab.x2}) / 2.0]
		set y [expr (${lab.y1} + ${lab.y2}) / 2.0]
		if { ! [inside_rect $x $y $bx1 $by1 $bx2 $by2] } {
		    continue
		}
		if {$y > $ymid} {
		    set type "p"
		    set y ${lab.y1}
		} else {
		    set type "n"
		    set y ${lab.y2}
		}
		lappend ROUTE_DATA(terms,$type)
		    "$lay $x1 $x2 $y $fet_info($fetid,$pin)"
	    }
	}
    } else {
      foreach net [array names fet_ports] {
	  set type [get_assoc "type" $fet_ports($net)]
	  lappend ROUTE_DATA(ports) "$net $type"
      }

      # This gets the data from last run of the Layout Generator.
      # Create the ROUTE_DATA
      foreach type {p n} {
	set ROUTE_DATA(terms,$type) ""
	foreach thing $fet_route(terms,$type) {
	  setl {fetid gsd} $thing
	  setl {x1 y1 x2 y2} [use_first fet_info($fetid,${gsd}_extent) fet_info($fetid,${gsd}_pos)]
	  if { $gsd == "g" } {
	      # Must be layer name used by router, not name in this tech.
	      set lay "poly"
	      set ex1 [_stdcell_fet_extension $fetid -1]
	      set ex2 [_stdcell_fet_extension $fetid 1]

	      if { $STDCELL(debug) } {
		# DEBUG: draw extensions in m4 and m5 so we can see them.
		if { $type == "p" } {
		  set debugy2 [expr $fet_info($fetid,y) - \
			[techinfo2 sep poly pdiff]]
		  set debugy1 [expr $debugy2 - [techinfo2 width poly]]
		} else {
		  set debugy1 [expr $fet_info($fetid,y) + $fet_info($fetid,w) +\
			[techinfo2 sep poly ndiff]]
		  set debugy2 [expr $debugy1 + [techinfo2 width poly]]
		}
		lay_box $ex1 $debugy1 $x1 $debugy2
		:paint m4
		lay_box $x2 $debugy1 $ex2 $debugy2
		:paint m5
	      }
	  } else {
	      set lay "m1"
	      set ex1 $x1  ;# TODO: Figure this out!
	      set ex2 $x2
	  }
	  if { $type == "p" } { set y $y1 } else { set y $y2 }
	  lappend ROUTE_DATA(terms,$type) \
		"$lay $x1 $x2 $ex1 $ex2 $y $fet_info($fetid,$gsd)"
	}
      }
    }
}

proc _stdcell_notch_fill_rect {layer x1 y1 x2 y2} -desc {
  fill notches around paint in specified area
} {
    set visible [dbt_visible_layers]
    set layer [techinfo2 layer $layer]
    # The closest_edge function works on the visible layers:
    # so remember them, then set the layer.
    :see no *
    :see $layer
#puts "notch_fill $layer $x1 $y1 $x2 $y2"
    set xx1 [expr $x1 - [techinfo sep $layer]]
    set xx2 [expr $x2 + [techinfo sep $layer]]
    set yy1 [expr $y1 - [techinfo sep $layer]]
    set yy2 [expr $y2 + [techinfo sep $layer]]
    # At each corner of the rectangle, search for paint edges:
    # search outward from corner x,y to find point
    # mx,my, and along the edge of the rectangle (one res away
    # from the rectangle edge) from x,y toward the center of the rectangle
    # to find point nx,ny.  Depending on which corner we started
    # from, the notch is bounded by x,y and either mx,ny or nx,my.
    # If this notch is with one layer separation, its a notch: fill it.
    # The list contents are: a bounding box adjacent to the rectangle
    # extending one layer sep out from the rectangle, the first
    # direction to search, the corner to start from, the second
    # direction to search, and the vx,vy that is one res away
    # from that corner.
    foreach thingy [list \
	  [list $xx1 $y1  $x1  $y2  w $x1 $y1 n [expr $x1-[res]] $y1] \
	  [list $xx1 $y1  $x1  $y2  w $x1 $y2 s [expr $x1-[res]] $y2] \
	  [list $x2  $y1  $xx2 $y2  e $x2 $y1 n [expr $x2+[res]] $y1] \
	  [list $x2  $y1  $xx2 $y2  e $x2 $y2 s [expr $x2+[res]] $y2] \
	  [list $x1  $yy1 $x2  $y1  s $x1 $y1 e $x1 [expr $y1-[res]]] \
	  [list $x1  $yy1 $x2  $y1  s $x2 $y1 w $x2 [expr $y1-[res]]] \
	  [list $x1  $y2  $x2  $yy2 n $x1 $y2 e $x1 [expr $y2+[res]]] \
	  [list $x1  $y2  $x2  $yy2 n $x2 $y2 w $x2 [expr $y2+[res]]] \
	  ] {
	setl {sx1 sy1 sx2 sy2 dir1 x y dir2 vx vy} $thingy
	setl {mx my} [closest_edge $x $y $dir1]
	setl {nx ny} [closest_edge $vx $vy $dir2]
	switch $dir1 {
	    "w" { set rx $mx; set ry $ny }
	    "e" { set rx $mx; set ry $ny }
	    "n" { set rx $nx; set ry $my }
	    "s" { set rx $nx; set ry $my }
	}
	# Is point rx,ry within the rectangle, excluding the rect edges?
	if { [approx $sx1 < $rx] && [approx $rx < $sx2] && \
	    [approx $sy1 < $ry] && [approx $ry < $sy2] } {
	    eval db_paint $layer [can_rect [list $x $y $rx $ry]]
	}
    }
    :see no *
    :see [join $visible ,]
}

proc _stdcell_notch_fill_via {type cx cy} -desc {
  fill notches around contact with specified center.
} {
    foreach layer [list poly m1] {
      set layer [techinfo2 layer $layer]
      # amt is half width of this layer in a contact
      set amt [expr [techinfo2 width contact]/2.0 + \
	      [techinfo2 overlap $layer contact]]
      set x1 [expr $cx - $amt]
      set x2 [expr $cx + $amt]
      set y1 [expr $cy - $amt]
      set y2 [expr $cy + $amt]
      _stdcell_notch_fill_rect $layer $x1 $y1 $x2 $y2
    }

  if {0} {
    set cells [db_search cells -area $x1 $y1 $x2 $y2]
    foreach thing [split [string trim $cells] \n] {
      # If its not a via, do nothing
      struct max_cell c $thing
      if { ! [string match {*via*} ${c.id}] } { continue }
      foreach mmilayer [list poly m1] {
	set layer [techinfo2 layer $mmilayer]
	# Get the extent of this layer inside the via.
	# Max does not let you ask for the paint inside a gcell,
	# and yet it fractures the paint separately and returns
	# a separate paint ball tagged with the via cell name!
	# So screw it.  Figure out where the paint is from fundamentals.
	struct max_paint p \
	      [db_search paint -any_cell -area ${c.x1} ${c.y1} ${c.x2} ${c.y2} $layer]
	set xx1 [expr ${p.x1} - [techinfo sep $layer]]
	set xx2 [expr ${p.x2} + [techinfo sep $layer]]
	set yy1 [expr ${p.y1} - [techinfo sep $layer]]
	set yy2 [expr ${p.y2} + [techinfo sep $layer]]
	# Look for any paint in the little rectangles on
	# the four sides of the via.  If any is found,
	# paint the entire rectangle to eliminate the notch.
	foreach side [list \
	  [list $xx1    ${p.y1} ${p.x1} ${p.y2}] \
	  [list ${p.x2} ${p.y1} $xx2    ${p.y2}] \
	  [list ${p.x1} $yy1    ${p.x2} ${p.y1}] \
	  [list ${p.x1} ${p.y2} ${p.x2} $yy2   ] ] {
	  set pballs [eval db_search paint -area $side $layer]
	  # If there is more than one paint rectangle in this
	  # area, it probably indicates a notch error.
	  if { [llength [split [string trim $pballs] \n]] > 1} {
	    eval db_paint $layer $side
	  }
	}
      }
    }
  }
}
  


proc stdcell_route_direct {} -desc {
  call router directly without interactive menus
} {
    global env fet_route fet_ports fet_info STDCELL LAYINFO
    global MAX_DEVELOPER ROUTE_OPTION ROUTE_SOLUTION ROUTE_DATA

    _stdcell_init_route_option

    catch { unset ROUTE_DATA }

    # Get obstructions
    _stdcell_route_obs
    _stdcell_route_data

    # For testing: put router environment into file "router.env".
    # The resulting file can be sourced from a csh so you
    # can run the router without max for testing.

    if { $MAX_DEVELOPER } {
	set fp [open "router.env" w]
    } else {
	set fp ""
    }

    proc _stdcell_setenv {fp name val} {
	global env
	set env($name) $val
	# Also create env file with above environment so router can be
	# run in stand-alone mode for testing:
	if { $fp != "" } { puts $fp "setenv \"$name\" \"$val\"" }
    }

    # Put info in environment for router.
    # We cant just throw DRC_DATA in the environment because
    # the layer names vary.
    foreach thing [list extend,poly,pfet sep,poly,pdiff \
	    enclose,diff,contact enclose,m1,contact] {
	setl {a b c} [split $thing ,]
    	_stdcell_setenv $fp DRC($thing) [techinfo2 $a $b $c]
    }
    foreach thing "poly m1 m2 m3" {
    	_stdcell_setenv $fp DRC(width,$thing) [techinfo2 width $thing]
    	_stdcell_setenv $fp DRC(spacing,$thing) [techinfo2 spacing $thing]
    }

    # Via info
    foreach thing "poly m1" {
	_stdcell_setenv $fp DRC(viawidth,0,$thing) [expr \
	    [techinfo2 width contact] + 2 * [techinfo2 enclose $thing contact] ]
    }
    foreach thing "m1 m2" {
	_stdcell_setenv $fp DRC(viawidth,1,$thing) [expr \
	    [techinfo2 width v12] + 2 * [techinfo2 enclose $thing v12] ]
    }
    foreach thing "m2 m3" {
	_stdcell_setenv $fp DRC(viawidth,2,$thing) [expr \
	    [techinfo2 width v23] + 2 * [techinfo2 enclose $thing v23] ]
    }
    _stdcell_setenv $fp DRC(units) [lindex [mn_units] 1]


    foreach arrayname {STDCELL ROUTE_DATA ROUTE_OPTION LAYINFO} {
	global $arrayname
	foreach item [array names $arrayname] {
	    eval set val \$${arrayname}(\$item)
	    _stdcell_setenv $fp ${arrayname}($item) $val
	}
    }

if {0} {
    foreach item [array names ROUTE_DATA] {
	_stdcell_setenv $fp ROUTE_OPTION($item) $ROUTE_OPTION($item)
    }
    foreach item [array names ROUTE_OPTION] {
	_stdcell_setenv $fp ROUTE_OPTION($item) $ROUTE_OPTION($item)
    }
    foreach item [array names LAYINFO] {
	_stdcell_setenv $fp LAYINFO($item) $LAYINFO($item)
    }
    foreach item [array names fet_route] {
	_stdcell_setenv $fp fet_route.$item $fet_route($item)
    }
    foreach item [array names fet_ports] {
	_stdcell_setenv $fp fet_ports.$item $fet_ports($item)
    }
    foreach item [array names fet_info] {
	_stdcell_setenv $fp fet_info.$item $fet_info($item)
    }
}
    if { $fp != "" } { close $fp }

    # Try to find the router executable.
    set router_exe ""
    set router [use_first ROUTE_OPTION(router) 'router]
    if { [string match {/*} $router] } {
	set router_exe $router
    } else {
	set mmi_local [use_first env(MMI_LOCAL) '$env(MMI_TOOLS)/../mmi_local]
	foreach tmp [list $router \
	    ~/mmi_private/max/$router \
	    $mmi_local/max/$router \
	    $env(MMI_TOOLS)/mmi/max/$router \
	    ] {
	    if {[file exists $tmp]} {
		set router_exe $tmp
		break
	    }
	}
    }

    if { $router_exe == "" } {
	return "Could not find executable: $router"
    }

    if { [use_first ROUTE_OPTION(read_file) '0] } {
	# Debug mode: get result from file "out"
	puts "Reading file out for routing info..."
	if { [catch { set result \
		[exec "/bin/cat" "/home/pat/mmi_private/max/maxtcl/out"] }] } {
	    puts "reading file out FAILED!"
	}
    } else {
	puts "Calling router..."
	# THIS CATCH SHOLD NOT BE NECESSARY???
	set result ""
	if { [catch {
	    set result [ eval exec "$router_exe 2> /dev/tty" ]
	    }] } {
	    puts "Router FAILED!"
	}
    }

    # Result is "" if router failed, otherwise a list of items of the form:
    # 	solution    <- starts a new routing solution.
    # 	segment layername x1 y1 x2 y2
    # 	via x1 y1

    if { $result == "" } {
	return "Router failed to run"
    }

    set message ""

    # Draw routing.
    #puts "result=$result"
    set ROUTE_SOLUTION(cnt) 0
    set result_list [split [string trim $result "\n"] "\n"]
    for {set i 0} {$i < [llength $result_list]} {incr i} {
	set item [lindex $result_list $i]
	if { $item == "" } continue
	if { [string match "result*" $item] } {
	    incr i
	    set message [lindex $result_list $i]
	    continue
	}
	if { [string match "solution*" $item] } {
	    incr ROUTE_SOLUTION(cnt)
	    set ROUTE_SOLUTION($ROUTE_SOLUTION(cnt)) ""
	} else {
	    append ROUTE_SOLUTION($ROUTE_SOLUTION(cnt)) "$item\n"
	}
    }

    if { $ROUTE_SOLUTION(cnt) == 0 } {
	msg "No routing solutions found\n"
    } else {
	_stdcell_route_draw_solution 1
    }

    return $message
}

# Draw a via between layer1 and layer2 with center at x1,y1.
proc _stdcell_draw_via {x1 y1 layer1 layer2} {
    set vias [techinfo vias "" opt]
    if { $vias == "" } {
	msg "Cant paint vias, skipping them."
	return
    }

    # Note: the layer names are canonical names like poly, m1, m2, etc.,
    # the techinfo2 routine returns the vianame in the current technology.
    set vialayer [techinfo2 vianame $layer1 $layer2]
    if { $vialayer == "" || $vialayer == "0" } { return }

    if {[_layinfo draw_vias_using] == "gcells" } {
	# THIS CRASHES MAX!!!
	# 1/31/00: Putting this code back in, hoping crash is fixed now.
	# Try using a gcell or subcell via first.
	if {![msg_catch [list place_gcell via "$x1 $y1" -type $vialayer]]} {
	    # It worked
	    return

	}
	max_error "_stdcell_draw_via: error: drawing via using gcell failed"
    }
    if {[_layinfo draw_vias_using] == "subcells" } {
	if {![msg_catch ":getcell $vialayer child 0 0 parent $x1 $y1"]} {
	    # It worked.  Note: the via cell must have its 0,0 origin
	    # at the location that wants to be at the center of the wire.
	    :expand
	    return
	}
	max_error "_stdcell_draw_via: error: can not find via subcell named $vialayer"
    }

    # Last resort: paint in the via.
    wire_paint_via $vialayer $x1 $y1
    return

    # OLD CODE:

    set tmp [expr [techinfo2 width ${vialayer}] / 2.0]
    lay_box [expr $x1 - $tmp] [expr $y1 - $tmp] \
	[expr $x1 + $tmp] [expr $y1 + $tmp]
    :paint $vialayer
    set tmp [expr [techinfo2 width ${vialayer}]/2.0 + \
	[techinfo2 overlap ${layer1} ${vialayer}]]
    lay_box [expr $x1 - $tmp] [expr $y1 - $tmp] \
	[expr $x1 + $tmp] [expr $y1 + $tmp]
    :paint $layer1
    set tmp [expr [techinfo2 width ${vialayer}]/2.0 + \
	[techinfo2 overlap ${layer2} ${vialayer}]]
    lay_box [expr $x1 - $tmp] [expr $y1 - $tmp] \
	[expr $x1 + $tmp] [expr $y1 + $tmp]
    :paint $layer2
}


# Fets longer than max width turn into multiple fets.
# Number of folds does not have to be a power of 2.
proc _stdcell_fold_fets {type forder} {
    global fet_info STDCELL
    set fetcnt [llength $forder]
    if { $type == "p" } {
	set tracks_above [_layinfo wiring_tracks_above_center]
	set fet_maxw [expr $STDCELL(pfet_ymax) - \
		$STDCELL($tracks_above,pfet_ymin)]
    } else {
	set tracks_below [_layinfo wiring_tracks_below_center]
	set fet_maxw [expr $STDCELL($tracks_below,nfet_ymax) - \
	        $STDCELL(nfet_ymin)]
    }
    for {set i 0} {$i < $fetcnt} {incr i} {
        set id [lindex $forder $i]
	if {$fet_info($id,w) <= $fet_maxw} { continue }
	set nfolds [expr ceil($fet_info($id,w) / $fet_maxw)]
	# This happens if somehow the input forgot to add a micron
	# designator, so the user is trying to generate a 1/4 meter long fet.
	if { $nfolds > 200 } {
	    set ret [warning "Folded fet has many folds ($nfolds folds)" "ok cancel"]
	    if { $ret == 1} {
	      # User cancelled.  I dont know how to longjump out of
	      # here except to call error, which will generate
	      # another popup
	      error "Folded fet has too many folds"
	    }
	}
	set newwidth [uusnap -mask [expr $fet_info($id,w) / $nfolds]]
	# Fix the original fet.
	set fet_info($id,w) $newwidth
	# Add new fets.
	# Orientation does not matter; it will be optimized later.
	for {set j 1} {$j < $nfolds} {incr j} {
	    # User better not use a name like this elsewhere.
	    set newid "${id}_fold$j"
	    _stdcell_fet_info_init $newid $type $fet_info($id,l) $newwidth \
		$fet_info($id,g) $fet_info($id,s) $fet_info($id,d)
	    set forder [linsert $forder $i $newid]
	    incr i
	    incr fetcnt
	}
    }
    return $forder
}


# Count number of times each net is used.  Nets that are only
# used twice are candidates for shared diffusion.
proc _stdcell_count_net_uses {f_use_terms} {
    global STDCELL fet_info fet_ports fet_net_uses fet_order fet_route
    proc _stdcell_count_net {net} {
	global fet_net_uses
	if {![info exists fet_net_uses($net)]} { set fet_net_uses($net) 0 }
	incr fet_net_uses($net)
    }

    # Count how many times each net is mentioned.
    if { $f_use_terms } {
      foreach type [list n p] {
	foreach item $fet_route(terms,$type) {
	  setl {id gsd} $item
	  _stdcell_count_net $fet_info($id,$gsd)
	}
      }
    } else {
      foreach type [list n p] {
	foreach id $fet_order($type) {
	    _stdcell_count_net $fet_info($id,g)
	    _stdcell_count_net $fet_info($id,s)
	    _stdcell_count_net $fet_info($id,d)
	}
      }
    }

    # Nets that are ports can not share diffusion.
    # Incrementing their count prevents it.
    foreach name [array names fet_ports] {
	_stdcell_count_net $name
    }

    # We never want to share diffusion for vdd or gnd.  To prevent it,
    # make sure they are used more than 2 times.
    set fet_net_uses($STDCELL(vdd)) 100
    set fet_net_uses($STDCELL(gnd)) 100
}


if {0} {
    proc _stdcell_is_buried_contact {type entry} -desc {
      Is the contact buried by an inner preroute?
    } -doc {
      FYI, the type is redundant, could be determined from $entry.
    } {
	global fet_route
	setl {id gsd} $entry
	if { $gsd == "g" } {
	    # Its a poly terminal, cant be obscured by metal runs.
	    return 0
	}
	# t1 is the position of the terminal we are interested in.
	set order $fet_route(allterms,$type)
	set t1 [lsearch -exact $order $entry]
	for {set i 0} {$i < [llength $fet_route(inner,m1,$type)]} {incr i 2} {
	    set entry1 [lindex $fet_route(inner,m1,$type) $i]
	    set entry2 [lindex $fet_route(inner,m1,$type) [expr $i+1]]
	    # i1, i2 are the extent of this inner preroute.
	    set i1 [lsearch -exact $order $entry1]
	    set i2 [lsearch -exact $order $entry2]
	    if { $i1 < $t1 && $t1 < $i2} { return 1 }
	}
	return 0
    }
}


proc _stdcell_init_fet_route {} -desc {
  init fet_route from fet_order
} {
    global STDCELL fet_order fet_route fet_info
    catch { unset fet_route }
    foreach type {p n} {
	set fetcnt [llength $fet_order($type)]

	# Make allterms a list of the connections to be wired in the
	# center wiring channel.  Make allcontacts a list of all contacts.
	set allterms ""
	set allcontacts ""

	set id ""
	for {set i 1} {$i <= $fetcnt} {incr i} {
	    set idleft $id
	    set id [lindex $fet_order($type) [expr $i-1]]
	    set idright [lindex $fet_order($type) $i]  ;# may be null
	    # When fets share contacts, we want to save the largest
	    # of the two contacts in the terms.
	    # Look at fet s (source).  If this fet shares on the left,
	    # with an equal or smaller size fet,
	    # then its s net has already been processed.
	    if { ! $fet_info($id,share_diff_left) && \
		( ! $fet_info($id,share_contact_left) || \
		    [approx $fet_info($id,w) > $fet_info($idleft,w)] ) \
		    } {
		set net $fet_info($id,s)
		lappend allcontacts "$id s"
		if { $net != $STDCELL(vdd) && $net != $STDCELL(gnd) } {
		    lappend allterms "$id s"
		}
	    }

	    # Add poly connection to list
	    set net $fet_info($id,g)
	    lappend allterms "$id g"

	    # Add drain connection to list, if necessary.
	    if { ! $fet_info($id,share_diff_right) &&
		( ! $fet_info($id,share_contact_right) || \
		    [approx $fet_info($id,w) >= $fet_info($idright,w)] ) \
		} {
		set net $fet_info($id,d)
		lappend allcontacts "$id d"
		if { $net != $STDCELL(vdd) && $net != $STDCELL(gnd) } {
		    lappend allterms "$id d"
		}
	    }
	}

	# fet_route(terms,p/n) is a list of terminals that need routing.
	# It starts == allterms, but has inner and outer preroutes
	# are removed later.
	set fet_route(terms,$type) $allterms
	set fet_route(allterms,$type) $allterms
	set fet_route(allcontacts,$type) $allcontacts
	set fet_route(outer,poly,$type) ""
	set fet_route(inner,poly,$type) ""
	set fet_route(outer,m1,$type) ""
	set fet_route(inner,m1,$type) ""
	set fet_route(prerouted) ""
	set fet_route(equiv) ""
    }
}



# Function primary purpose is to create fet_route.
# fet_route(allterms,p/n) is a list of all terminals (poly and contact).
# fet_route(allcontacts,p/n) is a list of all contacts.
# fet_route(terms,p/n) is a list of terms to be wired in the center channel.
# Note: fet_route(terms,p/n) is the same as fet_route(allterms,p/n) unless
# draw_m_preroute is called, in which case the inner and outer routes
# are removed from fet_route(terms,p/n).
# fet_route(inner,m1,p/n) is a list of terms to go in the special inner channel.
# fet_route(outer,m1,p/n) is a list of terms to go in the special outer channel.
# Type is p or n for upper or lower row of fets.
proc _stdcell_preroute_m {type} {
    global fet_route fet_info STDCELL fet_ports fet_order

    # Look for two special cases for wiring m1 contacts.
    # See if we can wire any m1 contacts in the top/bottom channels.
    # We can also special-case a wire that goes from a metal contact
    # to another metal contact where the intermediate contacts
    # are to vdd (pfets) or gnd (nfets), or to contacts that
    # were routed in the outer channel.
    # only nets that must be routed normally in the center channel.

    # First accumulate lists: fet_route($channel,m1,$type), where
    # channel is inner/outer and type is n/p.  Each list contains
    # pairs of contacts to be routed in the inner/outer channels.
    # Do the outer routes first, because this may make additional
    # nets available for routing in the special inner channel.

    set cnt [llength $fet_route(allcontacts,$type)]
    foreach channel "outer inner" {
      if { ! [string match *metal* [_layinfo preroute_${channel}]] } {
	continue
      }
      for {set i 0} {$i < $cnt} {incr i} {
	setl {id1 gsd1} [lindex $fet_route(allcontacts,$type) $i]
	set net1 $fet_info($id1,$gsd1)

	# We are looking for contacts to route, so ignore Vdd/gnd contacts.
	if {($type == "p" && $net1 == $STDCELL(vdd)) || \
	    ($type == "n" && $net1 == $STDCELL(gnd)) } {
	    continue
	}
	# If net1 is a port, it must be routed in the center channel
	# to make sure it gets a nice on-grid landing pad.
	# TODO: Not really.  We could put an on-grid port
	# on m2 directly over the contact.
	# if {[info exists fet_ports($net1)]} { continue }

	# If the net is used more than two times, its too complicated
	# to do the special routing, so forget it.
	# TODO: Not really.  We could split it into two nets.
	# Right now, it just leaves the other connections connected
	# to one or the other of the two new parts.
	# We should partition the net so that connects to the left
	# go to the left arm, and connections to the right go to
	# the right arm.
	#	if { $fet_net_uses($net1) > 2} { continue }

	# Look at all contacts to the right of i.
	set minsize [_layinfo route_through_fets_wider_than]
	for {set j [expr $i+1]} {$j < $cnt} {incr j} {
	    setl {id2 gsd2} [lindex $fet_route(allcontacts,$type) $j]
	    set net2 $fet_info($id2,$gsd2)
	    # Dont do special inner routing of fets too small.
	    # The inner routing code does not check for large enough
	    # fet size, and will slaughter them when it tries to
	    # run a wire through the middle of them.
	    if { $channel == "inner" && $fet_info($id2,w) < $minsize } {
		break
	    }
	    # If fets are aligned to the outside of the channel,
	    # dont do an inner channel route of different size fets,
	    # because the ends of the fets are not at the same y location.
	    # This restriction could be relaxed, but the code that 
	    # lays down the wires would have to be alot smarter.
	    if { $channel == "inner" && [_layinfo align_fets] == "outer" && \
		$fet_info($id2,w) != $fet_info($id1,w) } {
		break
	    }
	    if {$net1 == $net2} {
		# This metal connection can be routed specially.
		# However, first check to see if we already prerouted it.
		# This happens when we are spreading fets and a single
		# contact is split apart: it tries to add both an inner
		# and an outer preroute.
		set otmp $fet_route(outer,m1,$type)
		if { $channel == "inner" && \
		    [set itmp [lsearch -exact $otmp "$id1 $gsd1"]] >= 0 && \
		    [lindex $otmp [expr $itmp+1]] == "$id2 $gsd2" } {
		    break

		}
		lappend fet_route($channel,m1,$type) "$id1 $gsd1"
		lappend fet_route($channel,m1,$type) "$id2 $gsd2"
		# Skip i ahead to restart at id2.
		# Remember the "for" loop, above, has an additional incr i.
		set i [expr $j-1]
		break
	    }
	    if {($type == "p" && $net2 == $STDCELL(vdd)) || \
		($type == "n" && $net2 == $STDCELL(gnd)) } {
		# We cant route in the outer (top/bottom) channel, because
		# there is a power connection in the way.
		# Its still OK for the inner channel though,
		# because it is not an obstruction to the inner channel.
		# BUT!  If this is a singleton fet and the OTHER
		# connection is the net we want, we can flip the
		# fet and still route it!
		if { $channel == "outer" } {
		    if {[_stdcell_is_single_fet $id2] && $gsd2 == "s" &&
			    $fet_info($id2,d) == $net1} {
			# Got it!  Flip that there fet.
			# This changes the allcontacts array, so we
			# have to start over from scratch.  Easiest
			# way is just to return and start over.
			_stdcell_flip_fet $id2
			return 1
		    } else {
			break
		    }
		}
	    } else {
		if { $channel == "inner" } {
		    # Its not a vdd/gnd connection, so we probably
		    # can not do an inner special route.
		    # However, we can still do it if this contact
		    # was previously turned into a special outer route.
		    if { [lsearch -exact $fet_route(outer,m1,$type)\
			      "$id2 $gsd2"] < 0 } {
			# This contact was not routed in the outer
			# channel, so it is an obstruction to routing
			# in the special inner-channel, so give up.
			break
		    }
		}
	    }
	}
      }
    }
    return 0
}

proc _stdcell_add_wire {x1 y1 x2 y2 {layer ""}} {
    lay_box $x1 $y1 $x2 $y2
    if { $layer == "" } { set layer [techinfo2 layer m1] }
    :paint $layer
}

proc _stdcell_move_fet {id dx dy} {
    global fet_info
    set fet_info($id,y) [expr $fet_info($id,y) + $dy]
    set fet_info($id,x) [expr $fet_info($id,x) + $dx]
    foreach thing "g_pos s_pos d_pos g_extent s_extent d_extent" {
	if { [info exists fet_info($id,${thing})] } {
	    setl {x1 y1 x2 y2} $fet_info($id,${thing})
	    set fet_info($id,${thing}) \
		"[expr $x1 + $dx] [expr $y1 + $dy] \
		 [expr $x2 + $dx] [expr $y2 + $dy]"
	}
    }
}

# Reduce contact size until inner/outer y dimension clears amt.
# Which arg is "inner" or "outer" for which routing channel to move away from.
# If shared is 0, also resize any shared contact.
proc _stdcell_resize_contact {id gsd which ycenter {shared 0}} {
    global fet_info fet_order STDCELL
    set type $fet_info($id,type)
    setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
    set m1w [expr [techinfo2 min_width m1]/2.0 + [techinfo2 sep m1]]
    switch "$which $type" {
	"inner p" { set y1 [max $y1 [expr $ycenter + $m1w]]; set r +1 }
	"inner n" { set y2 [min $y2 [expr $ycenter - $m1w]]; set r -1 }
	"outer p" { set y2 [min $y2 [expr $ycenter - $m1w]]; set r -1 }
	"outer n" { set y1 [max $y1 [expr $ycenter + $m1w]]; set r +1 }
    }
    # This is the exact contact loc needed to paint a fet.
    set fet_info($id,${gsd}_pos) "$x1 $y1 $x2 $y2"
    append fet_info($id,${gsd},resized) "$r "

    if { $shared == 0 } {
	# If shared contact, call ourselves recursively (once)
	# to also fix the shared contact.
	set i [lsearch -exact $fet_order($type) $id]
	assert { $i >= 0 }
	# If its a shared contact, process the shared contact too.
	if { $gsd == "s" && $fet_info($id,share_contact_left) } {
	    set id_left [lindex $fet_order($type) [expr $i-1]]
	    _stdcell_resize_contact $id_left d $which $ycenter 1
	}
	if { $gsd == "d" && $fet_info($id,share_contact_right) } {
	    set id_right [lindex $fet_order($type) [expr $i+1]]
	    _stdcell_resize_contact $id_right s $which $ycenter 1
	}
    }
}

proc _stdcell_mark_prerouted {id1 gsd1 id2 gsd2 fequiv} -desc {
    The specified terminals have been prerouted; mark them as such.
} -doc {
  if fequiv, also mark the terminals as equivalent terminals.
} {
    global fet_route
    # Mark the terminal as prerouted.
    lappend fet_route(prerouted) "$id1 $gsd1 $id2 $gsd2"
    if { $fequiv } {
	for {set i 0} {$i < [llength $fet_route(equiv)]} {incr i} {
	    set thing [lindex $fet_route(equiv) $i]
	    if { [lsearch -exact $thing "$id1 $gsd1"] >= 0} {
		lappend thing "$id2 $gsd2"
		set fet_route(equiv) [lreplace $fet_route(equiv) $i $i $thing]
		return
	    }
	    if { [lsearch -exact $thing "$id2 $gsd2"] >= 0} {
		lappend thing "$id1 $gsd1"
		set fet_route(equiv) [lreplace $fet_route(equiv) $i $i $thing]
		return
	    }
	}
	# Neither id1 gsd1 or id2 gsd2 in equiv list yet; add them
	lappend fet_route(equiv) [list "$id1 $gsd1" "$id2 $gsd2"]
    }
}

proc _stdcell_remove_term {term} -desc {
  remove a terminal from fet_route(terms,$type)
} {
    global fet_route fet_info fet_net_uses
    setl {id gsd} $term
    set type $fet_info($id,type)
    set tmp1 [lsearch -exact $fet_route(terms,$type) $term]
    assert { $tmp1 >= 0 }
    set fet_route(terms,$type) \
	    [lreplace $fet_route(terms,$type) $tmp1 $tmp1]
    set net $fet_info($id,$gsd)
    incr fet_net_uses($net) -1
}


proc _stdcell_draw_m_preroute {type} {
    global fet_info fet_route fet_order fet_net_uses STDCELL
    set fetcnt [llength $fet_order($type)]

    # Inner preroutes are consolidated here:
    #   the first terminal is left in fet_route(terms,..), and
    #   fet_info(id,g_extent) is set to the total length of the
    #   the prerouted poly.  The second and subsequent terminals are removed.
    # Outer preroutes are sent to mark_prerouted for later processing.

    # Route the outer channel connections.
    # First make a list of fets that need to be moved down.
    # fet_route(outer,...)  has pairs of terminals that must be routed together.
    set outercnt [llength $fet_route(outer,m1,$type)]
    for {set fetn 0} {$fetn < $outercnt} {incr fetn 2} {
	setl {id1 gsd1} [lindex $fet_route(outer,m1,$type) $fetn]
	setl {id2 gsd2} [lindex $fet_route(outer,m1,$type) [expr $fetn+1]]
	set first [lsearch -exact $fet_route(allcontacts,$type) "$id1 $gsd1"]
	set last [lsearch -exact $fet_route(allcontacts,$type) "$id2 $gsd2"]
	assert { $first >= 0 && $last >= 0 }

	# This preroute is going to require moving or resizing
	# all the intermediate contacts, so mark them.
	for {set i [expr $first+1]} {$i < $last} {incr i} {
	    setl {id gsd} [lindex $fet_route(allcontacts,$type) $i]
	    set fets_to_process($id) 1
	}
	# Also mark all fets that share contacts or diff with a fet to be moved.
	# I tried to make it so fets that share contacts do not have
	# to move together if one of the contacts is already a different size,
	# but we need to also check that it is not being moved so far
	# that it goes beyond the end of the adjacent fet,
	# which means the adjacent fet would need a long diff contact.
	# Too hard, and too little gain, so just move them all together.
	if { $last - $first >= 2 } {
	    set i [expr $first+1]
	    while { $i >= 0 } {
		setl {id junk} [lindex $fet_route(allcontacts,$type) $i]
		set fets_to_process($id) 1
		if { $fet_info($id,share_diff_left) || \
		    $fet_info($id,share_contact_left) } {
		    incr i -1
		} else { break }
	    }
	    set i [expr $last-1]
	    while { $i < $fetcnt } {
		setl {id junk} [lindex $fet_route(allcontacts,$type) $i]
		set fets_to_process($id) 1
		if { $fet_info($id,share_diff_right) || \
		    $fet_info($id,share_contact_right) } {
		    incr i
		} else { break }
	    }
	}

	# If the fet is too small to route through, we will have to move
	# it toward the center of the channel.
	# TODO: This may not be right if m1 was not the
	# thing that limited the fet placement?
	set minsize [_layinfo route_through_fets_wider_than]
	if { $type == "p" } {
	    set ycenter [expr $STDCELL(m1_ymax) - [techinfo2 min_width m1]/2.0]
	} else {
	    set ycenter [expr $STDCELL(m1_ymin) + [techinfo2 min_width m1]/2.0]
	}
	set fet_top [expr $STDCELL(m1_ymax) - [techinfo2 sep m1 m1] - \
		[techinfo2 min_width m1] + $STDCELL(diff,m1,overlap)]
	set fet_bot [expr $STDCELL(m1_ymin) + [techinfo2 sep m1 m1] + \
		[techinfo2 min_width m1] - $STDCELL(diff,m1,overlap)]
	foreach id [array names fets_to_process] {
	    if { $fet_info($id,w) < $minsize } {
		if { $type == "p" } {
		    _stdcell_move_fet $id 0 [expr $fet_top - \
			($fet_info($id,y) + $fet_info($id,w))]
		} else {
		    _stdcell_move_fet $id 0 [expr $fet_bot - $fet_info($id,y)]
		}
	    }
	}

	# Resize contacts on the intermediate contacts.
	set first [lsearch -exact $fet_route(allcontacts,$type) "$id1 $gsd1"]
	set last [lsearch -exact $fet_route(allcontacts,$type) "$id2 $gsd2"]
	assert { $first >= 0 && $last >= 0 }
	for {set i [expr $first+1]} {$i < $last} {incr i} {
	    #if { $type == "p" } {
	#	set amt [expr $fet_info($id,y) + $fet_info($id,w) - $fet_top]
	#    } else {
	#	set amt [expr $fet_info($id,y) - $fet_bot]
	#    }
	#    if { $amt <= 0 } { continue }
	    setl {id gsd} [lindex $fet_route(allcontacts,$type) $i]
	    _stdcell_resize_contact $id $gsd outer $ycenter
	}

	# Add wires to make this connection.
	setl {ax1 ay1 ax2 ay2} $fet_info($id1,${gsd1}_pos)
	setl {bx1 by1 bx2 by2} $fet_info($id2,${gsd2}_pos)
	set m1_width [techinfo2 min_width m1]
	set y1 [expr $ycenter - $m1_width/2.0]
	set y2 [expr $ycenter + $m1_width/2.0]
	_stdcell_add_wire $ax1 $y1 $bx2 $y2
	if {$type == "p"} {
	    # This could also have an inner contact, which has
	    # not been resized yet.  Run metal from top of contact
	    # up to inner route, if necessary.
	    _stdcell_add_wire $ax1 $ay2 $ax2 $y2
	    _stdcell_add_wire $bx1 $by2 $bx2 $y2
	} else {
	    _stdcell_add_wire $ax1 $y1 $ax2 $ay1
	    _stdcell_add_wire $bx1 $y1 $bx2 $by1
	}
	_stdcell_mark_prerouted $id1 $gsd1 $id2 $gsd2 1
    }

    # Route the inner channel special connections.
    # The caller already guaranteed that the fets are greater
    # than option:route_through_fets_wider_than, and that they
    # are the same width.
    set innercnt [llength $fet_route(inner,m1,$type)]
    for {set fetn 0} {$fetn < $innercnt} {incr fetn 2} {
	setl {id1 gsd1} [lindex $fet_route(inner,m1,$type) $fetn]
	setl {id2 gsd2} [lindex $fet_route(inner,m1,$type) [expr $fetn+1]]
	setl {ax1 ay1 ax2 ay2} $fet_info($id1,${gsd1}_pos)
	setl {bx1 by1 bx2 by2} $fet_info($id2,${gsd2}_pos)

	# Reduce contact sizes on the intermediate contacts.
	set first [lsearch -exact $fet_route(allcontacts,$type) "$id1 $gsd1"]
	set last [lsearch -exact $fet_route(allcontacts,$type) "$id2 $gsd2"]
	assert { $first >= 0 && $last >= 0 }
	if {$type == "p"} {
	    set y [min $ay1 $by1]
	    set ycenter [expr $y + [techinfo2 min_width m1]/2.0]
	} else {
	    set y [max $ay2 $by2]
	    set ycenter [expr $y - [techinfo2 min_width m1]/2.0]
	}
	for {set i [expr $first+1]} {$i < $last} {incr i} {
	    setl {id gsd} [lindex $fet_route(allcontacts,$type) $i]
	    _stdcell_resize_contact $id $gsd inner $ycenter
	    set fet_info($id,$gsd,buried_contact) 1
	}

	# Add wires to make this connection.
	set m1_width [techinfo2 min_width m1]
	set y1 [expr $ycenter - $m1_width/2.0]
	set y2 [expr $ycenter + $m1_width/2.0]
	_stdcell_add_wire $ax1 $y1 $bx2 $y2
	if {$type == "p"} {
	    if { $ay1 != $by1 } {
		_stdcell_add_wire $ax1 $y1 $ax2 $ay1
		_stdcell_add_wire $bx1 $y1 $bx2 $by1
	    }
	} else {
	    if { $ay2 != $by2 } {
		_stdcell_add_wire $ax1 $ay2 $ax2 $y2
		_stdcell_add_wire $bx1 $by2 $bx2 $y2
	    }
	}

	# Remember the extent of the longest wire.
	if { $fetn > 0} {
	   setl {id1prev gsd1prev} \
		[lindex $fet_route(inner,m1,$type) [expr $fetn-2]]
	   setl {id2prev gsd2prev} \
		[lindex $fet_route(inner,m1,$type) [expr $fetn-1]]
	   if { $id2prev == $id1 && $gsd2prev == $gsd1 } {
	    	# The preroute to the immediate left shares a contact
		# with the current preroute, so its one long preroute.
		# We want to extend the size of id1prev, not id1
		set id1 $id1prev
		set gsd1 $gsd1prev
	   }
	}
	setl {ax1 ay1 ax2 ay2} [use_first fet_info($id1,${gsd1}_extent) fet_info($id1,${gsd1}_pos)]
	setl {bx1 by1 bx2 by2} [use_first fet_info($id2,${gsd2}_extent) fet_info($id2,${gsd2}_pos)]
	set fet_info($id1,${gsd1}_extent) "[min $ax1 $bx1] $ay1 [max $ax2 $bx2] $ay2"
	# Not used:
	#set fet_info($id2,${gsd2}_extent) "[min $ax1 $bx1] $by1 [max $ax2 $bx2] $by2"

	_stdcell_mark_prerouted $id1 $gsd1 $id2 $gsd2 0

	# Remove the second terminal.
	# If the first terminal is the same as the last terminal of
	# the previous loop, it was already deleted, so no action required.
	_stdcell_remove_term "$id2 $gsd2"
    }

    # Now go through connections in fet_route(inner/outer,m1,p/n) and
    # remove those connections from fet_route(terms,p/n)
    # There may be dups in the fet_route(inner/outer,m1,p/n) array,
    # if the same contact is special routed both right and left,
    # or in both inner and outer channels.
    # so be careful to check that we dont delete the same contact twice,
    # which would result in two center-channel connections to the same contact.


  if {0} { ;# removed 2/7
    set delete_cnt 0
    foreach channel "inner" {
	# There are many dups in the list of contacts in the inner/outer
	# channel list, so first construct a list of all the contacts
	# that were wired in the inner/outer channels.
	foreach entry $fet_route($channel,m1,$type) {
	    setl {id1 gsd1} $entry
	    set net1 $fet_info($id1,$gsd1)  ;# Both nets are the same
	    if {![info exists delete_list($net1)]} {
		set delete_list($net1) ""
	    }
	    if { [lsearch -exact $delete_list($net1) "$id1 $gsd1"] < 0 } {
		lappend delete_list($net1) "$id1 $gsd1"
		incr delete_cnt
	    }
	}
    }
    # Now delete_list is a unique list of nets and contacts to delete.
    # Unless the net was completely routed, we need to leave one
    # contact for routing in the center channel; this is the contact
    # that the flyline will be connected to.  So skip deleting
    # the first contact that is not buried by an inner preroute.
    # TODO: Should leave all terms, but mark them as already
    # connected, somehow, so router can choose which one to use.
    # TODO: what we should do is try each of the contacts,
    # and select the one that results in minimum number
    # of flyline crossings, by computing min clique.
    if { $delete_cnt } {
      foreach net [array names delete_list] {
	set skipped 0  ;# Havent skipped any contacts yet.
	if { [llength $delete_list($net)] == $fet_net_uses($net) && \
		! [info exists fet_ports($net)] } {
	    # Net was completely routed: delete all the contacts.
	    set skipped 1
	}
	for {set i 0} {$i < [llength $delete_list($net)]} {incr i} {
	    set entry [lindex $delete_list($net) $i]
	    setl {id gsd} $entry
	    # TODO: Do not connect a flyline that has been cut off
	    # from the central wiring channel by an inner preroute.
	    # Eg: needed for MMI_OA21C.
	    if { ! $skipped && ! $fet_info($id,$gsd,buried_contact) } {
		# Skip deleting (ie, leave for wiring) the first contact
		# that is not buried
		set skipped 1
		continue
	    }
	    _stdcell_remove_term $entry
	}
      }
    }
 }
}

proc _stdcell_con_layer {connect} -desc {
  return layer of flyline connection, or "mixed" if both
} {
    setl {id1 gsd1 id2 gsd2} $connect
    if { $gsd1 == "g" && $gsd2 == "g" } {
      return "poly"
    } elseif { ($gsd1=="d" || $gsd1=="s") && ($gsd2=="d" || $gsd2=="s") } {
      return "m1"
    } else {
      return "mixed"
    }
}

proc _stdcell_count_crossings {connects} -desc {
  return cost of connection list, based on crossings and wire length
} {
  global fet_info _stdcell_tmp
  set crossings 0
  set wirelen 0
  foreach con1 $connects {
    setl {id1 gsd1 id2 gsd2} $con1
    set type1 $fet_info($id1,type)
    set type2 $fet_info($id2,type)
    set layer [_stdcell_con_layer $con1]
    setl {x1 y1 x2 y2} $fet_info($id1,${gsd1}_pos)
    set fx1 $x1
    setl {x1 y1 x2 y2} $fet_info($id2,${gsd2}_pos)
    set fx2 $x1
    set wirelen [expr $wirelen + abs($fx2 - $fx1)]
    if { $type1 == $type2 } {
      # Both ends of this connection are on same side of channel.
      # It is a crossing if other connection is on the same layer
      # and one of its endpoints is inside con1, and the other is outside.
      foreach con2 $connects {
	if { $con1 == $con2 } { continue }
	if { $layer == "mixed" || $layer == [_stdcell_con_layer $con2] } {
	  # Might be a crossing.
	  setl {id3 gsd3 id4 gsd4} $con2
	  setl fx3 $fet_info($id3,${gsd3}_pos)
	  set type3 $fet_info($id3,type)
	  setl fx4 $fet_info($id4,${gsd4}_pos)
	  set type4 $fet_info($id4,type)
	  set inside3 [expr $type3 == $type1 && $fx1 < $fx3 && $fx3 < $fx2]
	  set inside4 [expr $type4 == $type1 && $fx1 < $fx4 && $fx4 < $fx2]
	  if { $inside3 != $inside4 } { incr crossings }
	}
      }
    } else {
      # The ends of this connection are on opposite sides of the channel.
      # It is a crossing if the other connection has one of its endpoints
      # on the left and the other on the right of this connection.
      if {"$type1" == "p"} {
	set x(p) $fx1; set x(n) $fx2
      } else {
	set x(p) $fx2; set x(n) $fx1
      }
      foreach con2 $connects {
	if { $con1 == $con2 } { continue }
	if { $layer == "mixed" || $layer == [_stdcell_con_layer $con2] } {
	  # Might be a crossing.
	  setl {id3 gsd3 id4 gsd4} $con2
	  setl fx3 $fet_info($id3,${gsd3}_pos)
	  set type3 $fet_info($id3,type)
	  setl fx4 $fet_info($id4,${gsd4}_pos)
	  set type4 $fet_info($id4,type)
	  set left3 [expr $fx3 < $x($type3)]
	  set left4 [expr $fx4 < $x($type4)]
	  if { $left3 != $left4 } { incr crossings }
	}
      }
    }
  }
  set cost [expr $crossings * 1000 + $wirelen]
  if { $cost < $_stdcell_tmp(best,cost) } {
    set _stdcell_tmp(best,cost) $cost
    set _stdcell_tmp(best,connect) $connects
  }
}

proc _stdcell_minimize_con {conlist nn} -desc {
  Permute the connection list at nn, accumulate best in _stdcell_tmp
} {
#puts "minimize $nn $conlist"
  global fet_info fet_route _stdcell_tmp
  if { $nn >= [llength $conlist] } {
    _stdcell_count_crossings $conlist
    return
  }
  if { $nn == 0 } {
    set _stdcell_tmp(best,cost) 1e30
    set _stdcell_tmp(best,connect) ""
  }

  setl {id1 gsd1 id2 gsd2} [lindex $conlist $nn]

  set equiv1 "{$id1 $gsd1}"; set equiv2 "{$id2 $gsd2}"
  foreach equiv $fet_route(equiv) {
    setl {eid egsd} [lindex $equiv 0]
    if { $id1 == $eid && $gsd1 == $egsd } {
      set equiv1 $equiv
    }
    if { $id2 == $eid && $gsd2 == $egsd } {
      set equiv2 $equiv
    }
  }

#puts "nn=$nn e1=$equiv1 e2=$equiv2"

  foreach term1 $equiv1 {
    setl {id1 gsd1} $term1
    foreach term2 $equiv2 {
      setl {id2 gsd2} $term2
      set newcon [lreplace $conlist $nn $nn [list $id1 $gsd1 $id2 $gsd2]]
      _stdcell_minimize_con $newcon [expr $nn+1]
    }
  }
  return $_stdcell_tmp(best,connect)
}

proc _stdcell_post_preroute {} -desc {
  after prerouting, fix up fet_route info.
} -doc {
  remove redundant (prerouted) terminals from fet_route(terms),
  generate fet_route(equiv)
} {
    global STDCELL fet_route fet_info fet_net_uses

    # Go through equiv list and remove buried contacts.
    set new_equiv ""
    for {set i 0} {$i < [llength $fet_route(equiv)]} {incr i} {
	set thing [lindex $fet_route(equiv) $i]
	set new_thing ""
	foreach item $thing {
	    setl {id1 gsd1} $item
	    if { ($gsd1 == "d" || $gsd1 == "s") && \
		$fet_info($id1,$gsd1,buried_contact) } {
		_stdcell_remove_term "$id1 $gsd1"
	    } else {
		lappend new_thing $item
	    }
	}
	if { [llength $new_thing] > 1} {
	    lappend new_equiv $new_thing
	}
    }
#puts "old=$fet_route(equiv)"
    set fet_route(equiv) $new_equiv
#puts "new=$fet_route(equiv)"
  
    # Now fet_route(terms,...) is all done, except that it has multiple
    # entries for terminals that already have outer preroutes,
    # which are also noted in fet_route(equiv).  Run though and pick
    # one term from each equiv list that minimizes the number of crossings.

    # Create a default connect list, assuming you use the first
    # terminal of each equiv list.
    foreach net [array names fet_net_uses] {
      # This is probably not necessary: all power/gnd names are
      # normalized on read-in
      if { $net == $STDCELL(vdd) || $net == $STDCELL(gnd) } { continue }
      set newlist ""
      foreach type [list p n] {
	foreach term $fet_route(terms,$type) {
	  setl {id gsd} $term
	  set skipit 0
	  foreach equiv $fet_route(equiv) {
	    # If term appears in an equiv list anywhere but the front, skip it.
	    for {set ei 1} {$ei < [llength $equiv]} {incr ei} {
	      set eterm [lindex $equiv $ei]
	      if { $eterm == $term } { set skipit 1; break }
	    }
	  }
	  if { $net == $fet_info($id,$gsd) && ! $skipit } {
	    setl {ax1 ay1 ax2 ay2} $fet_info($id,${gsd}_pos)
	    # All the numbers are already positive, so numeric sort is easy.
	    # Only need to sort on first two entries.
	    set tmp [format "%08.4f %08.4f %s %s" $ax1 $ay1 $id $gsd]
	    lappend newlist $tmp
	  }
	}
      }
      set netlist($net) [lsort $newlist]
    }
  
    set conlist ""
    foreach net [array names netlist] {
      for {set i 1} {$i < [llength $netlist($net)]} {incr i} {
	  setl {ax1 ay1 aid agsd} [lindex $netlist($net) [expr $i - 1]]
	  setl {bx1 by1 bid bgsd} [lindex $netlist($net) $i]
	  lappend conlist "$aid $agsd $bid $bgsd"
      }
    }

#DEBUG
global fly1
set fly1 $conlist

    # Conlist is now a default list of flylines.
    # We will now minimize the number of crossings:
    if { [_layinfo flyline_crossing_minimization] } {
      set conlist [_stdcell_minimize_con $conlist 0]
    }
    set fet_route(flylines) $conlist

#DEBUG
global fly2
set fly2 $conlist


    # Uniquify the names of nets connected to multiple
    # equivalent terminals, so the router can differentiate them.
    foreach equiv $fet_route(equiv) {
      set nnn 0
      foreach term $equiv {
	setl {id gsd} $term
	# Change the net name to uniquify it.
	set oldnetname $fet_info($id,$gsd)
	set newnetname ${oldnetname}_EQUIV$fet_info($id,type)$nnn
	set fet_info($id,$gsd) $newnetname
	while {1} {
	  set fnd 0
	  foreach con $conlist {
	    setl {id1 gsd1 id2 gsd2} $con
	    if { $fet_info($id1,$gsd1) == $newnetname || \
		 $fet_info($id2,$gsd2) == $newnetname } {
	      if { $fet_info($id1,$gsd1) == $oldnetname || \
		   $fet_info($id2,$gsd2) == $oldnetname } {
		  set fnd 1
		  set fet_info($id1,$gsd1) $newnetname
		  set fet_info($id2,$gsd2) $newnetname
	      }
	    }
	  }
	  if { ! $fnd } { break }
	}

	incr nnn
      }
    }

    # Regen fet_net_uses from terminals we are actually using.
    catch { unset fet_net_uses }
    foreach con $conlist {
      setl {id1 gsd1 id2 gsd2} $con
      foreach net [list $fet_info($id1,$gsd1) $fet_info($id2,$gsd2)] {
	set fet_net_uses($net) [expr [use_first fet_net_uses($net) '0] + 1]
      }
    }

    # Remove unused terms
    foreach type [list n p] {
      set delete_list ""
      foreach term $fet_route(terms,$type) {
	setl {id gsd} $term
	set net $fet_info($id,$gsd)
	if { ! [use_first fet_net_uses($net) '0] } {
	  lappend delete_list "$id $gsd"
	}
      }
      foreach term $delete_list {
	set n [lsearch -exact $fet_route(terms,$type) $term]
	assert { $n >= 0 }
	set fet_route(terms,$type) [lreplace $fet_route(terms,$type) $n $n]
      }
    }

    # We just changed a bunch of net names, so regen fet_net_uses
    _stdcell_count_net_uses 1
}

proc _stdcell_draw_poly_preroute {type} {
    global fet_route fet_info

    foreach thing $fet_route(inner,poly,$type) {
	setl {id1 id2} $thing
	setl {ax1 ay1 ax2 ay2} $fet_info($id1,g_pos)
	setl {bx1 by1 bx2 by2} $fet_info($id2,g_pos)
	if {$type == "p"} {
	  # Bottom of lower pfet
	  set bot [min $fet_info($id1,y) $fet_info($id2,y)]
	  set y2 [expr $bot - [techinfo2 sep poly diff]]
	  set y1 [expr $y2 - [techinfo2 min_width poly]]
	  # Add stubs up to the fet gates,
	  # in case one gate higher/lower than other.
	  _stdcell_add_wire $ax1 $y1 $ax2 $ay1 poly
	  _stdcell_add_wire $bx1 $y1 $bx2 $by1 poly
	} else {
	  # Top of higher nfet
	  set top [max [expr $fet_info($id1,y)+$fet_info($id1,w)] \
			[expr $fet_info($id2,y)+$fet_info($id2,w)] ]
	  set y1 [expr $top + [techinfo2 sep poly diff]]
	  set y2 [expr $y1 + [techinfo2 min_width poly]]
	  # Add stubs down to the fet gates,
	  _stdcell_add_wire $ax1 $y1 $ax2 $ay2 poly
	  _stdcell_add_wire $bx1 $y1 $bx2 $by2 poly
	}
	_stdcell_add_wire $ax1 $y1 $bx2 $y2 poly
    }
    foreach thing $fet_route(outer,poly,$type) {
	setl {id1 id2} $thing
	setl {ax1 ay1 ax2 ay2} $fet_info($id1,g_pos)
	setl {bx1 by1 bx2 by2} $fet_info($id2,g_pos)
	if {$type == "p"} {
	  # Top of higher pfet
	  set top [max [expr $fet_info($id1,y)+$fet_info($id1,w)] \
			[expr $fet_info($id2,y)+$fet_info($id2,w)] ]
	  # The wire must clear poly extensions of intermediate fets.
	  set y1 [expr $top + [techinfo2 extend poly ${type}fet] + \
		[techinfo2 sep poly]]
	  set y2 [expr $y1 + [techinfo2 min_width poly]]
	  # Add stubs down to the fet gates,
	  # in case one gate higher/lower than other.
	  _stdcell_add_wire $ax1 $y1 $ax2 $ay2 poly
	  _stdcell_add_wire $bx1 $y1 $bx2 $by2 poly
	} else {
	  # Bottom of lower nfet
	  set bot [min $fet_info($id1,y) $fet_info($id2,y)]
	  set y2 [expr $bot - [techinfo2 extend poly ${type}fet] - \
		[techinfo2 sep poly]]
	  set y1 [expr $y2 - [techinfo2 min_width poly]]
	  # Add stubs up to the fet gates,
	  _stdcell_add_wire $ax1 $y1 $ax2 $ay1 poly
	  _stdcell_add_wire $bx1 $y1 $bx2 $by1 poly
	}
	_stdcell_add_wire $ax1 $y1 $bx2 $y2 poly
    }
}

proc _stdcell_preroute_poly {type} {
    global fet_info fet_route STDCELL fet_order
    set forder $fet_order($type)

    # Inner preroutes are consolidated here:
    #   the first terminal is left in fet_route(terms,..), and
    #   fet_info(id,g_extent) is set to the total length of the
    #   the prerouted poly.  The second and subsequent terminals are removed.
    # Outer preroutes are sent to mark_prerouted for later processing.

    set fet_route(inner,poly,$type) ""
    set fet_route(outer,poly,$type) ""

    if { [string match *poly* [_layinfo preroute_inner]] } {
	# Route adjacent polys
	# Save the stuff to remove till later so we dont try to
	# modify fet_route as we traverse it.
	set remove_terms ""
	set fetcnt [llength $fet_route(terms,$type)]
	for {set i 0} {$i < $fetcnt} {incr i} {
	    setl {id1 gsd1} [lindex $fet_route(terms,$type) $i]
	    if { $gsd1 != "g" } { continue }
	    for {set j [expr $i+1]} {$j < $fetcnt} {incr j} {
		setl {id2 gsd2} [lindex $fet_route(terms,$type) $j]
		if { $gsd2 != "g" } { continue }
		if { $fet_info($id1,g) == $fet_info($id2,g) } {
		    # Found adjacent poly.  Route and remove from fet_route.
		    setl {ax1 ay1 ax2 ay2} [use_first fet_info($id1,g_extent) fet_info($id1,g_pos)]
		    setl {bx1 by1 bx2 by2} [use_first fet_info($id2,g_extent) fet_info($id2,g_pos)]
		    set fet_info($id1,g_extent) "[min $ax1 $bx1] $ay1 [max $ax2 $bx2] $ay2"
		    set fet_info($id2,g_extent) "[min $ax1 $bx1] $by1 [max $ax2 $bx2] $by2"
		    # We have to remove the shorter of the two fets!
		    if { ($type == "p" && $ay1 >= $by1) || \
			 ($type == "n" && $ay2 <= $by2) } {
			lappend remove_terms "$id1 $gsd1"
		    } else {
			lappend remove_terms "$id2 $gsd2"
		    }
		    _stdcell_mark_prerouted $id1 $gsd1 $id2 $gsd2 0
		    lappend fet_route(inner,poly,$type) "$id1 $id2"
		}
		break
	    }
	}
	foreach term $remove_terms {
	    _stdcell_remove_term $term
	}
    }

    if { [string match *poly* [_layinfo preroute_outer]] } {
	# We have already routed adjacent poly on the inside of the fets,
	# so this will find poly connections that are not adjacent.
	set remove_terms ""
	set fetcnt [llength $fet_route(terms,$type)]
	for {set i 0} {$i < $fetcnt} {incr i} {
	    setl {id1 gsd1} [lindex $fet_route(terms,$type) $i]
	    if { $gsd1 != "g" } { continue }
	    for {set j [expr $i+1]} {$j < $fetcnt} {incr j} {
		setl {id2 gsd2} [lindex $fet_route(terms,$type) $j]
		if { $gsd2 != "g" } { continue }
		if { $fet_info($id1,g) == $fet_info($id2,g) } {
		    # Found poly connection.  Route and remove from fet_route.
		    lappend remove_terms "$id1 $gsd1"
		    _stdcell_mark_prerouted $id1 $gsd1 $id2 $gsd2 1
		    lappend fet_route(outer,poly,$type) "$id1 $id2"
		    # Reset outer loop to begin again at this poly;
		    # need to compensate for the {incr i}
		    set i [expr $j-1]
		    break
		}
	    }
	}

	# Move fets, if necessary, to avoid nwc/pwc layers.

	# Name of layer the outer poly must avoid.
	if { $type == "p" } {
	    set wc nwc
	} else {
	    set wc pwc
	}

	# Determine how much a fet may need to move.
	if { $fet_route(outer,poly,$type) != "" && [_layinfo layers:$wc] } {
	    # Separation required between well contact layer and
	    # fet diffusion layer with one poly run between them.
	    set wc_sep [expr [_layinfo ${wc},width]/2.0 + \
		[techinfo2 sep $wc poly] + [techinfo2 min_width poly] + \
		[techinfo2 sep poly] + \
		[min [techinfo2 extend poly ${type}fet] \
		     [expr [techinfo2 sep poly ${type}diff] + \
		     [techinfo2 min_width poly]]] \
		]

	    # Mark the fets that may need to be moved, in case there are dups.
	    foreach thing $fet_route(outer,poly,$type) {
		setl {id1 id2} $thing
		set i1 [lsearch -exact $forder $id1]
		set i2 [lsearch -exact $forder $id2]
		for {set i $i1} {$i <= $i2} {incr i} {
		    set fets_to_move($i) 1
		}

		# Also move fets that share contact or diffusion
		# with one of the fets we move.
		# 2/10: dont have to do it if the other fet is bigger.
		# 3/00: Still have to do it if the other fet is not
		# big enough so that when you slide the smaller fet up,
		# it sticks out above the top of the fet.
		while {$i1 > 0} {
		    set id [lindex $forder $i1]
		    set idx [lindex $forder [expr $i1-1]]
		    if { ($fet_info($id,share_contact_left) || \
			$fet_info($id,share_diff_left)) && \
			$fet_info($id,w) + $wc_sep >= $fet_info($idx,w) } {
			incr i1 -1
			set fets_to_move($i1) 1
		    } else {
			break
		    }
		}

		# Loop above stops one before beginning, and this
		# loop stops exactly at the end, but doesnt matter
		# because last fet cant share diff or contact right.
		set llen [expr [llength $forder]-1]
		while {$i2 < $llen} {
		    set id [lindex $forder $i2]
		    set idx [lindex $forder [expr $i2+1]]
		    if { ($fet_info($id,share_contact_right) || \
			$fet_info($id,share_diff_right)) && \
			$fet_info($id,w) + $wc_sep >= $fet_info($idx,w) } {
			incr i2 1
			set fets_to_move($i2) 1
		    } else {
			break
		    }
		}
	    }

	    # Move the fets.
	    foreach i [array names fets_to_move] {
		set id [lindex $forder $i]
		if { $type == "p" } {
		    set ytop [expr $fet_info($id,y) + $fet_info($id,w)]
		    set amt [expr [_layinfo cell_height] - $ytop - $wc_sep]
		    if { $amt < 0 } {
			_stdcell_move_fet $id 0 $amt
		    }
		} else {
		    set amt [expr $wc_sep - $fet_info($id,y)]
		    if { $amt > 0 } {
			_stdcell_move_fet $id 0 $amt
		    }
		}
	    }
	}
	if { 0 } { ;# Removed 2/7/99
	    foreach term $remove_terms {
		set tmp [lsearch -exact $fet_route(terms,$type) $term]
		assert { $tmp >= 0 }
		set fet_route(terms,$type) \
		    [lreplace $fet_route(terms,$type) $tmp $tmp]
	    }
	}
    }
}


proc _layinfo {what} -desc {
  return layout info from the LAYINFO array.
} -doc {
  The main purpose of this function is to fill in "default" values.
} {
  global LAYINFO_SCHEMATIC LAYINFO STDCELL
  set ret [use_first LAYINFO_SCHEMATIC($what) \
	LAYINFO(option:$what) LAYINFO(stdcell:$what) \
	LAYINFO($what) 'BADBAD]

  switch -- $what {
    "pwc,width" -
    "nwc,width" {
	if { $ret == "default" } {
	  setl {type junk} [split $what ","]
	  set w1 [expr [techinfo2 width contact] + \
		  2*[techinfo2 enclose ${type} contact]]
	  set w2 [techinfo2 width ${type}]
	  set ret [max $w1 $w2]
	}
    }
    "N/P_boundary" {
	if { $ret == "default" } {
	  set ret [expr $LAYINFO(stdcell:cell_height)/2.0]
	}
    }
    "pad_track" {
	if { $ret == "default" } {
	  set ret [expr round( [_layinfo N/P_boundary] / \
	      $LAYINFO(stdcell:dpc_router_pitch) - 0.5001)]
	}
    }
    "route_through_fets_wider_than" {
	if { $ret == "default" } {
	  # The fet must be wide enough to have room for a contact
	  # plus a metal run over the top of it.
	  set ret [expr \
	      [techinfo2 width v0] + [techinfo2 overlap diff v0] + \
	      [techinfo2 overlap m1 v0] + [techinfo2 sep m1 m1] + \
	      [techinfo2 min_width m1] + $STDCELL(diff,m1,overlap)]
	}
    }
    "m1,router_pad_size" {
	if { $ret == "default" } {
	  # Pad size must be large enough to satisfy min metal1 island size.
	  set area [techinfo2 area m1]
	  if {$area == 0 || $area == ""} {
	    # techinfo failed!  It already printed a message.
	    set ret "0.5 x 0.5"  ;# Use some hokey default
	  } else {
	    set len [expr sqrt($area)]
	    # Round up to .001 boundary.
	    # TODO: THIS SHOULD BE A VARIABLE!!!
	    set len [expr round($len/0.001 + 0.49999)*0.001]
	    set ret "$len x $len"
	  }
	}
    }
    "dpc_router_offset_x" {
	setl {offsetx offsety} [split $LAYINFO(stdcell:dpc_router_offset_x,y) ,]
	return $offsetx
    }
    "dpc_router_offset_y" {
	setl {offsetx offsety} [split $LAYINFO(stdcell:dpc_router_offset_x,y) ,]
	return $offsety
    }
    "cell_router_pitch" {
	if { $ret == "" } { set ret [_layinfo dpc_router_pitch] }
    }
  }
  if { $ret == "BADBAD" } {
    error "invalid _layinfo $what"
  }

  return $ret
}

proc _stdcell_init {thing default {required 0}} {
  global LAYINFO STDCELL ROUTE_OPTION
  if { ! [info exists $thing] } {
    set $thing $default
    if { $required == "req" } {
      msg "warning: no value for $thing in tech file, using default: $default\n"
    }
  }
}

proc _stdcell_calculate_stuff {fetlist {warn 0}} {
    global LAYINFO LAYINFO_HELP fet_info STDCELL

    ############################################################################
    # Optional layers.  Set any variable to 0 to NOT generate that layer.
    # Designated by LAYINFO(layers:<name>)
    ############################################################################
    _stdcell_init LAYINFO(layers:nwc) 1
    _stdcell_init LAYINFO(layers:pwc) 1
    _stdcell_init LAYINFO(layers:nplus) 1
    _stdcell_init LAYINFO(layers:pplus) 1
    _stdcell_init LAYINFO(layers:nwell) 1
    _stdcell_init LAYINFO(layers:bbox_label) 0
    _stdcell_init LAYINFO(layers:prb_layer) 1
    _stdcell_init LAYINFO(layers:power_strap) 1
    _stdcell_init LAYINFO(layers:well_contact) 1

    _stdcell_init STDCELL(stdcell_layers) 1
    _stdcell_init STDCELL(debug) 0

    ############################################################################
    # Other options.
    # Designated by LAYINFO(option:<name>) or LAYINFO(stdcell:<name>)
    # "default" values are filled in the first time this module is called.
    # Cant do it earlier, cause technology file is not read in yet.
    # Most of these defaults will suck, but we do it this way:
    # 1. so we can generate all the error messages about missing tech file
    # variables at once; 2. so we will always generate something.
    ############################################################################

    _stdcell_init LAYINFO(stdcell:power_high_names) "vdd"
    _stdcell_init LAYINFO(stdcell:power_low_names) "gnd vss"
    # The first one in the list is the one that will be used throughout
    # this file, so lets make it easier to use by adding the chosen
    # name to STDCELL.
    set STDCELL(vdd) [lindex $LAYINFO(stdcell:power_high_names) 0]
    set STDCELL(gnd) [lindex $LAYINFO(stdcell:power_low_names) 0]

    set LAYINFO_HELP(stdcell:power_high_names) {-entry \
      -help {The name(s) of the positive power supply. \
      If multiple names, they will all be considered equivalent. \
      The positive power rail is labeled with the first name.}}
    set LAYINFO_HELP(stdcell:power_low_names) {-entry \
      -help {The name(s) of the negative power supply. \
      If multiple names, they will all be considered equivalent. \
      The negative power rail is labeled with the first name.}}

    # RCS header.
    _stdcell_init LAYINFO(stdcell:comment) {}

    # Only the dpc_router_pitch is required, everything else will
    # default from that.  If it is not specified,
    # try to find any pitch that the user specified.
    set pitch [use_first LAYINFO(stdcell:dpc_router_pitch) \
      LAYINFO(stdcell:router_pitch) \
      LAYINFO(stdcell:cell_width_pitch) \
      LAYINFO(stdcell:well_v0_pitch) '1.0]
    _stdcell_init LAYINFO(stdcell:dpc_router_pitch) $pitch req
    set LAYINFO_HELP(stdcell:dpc_router_pitch) {-entry \
      -help {The router pitch that will be used \
      for final (post DPC) routing.  \
      Router landing pads are created on this pitch.}}

    _stdcell_init LAYINFO(stdcell:cell_width_pitch) $pitch
    set LAYINFO_HELP(stdcell:cell_width_pitch) "-number -incr $pitch \
      -help {The cell width will be rounded up to \
      this pitch, normally equal to dpc_router_pitch.}"

    _stdcell_init LAYINFO(stdcell:well_v0_pitch) $pitch
    set LAYINFO_HELP(stdcell:well_v0_pitch) "-number -incr $pitch \
      -help {Well contacts under the power straps, if enabled, will be\
      created on this pitch, normally equal to dpc_router_pitch.}"

    _stdcell_init LAYINFO(stdcell:cell_router_pitch) $pitch
    set LAYINFO_HELP(stdcell:cell_router_pitch) {-entry \
      -help {The pitch that will be used for inter-cell wiring,\
      which may be finer than the dpc_router_pitch.  See also: \
      wiring_tracks_above_center and wiring_tracks_below_center \
      in the Per-Cell Options menu.}}

    set p2 [expr $pitch / 2.0]
    _stdcell_init LAYINFO(stdcell:dpc_router_offset_x,y) "${p2},${p2}"
    set LAYINFO_HELP(stdcell:dpc_router_offset_x,y) {-entry \
      -help {Offset of final router tracks, in microns. in the form: \
      <xoffset>, <yoffset>.  Usually both xoffset and yoffset are equal to \
      one-half the dpc_router_pitch.}}

    # Init this for a 10 track library.
    set tmp [expr $pitch * 10.0]
    _stdcell_init LAYINFO(stdcell:cell_height) $tmp req
    set LAYINFO_HELP(stdcell:cell_height) "-number -incr $pitch\
       -help {Height of cell in microns.}"

    _stdcell_init LAYINFO(stdcell:power_strap_width) 1.0 req
    set LAYINFO_HELP(stdcell:power_strap_width) {-entry \
      Width of optional power straps.}

    _stdcell_init LAYINFO(stdcell:m1,router_pad_size) default
    set LAYINFO_HELP(stdcell:m1,router_pad_size) {-entry -help {\
      The size of metal1 landing pads required for the final router, \
      in the form: <width> x <height> in microns. \
      The default size is determined from the minimum metal1 area rule.}}

    # Fill in default value now, so user can see it.
    set LAYINFO(stdcell:m1,router_pad_size) [_layinfo m1,router_pad_size]

    _stdcell_init LAYINFO(stdcell:N/P_boundary) default
    # Can not leave it "default" or the router croaks.
    set LAYINFO(stdcell:N/P_boundary) [_layinfo N/P_boundary]
    set LAYINFO_HELP(stdcell:N/P_boundary) { -entry \
      -help {Height of Nplus/Pplus boundary from bottom of cell, in microns.}}

    _stdcell_init LAYINFO(stdcell:nwc,width) default
    set LAYINFO_HELP(stdcell:nwc,width) {-entry \
      -help { The size of the nwell contact under the power strap, if any.}}
    _stdcell_init LAYINFO(stdcell:pwc,width) default
      set LAYINFO_HELP(stdcell:pwc,width) {-entry \
      -help { The size of the pwell contact under the power strap, if any.}}

    _stdcell_init LAYINFO(option:wiring_tracks_above_center) 1
    set LAYINFO_HELP(option:wiring_tracks_above_center) {-number 0 \
      -help {Pfets will be folded to preserve wiring space between the \
      pfets and the cell N/P boundary that would allow this many wiring \
      tracks.  The wiring track size is taken from "cell_router_pitch" in \
      the Stdcell Options menu. }}

    _stdcell_init LAYINFO(option:wiring_tracks_below_center) 1
    set LAYINFO_HELP(option:wiring_tracks_below_center) {-number 0 \
      -help {Nfets will be folded to preserve wiring space between the \
      nfets and the cell N/P boundary that would allow this many wiring \
      tracks.  The wiring track size is taken from "cell_router_pitch" in \
      the Stdcell Options menu. }}

    # Temporary: preroutes must default to "no" or "poly" if
    # we are using gcells, because they do not support it.
    _stdcell_init LAYINFO(option:preroute_outer) poly
    set LAYINFO_HELP(option:preroute_outer) {-choice {no metal poly metal+poly}\
      -help {If enabled, the layout generator will attempt to pre-route \
      above and below the fets, where possible. \
      Metal preroutes will reduce the contact sizes \
      and place metal wires directly over fets.}}

    _stdcell_init LAYINFO(option:preroute_inner) poly
    set LAYINFO_HELP(option:preroute_inner) {-choice {no metal poly metal+poly}\
      -help {If enabled, the layout generator will attempt to pre-route \
      between the fets and the inner wiring channel, where possible. \
      Metal preroutes will reduce the contact sizes \
      and place metal wires directly over fets.}}

    # The min size for this should be v0,width + 2 * diff,v0,overlap
    _stdcell_init LAYINFO(option:route_through_fets_wider_than) default
    set LAYINFO_HELP(option:route_through_fets_wider_than) { -entry \
      -help {If option:preroute_inner or preroute_outer is enabled,\
      this option specifies\
      the minimum size fet that may NOT be routed over.  If "default", \
      the min fet width will be set to preserve one contact.}}


    _stdcell_init LAYINFO(option:reverse_stacked_fets) no
    set LAYINFO_HELP(option:reverse_stacked_fets) {\
      -choice {no nfets pfets nfets+pfets} \
      -help {Reverse the layout order of specified type of fets\
      (nfets or pfets) in the layout for stacked fets (fets that share \
      diffusion.)  This is used to ease congestion.}}

    _stdcell_init LAYINFO(option:flylines) 1
    set LAYINFO_HELP(option:flylines) {-binary \
      -help {Create flylines to indicate connectivity from the schematic.}}
    
    _stdcell_init LAYINFO(option:flyline_crossing_minimization) 1
    set LAYINFO_HELP(option:flyline_crossing_minimization) {-binary \
      -help {Rearrange flylines to minimize crossings.\
      This is a time-consuming step, and probably not necessary\
      if you are going to hand route the cell.}}

    _stdcell_init LAYINFO(option:router_pads) contact
    set LAYINFO_HELP(option:router_pads) {-choice {no metal contact} \
      -help {If set, the layout generator will place on-grid router\
      landing pads for nets that are ports.\
      If set to "contact", the layout generator will also provide \
      contacts for nets that are on poly. \
      Note: the pad size is specified by "router_pad_size" in the \
      Stdcell Options menu.}}

    _stdcell_init LAYINFO(option:align_fets) "inner"
    set LAYINFO_HELP(option:align_fets) {-choice {inner outer} \
    -help {If "outer", fets will be placed as close to power rails as possible;\
      if "inner", fets will be placed near the cental wiring channel.}}

    #_stdcell_init LAYINFO(option:fold_pfets_wider_than) "default"
    #_stdcell_init LAYINFO(option:fold_nfets_wider_than) "default"

    _stdcell_init LAYINFO(option:fully_contact_fets) 1
    set LAYINFO_HELP(option:fully_contact_fets) {-enum {no yes} -hide}

    _stdcell_init LAYINFO(option:share_contacts) "all"
    set LAYINFO_HELP(option:share_contacts) {-choice {no same_size all} \
      -help {Controls whether fets will share contacts with neighboring fets. }}

    _stdcell_init LAYINFO(option:pad_track) "default"
    set LAYINFO_HELP(option:pad_track) { -entry \
      -help {If router pads are being created, this specifies the y coord,\
      in dpc_router_pitch units, where pads will be placed.  If "default", \
      pads are placed near the Nplus/Pplus boundary.  \
      See also: option:router_pads. } }

    _stdcell_init LAYINFO(stdcell:draw_fets_using) gcells
    set LAYINFO_HELP(stdcell:draw_fets_using) {-choice {paint subcells gcells} \
      -help {Fets will be created using the specified method. \
      Notes: If you specify any "preroute_" options that require \
      modifications to the fets, the fets will be drawn using paint \
      regardless of the setting of this option. \
      If you specify "subcells" you should flatten the subcells \
      created for fets before writing out standard cell, to avoid naming \
      conflicts among the subcells created for the fets. \
      }}
    _stdcell_init LAYINFO(stdcell:draw_vias_using) gcells
    set LAYINFO_HELP(stdcell:draw_vias_using) {-choice {paint subcells gcells} \
      -help {Vias will be created using the specified method.}}

    _stdcell_init LAYINFO(stdcell:gcell_name_fet) "fet"
    set LAYINFO_HELP(stdcell:gcell_name_fet) {-entry -help {Name of fet gcell,\
      if stdcell:draw_fets_using is "gcells"}}
    _stdcell_init LAYINFO(stdcell:gcell_name_via) "via"
    set LAYINFO_HELP(stdcell:gcell_name_via) {-entry -help {Name of via gcell,\
      if stdcell:draw_vias_using is "gcells"}}

    _stdcell_init LAYINFO(option:spread_fets) no
    set LAYINFO_HELP(option:spread_fets) {-choice {no larger best all} \
      -help {If no, fets will all be jammed to the left.  \
      If yes, the shorter row of fets will be spread out. \
      If "larger", only larger fets will be pushed to the right. \
      If "best", split connected fets at vdd/gnd contacts, or if fets are \
      larger. }}


    # Determine top of pfets (pfet_ymax) and bottom of nfets (ymin).
    # If there is a power strap, move up/down so poly overlap beyond p/ndiff
    # will clear p/nwc under the power strap.

    if { [_stdcell_layer power_strap] } {
	# pfet_ymax and fet_ymin might be limited by poly to p/nwc sep,
	# or by metal metal sep.
	# TODO: If not fully contacted, we could ignore the
	# metal-metal sep rule and push the fets as far as they will go,
	# then reduce the contact size later. For now, fully_contact
	# option is always on in LAYINFO, at top of file.
	if { $LAYINFO(option:fully_contact_fets) } {
	    set power_strap_clearance [expr [techinfo2 sep m1 m1] + \
	    [techinfo2 overlap m1 v0] - [techinfo2 overlap diff v0]]
	} else {
	    set power_strap_clearance 0
	}
	# See about poly to nwc spacing.
	set ymax1 [expr $LAYINFO(stdcell:cell_height) - \
	    [_layinfo nwc,width]/2.0 - [techinfo2 sep poly nwc] - \
	    [techinfo2 extend poly pfet]]
	set ymin1 [expr 0 + \
	    [_layinfo pwc,width]/2.0 + [techinfo2 sep poly pwc] + \
	    [techinfo2 extend poly nfet]]
	# See about metal clearance.
	set ymax2 [expr $LAYINFO(stdcell:cell_height) - \
	    $LAYINFO(stdcell:power_strap_width)/2.0 - \
	    $power_strap_clearance]
	set STDCELL(pfet_ymax) [min $ymax1 $ymax2]
	set ymin2 [expr $LAYINFO(stdcell:power_strap_width)/2.0 + \
		$power_strap_clearance]
	set STDCELL(nfet_ymin) [max $ymin1 $ymin2]
	if { $warn && $ymin2 > $ymin1 } {
	    puts "Note: fet min/max locations are limited by power strap width,"
	    puts "not spacing from fets to well contact; optimal power strap width = $ymin1"
	}

	set STDCELL(m1_ymax) [expr $LAYINFO(stdcell:cell_height) - \
	    $LAYINFO(stdcell:power_strap_width)/2.0 - [techinfo2 sep m1 m1]]
	set STDCELL(m1_ymin) [expr 0 + \
	    $LAYINFO(stdcell:power_strap_width)/2.0 + [techinfo2 sep m1 m1]]
    } else {
	set STDCELL(pfet_ymax) $LAYINFO(stdcell:cell_height)
	set STDCELL(nfet_ymin) 0
	set STDCELL(m1_ymax) $LAYINFO(stdcell:cell_height)
	set STDCELL(m1_ymin) 0
    }
    # diff,m1,overlap is the amount diff overlaps metal on a
    # contact (aka via0) structure.  It is computed from other params.
    set STDCELL(diff,m1,overlap) [expr [techinfo2 overlap diff v0] - \
	[techinfo2 overlap m1 v0]]
    # Left/right edge of cell to fet diffusion.
    # This might be limited by either diff or m1 spacing.
    set STDCELL(fet_xmin) [max [expr [techinfo2 sep diff diff]/2.0] \
	[expr ([techinfo2 sep m1 m1] - $STDCELL(diff,m1,overlap))/2.0]]
    # Amount nplus/pplus must overlap right and left edges.
    if { [_stdcell_layer pplus] } {
      set STDCELL(pplus_side_overlap) \
	[expr [techinfo2 overlap pplus pdiff] - $STDCELL(fet_xmin)]
    }
    if { [_stdcell_layer nplus] } {
      set STDCELL(nplus_side_overlap) \
	[expr [techinfo2 overlap nplus ndiff] - $STDCELL(fet_xmin)]
    }
    if { [_stdcell_layer nwell] } {
      # The nwell overlap is different over the fets and nwc,
      # but we will use the max amount required.
      set STDCELL(nw_side_overlap) [max [techinfo2 overlap nwell nwc] \
	    [expr [techinfo2 overlap nwell pdiff] - $STDCELL(fet_xmin)]]
    }

    # Determine max width of any p/n fet.
    # Used later on to determine the routing channel location.
    # This should really vary across the cell, instead of being fixed.
    set STDCELL(fet_max_width,p) 0
    set STDCELL(fet_max_width,n) 0
    foreach id $fetlist {
	set type $fet_info($id,type)
	set STDCELL(fet_max_width,$type) \
		[max $STDCELL(fet_max_width,$type) $fet_info($id,w)]
    }
    #puts "fet_max_width=$STDCELL(fet_max_width,p),$fet_misc(fet_max_width,p)"

    # Determine maximum fet width for each possible number of main tracks.
    # A main track can have vias in it.
    set STDCELL(cell_height_tracks) [expr \
	round($LAYINFO(stdcell:cell_height) / $LAYINFO(stdcell:dpc_router_pitch))]
    # If there is just one track, it goes at the N/P boundary,
    # because fets cant cross this boundary anyway.
    # If there is a router offset (there usually is),
    # make the track center below the boundary, so the
    # extra half track goes to the pfets.  This is arbitrary
    # and could be suboptimal.
    set rpitch [_layinfo dpc_router_pitch]
    set offsety [_layinfo dpc_router_offset_y]
    set center [expr [_layinfo N/P_boundary] - $offsety - $rpitch/2.0 + .001]
    set center [expr [round_list_scale $center $rpitch] + $offsety]


    # For now, just make it a constant for the whole cell.
    # Get it from the LayGen icon, if any, otherwise from the
    # property menu.
    # TODO: This shouldnt be in the menu at all, or we should
    # read the sue file first to find out what the LayGen icon says.

    #set STDCELL(tracks_below) [use_first STDCELL(tracks_below) \
    #		LAYINFO(option:wiring_tracks_below_center) '1]
    #set STDCELL(tracks_above) [use_first STDCELL(tracks_above) \
    #		LAYINFO(option:wiring_tracks_above_center) '1]

    # Min space from fet (excluding the poly extension, which
    # is therefore added in here)
    # to the center of the adjoining main fat routing channel.
    # The spacing is determined by the poly extension from the fet
    # interfering with the poly contact in the center of the router channel

    set via_width(poly) [expr [techinfo2 width v0] + \
	    2.0 * [techinfo2 overlap poly v0] ]
    set via_width(m1) [expr [techinfo2 width v0] + \
	    2.0 * [techinfo2 overlap m1 v0] ]
    foreach type {n p} {
	set ${type}space [expr \
	    [techinfo2 extend poly ${type}fet] + \
	    [techinfo2 sep poly] + $via_width(poly)/2.0]
    }

    foreach mtracks {0 1 2 3 4} {
	# The main cell router tracks are centered in the available channels,
	# whose center is at center.  Pre-compute the maximum fet width
	# for each number of tracks_above and tracks_below the
	# centre of the cell.
	set track_top_y [expr $center + \
		($mtracks * [_layinfo cell_router_pitch])]
	set track_bot_y [expr $center - \
		($mtracks * [_layinfo cell_router_pitch])]
	set STDCELL($mtracks,pfet_ymin) [expr $track_top_y + $pspace]
	set STDCELL($mtracks,nfet_ymax) [expr $track_bot_y - $nspace]

	if {0} { if { $warn } {
	  set p [expr $STDCELL(pfet_ymax) - $STDCELL($mtracks,pfet_ymin)]
	  set n [expr $STDCELL($mtracks,nfet_ymax) - $STDCELL(nfet_ymin)]
	  puts "Note: for $mtracks tracks: max P/N = $p/$n"
	} }

	#DEBUG:
	set STDCELL($mtracks,track_top_y) $track_top_y

	# NOT CURRENTLY USED:
	if {0} {

	    # Determine location of first skinny track between main tracks and fets.
	    # For the m1, the via_width must be the max of the actual
	    # via width and the router_pad_size.
	    set pad_y(poly) 0
	    setl {x junk pad_y(m1)} [_layinfo m1,router_pad_size]
	    foreach l {poly m1} {
		set STDCELL($mtracks,skinnytrack,p,$l) [expr $track_top_y + \
		    [max $via_width($l) $pad_y($l)]/2.0 + [techinfo2 sep $l] + \
		    [techinfo2 width $l]/2.0 ]
		set STDCELL($mtracks,skinnytrack,n,$l) [expr $track_bot_y - \
		    [max $via_width($l) $pad_y($l)]/2.0 - [techinfo2 sep $l] - \
		    [techinfo2 width $l]/2.0 ]
	    }

	    # Determine maximum_fet_width that allows one poly skinnytrack.
	    # The skinny track location is limited only by the poly
	    # running into the fet diffusion.  We dont worry about the
	    # poly fet extension sticking out, because it is a port
	    # that we know about and will have to route to.

	    set STDCELL($mtracks,skinnyfetwidth,n,poly) [expr \
		    $STDCELL($mtracks,skinnytrack,n,poly) - \
		    [techinfo2 width poly]/2.0 - \
		    [techinfo2 sep poly ndiff] - \
		    $STDCELL(nfet_ymin) ]
	    set STDCELL($mtracks,skinnyfetwidth,p,poly) [expr \
		    $STDCELL(pfet_ymax) - \
		    $STDCELL($mtracks,skinnytrack,p,poly) - \
		    [techinfo2 width poly]/2.0 - \
		    [techinfo2 sep poly pdiff] ]
	    # Determine number of skinny metal tracks.
	    # It is determined by the number of contacts we
	    # need to keep in the fets.
	    # PUNT.  For now, just assume we have 1 skinny metal track.
	}
    }


    #if { $LAYINFO(option:fold_pfets_wider_than) == "default" } {
    #	set LAYINFO(option:fold_pfets_wider_than) [expr \
    #		$STDCELL(pfet_ymax) - \
    #		$LAYINFO(stdcell:N/P_boundary) - $LAYINFO(stdcell:cell_router_pitch)]
    #}
    #    if { $LAYINFO(option:fold_nfets_wider_than) == "default" } {
    #	set LAYINFO(option:fold_nfets_wider_than) [expr \
    #		$LAYINFO(stdcell:N/P_boundary) - \
    #		$STDCELL(nfet_ymin) - $LAYINFO(stdcell:cell_router_pitch) ]
    #    }
}

proc _stdcell_original_net_name {modified_name} -desc {
  return the original name of a net.
} -doc {
  nets that are split for routing purposes are renamed
  with a _EQUIV... suffix.
} {
    regsub {_EQUIV.*} $modified_name "" original_name
    return $original_name
}


# Determine location of on-grid pads for ports.
proc _stdcell_draw_pads {cell_width} {
    global LAYINFO fet_info fet_ports fet_order

    # Determine leftmost and rightmost appearance of each net.
    proc _stdcell_do_one_loc {terminal net coords} {
	upvar leftmost leftmost
	upvar rightmost rightmost
	set net [_stdcell_original_net_name $net]
	setl {newx1 newy1 newx2 newy2} $coords
	set newx [expr ($newx1 + $newx2) / 2.0]
	# First gate seen is for the left-most pfet, which is where
	# we will place inputs.
	if { $terminal == "g" && ! [info exists leftmost($net)] } {
	    set leftmost_g($net) $newx
	}
	if { ! [info exists leftmost($net)] || \
		[expr $newx < $leftmost($net)]} {
	    set leftmost($net) $newx
	}
	if { ! [info exists rightmost($net)] || \
		[expr $newx > $rightmost($net)]} {
	    set rightmost($net) $newx
	}
    }

    # Place input ports near the left-most pfet gate to the port.
    # Place non-input ports near the right-most terminal connected to any port.
    set anygates ""
    foreach type "p n" {
      foreach id $fet_order($type) {
	if { ! $fet_info($id,share_diff_left) } {
	    _stdcell_do_one_loc "s" $fet_info($id,s) $fet_info($id,s_pos)
	}
	_stdcell_do_one_loc "g" $fet_info($id,g) $fet_info($id,g_pos)
	set anygates "$anygates $fet_info($id,g)"
	if { ! $fet_info($id,share_diff_right) } {
	    _stdcell_do_one_loc "d" $fet_info($id,d) $fet_info($id,d_pos)
	}
      }
    }

    set pitch [_layinfo dpc_router_pitch]
    set offsetx [_layinfo dpc_router_offset_x]
    set offsety [_layinfo dpc_router_offset_y]

    set new_cell_width $cell_width
    while {1} {
	set max_gridx [expr round($new_cell_width / $pitch) -1]
	set min_gridx 1
	# If the grid offset is exactly 0.5, we get to add one more grid column.
	if { [_stdcell_approx $offsetx [expr $pitch/2.0] [res]] } {
	    set min_gridx 0
	}

	# See if the cell is big enough for all the pads it needs.
	set nports [array size fet_ports]
	if {$max_gridx - $min_gridx + 1 < $nports} {
	    set new_cell_width [expr $new_cell_width + $pitch]
	    continue   ;# Try again
	}
	break
    }

    # Determine the order in which the pads should be laid down,
    # from left to right.  padorder is a list of two element lists,
    # each contains the X coord of something hooked to the port pad,
    # followed by the port name.
    set padorder ""
    foreach net [array names fet_ports] {
	if { [get_assoc "type" $fet_ports($net)] == "input" } {
	    # The input port will be placed next to the leftmost gate,
	    # if any, else (if the input is to a pass gate and does
	    # not connect to any gates) to any convenient fet terminal.
	    if { [info exists leftmost_g($net)] } {
	      lappend padorder "$leftmost_g($net) $net"
	    } else {
	      lappend padorder "$leftmost($net) $net"
	    }
	} else {
	    lappend padorder "$rightmost($net) $net"
	}
    }
    set padorder [lsort -real -index 0 $padorder]

    # The gridpoints array keeps track of which gridpoints have been used.
    # Init the gridpoints by entering the ports in the lowest indicies,
    # ie, the initial pad placement is as far left as possible.
    # The unused upper indicies will be ""
    set i 0
    for {set g $min_gridx} {$g <= $max_gridx} {incr g; incr i} {
	set gridpoints($g) [lindex $padorder $i]
    }

    # Now we want to lay down the pads as close to their intended
    # locations as possible, but without changing the order,
    # which would introduce wire crossings.  Work from right to left
    # through the pad gridpoints, moving each pad as far right as possible.

    for {set g $max_gridx} {$g >= $min_gridx} {incr g -1} {
	set thingy $gridpoints($g)
	if { $thingy == "" } { continue }
	setl {padcx net} $thingy
	# Determine the most desirable gridpoint for this pad.
	set best_gridx [expr round(($padcx - $offsetx - 0.01)/$pitch)]
	# If the location is within a half grid of the edge of the
	# cell, it will land on the cell edge, so bound it by min/max_gridx.
	set best_gridx [min $best_gridx $max_gridx]
	set best_gridx [max $best_gridx $min_gridx]
	if { $best_gridx > $g } {
#puts "g=$g best=$best_gridx max=$max_gridx min=$min_gridx"
	    # This pad would like to be farther to the right.
	    # See if there are unused gridpoints to accomodate it.
	    for {set j [expr $g+1]} {$j <= $best_gridx} {incr j} {
		if { $gridpoints($j) == "" } {
		    set gridpoints($j) $gridpoints([expr $j-1])
		    set gridpoints([expr $j-1]) ""
		} else {
		    break
		}
	    }
	}
    }

    for {set gridx $min_gridx} {$gridx <= $max_gridx} {incr gridx} {
#puts "PAD placement $net, gates=$anygates"
	set thingy $gridpoints($gridx)
	if { $thingy == "" } { continue }
	setl {padcx net} $thingy
	set gridy [_layinfo pad_track]
	# x and y locations of center of pad.
	set x [expr $gridx * $pitch + $offsetx]
	set y [expr $gridy * $pitch + $offsety]
	# Save pad location for later connection with flylines.
	lappend fet_ports($net) "padloc {$x $y}"
	# wx and wy are width of router contact pad.
	setl {wx wy} [split [_layinfo m1,router_pad_size] "x"]
	lay_box [expr $x - $wx / 2.0] [expr $y - $wy / 2.0] \
	    [expr $x + $wx / 2.0] [expr $y + $wy / 2.0]
	if { $LAYINFO(option:router_pads) == "metal" } {
	    :paint [techinfo2 layer m1]
	} else {
	    :paint [techinfo2 layer m1]
	    # If the net is hooked to any poly,
	    # then draw a via under the pad.
	    if { [lsearch -exact $anygates $net] >= 0 } {
		_stdcell_draw_via $x $y poly m1
	    } else {
		:paint [techinfo2 layer m1]
	    }
	}
    }
    if { $new_cell_width != $cell_width } {
       warning "Cell width increased to allow room for pads"
    }
    return $new_cell_width
}


# For debugging.  If id is "all", dump all fets in callers fet_order list.
proc _stdcell_fet_dump {id} {
    global fet_info fet_net_uses fet_order
    if { $id == "all" } {
	foreach type "n p" {
	    for {set i 0} {$i < [llength $fet_order($type)]} {incr i} {
	      set id [lindex $fet_order($type) $i]
	      _stdcell_fet_dump $id
	    }
	}
	return
    }
    puts "id=$id type=$fet_info($id,type) \
	l=$fet_info($id,l) w=$fet_info($id,w) \
	diff_left=$fet_info($id,share_diff_left) \
	diff_right=$fet_info($id,share_diff_right)"
    puts "contact_left=$fet_info($id,share_contact_left) \
	contact_right=$fet_info($id,share_contact_right) \
	long=$fet_info($id,long_cont_left),$fet_info($id,long_cont_right) \
	ori=$fet_info($id,ori) flipok=$fet_info($id,flipok)"
    set s $fet_info($id,s); set g $fet_info($id,g); set d $fet_info($id,d)
    puts "nets: s=$s:$fet_net_uses($s) g=$g:$fet_net_uses($g) d=$d:$fet_net_uses($d)"
}

# Normalize power and ground names to vdd and gnd
# This is easier than doing a case insensitive comparison everywhere else.
proc _stdcell_fet_fixnetname {netname} {
    global LAYINFO
    set tmpname [string tolower $netname]
    set phigh [string tolower $LAYINFO(stdcell:power_high_names)]
    set plow [string tolower $LAYINFO(stdcell:power_low_names)]
    if { [lsearch -exact $phigh $tmpname] >= 0 } {
      return [lindex $LAYINFO(stdcell:power_high_names) 0]
    }
    if { [lsearch -exact $plow $tmpname] >= 0 } {
      return [lindex $LAYINFO(stdcell:power_low_names) 0]
    }
    return $netname
}

proc _stdcell_fet_info_init {id type l w g s d} {
    global fet_info
    set fet_info($id,type) [string tolower $type]
    set fet_info($id,l) [uusnap -mask $l]
    set fet_info($id,w) [uusnap -mask $w]
    set fet_info($id,g) $g
    set fet_info($id,s) $s
    set fet_info($id,d) $d
    # Set these to inner/outer to route metal
    # Flipok is 1 if fet can be flipped left to right
    # This is unset when an orientation is chosen.
    set fet_info($id,flipok) 1
    # For debugging only: ori is 1 if unflipped, -1 if flipped.
    set fet_info($id,ori) 1
    # long_cont_left/right is true if the fet gets a longer diffusion
    # arm to avoid a DRC because it is next to a longer fet on that side.
    set fet_info($id,long_cont_left) 0
    set fet_info($id,long_cont_right) 0
    set fet_info($id,share_diff_left) 0
    set fet_info($id,share_diff_right) 0
    set fet_info($id,share_contact_left) 0
    set fet_info($id,share_contact_right) 0
    set fet_info($id,s,buried_contact) 0 ;# Contact does not reach inner channel
    set fet_info($id,d,buried_contact) 0 ;# Contact does not reach inner channel
    set fet_info($id,s,resized) ""
    set fet_info($id,d,resized) ""
}

# Are the two numbers approximately the same within "within" accuracy?
proc _stdcell_approx {a b within} {
    set diff [expr $a - $b]
    if { $diff <= $within && $diff >= [expr 0 - $within] } {
	return 1
    } else {
	return 0
    }
}

proc _stdcell_is_on_grid {val} {
    global LAYINFO
    set grid [res -mask]
    return [_stdcell_approx \
		[expr round($val / $grid)] \
		[expr $val / $grid] \
		[expr $grid / 1000]  ]
}

# This function will go away when the max grid is fixed...
# Check the LAYINFO param to make sure it will still
# fit on the grid after being divided by 2.
proc _stdcell_check_val_on_grid {param} {
    global LAYINFO
    set grid [expr [res -mask] * 2.0]
    set val $LAYINFO($param)
    if { ! [_stdcell_is_on_grid [expr $val / 2.0]]} {
	puts "error: LAYINFO($param) = $val must be evenly divisible by $grid"
	return 1
    }
    # Thats the same as making sure it is divisible by (grid*2).
    #if { ! [_stdcell_approx \
    #		[expr round($val / $grid)] \
    #		[expr $val / $grid] \
    #		[expr $grid / 1000]  ]} {
    #	 set tmp1 [expr 1.0 * round($val / $grid)]
    #	 set tmp2 [expr $val / $grid]
    #	puts "error: LAYINFO($param) = $val must be evenly divisible by $grid"
    #	return 1
    #}
    return 0
}

# create a new cell if there isn't one in max of this name
# From Lee
proc _stdcell_goto_cell {cell_path} {

  global CELL

  set cell_name [file tail $cell_path]
  if {![cell_in_memory $cell_name]} {
    # create the new cell
    puts "Creating cell $cell_path"
    db_cell_new $cell_name ${cell_path}.max
    # goto the cell
    cell_load $cell_name

  } else {
    # goto the cell
    cell_load $cell_name

    # toast the contents of the cell
    eval sel_area [lay_bbox]
    :delete
  }

  db_flyline -delete
}


proc _stdcell_get_fet {id gsd} -desc {
  Return the id to the side of this fet.  gsd is "s" or "d".
} {
    global fet_info fet_order
    set type $fet_info($id,type)
    set i [lsearch -exact $fet_order($type) $id]
    assert {$i != -1}
    if { $gsd == "s" } { incr i -1 } else { incr i 1 }
    return [lindex $fet_order($type) $i]
}

# TODO: This does not muck with pads, vdd/gnd.
# Need to copy that code from old_place_flylines
proc _stdcell_flylines {{conlist ""}} {
  global fet_ports fet_info fet_route
  if { ! [_layinfo flylines] } { return }
  if { $conlist == "" } { set conlist $fet_route(flylines) }
  foreach con $conlist {
    setl {id1 gsd1 id2 gsd2} $con
    set label1 $fet_info($id1,$gsd1,label)
    set label2 $fet_info($id2,$gsd2,label)
    # Is it a port with a pad?
    # If so, connect all flylines on this net to the pad.
    set net $fet_info($id1,$gsd1)
    # Nets that have been split will have been renamed with _EQUIV... suffix.
    # They must all hook onto the original label.
    set net [_stdcell_original_net_name $net]
    if { [_layinfo router_pads] != "no" && [info exists fet_ports($net)]} {
      #eval [center_bbox [lindex $new_fet_net_labels($net) 0]]
      set porttype [get_assoc "type" $fet_ports($net)]
      setl {padx pady} [get_assoc "padloc" $fet_ports($net)]
      db_label -kind $porttype -pos center [techinfo2 layer m1] $net $padx $pady
      db_flyline $label1 $net
      db_flyline $label2 $net
    } else {
      db_flyline $label1 $label2
    }
  }
}

proc _stdcell_old_place_flylines {} {
    global LAYINFO STDCELL fet_info fet_route fet_net_uses fet_ports
    global fet_net_labels

# if {0} {
#    # Create fet_net_labels from fet_route
#    foreach type "p n" {
#	for {set i 0} {$i < [llength $fet_route(terms,$type)]} {incr i} {
#	    setl {id gsd} [lindex $fet_route(terms,$type) $i]
#	    set net $fet_info($id,$gsd)
#	    # Make the poly connections to the exposed end of the poly,
#	    # not into the middle of the gate.
#	    if { $gsd == "g" } {
#		setl {x1 y1 x2 y2} $fet_info($id,${gsd}_pos)
#		if { $type == "p" } {
#		    set y2 [expr $y1 + [techinfo2 overlap poly gate]]
#		} else {
#		    set y1 [expr $y2 - [techinfo2 overlap poly gate]]
#		}
#		lappend fet_net_labels($net) "$x1 $y1 $x2 $y2"
#	    } else {
#		lappend fet_net_labels($net) $fet_info($id,${gsd}_pos)
#	    }
#	}
#    }
# }

    set discard_list ""
    foreach item $fet_route(prerouted) {
	# Throw away one of the two terminals.
	# If one of the terminals was shortened and covered
	# by an inner preroute, discard the other.
	setl {id1 gsd1 id2 gsd2} $item
	if { ($gsd1 == "d" || $gsd1 == "s") && \
	    $fet_info($id1,$gsd1,buried_contact) } {
	    set discard "$id1 $gsd1"
	} elseif { ($gsd2 == "d" || $gsd2 == "s") && \
	    $fet_info($id2,$gsd2,buried_contact) } {
	    set discard "$id2 $gsd2"
	# If one terminal is already discarded, then discard the other.
	} elseif {[lsearch -exact $discard_list "$id1 $gsd1"] >= 0} {
	    set discard "$id2 $gsd2"
	} elseif {[lsearch -exact $discard_list "$id2 $gsd2"] >= 0} {
	    set discard "$id1 $gsd1"
	} else {
	    # Keep the left most terminal
	    setl {x1 junk junk junk} $fet_info($id1,g_pos)
	    setl {x2 junk junk junk} $fet_info($id2,g_pos)
	    if { $x1 < $x2 } {
		set discard "$id2 $gsd2"
	    } else {
		set discard "$id1 $gsd1"
	    }
	}
	lappend discard_list $discard
	setl {id gsd} $discard
	if { ($gsd == "d" && $fet_info($id,share_contact_right)) ||
	     ($gsd == "s" && $fet_info($id,share_contact_left)) } {
	    # Must discard the shared terminal also.
	    set id3 [_stdcell_get_fet $id $gsd]
	    if { $gsd == "d" } { set gsd3 "s" } else { set gsd3 "d" }
	    lappend discard_list "$id3 $gsd3"
	}
    }

    # Sort the flylines.  Then when a single net has multiple
    # flylines, they will be more or less ordered and non-crossing,
    # rather than crossing back and forth far across the stdcell.
    foreach net [array names fet_net_labels] {
	set newlist ""
	foreach connect $fet_net_labels($net) {
	    setl {ax1 ay1 ax2 ay2 id gsd alabel} $connect
	    # If this terminal was already prerouted, dont draw
	    # any flylines to it.
	    if {[lsearch -exact $discard_list "$id $gsd"] >= 0} {
		continue
	    }
	    # All the numbers are already positive, so numeric sort is easy.
	    # Only need to sort on first two entries.
	    set tmp [format "%08.4f %08.4f %s %s %s %s %s" \
		$ax1 $ay1 $ax2 $ay2 $id $gsd $alabel]
	    lappend newlist $tmp
	}
	#puts "old=$fet_net_labels($net)"
	#puts "new=$newlist"
	set new_fet_net_labels($net) [lsort $newlist]
    }
 
 
    # now put in the ports, vdd, gnd, and fly lines
    if { $LAYINFO(option:flylines) } {
      foreach net [array names new_fet_net_labels] {
	#puts "net $net connects to: $new_fet_net_labels($net)"
	if {$STDCELL(debug)} { puts "flylines $net $new_fet_net_labels($net)" }

	# Is it a port with a pad?
	# If so, connect all flylines on this net to the pad.
	if { $LAYINFO(option:router_pads) != "no" && \
		[info exists fet_ports($net)]} {
	    #eval [center_bbox [lindex $new_fet_net_labels($net) 0]]
	    set porttype [get_assoc "type" $fet_ports($net)]
	    setl {padx pady} [get_assoc "padloc" $fet_ports($net)]
	    lay_box $padx $pady $padx $pady
	    :label -kind $porttype $net c
	    # Connect all flylines to the new pad.
	    for {set i 0} {$i < [llength $new_fet_net_labels($net)]} {incr i} {
		setl {ax1 ay1 ax2 ay2 id gsd alabel} [lindex $new_fet_net_labels($net) $i]
		#set alabel [_stdcell_unique_label]
		#lay_box $ax1 $ay1 $ax2 $ay2
		#:label -kind hidden $alabel
		set alabel $fet_info($id,$gsd,label)
		db_flyline $alabel $net
	    }
	    continue
	}


	# Hook all vdd/gnd points to existing labels.
	# Note that power to the fets was already done.
	# Any remaining vdd/gnd wires are probably to fet gates.
	set name [string tolower $net]
	if {$name == $STDCELL(vdd) || $name == $STDCELL(gnd)} {
	    # If there is no power-strap layer, where can we hook these?
	    if { ! [_stdcell_layer power_strap] } { continue }

	    for {set i 0} {$i < [llength $new_fet_net_labels($net)]} {incr i} {
		setl {ax1 ay1 ax2 ay2 id gsd alabel} [lindex $new_fet_net_labels($net) $i]
		if { [_stdcell_layer power_strap] && \
			( $gsd == "d" || $gsd == "s" ) } {
		    # We already connected this source or drain to power strap.
		    continue
		}
		#set alabel [_stdcell_unique_label]
	        #eval lay_box [lindex $new_fet_net_labels($net) $i]
	        #:label -kind hidden $alabel
		set alabel $fet_info($id,$gsd,label)
		db_flyline $name $alabel
	    }
	    continue
	}
    
	for {set i 1} {$i < [llength $new_fet_net_labels($net)]} {incr i} {
	    setl {ax1 ay1 ax2 ay2 aid agsd alabel} [lindex $new_fet_net_labels($net) [expr $i - 1]]
	    setl {bx1 by1 bx2 by2 bid bgsd blabel} [lindex $new_fet_net_labels($net) $i]
	    # If the flylines are horizontal, they get laid on top
	    # of each other.  To prevent this, nudge them a little.
	    if { $ay1+$ay2 == $by1+$by2 } {
		set y [expr $ay1 + $ay2]
		if {! [info exists nudge_cnt($y)] } {
		    set nudge_cnt($y) 0
		} else {
		    incr nudge_cnt($y)
		}
		set nudge [expr - $nudge_cnt($y) * [res -user]]
	    } else { set nudge 0 }
	    #set alabel [_stdcell_unique_label]
	    #lay_box $ax1 $ay1 $ax2 [expr $ay2+$nudge]
	    #:label -kind hidden $alabel
	    #set blabel [_stdcell_unique_label]
	    #lay_box $bx1 $by1 $bx2 [expr $by2+$nudge]
	    #:label -kind hidden $blabel
	    set alabel $fet_info($aid,$agsd,label)
	    set blabel $fet_info($bid,$bgsd,label)
	    db_flyline $alabel $blabel
	}
      }
    }
}



# By pat, 1-99.
# Reads extended sim format, which sue has been modified to create.
# This is like regular sim format, but includes comments that indicate:
# instance names, subcells and locations in the schematic.
# If filename is "", prompt for filename.
# Example:
# A in0 input
# | device n_1 0 0
# n in0 net_2 net_1 24 120
# | begin inverter 260 -50
# | device inverter.n 550 360
# n net_1 gnd out 24 120
# | device inverter.p 550 200
# p net_1 vdd out 24 240
# | end inverter
# | device p_1 160 -100
# p in1 vdd net_1 24 120
#
proc stdcell_load_direct {filename} -desc {
  reads in a sim file and places fets and creates fly lines for circuit
} {
    global STDCELL LAYINFO
    global fet_order

    #if { ! [_stdcell_check_license -return] } { return }

    # OK, actually check out the license.
    # There is a race condition here, in case someone else manages
    # to check out the license before we get it.
    # The race is *extremely* unlikely to actually occur, and
    # fixing it requires changes to license_check and licenseCheck.h.
    license_check max_laygen

    # This indicates that we now have the license.
    set license_key [expr ( [pid] * 3 ) % 97]
    set STDCELL(x_info) $license_key
    # Add some additional unused camouflage.
    set STDCELL(y_info) [expr ( [pid] * 13 ) % 97]

    # unset stops at the first variable that does not exist.
    # You MUST unset each variable in a separate statement.
    # If you have an unset without a global, nothing happens,
    # so keep the globals on the same line as the unset.
    # Note that STDCELL is NOT unset.  We save some stuff there. (debug)
    global fet_info; catch {unset fet_info}
    global fet_route; catch {unset fet_route}
    global fet_net_uses; catch {unset fet_net_uses}
    global fet_net_labels; catch {unset fet_net_labels}
    global fet_ports; catch {unset fet_ports}
    global laygen_info; catch {unset laygen_info}
    global LAYINFO_SCHEMATIC; catch {unset LAYINFO_SCHEMATIC}
    if {![info exists STDCELL(debug)]} {
	set STDCELL(debug) 0
    }

    # Check everything that we will have to divide by 2 to make
    # sure it will still be on grid.

    # TODO: this doesnt work any more with Lees new tech files.
    # TODO: put this back in?
    if {0} {
	if {[_stdcell_check_val_on_grid gate,gate,sep] || \
	    [_stdcell_check_val_on_grid v0,width] || \
	    [_stdcell_check_val_on_grid stdcell:power_strap_width] || \
	    [_stdcell_check_val_on_grid stdcell:pwc,width] || \
	    [_stdcell_check_val_on_grid stdcell:nwc,width] || \
	    [_stdcell_check_val_on_grid stdcell:cell_router_pitch] || \
	    [_stdcell_check_val_on_grid stdcell:dpc_router_pitch] } {
	    puts "stdcell generator aborting..."
	    return 0
	}
    }
  
    if {![file readable $filename]} {
	msg "Aborting, Can't read file: $filename\n"
	return 0
    }
  
    msg "Running Layout Generator on $filename\n"
  
    # so the user can back up to here
    undo_delim
  
    setl {x1 y1 x2 y2} [lay_box]
    if {$x1 == ""} {
	lay_box 0 0 0 0
	setl {x1 y1 x2 y2} [lay_box]
    }

    set lay_props ""
    lappend lay_props {reverse_stacked_fets ""}
    lappend lay_props {tracks_above ""}
    lappend lay_props {tracks_below ""}
    lappend lay_props {order_devices_by ""}
    lappend lay_props {preroute_outer ""}
    lappend lay_props {preroute_inner ""}

    db_flyline -delete
  
    # Pass1: open the sim file, extract LayGen icon options.
    # Gather up scale and LayGen options on a per-schematic basis.
    # We need to have this information before we read in the fets.
    set tmp_id [open $filename r]
    set schematic_stack "TOP"
    set cur_schematic "TOP"

    while {[gets $tmp_id line] >= 0} {
      switch [lindex $line 0] {
	"|" { ;     # Why, its a comment!
	    setl {char type junk2} $line
	    switch $char$type {
		"|begin" { ;	# Begin sub-circuit
		    setl {junk1 junk2 id x y} $line
		    push schematic_stack $id
		    set cur_schematic $id
		}
		"|end" { ;	# End of sub-circuit
		    pop schematic_stack
		    set cur_schematic [lindex $schematic_stack 0]
		}
		"|LayGen" { ;    # Layout Generator control icon
		    set Laygen($cur_schematic) [lrange $line 2 end]
		}
	    }
	}
      }
    }
    close $tmp_id

    # Pass2: open the sim file, extract fets and ports.
    set tmp_id [open $filename r]
  
    # This is an amount that must be larger than any x,y coord
    # in sue to bias numbers so they are always positive.
    set bias 100000

    set lay_defaults "-reverse_stacked_fets [_layinfo reverse_stacked_fets] \
	    -order_devices_by position"
  
    set schematic_stack "TOP"
    set cur_schematic "TOP"
    set fnd_comment 0
    set parent_pos ""
    set fet_sortlist ""

    # Get the Layout Generator params for the top level schematic, if any,
    call_use_keyword [use_first Laygen($cur_schematic) lay_defaults] $lay_props
    if { [info exists tracks_above] } {
	set LAYINFO_SCHEMATIC(wiring_tracks_above_center) $tracks_above  ;# Get from schematic.
    }
    if { [info exists tracks_below] } {
	set LAYINFO_SCHEMATIC(wiring_tracks_below_center) $tracks_below  ;# Get from schematic.
    }
    if { [info exists preroute_inner] } {
	set LAYINFO_SCHEMATIC(preroute_inner) $preroute_inner  ;# Get from schematic.
    }
    if { [info exists preroute_outer] } {
	set LAYINFO_SCHEMATIC(preroute_outer) $preroute_outer  ;# Get from schematic.
    }

    while {[gets $tmp_id line] >= 0} {
      switch [lindex $line 0] {
	"|" { ;     # Why, its a comment!
	  setl {junk1 type junk2} $line
	  switch $type {
	    "units:" {
		# special comment contains scale factor.
		# values are given in centimicrons
		# Looks like this: | units: 1.0  tech: scmos  format: MIT
		set scale [expr 0.01 / [lindex $line 2]]
	    }
	    "begin" { ;	# Begin sub-circuit
		setl {junk1 junk2 id x y} $line
		set device_name 0
		if { $order_devices_by == "device_name" } {
		    # Get position from device name.
		    # The name looks like blah.blah.n1
		    # We want the "1"
		    regsub {^.*\.} $id "" tmp
		    if { ![regexp {[0-9]+} $tmp device_name] } {
			error "non-numeric device name $id used with order_devices_by: device_name"
		    }
		    set y 0
		}
		set parent_pos [format "%s%03d,%06d,%06d/" $parent_pos \
		    $device_name [expr $x + $bias] [expr $y + $bias]]
		push schematic_stack $id
		set cur_schematic $id
		call_use_keyword [use_first Laygen($cur_schematic) \
			lay_defaults] $lay_props
	    }
	    "end" { ;	# End of sub-circuit
		# Hack off the last sub-position.
		regsub {[-0-9]+,[-0-9]+,[-0-9]+/} $parent_pos "" parent_pos
		pop schematic_stack
		set cur_schematic [lindex $schematic_stack 0]
		call_use_keyword [use_first Laygen($cur_schematic) \
			lay_defaults] $lay_props
	    }
	    "device" { ;	# X,Y location of a device
		setl {junk1 junk2 id x y} $line
		if { $id == "LayGen" } { continue }
		set fnd_comment 1
		set device_name 0
		if { $order_devices_by == "device_name" } {
		    regsub {^.*\.} $id "" tmp
		    if { ![regexp {[0-9]+} $tmp device_name] } {
			#error "non-numeric device name $id used with order_devices_by: device_name"
		    }
		    set y 0
		}
	    }
	  }
	}
  
  
        "n" -
        "N" -
        "p" -
	"P" {
	    # found a fet (all we care about)
	    if {! $fnd_comment } {
		max_error "stdcell_load_sim: error: Invalid .sim file: no device location comments found"
		puts "exiting..."
		return 0
	    }

	    set fnd_comment 0
	    setl {type g s d l w} $line
	    set l [expr $l * $scale]
	    set w [expr $w * $scale]
	    # Check for gigantically huge fets.  These will cause max to crash.
	    if { $l > 100000 || $w > 10000 } {
		max_error "stdcell_load_sim: error: Invalid .sim file: fets too huge!"
		puts "exiting..."
		return 0
	    }
	    if {! [_stdcell_is_on_grid $w]  || ! [_stdcell_is_on_grid $l] } {
		max_error "stdcell_load_sim: error: FET width or length not divisible by resolution = [res -mask]"
		puts "exiting..."
		return 0
	    }
	    set g [_stdcell_fet_fixnetname $g]
	    set s [_stdcell_fet_fixnetname $s]
	    set d [_stdcell_fet_fixnetname $d]
	    set xpos [expr $bias + $x]
	    set ypos [expr $bias + $y]
	    # Optionally reverse the order of fets that appear stacked
	    # above each other in the schematic.
	    set rev_opt $reverse_stacked_fets
	    if { ([string match "*pfet*" $rev_opt] && $type == "p") ||\
		 ([string match "*nfet*" $rev_opt] && $type == "n") } {
		set ypos [expr $bias - $y]
	    }
	    lappend fet_sortlist [format "%s%03d,%06d,%06d %s" $parent_pos \
		$device_name $xpos $ypos $id]
	    _stdcell_fet_info_init $id $type $l $w $g $s $d
	}
  
        "a" -
        "A" {
	    # attribute line is for ports: name is node name,
	    # type is input/output/bidir/inout
	    setl {junk name iotype} $line
#TODO
# Temporary bug fix for sue bug.  Will be removed soon:
if { $iotype == "io" } { set iotype "inout" }
	    set name [_stdcell_fet_fixnetname $name]
	    set fet_ports($name) [list "type $iotype"]
        }
      }
    }

  
    # close the file
    close $tmp_id

    if {[llength $fet_sortlist] == 0} {
      max_error "stdcell_load_sim: error: No fets in input file"
      return 0
    }

  
    # Sort the fets by location, and save in fet_order.
    # After this, fet_sortlist is unused: always use fet_order.
    set fet_order(p) ""
    set fet_order(n) ""
    foreach eachfet [lsort $fet_sortlist] {
	# First element is sort key, second is instance id.
	setl {junk id} $eachfet
	set type $fet_info($id,type)
	lappend fet_order($type) $id
    }

    # TODO: THIS IS WRONG: keep the laygen options in the fet_sortlist,
    # so we know the ids of the fets beyond which this applies to.
    # Furthermore: cause vertical synchronization at that spot.
    #foreach thing [lsort $laygen_sortlist] {
    #	# First element is sort key, second is options
    #	setl {junk id} $thing
    #	lappend laygen_options($type) $id
    #}


    _stdcell_calculate_stuff "$fet_order(p) $fet_order(n)" 1

    # This may insert additional fets into fet_order.
    set fet_order(p) [_stdcell_fold_fets "p" $fet_order(p)]
    set fet_order(n) [_stdcell_fold_fets "n" $fet_order(n)]

    # Fet widths have may changed due to folding: calculate stuff again.
    _stdcell_calculate_stuff "$fet_order(p) $fet_order(n)"


    # Determine fet_net_uses, number of times each net is used.
    # This is used to determine whether fets can share diffusion or not.
    _stdcell_count_net_uses 0
  
    # Determine orientation of fets, ie, swap s and d to maximize shared diff.
    _stdcell_determine_orientation1 "p" $fet_order(p)
    _stdcell_determine_orientation1 "n" $fet_order(n)
    _stdcell_determine_orientation2 "p" $fet_order(p)
    _stdcell_determine_orientation2 "n" $fet_order(n)

    # Determine tentative fet x,y locations.
    # Route_special may move them in y direction only.
    set pfet_width [_stdcell_locate_fets "p"]
    set nfet_width [_stdcell_locate_fets "n"]

    # Spread out the fets
    if { [_layinfo spread_fets] != "no" } {
	if { $pfet_width < $nfet_width } {
	    # Note: fet_order is an upvar parameter
	    _stdcell_spread_fets "p"
	} else {
	    # Note: fet_order is an upvar parameter
	    _stdcell_spread_fets "n"
	}
    }

    # Determine cell_width and height.
    set cell_width [max $pfet_width $nfet_width]
    # Round to even cell pitch.
    set pitch [_layinfo cell_width_pitch]
    set cell_width [expr floor(($cell_width + $pitch - 0.0001)/$pitch) * $pitch]
    set cell_height [_layinfo cell_height]


    _stdcell_init_fet_route

    # This may flip some fets, in which case it must be redone.
    # We will repeat it as long as it can improve things.

    while {[_stdcell_preroute_m "p"]} {}
    while {[_stdcell_preroute_m "n"]} {}


    # Look for poly preroutes.  If an outer poly preroute is found,
    # this may move fets up/down to make room.
    _stdcell_preroute_poly "p"
    _stdcell_preroute_poly "n"

    # Put in preroutes.  _stdcell_draw_m_preroute may move fets up/down
    # to help with preroutes, which is why the tentative fet location
    # needed to be computed first.
    if { [_layinfo preroute_outer] != "no" ||
	 [_layinfo preroute_inner] != "no" } {
	_stdcell_draw_m_preroute "p"
	_stdcell_draw_m_preroute "n"
    }

    _stdcell_draw_poly_preroute "p"
    _stdcell_draw_poly_preroute "n"

    _stdcell_post_preroute

    # For debug: print out the list of fets.
    if { $STDCELL(debug) } {
        puts "AFTER optimization:"
	_stdcell_fet_dump "all"
    }

    puts "drawing fets..."
    _stdcell_draw_fets "p"
    _stdcell_draw_fets "n"


    if { $LAYINFO(option:router_pads) != "no" } {
	# If there is not enough room for all the pads,
	# _stdcell_draw_pads will make the cell bigger.
	set cell_width [_stdcell_draw_pads $cell_width]
    }

    # Put in the power straps and label em.
    if { [_stdcell_layer power_strap] } {
	set tmp [expr $LAYINFO(stdcell:power_strap_width) / 2]
	lay_box 0 [expr 0 - $tmp] $cell_width $tmp
	:paint [techinfo2 layer m1]
	# divide by 4 so "vdd" label doesnt land right on the centered "bbox" label.
	set x1 [expr $cell_width/4];
	eval lay_box [uusnap -mask $x1 0 $x1 0]
	:label -kind global $STDCELL(gnd) c
	lay_box 0 [expr $cell_height - $tmp] $cell_width [expr $cell_height + $tmp]
	:paint [techinfo2 layer m1]
	eval lay_box [uusnap -mask $x1 $cell_height $x1 $cell_height]
	:label -kind global $STDCELL(vdd) c
    }
 
    # Put in the well ties.
    # The nwc (n well contact, aka well tie) is actually a
    # N+ "active" (aka OD) region put in the nwell and tied to
    # gnd to bias the nwell.
    # Max would auto-generate the N+ region to surround the nwc,
    # but we will draw it in explicitly so the user can see it,
    # and to eliminate problems in auto-generation in max.

    # Set defaults for these: will be over-ridden below if well ties.
    set pplus_max $cell_height
    set nplus_min 0
    set width(nwc) 0

    set contact_pitch $LAYINFO(stdcell:well_v0_pitch)
    foreach thing [list "pwc pplus 0" "nwc nplus $cell_height"] {
      setl {type pnplus centered_at} $thing
      if {[_stdcell_layer $type]} {
	set x1 0
	set x2 $cell_width
	set width($type) [_layinfo ${type},width]
	set y1 [expr $centered_at - $width($type)/2.0]
	set y2 [expr $centered_at + $width($type)/2.0]
	if {[_stdcell_layer $pnplus]} {
	  set overlap [techinfo2 overlap $pnplus $type]
	} else {
	  # Dont generate an error message if they did not ask for this layer.
	  set overlap [techinfo2 overlap $pnplus $type opt]
	}
	if { $width($type) > 0 } {
	    lay_box $x1 $y1 $x2 $y2
	    :paint $type
	    if { [_stdcell_layer $pnplus] } {
		lay_box  [expr $x1 - $overlap] [expr $y1 - $overlap] \
		   [expr $x2 + $overlap] [expr $y2 + $overlap]
		:paint [techinfo2 layer $pnplus]
	    }
	    # Put in the contacts.  If well_contact_pitch == 0, omit them.
	    if { $contact_pitch > 0 && [_stdcell_layer well_contact]} {
		set cw [expr [techinfo2 width v0] / 2.0]
		for {set i [expr $contact_pitch/2.0]} {$i<$cell_width} \
			    {set i [expr $i+$contact_pitch]} {
		    lay_box [expr $i-$cw] [expr $centered_at-$cw] \
			    [expr $i+$cw] [expr $centered_at+$cw]
		    :paint [techinfo2 layer contact]
		}
	    }
	    if {[_stdcell_layer nplus] && [_stdcell_layer nplus]} {
	      set sep_pnplus [techinfo2 sep pplus nplus]
	    } else {
	      # Dont generate a warning.
	      set sep_pnplus [techinfo2 sep pplus nplus opt]
	    }
	    if { $type == "pwc" } {
	      # Save top of pwc for later use as bottom of nplus.
	      set nplus_min [expr $y2 + $overlap + $sep_pnplus]
	    } else {
	      # Save bottom of nplus for later use as top of pplus.
	      set pplus_max [expr $y1 - $overlap - $sep_pnplus]
	    }
	}
      }
    }

if {0} {
    # P-well ties.  If pwc,width == 0, omit it.
    set pwcwidth [_layinfo pwc,width]
    set x1 0;      set y1 [expr 0 - $pwcwidth/2.0]
    set x2 $cell_width; set y2 [expr $pwcwidth/2.0]
    set overlap [techinfo2 overlap pplus pwc]
    if { $pwcwidth > 0 && [_stdcell_layer pwc] } {
	lay_box $x1 $y1 $x2 $y2
	:paint pwc
	if { [_stdcell_layer pplus] } {
	    lay_box  [expr $x1 - $overlap] [expr $y1 - $overlap] \
	       [expr $x2 + $overlap] [expr $y2 + $overlap]
	    :paint [techinfo2 layer pplus]
	}
	# Put in the contacts.  If well_contact_pitch == 0, omit them.
	if { $contact_pitch > 0 && [_stdcell_layer well_contact]} {
	    set cw [expr [techinfo2 width v0] / 2.0]
	    for {set i [expr $contact_pitch/2.0]} {$i<$cell_width} \
			{set i [expr $i+$contact_pitch]} {
		lay_box [expr $i-$cw] [expr 0-$cw] [expr $i+$cw] $cw
		:paint [techinfo2 layer contact]
	    }
	}
	# Save top of pwc for later use as bottom of nplus.
	set nplus_min [expr $y2 + $overlap + [techinfo2 sep pplus nplus]]
    } else {
	set nplus_min 0
	set pwcwidth 0		;# layers:nwc was 0, so set nwcwidth to 0.
    }
 
    # N-well ties.  If nwc,width == 0, omit it.
    set nwcwidth [_layinfo nwc,width]
    set x1 0;      set y1 [expr $cell_height - $nwcwidth/2.0]
    set x2 $cell_width; set y2 [expr $cell_height + $nwcwidth/2.0]
    set overlap [techinfo2 overlap nplus nwc]
    if { $nwcwidth > 0  && [_stdcell_layer nwc] } {

	lay_box $x1 $y1 $x2 $y2
	:paint [techinfo2 layer nwc]
	if { [_stdcell_layer nplus] } {
	    lay_box  [expr $x1 - $overlap] [expr $y1 - $overlap] \
	       [expr $x2 + $overlap] [expr $y2 + $overlap]
	    :paint [techinfo2 layer nplus]
	}

	# Put in the contacts.  If well_contact_pitch == 0, omit them.
	if { $contact_pitch > 0 && [_stdcell_layer well_contact]} {
	    set cw [expr [techinfo2 width v0] / 2.0]
	    for {set i [expr $contact_pitch/2.0]} {$i<$cell_width} \
			{set i [expr $i+$contact_pitch]} {
		lay_box [expr $i-$cw] [expr $cell_height-$cw] \
			[expr $i+$cw] [expr $cell_height+$cw]
		:paint [techinfo2 layer contact]
	    }
	}
	# Save bottom of nplus for later use as top of pplus.
	set pplus_max [expr $y1 - $overlap - [techinfo2 sep pplus nplus]]
    } else {
	set pplus_max $cell_height
	set nwcwidth 0		;# layers:nwc was 0, so set nwcwidth to 0.
    }
}
 
    # Put in the nwell and pplus/nplus regions.
    # Max can auto-generate these, but the current DRC rules sometimes
    # create violations on nplus/pplus when cells are placed side by side,
    # because the nplus/pplus is drawn just around the transistors,
    # and when the cells are placed next to each other,
    # the nplus or pplus region ends up with a notch.
    # So just cover the entire area to be safe.
    # The nplus/pplus probably overlap the sides of the cell a little,
    # as well, but the only place it matters is at the ends of the
    # rows of cells, and max can fix it there without making DRC violations.
    if { [_stdcell_layer nwell] } {
	lay_box [expr 0 - $STDCELL(nw_side_overlap)] \
	    [_layinfo N/P_boundary] \
	    [expr $cell_width + $STDCELL(nw_side_overlap)] \
	    [expr $cell_height + $width(nwc)/2.0 + \
	      [techinfo2 overlap nwell nwc]]
	:paint [techinfo2 layer nwell]
    }
    if { [_stdcell_layer pplus] } {
	set tmp $STDCELL(pplus_side_overlap)
	lay_box [expr 0 - $tmp] [_layinfo N/P_boundary] \
		[expr $cell_width + $tmp] $pplus_max
	:paint [techinfo2 layer pplus]
    }
    if { [_stdcell_layer nplus] } {
	set tmp $STDCELL(nplus_side_overlap)
	lay_box [expr 0 - $tmp] $nplus_min [expr $cell_width + $tmp] \
	   [expr [_layinfo N/P_boundary] - [techinfo2 sep pplus nplus]] 
	:paint [techinfo2 layer nplus]
    }

    #_stdcell_old_place_flylines
    _stdcell_flylines

# NOTE: Lee moved this to after labels so labels wouldn't drop onto
# prb layer and choke.
    # Put in a box label to mark the cell perimeter.
    lay_box 0 0 $cell_width $cell_height
    if { [_stdcell_layer prb_layer] } {
	# This layer name should be programmable, but too late
	# for this release.
	set prb [techinfo layer prb "" opt]
	if { $prb != "" } {
	  :paint prb
	} else {
	    msg "warning: no prb layer defined in this technology for cell bounding box\n"
	}
    }
    if { [_stdcell_layer bbox_label] } {
	:label "bbox" "n" "space"
    }

    set text [use_first LAYINFO(stdcell:comment)]
    if { $text != "" } {
	set ypos -0.5
	if { [_stdcell_layer power_strap] } {
	    set ypos [expr $ypos - [_layinfo power_strap_width] / 2]
	}
	db_label -pos e -kind comment space $text 0 $ypos
    }
 

    # Save this for the router.
    set STDCELL(cell_width) $cell_width
    set STDCELL(edit_cell) [lay_editcell]

    # Just for looks: dont leave a selection laying around.
    sel_clear
    layt_box user 0 0 $cell_width $cell_height
    view_cell
    msg "Layout Generator done\n"
    return 1
}


proc _stdcell_unique_label {} -desc {
  returns a unique label name
} {

  global LABEL_COUNT

  if {![info exists LABEL_COUNT]} {
    set LABEL_COUNT 1
  }

  set name label$LABEL_COUNT
  incr LABEL_COUNT
  sel_labels -text $name
  while {[sel_what labels] != ""} {
    set name label$LABEL_COUNT
    incr LABEL_COUNT
    sel_labels -text $name
  }

  return $name
}

# Save LAYINFO to a file.
proc _stdcell_save_layinfo {{save 1}} {
    global LAYINFO
    if {$save} {
	#set filename [FSBoxNew -message "Select file for parameter save:" \
	    -file "max.rc" -mode "w"]
	set filename [fs_box -message "Select file for parameter save:" \
	    -filename "max.rc"]

	if { $filename == "" } { return }
	set old_lines ""
	if {[file exists $filename]} {
	    # Slurp in the old file, deleting LAYINFO lines
	    set tmp_id [open $filename r]
	    while {[gets $tmp_id line] >= 0} {
		if {[string first "set LAYINFO" $line] == 0} { continue }
		lappend old_lines $line
	    }
	    close $tmp_id
	}
	# Reopen file, write out previous contents, append LAYINFO.
	set tmp_id [open $filename w]
	foreach line $old_lines {
	    puts $tmp_id $line
	}
	foreach name [array names LAYINFO] {
	    puts $tmp_id "set LAYINFO($name) {$LAYINFO($name)}"
	}
	close $tmp_id
	puts "Done.  Note: to restore parameters, type: source $filename"
    }
}

proc stdcell_setup {args} -desc {
  Layout Generator Setup; edits the LAYINFO array.
} -doc {
  USAGE:
    stdcell_setup [-options] [type]
  
  If -options : show only options, not file names.
  If <type> specified, it is the prefix of LAYINFO entries to edit.

  Return 0 if user canceled, 1 if ok.
} {
    global LAYINFO LAYINFO_HELP STDCELL

    set type [call_keyword $args {options}]

    # Fills in LAYINFO entries that must be computed.
    _stdcell_calculate_stuff "" 

    set prop_list ""
    if { $type != "" } {
      # Only edit LAYINFO options that match a specified pattern.
      # If type is "process", edit LAYINFO options that contain no colon.
      switch $type {
	  "process" { set pattern {^[^:]*$} }
	  default { set pattern "^$type:" }
      }
      set nitems 1
      foreach attr [lsort [array names LAYINFO]] {
	  if { ![regexp $pattern $attr] } {
	  continue }
	  set item "$attr LAYINFO($attr)"
	  if {[info exists LAYINFO_HELP($attr)]} {
	      set item "$item $LAYINFO_HELP($attr)"
	  } elseif { [string first "layers:" $attr ] == 0 ||
		     ([string first "option:" $attr ] == 0 &&
		     ($LAYINFO($attr) == 0 || $LAYINFO($attr) == 1)) } {
	      append item " -binary"
	  }
	  if {[incr nitems] >= 25 && [string first -hide $item] < 0} {
	      set nitems 1
	      append item " -break"
	  }
	  lappend prop_list $item
      }
    }

    if {$type == ""} {
      # Create custom top level menu.
      _stdcell_init STDCELL(input_filename) ""
      _stdcell_init STDCELL(output_filename) ""
      set STDCELL(original_output_filename) $STDCELL(output_filename)
      # If the user picks a filename with the "Find..." button
      # on the input filename, and the output filename is unchanged,
      # fill it in for them.
      if {!  $options } {
	lappend prop_list [list "Input File Name:" STDCELL(input_filename) \
	  -filename {-pattern *.sim} -width 30 \
	  -command {
	  if {$STDCELL(output_filename)==$STDCELL(original_output_filename)} {
	    set STDCELL(output_filename) \
	      [file rootname [file tail $STDCELL(input_filename)]]
	    set STDCELL(original_output_filename) $STDCELL(output_filename)
	    }}]
	lappend prop_list [list "Output File Name:" STDCELL(output_filename) \
	  -filename {-pattern *.max} -width 30] 
      }
      lappend prop_list [list "Generate stdcell layers:" \
	      STDCELL(stdcell_layers) -binary]
      lappend prop_list [list "Edit Per-Cell Options..."  {} \
	      -button "stdcell_setup option"]
      lappend prop_list [list "Edit Stdcell Options..." {} \
	      -button "stdcell_setup stdcell"]
      lappend prop_list [list "Edit Layers to Generate..." {} \
	      -button "stdcell_setup layers"]

      # 8/26 These two options are not working due to tech file changes.
      #lappend prop_list [list "Edit Process Params..." {} \
	      -button "stdcell_setup process" ]
      #lappend prop_list [list "Save All Params to File..." {} \
	      -button "_stdcell_save_layinfo 1"]

      global MAX_DEVELOPER
      if { $MAX_DEVELOPER } {
	  lappend prop_list [list "MAX DEVELOPER OPTIONS:" "" -label]
	  lappend prop_list [list "Reread .maxrc ..." {} \
	      -button {source .maxrc; puts "done\n"}]
	  lappend prop_list [list "Debug" STDCELL(debug) -binary]
      }
    }

    # create the menu
    set title "Layout Generator"
    switch $type {
      "stdcell" { set message "Stdcell Options (for all cells):" }
      "option" { set message "Per-Cell Options:" }
      "layers" { set message "Layers to Generator:" }
      default { set message "Layout Generator:" }
    }
    while {1} {
      set stat [prop_menu2 -message $message -title $title $prop_list]
      if {$stat == 0} {
	# empty list means the user hit cancel
	return 0
      }
      break
    }

    return 1
}

proc stdcell_reload {} -desc {
  Regenerate the current cell with current options.
} {
    global STDCELL
    source stdcell.tcl
    set cell [lay_rootcell]
    if { $cell == "UNNAMED" } { return }
    setl {flags pathname} [cell_info $cell]
    set filename [file tail $pathname]
    regsub {\.max$} $filename "" filename

    # The .sim files may be in a different directory from
    # the .max files.  If we have already been run, assume the
    # directory for .sim files is the same as the last run,
    # otherwise try the directory containing the max file.
    if { [info exists STDCELL(input_filename)] } {
	set oldpath [file dirname $STDCELL(input_filename)]
	set newpath $oldpath/$filename
    } else {
	set oldpath [file dirname $pathname]
	set newpath $oldpath/$filename
    }

    return [stdcell_load_sim ${newpath} 0]
}

# If verbose is 1, you get to edit everything in LAYINFO.
proc stdcell_load_sim { {filename ""} {verbose 1} } {
    global STDCELL

    #if { ! [_stdcell_check_license -check] } { return }
  
    # Prompt user for input filename.
    if {$filename == ""} {
	# Default to current cell name.
	set filename [lay_editcell]
	if { [string match UNNAMED $filename] } {
	    set filename ""
	} else {
	    set filename ${filename}.sim
	}
	set filename [fs_box -message "Select sim file to load" \
	  -pattern *.sim -filename $filename]
	if {$filename == ""} {
	  # user hit cancel key
	  return 0
	}
    }

    if {[file extension $filename] == ""} {
	set filename "$filename.sim"
    }

    # Create STDCELL array.
    # Set defaults if not already initialized.
    set STDCELL(input_filename) $filename
    # Generate output filename from input filename.
    # Default is now the same name without .sim suffix.
    set STDCELL(output_filename) [file rootname [file tail $filename]].max
    # TODO: The Router is not working on gcells because they do not
    # have variable sized contacts, so routing above/below cells
    # does not work.  So default the router off for now.
    set STDCELL(debug) 0


    if { $verbose != "0" } {
      if {! [stdcell_setup] } { return }
    }

    # This sucks: can NOT leave .max extension on filename.
    regsub {\.max$} $STDCELL(output_filename) "" STDCELL(output_filename)
    _stdcell_goto_cell $STDCELL(output_filename)
    update

    cursor_busy 1
    stdcell_load_direct $STDCELL(input_filename)
    cursor_busy 0
}

# Backward compatible name.
proc load_sim {} {
    stdcell_load_sim
}



# This probably does not work any more.  (pat)
#
proc load_spice {{filename ""}} -desc {
  reads in a hierarchical spice file and creates fly lines for the circuit
} {
  #if { ! [_stdcell_check_license -check] } { return }

  if {$filename == ""} {
    set filename [fs_box -message "Select spice file to load" -pattern *.sp]
    if {$filename == ""} {
      # user hit cancel key
      return
    }
  }

  if {[file extension $filename] == ""} {
    set filename "$filename.sp"
  }

  if {![file readable $filename]} {
    msg "Aborting, Can't read file $filename\n"
    return
  }

  # so the user can back up to here
  undo_delim

  msg "Parsing file $filename ...\n"

  # open the spice file
  set tmp_id [open $filename r]

  set count 0
  set line_no 0
  set this_line ""
  set netlist ""

  while {[gets $tmp_id line] >= 0} {
    incr line_no
    switch [string tolower [string index $line 0]] {
      * {
	# comment, ignore
      }

      + {
	# continuation character
	set this_line "$this_line [string range $line 1 end]"
      }

      . - x {
	# only care about lines beginning with a "." or an "x"
	if {$this_line != ""} {
	  lappend netlist $this_line
	}
	set this_line $line
      }

      "" {
	# whitespace, ignore
      }

      default {
	# what's this
	msg "  Skipping unknown spice line (\#$line_no): \"$line\"\n"
      }
    }
  }

  # close the file
  close $tmp_id
  
  # now go through the netlist and parse it
  foreach line $netlist {
    if {[string index $line 0] == "."} {
      switch [string tolower [lindex $line 0]] {
	.subckt {
	  # get the subcircuit port names
	  set instance_name [lindex $line 1]
	  set instance_ports($instance_name) [lrange $line 2 end]
	}

	.ends {
	  # finished with this instance
	  set instance_name ""
	}

	default {
	  # ignore, must be some option or something
	}
      }
    } else {
      # this must be an instance declaration
      set name [string range [lindex $line 0] 1 end]
      set len [expr [llength $line] - 1]
      set instances($name) [lindex $line $len]
      set ports $instance_ports($instances($name))

      set index 0
      foreach net [lrange $line 1 [expr $len - 1]] {
	# doesn't do hierarchy yet
	lappend nets($net) "$name [lindex $ports $index]"
	incr index
      }
    }
  }

  # now put in the flylines
  msg "Adding flylines ...\n"

  set flylines 0
  set net_cnt 0

  foreach net [array names nets] {
    incr net_cnt

    # every port on the same net gets attached
    if {[llength $nets($net)] == 1} {
      msg "  Warning, only one connection on net $net\n"
      continue
    }

    set last_label ""
    foreach port $nets($net) {
      # find where to put the label

      setl {cell port_name} $port
      # select the instance
      if {[msg_catch "sel_cell $cell" code msg] == 1} {
	# couldn't select cell
	msg "  Skipping net $port_name, couldn't find cell $cell.\n"
	continue
      }

      # goto the cell
      edit_push in_place

      sel_labels -text $port_name
      setl {layer x y} [sel_what labels]

      # go back to the top most cell
      edit_pop

      # put in a hidden label (needs a square of paint under it
      set label [_stdcell_unique_label]
      lay_box $x $y [expr $x + [res -mask]] [expr $y + [res -mask]]
      :paint $layer
      :label -kind hidden $label c $layer

      if {$last_label != ""} {
	# put in the flyline
	db_flyline $last_label $label
	incr flylines
      }
      set last_label $label	
    }
  }

  sel_clear
  eval lay_box [lay_bbox]
  view_cell
  
  msg "Added $flylines flylines to $net_cnt nets.\n"
}

proc laygen_init {} -desc {
    Add Layout Generator to Tool menu.
} {
    global MAX_DEVELOPER
    menu_tool_cmd "Layout Generator" stdcell_load_sim "Load and run layout generator"
    if { $MAX_DEVELOPER } {
	menu_tool_cmd "Layout Rerun" stdcell_reload "Rerun layout generator on current cell"
    }
    if { [STDCELL_ROUTER] } {
	menu_tool_cmd "Layout Router" stdcell_route "Run router on generated layout"
    }
    msg "Layout Generator (Version 1.0)\n"
}
