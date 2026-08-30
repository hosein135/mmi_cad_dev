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


# Extracts a spice netlist of the current cell.  Source/Drain areas/perims
# add.  Resistances are ignored.

# Will not extract weird shaped transistors.


proc extract_subcircuit {} -desc {
  extracts a spice netlist of a cell and writes to existing file using ext_puts.  Note, does not put wire capacitance on I/O's.
} {

  global _EXTRACT_LABELS _EXTRACT MC

  catch {unset _EXTRACT}

  # make sure that everything is expanded
  eval lay_box [lay_bbox]
  lay_internals -area

  # don't extract I/O's, globals
  sel_labels
  foreach label [split [sel_what labels] \n] {
    setl {layer x1 y1 x2 y2 pos text path group kind} $label
    if {[lsearch "global input output inout" $kind] != -1} {
      set _EXTRACT($text,cap) 0
    }
  }

  set _EXTRACT(__lines) ""
  _extract_spice

  # write out the subckt
  ext_puts ".SUBCKT [lay_rootcell] [lsort $_EXTRACT_LABELS(__ios)]"

  foreach line $_EXTRACT(__lines) {
    ext_puts $line
  }

  ext_puts ".ENDS\t\$ [lay_rootcell]"

  ext_puts " "

  sel_clear
  puts "  Extracted spice netlist of cell \"[lay_rootcell]\"."
}


proc extract_spice {{suffix sp} {verbose 0}} -desc {
  extracts a spice netlist of a cell and writes to a file
} {

  global _EXTRACT_LABELS _EXTRACT MC MC_GLOBAL FILE_ID

  catch {unset _EXTRACT}
  catch {unset MC_GLOBAL}

  # make sure that everything is expanded
  eval lay_box [lay_bbox]
  lay_internals -area

  # write out the netlist
  set cell [lay_rootcell]

  # compute directory for netlist
  set file [lindex [cell_info $cell] 1]
  if {$file == ""} {
    set dir "[pwd]/"
  } else {
    set dir [file dirname $file]/
    if {$dir == "./"} {
      set dir "[pwd]/"
    }
  }
  set filename "$dir$cell.$suffix"

  if {[catch "open $filename w" FILE_ID]} {
    # error
    puts "ERROR: $FILE_ID"
    return
  }

  spice_line_to_file $FILE_ID "*** Extracted spice netlist generated from MAX ***"

  if {$verbose} {
    ext_puts "\n* node correspondances:"
  }

  set _EXTRACT(__lines) ""
  _extract_spice $verbose

  spice_line_to_file $FILE_ID "\n.SUBCKT $cell [lsort $_EXTRACT_LABELS(__ios)]"

  foreach line $_EXTRACT(__lines) {
    spice_line_to_file $FILE_ID $line
  }

  spice_line_to_file $FILE_ID ".ENDS\t$ $cell\n"

  # added low and high supply to any other globals
  set MC_GLOBAL([string tolower $MC(supply,low)]) 1
  set MC_GLOBAL([string tolower $MC(supply,high)]) 1

  spice_line_to_file $FILE_ID ".GLOBAL [array names MC_GLOBAL]\n"
#  spice_line_to_file $FILE_ID ".END"

  # close the tempfile
  close $FILE_ID

  sel_clear
  puts "Extracted spice netlist of cell \"$cell\" to $filename."
}


