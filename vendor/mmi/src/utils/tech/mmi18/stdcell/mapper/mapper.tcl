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
# note that the final closing brace must be the first character in a line by itself!
# why?  because i'm lazy and i don't want to write a real parser
#
# see README for more info...


###################################################################################
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
    if { ([string compare [string range $arg 0 0] "-"] != 0) ||
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
      if { ! $okargs($arg) } {
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



###################################################################################
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



###################################################################################
# look for a readable body file in the given directories
proc find_body_file {cell dirs} {

  foreach dir $dirs {
    if {[file readable $dir/$cell.body]} {
      return $dir/$cell.body
    }
  }

  # can't find/read it
  puts "ERROR, Can't read body file \"$cell\" from directories \"$dirs\"."

  # can't find/read it
  return ""
}



###################################################################################
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



###################################################################################
# here's the real mapper code

proc mapp {args} {

  set debug 0

  # process the arguments
  # init the dash args to default values
  set values(-icononly) 0
  set values(-verilog) 0
  set values(-date) 0
  set values(-version) 0
  set values(-realschematics) 0
  set values(-nogen) 0

  set dash_ok [list -icononly 0 -verilog 0 -date 1 -version 1 \
		   -realschematics 0 -nogen 0]

  if { [catch {process_args $dash_ok 4 -1 values pvalues $args}] != 0 } {
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

  set date $values(-date)
  set version $values(-version)

  set icon_only $values(-icononly)
  set real_schematics $values(-realschematics)
  set map_schematics [expr ($icon_only == 0) && ($real_schematics == 0)]
  set nogen $values(-nogen)

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

  set fromdirs ""
  set endfrom [array size pvalues]
  for {set i 2} {$i < $endfrom} {incr i} {
    lappend fromdirs $pvalues($i)
  }

  if ($debug) {
    # what did we get?
    puts [format "-icononly=%d" $values(-icononly)]
    puts [format "-verilog=%d" $values(-verilog)]
    puts [format "-date=%d" $values(-date)]
    puts [format "-version=%d" $values(-version)]
    puts [format "-realschematics=%d" $values(-realschematics)]

    puts [format "control file=%s" $filename]
    puts [format "todir=%s" $todir]
    puts [format "fromdirs=%s" $fromdirs]
  }


  # clean up the to directory
  catch "exec rm -rf $todir/*.sue" foo

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
	lappend sizenames [string toupper [lindex $sizeline 0]]
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
	# save this for use in building the icon proc later
	set ndterminfo [lrange $nodemorganinfo(0) 1 end]
	if {$debug} {
	  puts "NoDeMorganInfo = $nodemorganinfo($i)"
	}
	# DeMorganInfo
	if {$demorgan($i) == 1} {
	  set demorganinfo($i) [lindex $sizeline 2]
	  if {$debug} {
	    puts "DeMorganInfo = $demorganinfo($i)"
	  }
	}
      }

      #############################################################################################
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
      if {$anydemorgan == 1} {
	set dstring [format " \{DeMorgan 0\}"]
      } else {
	set dstring ""
      }

      # case 1:  icon_only
      # if there is any demorgan version of this icon, then there will be a schematic
      # proc, which consists of a placement of the non-demorganned icon.
      if {($icon_only == 1) && ($anydemorgan == 1)} {
	puts $MMI_ID "proc SCHEMATIC_$mmi args \{"
	puts $MMI_ID "  call_use_keyword \$args \{\{Size \"$sdefault\"\}$dstring\}\n"
	puts $MMI_ID "  set size \[string toupper \$Size\]\n"
	puts $MMI_ID "  switch \$size \{"
	
	for {set i 0} {$i < [llength $sizenames]} {incr i} {
	  set size [lindex $sizenames $i]
	  puts $MMI_ID [format "    \"%s\" \{" $size]

	  if {$demorgan($i) == 1} {
	    # if a demorgan version exists...
	    puts $MMI_ID [format "      if \{\$DeMorgan\} \{"]
	    # place the non-demorganned icon
	    set cell [format "%s%s" $mmi $size]
	    puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 0" $mmi $cell $size]
	    place_cell $MMI_ID $cell $demorganinfo($i) $debug
	    # now place the demorganned icon, for documentation purposes
	    set cell [format "%s%s_" $mmi $size]
	    puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 1" $mmi $cell $size]
	    puts $MMI_ID [format "        make %s -origin \{300 200\}" $cell]
	    # close "if DeMorgan..."
	    puts $MMI_ID "      \}"
	  } else {
	    # if there is no demorgan version, the schematic proc is empty
	  }

	  # close this switch term
	  puts $MMI_ID "    \}\n"
	}
      
	# end switch statement
	puts $MMI_ID "  \}"
      
	# title bar
	puts $MMI_ID [format "  make sccs_title_bar -origin {0 400} -owner MMI -version %s -date %s" $version $date]
      
	# end schematic proc
	puts $MMI_ID "\}\n\n"
      }


      # case 2:  mapping to a user's library
      # in this case, the demorgan schematic consists of a placement of the user's demorgan icon;
      # likewise, the non-demorgan schematic consists of a placement of the user's non-demorgan icon.
      # this will permit the user to potentially have unrelated schematics for demorgan & non-demorgan versions.
      # probably not useful, but who knows.
      if {($map_schematics == 1)} {
	puts $MMI_ID "proc SCHEMATIC_$mmi args \{"
	puts $MMI_ID "  call_use_keyword \$args \{\{Size \"$sdefault\"\}$dstring\}\n"
	puts $MMI_ID "  set size \[string toupper \$Size\]\n"
	puts $MMI_ID "  switch \$size \{"
	
	for {set i 0} {$i < [llength $sizenames]} {incr i} {
	  set size [lindex $sizenames $i]
	  puts $MMI_ID [format "    \"%s\" \{" $size]

	  if {$demorgan($i) == 1} {
	    # place the non-demorganned user icon
	    puts $MMI_ID [format "      if \{!\$DeMorgan\} \{"]
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
	puts $MMI_ID [format "  make sccs_title_bar -origin {0 400} -owner MMI -version %s -date %s" $version $date]
      
	# end schematic proc
	puts $MMI_ID "\}\n\n"
      }


      # case 3:  mapping to schematics
      # in this case, the demorgan schematic consists of a placement of the non-demorganned MMI icon.
      # the non-demorgan schematic consists of a placement of the schematic.
      if {($real_schematics == 1)} {

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
	  puts $MMI_ID [format "    \"%s\" \{" $size]

	  # source the schematic file
	  set cell [lindex $nodemorganinfo($i) 0]
	  set file [find_sue_file $cell $fromdirs]
	  if {$file == ""} {continue}
	  source $file

	  if {$demorgan($i) == 1} {
	    puts $MMI_ID [format "      if \{!\$DeMorgan\} \{"]
	    # place the schematic
	    puts $MMI_ID [info body SCHEMATIC_$cell]
	    # add the MMI icon for documentation
	    set cell [format "%s%s" $mmi $size]
	    puts $MMI_ID [format "        set bbx \[api_bbox\]"]
	    puts $MMI_ID [format "        set urx \[lindex \$bbx 2\]"]
	    puts $MMI_ID [format "        set ury \[lindex \$bbx 1\]"]
	    puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 0" $mmi $cell $size]
	    puts $MMI_ID [format "        make %s -origin \"\$urx \$ury\"" $cell]

	    puts $MMI_ID "      \} else \{"
	    # place the demorganned MMI icon
	    set cell [format "%s%s" $mmi $size]
	    puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 0" $mmi $cell $size]
	    place_cell $MMI_ID $cell $demorganinfo($i) $debug
	    # place the MMI icon for documentation purposes
	    set cell [format "%s%s_" $mmi $size]
	    puts $MMI_ID [format "        generate %s %s -Size %s -DeMorgan 1" $mmi $cell $size]
	    puts $MMI_ID [format "        make %s -origin \{300 200\}" $cell]

	    # note:  it is assumed that the real schematic already contains a title bar, so the title
	    # bar is only added when the schematic proc consists of an icon placement.
	    puts $MMI_ID [format "  make sccs_title_bar -origin {0 400} -owner MMI -version %s -date %s" $version $date]

	    # close the "if !DeMorgan..."
	    puts $MMI_ID "      \}"

	  } else {
	    # there is no demorgan version, so just place the schematic
	    puts $MMI_ID [info body SCHEMATIC_$cell]
	    # place the MMI icon for documentation purposes
	    set cell [format "%s%s" $mmi $size]
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
      

      #############################################################################################
      # make the name proc

      if {!$nogen} {

	puts $MMI_ID "proc NAME_$mmi args \{"
	puts $MMI_ID "  call_use_keyword \$args \{\{Size \"$sdefault\"\}$dstring\}\n"
	puts $MMI_ID "  set nom \[format \"$mmi%s\" \[string toupper \$Size\]\]\n"
	if {$anydemorgan == 1} {
	  puts $MMI_ID "  if \{\$DeMorgan == 1\} \{"
	  puts $MMI_ID "    set nom \[format \"%s_\" \$nom\]"
	  puts $MMI_ID "  \}\n"
	}
	puts $MMI_ID "  return \$nom"
	puts $MMI_ID "\}\n\n"
      }

      #############################################################################################
      # make the icon proc

      # header
      puts $MMI_ID "proc ICON_$mmi_mmi args \{"
      set sizearg [format "\{Size \"%s\" \{radio %s\}\}" $sdefault $sizenames]
      if {$anydemorgan == 1} {
	set demorganarg [format " \{DeMorgan 0 binary\}"]
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
      if {$anydemorgan == 0} {
	puts $MMI_ID "  set DeMorgan 0"
      }

      # error checking on inputs
      puts $MMI_ID "\n  \# check for acceptable response on Size"
      set sizeif [format "if \{(\$size != \"%s\")" $sdefault]
      for {set i 1} {$i < [llength $sizenames]} {incr i} {
	set sizeif [format "%s && (\$size != \"%s\")" $sizeif [lindex $sizenames $i]]
      }
      set sizeif [format "%s\} \{" $sizeif]
      puts $MMI_ID "  $sizeif"
      puts $MMI_ID "    error \"ERROR: Size (\$size) not supported\""
      puts $MMI_ID "  \}\n"
      
      if {$anydemorgan == 1} {
	puts $MMI_ID "  \# check for acceptable response on DeMorgan"
	puts $MMI_ID "  if \{(\$DeMorgan != 0) && (\$DeMorgan != 1)\} \{"
	puts $MMI_ID "    error \"ERROR: DeMorgan property (\$DeMorgan) must be 0 or 1\""
	puts $MMI_ID "  \}\n"
      }

      puts $MMI_ID {  icon_setup $args {{origin {0 0}} {orient R0} {name {}} {M {}} {dpc {}}}}
      puts $MMI_ID "\n"

      # suck in icon body file here
      set bodyfile [find_body_file $mmi $fromdirs]
      if {$bodyfile == ""} {
	puts [format "ERROR, Can't read cell %s.body from directories %s." $mmi $fromdirs]
	continue
      }
      if {[catch "open $bodyfile r" BODY_ID]} {
	puts [format "ERROR, Can't read icon body info for \"%s\"." $mmi]
	continue
      }
      while {[gets $BODY_ID line] >= 0} {
	puts $MMI_ID $line
      }

      # close the file
      close $BODY_ID

      # properties
      puts $MMI_ID "\n  \# properties"
      puts $MMI_ID {  icon_property -origin {-40 280} -type user -name name}
      puts $MMI_ID {  icon_property -origin {-40 300} -type user -name M}
      puts $MMI_ID {  icon_property -origin {-40 320} -type user -name dpc}

      # note on legal usage of verilog property: 
      # there can be only one verilog property in all the nested schematics in a .sue file.
      # - if the icon is mapped to a user library, -verilog should be 0.  the verilog property is assumed
      #   to already be present on the mapped cell.
      # - a demorganned icon has NO verilog property; sue expects the verilog property to be present only
      #   on the non-demorganned icon.
      if {($values(-verilog) == 1)} {
	puts $MMI_ID "\n  \# verilog property"
	puts $MMI_ID [format "  if \{!\$DeMorgan\} \{"]
	if {$nogen} {
	  puts $MMI_ID "    set fname $mmi_mmi"
	} else {
	  puts $MMI_ID [format "    set fname \[NAME_$mmi -Size \$Size\]"]
	}

	# first pin name
	set term [lindex $ndterminfo 0]
	set mminame [lindex $term 0]
	set openbracket [string first "\[" $mminame]
	if {($openbracket == -1)} {
	  set pnames [format ".%s(\\\$\\\{%s\\\})" $mminame $mminame]
	} else {
	  set mminamebase [string range $mminame 0 [expr $openbracket - 1]]
	  set closebracket [string first "\]" $mminame]
	  set bitrange [string range $mminame [expr $openbracket + 1] [expr $closebracket - 1]]
	  set pnames [format ".%s(\\\$\\\{%s\\\[%s\\\]\\\})" $mminamebase $mminamebase $bitrange]
	}

	# rest of the pin names
	set nterms [llength $ndterminfo]
	for {set i 1} {$i < $nterms} {incr i} {
	  set term [lindex $ndterminfo $i]
	  set mminame [lindex $term 0]
	  set openbracket [string first "\[" $mminame]
	  if {($openbracket == -1)} {
	    set pnames [format "%s, .%s(\\\$\\\{%s\\\})" $pnames $mminame $mminame]
	  } else {
	    set mminamebase [string range $mminame 0 [expr $openbracket - 1]]
	    set closebracket [string first "\]" $mminame]
	    set bitrange [string range $mminame [expr $openbracket + 1] [expr $closebracket - 1]]
	    set pnames [format "%s, .%s(\\\$\\\{%s\\\[%s\\\]\\\})" $pnames $mminamebase $mminamebase $bitrange]
	  }
	}

	puts $MMI_ID [format "    set vprop \[format \"%%s \\\[unique_name \\\"\\\" \\\$name %%s\\\] (%s)\\\\;\" \$fname \$fname\]" $pnames]
	puts $MMI_ID [format "    icon_property -origin \{-40 360\} -type auto -name verilog -text \$vprop"]
	puts $MMI_ID [format "  \}\n"]
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
  puts "done."
}



###################################################################################
# do it
eval mapp $argv

exit

