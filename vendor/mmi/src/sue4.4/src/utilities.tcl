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


# Random useful generic utility procedures for sue.


# checks the tag list of an id to see if the tag is found

proc is_tagged {id tag} {

  global cur_c

  return [expr [lsearch [$cur_c gettags $id] $tag] != -1]
}

# finds the id of the origin of the object with a tag inst#
# if the # is missing, then the object is the origin

proc find_origin {id} {

  global cur_c

  set tags [$cur_c gettags $id]

  # look for inst# in the tags
  set inst_index [lsearch -regexp $tags ^inst]
  if {$inst_index == -1} {
    return $id
  }
  # extract out # out of inst#
  return [string range [lindex $tags $inst_index] 4 end]
}


# finds the tag that matches everyone in the group given by id.

proc find_origin_tag {id} {

  global cur_c

  set tags [$cur_c gettags $id]

  # look for inst# in the tags
  set inst_index [lsearch -regexp $tags ^inst]
  if {$inst_index == -1} {
    return $id
  }
  return [lindex $tags $inst_index]
}


# Finds the center of either a rectangle or line box from its id

proc center {id} {

  global cur_c

  set c [$cur_c coords $id]
  set type [$cur_c type $id]

  if {$type == "line"} {
    if {[is_tagged $id origin]} {
      return [list [expr ([lindex $c 0]+[lindex $c 2])/2] \
		  [expr ([lindex $c 1]+[lindex $c 3])/2]]
    } elseif {[is_tagged $id open]} {
      return [list [expr ([lindex $c 0]+[lindex $c 4])/2] \
		  [expr ([lindex $c 1]+[lindex $c 5])/2]]
    } else {
      return [list [expr ([lindex $c 0]+[lindex $c 2])/2] \
		  [expr ([lindex $c 4]+[lindex $c 5])/2]]
    }
  }
  if {$type == "rectangle" || $type == "arc"} {
    return [list [expr ([lindex $c 0]+[lindex $c 2])/2] \
		[expr ([lindex $c 1]+[lindex $c 3])/2]]
  }
  if {$type == "text"} {
    return [list [lindex $c 0] [lindex $c 1]]
  }
  if {$type == ""} {
    # id doesn't exist
    return ""
  }
  error "Don't know how to find center of type $type."
}


# Finds the center of the 4 coords or a bbox.

proc center_bbox {bbox} {

  return [list [snap [expr ([lindex $bbox 0]+[lindex $bbox 2])/2]] \
	      [snap [expr ([lindex $bbox 1]+[lindex $bbox 3])/2]]]
}


# rounds number to the canvas scale (i.e. grid)

proc snap {number} {

  global scale

  return [expr round(1.0*$number/$scale)*$scale]
}


# tags with new_tag all objects that have both tag1 and tag2
# OLD, replaced below

proc intersect_tag {new_tag tag1 tag2} {

  global cur_c

  $cur_c addtag Xsect1 withtag $tag1
  $cur_c dtag $tag2 Xsect1

  $cur_c addtag Xsect2 withtag $tag2
  $cur_c dtag $tag1 Xsect2

  $cur_c addtag Xsect2 withtag Xsect1
  $cur_c dtag Xsect1

  $cur_c addtag New withtag $tag1
  $cur_c addtag New withtag $tag2

  $cur_c dtag Xsect2 New
  $cur_c dtag Xsect2
  $cur_c addtag $new_tag withtag New
  $cur_c dtag New
}


proc intersect_tag {new_tag tag1 tag2} {

  global cur_c

  return [$cur_c addtag $new_tag withtag $tag1&$tag2]
}


# returns all id's which contain both tag1 and tag2
# OLD, replaced below

proc get_intersect_tag {tag1 tag2} {

  global cur_c

  $cur_c addtag Xsect1 withtag $tag1
  $cur_c dtag $tag2 Xsect1

  $cur_c addtag Xsect2 withtag $tag2
  $cur_c dtag $tag1 Xsect2

  $cur_c addtag Xsect2 withtag Xsect1
  $cur_c dtag Xsect1

  $cur_c addtag Xsect1 withtag $tag1
  $cur_c addtag Xsect1 withtag $tag2

  $cur_c dtag Xsect2 Xsect1
  $cur_c dtag Xsect2

  set list [$cur_c find withtag Xsect1]
  $cur_c dtag Xsect1

  return $list
}


proc get_intersect_tag {tag1 tag2} {

  global cur_c

  return [$cur_c find withtag $tag1&$tag2]
}


# provides information about the state of the current canvas for debugging

proc info_canvas {{grep ""}} {

  global cur_c

  set alltags [$cur_c find all]
  foreach i $alltags {
    set info "$i [$cur_c type $i] [$cur_c gettags $i]"
    if {$grep == "" || [string first $grep $info] != -1} {
      puts $info
    }
  }
}

# This routine returns the procedure name of the calling routine
# an optional argument returns the nth calling procedure

proc current_procedure {{up 0}} {

  # get level
  set level [info level]

  # Actually want level of caller
  set level [expr $level - 1 - $up]

  set name [lindex [info level $level] 0]

  return $name
}


###########################################################################
# if two sets of coords are nearby (i.e. within del of eachother) then
# return a 1, otherwise return a 0.  This in theory is not required because
# of gridding.
###########################################################################

proc nearby {x1 y1 x2 y2 {del ""}} {

  global scale

  if {$del == ""} {
    set del [expr $scale/3.0]
  }

  if {[expr abs($x1-$x2)] < $del && [expr abs($y1-$y2)] < $del} {
    return 1
  }
  return 0
}

proc nearby_num {x1 x2 {del ""}} {

  global scale

  if {$del == ""} {
    set del [expr $scale/3.0]
  }

  if {[expr abs($x1-$x2)] < $del} {
    return 1
  }
  return 0
}


# Accepts a list of numbers and rounds them to the nearest integer, 
# returning the rounding value in a new list

proc round_list {x} {

  set out ""
  foreach y $x {
    lappend out [expr round($y)]
  }

  return $out
}


# this could be merged into round_list but tcl is so pathetically slow
# with numbers, I couldn't do it.

