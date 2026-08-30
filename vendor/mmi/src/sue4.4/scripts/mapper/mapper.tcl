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

#!/bin/csh -f

# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit
 
# Script to create schematics which map between MMI_* icons and a
# customer's cell library.
# Written by Elizabeth M. Cooper

# Parses this format in the mapfile:
# {MMI_Base_Cell_Name CorrespondingCellInfo CorrespondingCellInfo ...}
#    CorrespondingCellInfo = {MMI_Size NoDeMorganInfo DeMorganInfo}
#      NoDeMorganInfo = {CorrespondingCellName PinInfo PinInfo...}
#      DeMorganInfo = {CorrespondingCellName PinInfo PinInfo...}
#        PinInfo = {MMI_Pin_Name CorrespondingCellPinName}
#
# for example, a mapping from INVA and INVA_ to MMI_INVA is:
# {MMI_INV {A {INVA {in in0} {out out0}} {INVA_ {in in0} {out out0}}}
# }
# note: the final closing brace must be the first character in a line by itself!
# why?  because i'm lazy and i don't want to write a real parser
#
# see README for more info...


###############################################################################
# process_args - semi-generic options parser.
#
#  - No option abbreviation
#  - Assumes that options are words beginning with a letter.
#  - Assumes that a contiguous negative decimal string is a value. Other
#    kinds of negative numbers (like hex) are a problem for positional args.
#  - The LAST instance of a dash arg wins, so -a 23 -a 43 means -a is 43.
#  - Does not handle the concept of a required dash_arg
#
# + dash_arg_defs is a list of name/type pairs of dash args.  The
#   type is 0 for boolean, 1 if it takes a value.
# + min_posit/max_posit are the minimum/maximum number of positional args.
#   Just extra checking.  Caller can do that themselves.   -1 for either
#   means don't check.
# + dvalues is an array (fixed) from the caller which will be populated with 
#   the dash arg values.  Indexed by arg name.  Caller provided initial values
#   (we don't init)
# + pvalues is an array from the caller, empty to start.  We populate with
#   the positional args.  Indexed by the position, starting at 0.
# + cargs are the args that were passed to the caller.
#
# Returns error if any unknown options, min/max posit test failed, or
# dash arg which required a value didn't get one (trailed off the end).
#
# Example usage:
#
# set ok [process_args [list -hier 0 -add_value 1] 0 4 vdash vposit $args]
#
proc process_args { dash_arg_defs min_posit max_posit dvalues pvalues cargs } {
  upvar $dvalues values
  upvar $pvalues posit_values
  set posit 0
  set pick_up 0
  set last_opt 0
  set errors 0

  # Setup the ok dash_args table
  foreach {da_name da_type} $dash_arg_defs {
    set okargs($da_name) $da_type
  }

  # parse away
  foreach arg $cargs {
    if { $pick_up } {
      set values($last_opt) $arg
      set pick_up 0
      continue
    }
    if { ([string index $arg 0] != "-") ||
	 [regexp {^\-[0-9]+$} $arg] } {
      # positional
      set posit_values($posit) $arg
      incr posit
    } else {
      # dash - look it up in okargs

      if { ![info exists okargs($arg)] } {
	set errors 1
	puts "Error: Unknown option '$arg'"
	continue
      }
      if { $okargs($arg) == 0 } {
	# boolean
	set values($arg) 1
      } else {
	# takes value
	set pick_up 1
      }

      if { $pick_up } {
	set last_opt $arg
      }
    }
  }
  
  if { $pick_up } {
    puts "Error: Expected value for '$last_opt'"
    set errors 1
  }
  if { $min_posit != -1 && ($posit < $min_posit) } {
    puts "Error: Expected at least $min_posit positional args (got $posit)"
    set errors 1
  }
  if { $max_posit != -1 && ($posit > $max_posit) } {
    puts "Error: Expected no more than $max_posit positional args (got $posit)"
    set errors 1
  }

  if { $errors } {
    return -code error
  }

  return
}



################################################################################
# look for a readable sue file in the given directories
proc find_sue_file {cell dirs} {

  foreach dir $dirs {
    if {[file readable $dir/$cell.sue]} {
      return $dir/$cell.sue
    }
  }

  # can't find/read it
  puts "ERROR, Can't read cell \"$cell\" from directories \"$dirs\"."

  return ""
}



################################################################################
# look for a readable body file in the given directories
proc find_body_file {cell dirs} {

  foreach dir $dirs {
    if {[file readable $dir/$cell.body]} {
      return $dir/$cell.body
    }
  }

  # can't find/read it
#  puts "ERROR, Can't read body file \"$cell\" from directories \"$dirs\"."

  # can't find/read it
  return ""
}

