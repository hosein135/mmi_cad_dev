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

set RCSVERSION(colors.tcl) { $Revision: 1.30 $ }

# NOTE: eventually set from max C code.
if {![info exists GR_COLOR_MAPPED]} {
  set GR_COLOR_MAPPED 1
}

# procs to setup layout widget colors/styles
#
# palette/colors code broken up as follows:
#   pal.tcl             - procs to build and manipulate palette widget.
#   pal_file.tcl        - procs to read .palette file. 
#   colors.tcl          - procs to setup layout widget colors/styles 
#   color_editor.tcl    - builds widget for editing layer colors/styles

proc _pal_cmap {entry color} -desc {
  set colormap entry
} {
    global COLORMAP

  # set colormap entry   
  eval lay_cmap $entry $color

  # also save in tcl array since lay_cmap is write-only    
  set COLORMAP($entry) $color
}


proc _pal_new_color {color rgb} -desc {
  make a new color with the given rgb.
} {
    global COLORMAP GR_COLOR_MAPPED

  # add the color
  if { $GR_COLOR_MAPPED } {
    # color map mode

    if {$color > 126} {
      puts "PALETTE WARNING: too many colors"
    } else {
      incr color
    }

    eval lay_cmap $color $rgb

  } else {
    # truecolor mode
    set color [eval gr_rgb_to_pixel $rgb]
  }

  # save this since we can't go the other way
  set COLORMAP($color) $rgb

  return $color
}


proc _pal_set_special_color {name color default} -desc {
    setup special (non-paint) color 
} -doc {
    usage:  _pal_set_special_color name color default
    color is index in color map (ignored in direct mode)
    default is {r g b} in 0-255 range.

    returns pixel value for color.
} {
    global PAL_DATA GR_COLOR_MAPPED COLORMAP

    if {![info exists PAL_DATA($name)]} {
	set PAL_DATA($name) $default
    }

    if { $GR_COLOR_MAPPED } {
	_pal_cmap $color $PAL_DATA($name)
    } else {
        set color [eval gr_rgb_to_pixel $PAL_DATA($name)]
    }
    
    set COLORMAP($color) $PAL_DATA($name)

    set PAL_DATA(color,$name) $color

    return $color
}


proc _pal_set_special_stipple {name number default} -desc {
    setup special (non-paint) stipple
} {
    global PAL_DATA

    if {![info exists PAL_DATA(stipple,$number)]} {
	set PAL_DATA(stipple,$number) $default
    }

    eval lay_stipple $number $PAL_DATA(stipple,$number)
#puts "$name -----> $number ---> $PAL_DATA(stipple,$number)"
}


proc _pal_style {args} -desc {
    set display style (wrapper for lay_style)
} {
    set pos_args [call_with_keyword $args {
	{mask 0177}
	{outline 0}
	{fill solid}
	{stipple 0}
	{dim ""}
    }]

    set style [lindex $pos_args 0]
    set color [lindex $pos_args 1]

   if {$dim != ""} {
       lay_style -dim $style $mask $color $outline $fill $stipple
   } else {
#       puts "DEBUG lay_style $style $mask $color $outline $fill $stipple"
       lay_style $style $mask $color $outline $fill $stipple
   }
}	


proc _colors_need_stipple_only {} -desc {
  check if we need to run stipple_only mode.
} -doc {
    if too many stippled layers, we don't have enough colors in colormap
    to support transparent layers.
} {
    global PAL_DATA COLORMAP

    set compose 0
    set solids 0
    set stipples 0

    # walk through paint layers counting types
    foreach list $PAL_DATA(colors) {
	setl {layer rgb fill} $list

	if {[info exist PAL_DATA(compose,$layer)]} {
	    incr compose
	}

	switch [lindex $fill 0] {
	    solid {
		incr solids
	    }
	    
	    stipple {
		incr stipples
	    }
	}
    }
	    
#    puts "_colors_need_stipple_only DEBUG compose=$compose solids=$solids stipples=$stipples"

    # 32 colors for solids, 10 for special and 1 for drc 
    # and 128 colors total.  128 - 32 - 10 - 1 = 85
    if { [expr $stipples + [max 0 [expr $solids - 5]]] > 84} {
	puts "Palette:  Using stipple_only mode.  (Too many layers to support transparency.)"
	
	return 1
    }

    return 0
}


