## Ritesh Saraf 05/01/2001


proc quickRC {type args} {

## find if request is for C or R 

## r= R(wire) for pi model
	if { $type == "R" } {

	set wire [lindex $args 0]
	set wirelength [lindex $args 1]
	set wirewidth [lindex $args 2]
	set wireproc [lindex $args 3]
	set wiretemp [lindex $args 4]

	return [calcR $wire $wirelength $wirewidth $wireproc $wiretemp]
	}

## c= C(wire)/2 for pi model
	if { $type == "C" } {

	set system  [lindex $args 0]
	set wirelength [lindex $args 1]
	set wirewidth [lindex $args 2]
	set wirespaceL  [lindex $args 3]
	set wiremillerL [lindex $args 4]
	set wirespaceR  [lindex $args 5]
	set wiremillerR [lindex $args 6]
        set wireproc [lindex $args 7]
        set wiretemp [lindex $args 8]

	
	set cap_val [calcC $system $wirelength $wirewidth $wirespaceL $wiremillerL $wirespaceR $wiremillerR $wireproc $wiretemp]
	return $cap_val
	}

}

proc quickRCsp {type args} {

## find if request is for C or R

## r= R(wire) for pi model
        if { $type == "R" } {

        set wire [lindex $args 0]
        set wirelength [lindex $args 1]
        set wirewidth [lindex $args 2]
        set wireproc [lindex $args 3]

        return [calcRsp $wire $wirelength $wirewidth $wireproc ]
        }

## c= C(wire)/2 for pi model
        if { $type == "C" } {

        set system  [lindex $args 0]
        set wirelength [lindex $args 1]
        set wirewidth [lindex $args 2]
        set wirespaceL  [lindex $args 3]
        set wiremillerL [lindex $args 4]
        set wirespaceR  [lindex $args 5]
        set wiremillerR [lindex $args 6]
        set wireproc [lindex $args 7]
	set wiretemp 25

       
        set cap_val [calcC $system $wirelength $wirewidth $wirespaceL $wiremillerL $wirespaceR $wiremillerR $wireproc $wiretemp]
        return $cap_val
        }

}





proc genPiSpice {node1 node2 Rwire_l Cwire piSegments } {

	set Rwire [lindex $Rwire_l 0]
	set tc1 [lindex $Rwire_l 1]
	set tc2 [lindex $Rwire_l 2]
	set Rpi [expr $Rwire / $piSegments ]
	set Cpi [expr $Cwire / $piSegments ]

	lappend spiceL "[unique_name C] $node1 gnd [expr $Cpi / 2]ff \n"

	set node_list $node1
## generate unique node names if required
	if { $piSegments > 1 } {
		while { [expr $piSegments - 1] > 0 } {
		lappend node_list [unique_name rcnetPi]
		set piSegments [expr $piSegments - 1]
		}
	 }

	set seg [llength $node_list]
		set count 0
		while {  $count < [expr $seg - 1] } {
		set count [expr $count + 1]
		lappend spiceL "[unique_name R] [lindex $node_list [expr $count - 1]] [lindex $node_list $count] $Rpi TC1=$tc1 TC2=$tc2\n"
		lappend spiceL "[unique_name C] [lindex $node_list $count] gnd ${Cpi}ff \n"
		}

	lappend spiceL "[unique_name R] [lindex $node_list $count] $node2 $Rpi TC1=$tc1 TC2=$tc2\n"
	lappend spiceL "[unique_name C] $node2 gnd [expr $Cpi / 2]ff "

## hack to fix the first line in spice
	foreach line  $spiceL {
	append piNetlist $line
	}

	return $piNetlist

		
}


## getting resistance data for a particular metal