################################################################################
proc place_cell { MMI_ID cell demorganinfo debug } {

  # place the icon
  puts $MMI_ID [format "        make %s -origin \{0 0\}" $cell]

  # make terminals
  puts $MMI_ID [format "        set terms \[api_terminal_data %s\]" $cell]
  puts $MMI_ID [format "        if \{\$terms == \"\"\} \{"]
  puts $MMI_ID [format "          error \"ERROR: No pin info found for icon $cell\""]
  puts $MMI_ID [format "        \}"]
  set terminfo [lrange $demorganinfo 1 end]
  if {$debug} {
    puts "terminfo = $terminfo"
  }
  foreach term $terminfo {
    set mminame [lindex $term 0]
    set corrname [lindex $term 1]
    puts $MMI_ID [format "        set data \[get_assoc \{%s\} \$terms\]" $corrname]
    puts $MMI_ID [format "        set type \[get_assoc type \$data\]"]
    puts $MMI_ID [format "        set origin \[get_assoc origin \$data\]"]
    puts $MMI_ID [format "        set orient \[get_assoc orient \$data\]"]
    puts $MMI_ID [format "        if \{\$orient != \"\"\} \{"]
    puts $MMI_ID [format "          make \$type -origin \$origin -name \{%s\} -orient \$orient" $mminame]
    puts $MMI_ID [format "        \} else \{"]
    puts $MMI_ID [format "          make \$type -origin \$origin -name \{%s\}" $mminame]
    puts $MMI_ID [format "        \}"]
  }

}

################################################################################
# Find the difference between open and close braces to see if there
# is a continuation.

proc find_open_braces {line {open_braces 0}} {

  # increment open_braces for every open braces, decrement for every
  # closed braces

  incr open_braces \
      [expr [llength [split $line \{]] - [llength [split $line \}]]]

  return $open_braces
}

#puts [find_open_braces "now is the time"]
#puts [find_open_braces "now is the \{ time"]
#puts [find_open_braces "now is the \{ time \}"]
#puts [find_open_braces "now is the \{ time \} \{"]

###############################################################################
# here's the real mapper code

