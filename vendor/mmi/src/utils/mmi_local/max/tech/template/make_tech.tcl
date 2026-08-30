#!/bin/csh -f

# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 -- $* ; exit

# Written by Lee Tavrow, 1999

# Creates max technology files from a table description of layers
# and templates

set GOLDEN_TECHS "g18 g25 g35" 

proc make_tech args {

  global env GOLDEN_TECHS

  set default_min 0.4
  set default_overlap 0.04

  if {[llength [lindex $args 0]] < 2} {
    usage_info_exit
  }

  call_keyword [lindex $args 0] {{tech test} {r} {file ""} {h}}

  if {$h} {
    usage_info_exit
  }

  if {![info exists env(MMI_TOOLS)]} {
    puts "Aborting, must set MMI_TOOLS environment variable."
    exit
  }

  if {[lsearch $GOLDEN_TECHS $tech] != -1} {
    puts "Aborting, can't replace any of the GOLDEN TECHNOLOGY files: $GOLDEN_TECHS"
    return
  }

  # figure out the pathname of this script
  set sourceroot [file dirname [info script]]

  set techroot "$env(MMI_TOOLS)/../mmi_local/max/tech"
  # for testing
#  set techroot "~/mmi_private/max/tech"

  # get rid of ~
  set techroot [file nativename $techroot]

  if {$file == ""} {
    puts "Aborting, must supply layer file name."
    usage_info_exit
  }

  if {![file readable $file]} {
    msg "Aborting, Can't read file $file\n"
    return
  }

  if {[catch "open $file r" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    return
  } 

  if {[file isdirectory $techroot/$tech]} {
    if {$r} {
      # remove old technology file of same name
      puts "Removing existing technology directory $techroot/$tech"
      if {[catch "exec rm -rf $techroot/$tech"]} {
	puts "Aborting, can't remove existing technology file \"$tech\".  Change permissions or choose another name."
	exit
      }
    } else {
      puts "Aborting, technology file \"$tech\" already exists."
      puts "use -r option to replace."
      exit
    }
  }

  set planes ""
  set types ""
  set styles ""
  set ignores ""
  set bbox ""
  set act ""
  set poly ""
  set act_types ""
  set metal_types ""
  set other_types ""
  set vias ""
  set last_metal ""
  set last_via ""

  set other_styles {{23 24} {25 26} {27 28} {29 30} {31 32} {33 34} {35 36} {37 38} {39 40} {41 42} {43 44} {45 46} {47 48} {49 50} 51}
  set act_styles {3 5}
  set poly_styles {2}
  set via_styles {52 {53 52} {57 52} {58 52} {59 52} {60 52} 52}
  set metal_styles {12 13 17 {16 20} {15 21} {17 22}}
    
  puts "Parsing layer file \"$file\" ..."

  while {[gets $FILE_ID line] >= 0} {

    set line [string trim $line]

    if {[string index $line 0] == "\#"} {
      # comment
      continue
    }

    if {$line == ""} {
      # blank line, ignore
      continue
    }

    # check for illegal characters
    if {[regexp {\{|\}} $line bogus]} {
      puts "ERROR: line contains {}, skipping\n\t$line"
      continue
    }

    setl {layer	gds txt	type width space} $line

    set gds_layers($layer) $gds
    set txt_layers($layer) $txt
    if {![catch "expr $width"]} {
      # valid number, save it
      set width_layers($layer) $width
    }
    if {![catch "expr $space"]} {
      # valid number, save it
      set space_layers($layer) $space
    }

    switch _$type {

      _act {
	lappend act $layer
	if {[lsearch $planes act] == -1} {
	  lappend planes act
	}
	lappend types "act $layer"
	lappend act_types $layer
      }

      _poly {
	lappend poly $layer
	if {[lsearch $planes act] == -1} {
	  lappend planes act
	}
	lappend types "act $layer"
	lappend act_types $layer
      }

      _via {
	lappend planes $layer
	lappend types "$layer $layer"
	lappend vias $layer
	lappend metal_types $layer

	if {$last_metal == ""} {
	  # must be a contact
	  if {$act_types != ""} {
	    foreach a $act_types {
	      lappend connects($layer) $a
	    }
	    set last_via $layer
	  }
	} else {
	  # via, metal below
	  set connects($layer) $last_metal
	  set last_via $layer
	  # do we need to do this?
	  set last_metal ""
	}
      }

      _metal {
	lappend planes $layer
	lappend types "$layer $layer"
	lappend metal_types $layer
	if {$last_via != ""} {
	  # connect to this via
	  lappend connects($last_via) $layer
	  # do we need to do this?
	  set last_via ""
	}
	set last_metal $layer
      }

      _ignore {
	# ignore this on gds input
	lappend ignores $layer
      }

      _bbox {
	# ignore this on gds input
	lappend ignores $layer
	# write out bbox on gds output
	set bbox $layer
      }

      default {
	# other layers type
	lappend planes $layer
	lappend types "$layer $layer"
	lappend other_types $layer
	set type other
      }
    }

    if {$type != "bbox" && $type != "ignore"} {
      lappend styles "$layer [lindex [set ${type}_styles] 0]"
      if {[llength [set ${type}_styles]] != 1} {
	set ${type}_styles [lrange [set ${type}_styles] 1 end]
      }
    }
  }

  # close the file
  close $FILE_ID

  puts "Building tech directory $techroot/$tech"

  # so far, so good.  Let's build the tech directory
  if {[catch "exec mkdir $techroot/$tech"]} {
    puts "Aborting, can't make directory $techroot/$tech"
    exit
  }

  # now make the .tech file
  if {[catch "open $techroot/$tech/$tech.tech w" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    exit
  } 

  # header stuff
  puts $FILE_ID "/*\tMAX TECHNOLOGY FILE: $tech"
  puts $FILE_ID "\tAutogenerated by make_tech on [clock format [clock seconds]]"
  puts $FILE_ID "*/\n"

  puts $FILE_ID "/* "
  puts $FILE_ID "* To use this file, need to run through the following:"
  puts $FILE_ID "*	./cpp -P $tech.tech | ./m4 > $tech.tech27"
  puts $FILE_ID "*/\n"
  puts $FILE_ID "\#include \"drc_macros.i\"\n"
  puts $FILE_ID "tech"
  puts $FILE_ID "\t$tech"
  puts $FILE_ID "end\n"
  puts $FILE_ID "version"
  puts $FILE_ID "\tversion STRING_CAT($tech,__TIME__,__DATE__)"
  puts $FILE_ID "\tdescription \"$tech\""
  puts $FILE_ID "end\n"

  puts $FILE_ID "planes"
  foreach plane $planes {
    puts $FILE_ID "\t$plane"
  }
  puts $FILE_ID "end\n"

  puts $FILE_ID "types"
  foreach type $types {
    setl {a b} $type
    puts $FILE_ID "\t$a\t$b"
  }
  if {$act != "" && $poly != ""} {
    puts $FILE_ID "\tact\tfet"
  }
  puts $FILE_ID "end\n"

  puts $FILE_ID "contact"
  puts $FILE_ID "end\n"

  puts $FILE_ID "styles"
  # error styles for drc
  puts $FILE_ID "\terror_p\t62"
  puts $FILE_ID "\terror_s\t62"
  puts $FILE_ID "\terror_ps\t62"
  foreach styles $styles {
    setl {a b c} $styles
    puts $FILE_ID "\t$a\t$b"
    if {$c != ""} {
      puts $FILE_ID "\t$a\t$c"
    }
  }
  if {$act != "" && $poly != ""} {
    puts $FILE_ID "\tfet\t7"
    puts $FILE_ID "\tfet\t8"
  }
  puts $FILE_ID "end\n"

  puts $FILE_ID "compose"
  if {$act != "" && $poly != ""} {
    foreach one $act {
      puts $FILE_ID "\tcompose\tfet\t[join $poly ,]\t$one"
    }
  }
  puts $FILE_ID "end\n"

  puts $FILE_ID "connect"
  if {$act != "" && $poly != ""} {
    foreach one $poly {
      puts $FILE_ID "\t$one,fet\t$one,fet"
    }
  }
  foreach con $vias {
    if {[info exists connects($con)]} {
      if {[llength $connects($con)] < 2} {
	# ignore
	unset connects($con)
	continue
      }

      puts $FILE_ID "\t$con\t[join $connects($con) ,]"
    }
  }
  puts $FILE_ID "end\n"

  puts $FILE_ID "cifoutput"
  puts $FILE_ID "style $tech\n"
  puts $FILE_ID "\tunits .01 .001 .01 .001"
  puts $FILE_ID "\tcharset unrestricted\n"
# TODO
#  iname 63 0

  if {$bbox != ""} {
    puts $FILE_ID "\tbbox [parse_gds $gds_layers($bbox) 0]"
  }

  puts $FILE_ID ""

  foreach type $types {
    setl {plane layer} $type
    if {$gds_layers($layer) != "-"} {
      if {$poly == $layer && $act != ""} {
	# special case, output a fet
	set add ",fet"
      } else {
	set add ""
      }

      puts $FILE_ID "\tlayer GDS_$layer $layer$add"

      # square via if we know width and spacing
      if {[lsearch $vias $layer] != -1} {
	# this is a via
	if {[info exists width_layers($layer)] && \
		[info exists space_layers($layer)]} {
	  # put in squaring
	  puts $FILE_ID "\t/* squares <border> <size> <separation> \[align\] */"
	  puts $FILE_ID "\tsquares 0 $width_layers($layer) $space_layers($layer)"
	}
      }

      if {$txt_layers($layer) == "-"} {
	# use same as paint
	puts $FILE_ID "\tlabels $layer$add"

	puts $FILE_ID "\tcalma [parse_gds $gds_layers($layer) 0]\n"

      } else {
	# separate layers
	puts $FILE_ID "\tcalma [parse_gds $gds_layers($layer) 0]\n"

	puts $FILE_ID "\tlayer TXT_$layer"
	puts $FILE_ID "\tlabels $layer$add"

	puts $FILE_ID "\tcalma [parse_gds $txt_layers($layer) 0]\n"
      }
    }
  }
  puts $FILE_ID "end\n"

  set calma ""

  puts $FILE_ID "cifinput"
  puts $FILE_ID "style\t$tech"
  puts $FILE_ID "\tscalefactor\t1\n"
# TODO
#  iname 63 0 		/* instance names here */

  foreach layer $ignores {
    if {$gds_layers($layer) != "-"} {
      puts $FILE_ID "\tignore\tGDS_$layer"
      lappend calma "\tcalma GDS_$layer\t[parse_gds $gds_layers($layer) *]"
    }
    if {$txt_layers($layer) != "-"} {
      puts $FILE_ID "\tignore\tTXT_$layer"
      lappend calma "\tcalma TXT_$layer\t[parse_gds $txt_layers($layer) *]"
    }
  }

  puts $FILE_ID ""

  foreach type $types {
    setl {plane layer} $type
    if {$gds_layers($layer) != "-"} {
      puts $FILE_ID "\tlayer $layer GDS_$layer"

      if {$txt_layers($layer) == "-"} {
	# use same as paint
	puts $FILE_ID "\tlabels GDS_$layer\n"
      } else {
	# use different
	puts $FILE_ID "\tlabels TXT_$layer\n"
      }

      lappend calma "\tcalma GDS_$layer\t[parse_gds $gds_layers($layer) *]"

      if {$txt_layers($layer) != "-"} {
	lappend calma "\tcalma TXT_$layer\t[parse_gds $txt_layers($layer) *]"
      }
    }
  }

  foreach line $calma {
    puts $FILE_ID $line
  }

  puts $FILE_ID "end\n"

  puts $FILE_ID "mzrouter"
  puts $FILE_ID "end\n"

  puts $FILE_ID "drc"
  puts $FILE_ID "cifstyle $tech\n"

  foreach type_pair $types {
    setl {place type} $type_pair
    if {[info exists width_layers($type)]} {
      # make a min width rule
      puts $FILE_ID "\twidth $type [expr $width_layers($type) * 1.0] \\"
      puts $FILE_ID "\t\t\"$type min width = $width_layers($type) um\"\n"
    }

    if {[info exists space_layers($type)]} {
      # make a min space rule
      puts $FILE_ID "\tspacing $type $type [expr $space_layers($type) * 1.0] touching_ok \\"
      puts $FILE_ID "\t\t\"$type min spacing = $space_layers($type) um\"\n"
    }
  }

  if {$act != "" && $poly != ""} {
    puts $FILE_ID "\tno_overlap\tfet,fet\tfet,fet\n"
  }

  if {$vias != ""} {
    puts $FILE_ID "\texact_overlap\t[join $vias ,]\n"
  }

  puts $FILE_ID "end\n"

  puts $FILE_ID "extract"
  puts $FILE_ID "style\t$tech"
  puts $FILE_ID "\tnoplaneordering"
  puts $FILE_ID "end\n"

  # close the file
  close $FILE_ID

  # now make the make file to make the .tech27 file
  if {[catch "open $techroot/$tech/Makefile w" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    exit
  } 

  puts $FILE_ID "\# Makefile for .tech27 file for max\n"
  puts $FILE_ID "all:"
  puts $FILE_ID "\t./cpp -P -traditional $tech.tech | ./m4 > $tech.tech27"

  # close the file
  close $FILE_ID

  # move the drc_macros.i files here
  if {[catch "exec cp $sourceroot/drc_macros.i $techroot/$tech/drc_macros.i"]} {
    puts "ERROR, can't copy $sourceroot/drc_macros.i to $techroot/$tech/drc_macros.i"
  }

  # give a cpp and m4 also and make them executable
  if {[catch "exec cp $sourceroot/m4 $techroot/$tech/m4"]} {
    puts "ERROR, can't copy $sourceroot/m4 to $techroot/$tech/m4"
  }
  if {[catch "exec chmod a+x $techroot/$tech/m4"]} {
    puts "ERROR, can't change permissions of m4"
  }
  if {[catch "exec cp $sourceroot/cpp $techroot/$tech/cpp"]} {
    puts "ERROR, can't copy $sourceroot/cpp to $techroot/$tech/cpp"
  }
  if {[catch "exec chmod a+x $techroot/$tech/cpp"]} {
    puts "ERROR, can't change permissions of cpp"
  }

  # now run make file to make the .tech27 file
  set save_cd [pwd]
  cd $techroot/$tech
  # make doesn't return a good error code
  if {[catch "exec make" msg]} {
    puts "ERROR, can't run \"make\" to make $tech.tech27: $msg"
  }
  cd $save_cd

  # create a .tcl file
  if {[catch "open $techroot/$tech/$tech.tcl w" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    exit
  } 

  puts $FILE_ID "\# $tech.tcl technology file.  Companion to $tech.tech.\n"

  puts $FILE_ID "\# set default MAX viewing grid"
  puts $FILE_ID "set GRID(fine_default_size)   0.1"
  puts $FILE_ID "set GRID(coarse_default_size) 1.0\n"

  puts $FILE_ID "\# Setup palette"
  puts $FILE_ID "pal_group col1 \"metal\" [lreverse $metal_types]"
  if {$act != "" && $poly != ""} {
    set fet fet
  } else {
    set fet ""
  }
  puts $FILE_ID "pal_group col1 \"active\" [lreverse $act_types] $fet"
  puts $FILE_ID "pal_group col1 \"other\" $other_types"

  puts $FILE_ID ""

  # TODO: put in the correct value here
  puts $FILE_ID "set MN_TYPICAL_WIRE_WIDTH 0.3"

  # for the wiring tool and fet generator (eventually)
  puts $FILE_ID "\# for the wiring tool"
  puts $FILE_ID "set LAYINFO(grid) \[res\]"

  if {$vias != ""} {
    puts $FILE_ID "\n\# order of routable layers from the top"
    puts $FILE_ID "set ROUTE(order) \"[lreverse $metal_types] [lreverse $act_types]\""
    set m1 ""
    foreach layer $metal_types {
      if {[lsearch $vias $layer] == -1} {
	# this is the first metal layer
	puts $FILE_ID "set ROUTE(default_layer) $layer"
	set m1 $layer
	break
      }
    }

    puts $FILE_ID "\n\# minimum conductor widths"
    foreach layer [concat $act_types $metal_types] {
      if {[lsearch $vias $layer] != -1} {
	# skip these
	continue
      }
      
      if {[info exists width_layers($layer)]} {
	puts $FILE_ID "set ROUTE($layer) $width_layers($layer)"
      }
    }
    
    puts $FILE_ID "\n\# via routing information"
    set ct ""
    set down ""
    foreach layer [concat $act_types] {
      set _ct [lindex $vias 0]
      if {[info exists connects($_ct)] \
	      && [lsearch $connects($_ct) $layer] != -1} {
	set ct $_ct
	set via ${layer}_$ct
	puts $FILE_ID "set ROUTE($layer,up) $m1"
	puts $FILE_ID "set VIA($layer,$m1) $via"
	puts $FILE_ID "set VIA($m1,$layer) $via"
	
	set via_width [use_first width_layers($ct) default_min]

	puts $FILE_ID "set VIA($via) \"$ct $via_width\""
	puts $FILE_ID "set VIA($via,down) \"$layer [max [use_first width_layers($layer) default_min] [expr $via_width + 2 * [use_first overlap_layers($ct) default_overlap]]]\""
	puts $FILE_ID "set VIA($via,up) \"$m1 [max [use_first width_layers($m1) default_min] [expr $via_width + 2 * [use_first overlap_layers($ct) default_overlap]]]\""
	
	puts $FILE_ID ""
	
	lappend down $layer
      }      
    }
    if {$down != ""} {
      puts $FILE_ID "set ROUTE($m1,down) \"$down\""
    }

    foreach via $vias {
      if {$via == $ct} {
	# already done this one
	continue
      }

      if {[info exists connects($via)]} {
	# assumes two connects
	setl {lower upper} $connects($via)
	puts $FILE_ID "set ROUTE($lower,up) $upper"
	puts $FILE_ID "set ROUTE($upper,down) $lower"
	puts $FILE_ID "set VIA($lower,$upper) $via"
	puts $FILE_ID "set VIA($upper,$lower) $via"

	set via_width [use_first width_layers($via) default_min]

	puts $FILE_ID "set VIA($via) \"$via $via_width\""
	puts $FILE_ID "set VIA($via,down) \"$lower [max [use_first width_layers($lower) default_min] [expr $via_width + 2 * [use_first overlap_layers($via) default_overlap]]]\""
	puts $FILE_ID "set VIA($via,up) \"$upper [max [use_first width_layers($upper) default_min] [expr $via_width + 2 * [use_first overlap_layers($via) default_overlap]]]\""
	puts $FILE_ID ""
      }
    }
  }

  # close the file
  close $FILE_ID

  # now move the color_map and display_styles files here
  if {[catch "exec cp $sourceroot/template.color_map $techroot/$tech/$tech.color_map"]} {
    puts "ERROR, can't copy $sourceroot/template.color_map to $techroot/$tech/$tech.color_map"
  }
  if {[catch "exec cp $sourceroot/template.display_styles $techroot/$tech/$tech.display_styles"]} {
    puts "ERROR, can't copy $sourceroot/template.display_styles to $techroot/$tech/$tech.display_styles"
  }

  puts "done."
}


# show the usage info and then exit

proc usage_info_exit {} {

  puts ""
  puts "Usage:"
  puts "\t-h\tprint this message"
  puts "\t-file\tpathname to layer description file (required)"
  puts "\t-tech\ttechnology name (defaults to test)"
  puts "\t-r\treplace existing technology file"
  puts ""
  exit
}


# return the gds layer number and datatype

proc parse_gds {string default} {

  setl {gds dt} [split $string :]
  if {$dt == "" || $dt == "*"} {
    # use datatype 0 for output by default
    set dt $default
  }

  return "$gds $dt"
}


# like call_with_keyword but returns a list of arguments not keyworded AND
# keyworded arguments not in default list.  unlike call_with_keyword,
# doesn't error if arguments aren't in default list.

proc call_keyword {_ARG_LIST _DEFAULT_LIST} {
  
  set _RETURN ""

  upvar default_value default_value
  upvar defaulted defaulted
  foreach _DEFAULT $_DEFAULT_LIST {
    set _ARG_NAME [lindex $_DEFAULT 0] 
    upvar $_ARG_NAME $_ARG_NAME
    if {[llength $_DEFAULT] == 1} {
      set ${_ARG_NAME}_BINARY 1
      set $_ARG_NAME 0
    } else {
      set ${_ARG_NAME}_BINARY 0
      set $_ARG_NAME [lindex $_DEFAULT 1]
    }
    set default_value($_ARG_NAME) [set $_ARG_NAME]
    set defaulted($_ARG_NAME) 1
  }

  for {set _INDEX 0} {$_INDEX < [llength $_ARG_LIST]} {} {
    if {[string index [lindex $_ARG_LIST $_INDEX] 0] == "-"} {
      # is a keyword pair
      set _ARG_NAME [string range [lindex $_ARG_LIST $_INDEX] 1 end]
      set _ARG_VALUE [lindex $_ARG_LIST [expr $_INDEX+1]]
    
      if {[use_first ${_ARG_NAME}_BINARY] == 1} {
	# binary switch
	set $_ARG_NAME 1
	incr _INDEX

      } elseif {[info exists $_ARG_NAME] == 0} {
	lappend _RETURN -$_ARG_NAME $_ARG_VALUE
	incr _INDEX 2

      } else {
	set $_ARG_NAME $_ARG_VALUE
	set defaulted($_ARG_NAME) 0
	incr _INDEX 2
      }

    } else {
      # not a keyword pair
      lappend _RETURN [lindex $_ARG_LIST $_INDEX]

      incr _INDEX
    }
  }
  return $_RETURN
}




# do it
make_tech $argv

exit