proc getRdata {process metal args} {

   upvar R R


   set rctech [getrctechfile $args] 

   if {[catch "open $rctech r" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    return
   }

  while {[gets $FILE_ID line] >= 0} {

    set line [cleanUpLine $line $FILE_ID]
    switch [string tolower [lindex $line 0]] {

	res {

	while {[gets $FILE_ID line] >= 0  }  {
		set line [cleanUpLine $line $FILE_ID]

		if {[lindex $line 0] == $process } {


			while {[gets $FILE_ID line] >= 0   } {
			set line [cleanUpLine $line $FILE_ID]

			if { [lindex $line 0] == $metal } {
			set paramList { "r0" "tc1" "tc2" "tnom" }
			foreach param $paramList {
			gets $FILE_ID line
			set line [cleanUpLine $line $FILE_ID]
				if { [lsearch -exact $line $param] == 0 } {
				set R([lindex $line 0]) [lindex $line 1]
				}
			}
			break
			}

			if { [lindex $line 0] == "end" && [lindex $line 1] == "process" } {
			puts "ERROR: no parameters for $metal resistance"
			break
	  	        }

		        }
		} else {
		
		if { [lindex $line 0] == "end" && [lindex $line 1] == "res" } {
		puts "ERROR: no parameters for $process process"
		break
		}
		continue 
		}
	      break
	}
	break
	}

     	default {
	  continue
		}
		
    } 

 } 
  close $FILE_ID
}

## getting capicitance data for a particular metal

proc getCdata {process metSystem args} {

   upvar C C

   set rctech [getrctechfile $args]

   if {[catch "open $rctech r" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    return
   }

      while {[gets $FILE_ID line] >= 0} {

    set line [cleanUpLine $line $FILE_ID]
    switch [string tolower [lindex $line 0]] {

        cap {

        while {[gets $FILE_ID line] >= 0  }  {
                set line [cleanUpLine $line $FILE_ID]

                if {[lindex $line 0] == $process } {


                        while {[gets $FILE_ID line] >= 0   } {
                        set line [cleanUpLine $line $FILE_ID]

                        if { [lindex $line 0] == $metSystem } {
                        set paramList { "width" "space" "ct_a" "cf_t" "cc" "cb_a" "cf_b" }
                        foreach param $paramList {
                        gets $FILE_ID line
                        set line [cleanUpLine $line $FILE_ID]
                                if { [lsearch -exact $line $param] == 0 } {
                                set C([lindex $line 0]) [lreplace $line 0 0 ]
                                }
                        }
                        break
                        }

                        if { [lindex $line 0] == "end" && [lindex $line 1] == "process" } {
                        puts "ERROR: no cap parameters for $metSystem metal system"
                        break
                        }

                        }
                } else {

                if { [lindex $line 0] == "end" && [lindex $line 1] == "cap" } {
                puts "ERROR: no parameters for $process process"
                break
                }
                continue
                }
              break
        }
        break
        }

        default {
          continue
                }

    }

 }
 close $FILE_ID
}




proc cleanUpLine {line file_id} {

    if {$line == ""} {
      # blank line, get next line
      gets $file_id line
      set line [cleanUpLine $line $file_id]
    }

    set line [remove_comments $line]

    set line [string trim $line]

    # look for a continuation (backslash at end of line)
    while {[string index $line [expr [string length $line] - 1]] == "\\"} {
      # continuation, append next line
      gets $file_id line2

      set line2 [remove_comments $line2]

      set line "[string trimright $line \\] $line2"
    }

    # check for illegal characters
    if {[regexp {\{|\}} $line bogus] && \
            [string tolower [lindex $line 0]] != "set"} {
      puts "ERROR: line contains {}, skipping\n\t$line"
    }

    return $line
}

proc remove_comments {line} {

  if {[set pos [string first \# $line]] != -1} {
    # remove comment to end of line (but preserve backslash if any)
    if {[string index $line [expr [string length $line] - 1]] == "\\"} {
      if {[string index [string trim $line] 0] == "\#"} {
        # ignore case where entire line is a comment
        set char ""
      } else {
        set char "\\"
      }
    } else {
      set char ""
    }
    set line "[string range $line 0 [expr $pos -1]]$char"
  }

  return $line
}


proc getrctechfile {args }  {

	global env

	set TECH_FILE_PATH "/volume/cad/mmi/mmi_local.dev/sue/tech"

	if { [lindex $args 0] == "" } {
	set tech $env(MAX_DEFAULT_TECH)
	} else {
	set tech [lindex $args 0]
	}
	set RCtechName [join [list $tech "rc_table" ] . ]
	set techfile [join [list $TECH_FILE_PATH $RCtechName] "/" ]
	if { [file isfile $techfile] == 1 } {
	return $techfile } else {
	puts "ERROR: $techfile not found "
	return 
	}
  }

proc calcRsp { args } {


        set Mwire [lindex $args 0]

        set length [toMicrons  [lindex $args 1] ]
        set width [toMicrons  [lindex $args 2] ]
        set process [lindex $args 3]

        getRdata $process $Mwire

        set r_sqr  $R(r0)
        set tc1    $R(tc1)
        set tc2    $R(tc2)
        set tnom   $R(tnom)
        set r_wire [expr $r_sqr * $length / $width ]


        return [list $r_wire $tc1 $tc2]

 }




proc calcR { args } {


	set Mwire [lindex $args 0]

	set length [toMicrons  [lindex $args 1] ]
	set width [toMicrons  [lindex $args 2] ]
	set process [lindex $args 3]
	set temp [lindex $args 4]

	getRdata $process $Mwire

	set r_sqr  $R(r0)
	set tc1	   $R(tc1)
	set tc2    $R(tc2)
	set tnom   $R(tnom)
	set deltat [expr $temp - $tnom]
	set r_wire [expr [expr $r_sqr * $length / $width ] * [expr 1 + ($tc1 * $deltat) + ($tc2 * pow( $deltat,2)) ] ]


	return $r_wire

 }


proc calcC { args } {


	set Msystem  [lindex $args 0]
	set length [toMicrons [lindex $args 1] ]
	set width [toMicrons [lindex $args 2] ]
	set spaceLeft [toMicrons [lindex $args 3] ]
	set millerLeft [lindex $args 4]
	set spaceRight [toMicrons [lindex $args 5] ]
	set millerRight [lindex $args 6]
	set process [lindex $args 7]
	set temp [lindex $args 8]

	getCdata $process $Msystem

	set width_model $C(width)
	set space_model $C(space)
	set ct_a_model  $C(ct_a)
	set cf_t_model	$C(cf_t)
	set cc_model	$C(cc)
	set cb_a_model  $C(cb_a)
	set cf_b_model  $C(cf_b)

## model has only one width
	if { [lindex $width_model 0] == [lindex $width_model 1]} {
	set width_model [lindex $width_model 0]
	}

	set spaceLLowInd [getLowerIndex $space_model $spaceLeft]
	set spaceLHigInd [getUpperIndex $space_model $spaceLeft]


	set spaceRLowInd [getLowerIndex $space_model $spaceRight]
	set spaceRHigInd [getUpperIndex $space_model $spaceRight]

	set x1L [lindex $space_model $spaceLLowInd]
	set x2L [lindex $space_model $spaceLHigInd]


	set ct_a_model_fitL [fitPWL $spaceLeft $x1L [lindex $ct_a_model $spaceLLowInd] $x2L [lindex $ct_a_model $spaceLHigInd] ]
	set cf_t_model_fitL [fitPWL $spaceLeft $x1L [lindex $cf_t_model $spaceLLowInd] $x2L [lindex $cf_t_model $spaceLHigInd] ]
	set cc_model_fitL   [fitPWL $spaceLeft $x1L [lindex $cc_model $spaceLLowInd] $x2L [lindex $cc_model $spaceLHigInd] ]
	set cb_a_model_fitL [fitPWL $spaceLeft $x1L [lindex $cb_a_model $spaceLLowInd] $x2L [lindex $cb_a_model $spaceLHigInd] ]
	set cf_b_model_fitL [fitPWL $spaceLeft $x1L [lindex $cf_b_model $spaceLLowInd] $x2L [lindex $cf_b_model $spaceLHigInd] ]


	set ctotL [expr ($width * ($ct_a_model_fitL + $cb_a_model_fitL ) / $width_model ) / 2 + $cf_t_model_fitL + $cf_b_model_fitL + ($cc_model_fitL * $millerLeft) ] 


        set x1R [lindex $space_model $spaceRLowInd]
        set x2R [lindex $space_model $spaceRHigInd]

        set ct_a_model_fitR [fitPWL $spaceRight $x1R [lindex $ct_a_model $spaceRLowInd] $x2R [lindex $ct_a_model $spaceRHigInd] ]
        set cf_t_model_fitR [fitPWL $spaceRight $x1R [lindex $cf_t_model $spaceRLowInd] $x2R [lindex $cf_t_model $spaceRHigInd] ]
        set cc_model_fitR   [fitPWL $spaceRight $x1R [lindex $cc_model $spaceRLowInd] $x2R [lindex $cc_model $spaceRHigInd] ]
        set cb_a_model_fitR [fitPWL $spaceRight $x1R [lindex $cb_a_model $spaceRLowInd] $x2R [lindex $cb_a_model $spaceRHigInd] ]
        set cf_b_model_fitR [fitPWL $spaceRight $x1R [lindex $cf_b_model $spaceRLowInd] $x2R [lindex $cf_b_model $spaceRHigInd] ]

	set ctotR [expr ($width * ($ct_a_model_fitR + $cb_a_model_fitR ) / $width_model ) / 2 + $cf_t_model_fitR + $cf_b_model_fitR + ($cc_model_fitR * $millerRight) ]

	return [expr ($ctotL + $ctotR) * $length]

}

proc toMicrons {value} {
        set e ""
        regsub u $value $e u_value
        return $u_value
}


proc fitPWL {k x1 y1 x2 y2} {
	set yk [expr $y1 + (($k - $x1) * ($y2 - $y1) / ($x2 - $x1))]
	return $yk
}


proc getLowerIndex {list elem } {
	set index 0

	if { $elem < [lindex $list 0] } {
		puts "ERROR: $elem is too small "
		return
		}

	while { $index < [llength $list ] } {
		if { ($elem >= [lindex $list $index]) && ($elem <= [lindex $list [expr $index + 1]]) } {
		return $index }
		incr index
	       }

	if { $elem > [lindex $list [expr [llength $list ] + 1]] } {
		puts "ERROR: $elem out of range "
		return
		}

}


proc getUpperIndex {list elem } {
        set index 0

        if { $elem < [lindex $list 0] } {
                puts "ERROR: $elem is too small "
                return
                }
        while { $index < [llength $list ] } {
                if { ($elem >= [lindex $list $index]) && ($elem <= [lindex $list [expr $index + 1]]) } {
                return [expr $index + 1]}
		incr index
               }        
        if { $elem > [lindex $list [expr [llength $list ] + 1]]} {
                puts "ERROR: $elem out of range "
                return
                }

}

