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


# Create an edif description of a SUE schematic and descendents

# TODO add a setup menu


proc edif_write {} {
  
  global EDIF SUE2EDIF_VERSION SUFFIX
  global portrefs_by_bitno

  puts "\nStarting SUE to EDIF translator, Version $SUE2EDIF_VERSION."

  # license check
  edif_setup

  catch {unset EDIF}

  # for interrupting
  set EDIF(interrupt) 0

  # debug switch... do all cells, or just the current one
  #	set EDIF(one_only) "only_one"
  set EDIF(one_only) "do_the_many"
  
  set EDIF(cells_written) ""
  set EDIF(save_cell) ""

  set cell [api_current_cell]
  
  set filename "[file dirname [get_assoc filename [api_cell_info $cell]]]/$cell$SUFFIX(edif)"
  puts "Creating edif file \"$filename\" ..."

  set EDIF(FID) ""
  if {[catch {open $filename w} EDIF(FID)] != 0} {
    warning "Aborting, can't write file \"$filename\"."
    return 0
  }
  
  # header type boilerplate
  puts $EDIF(FID) "(edif SUE_EDIF_$cell"
  puts $EDIF(FID) "  (edifVersion 2 0 0) (edifLevel 0)"
  puts $EDIF(FID) "  (keywordMap (keywordLevel 0))"
  puts $EDIF(FID) "  (library $cell"
  puts $EDIF(FID) "    (edifLevel 0)"
  puts $EDIF(FID) "    (technology"
  puts $EDIF(FID) "      (numberDefinition)"
  puts $EDIF(FID) "      (figureGroup device (visible (true)))"
  puts $EDIF(FID) "      (figureGroup wire (visible (true)))"
  puts $EDIF(FID) "      (figureGroup pin (visible (true)))"
  puts $EDIF(FID) "      (figureGroup annotate (visible (true)))"
  puts $EDIF(FID) "    )"
  # ... scales for coordinate grids, etc			
  
  # we want to write out the complete tree for the current cell,
  # starting with the leaves.  So decend recursively through
  # contained instances, until we find a cell that contains
  # only basic cells amd cells previously written.
  
  _edif_find_and_write_subcells $cell
  
  # & we're done! recursion makes everything so simple!
  # .... except tcl doesn't *do* recursion. But we can fake it.
  
  puts $EDIF(FID) "  )"	
  # ...library expr
  
  puts $EDIF(FID) ")"	
  # ...edif expr
  
  flush $EDIF(FID)
  close $EDIF(FID)

  puts "done."
}


proc _edif_find_and_write_subcells {{type ""}} {

  global EDIF
  global port_by_net
  
  # look for control-c
  if {[mmi_interrupt]} {
    puts "Interrupt, aborting edif writing."
    set EDIF(interrupt) 1
  }

  if {$EDIF(interrupt)} {
    return
  }

  # save
  set EDIF(save_cell) "[api_current_cell] $EDIF(save_cell)"
  api_goto_cell $type
  
  # look at all the icon-instances within the arg cell,
  # distinguishing ports and others 
  # for each non-port, if the instance 
  # has not already been processed, process it.
  set instances [api_instances]
  foreach instance $instances {
    set instance_data [api_get_data $instance]
    set instance_type [get_assoc type $instance_data]
    if {$instance_type == $type} continue	
    
    # if {[get_assoc generator $instance_data] == 1} continue
    switch $instance_type {
      "input"		continue
      "output"	continue
      "inout"		continue
      "title_bar"	continue
      ""		continue
      default	{
	if {[lsearch $EDIF(cells_written) $instance_type] == -1} {
	  lappend EDIF(cells_written) $instance_type
	  if {$EDIF(one_only) != "only_one"} {
	    _edif_find_and_write_subcells $instance_type

	    if {$EDIF(interrupt)} {
	      return
	    }
	  }
	}
      }
    }
  }
  
  # now that the environment is complete for this cell, process it
  _edif_write_cell $type
  
  # restore
  api_goto_cell [lindex $EDIF(save_cell) 0]
  set EDIF(save_cell) [lrange $EDIF(save_cell) 1 end]

}