proc _extract_spice {{verbose 0}} -desc {
  does the work of extracting a spice netlist of a cell
} {

  global _EXTRACT _EXTRACT_LABELS MC _EXTRACT_NETS
 
  catch {unset _EXTRACT_NETS}

  catch {unset _EXTRACT_LABELS}
  set _EXTRACT_LABELS(__unique) 0
  set _EXTRACT_LABELS(__ios) ""

  set _EXTRACT(__CAP) 0
  set _EXTRACT(__Mp) 0
  set _EXTRACT(__Mn) 0
  set _EXTRACT(__fets) ""

  set lines ""

  foreach device [techinfo devices] {
    set diff [lindex [techinfo device $device] 1]
    lappend diffs $diff
    set _EXTRACT(device,$diff) $device
  }
  set _EXTRACT(diffs) $diffs

  # select the fets
  eval sel_area -any_cell -layers [join [techinfo devices] ,] [lay_bbox]
  foreach paint [split [sel_what paint] \n] {
    setl {type x1 y1 x2 y2} $paint

    # find the source/drain connections
    eval sel_area -any_cell -layers [join $diffs ,] \
	[expr $x1 - 2*[res]] [expr $y1 - 2*[res]] \
	[expr $x2 + 2*[res]] [expr $y2 + 2*[res]]

    setl {typea x1a y1a x2a y2a typeb x1b y1b x2b y2b blank} [sel_what paint]
    if {$typea == "" || $typeb == "" || $blank != ""} {
      # something's wrong
      puts "ERROR: aborting, cannot extract this transistor."
      return
    }

    if {[expr $x2a - $x1a] == [expr $x2 - $x1]} {
      # transistor is oriented up/down
      set w [expr $x2 - $x1]
      set l [expr $y2 - $y1]

    } elseif {[expr $y2a - $y1a] == [expr $y2 - $y1]} {
      # transistor is oriented left/right
      set w [expr $y2 - $y1]
      set l [expr $x2 - $x1]

    } else {
      # something's wrong
      puts "ERROR: aborting, cannot extract this transistor."
      return
    }

    # compute parasitics and net names
    set nets ""
    foreach port [list \
		      "[center_coords $x1a $y1a $x2a $y2a] $typea" \
		      "[center_coords $x1 $y1 $x2 $y2] $type" \
		      "[center_coords $x1b $y1b $x2b $y2b] $typeb" \
		     ] {

      # get the net name for the net connected to this point
      # also computes cap and diodes.
      lappend nets [eval _extract_net_identifier $port $verbose]
    }

    # for naming only
    set t [string index $type 0]

    if {[use_first MC(parasitics)] != 0} {
      # parasitics
      setl {drain gate source} $nets

      lappend _EXTRACT(__fets) [list $w $type $drain $source "M${t}_[incr _EXTRACT(__M$t)] $nets $MC($type,bulk) $MC($type,model) W=${w}U L=${l}U"]
      
      # go thru drain and source
      foreach net "$drain $source" {
	if {[info exists _EXTRACT($net,$type,w)]} {
	  set _EXTRACT($net,$type,w) [expr $_EXTRACT($net,$type,w) + $w + 0.0]
	} else {
	  set _EXTRACT($net,$type,w) $w
	}
      }

    } else { 
      # no parasitics
      lappend _EXTRACT(__lines) "M${t}_[incr _EXTRACT(__M$t)] $nets $MC($type,bulk) $MC($type,model) W=${w}U L=${l}U"
    }
  }    

  if {[use_first MC(parasitics)] != 0} {
    # add fets with proper AD/PD,AS/PS
    foreach list $_EXTRACT(__fets) {
      setl {w type drain source line} $list

      setl {ad pd} $_EXTRACT($drain,$type)
      set dratio [expr $w / $_EXTRACT($drain,$type,w)]

      setl {as ps} $_EXTRACT($source,$type)
      set sratio [expr $w / $_EXTRACT($source,$type,w)]

      lappend _EXTRACT(__lines) \
	  [format "$line AD=%gP PD=%gU AS=%gP PS=%gU" \
	       [expr $ad*$dratio] [expr $pd*$dratio] \
	       [expr $as*$sratio] [expr $ps*$sratio]]
    }
  }

  return $lines
}


# returns a unique net identifier for the port location.  Also remembers
# io's and reports duplicates.  Also computes capacitance and diodes.
# Caches data.