proc mapp {args} {

  set debug 0

  # process the arguments
  # init the dash args to default values
  set values(-icononly) 0
  set values(-verilog) 0
  set values(-spice) ""
  set values(-owner) MMI
  set values(-realschematics) 0
  set values(-nogen) 0
  set values(-nonhierdemorgan) 0

  set dash_ok [list -icononly 0 -verilog 0 -spice "" -owner MMI \
		   -realschematics 0 -nogen 0 -nonhierdemorgan 0]

  if { [catch {process_args $dash_ok 3 -1 values pvalues $args}] != 0 } {
    return
  }

  # warnings
  if {$values(-icononly) && $values(-realschematics)} {
    puts "Warning, -icononly and -realschematics both requested; -realschematics ignored"
    set values(-realschematics) 0
  }
  if {$values(-realschematics) && !$values(-verilog)} {
    puts "Warning, -realschematics specified without -verilog, are you sure about that?"
  }

  if {$values(-spice) != "" && $values(-verilog) == 0} {
    puts "Setting verilog property.  Needed to create spice property"
    set values(-verilog) 1
  }

  set owner $values(-owner)

  set icon_only $values(-icononly)
  set real_schematics $values(-realschematics)
  set map_schematics [expr ($icon_only == 0) && ($real_schematics == 0)]
  set nogen $values(-nogen)
  set nonhierdemorgan $values(-nonhierdemorgan)

  # parcel out the positional args
  # arg 0: control file
  # arg 1: to-directory
  # arg 2-?: source directories, must include mmi_body and all library sources
  set filename $pvalues(0)
  set todir $pvalues(1)

  puts "Reading control file \"$filename\" ..."
  if {![file readable $filename]} {
    puts "Aborting, can't read file \"$filename\""
    exit
  }
  # read the file
  if {[catch "open $filename r" FILE_ID]} {
    # problem
    puts "Aborting, error while reading file \"$filename\": $FILE_ID"
    exit
  } 

  set GENERATORS ""

  set ndterminfo ""
  set fromdirs ""
  set endfrom [array size pvalues]
  for {set i 2} {$i < $endfrom} {incr i} {
    lappend fromdirs $pvalues($i)
  }

#  if {[llength $fromdirs] == 1 && $icon_only} {
#    # no icons to map to, only verilog.
#    set no_source_icons 1
#  } else {
#    set no_source_icons 0
#  }

  if {$icon_only} {
    # no icons to map to, only verilog.
    set no_source_icons 1
  } else {
    set no_source_icons 0
  }

  if ($debug) {
    # what did we get?
    puts [format "-icononly=%d" $values(-icononly)]
    puts [format "-verilog=%d" $values(-verilog)]
    puts [format "-spice=%s" $values(-spice)]
    puts [format "-owner=%s" $values(-owner)]
    puts [format "-realschematics=%d" $values(-realschematics)]
    puts [format "-nonhierdemorgan=%d" $values(-nonhierdemorgan)]

    puts [format "control file=%s" $filename]
    puts [format "todir=%s" $todir]
    puts [format "fromdirs=%s" $fromdirs]
  }

  # clean up the to directory
  if {![file isdirectory $todir]} {
    # no directory, try making it
    if {[catch "exec mkdir $todir" msg]} {
      # failed
      puts "Aborting, can't make directory $todir: $msg"
      exit
    }
  }

  catch "exec rm -f [glob $todir/*.sue]" msg

  if {$values(-spice) != ""} {
    # parse this subckt file
    # Get using (assumes no continuations in .subckt def.)
    # grep -h ".subckt" <pathname/*.spi> > <subckt_file>
    parse_subckt_file $values(-spice)
  }

  # parse this format:
  set inline ""
  set inline_cont ""
  set last 0

  while {1} {
    if {$inline_cont == ""} {
      # look for a new cell group

      if {[gets $FILE_ID line] < 0} {
	# done
	break
      }

      set line [string trim $line]
      if {[string index $line 0] == "\#" || [string index $line 0] == ""} {
	# comment or blank line, skip
	continue
      }

      # add to working buffer
      set inline [format "%s %s" $inline $line]

      set last 0

      set ndterminfos ""

    } else {
      # still in the cell group, goto next
      setl {tmp1 tmp2 tmp3} $inline_cont
      # take only the first one and ignore demorgans
      set inline [list [list $tmp1 [lrange $tmp2 0 1]]]

      set line "\}"

      if {$tmp3 == ""} {
	# last one
	set inline_cont ""
	set last 1
      } else {
	# remove the first one
	set inline_cont [lreplace $inline_cont 1 1]
      }
    }

    # we have a full specification when the first character is a close brace
    if {$line == "\}"} {

      set inline [lindex $inline 0]

      if {$nogen && $inline_cont == "" && !$last} {
	# first time to here for this group
	set inline_cont $inline
	continue
      }

      if {$debug} {
	puts "Inline = $inline"
      }

      set anydemorgan 0

      # parse the line
      set mmi_base_cell [lindex $inline 0]
      if {$debug} {
	puts "MMI_base_cell = $mmi_base_cell"
      }
      set sizecount [expr [llength $inline] - 1]
      if {$sizecount < 1} {
	puts "Syntax error in $inline, no size information given"
	exit
      }

      # parse CorrespondingCellInfo
      set sizenames ""
      for {set i 0} {$i < $sizecount} {incr i} {
	# MMI_Size
	set sizeline [lindex $inline [expr $i + 1]]
	set sizename [string toupper [lindex $sizeline 0]]
	lappend sizenames $sizename
	if {$debug} {
	  puts "Sizenames = $sizenames"
	}
	# NoDeMorganInfo, DeMorganInfo
	set mapcount [expr [llength $sizeline] - 1]
	if {($mapcount < 1) || ($mapcount > 2)} {
	  puts "Syntax error in $sizeline, incorrect demorganinfo count"
	  exit
	}
	# is there any demorgan info?
	if {($mapcount == 2)} {
	  set demorgan($i) 1
	  set anydemorgan 1
	} else {
	  set demorgan($i) 0
	}
	# NoDeMorganInfo
	set nodemorganinfo($i) [lindex $sizeline 1]
	set SIZENAMES($sizename) $i

	# save this for use in building the icon proc later
	set last_ndterminfo $ndterminfo
	set ndterminfo [lrange $nodemorganinfo($i) 1 end]
	if {$ndterminfo == ""} {
	  set ndterminfo $last_ndterminfo
	}
	lappend ndterminfos $ndterminfo

	if {$debug} {
	  puts "NoDeMorganInfo = $nodemorganinfo($i)"
	}
	# DeMorganInfo
	if {$demorgan($i)} {
	  set demorganinfo($i) [lindex $sizeline 2]
	  if {$debug} {
	    puts "DeMorganInfo = $demorganinfo($i)"
	  }
	}
      }

      ##########################################################################
      # make the schematic proc

      set mmi $mmi_base_cell

      if {$nogen} {
	set mmi_mmi $mmi[lindex $sizenames 0]
      } else {
      	set mmi_mmi $mmi
      }

      set mmifile $todir/$mmi_mmi.sue
      if {[catch "open $mmifile w" MMI_ID]} {
	# problem
	puts "ERROR, skipping \"$mmi_mmi\".  Can't create file \"$mmifile\": $MMI_ID"
	continue
      } 
      
      puts $MMI_ID "\# Created using mapper from:\n\#\"$inline\"\n"

      # identify the default size
      set sdefault [lindex $sizenames 0]

      # is there a demorgan property for this icon?
      if {$anydemorgan || $no_source_icons} {
	set dstring " \{DeMorgan 0\}"
      } else {
	set dstring ""
      }

      # case 1:  icon_only
      # if there is any demorgan version of this icon and not nonhierdemorgan,
      # then there will be a schematic
      # proc, which consists of a placement of the non-demorganned icon.
      if {$icon_only && $anydemorgan && !$nonhierdemorgan} {
	puts $MMI_ID "proc SCHEMATIC_$mmi args \{"
	puts $MMI_ID "  call_use_keyword \$args \{\{Size \"$sdefault\"\}$dstring\}\n"
	puts $MMI_ID "  set size \[string toupper \$Size\]\n"
	puts $MMI_ID "  switch \$size \{"
	
	for {set i 0} {$i < [llength $sizenames]} {incr i} {
	  set size [lindex $sizenames $i]
	  puts $MMI_ID "    $size \{"

	  if {$demorgan($i) == 1} {
	    # if a demorgan version exists...
	    puts $MMI_ID "      if \{\$DeMorgan\} \{"
	    # place the non-demorganned icon
	    set cell $mmi$size
	    puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 0" $mmi $cell $size]
	    place_cell $MMI_ID $cell $demorganinfo($i) $debug
	    # now place the demorganned icon, for documentation purposes
	    set cell [format "%s%s_" $mmi $size]
	    puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 1" $mmi $cell $size]
	    puts $MMI_ID [format "        make %s -origin \{300 200\}" $cell]
	    # close "if DeMorgan..."
	    puts $MMI_ID "      \}"
	  } else {
p	    # if there is no demorgan version, the schematic proc is empty
	  }

	  # close this switch term
	  puts $MMI_ID "    \}\n"
	}
      
	# end switch statement
	puts $MMI_ID "  \}"
      
	# title bar
	puts $MMI_ID "  make title_bar -origin {0 400} -owner $owner"
      
	# end schematic proc
	puts $MMI_ID "\}\n\n"
      }


      # case 2:  mapping to a user's library
      # in this case, the demorgan schematic consists of a placement of the user's demorgan icon;
      # likewise, the non-demorgan schematic consists of a placement of the user's non-demorgan icon.
      # this will permit the user to potentially have unrelated schematics for demorgan & non-demorgan versions.
      # probably not useful, but who knows.
      if {$map_schematics} {
	puts $MMI_ID "proc SCHEMATIC_$mmi args \{"
	puts $MMI_ID "  call_use_keyword \$args \{\{Size \"$sdefault\"\}$dstring\}\n"
	puts $MMI_ID "  set size \[string toupper \$Size\]\n"
	puts $MMI_ID "  switch \$size \{"
	
	for {set i 0} {$i < [llength $sizenames]} {incr i} {
	  set size [lindex $sizenames $i]
	  puts $MMI_ID "    $size \{"

	  if {$demorgan($i) == 1} {
	    # place the non-demorganned user icon
	    puts $MMI_ID "      if \{!\$DeMorgan\} \{"
	    set cell [lindex $nodemorganinfo($i) 0]
	    set file [find_sue_file $cell $fromdirs]
	    if {$file == ""} {continue}
	    place_cell $MMI_ID $cell $nodemorganinfo($i) $debug
	      
	    # now place the demorganned user icon
	    puts $MMI_ID "      \} else \{"
	    set cell [lindex $demorganinfo($i) 0]
	    set file [find_sue_file $cell $fromdirs]
	    if {$file == ""} {continue}
	    place_cell $MMI_ID $cell $demorganinfo($i) $debug
	    # close the "if !DeMorgan..."
	    puts $MMI_ID "      \}"
	      
	  } else {
	    # there is no demorgan version, so we don't need to print out the "if DeMorgan" stuff
	    # place the non-demorganned user icon
	    set cell [lindex $nodemorganinfo($i) 0]
	    set file [find_sue_file $cell $fromdirs]
	    if {$file == ""} {continue}
	    place_cell $MMI_ID $cell $nodemorganinfo($i) $debug
	  }

	  # close this switch term
	  puts $MMI_ID "    \}\n"
	}
      
	# end switch statement
	puts $MMI_ID "  \}"
      
	# title bar
	puts $MMI_ID "  make title_bar -origin {0 400} -owner $owner"
      
	# end schematic proc
	puts $MMI_ID "\}\n\n"
      }


      # case 3:  mapping to schematics
      # in this case, the demorgan schematic consists of a placement of the non-demorganned MMI icon.
      # the non-demorgan schematic consists of a placement of the schematic.
      if {$real_schematics} {

	if {$nogen} {
	  # not a generator
	  puts $MMI_ID "proc SCHEMATIC_$mmi_mmi \{\} \{"
	  puts $MMI_ID "  set size [lindex $sizenames 0]"

	} else {
	  puts $MMI_ID "proc SCHEMATIC_$mmi args \{"
	  puts $MMI_ID "  call_use_keyword \$args \{\{Size \"$sdefault\"\}$dstring\}\n"
	  puts $MMI_ID "  set size \[string toupper \$Size\]\n"
	}

	puts $MMI_ID "  switch \$size \{"
	
	for {set i 0} {$i < [llength $sizenames]} {incr i} {
	  set size [lindex $sizenames $i]
	  puts $MMI_ID "    $size \{"

	  if {0 && !$nogen} {
	    # make the GENERATORS array
	    lappend GENERATORS "set GENERATORS($mmi$size) \"generate $mmi $mmi$size -Size $size\""
	    if {$demorgan($i)} {
	      lappend GENERATORS "set GENERATORS($mmi${size}_) \"generate $mmi $mmi$size -Size $size -DeMorgan 1\""
	    }
	  }

	  # source the schematic file
	  set cell [lindex $nodemorganinfo($i) 0]
	  set file [find_sue_file $cell $fromdirs]
	  if {$file == ""} {continue}
#puts "using $file for schematic"
	  source $file

	  if {$demorgan($i)} {

	    if {!$nonhierdemorgan} {
	      puts $MMI_ID "      if \{!\$DeMorgan\} \{"
	    }

	    # place the schematic
	    foreach line [split [info body SCHEMATIC_$cell] \n] {
	      if {[regexp "^\[^.\]*make\[^.\]+$cell " $line]} {
		# ignore instances of self, added later
		continue
	      }

	      puts $MMI_ID $line
	    }

	    # add the MMI icon for documentation
	    set cell $mmi$size
	    puts $MMI_ID "        set bbx \[api_bbox\]"
	    puts $MMI_ID "        set urx \[lindex \$bbx 2\]"
	    puts $MMI_ID "        set ury \[lindex \$bbx 1\]"

	    if {$nonhierdemorgan} {
	      puts $MMI_ID "      if \{!\$DeMorgan\} \{"
	    }

	    puts $MMI_ID "        generate $mmi $cell -Size $size -DeMorgan 0"
	    puts $MMI_ID "        make $cell -origin \"\$urx \$ury\""

	    if {$nonhierdemorgan} {
	      puts $MMI_ID "      \} else \{"

	      puts $MMI_ID "        generate $mmi ${cell}_ -Size $size -DeMorgan 1"
	      puts $MMI_ID "        make ${cell}_ -origin \"\$urx \$ury\""
	      puts $MMI_ID "      \}"

	    } else {

	      puts $MMI_ID "      \} else \{"

	      # place the demorganned MMI icon
	      set cell $mmi$size
	      puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 0" $mmi $cell $size]
	      place_cell $MMI_ID $cell $demorganinfo($i) $debug
	      # place the MMI icon for documentation purposes
	      set cell [format "%s%s_" $mmi $size]
	      puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 1" $mmi $cell $size]
	      puts $MMI_ID [format "        make %s -origin \{300 200\}" $cell]

	      # note:  it is assumed that the real schematic already 
	      # contains a title bar, so the title bar is only added when
	      # the schematic proc consists of an icon placement.
	      puts $MMI_ID "  make title_bar -origin {0 400} -owner $owner"

	      # close the "if !DeMorgan..."
	      puts $MMI_ID "      \}"
	    }

	  } else {
	    # there is no demorgan version, so just place the schematic
	    foreach line [split [info body SCHEMATIC_$cell] \n] {
	      if {[regexp "^\[^.\]*make\[^.\]+$cell " $line]} {
		# ignore instances of self, added later
		continue
	      }

	      puts $MMI_ID $line
	    }

	    # place the MMI icon for documentation purposes
	    set cell $mmi$size
	    puts $MMI_ID [format "        set bbx \[api_bbox\]"]
	    puts $MMI_ID [format "        set urx \[lindex \$bbx 2\]"]
	    puts $MMI_ID [format "        set ury \[lindex \$bbx 1\]"]
	    if {!$nogen} {
	      puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 0" $mmi $cell $size]
	    }
	    puts $MMI_ID [format "        make %s -origin \"\$urx \$ury\"" $cell]
	  }
	  # close this switch term
	  puts $MMI_ID "    \}\n"
	}
      
	# end switch statement
	puts $MMI_ID "  \}"
      
      	# end schematic proc
	puts $MMI_ID "\}\n\n"
      }
      
      if {!$nogen} {
	for {set i 0} {$i < [llength $sizenames]} {incr i} {
	  set size [lindex $sizenames $i]

          # make the GENERATORS array
	  lappend GENERATORS "set GENERATORS($mmi$size) \"generate $mmi $mmi$size -Size $size\""
	  if {$demorgan($i)} {
	    lappend GENERATORS "set GENERATORS($mmi${size}_) \"generate $mmi $mmi$size -Size $size -DeMorgan 1\""
	  }
	}
      }

      ##########################################################################
      # make the name proc

      if {!$nogen} {

	puts $MMI_ID "proc NAME_$mmi args \{"
	puts $MMI_ID "  call_use_keyword \$args \{\{Size \"$sdefault\"\}$dstring\}\n"
        puts $MMI_ID "  switch _\$Size \{"
	for {set i 0} {$i < [llength $sizenames]} {incr i} {
	  set size [lindex $sizenames $i]
# TODO: ??? demorgan better than this?
          puts $MMI_ID "    _$size \{ set nom [lindex $nodemorganinfo($SIZENAMES($size)) 0] \}"
        } 
        puts $MMI_ID "  \}"

	if {$anydemorgan || $no_source_icons} {
	  puts $MMI_ID "  if \{\$DeMorgan\} \{"
	  puts $MMI_ID "    set nom \${nom}_"
	  puts $MMI_ID "  \}\n"
	}
	puts $MMI_ID "  return \$nom"
	puts $MMI_ID "\}\n\n"
      }

      #########################################################################
      # make the icon proc

      # header
      puts $MMI_ID "proc ICON_$mmi_mmi args \{"
      set sizearg [format "\{Size \"%s\" \{radio %s\}\}" $sdefault $sizenames]
      if {$anydemorgan || $no_source_icons} {
	set demorganarg " \{DeMorgan 0 binary\}"
      } else {
	set demorganarg ""
      }

      if {$nogen} {
	# not a generator
	puts $MMI_ID "  set size [lindex $sizenames 0]"

      } else {
	puts $MMI_ID "  icon_generator \$args \{$sizearg $demorganarg\}\n"
	puts $MMI_ID "  set size \[string toupper \$Size\]"
      }

      # if the mmi icon has a demorgan symbol, but the user library doesn't,
      # we need to set DeMorgan to 0 so the demorganned icon isn't visible
      if {$anydemorgan || $no_source_icons} {
      } else {
	puts $MMI_ID "  set DeMorgan 0"
      }

      # error checking on inputs
      puts $MMI_ID "\n  \# check for acceptable response on Size"
      set sizeif [format "if \{(\$size != \"%s\")" $sdefault]
      for {set i 1} {$i < [llength $sizenames]} {incr i} {
	set sizeif [format "%s && (\$size != \"%s\")" $sizeif [lindex $sizenames $i]]
      }
      set sizeif "$sizeif\} \{"
      puts $MMI_ID "  $sizeif"
      puts $MMI_ID "    error \"ERROR: Size (\$size) not supported\""
      puts $MMI_ID "  \}\n"
      
      if {$anydemorgan || $no_source_icons} {
	puts $MMI_ID "  \# check for acceptable response on DeMorgan"
	puts $MMI_ID "  if \{(\$DeMorgan != 0) && (\$DeMorgan != 1)\} \{"
	puts $MMI_ID "    error \"ERROR: DeMorgan property (\$DeMorgan) must be 0 or 1\""
	puts $MMI_ID "  \}\n"
      }

#      puts $MMI_ID {  icon_setup $args {{origin {0 0}} {orient R0} {name {}} {M {}} {dpc {}}}}
      puts $MMI_ID {  icon_setup $args {{origin {0 0}} {orient R0} {name {}} {dpc {}}}}
      puts $MMI_ID "\n"

      # suck in icon body file here
      set bodyfile [find_body_file $mmi $fromdirs]
      if {$bodyfile == ""} {

	puts "INFO, no icon body $mmi.body from directories $fromdirs, using icon def from .sue file.  Note: ignoring any demorgans."

	# use body from icon -- no demorgans, though
	puts $MMI_ID "  switch \$size \{"
	for {set i 0} {$i < [llength $sizenames]} {incr i} {

	  set mmi_size "$mmi[lindex $sizenames $i]"
	  set file [find_sue_file $mmi_size $fromdirs]
	  if {$file == ""} {continue}
	  source $file
#puts "using $file for schematic --"

	  set size [lindex $sizenames $i]
	  puts $MMI_ID "    $size \{"

	  # note this ICON proc was loaded when schematic was loaded
	  set open_braces 0
	  foreach line [split [info body ICON_$mmi_size] \n] {

	    # NOTE: could be on continuation line -- TODO fix
#	    if {[regexp {\\$} $line]} {
	      # uh oh, continuation
#           }

	    if {$open_braces > 0} {
	      # ignore this line and possibly future
	      set open_braces [find_open_braces $line $open_braces]
	      continue
	    }

	    if {[regexp "^\[^.\]*icon_setup " $line]} {
	      # ignore icon_setup
	      continue
	    }
	    if {[regexp "^\[^.\]*icon_property " $line] && \
		    [regexp -- "-type\[^.\]+(user|fixed|auto) " $line]} {
	      # ignore user/fixed props, added later
	      set open_braces [find_open_braces $line]
	      continue
	    }

	    puts $MMI_ID $line
	  }
	  puts $MMI_ID "    \}"
	}
	puts $MMI_ID "  \}"

      } else {

	if {[catch "open $bodyfile r" BODY_ID]} {
	  puts "ERROR, Can't read icon body info for \"$mmi\"."
	  continue
	}
	while {[gets $BODY_ID line] >= 0} {
	  puts $MMI_ID $line
	}

	# close the file
	close $BODY_ID
      }

      # properties
      puts $MMI_ID "\n  \# properties"
      puts $MMI_ID {  icon_property -origin {-40 280} -type user -name name}
#      puts $MMI_ID {  icon_property -origin {-40 300} -type user -name M}
      puts $MMI_ID {  icon_property -origin {-40 320} -type user -name dpc}

      # note on legal usage of verilog property: 
      # there can be only one verilog property in all the nested schematics in a .sue file.
      # - if the icon is mapped to a user library, -verilog should be 0.  the 
      #   verilog property is assumed to already be present on the mapped cell.
      # - a demorganned icon has NO verilog property; sue expects the 
      #   verilog property to be present only on the non-demorganned icon.

      if {$values(-verilog) == 1} {
#	puts $MMI_ID "\n  \# verilog property"
	if {$no_source_icons} {
	  puts $MMI_ID "  switch _\$size \{"
	  foreach size $sizenames {
	    puts $MMI_ID "    _$size \{ set fname [lindex $nodemorganinfo($SIZENAMES($size)) 0] \}"
	  }
	  puts $MMI_ID "  \}"
	  # ??? -- maybe no demorgan line
	  puts $MMI_ID "  set nname \[NAME_$mmi -Size \$Size -DeMorgan \$DeMorgan]"
	  
	} elseif {$nogen} {
	  puts $MMI_ID "  set fname $mmi_mmi"
	  puts $MMI_ID "  set nname \$fname"
	} else {
	  puts $MMI_ID "  set fname \[NAME_$mmi -Size \$Size\]"
	  puts $MMI_ID "  set nname \[NAME_$mmi -Size \$Size\ -DeMorgan \$DeMorgan]"
	}

	if {!$no_source_icons && !$nonhierdemorgan} {
	  puts $MMI_ID "  if \{!\$DeMorgan\} \{"
	}

	puts $MMI_ID "  switch \$size \{"

	set i 0
	foreach _size $sizenames {
	  set pnames [create_verilog_prop \
			  [lindex $ndterminfos $i] $no_source_icons]

	  puts $MMI_ID "    $_size \{"
	  puts $MMI_ID "    set pnames \"$pnames\""

          if {$values(-spice) != ""} {
   	    set snames [create_spice_prop \
			    [lindex $nodemorganinfo($SIZENAMES($_size)) 0] \
			    [lindex $ndterminfos $i] $no_source_icons]

   	    puts $MMI_ID "    set snames \"$snames\""
            if {$snames == ""} {
	      puts "Error: No .SUBCKT definition for [lindex $nodemorganinfo($SIZENAMES($_size)) 0].  Bad spice property."
	    }
          }

	  incr i

	  puts $MMI_ID "    \}"
	}
	puts $MMI_ID "  \}\n"

	puts $MMI_ID "  set vprop \"\$fname \\\[unique_name \\\"\\\" \\\$name \$nname\\\] (\$pnames)\\\\;\""
	puts $MMI_ID "  icon_property -origin \{-40 360\} -type fixed -name verilog -text \$vprop"

        if {$values(-spice) != ""} {
	  # add spice property
	  # NOTE: doesn't add "M" property
#xxx
	  puts $MMI_ID "  set sprop \"\\\[unique_name X \\\$name \$nname\\\] \$snames \$nname\""
	  puts $MMI_ID "  icon_property -origin \{-40 400\} -type fixed -name spice -text \$sprop"
	}

	if {!$no_source_icons && !$nonhierdemorgan} {
	  puts $MMI_ID "  \}\n"
	}
      }

      # end icon proc
      puts $MMI_ID "\}"

      # close the file
      close $MMI_ID
      puts "Created \"$mmifile\"."

      # done parsing this specification
      set inline ""
    }

    if {$debug} {
      puts "$line"
    }
  }

  # close the file
  close $FILE_ID

  if {$GENERATORS != ""} {
    # make the generator def file

    set file "$todir/generators.tcl"
    if {[catch "open $file w" FILE_ID]} {
      puts "ERROR, Can't create generator file \"$file\": $FILE_ID"

    } else {
      
      puts $FILE_ID "\# Source this file from .suerc to use schematics without explicit"
      puts $FILE_ID "\# generator calls.\n"

      puts $FILE_ID [join $GENERATORS \n]

      # close the file
      close $FILE_ID

      puts "Wrote generator file to \"$file\"."
    }
  }

  puts "done."
}