proc _edif_write_cell {{type ""}} {
  
  global EDIF
  global thingno
  global edif_instances
  global view_properties
  global port_instances
  global non_port_instances

  set thingno 1

  set edif_instances ""
  set view_properties ""
  
  if {$type != [api_current_cell]} {
    puts "  Writing cell $type (icon only) ..."
    set is_icon_only true
  } else {
    puts "  Writing cell $type ..."
    set is_icon_only false
  }

  puts $EDIF(FID) "    (cell $type (cellType GENERIC)"
  puts $EDIF(FID) "      (view symbol (viewType SCHEMATIC)"
  puts $EDIF(FID) "        (interface"
  
  # ports
puts ""
puts "type $type"

  set instances [api_instances]
puts "instance $instances"

  set non_port_instances ""
  set port_instances ""
  set didthat ""
  foreach instance $instances {
    set instance_data [api_get_data $instance]

puts "... instance $instance data $instance_data"

    set instance_type [get_assoc type $instance_data]
    set instance_name [get_assoc _name $instance_data]
    set direction ""
    
    switch $instance_type {
      input	{set direction INPUT}
      output	{set direction OUTPUT}
      inout	{set direction INOUT}
      title_bar continue
      default	{
	lappend non_port_instances $instance
	continue
      }
    }
    lappend port_instances $instance
    
    if {[lsearch $didthat $instance_name] != -1} continue
    lappend didthat $instance_name
    
    set edif_info [_edif_info_by_id $instance]
    set edif_name [get_assoc edif_name $edif_info]
    set rename [get_assoc rename $edif_info]
    set is_array [get_assoc is_array $edif_info]
    
    # special case for globals
    if {$rename == "\$name"} {
      set rename "DOLLAR_NAME"
    }
    
    if {$is_array == "no"} {
      puts $EDIF(FID) "          (port $rename"
      
    } else {
      set from [get_assoc from $edif_info]
      set to [get_assoc to $edif_info]
      set array_size [get_assoc array_size $edif_info]
      puts $EDIF(FID) "          (port (array $rename $array_size)"
    }
    
    puts $EDIF(FID) "            (direction $direction)"
    puts $EDIF(FID) "          )"; 
  }
  
  # want to be looking at ICON now...
  # ...if icon only, $type *is* the ICON_type...
  if {$is_icon_only == "false"} {
    api_goto_cell ICON_$type
  }
  
  if {[api_current_cell] == "ICON_${type}"} {
    
    puts $EDIF(FID) "          (symbol"
    
    # bounding box
    set bbox [api_bbox]
    set x1 [lindex $bbox 0]
    set y1 [expr - [lindex $bbox 1]]
    set x2 [lindex $bbox 2]
    set y2 [expr - [lindex $bbox 3]]
    puts $EDIF(FID) "            (boundingBox (rectangle (pt $x1 $y1) (pt $x2 $y2)))"
    
    # figures, also properties
    foreach item [api_types line] {
      _edif_process_line_item $item
    }
    foreach item [api_types arc] {
      _edif_process_arc_item $item
    }
    foreach item [api_types text] {
      _edif_process_text_item $item
      
    }
    
    # portimplementations 
    # ...this is not redundant, because now we are on the ICON side...
    set instances [api_instances]
    foreach instance $instances {
      set instance_data [api_get_data $instance]
      set instance_type [get_assoc type $instance_data]
      
      # if {[get_assoc generator $instance_data] == 1} continue
      switch $instance_type {
	input	{ }
	output	{ }
	inout	{ }
	default	continue
      }
      
      set edif_info [_edif_info_by_id $instance]
      set edif_name [get_assoc edif_name $edif_info]
      
      # special case for globals
      if {$edif_name == "\$name"} {
	set edif_name "DOLLAR_NAME"
      }
      
      set origin [get_assoc origin $instance_data]
      set x1 [lindex $origin 0]
      set y1 [expr - [lindex $origin 1]]
      
      set orient_str ""
      set sue_orient [get_assoc orient $instance_data]
      if {$sue_orient != "R0"} {
	switch $sue_orient {
	  R0	{set edif_orient R0}
	  R90	{set edif_orient R270}
	  RXY	{set edif_orient R180}
	  R270	{set edif_orient R90}
	  RY	{set edif_orient MX}
	  RX	{set edif_orient MY}
	  R90X	{set edif_orient MXR90}
	  R90Y	{set edif_orient MYR90}
	  default {set edif_orient "??unknown??"}
	}
	set orient_str " (userData orientation $edif_orient) "
      }		
      
      
      puts $EDIF(FID) "            (portImplementation $edif_name (connectLocation (figure pin (dot (pt $x1 $y1)))) $orient_str )"
    }		
    
    puts $EDIF(FID) "          )"
    # ...symbol
    
    # enough with the ICON
    if {$is_icon_only == "true"} {
#      puts "icon only"
      
      puts $EDIF(FID) "        )"
      # ...interface

      if {$view_properties != ""} {
        puts $EDIF(FID) $view_properties
      }
  
      puts $EDIF(FID) "      )"
      # ...view
      puts $EDIF(FID) "    )"
      # ...cell
      return
    }
  }
  
  puts $EDIF(FID) "        )"
  # ...interface
  
  if {$view_properties != ""} {
    puts $EDIF(FID) $view_properties
  }
  
  api_goto_cell $type
  api_generate_term_names
  
  # properties
  
  puts $EDIF(FID) "        (contents"
  puts $EDIF(FID) "          (page PAGE1"
  
  # portimplementations
  set instances [api_instances]
  foreach instance $port_instances {
    _edif_process_schematic_port $instance
  }
  
  # instances
  foreach instance $non_port_instances { 
    _edif_process_instance $instance 
  }
  
  # nets
  _edif_process_nets
  
  # figures, chunks of text....
  foreach item [api_types text] {
    _edif_process_text_item $item
  }
  
  
  puts $EDIF(FID) "          )"
  # ...page
  
  puts $EDIF(FID) "        )"
  # ...contents
  
  puts $EDIF(FID) "      )"
  # ...view
  
  puts $EDIF(FID) "    )"
  # ...cell
  return
  
}


proc _edif_process_line_item {{item ""}} {

  global EDIF

  set draw_item_data [api_get_data $item]
  set draw_item_type [get_assoc type $draw_item_data]
  
  set xylist [round_list [get_assoc coords $draw_item_data]]
  set out "            (figure device (path (pointList "
  while {[lindex $xylist 0] != ""} {
    set x1 [lindex $xylist 0]
    set y1 [expr - [lindex $xylist 1]]
    append out "(pt $x1 $y1) "
    set xylist [lrange $xylist 2 end]
  }
  append out ")))"
  puts $EDIF(FID) "$out"
}


proc _edif_process_arc_item {{item ""}} {

  global EDIF

  set draw_item_data [api_get_data $item]
  set draw_item_type [get_assoc type $draw_item_data]
  
  # The tk way of giving an arc is give opposing corners of the 
  # bounding box of the complete elipse from which this arc is 
  # taken (the "coords"), the starting angle (the most clockwise
  # end) in degrees counterclockwise from the x-axis, and the
  # angular size of the arc in degrees; angles taken from the
  # "center" of the elipse, == the center of the bounding box.
  #
  # The edif way, au l'autre main, is to give the coordinates of
  # the two end plus any other point you like on the arc.  
  #
  # That understood, the following geometric transform is 
  # straightforward if you remember that the c math library
  # does trig functions in radians, and you're good with
  # geometric algebra....thanks to http://mathworld.wolfram.com... 
  
  set arccoords [get_assoc bbox $draw_item_data]
  set arcstart [get_assoc start $draw_item_data]
  set arcextent [get_assoc extent $draw_item_data]
  set x1 [lindex $arccoords 0]
  set y1 [expr - [lindex $arccoords 1]]
  set x2 [lindex $arccoords 2]
  set y2 [expr - [lindex $arccoords 3]]
  set centery [expr ($y1 + $y2) / 2]
  
  if {$arcextent == 359} {
    puts $EDIF(FID) "            (figure device (circle (pt $x1 $centery) (pt $x2 $centery)))"
    return
  }
  
  set pi 3.14159
  set startrad [expr ($pi * $arcstart) / 180.0]
  set extentrad [expr ($pi * $arcextent) / 180.0]
  set endrad [expr $startrad + $extentrad]
  set midrad [expr ($startrad + $endrad) / 2]
  set centerx [expr ($x1 + $x2) / 2]
  
  set a [expr abs(($x1 - $x2) / 2)]
  set b [expr abs(($y1 - $y2) / 2)]
  set absq [expr ($a * $b) * ($a * $b)]
  
  set bcossq [expr ($b * cos($startrad)) * ($b * cos($startrad))]
  set asinsq [expr ($a * sin($startrad)) * ($a * sin($startrad))]
  set r [expr sqrt( $absq / ($bcossq + $asinsq))]
  set end1x [round_list [expr $r * cos($startrad) + $centerx]]
  set end1y [round_list [expr $r * sin($startrad) + $centery]]
  
  set bcossq [expr ($b * cos($endrad)) * ($b * cos($endrad))]
  set asinsq [expr ($a * sin($endrad)) * ($a * sin($endrad))]
  set r [expr sqrt( $absq / ($bcossq + $asinsq))]
  set end2x [round_list [expr $r * cos($endrad) + $centerx]]
  set end2y [round_list [expr $r * sin($endrad) + $centery]]
  
  set bcossq [expr ($b * cos($midrad)) * ($b * cos($midrad))]
  set asinsq [expr ($a * sin($midrad)) * ($a * sin($midrad))]
  set r [expr sqrt( $absq / ($bcossq + $asinsq))]
  set midx [round_list [expr $r * cos($midrad) + $centerx]]
  set midy [round_list [expr $r * sin($midrad) + $centery]]
  
  puts $EDIF(FID) "            (figure device (openshape (curve (arc"
  puts $EDIF(FID) "              (pt $end1x $end1y) (pt $midx $midy) (pt $end2x $end2y)))))"
  
}