proc _extract_net_identifier {x y layer {verbose 0}} {

  global _EXTRACT_LABELS MC _EXTRACT _EXTRACT_NETS MC_GLOBAL

  # first check if we already got this one by selecting the point

# HACK but doesn't always work
  # on this layer only
#  sel_region -point $x $y $layer
  eval sel_net -point $x $y $layer
  set paint [lrange [sel_what paint] 0 4]
  if {[info exists _EXTRACT_NETS($paint)]} {
    # been here before
    return $_EXTRACT_NETS($paint)
  }

  set warning 0

  # need to extract this entire net
#  eval sel_net -point $x $y $layer

  # insure that all disconnected, but same named I/O's and globals
  # are connected
  set labels [split [sel_what labels] \n]
  foreach label $labels {
    setl {layer x1 y1 x2 y2 pos text path group kind} $label
    if {$path == "" && ![info exists trace($text)] && \
			    [lsearch "global input output inout" $kind] != -1} {
      sel_labels -more -text $text
      set trace($text) 1
    }
  }

  set new_labels [split [sel_what labels] \n]
  if {$labels != $new_labels} {
    set warning 1

    foreach label $new_labels {
      if {[lsearch $labels $label] == -1} {
	setl {layer x1 y1 x2 y2 pos text path group kind} $label
	if {$path == "" && [lsearch "global input output inout" $kind] != -1} {
	  sel_net -more -point $x1 $y1 $layer
	}
      }
    }
  }

  set net_label ""
  set net_label_local ""
  foreach label [split [sel_what labels] \n] {
    setl {layer x1 y1 x2 y2 dir name path group kind} $label

    if {$path != ""} {
      # ignore labels that aren't in the top level cell
      continue
    }

    switch $kind {
      input - output - inout {
	if {[info exists _EXTRACT_LABELS($name)]} {
	  puts "WARNING: unconnected duplicate I/O label \"$name\"."
	  # use this name, however
	}

	if {$net_label != "" && $net_label != $name} {
	  puts "ERROR: duplicate I/O label on net \"$name\"."
	} elseif {$net_label == ""} {
	  set net_label $name
	  
	  # remember i/o's
	  lappend _EXTRACT_LABELS(__ios) $name
	}
      }

      global {
	if {$net_label != "" && $net_label != $name} {
	  puts "ERROR: duplicate global label on net \"$name\"."
	} else {
	  set net_label $name
	  # remember globals
	  set MC_GLOBAL([string tolower $name]) 1
	}
      }

      local - comment {
	if {[info exists _EXTRACT_LABELS($name)]} {
	  puts "ERROR: duplicate label $name"
	} else {
	  set net_label_local $name
	}
      }
    }
  }

  if {$net_label != ""} {
    # found an input/output/inout
    set _EXTRACT_LABELS($net_label) 1
    set name $net_label
    
  } elseif {$net_label_local != ""} {
    # found a local/comment for the name
    set _EXTRACT_LABELS($net_label_local) 1
    set name $net_label_local

  } else {
    # no labels, make up a name
    set name net_[incr _EXTRACT_LABELS(__unique)]
    while {[info exists _EXTRACT_LABELS($name)]} {
      # already used, make a new one
      set name net_[incr _EXTRACT_LABELS(__unique)]
    }

    set _EXTRACT_LABELS($name) 1
  }

  # store away all the pieces of paint with reference to this name
  # for reference
  foreach paint [split [sel_what paint] \n] {
    set _EXTRACT_NETS($paint) $name
  }

  if {$verbose} {
    ext_puts "* $name ="
    foreach label [split [sel_what labels] \n] {
      ext_puts "*\t[lindex $label 7][lindex $label 6]"
    }
  }

  if {[use_first MC(parasitics)] != 0} {
    # add parasitics to this net

    # add this cap
    setl {cap units} [ext_capacitance]
    if {$cap != 0.0} {
      lappend _EXTRACT(__lines) \
	  "C_[incr _EXTRACT(__CAP)] $name $MC(supply,low) $cap$units"
    }

    # add the source/drain areas on this net
    foreach diff $_EXTRACT(diffs) {
      _extract_add_diode $name $diff
    }
  }

  if {$warning} {
    puts "WARNING: unconnected duplicate labels \"$name\" tied together."
  }

  return $name
}