################################################################################
proc create_verilog_prop {ndterminfo no_source_icons} {

  # first pin name
  set term [lindex $ndterminfo 0]

  if {$no_source_icons} {
    # do the translation
    setl {mminame mminame_them} $term
  } else {
    set mminame [lindex $term 0]
    set mminame_them $mminame
  }

  set openbracket [string first "\[" $mminame]
  if {($openbracket == -1)} {
    set pnames ".$mminame_them\(\\\$$mminame\)"
  } else {
    set mminamebase [string range $mminame 0 [expr $openbracket - 1]]
    set closebracket [string first "\]" $mminame]
    set bitrange [string range $mminame [expr $openbracket + 1] \
		      [expr $closebracket - 1]]
    set pnames [format ".%s(\\\$\\\{%s\\\[%s\\\]\\\})" \
		    $mminamebase $mminamebase $bitrange]
  }
  
  # rest of the pin names
  set nterms [llength $ndterminfo]
  for {set i 1} {$i < $nterms} {incr i} {
    set term [lindex $ndterminfo $i]
    
    if {$no_source_icons} {
      # do the translation
      setl {mminame mminame_them} $term
    } else {
      set mminame [lindex $term 0]
      set mminame_them $mminame
    }

    set openbracket [string first "\[" $mminame]
    if {($openbracket == -1)} {
      set pnames "$pnames, .$mminame_them\(\\\$$mminame\)"
      
    } else {
      set mminamebase [string range $mminame 0 [expr $openbracket - 1]]
      set closebracket [string first "\]" $mminame]
      set bitrange [string range $mminame [expr $openbracket + 1] \
			[expr $closebracket - 1]]
      set pnames [format "%s, .%s(\\\$\\\{%s\\\[%s\\\]\\\})" \
		      $pnames $mminamebase $mminamebase $bitrange]
    }
  }

  return $pnames
}