proc _edif_process_text_item {{item ""}} {

  global EDIF FONT
  global view_properties
  
  set draw_item_data [api_get_data $item]
  
  set draw_item_type [get_assoc type $draw_item_data]
  set text [string trim [get_assoc text $draw_item_data]]
  set origin [get_assoc origin $draw_item_data]
  
  if {[get_assoc rotate $draw_item_data] == 1} {
    set rotate "(orientation R90)"
  } else {
    set rotate "(orientation R0)"
  }
  # see if there are any options
  set done "false"
  set name ""
  if {[string index $text 0] == "-"} {
    set arg_default "{}"
    set arg_type ""
    while {$text != ""} {
      set arg [lindex $text 0]
      set value [lindex $text 1]
      switch -- $arg {
	-type	{set arg_type $value}
	-name	{set name $value}
	-default	{set arg_default $value}
	-text	break
	default	{
	  puts "unknown property arg text <$text> arg <$arg>"
	  return
	}
      }
      set text [lrange $text 2 end]
    }
    
    if {$arg_type == "fixed" && $name != "primitive"}  {
      # convert quotes to %34%
      regsub -all \" $text %34% text

      set property "        (property $name (string \"-type fixed -name $name $text\"))"
      if {$view_properties == ""} {
	set view_properties $property
      } else {
	set view_properties ${view_properties}\n${property}
      }
      set done "true"
    } 

    if {$arg_type == "user" && $name != "" && $name != "name"} {
      set property "        (property $name (string \"$arg_default\"))"
      if {$view_properties == ""} {
	set view_properties $property
      } else {
	set view_properties ${view_properties}\n${property}
      }
      set done "true"
    } 

  }
  
  if {$done != "true" && $name != "name"} {
    # just chunk of text	 
    set anchor [api_get_data $item anchor]

    set justify ""
    switch -- $anchor {
      w	{ set justify "(justify CENTERLEFT)" }
      e	{ set justify "(justify CENTERRIGHT)" }
      c - center	{ set justify "(justify CENTERCENTER)" }
      default	{
#	puts $EDIF(FID) "Warning: Unknown anchor type <$anchor>, using center."
	puts "Warning: Unknown anchor type <$anchor>, using center."
	set justify "(justify CENTERCENTER)"
      }
    }
    set size [api_get_data $item size]
    set textheight ""

    # font ratio of small to standard and large to standard size fonts
    #set FONT(very-small) 0.3
    #set FONT(small) 0.6
    #set FONT(standard) 1.0
    #set FONT(large) 1.5
    #set FONT(very-large) 3.0

    if {[info exists FONT($size)]} {
      if {$FONT($size) != 1.0} {
	set textheight "(textHeight [expr int(10 * $FONT($size))])"
      }

    } else {
#      puts $EDIF(FID) "Warning: Unknown size <$size>, using standard."
      puts "Warning: Unknown size <$size>, using standard."
    }

    if {$textheight == ""} {
      set figuregroup "annotate"
    } else {
      set figuregroup "(figureGroupOverride annotate $textheight)"
    }
    
    # convert quotes to %34%
    regsub -all \" $text %34% text
    if {[string range $text 0 4] == "-text"} {
      set text [string range $text 5 end]
      puts $EDIF(FID) "            (property comment (string \"${text}\"))"
      return
    }
    
    puts $EDIF(FID) "            (commentGraphics (annotate"
    puts $EDIF(FID) "              (stringDisplay \"${text}\""
    set x1 [lindex $origin 0]
    set y1 [expr - [lindex $origin 1]]
    puts $EDIF(FID) "                (display $figuregroup $justify $rotate (origin (pt $x1 $y1))))))"
  }
}


proc _edif_process_instance {{instance ""}} {

  global EDIF
  
  set instance_data [api_get_data $instance]
  set type [get_assoc type $instance_data]
  
  set origin_coords "[get_assoc origin $instance_data]"
  set x1 [lindex $origin_coords 0]
  set y1 [expr - [lindex $origin_coords 1]]
  
  set edif_info [_edif_info_by_id $instance]
  set edif_name [get_assoc edif_name $edif_info]
  set is_array [get_assoc is_array $edif_info]
  set rename [get_assoc rename $edif_info]
  
  if {$type == "name_net" || $type == "name_net_s"} {
    # I don't care if it *looks* like an array, it isn't one.
    puts $EDIF(FID) "            (instance $rename"
    puts $EDIF(FID) "              (viewRef symbol (cellRef $type))"
    puts $EDIF(FID) "              (transform (origin (pt $x1 $y1)))"
    puts $EDIF(FID) "            )"
    return
  }		
  
  if {$is_array == "no"} {
    puts $EDIF(FID) "            (instance $rename"
    
  } else {
    set from [get_assoc from $edif_info]
    set to [get_assoc to $edif_info]
    set array_size [get_assoc array_size $edif_info]
    
    if {$array_size == 1} {
      puts $EDIF(FID) "            (instance $rename"
    } else {	
      puts $EDIF(FID) "            (instance (array $rename $array_size)"
    }
  }
  
  puts $EDIF(FID) "              (viewRef symbol (cellRef $type))"
  
  set sue_orient [get_assoc orient $instance_data]
  switch $sue_orient {
    R0	{set edif_orient R0}
    R90	{set edif_orient R270}
    RXY	{set edif_orient R180}
    R270	{set edif_orient R90}
    RY	{set edif_orient MX}
    RX	{set edif_orient MY}
    R90X	{set edif_orient MXR90}
    R90Y	{set edif_orient MYR90}
    default {set edif_orient "??unknown??"}
  }		
  
  puts $EDIF(FID) "              (transform (orientation $edif_orient) (origin (pt $x1 $y1)))"
  
  
  set default_data [get_assoc defaults [api_instance_type_data $type]]
  foreach prop $instance_data {
    set prop_name [lindex $prop 0]
    if {[string range $prop_name 0 0] == "_"} {
      if {$prop_name == "_name"} continue
      set prop_name [string range $prop_name 1 end]
      set prop_actual [lindex $prop 1]
      set prop_default [get_assoc $prop_name $default_data]
      if {$prop_actual != $prop_default} {
	puts $EDIF(FID) "              (property $prop_name (string \"\$${prop_actual}\"))"
      }
    }
  }
  
  puts $EDIF(FID) "            )"
}