proc round_list_scale {x scale} {

  set out ""
  foreach y $x {
    lappend out [expr round(1.0*$y/$scale)*$scale]
  }

  return $out
}


# scales each element in a list

proc scale_list {list scale} {

  set out ""
  foreach element $list {
    lappend out [expr $element * $scale]
  }

  return $out
}


# returns the size of the text with the given id as a keyword pair or ""
# if it is the default (standard).

proc text_size {id} {

  global cur_c

  set tags [$cur_c gettags $id]
  set size [string range [lindex $tags [lsearch $tags size_*]] 5 end]
  if {$size == "standard"} {
    return ""
  } else {
    return " -size $size"
  }
}


# returns the anchor position of the text with the given id as a keyword
# pair of "" if it is the default (w).  Only works for icons where it
# makes any sense.

proc text_anchor {id {opposite ""}} {

  global cur_c cur_s

  set anchor [$cur_c itemcget $id -anchor]
  if {$opposite == ""} {
    if {$anchor == "w"} {
      return ""
    } else {
      return " -anchor $anchor"
    }
  } else {

    switch $anchor {
      "w" { return " -anchor e" }
      "c" { return " -anchor c" }
      "center" { return " -anchor center" }
      "e" { return "" }

      default { return "" }
    }
  }
}


# swaps values of two variables

proc swap_var {var1 var2} {

  upvar $var1 _var1
  upvar $var2 _var2

  set tmp $_var1
  set _var1 $_var2
  set _var2 $tmp
}


# just like incr but if the argument isn't defined, sets to 0.

proc incrX {var {inc 1}} {

  upvar $var data

  if {[info exists data] != 1} {
    set data 0
  }

  incr data $inc
}


proc warning {msg} -type user -desc {

Creates a popup window with the given message in it.  Often used for
warning the user about something.

Also prints the message to the SUE command window.

If BATCH is set to 1, will not create the popup window.

} {

  global SUE_DIR

  # write to warning to screen
  puts $msg

  if {[string length $msg] > 1000} {
    # only show part to the screen
    set msg "[string range $msg 0 900]\n...\n{Too many errors.  See SUE command window.}"
  }

  # give user a nice dialog box to play with
  set button [tk_dialog .warning "Warning" $msg \
		  @$SUE_DIR/sue_icon.xbm 0 {ok}]

  return 1
}


# saves up error messages.  When flushed will give a popup window if
# the appropriate switch is set in .suerc

proc sue_error {message {cell ""}} {

  global SUE_ERRORS ERROR_POPUP SUE_DIR NONEWLINE NETLIST_CACHE NETLIST 
  global ANY_ERROR

  if {$message == "flush"} {
    if {[use_first SUE_ERRORS] == ""} {
      # no errors to report
      return 0
    }

    if {$ERROR_POPUP == 1} {
      # check to see that there aren't too many errors to show.
      if {$NETLIST(popup_length) > [llength $SUE_ERRORS]} {
	set text $SUE_ERRORS
      } else {
	set text "[lrange $SUE_ERRORS 0 [expr $NETLIST(popup_length)-1]] {Too many errors.  See SUE command window.}"
      }

      # clear away those nasty errors.  Must do this first.
      set SUE_ERRORS ""

      # make a popup and show all the happy errors
      set button [tk_dialog .errors "ERRORS" \
		      [join $text "\n"] \
		      @$SUE_DIR/sue_icon.xbm 0 {ok}]

    } else {
      # clear away those nasty errors
      set SUE_ERRORS ""
    }

    set NETLIST(error) 0

    return 1
  }

  if {[use_first NONEWLINE] == 1} {
    puts ""
    set NONEWLINE 0
  }

  puts $message
  lappend SUE_ERRORS $message

  set NETLIST_CACHE($cell,error) error

  set NETLIST(error) 1
  # there is an error in this sue session.  Used by exit.
  set ANY_ERROR 1

  return
}


# prints out the warning and saves it away

proc sue_warning {message {type ""}} {

  global cur_s NONEWLINE NETLIST_CACHE

  if {[use_first NONEWLINE] == 1} {
    puts ""
    set NONEWLINE 0
  }

  puts $message

  if {$type == ""} {
    lappend NETLIST_CACHE($cur_s,warnings) $message
  } else {
    global $type
    lappend ${type}($cur_s,warnings) $message
  }

  return
}


# returns the schematic name

proc get_rootname {schematic} {

  if {[lsearch $schematic "ICON_*"] != -1} {
    return [string range $schematic 5 end]
  } else {
    return $schematic
  }
}



# Makes it easy to reload changes/fixes.

proc reload {file} {

  global SUE_DIR SOURCE_DIR

  set dir [use_first SOURCE_DIR SUE_DIR]

  if {![file readable $dir/src/$file]} {
    set file "$file.tcl"
  }

  puts "Sourcing $dir/src/$file"
  # need to source this file in the top level context
  uplevel #0 "source $dir/src/$file"
}


# Translates numbers like 2x and 3x into '2*Wmin', '3*Wmin'

proc x {exp} {

  regsub {^([0-9\.]+)(x)$} $exp {'\1*Wmin'} exp

  return $exp
}


# prints the coords of the selected object scaled.

proc sue_coords {{id ""}} {

  global cur_c

  if {$id == ""} {
    set id [lindex [$cur_c find withtag selected] 0]
    if {$id == ""} {
      return ""
    }
    set id [find_origin $id]
  }

  if {[is_tagged $id wire]} {
    set coords [$cur_c coords $id]
    return "<[scale_coord $coords 0],[scale_coord $coords 1] to [scale_coord $coords 2],[scale_coord $coords 3]>"
  }

  if {[is_tagged $id draw_item]} {
    # lines and arcs are different
    set type [$cur_c type $id]
    if {$type == "arc"} {
      foreach coord [$cur_c coords $id] {
	lappend c [scale_coord $coord]
      }
      set start [$cur_c itemcget $id -start]
      set extent [$cur_c itemcget $id -extent]
      return "<$c> start $start extent $extent"
    }
    if {$type == "line"} {
      foreach coord [$cur_c coords $id] {
	lappend c [scale_coord $coord]
      }
      return "<$c>"
    }
  }

  set center [center $id]

  return "<[scale_coord $center 0],[scale_coord $center 1]>"
}