proc create_spice_prop {type ndterminfo no_source_icons} {

  global SPICE

#  puts "$type --> $ndterminfo"
  
  if {![info exists SPICE($type)]} {
    return ""
  }

  # rest of the pin names
  foreach term $ndterminfo {

    if {$no_source_icons} {
      # do the translation
      setl {mminame mminame_them} $term
    } else {
      set mminame [lindex $term 0]
      set mminame_them $mminame
    }

    set terms($mminame_them) $mminame
  }

  set snames ""
  foreach arg $SPICE($type) {
    if {[info exists terms($arg)]} {
      lappend snames "\\\$$terms($arg)"
    } else {
      # not defined, use this -- probably a supply
      lappend snames "$arg"
    }
  }

  # lose {} -- hack
  regsub -all "\{|\}" $snames "" snames

  return $snames
}


proc parse_subckt_file {file} {

  global SPICE

  # open to read file
  if {[catch "open $file r" msg]} {
    # error
    puts "ERROR: Can't open $file: $msg"
    exit
  }
  set FILE_ID $msg

  while {[gets $FILE_ID line] >= 0} {
    if {[string tolower [lindex $line 0]] != ".subckt"} {
      # ignore non .subckt lines
      continue
    }

    set SPICE([lindex $line 1]) [lrange $line 2 end]
  }

  # close the tempfile
  close $FILE_ID
}



###############################################################################
# do it
eval mapp $argv

exit