proc _edif_process_nets {} {

  global EDIF
  global non_port_instances
  global ports_by_net
  global compound_net_names
  global wires_by_base_name

  set net_names ""
  set net_names_by_base_name ""
  set compound_net_names ""
  
  # sort the ports of all instances into nets
  # ... first clear the buckets....a
  foreach id [api_types wire] {
    set data [api_get_data $id]
    set net [get_assoc net $data]
    set ports_by_net($net) ""
  }
  
  # now walk the instances & ports...
  foreach id [api_types instance] {
    # figure out the name of this instance
    set data [api_get_data $id]
    
    set type [get_assoc type $data]
    if {$type == "name_net_s"}	continue;
    if {$type == "name_net"}	continue;    

    set name [get_assoc _name $data]
    
    # get all of the ports on this instance
    foreach port_list [api_terminal_data $type] {

      set port [lindex $port_list 0]
      set net_name [api_netlist_data $id $port]

      if {$net_name == 0} {
	# didn't find a named net.... 
	# probably the port name is "$name", like for portimplementations or name_nets...need to lookup
	regsub -all {\{|\}|\$} $port "" port
	set port [get_assoc _$port $data]
	set net_name [api_netlist_data $id $port]
	if {$net_name == 0} {
	  # well, what IS going on???
	  puts "WARNING: can figure net out port $port of type $type"
	  continue
	}
      }
      
      if {[string first "," $net_name] == -1} {
	# ... simple name (one base name)
        set edif_info [_edif_info_by_name $net_name]
        set match_name [get_assoc match $edif_info]
        lappend ports_by_net($match_name) [list $id $port 0 0]
      
        # remember what are the net names
        if {[lsearch $net_names $match_name] == -1} {
  	  lappend net_names $match_name
  	  set base_name [get_assoc base_name $edif_info]
	  lappend net_names_by_base_name [list $base_name $match_name $net_name]
        }

      } else {

	# ... compound name (list of base names, like {a[1:0],b}
	lappend compound_net_names $net_name
	set compound_net_name $net_name

	set comma_index [string first "," $net_name]
	set starting_index 0
	while {$comma_index != -1} {
	  set net_name_chunk [string range $net_name 0 [expr $comma_index - 1]]
	  set net_name [string range $net_name [expr $comma_index + 1] end]
          set edif_info [_edif_info_by_name $net_name_chunk]
          set match_name [get_assoc match $edif_info]
          lappend ports_by_net($match_name) [list $id $port $compound_net_name $starting_index]
	  set starting_index [expr $starting_index + [get_assoc array_size $edif_info]]

          # remember what are the net names
          if {[lsearch $net_names $match_name] == -1} {
  	    lappend net_names $match_name
  	    set base_name [get_assoc base_name $edif_info]
	    lappend net_names_by_base_name [list $base_name $match_name $net_name_chunk]
          }

 	  set comma_index [string first "," $net_name]
	}

	# ... last chunk
        set edif_info [_edif_info_by_name $net_name]
        set match_name [get_assoc match $edif_info]
        lappend ports_by_net($match_name) [list $id $port $compound_net_name $starting_index]
	set starting_index [expr $starting_index + [get_assoc array_size $edif_info]]

        if {[lsearch $net_names $match_name] == -1} {
  	  lappend net_names $match_name
  	  set base_name [get_assoc base_name $edif_info]
	  lappend net_names_by_base_name [list $base_name $match_name $net_name]
        }
      }
    }
  }

  # ...and while we're at it, sort wires over nets
  foreach id [api_types wire] {
    set data [api_get_data $id]
    set net [get_assoc net $data]
    set edif_info [_edif_info_by_id $id]
    set base_name [get_assoc base_name $edif_info]
    lappend wires_by_base_name($base_name) $id
  }
  
  # .....NOW THEN.....
  # if there are bus dividers about, there will be more than one net with some given net name...
  # in that case we must do something complicated.  So first we sort out the simple case,
  # where all bits in the net go to whatever set of instances.  (There may be multiple 
  # wire segments.)
  
  set net_names_by_base_name [lsort $net_names_by_base_name]
  while {$net_names_by_base_name != ""} { 

    set first_net [lindex $net_names_by_base_name 0]
    set net_names_by_base_name [lrange $net_names_by_base_name 1 end]
    
    # ....first net will be [list $base_name $match_name $net]
    # ....base name is with subscripts removed; match name is with subscripts encoded for tcl; net is as it really was.

    if {[lindex $first_net 0] != [lindex [lindex $net_names_by_base_name 0] 0]} {

      # ... base name of next net is different; this is a simple case
      _edif_process_simple_net $first_net
      
    } else {
      
      # ... there is more than one net with this base name
      # ... sweep them all together & to the complicated thing
      
      set net_list [list $first_net]
      set net_name [lindex $first_net 0]
      while {$net_names_by_base_name != "" && $net_name == [lindex [lindex $net_names_by_base_name 0] 0]} {
	lappend net_list [lindex $net_names_by_base_name 0]
	set net_names_by_base_name [lrange $net_names_by_base_name 1 end]
      }
      _edif_process_split_net $net_list
      
    }
  }

  # and for compound nets, write out any wire segments
  foreach net_name $compound_net_names {
    set wires $wires_by_base_name($net_name)

    # make a net to carry graphical information
    puts $EDIF(FID) "            (net $net_name"
    # "joined" is required, but we have nothing to say...
    puts $EDIF(FID) "              (joined)"

    foreach wire $wires {
      set wire_info [api_get_data $wire]
      set wirepts [get_assoc coords $wire_info]
      while {$wirepts != ""} {
        set x1 [lindex $wirepts 0]
        set y1 [expr - [lindex $wirepts 1]]
        set x2 [lindex $wirepts 2]
      
        set y2 [expr - [lindex $wirepts 3]]
        puts $EDIF(FID) "              (figure wire (path (pointList (pt $x1 $y1) (pt $x2 $y2))))"
        set wirepts [lrange wirepts 4 end]
      }
    }
    puts $EDIF(FID) "            )"
  }
}


