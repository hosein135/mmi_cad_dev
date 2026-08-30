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


# Routines to write (really create) an icon procedure from a cell.


# Top level routine to create an icon procedure that can either be written
# out to a file or executed.

proc write_icon {{return ""}} {

  global cur_c cur_s scale PROC

  set PROC ""

  # delete any dot's, open's, or tmp's
  $cur_c delete dot
  $cur_c delete open
  $cur_c delete tmp

  # Scale everything to 10 for saving
  set old_scale $scale
  scale_canvas 10

  # Move so that origin is at 0,0
  set offset [get_origin_offset]
  $cur_c move all [expr -1.0*[lindex $offset 0]] [expr -1.0*[lindex $offset 1]]
  
  ###### Write instances and terminals
  icon_write_terminals

  ###### Write wires, lines, arcs, text
  icon_write_all_but_instances

  ###### Write icon_setup line
  set setup "  icon_setup \$args [list [icon_default]]"

  if {$return == ""} {
    # define the icon procedure
    proc $cur_s {args} [join "[list $setup] $PROC" "\n"]

    # unset the global variable that held the body of the icon
    unset PROC
  } else {
    set PROC [join "[list $setup] $PROC" "\n"]
  }

  # move the icon back (otherwise we have to move the scrollbars, etc.)
  eval $cur_c move all $offset

  scale_canvas $old_scale
}


# This section deals with writing icon terminals (aka IOs)
# we only allow instances of terminals in icons and title_bars?????

proc icon_write_terminals {} {

  global cur_c cur_s PROC

  # Loop through all instances in the canvas
  foreach id [$cur_c find withtag origin] {
    if {[is_tagged $id icon_input] || [is_tagged $id icon_output] || \
	    [is_tagged $id icon_inout]} {
      # good, it's a terminal 
      set proc_call icon_term
    } elseif {[is_tagged $id *_title_bar]} {
      # allow title bars in icons
      set proc_call icon_special
    } else {
      # not a terminal, waste it.
      set tags [$cur_c gettags $id]
      set deadmeat [string range [lindex $tags \
				      [lsearch -regexp $tags icon_]] 5 end]
      puts "Warning: Removed instance \"$deadmeat\" from icon [get_rootname $cur_s]."

      $cur_c delete inst$id
      global ${cur_s}_inst$id
      unset ${cur_s}_inst$id

      continue
    }

    # set up data structures to get icon data

    # instance-specific data (like W=1.2u) are here
    upvar #0 ${cur_s}_inst$id i_data

    set type $i_data(type)

    # instance-generic data (like default L=0.6u) are here
    upvar #0 icon_$type g_data
    
    # Make origin argument
    set origin [round_list [lrange [$cur_c coords $id] 0 1]]
    set creator "$proc_call -type $type -origin [list $origin]"

    if {$i_data(orient) != "R0"} {
      # Non default value, so print it out
      lappend creator "-orient" $i_data(orient)
    }

    # motor through the properties
    foreach name $g_data(prop_names) {
      if {$i_data(_$name) != $g_data(_$name,default)} {
	# Non default value, so print it out
	lappend creator "-$name" $i_data(_$name)
      }
    }

    # special case of editing a primitive terminal
    set tags [$cur_c gettags $id]
    set priority [lindex $tags [lsearch $tags "priority_*"]]

    if {$priority != ""} {
      # got one
      lappend creator -priority \
	  [string range $priority [expr [string first _ $priority] + 1] end]
    }

    lappend PROC "  $creator"
  }

  return
}


# Note that wires simply become lines.

proc icon_write_all_but_instances {} {

  global cur_c cur_s PROC ROTATE_TEXT

  # first, turn wires into lines
  foreach id [$cur_c find withtag wire] {
    lappend PROC "  icon_line [round_list [$cur_c coords $id]]"
  }

  # walk through all draw_items in the canvas
  foreach id [$cur_c find withtag draw_item] {
    switch [$cur_c type $id] {

      "line" {
	if {[is_tagged $id origin_icon]} {
	  # ignore the origin +
	  continue
	}

	lappend PROC "  icon_line [round_list [$cur_c coords $id]]"
      }

      "text" {
	set this_text [string trim [$cur_c itemcget $id -text]]
	set origin [list [round_list [$cur_c coords $id]]]

	if {$ROTATE_TEXT && [$cur_c itemcget $id -rotate] == 1} {
	  set rotate " -rotate 1"
	} else {
	  set rotate ""
	}

	# see if there are any options
	if {[string index $this_text 0] == "-"} {
	  # a bona fide property
	  # if it's an auto property, call the procedure to automatically
	  # regenerate it
	  if {![catch {call_keyword -consume $this_text \
			   {{type text} {name ""} {label ""} \
				{text ""} {default ""} {choices ""}}} msg]} {
	    # successful
	    if {$type == "auto"} {
	      if {![catch {auto_$name $id} msg]} {
		# successful
		set id $msg
		set this_text [string trim [$cur_c itemcget $id -text]]
	      }
	    }
	  } else {
            puts "WARNING: Ignoring property: $msg."
	    continue
	  }

	  if {$type != "text" || $text != ""} {
	    lappend PROC "  icon_property -origin $origin[text_size $id][text_anchor $id]$rotate $this_text"
	    continue
	  }
	}

	# just a piece of text
	set line "icon_property -origin $origin[text_size $id][text_anchor $id]$rotate -label"
	lappend line $this_text
	lappend PROC "  $line"
      }

      "arc" {
	set extent [expr round([$cur_c itemcget $id -extent])]
	set start [expr round([$cur_c itemcget $id -start])]
	lappend PROC "  icon_arc [round_list [$cur_c coords $id]] -start $start -extent $extent"
      }
      default {
	# should never happen
      }
    }
  }
}


# gets the list of arguments and default values of icon

proc icon_default {} {

  global PROC

  set default_list {{origin {0 0}} {orient R0}}
  foreach line $PROC {
    if {[lindex $line 0] == "icon_property"} {
      if {[catch {call_keyword $line \
		      {{type text} {name ""} {default ""}}}]} {
	# we got a problem.  Bad syntax in property
	puts "ERROR: Bad syntax in icon property: $line"
	puts $msg
	continue
      }

      if {$type == "user"} {
	lappend default_list [list $name $default]
      }
    }
  }

  return $default_list
}


proc get_origin_offset {} {

  global cur_c cur_s

  # doesn't break on multiple origins (should be only one)
  set id [lindex [$cur_c find withtag origin_icon] 0]

  if {$id == ""} {
    # oops, no origin
    return "0 0"
  }

  return [round_list [lrange [$cur_c coords $id] 0 1]]
}