proc scale_coord {n {index 0}} {

  global scale

  return [expr round([lindex $n $index] * 10/$scale)]
}



# creates a menu item and stores the hotkey for that menu in a string
# to be executed later (per canvas).

proc menu_add {args} -type user -desc {

Adds a menu item to the bottom of the given SUE menu.

Usage:

        menu_add [-menu (file|edit|view|sim|local|help)] -label <name> 
                 -command <command> [-hotkey <hotkey>] [-help <string>]
                 [-position <line>]

<command> is executed when the user clicks on this <name> menu option
or hits the optional hotkey.  The <string> help line will be displayed
in the message window when the user has the cursor over the menu
item.  If the label <name> is "separator", then a separator line
will be added to the menu.

If no menu is specified, the menu defaults to the local menu.  By
default, the new menu option will be placed at the bottom of the
specified menu.  To place it in another location, specify the <line>
position, and it will try to place it at that line number.

For example:

        menu_add -label separator
        menu_add -label foo -command "puts foo" -help "yippee!"

SUE will not permit multiple menu entries with the same name.  If the
new menu item has the same name as an existing, the old one will be
replaced or moved.  
} {

  global WIN_DATA WIN KEYS MENU_HELP MENUS READ_ONLY_MODE

  if {![info exists WIN]} {
    # store this away for later
    lappend WIN_DATA(menu) $args
    return
  }

  if {[catch [list call_by_keyword $args {{menu local} {label ""} {command ""} {hotkey ""} {help ""} {position ""} {modify 0}}] msg]} {
    sue_error $msg
    return
  }

  if {$position != "" && [catch "expr $position"]} {
    sue_error "Illegal menu position, must be an integer: menu_add $args"
    return
  }

  if {[lsearch "file edit view sim local help" $menu] == -1} {
    sue_error "Illegal menu in line: menu_add $args"
    return
  }

  if {$label == ""} {
    sue_error "Must provide a label to a menu in line: menu_add $args"
    return
  }
  set trimlabel [string trim $label]
  regsub -all {\.} $trimlabel "" trimlabel

  if {$trimlabel == "separator"} {
    if {$position != ""} {
      $WIN.mbar.$menu.menu insert $position separator
    } else {
      $WIN.mbar.$menu.menu add separator
    }
    return
  }

  if {$command == ""} {
    sue_error "Must provide a command to a menu in line: menu_add $args"
    return
  }

  # look for a hotkey defined through the KEYS global array if not given
  set hotkey [use_first hotkey KEYS([string tolower [join $trimlabel _]])]

  if {[info exists MENUS($trimlabel)] && $MENUS($trimlabel) != $menu} {
    # move a menu item to another menu.
    set _menu $MENUS($trimlabel)
    if {![catch {$WIN.mbar.$_menu.menu index $label} index]} {
      $WIN.mbar.$_menu.menu delete $index
    }
  }
  set MENUS($trimlabel) $menu

  if {[catch {$WIN.mbar.$menu.menu index $label} index]} {
    # new label, add
    if {$READ_ONLY_MODE && $modify} {
      # disable this guy
      $WIN.mbar.$menu.menu add command -label $label -state disabled \
	  -command [list launch $command] -accelerator [abbrev $hotkey]
    } else {
      if {$position == ""} {
	$WIN.mbar.$menu.menu add command -label $label \
	    -command [list launch $command] -accelerator [abbrev $hotkey]
      } else {
	$WIN.mbar.$menu.menu insert $position command -label $label \
	    -command [list launch $command] -accelerator [abbrev $hotkey]
      }
    }

  } else {
    # replace existing
    $WIN.mbar.$menu.menu delete $index
    if {$position == ""} {
      # replace in same position
      $WIN.mbar.$menu.menu insert $index command -label $label \
	  -command [list launch $command] -accelerator [abbrev $hotkey]
    } else {
      $WIN.mbar.$menu.menu insert $position command -label $label \
	  -command [list launch $command] -accelerator [abbrev $hotkey]
    }
  }

  set hotkey_change 0

  # delete hotkey if it existed for this before
  if {[info exists MENUS(HOTKEY,$trimlabel)]} {
    catch "unset WIN_DATA($WIN,keys,$MENUS(HOTKEY,$trimlabel))"
    unset MENUS(HOTKEY,$trimlabel)
    set hotkey_change 1
  }

  # remember hotkey (duplicates get overridden).
  if {$hotkey != ""} {
    set WIN_DATA($WIN,keys,$hotkey) [list launch $command]
    set MENUS(HOTKEY,$trimlabel) $hotkey
    set hotkey_change 1
  }

  # add help entry
  if {$help != ""} {
    set MENU_HELP([string tolower [join $trimlabel _]]) $help
    set MENU_HELP($hotkey) $help
  }

  global CURRENT_BINDINGS DELAY_UPDATING_BINDINGS
 

  if {$hotkey_change && [info exists CURRENT_BINDINGS] && \
	  !$DELAY_UPDATING_BINDINGS} {
    # this command is added after the start, need to add hotkey
    # to get into this and all canvases
    update_bindings
  }
}


# update bindings for windows after a change

proc update_bindings {} {

  global CURRENT_BINDINGS

  if {[info exists CURRENT_BINDINGS]} {
    clear_bindings
    setup_bindings
    save_bindings newest
    incr CURRENT_BINDINGS
  }
}


# Add a binding and associated help