proc _edif_process_simple_net {{net_descriptor ""}} {

  global EDIF
  global edif_info_by_id
  global ports_by_net
  global port_instances
  
  set base_name [lindex $net_descriptor 0]
  set match_name [lindex $net_descriptor 1]
  set net_name [lindex $net_descriptor 2]
  
  # don't bother with unconnected nets
  if {[string range $net_name 0 5] == "uc_net"} return
  
  set ports $ports_by_net($match_name)
  foreach port $ports {
    set is_from_compound_net [lindex $port 2]
    if {$is_from_compound_net != 0} {
      _edif_process_split_net [list $net_descriptor]
      return
    }
  }
  
  set ports_by_net($match_name) ""
  
  set net_edif_info [_edif_info_by_name $net_name]
  set net_width [get_assoc array_size $net_edif_info]
  
  set net_rename [get_assoc rename $net_edif_info]
  puts $EDIF(FID) "            (net $net_rename"
  puts $EDIF(FID) "              (joined"

  foreach port $ports {
    
    set instance_id [lindex $port 0]
    
    set instance_edif_info $edif_info_by_id($instance_id)
    set instance_is_array [get_assoc is_array $instance_edif_info]
    
    if {[lsearch $port_instances $instance_id] == -1} {set is_portimp "no"} else {set is_portimp "yes"}	
    
    set port_sue_name [lindex $port 1]
    set port_edif_info [_edif_info_by_name $port_sue_name $is_portimp]
    set port_is_array [get_assoc is_array $port_edif_info]
    set port_name [get_assoc edif_name $port_edif_info]
    
    if {$instance_is_array == "yes"} {set instance_width [get_assoc array_size $instance_edif_info]
    } else {set instance_width 1}
    
    if {$port_is_array == "yes"} {set port_width [get_assoc array_size $port_edif_info]
    } else {set port_width 1}
    
    set instance_type [get_assoc type [api_get_data $instance_id]]
    if { $instance_type == "name_net_s" || $instance_type == "name_net" || $instance_type == "flag"} {
      # 'pon reflection, I don't think it's right to show name_nets as "joined" to anything...same for flag...
      # set edif_name [get_assoc edif_name $net_edif_info]
      # puts $EDIF(FID) "                (portRef DOLLAR_NAME (instanceRef $edif_name))" 
      continue
    }
    
    set instance_name [get_assoc edif_name $instance_edif_info]
    
    if {$is_portimp == "yes"} {
      set outstr "                (portRef $instance_name)"
      # ...in the sue view, instance and port are redundant ($port_width == $net_width, &tc.)
      
      if {$net_width == $port_width} {
	puts $EDIF(FID) $outstr
	
      } elseif {$port_width == 1} then {
	
	puts $EDIF(FID) "                (portList"
	set i 0
	while {$i < $net_width} {
	  puts $EDIF(FID) "  $outstr"
	  set i [expr $i + 1]
	}
	puts $EDIF(FID) "                )"
	
      } else {
	puts $EDIF(FID)  "ERROR"	
	puts $EDIF(FID) "simple net portimplementation to net width matching problem"
	puts $EDIF(FID) "...net_width $net_width port_width $port_width"
	puts $EDIF(FID) "...port_name $port_name"
	puts ""
	puts "ERROR"	
	puts "simple net portimplementation to net width matching problem"
	puts "...net_width $net_width port_width $port_width"
	puts "...port_name $port_name instance_name"
	puts ""
      }
      
    } else { 
      # ...not a portimplementation; it's a port on an instance
      
      if {($net_width == $port_width && $instance_width == 1) ||		
	  ($net_width == $instance_width && $port_width == 1)} {
	
	puts $EDIF(FID) "                (portRef $port_name (instanceRef $instance_name))" 
	
      } elseif {$port_width == 1 && $instance_width == 1} then {
	
	# connect this single port to all net bits
	
	puts $EDIF(FID) "                (portList"
	set i 0
	while {$i < $net_width} {
	  puts $EDIF(FID) "                (portRef $port_name (instanceRef $instance_name))"
	  set i [expr $i + 1]
	}
	puts $EDIF(FID) "                )"
	
      } elseif {$net_width == 1} {
	
	# connect the net to all ports.... 3 cases...
	
	if {$port_width > 1 && $instance_width > 1} {
	  for {set i 0} {$i < $instance_width} {incr i} {
	    for {set j 0} {$j < $port_width} {incr j} {
	      puts $EDIF(FID) "                (portRef (member $port_name $j) (instanceRef (member $instance_name $i)))"
	    }
	  }
	  
	} elseif {$port_width == 1 && $instance_width > 1} {
	  for {set i 0} {$i < $instance_width} {incr i} {
	    puts $EDIF(FID) "                (portRef $port_name (instanceRef (member $instance_name $i)))"
	  }
	  
	} else { # ... {$port_width > 1 && $instance_width == 1} 
	  for {set j 0} {$j < $port_width} {incr j} {
	    puts $EDIF(FID) "                (portRef (member $port_name $j) (instanceRef $instance_name))"
	  }
	}
	
      } elseif {$port_width == $net_width && $instance_width > 1} {
	# connect the full-width net to each instance
	set i 0
	while {$i < $instance_width} {
	  puts $EDIF(FID) "                (portRef $port_name (instanceRef (member $instance_name $i)))"
	  set i [expr $i + 1]
	}
	
	# ... by symetry there ought to be a case where 
	# net_width == instance_width && port_width > 1,
	# but that doesn't actually make sense.
	
      } elseif {$net_width == [expr $port_width * $instance_width]} {
	# distribute the net's bits to the various instances
	puts $EDIF(FID) "                (portList"
	for {set i 0} {$i < $instance_width} {incr i} {
	  for {set j 0} {$j < $port_width} {incr j} {
	    puts $EDIF(FID) "                  (portRef (member $port_name $j) (instanceRef (member $instance_name $i)))"
	  }
	}
	puts $EDIF(FID) "                )"
	
      } else {
	
	puts $EDIF(FID)  "ERROR"	
	puts $EDIF(FID) "simple net instance/port to net width matching problem"
	puts $EDIF(FID) "...net_width $net_width port_width $port_width instance_width $instance_width"
	puts $EDIF(FID) "...port_name $port_name instance_name $instance_name"
	puts ""
	puts "ERROR"	
	puts "simple net instance/port to net width matching problem"
	puts "...net_width $net_width port_width $port_width instance_width $instance_width"
	puts "...port_name $port_name instance_name $instance_name"
	puts ""
	
      }
    }
  }
  # ....joined
  puts $EDIF(FID) "              )"
  
  # walk over the wires *again*, find the ones on this net, make a figure for each
  foreach id2 [api_types wire] {
    set data2 [api_get_data $id2]
    set net2 [get_assoc net $data2]
    if {$net2 != $net_name} continue
    set wirepts [get_assoc coords $data2]
    while {$wirepts != ""} {
      set x1 [lindex $wirepts 0]
      set y1 [expr - [lindex $wirepts 1]]
      set x2 [lindex $wirepts 2]
      
      set y2 [expr - [lindex $wirepts 3]]
      puts $EDIF(FID) "              (figure wire (path (pointList (pt $x1 $y1) (pt $x2 $y2))))"
      set wirepts [lrange wirepts 4 end]
    }
  }
  
  # ...net
  puts $EDIF(FID) "            )"
}