proc _pal_colors {} -desc {
  setup all of the colormap entrys, stipples and styles
} {
  global PAL PAL_DATA COLORMAP GR_COLOR_MAPPED
  
  ### CLEAN UP GROUPS
  set groups $PAL_DATA(groups)
  set PAL_DATA(groups) ""
  foreach group $groups {
    if {[info exists PAL_DATA($group.layers)]} {
      lappend PAL_DATA(groups) $group
    }
  }

  # stipple only mode makes more efficient use of colormap,
  # and hence allows more layers.
  
  # if too many stippled layers, force stipple_only mode.
  set stipple_only [_colors_need_stipple_only]
#  set stipple_only 0

  if { !$GR_COLOR_MAPPED } {
    if {![info exists PAL(stipple_only)]} {
      puts "Direct graphics, setting stipple_only mode."
    }
    set stipple_only 1
  }

#qqq
#  puts "*** FORCING STIPPLE_ONLY MODE ***   GR_COLOR_MAPPED = $GR_COLOR_MAPPED"
#  set stipple_only 1

  # if stipple_only make globally known, and convert all layers to stipples
  if { $stipple_only} {
      set PAL(stipple_only) 1
      # no transparent styles, so can do redisplay in one pass
      lay_style_groups -one
  }

  # maximum number of transparent layers supported    
  set maxTransparent 5

  # INITIALIZE COUNTERS
  # number of solid layers used
  set solids 0

  # can really only have 10 solid layers (5 transparent, 5 faked)
  set PAL_DATA(solids) [min $PAL_DATA(solids) 10]

  # last non-solid color used.
  if { $stipple_only } {
      set PAL_DATA(min_nontransparent_color) 0
  } else {
      set PAL_DATA(min_nontransparent_color) 31
  }
  set color $PAL_DATA(min_nontransparent_color)

  # last style used
  set style 0

  # this is where we start the non-solid styles
  if { $stipple_only } {
    set ns_style \
	[expr [max [expr 2 * $PAL_DATA(solids) - 4] 0] + [llength $PAL_DATA(compose)] + 8]
  } else {
    set ns_style \
	[expr [max [expr 2 * $PAL_DATA(solids) - 4] 0] + [llength $PAL_DATA(compose)] + 3]
  }

  # last style assigned from high end
  set high_style 128

  # NOTE: must be stipple pattern 2 since this is the
  # default when changing from a solid to a stippled layer
  #DIM STIPPLE (used to dim transparent paint layers)
  # (defined early because used by grid to work around bug)
  set stipple_dim 2
  set PAL_DATA(stipple,2) "\
      10101010 \
      01010101 \
      10101010 \
      01010101 \
      10101010 \
      01010101 \
      10101010 \
      01010101 "
  eval lay_stipple 2 $PAL_DATA(stipple,2)

  # last stipple used
  set stipple 2

  # ANNOTATION
  incr color
  set c [_pal_set_special_color annotation $color "185 124 84"]
  _pal_style annotation $c -mask 0177

  # BACKGROUND
  # (background MUST be color 0)
  set c [_pal_set_special_color background 0 "200 200 200"]
  _pal_style background $c -mask 0177

  if { $GR_COLOR_MAPPED } {
    set background 0
  } else {
    set background [lindex [lay_style background] 1]
  }

  # BOX 
  incr color
  set c [_pal_set_special_color box $color "162 10 10"]
  _pal_style box $c -mask 0177

  # BBOX (unexpanded instance) 
  incr color
  set c [_pal_set_special_color bbox $color "0 0 0"]
  _pal_style unexpanded_instance $c -fill outline -outline 0377 -mask 0177
  # also use for outlining tiles during ':*watch' (debugging) 
  _pal_style watched_tile $c -fill outline -outline 0377 -mask 0177
  # blend with background to get dim verison
  set color [_blend_color -attenuation 200 $c $background [incr color]]
  _pal_style unexpanded_instance_dim $color -fill outline -outline 0377 -mask 0177

  # DRC ERRORS (internal 'paint' layer)
  incr color
  set c [_pal_set_special_color drc $color "255 255 255"]

  incr stipple
  set default "\
      00000011 \
      00000011 \
      00110000 \
      00110000 \
      00001100 \
      00001100 \
      11000000 \
      11000000"
  _pal_set_special_stipple drc $stipple $default

  # use highest numbered style, so errors are on top.
  incr high_style -1
  _pal_style $high_style $c -fill stipple -stipple $stipple
  _pal_style $high_style $c -fill stipple -stipple $stipple -dim 1

  #assign style to error layers
  foreach error "error_p error_s error_ps" {
    lay_layer_styles $error $high_style
  }

  # reserve a temporary style for use by color editor
  incr high_style -1
  set PAL(temp_style) $high_style

  # GRID 
  incr color
  set c [_pal_set_special_color grid $color "200 0 0"]
  # changing the line style seems to be broken so use stipple instead.
  _pal_style grid_fine $c -fill stipple -stipple $stipple_dim -mask 0177
  _pal_style grid_coarse $c -outline 0377 -mask 0177
  _pal_style grid_origin $c -mask 0177 

  # FEEDBACK pwd
  incr color
  set c [_pal_set_special_color feedback $color "200 255 200"]

  #feedback_solid
  _pal_style feedback_solid $c -mask 0177

  #feedback_medium
  incr stipple
  set default "\
	00001000 \
	00100000 \
	00000010 \
	10000000 \
	00000001 \
	01000000 \
	00000100 \
	00010000"
  _pal_style feedback_medium $c -fill stipple -stipple $stipple -mask 0177
  _pal_set_special_stipple feedback_medium $stipple $default

  #feedback_pale
  incr stipple
  set default "\
      10000001 \
      11000000 \
      01100000 \
      00110000 \
      00011000 \
      00001100 \
      00000110 \
      00000011"
  _pal_style feedback_pale $c -fill stipple -stipple $stipple -mask 0177
  _pal_set_special_stipple feedback_pale $stipple $default

  #feedback_outline
  _pal_style feedback_outline $c -fill outline -outline 0377 -mask 0177

  #feedback_dotted
  # NOTE: dotted outlines broken as of 5/9/00
  _pal_style feedback_dotted $c -fill outline -outline 0314 -mask 0177

  # FLYLINE
  incr color
  set c [_pal_set_special_color flyline $color "246 246 7"]
  _pal_style flyline $c -mask 0177
  # blend with background to get dim verison
  set color [_blend_color -attenuation 200 $c $background [expr $color + 1]]
  _pal_style flyline_dim $color -mask 0177

  # LABEL
  incr color
  set c [_pal_set_special_color label $color "246 246 7"]
  _pal_style label $c -fill outline -outline 0377 -mask 0177
  # blend with background to get dim verison
  set color [_blend_color -attenuation 200 $c $background [expr $color + 1]]
  _pal_style label_dim $color -fill outline -outline 0377 -mask 0177

  # SELECTION
  incr color
  set c [_pal_set_special_color selection $color "255 255 255"]

  incr stipple
  set default "\
	00001000 \
	00100000 \
	00000010 \
	10000000 \
	00000001 \
	01000000 \
	00000100 \
	00010000"
  _pal_set_special_stipple selection $stipple $default

 _pal_style selection_solid $c -mask 0177 
 _pal_style selection_stippled $c -fill stipple -stipple $stipple -mask 0177
 _pal_style selection_outline $c -fill outline -outline 0377 -mask 0177

#  puts "DEBUG last special color = $color"

  # STANDARD (PAINT) LAYERS

  #PSEUDO TRANSPARENT STIPPLES (non-transparent solid layers)
  lay_stipple [incr stipple] \
      01010101 \
      10101010 \
      01010101 \
      10101010 \
      01010101 \
      10101010 \
      01010101 \
      10101010
  set stipple_pseudo(base) $stipple
  # remember that this stipple is really a pseudo-transparent one
  set PAL_DATA(pseudo,$stipple) 1

  lay_stipple [incr stipple] \
      01010101 \
      00000000 \
      01010101 \
      00000000 \
      01010101 \
      00000000 \
      01010101 \
      00000000
  set stipple_pseudo(1) $stipple

  lay_stipple [incr stipple] \
      00000000 \
      10101010 \
      00000000 \
      10101010 \
      00000000 \
      10101010 \
      00000000 \
      10101010
  set stipple_pseudo(2) $stipple

  lay_stipple [incr stipple] \
      00000000 \
      01010101 \
      00000000 \
      01010101 \
      00000000 \
      01010101 \
      00000000 \
      01010101
  set stipple_pseudo(3) $stipple

  lay_stipple [incr stipple] \
      10101010 \
      00000000 \
      10101010 \
      00000000 \
      10101010 \
      00000000 \
      10101010 \
      00000000
  set stipple_pseudo(4) $stipple

  set stipple_pseudo(5) 0

  if { $stipple_only } {
    # these will replace the transparent layers

    lay_stipple [incr stipple] \
	10101010 \
	01010101 \
	10101010 \
	01010101 \
	10101010 \
	01010101 \
	10101010 \
	01010101
    set stipple_pseudo(s,base) $stipple
    # remember that this stipple is really a pseudo-transparent one
    set PAL_DATA(pseudo,$stipple) 1

    lay_stipple [incr stipple] \
	00000000 \
	01010101 \
	00000000 \
	01010101 \
	00000000 \
	01010101 \
	00000000 \
	01010101
    set stipple_pseudo(s,1) $stipple

    lay_stipple [incr stipple] \
	10101010 \
	00000000 \
	10101010 \
	00000000 \
	10101010 \
	00000000 \
	10101010 \
	00000000
    set stipple_pseudo(s,2) $stipple

    lay_stipple [incr stipple] \
	01010101 \
	00000000 \
	01010101 \
	00000000 \
	01010101 \
	00000000 \
	01010101 \
	00000000
    set stipple_pseudo(s,3) $stipple

    lay_stipple [incr stipple] \
	00000000 \
	10101010 \
	00000000 \
	10101010 \
	00000000 \
	10101010 \
	00000000 \
	10101010
    set stipple_pseudo(s,4) $stipple

    set stipple_pseudo(s,5) 0
  }

  # compose style placed first
  set compose_style $style
  incr style [llength $PAL_DATA(compose)]

  # process paint layers in reverse order
  # NOTE: must use special version of lreverse
  foreach list [lreverse_list $PAL_DATA(colors)] {
    setl {layer rgb fill} $list

    if {[info exist PAL_DATA(compose,$layer)]} {
      # gets processed later
      continue
    }

    if {[lindex $fill 0] == "solid" && $solids >= 10} {
      # TODO: change to stipple and devise a stipple pattern
      puts "Only 10 solid layers allowed.  Change line \"$list\""
      continue
    }

    switch [lindex $fill 0] {
      solid {
        # solid layers have no user defined stipple, they blend
	# together when layered as if made of cellophane.
        #
        # the first 5 (i.e. bottom 5) solid layers are implemented
        # as 'transparent' layers by assigning each a plane in the
        # colormap, and setting up the colormap to display combinations
        # correctly.
        #
        # up to 5 more (higher solid layers called 'pseudo transparent')
        # are implemented with fine stipple patterns.
	# All pseudo transparent layers are first drawn as a common 
	# 2x2 stipple that shows through the transparent layers below
	  
	incr solids

	if {$solids > $maxTransparent } {
	  # use stipples to fake transparency
	  set PAL_DATA($layer,kind) pseudo_transparent  
	    
	  # index of this pseudo layer  
          set pseudo [expr $solids - $maxTransparent]	    

	  incr style
	  lay_layer_styles $layer $style

	  # compute the other style number (pseudo solids drawn twice)
	  set other_style [expr $style + 2*($PAL_DATA(solids) - $solids)]

#puts "p solid $layer $style --> $other_style"

	  # add the color
	  set color [_pal_new_color $color $rgb]

	  set other_stipple $stipple_pseudo($pseudo)

	  # make the styles
	  lay_style $style 0177 $color 0 stipple $stipple_pseudo(base)
	  if {$other_stipple == 0} {
	    # top pseudo layer (no other stipple)
	    lay_style -dim $style 0177 $color 0 stipple $stipple_pseudo(base)
	  } else {
	    lay_style -dim $style 0177 $color 0 stipple $other_stipple
	  }

	  if {$other_style != $style} {
	    # not top layer, so add second (other) style.
	    lay_layer_styles -add $layer $other_style
	    lay_style $other_style 0177 $color 0 stipple $other_stipple
	    lay_style -dim $other_style 0177 $color 0 stipple $other_stipple
	  }

	} else {

	  if { $stipple_only } {
	    # use some more pseudo-transparent layers to fudge this
	    set PAL_DATA($layer,kind) pseudo_transparent  
	    
	    # index of this pseudo layer  
	    set pseudo $solids

	    incr style
	    lay_layer_styles $layer $style

	    # compute the other style number (pseudo solids drawn twice)
	    set other_style [expr $style + 2*([min $PAL_DATA(solids) 5] - $solids)]

#puts "solid $layer $style --> $other_style"

	    # add the color
	    set color [_pal_new_color $color $rgb]

	    set other_stipple $stipple_pseudo(s,$pseudo)

	    # make the styles
	    lay_style $style 0177 $color 0 stipple $stipple_pseudo(s,base)
	    if {$other_stipple == 0} {
	      # top pseudo layer (no other stipple)
	      lay_style -dim $style 0177 $color 0 stipple $stipple_pseudo(s,base)
	    } else {
	      lay_style -dim $style 0177 $color 0 stipple $other_stipple
	    }

	    if {$other_style != $style} {
	      # not top layer, so add second (other) style.
	      lay_layer_styles -add $layer $other_style
	      lay_style $other_style 0177 $color 0 stipple $other_stipple
	      lay_style -dim $other_style 0177 $color 0 stipple $other_stipple
	    }

	    if {$solids > 4} {
	      # add for double styles
	      incr style 4

	      # make room for compose styles
#	      set compose_style $style
#	      incr style [llength $PAL_DATA(compose)]
	    }

	  } else {
	    # transparent
	    set PAL_DATA($layer,kind) transparent  

	    # assign the next style to this layer
	    incr style
	    lay_layer_styles $layer $style

	    # set up this style and dim style
	    set num [expr int(pow(2,($solids - 1)))]
	    lay_style $style $num $num 0 solid 0
	    lay_style -dim $style $num $num 0 stipple $stipple_dim

	    set COLORMAP($num) $rgb
	    eval lay_cmap $num $COLORMAP($num)

	    if {$solids > 4} {
	      # make room for compose styles
#	      set compose_style $style
#	      incr style [llength $PAL_DATA(compose)]
	    }
	  }
	}
      }

      stipple {
	# first make the stipple
	incr stipple
	if {[lindex $fill 1] == "outline"} {
          set PAL_DATA($layer,kind) outline
	  set outline 1
	  set stipple_pattern [lrange $fill 2 end]
	} else {
          set PAL_DATA($layer,kind) stippled
	  set outline 0
	  set stipple_pattern [lrange $fill 1 end]
	}
	if {$stipple_pattern == ""} {
	  # make_tech screwed up, make up a stipple pattern
	  set stipple_pattern "\
	      10001000 \
	      01000100 \
	      00100010 \
	      00010000 \
	      10001000 \
	      01000100 \
	      00100010 \
	      00010000 \
              "
	}

	set PAL_DATA(stipple,$stipple) $stipple_pattern
	eval lay_stipple $stipple $stipple_pattern

	# add the color
	set color [_pal_new_color $color $rgb]

	# now add the layer
	incr ns_style
#puts "$layer -----> $ns_style"
	lay_layer_styles $layer $ns_style
	lay_style $ns_style 0177 $color 0 stipple $stipple

	# No dim stipples for now (could allow second stipple to be dim one)
	lay_style -dim $ns_style 0177 $color 0 stipple $stipple

	if {$outline} {
	  # outline
	  incr ns_style
	  lay_layer_styles -add $layer $ns_style
	  lay_style $ns_style 0177 $color 0377 outline 0
	  lay_style -dim $ns_style 0177 $color 0377 outline 0
	}
      }

      default {
	puts "illegal fill \"$fill\" in $list.  Must be solid or stipple/pattern"
      }
    }
  }

#  if {![info exists compose_style]} {
#    # not even 5 solid styles
#    if { $stipple_only } {
#      set compose_style [expr $style + [max 0 [expr $solids - 1]]]
#
#    } else {
#      set compose_style $style
#    }
#  }

  if { !$stipple_only } {
    # now build color map entries for transparent overlaps 
    _make_transparency [min $solids $maxTransparent]
  }

  # do composition (i.e. setup displays of "layer combinations" tiles e.g. nfet)
  # this will become unnecessary when we are fully coverted to 
  # simple layers = one layer per plane.
  foreach list $PAL_DATA(compose) {
    setl {layer l1 l2} $list
    if {[lindex $l2 0] == "stipple"} {
      # special case line nwc, pwc
      # first make the stipple (note: outlines not allowed)
      incr stipple
      set stipple_pattern [lrange $l2 1 end]

      set PAL_DATA(stipple,$stipple) $stipple_pattern
      eval lay_stipple $stipple $stipple_pattern

      setl {mask1 color1} [lay_style [lay_layer_styles $l1]]
      incr compose_style
#puts "$layer compose style $compose_style"
      lay_layer_styles $layer $compose_style
      lay_style $compose_style $mask1 $color1 0 stipple $stipple
      # NOTE: should contrive? a dimmer style here -- not important
      lay_style -dim $compose_style $mask1 $color1 0 stipple $stipple

    } else {
      # special case line nfet, pfet
      setl {mask1 color1} [lay_style [lay_layer_styles $l1]]
      setl {mask2 color2} [lay_style [lay_layer_styles $l2]]
  
      if {$color1 > $PAL_DATA(min_nontransparent_color) || \
	      $color2 > $PAL_DATA(min_nontransparent_color)} {
	# hack, blend colors ourselves and choose a fine stipple (2)
	if { $GR_COLOR_MAPPED } {
	  # color map mode

	  if {$color > 126} {
	    puts "PALETTE WARNING: too many colors"
	  } else {
	    incr color
	  }

	  _blend_color [expr $color1 + 0] [expr $color2 + 0] $color

	} else {
	  # truecolor mode
          set color [_blend_color $color1 $color2 $color]
#puts "$color1 $color2 --> $color"
	}

	# this style is first
	incr compose_style
#puts "$layer compose style $compose_style"
	lay_layer_styles $layer $compose_style
	lay_style $compose_style 0177 $color 0 stipple 2
	# Note: could make a stipple for dim stipple 2 and use 
	lay_style -dim $compose_style 0177 $color 0 stipple $stipple_dim

      } else {
	# both transparent
	incr compose_style
	lay_layer_styles $layer $compose_style
	lay_style $compose_style [expr $mask1 + $mask2] \
	    [expr $color1 + $color2] 0 solid 0
	lay_style -dim $compose_style [expr $mask1 + $mask2] \
	    [expr $color1 + $color2] 0 stipple $stipple_dim
      }
    }
  }

  # put in the special stipples now
  foreach thing $PAL_DATA(todo) {

    setl {type fill} $thing

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

    # can change stipple on only these layers
    set PAL_DATA(stipple,$stipple) $fill

    _pal_set_special_stipple $type $stipple $fill
  }
}