proc bind_add {args} {

  global cur_c MENU_HELP

  if {[catch [list call_by_keyword $args {{mode ""} {type ""} {window ""} {hotkey ""} {command ""} {help ""} {no_launch 0}}] msg]} {
    sue_error $msg
    return
  }

  set window [use_first window cur_c]

  if {$command == ""} {
    sue_error "Must provide a command to a menu in line: bind_add $args"
    return
  }

  if {$command == "_UNSET_"} {
    # unset this binding
    set command ""
  }

  if {$hotkey == ""} {
    # not bound to anything
    return
  }

  if {!$no_launch} {
    # always use launch except inside of modes
    if {$mode == ""} {
      set command [list launch $command]
    } else {
      set command [list launch $command no_busy]
    }
  }

  # bind her up
  if {$hotkey == "?"} {
    # weird special case
    bind $window $hotkey $command
  } else {
    if {$type != ""} {
      $window bind $type <$hotkey> $command
    } else {
      bind $window <$hotkey> $command
    }
  }

  regsub "Any-" $hotkey "" hotkey

  # add help entry
  if {$help != ""} {
    if {$mode != ""} {
      set MENU_HELP($mode,mode,$hotkey) $help
    } elseif {$type != ""} {
      set MENU_HELP($type,$hotkey) $help
    } elseif {$window == $cur_c} {
      set MENU_HELP($hotkey) $help
    } else {
      set MENU_HELP($window,$hotkey) $help
    }
  }
}


# special command to figure out if this command corresponds to a 
# icons/schematic listbox and execute.  Required due to focus weirdness.

proc scroll_listbox {command x y} {

  global cur_c HELP_FONT WIN_DATA WIN ICON_WINDOWS MENU_HELP

  set mouse_win [winfo containing [expr $x + [winfo rootx $WIN]] \
		     [expr $y + [winfo rooty $WIN]]]

  if {[regexp -indices {lb.(schematic|icon)} $mouse_win pos]} {
    set end [string range $mouse_win [lindex $pos 1] end]
    if {[string first . $end] == -1} {
      set mouse_win "${mouse_win}.nodes"
    }

    regsub .scroll$ $mouse_win .nodes mouse_win
    regsub .dir$ $mouse_win .nodes mouse_win

    eval $mouse_win yview scroll $command
  }
}


# BUS Primitives
# buses have the \[ character in their names