proc _edif_process_split_net {{net_list ""}} {

  global EDIF
  global edif_info_by_id
  global ports_by_net
  global port_instances
  global compound_net_names
  global wires_by_base_name
  
  set wire_figures ""

  # The situation is that a wide net ("bits[3:0]") has been 
  # passed through some name_net's to split out subnets
  # ("bits[2]", "bits[1:0]")
  # The Plan is to create 1 net that carries the full width
  # of the net & all the wire segments (the graphic information); 
  # and a separate net for each bit that carries the 
  # connectivity information ("joined")

  # the wide net might have been compound ("{bits[3:0],c[0],1`b0,clk}")
  # in which case the nets have been split apart, so we come in here
  # with individual nets ("bits", "c", ...)
  # there is boolean on port_by_net that tells whether this was
  # such a deal, and if so what bit position we should start with...
  
  set max_bitno -1
  set net_bitno 0
  set some_port_is_from_compound_net 0
  foreach net_descriptor $net_list {

    set base_name [lindex $net_descriptor 0]
    set match_name [lindex $net_descriptor 1]
    set net_name [lindex $net_descriptor 2]
    
    # don't bother with unconnected nets
    if {[string range $net_name 0 5] == "uc_net"} return
    
    set ports $ports_by_net($match_name)
    set ports_by_net($match_name) ""

    set net_edif_info [_edif_info_by_name $net_name]
    set net_width [get_assoc array_size $net_edif_info]
    set net_lsb [get_assoc from $net_edif_info]
    set net_msb [expr $net_lsb + $net_width - 1]
    if {$net_msb > $max_bitno} {
      for {set i [expr $max_bitno + 1]} {$i <= $net_msb} {incr i} {
	set portrefs_by_bitno($i) ""
      }	
      set max_bitno $net_msb
    }
    
    foreach port $ports {

      set instance_id [lindex $port 0]
      set instance_edif_info $edif_info_by_id($instance_id)
      set instance_is_array [get_assoc is_array $instance_edif_info]
     
      if {[lsearch $port_instances $instance_id] == -1} {set is_portimp "no"} else {set is_portimp "yes"}	
      
      set port_sue_name [lindex $port 1]
      set port_edif_info [_edif_info_by_name $port_sue_name]
      set port_is_array [get_assoc is_array $port_edif_info]
      set port_name [get_assoc edif_name $port_edif_info]

      set is_from_compound_net [lindex $port 2]
      if {$is_from_compound_net != 0} {
	set some_port_is_from_compound_net $is_from_compound_net
      }
      set port_starting_index [lindex $port 3]

      if {$instance_is_array == "yes"} {set instance_width [get_assoc array_size $instance_edif_info]
      } else {set instance_width 1}
      
      if {$port_is_array == "yes"} {set port_width [get_assoc array_size $port_edif_info]
      } else {set port_width 1}

      set instance_type [get_assoc type [api_get_data $instance_id]]
      
      if { $instance_type == "name_net_s" || $instance_type == "name_net" || $instance_type == "flag"} {
	# 'pon reflection, I don't think it's right to show name_nets as 
	# "joined" to anything...same for flag...
	# for {set i 0} {$i < $net_width} {incr i} {
	#   set net_edif_name [get_assoc edif_name $net_edif_info]
	#   set outstr "(portRef DOLLAR_NAME (instanceRef ${net_edif_name}))"
	#   set net_bitno [expr $net_lsb + $i]
	#   lappend portrefs_by_bitno($net_bitno) $outstr
	# }
	continue
      }

      if {$is_portimp == "yes"} {
	# ...in the sue view, instance and port are redundant 
	# ($port_width == $net_width, &tc.)

	if {$port_width == 1} {
	  set port_name [get_assoc edif_name $port_edif_info]
	  for {set i 0} {$i < $net_width} {incr i} {
	    set outstr "(portRef ${port_name})"
	    set net_bitno [expr $net_lsb + $i]
	    lappend portrefs_by_bitno($net_bitno) $outstr
	  }
	  
	} elseif {$port_width >= [expr $port_starting_index + $net_width]} {
	  set port_lsb [expr [get_assoc from $port_edif_info] + $port_starting_index]
	  for {set i 0} {$i < $net_width} {incr i} {
	    set port_bitno [expr $port_lsb + $i]
	    set outstr "(portRef (member $port_name ${port_bitno}))"
	    set net_bitno [expr $net_lsb + $i]
	    lappend portrefs_by_bitno($net_bitno) $outstr
	  }
	  
	} else {
	  puts $EDIF(FID)  "ERROR"	
	  puts $EDIF(FID) "split net portimplementation to net width matching problem"
	  puts $EDIF(FID) "...net_width $net_width port_width $port_width"
	  puts $EDIF(FID) "...port_name $port_name"
	  puts ""
	  puts "ERROR"	
	  puts "split net portimplementation to net width matching problem"
	  puts "...net_width $net_width port_width $port_width"
	  puts "...port_name $port_name instance_name"
	  puts ""
	  
	}
	
      } else { 

	# ...not a portimplementation; it's a port on an instance
	set port_name [get_assoc edif_name $port_edif_info]
	set instance_name [get_assoc edif_name $instance_edif_info]

	if {$port_width == 1 && $instance_width == 1} {

	  set outstr "(portRef $port_name (instanceRef $instance_name))"
	  for {set i 0} {$i < $net_width} {incr i} {
	    set net_bitno [expr $net_lsb + $i]
	    lappend portrefs_by_bitno($net_bitno) $outstr
	  }
	  
	  
	} elseif {$net_width == 1		&&
	     $is_from_compound_net == 0	} {

	  # connect the net to all ports.... 3 cases...
	  set net_bitno $net_lsb
	  if {$net_bitno == ""}	{
	    set net_bitno 0
	  }
	  if {$port_width > 1 && $instance_width > 1} {
	    for {set i 0} {$i < $instance_width} {incr i} {
	      for {set j 0} {$j < $port_width} {incr j} {
		lappend portrefs_by_bitno($net_bitno) \
		    "(portRef (member $port_name $j) (instanceRef (member $instance_name $i)))"
	      }
	    }
	    
	  } elseif {$port_width == 1 && $instance_width > 1} {
	    for {set i 0} {$i < $instance_width} {incr i} {
	      lappend portrefs_by_bitno($net_bitno) "(portRef $port_name (instanceRef (member $instance_name $i)))"
	    }
	    
	  } else {	# ... $port_width > 1 && $instance_width == 1 
	    for {set j 0} {$j < $port_width} {incr j} {
	      lappend portrefs_by_bitno($net_bitno) "(portRef (member $port_name $j) (instanceRef $instance_name))"
	    }
	    
	  }
	  
	} elseif {$instance_width == 1	&&
	    [expr $net_width + $port_starting_index] <= $port_width} {

	  set port_lsb [expr [get_assoc from $port_edif_info] + $port_starting_index]
	  set port_bitno $port_lsb
	  for {set i 0} {$i < $net_width} {incr i} {
	    set outstr "(portRef (member ${port_name} $port_bitno) (instanceRef $instance_name))"
	    set net_bitno [expr $net_lsb + $i]
	    lappend portrefs_by_bitno($net_bitno) $outstr
	    incr port_bitno
	  }
	  
	  
	} elseif {$port_width == 1	&& 
	    [expr $net_width + $port_starting_index] <= $instance_width} {

	  set instance_lsb [expr [get_assoc from $instance_edif_info] + $port_starting_index]
	  for {set i 0} {$i < $net_width} {incr i} {
	    set instance_bitno [expr $instance_lsb + $i]
	    set outstr "(portRef  ${port_name} (instanceRef (member $instance_name $instance_bitno)))"
	    set net_bitno [expr $net_lsb + $i]
	    lappend portrefs_by_bitno($net_bitno) $outstr
	  }
	  
	} elseif {[expr $net_width + $port_starting_index] <= [expr $port_width * $instance_width]} {

	  set port_lsb [get_assoc from $port_edif_info]
	  set instance_lsb [get_assoc from $instance_edif_info]
	  # ...this is pretty kludgy...
	  set current_index -1	
	  set end_index [expr $net_width * $port_starting_index]
	  for {set i 0} {$i < $instance_width} {incr i} {
	    set instance_bitno [expr $instance_lsb + $i]
	    for {set j 0} {$j < $port_width} {incr j} {
	      incr current_index
	      if {$current_index >= $starting_index && $current_index < $end_index} { 
	        set port_bitno [expr $port_lsb + $j]
	        set outstr "(portRef  (member ${port_name} ${port_bitno}) (instanceRef (member $instance_name $instance_bitno)))"
	        set net_bitno [expr $net_lsb + $i * $port_width + $j]
	        lappend portrefs_by_bitno($net_bitno) $outstr
	      }
	    }
	  }
	  
	} else {
	  
	  puts $EDIF(FID)  "ERROR"	
	  puts $EDIF(FID) "split net instance/port to net width matching problem"
	  puts $EDIF(FID) "...net_width $net_width port_width $port_width instance_width $instance_width"
	  puts $EDIF(FID) "...port_name $port_name instance_name $instance_name"
	  puts ""
	  puts "ERROR  xxxxx2"	
	  puts "split net instance/port to net width matching problem"
	  puts "...net_width $net_width port_width $port_width instance_width $instance_width"
	  puts "...port_name $port_name instance_name $instance_name"
	  puts ""
	  
	}
      }
    }
    
    # find the wires for this net; remember them for later
    foreach id2 [api_types wire] {
      set data2 [api_get_data $id2]
      set net2 [get_assoc net $data2]
      if {$net2 != $net_name} continue
      
      if {$some_port_is_from_compound_net == 0} {
        # handle just below, attached to current net 
        set wirepts [get_assoc coords $data2]
        while {$wirepts != ""} {
          set x1 [lindex $wirepts 0]
          set y1 [expr - [lindex $wirepts 1]]
          set x2 [lindex $wirepts 2]
          set y2 [expr - [lindex $wirepts 3]]
          lappend wire_figures "(figure wire (path (pointList (pt $x1 $y1) (pt $x2 $y2))))"
          set wirepts [lrange wirepts 4 end]
        } 
      } else {
        # stick them with compound net
        lappend wires_by_base_name($some_port_is_from_compound_net) $id2
      }
    }
  }
  
  for {set bitno 0} {$bitno <= $max_bitno} {incr bitno} {
    if {$portrefs_by_bitno($bitno) == ""} continue
    
    set net_name [lindex $net_descriptor 0]__${bitno}
    puts $EDIF(FID) "            (net $net_name"
    puts $EDIF(FID) "              (joined"
    while {$portrefs_by_bitno($bitno) != ""} {
      puts $EDIF(FID) "                [lindex $portrefs_by_bitno($bitno) 0]"
      set portrefs_by_bitno($bitno) [lrange $portrefs_by_bitno($bitno) 1 end]
    }
    puts $EDIF(FID) "              )"
    puts $EDIF(FID) "            )"
  }
  
  # make a net to carry graphical information (use short_name)
  set net_name [lindex [lindex $net_list 0] 0]
  puts $EDIF(FID) "            (net $net_name"
  # "joined" is required, but we have nothing to say...
  puts $EDIF(FID) "              (joined)"
  while {$wire_figures != ""} {
    set figure [lindex $wire_figures 0]
    puts $EDIF(FID) "              $figure"
    set wire_figures [lrange $wire_figures 1 end]
  }
  puts $EDIF(FID) "            )"
}