proc _extract_add_diode {net diff} {

  global _EXTRACT

  set area 0
  set perim 0

  foreach paint [split [sel_what paint] \n] {
    setl {type x1 y1 x2 y2} $paint

    if {$type != $diff} {
      continue
    }

    # add this area/perim
    set area [expr $area + ($x2-$x1) * ($y2-$y1)]
    # NOTE that perim will be pessimistic on L shapes or other complicated
    # shapes
    set perim [expr $perim + 2 * (($x2-$x1) + ($y2-$y1))]
  }

  if {$area == 0} {
    # no area of type diffusion
    return
  }

  set _EXTRACT($net,$_EXTRACT(device,$diff)) "$area $perim"
}


proc spice_line_to_file {FILE_ID lines} {

  # first get rid of any curly braces that might have wandered in
  # and which aren't preceded by the backslash quote character
  regsub -all {([^\])(\})} $lines {\1} lines
  regsub -all {([^\])(\{)} $lines {\1} lines
  regsub -all {(\\)(\{|\})} $lines {\2} lines

  foreach line [split $lines \n] {
    if {$line == ""} {
      # a line feed
      puts $FILE_ID $line
    }
    # if you break a comment line, the new line should still be a comment
    if {[string index $line 0] == "*"} {
      set cont_char "*+"
    } else {
      set cont_char "+"
    }
    while {$line != ""} {
      if {[string length $line] > 75} {
	set space [string last " " [string range $line 0 75]]
	if {$space == -1} {
	  set space [expr 50 + [string first " " "[string range $line 50 end] "]]
	}

	set subline [string range $line 0 $space]
	puts $FILE_ID $subline
	set line "$cont_char [string range $line [incr space] end]"

      } else {
	puts $FILE_ID $line
	set line ""
      }
    }
  }
}


proc _is_leaf_cell {} -desc {
  returns 1 if current cell is a leafcell, 0 otherwise.  A leafcell either has a fet layer in it, a gcell fet, or a cell with a fet in it with no labels
} {

  set devices [join [techinfo devices] ,]

  # are there any fets here?
  eval sel_area -layers $devices [lay_bbox]
  if {[sel_what paint] != ""} {
    # leaf cell
    sel_clear
    return 1
  }

  # look at all the subcells for gcells
  foreach cell [db_kids] {
    if {[string index $cell 0] == "\#" && [string first fet $cell] != -1} {
      # leaf cell
      return 1
    }
  }

  # look at subcells for fet cells with no labels
  foreach cell [split [db_search cells] \n] {
    setl {name type} $cell
    if {[info exists trace($type)]} {
      # already looked at this
      continue
    }
    set trace($type) 1

    if {[string index $type 0] == "\#"} {
      # ignore gcells
      continue
    }

    # push into this cell
    sel_cell $name
    edit_push

    # look for fets
    eval sel_area -layers $devices [lay_bbox]
    if {[sel_what paint] != ""} {
      # got fets, are these fet cells?
      # assume fet cells are at least 50% s/d/g area
      set layers ""
      foreach fet [techinfo devices] {
	lappend layers $fet
	lappend layers [lindex [techinfo device $fet] 1]
      }
      eval sel_area -layers [join $layers ,] [lay_bbox]
      setl {x1 y1 x2 y2} [db_bbox -cell __SELECT__]
      setl {bx1 by1 bx2 by2} [lay_bbox]
      if {[expr ($y2 - $y1) * ($x2 - $x1) * 2] < \
	      [expr ($by2 - $by1) * ($bx2 - $bx1)]} {
	# not leaf cell
	sel_clear

      } else {
	# now look for labels
	sel_labels 
	if {[sel_what labels] == ""} {
	  # leaf cell
	  sel_clear
	  edit_pop
	  sel_clear
	  return 1
	}
      }
    }

    # return to calling cell
    edit_pop
  }

  # not a leaf cell
  sel_clear
  return 0
}