proc is_bus {name} {

  if {[string first \[ $name] != -1} {
    # is a bus
    return 1

  } else {
    # not a bus
    return 0
  }
}


# concatenated buses

proc is_cbus {name} {

  if {[string first \[ $name] != -1 || [string first , $name] != -1} {
    # is a bus
    return 1

  } else {
    # not a bus
    return 0
  }
}


# returns a list of all signal names on a bus
# Only understands foo, foo[num], foo[msb:lsb] for now
# if it recieves [num] or [msb:lsb] then it appends the default
# root onto the front of it

# format allows numbers to be padded for sorting

proc bus_expand {name {format "%d"}} -type user -desc {

Expands <name> into a list of all of its bits and returns it.  Returns
bits in lsb to msb order.  Also expands verilog binary constant
notation like 2'b01.  Does not expand comma separated list or other
syntax.

For example: 

        sue> bus_expand {foo[3:0]}
        foo[0] foo[1] foo[2] foo[3]
        sue> bus_expand bar
        bar
        sue> bus_expand 2'b01
        vdd gnd
} {

  global MAX_BUS_WIDTH cur_s

  # null names return null names
  if {$name == ""} {
    return 
  }

  # remove any leading zeros in buses - tcl thinks it means octal
  regsub -all {(\[)(0)*([0-9])} $name {[\3} name
  regsub -all {(:)(0)*([0-9])} $name {:\3} name

  set name_list [split $name "\[:\]"]

  if {[set len [llength $name_list]] < 4} {
    # not a bus

    if {$len == 3} {
      # single bit of a bus
      set bit [lindex $name_list 1]

      if {[catch "expr $bit"]} {
	sue_error "Invalid bus name \"$name\" in schematic \"$cur_s\"." $cur_s
	return $name
      }

      return "[lindex $name_list 0]\[[format $format $bit]\]"
    }

    if {[regexp {'(b|h|d|o)} $name]} {
      # this is a constant, expand and possible pad
      global GLOBAL_TRANSLATIONS NETLIST_TYPE

      # does the real work
      set bnum [const_to_binary $name]

      regsub -all {0|1} $bnum "1'b& " bus

      if {[info exists GLOBAL_TRANSLATIONS($NETLIST_TYPE,1'b0)]} {
	regsub -all {1'b0} $bus $GLOBAL_TRANSLATIONS($NETLIST_TYPE,1'b0) bus
      }

      if {[info exists GLOBAL_TRANSLATIONS($NETLIST_TYPE,1'b1)]} {
	regsub -all {1'b1} $bus $GLOBAL_TRANSLATIONS($NETLIST_TYPE,1'b1) bus
      }

      return [lreverse $bus]
    }

    return $name
  }

#  setl {root msb lsb} $name_list
    set root [lindex $name_list 0]
    set msb [lindex $name_list 1]
    set lsb [lindex $name_list 2]

  if {[catch "expr $lsb"] || [catch "expr $msb"]} {
    # error
    sue_error "Invalid bus name \"$name\" in schematic \"$cur_s\"." $cur_s
    return $name
  }

  if {[expr abs($lsb - $msb)] > $MAX_BUS_WIDTH} {
    # error
    global cur_s
    sue_error "Invalid bus name \"$name\" in schematic \"$cur_s\".  Bus too large, increase MAX_BUS_WIDTH (set to $MAX_BUS_WIDTH) if necessary." $cur_s
    
    return $name
  }

  if {$lsb > $msb} {
    # count down
    set incr -1
  } else {
    set incr 1
  }

  set list ""
  for {set i $lsb} {$i != $msb} {incr i $incr} {
    lappend list $root\[[format $format $i]\]
  }
  lappend list $root\[[format $format $i]\]

  # lappend adds curly brackets -- lose them
  regsub -all {\{|\}} $list {} list

  return $list
}


proc cbus_expand {name {format "%d"}} -type user -desc {

Expands <name> into a list of all of its bits and returns it.  Returns
bits in lsb-to-msb order.  Also expands verilog binary constant
notation like 2'b01.  Expands comma separated syntax but not other
syntax.

For example: 

        sue> cbus_expand {foo[1:0],bar}
        bar foo[0] foo[1]
        sue> cbus_expand {foo[1:0],2'b01,foo[1]}
        foo[1] vdd gnd foo[0] foo[1]
} {

  set bits ""

  foreach one [split $name ,] {

    if {$bits == ""} {
      set bits [bus_expand $one]
    } else {
      set bits "[bus_expand $one] $bits"
    }
  }

  return $bits
}


proc bus_width {name} -type user -desc {

Returns the bus width of <name>.  Only understands SUE bus notation. 

For example: 

        sue> bus_width {foo[3:0]}
        4
        sue> bus_width bar
        1
} {

  if {$name == ""} {
    return 0
  }

  if {[string first , $name] != -1} {
    # error, can't have concatenated buses here
    global cur_s

    sue_error "Can't use concatenated buses here ($name) in schematic \"$cur_s\"." $cur_s
    return 1
  }

  set name_list [split $name "\[:\]"]

  if {[llength $name_list] < 4} {
    # check for verilog syntax global, i.e. 2'b01
    if {[regexp {^([0-9]+)'} $name tmp width]} {
      return $width
    }

    # not a bus
    return 1
  }

  return [expr abs([lindex $name_list 1] - [lindex $name_list 2]) + 1]
}


proc cbus_width {name} -type internal -desc {

Returns the bus width of <name>.  Only understands SUE bus notation. 

For example: 

        sue> cbus_width {foo[3:0],bar[2:0]}
        7
        sue> cbus_width bar
        1
} {

  if {$name == ""} {
    return 0
  }

  regsub -all { } $name "" name

  set width 0
  foreach one [split $name ,] {

    set name_list [split $one "\[:\]"]

    if {[llength $name_list] < 4} {
      # check for verilog syntax global, i.e. 2'b01
      if {[regexp {^([0-9]+)'} $one tmp this_width]} {
	incr width $this_width
      } else {
	# not a bus
	incr width
      }
    } else {
      incr width [expr abs([lindex $name_list 1] - [lindex $name_list 2]) + 1]
    }
  }

  return $width
}


# return the root of the bus, e.g. foo is the bus_root of foo[3:2]

proc bus_root {name} {

  return [lindex [split $name \[] 0]
}


# for concatenated buses

proc cbus_root {name} {

  # remove whitespace TODO: tab also
  regsub -all { } $name "" name

  set list ""
  foreach one [split $name ,] {
    set root [lindex [split $one \[] 0]
    if {$root != ""} {
      lappend list $root
    }
  }

  return $list
}


# returns 1 if bus is valid (numerical), 0 otherwise

proc valid_bus {name} {

  set name_list [split $name "\[:\]"]

  set len [llength $name_list]

  if {$len < 3} {
    # not a bus
    return 0
  }

  if {$len > 4} {
    # toasted up
    return 0
  }

  if {[catch "expr [lindex $name_list 1]"]} {
    return 0
  }

  if {$len == 4} {
    if {[catch "expr [lindex $name_list 2]"]} {
      return 0
    }
  }

  # yes
  return 1
}


# returns a list giving the first and second elements in the bus

proc bus_range {name} {

  set name_list [split $name "\[:\]"]

  set len [llength $name_list]

  if {$len < 3} {
    # not a bus
    return ""
  }

  if {$len > 4} {
    # toasted up
    puts "ERROR: illegal bus range \"$name\""
    return "-1 -1"
  }

  if {$len == 3} {
    # a bit in a bus
    set bit [lindex $name_list 1]
    if {[catch "expr $bit"]} {
      puts "ERROR: illegal bus \"$name\""
      set bit 0
    }

    return "$bit $bit"
  }

  # Bus range
  setl msb [lindex $name_list 1]
  setl lsb [lindex $name_list 2]

  if {[catch "expr $lsb"] || [catch "expr $msb"]} {
    puts "ERROR: illegal bus range \"$name\""
    return "-1 -1"
  }

  return "$msb $lsb"
}


# returns the largest extent of the bus containing these names

proc bus_extent {names {default_order down}} {

  set dir ""
  set tmax ""
  set bad ""

  foreach name $names {
    setl {max min} [bus_range $name]

    if {$min == ""} {
      # not a bus, error
      lappend bad $name
      continue
    }

    if {$min > $max} {
      if {$dir == "down"} {
	lappend bad $name
	continue
      }

      set dir up

      # flip'm
      set tmp $min
      set min $max
      set max $tmp

    } elseif {$min < $max} {
      if {$dir == "up"} {
	lappend bad $name
	continue
      }
      set dir down
    }

    if {$tmax == ""} {
      set tmax $max
      set tmin $min
    } else {
      set tmax [max $tmax $max]
      set tmin [min $tmin $min]
    }
  }

  if {$bad != ""} {
    # print errors
    set other_names ""
    foreach name $names {
      if {[lsearch -exact $bad $name] == -1} {
	lappend other_names $name
      }
    }

    global cur_s
    if {$other_names == ""} {
      sue_error "ERROR: skipping [join $bad {, }]: no bus_extent of scalars in cell \"$cur_s\"." $cur_s
    } else {
      sue_error "ERROR: skipping [join $bad {, }]: can't be combined with [join $other_names {, }] in cell \"$cur_s\"." $cur_s
    }
  }

  if {$tmax == ""} {
    return ""
  } elseif {$tmax == $tmin} {
    return "\[$tmax\]"
  } elseif {$dir == "down"} {
    return "\[$tmax:$tmin\]"
  } elseif {$dir == "up"} {
    return "\[$tmin:$tmax\]"
  } elseif {$default_order == "down"} {
    return "\[$tmax:$tmin\]"
  } else {
    return "\[$tmin:$tmax\]"
  }
}


# returns 1 (true) is bus1 is a subset of bus2.  Otherwise returns 0 (false).

proc bus_subset {bus1 bus2} {

  setl {min1 max1} [lsort -integer [bus_range $bus1]]

  if {$max1 == ""} {
    # not a bus
    return 1
  }

  setl {min2 max2} [lsort -integer [bus_range $bus2]]

  if {$max2 == ""} {
    # not a bus
    return 0
  }
  
  if {$min1 >= $min2 && $max1 <= $max2} {
    return 1
  } else {
    return 0
  }
}


# for concatenated buses.  Is bus1 a subset of bus2.

proc cbus_subset {bus1 bus2} {

  foreach one [split $bus1 ,] {
    if {![cbus_subset_int $one $bus2]} {
      return 0
    } 
  }

  return 1
}


# like cbus_subset but requires bus1 to not be a concatenated bus.

proc cbus_subset_int {bus1 bus2} {

  setl {min1 max1} [lsort -integer [bus_range $bus1]]

  if {$max1 == ""} {
    # not a bus, check if rootname matches
    if {[lsearch [cbus_root $bus2] $bus1] == -1} {
      return 0
    } else {
      return 1
    }
  }

  set root1 [bus_root $bus1]

  foreach one [split $bus2 ,] {

    setl {root2 msb lsb} [split $one \[:\]]

    if {$msb == ""} {
      # not a bus
      continue
    }
  
    if {$root1 != $root2} {
      # wrong root
      continue
    }

    if {$lsb == ""} {
      set lsb $msb

    } elseif {$msb < $lsb} {
      # put in canonical order
      set tmp $msb
      set msb $lsb
      set lsb $tmp
    }

    if {$min1 >= $lsb && $max1 <= $msb} {
      # success
      return 1
    }
  }

  return 0
}


# translates bit of from_bus into the corresponding bit of to_bus.
# useful for tracing wires up and down through the hierarchy.

# Note: will also convert subranges, not just bits.
# Doesn't check ranges.

# NOTE: from_bus cannot be a concat bus
# if to_bus is a concat bus, return a concat bus, not compressed.


proc bit_convert {bit from_bus to_bus} {

  if {[string first , $to_bus] != -1} {
    # special case with concat buses (slower)
    if {[bus_root $bit] == ""} {
      set bit "[bus_root $from_bus]$bit"
    }

    set bit [bus_expand $bit]
    set from_bus [bus_expand $from_bus]
    
    set pos [string first $bit $from_bus]

    if {$pos != -1} {
      # found match
      set len [llength [string range $from_bus 0 [expr $pos -1]]]

      return [join [lreverse [lrange [cbus_expand $to_bus] $len [expr $len + [llength $bit] - 1]]] ,]
    }
    
    # bad
    return $to_bus
  }

  setl {e s} [bus_range $bit]

  if {$s == ""} {
    # error, just return to_bus
    return $to_bus
  }

  setl {fe fs} [bus_range $from_bus]

  setl {te ts} [bus_range $to_bus]
  set root [bus_root $to_bus]

  if {($ts > $te && $fs < $fe) || ($ts < $te && $fs > $fe)} {
    # bit ordering is reversed
    if {$e == $s} {
      return "$root\[[expr $fe - $s + $te]\]"
    } else {
      return "$root\[[expr $fe - $s + $te]:[expr $fe - $e + $te]\]"
    }
  } else {
    if {$e == $s} {
      return "$root\[[expr $s - $fs + $ts]\]"
    } else {
      return "$root\[[expr $e - $fs + $ts]:[expr $s - $fs + $ts]\]"
    }
  }
}


# convert lines of the form
#      `define SRCBASE			[23:0]	    // comment
# to 
#      set __SRCBASE {[23:0]}

proc load_verilog_defines {filename {debug ""}} -type user -desc {

Reads a verilog defines file and converts lines of the form

      `define SRCBASE			23:0	    // comment
into 

      set __SRCBASE 23:0

Net names and instance names can be defined using [`SRCBASE], for example,
and sue will look up their values in __SRCBASE for substition.
  
If passed the option parameter "debug" then will print out the set
lines to the SUE command window when run.

} {

  # open the verilog file to parse
  set FILE_ID [open $filename r]

  puts "Loading verilog define file $filename."

  # now read it
  while {[gets $FILE_ID line] >= 0} {
    set line [string trim $line]
    if {[string range $line 0 1] == "//"} {
      # comment line, ignore
      continue
    }

    if {[string range $line 0 1] == "/*"} {
      # comment start, look for end
      while {1} {
	if {[set pos [string first "*/" $line]] != -1} {
	  # found close
	  set line [string range $line [expr $pos + 2] end]
	  break
	}

	# look on the next line
	gets $FILE_ID line
	set line [string trim $line]
      }
    }

    if {$line == ""} {
      continue
    }

    if {[set pos [string first "/*" $line]] != -1 || \
	    [set pos [string first "//" $line]] != -1} {
      # comment -- kill to end of line (NOT NECESSARILY CORRECT)
      set line [string trim [string range $line 0 [expr $pos - 1]]]
    }

#    puts $line

    setl {command var} $line
    set value [lrange $line 2 end]
    regsub -all { } $value "" value

    if {$command == "`define"} {
      if {[string first ` $value] != -1} {
	# variables lurk
	regsub -all {`} $value {$__} value
	if {[catch {uplevel #0 "concat $value"} msg]} {
	  puts "LOAD DEFINE ERROR: $msg"
	} else {
	  set value $msg
	}
      }

      # remove any leading zeros in buses - tcl thinks it means octal
      regsub -all {(\[)(0)*([0-9])} $value {[\3} value
      regsub -all {(:)(0)*([0-9])} $value {:\3} value

      if {[catch {uplevel #0 "set __$var {$value}"} msg]} {
	puts "LOAD DEFINE ERROR: $msg"
      } elseif {$debug != ""} {
	global __$var
	puts "set __$var [set __$var]"
      }
    }
  }

  # close the file
  close $FILE_ID
}


# fix off grid schematics that got there through bugs

proc fix_off_grid {} {

  global cur_c scale

  puts "fixing off-grid problems ..."

  busy

  set save_scale $scale
  scale_canvas 10

  remove_connects

  # fix icons
  foreach id [$cur_c find withtag origin] {

    setl {x y} [$cur_c coords $id]

    set dx [expr 10*round($x/10.0) - $x]
    set dy [expr 10*round($y/10.0) - $y]

    $cur_c move inst$id $dx $dy
  }

  # fix wires
  foreach id [$cur_c find withtag wire] {
    eval $cur_c coords $id [round_list_scale [$cur_c coords $id] 10]
  }

  # put connection info back in
  show_connects "" clean 

  scale_canvas $save_scale

  is_modified

  ready

  puts "done."
}


# new auto_mkindex that caches modification times of files so it doesn't
# always have to be rerun.  Note: compatible with old tclIndex files.

proc sue_auto_mkindex {dir args} {

  global errorCode errorInfo TCLINDEX_TIME TCLINDEX

  if {[tclIndex_up_to_date $dir $args]} {
    # don't need to rerun
    puts "Up-to-date."
    return
  }

  set oldDir [pwd]
  cd $dir
  set dir [pwd]

  append index "# Tcl autoload index file, version 2.0\n"
  append index "# This file is generated by the \"auto_mkindex\" command\n"
  append index "# and sourced to set up indexing information for one or\n"
  append index "# more commands.  Typically each line is a command that\n"
  append index "# sets an element in the auto_index array, where the\n"
  append index "# element name is the name of a command and the value is\n"
  append index "# a script that loads the command.\n\n"
  append index "# Special SUE version which includes file modification times.\n\n"

  if {$args == ""} {
    set args *.tcl
  }

  # special variable to cache modification times
  set mtimes ""

  foreach type $args {
    foreach file [eval glob -nocomplain $type] {
      set f ""
      set error [catch {
	set f [open $file]
	lappend mtimes [list $file [file mtime $file]]
	while {[gets $f line] >= 0} {
	  if {[regexp {^proc[ 	]+([^ 	]*)} $line match procName]} {
	    set procName [lindex [auto_qualify $procName "::"] 0]
	    append index "set [list auto_index($procName)]"
	    append index " \[list source \[file join \$dir [list $file]\]\]\n"
	  }
	}
	close $f
      } msg]

      if {$error} {
	catch {close $f}
	cd $oldDir
	error $msg $errorInfo $errorCode
      }
    }
  }

  # write out the tclIndex file
  set f ""
  # make sure this is writable to all
  catch "exec chmod a+rw tclIndex"
  set error [catch {
    set f [open tclIndex w]
    puts $f $index nonewline
    puts $f "set mtimes \{$mtimes\}"
    close $f
    catch "exec chmod a+rw tclIndex"
    cd $oldDir

    puts "Created and Saved."

  } msg]

  if {$error} {
    catch {close $f}

    # tclindex's in SUE get loaded after creation.
    # since we can't write this one to disk, just set values

    global auto_index
    catch $index

    cd $oldDir
    set TCLINDEX_TIME($dir) [clock seconds]

    # save for auto_load_index
    set TCLINDEX($dir) $index

    puts "Created."

#    error $msg $errorInfo $errorCode
  }
}


# check the tclIndex to see if it is already up-to-date.

proc tclIndex_up_to_date {dir args} {

  set oldDir [pwd]
  cd $dir
  set dir [pwd]
  
  # Note that this is done in a local context so all set statements
  # in the tclIndex don't affect any global state
  catch "exec chmod a+rw tclIndex"
  if {[catch "source tclIndex"]} {
    # error, probably doesn't exists, punt.
    cd $oldDir
    return 0
  }

  # look for modification times of files
  if {![info exists mtimes]} {
    # probably ran with tcl auto_mkIndex, punt
    cd $oldDir
    return 0
  }

  # check if any of the files in the tclIndex have been changed or deleted 
  foreach pair $mtimes {
    setl {file cached_mtime} $pair
    if {[catch {set mtime [file mtime $file]}]} {
      # file probably doesn't exist, punt
      cd $oldDir
      return 0
    }

    if {$mtime > $cached_mtime} {
      # file has been changed, punt.
      cd $oldDir
      return 0
    }

    # this file hasn't changed
    set trace($file) 1
  }

  # check if any new files have been added to the directory
  foreach type $args {
    foreach file [eval glob -nocomplain $type] {
      if {![info exists trace($file)]} {
	# new file, punt.
	cd $oldDir
	return 0
      }
    }
  }

  cd $oldDir

  # she's up-to-date
  return 1
}


# used by the sign_extender to tie verilog nets together

proc verilog_expand {out in} {

  set verilog ""
  foreach one [bus_expand $out] {
    lappend verilog $in
  }

  return [join $verilog ", "]
}


# returns the relative origin for window placements.  for use in wm 
# geometry statements.

proc relative_origin {{win ""} {dx 50} {dy 50}} {

  global WIN

  if {$win == ""} {
    set win $WIN
  }

  set winx [expr [winfo rootx $win] + $dx]
  set winy [expr [winfo rooty $win] + $dy]

  return "+$winx+$winy"
}


# looks to see if the user hit ctrl-c and starts stopping things

proc check_interrupt {} {

  global INTERRUPT

  if {$INTERRUPT} {
    # return out of calling procedure
    return -code return
  }

  if {[mmi_interrupt]} {
    # user hit ctrl-c
    set INTERRUPT 1

#    puts "Aborting, Interrupt in procedure \"[info level [expr [info level] - 1]]\""

    # return out of calling procedure
    return -code return
  }
}


# expects explicit binary, octal, decimal, or hex constants like 2'b01.
# returns string of [01xz] of correct length, or "" for error
# if too short, extends x or z, else pads with 0
# trims leading 0s if too long.  yells if non-0 exceeds desired width.

proc const_to_binary {num {prefix 0}} {

  global cur_s

  set orig $num

  # remove underscores
  regsub -all _ $num "" num

  # check for each of the bases
  if {[regexp -nocase {^([0-9]+)'b([01xz]+)$} $num dummy width num]} {
    # no conversion necessary for binary
  } elseif {[regexp -nocase {^([0-9]+)'o([0-7xz]+)$} $num dummy width num]} {
    # convert octal
    regsub -nocase -all 0 $num 000 num
    regsub -nocase -all 1 $num 001 num
    regsub -nocase -all 2 $num 010 num
    regsub -nocase -all 3 $num 011 num
    regsub -nocase -all 4 $num 100 num
    regsub -nocase -all 5 $num 101 num
    regsub -nocase -all 6 $num 110 num
    regsub -nocase -all 7 $num 111 num
    regsub -nocase -all x $num xxx num
    regsub -nocase -all z $num zzz num
  } elseif {[regexp -nocase {^([0-9]+)'d([0-9]+)$} $num dummy width num]} {
    # convert decimal
    if {[string length $num] > 9} {
      # but not if it's big enough to give sign problems on a 32' machine
      sue_error "NETLIST_ERROR: Can't convert decimals over 9 digits: $orig." $cur_s
      return ""
    }
    # remove leading 0s, so tcl won't think it's octal
    regsub {^0+} $num "" x
    # convert to binary
    set num ""
    while {$x} {
      set num [expr $x & 1]$num
      set x [expr $x >> 1]
    }
  } elseif {[regexp -nocase {^([0-9]+)'h([0-9a-fxz]+)$} $num dy width num]} {
    # convert hex
    regsub -nocase -all 0 $num 0000 num
    regsub -nocase -all 1 $num 0001 num
    regsub -nocase -all 2 $num 0010 num
    regsub -nocase -all 3 $num 0011 num
    regsub -nocase -all 4 $num 0100 num
    regsub -nocase -all 5 $num 0101 num
    regsub -nocase -all 6 $num 0110 num
    regsub -nocase -all 7 $num 0111 num
    regsub -nocase -all 8 $num 1000 num
    regsub -nocase -all 9 $num 1001 num
    regsub -nocase -all a $num 1010 num
    regsub -nocase -all b $num 1011 num
    regsub -nocase -all c $num 1100 num
    regsub -nocase -all d $num 1101 num
    regsub -nocase -all e $num 1110 num
    regsub -nocase -all f $num 1111 num
    regsub -nocase -all x $num xxxx num
    regsub -nocase -all z $num zzzz num
  } else {
    # none of the above
    sue_error "NETLIST_ERROR: Unrecognized constant: $orig." $cur_s
    return ""
  }
  # remove leading 0's if they exceed the desired width
  while {[string length $num] > $width && [regexp {^0} $num]} {
    set num [string range $num 1 end]
  }
  # yell if too long
  if {[string length $num] > $width} {
    sue_error "NETLIST_ERROR: Constant exceeds width: $orig." $cur_s
    return ""
  }
  # pad if it's too short
  while {[string length $num] < $width} {
    if {[regexp -nocase {^x} $num]} {
      # x's extend
      set num x$num
    } elseif {[regexp -nocase {^z} $num]} {
      # z's extend
      set num z$num
    } else {
      # all else pads with 0
      set num 0$num
    }
  }

  if {$prefix} {
    # include the 4'b prefix
    return "$width'b$num"
  } else {
    return $num
  }
}


# if it is a file, move it.  If it is a link, copy the actual
# file at the end of the link

proc move_file_or_copy {fromfile tofile} {

  if {[catch "file readlink $fromfile"]} {
    # not a link (might not exist also)

    if {[file exists $fromfile]} {
      # move this baby
      if {![catch "file rename -force -- $fromfile $tofile"]} {
	puts "Moved file \"$fromfile\" to \"$tofile\"."
      }
    }

  } else {
    # this is a link, get root
    while {![catch "file readlink $fromfile" msg]} {
      set fromfile $msg
    }

    # copy this baby
    if {![catch "file copy -force -- $fromfile $tofile"]} {
      puts "Copied file \"$fromfile\" to \"$tofile\"."
    }
  }
}


# returns the directory associated with the cell type

proc find_dir_of_cell {cell} {

  global SUE auto_index

  # if it's generated, use the generator name for getting the directory
  upvar #0 icon_$cell g_data
  set gen [use_first g_data(generator) cell]

  # get the directory of the file
  if {[info exists SUE($gen)]} {
    # use the directory from the schematic canvas
    global SUE_$gen
    set dir [string trimright [set SUE_${gen}(dir)] /]

  } elseif {[info exists SUE(ICON_$gen)]} {
    # use the directory from the icon canvas
    global SUE_ICON_$gen
    set dir [string trimright [set SUE_ICON_${gen}(dir)] /]

  } else {
    # get out of the auto_index
    set path [lindex [use_first auto_index(ICON_$gen)] 1]
    set dir [file dirname $path]
  }

  return $dir
}


proc goto_new_schematic {cell_name {dir ""}} -desc {
  create a new schematic called "cell_name".  If it already exists,
  replace it.
} {

  global SUE auto_index cur_s cur_c

  if {![info exists SUE($cell_name)]} {
    # otherwise we will load this when we do goto_schematic
    catch {rename SCHEMATIC_$cell_name ""}
    catch {unset auto_index(SCHEMATIC_$cell_name)}
  }
  goto_schematic $cell_name

  if {$cur_s == $cell_name} {
    # schematic already exists, just erase everything in it
    foreach id [$cur_c find withtag origin] {
      # delete old icon and lose the old data structure
      $cur_c delete inst$id
      global ${cur_s}_inst$id
      catch {unset ${cur_s}_inst$id}
    }
     
    # delete anything else that might be around
    $cur_c delete all

    global SUE_$cell_name GRID_SPACING
    if {[use_first SUE_${cell_name}(grid)] == 1} {
      # grid was on before, turn it on again
      make_grid $GRID_SPACING
    }

    # set up the TERMS array with names of instances
    upvar #0 TERMS_$cur_s TERMS
    catch {unset TERMS}

    scale_canvas 10

    puts "Using cell $cell_name."

  } else {
    # make a new schematic
    if {$dir == "" || $dir == "."} {
      set dir [pwd]
    }
    # make sure it has a trailing /
    set dir [string trimright $dir /]/

    make_new_schematic $dir$cell_name
    puts "Created new cell $cell_name."
  }
}


# for the floorplanner (fp)

proc is_fp {cell} -desc {
  Returns 1 if given cell is a fp file.
} {

  # fps have are of the form <cell>_fp
  if {[regexp _fp$ $cell]} {
    # yes
    return 1
  } else {
    # no
    return 0
  }
}


# Force this to autoload so it is in text commands.

catch {prop_menu}