proc _edif_process_schematic_port {{instance ""}} {

  global EDIF
  
  set edif_info [_edif_info_by_id $instance "yes"]
  
  set edif_name [get_assoc edif_name $edif_info]
  puts $EDIF(FID) "            (portImplementation $edif_name"
  
  set instance_data [api_get_data $instance]
  set origin [get_assoc origin $instance_data]
  set x1 [lindex $origin 0]
  set y1 [expr - [lindex $origin 1]]
  puts $EDIF(FID) "              (connectLocation (figure pin (dot (pt $x1 $y1))))"
  puts $EDIF(FID) "            )"
}


proc _edif_info_by_id {{id ""} {is_portimp "no"}} {

  global thingno
  global edif_info_by_id
  global EDIF
  
  set edif_name ""
  set array_size 1
  set from -1
  set to -1
  
  set sue_data [api_get_data $id]
  set type [get_assoc type $sue_data]
  
  if {$type == "wire"} {
    set sue_name [get_assoc net $sue_data]
  } else {
    set sue_name [get_assoc _name $sue_data]
  }
  
  if {$type == "name_net" || $type == "name_net_s"} {
    if {$sue_name == ""} {
      set sue_name "NO_NAME_GIVEN"
    }
    set edif_name NAME_NET_${thingno}_$sue_name
    set thingno [expr $thingno + 1]
    set rename "(rename $edif_name $sue_name)"
    set edif_info [list [list edif_name $edif_name] [list is_array no] [list array_size 1]\
		       [list is_portimp no] [list match $edif_name] [list rename $rename] [list base_name $sue_name]]
    set edif_info_by_id($id) $edif_info
    return $edif_info
  }
  
  if {$type == "global"} {
    set edif_name GLOBAL_${thingno}_$sue_name
    set thingno [expr $thingno + 1]
    set edif_info [list [list edif_name $edif_name] [list is_array no] [list array_size 1] [list is_portimp no] [list match $edif_name] [list rename $edif_name] [list base_name $edif_name]]
    set edif_info_by_id($id) $edif_info
    return $edif_info
  }
  
  set edif_info [_edif_info_by_name $sue_name $is_portimp]
  set edif_info_by_id($id) $edif_info
  return $edif_info
}


proc _edif_info_by_name {{sue_name ""} {is_portimp "no"}} {

  global thingno
  global EDIF
  
  # name is not specified; we get to make one up.
  if {$sue_name == ""} {
    set edif_name THING_$thingno
    set thingno [expr $thingno + 1]
    set edif_info [list [list edif_name $edif_name] [list is_array no] [list array_size 1]\
		       [list is_portimp $is_portimp] [list match $edif_name] [list rename $edif_name] [list base_name $edif_name]]
    return $edif_info 
  }

  # a compound net name 
  if {[string first "," $sue_name] != -1} {
    set rename "COMPOUND_WIRE_${thingno}"
    set thingno [expr $thingno + 1]
    set edif_info [list [list edif_name $sue_name] [list is_array no] [list array_size 1]\
    	[list is_portimp $is_portimp] [list match $sue_name] [list rename $rename] [list base_name $sue_name]]
    return $edif_info
  }
  
  # an unaddorned array; again we get to make up name.
  set rc [scan $sue_name "\[%d:%d\]" from to]
  if {$rc == 2} {
    set edif_name THING_${thingno}__${from}_${to}
    set rename "(rename THING_${thingno}__${from}_${to} \"\[${from}:${to}\]\")"
    set thingno [expr $thingno + 1]
    if {$to < $from} {
      set temp $to
      set to $from
      set from $temp
    }
    set array_size [expr $to - $from + 1]
    set edif_info [list [list edif_name $edif_name] [list is_array yes] [list from $from] [list to $to] [list array_size $array_size]\
		       [list is_portimp $is_portimp] [list match ${edif_name}<${from}:${to}>] [list rename $rename] [list base_name $edif_name]]
    return $edif_info
  }
  
  # an unaddorned array instance "[3]"
  set rc [scan $sue_name "\[%d\]" from]
  if {$rc == 1} {
    set edif_name THING_${thingno}__${from}
    set rename "(rename THING_${thingno}__${from} \"\[$from\]\")"
    set thingno [expr $thingno + 1]
    set edif_info [list [list edif_name $edif_name] [list is_array yes] [list from $from] [list to -1] [list array_size 1]\
		       [list is_portimp $is_portimp] [list match ${edif_name}<${from}>] [list rename $rename] [list base_name $edif_name]]
    return $edif_info
  }
  
  # a named array... "bits[7:0]"
  # scan for a string not including square brackets; then range specifier
  set rc [scan $sue_name "%\[^\]\[\]\[%d:%d\]" short_name from to]
  # ...expect the name to match...
  if {$rc == 3} {
    set edif_name ${short_name}__${from}_${to}
    set rename "(rename ${edif_name} \"$short_name\[${from}:${to}\]\")"
    # set rename "(rename ${edif_name} \"$short_name\")"
    if {$to < $from} {
      set temp $to
      set to $from
      set from $temp
    }
    set array_size [expr $to - $from + 1]
    set edif_info [list [list edif_name $edif_name] [list is_array yes] [list from $from] [list to $to] [list array_size $array_size]\
		       [list is_portimp $is_portimp] [list match ${short_name}<${from}:${to}>] [list rename $rename] [list base_name $short_name]]
    return $edif_info
  }
  
  # a named instance... "bits[5]"
  set rc [scan $sue_name "%\[^\]\[\]\[%d\]" short_name from ]
  if {$rc == 2} {
    set edif_name ${short_name}__${from}
    set rename "(rename ${short_name}__${from} \"$edif_name\[$from\]\")"
    set edif_info [list [list edif_name $edif_name] [list is_array yes] [list from $from] [list to -1] [list array_size 1]\
		       [list is_portimp $is_portimp] [list match ${edif_name}<${from}>] [list rename $rename] [list base_name $short_name]]
    return $edif_info
  }
  
  # plain vanilla....
  set edif_info [list [list edif_name $sue_name] [list is_array no]  [list array_size 1]\
		     [list is_portimp $is_portimp] [list match $sue_name] [list rename $sue_name] [list base_name $sue_name]]
  return $edif_info
}
