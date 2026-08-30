#!/bin/csh -f

# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit

# Written by Lee Tavrow, 1999

# Converts dracula drc rules deck into max technology format.

proc read_drac {filename} {

  global LAYINFO max_win MC WIRE_WIDTH VIAS UPSIDEDOWN_CACHE

  if {![file readable $filename]} {
    msg "Aborting, Can't read file $filename\n"
    return
  }

  if {[catch "open $filename r" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    return
  } 

  set LAYERS ""

  puts stderr "Parsing DRACULA file $filename ..."

  while {[gets $FILE_ID line] >= 0} {

    set line [clean_line $line]

    if {$line == ""} {
      continue
    }

    # get the first word on the line
    regexp {^(.+)($|[ ])} $line bogus word

    switch -exact X_$word {

      X_*INPUT-LAYER {
	# layer definition

	while {[gets $FILE_ID original_line] >= 0} {

	  set line [clean_line $original_line]

	  if {$line == ""} {
	    continue
	  }

	  regexp {^([^ ]+)} $line bogus word

	  if {$word == "*END"} {
	    # done with this section
	    break
	  }

	  regexp {^([^ ]+)[ ]*=[ ]*(.+)$} $line bogus layer value
	  lappend LAYERS $layer
	  set GDS_LAYERS($layer) $value
	  set COMMENT_LAYERS($layer) [read_comment $original_line]
	}
      }

      X_*OPERATION {
	# drc rules

	while {[gets $FILE_ID line] >= 0} {

	  set line [clean_line $line]

	  if {$line == ""} {
	    continue
	  }

	  regexp {^([^ ]+)} $line bogus word

	  switch -exact X_$word {

	    X_NOT {
	      regexp {^([^ ]+)[ ]([^ ]+)[ ]([^ ]+)[ ]([^ ]+)} \
		  $line bogus command a b c
	      set LAYER_OP($c) "$a and-not $b"
	      set XLATE($a) $c
	    }

	    X_AND {
	      regexp {^([^ ]+)[ ]([^ ]+)[ ]([^ ]+)[ ]([^ ]+)} \
		  $line bogus command a b c
	      set LAYER_OP($c) "$a and $b"
	    }

	    X_WIDTH {
	      # a happy width rule
	      # WIDTH M2 LT 0.28 OUTPUT M2W1 63
	      # ; M2 width >= 0.28um. M2.W.1

	      regexp {^([^ ]+)[ ]([^ ]+)[ ]([^ ]+)[ ]([^ ]+)} \
		  $line bogus command a b c

	      if {$b == "LT"} {
		set WIDTH_RULE($a) "$c"
	      }
	    }

	    X_EXT[H] - X_EXT {
	      # a happy width rule
	      # EXT[H] M2 LT 0.28 OUTPUT M2S1 63
	      # ; M2 space >= 0.28um. M2.S.1

	      regexp {^([^ ]+)[ ]([^ ]+)[ ]([^ ]+)[ ]([^ ]+)} \
		  $line bogus command a b c

	      if {$b == "LT"} {
		set SPACE_RULE($a) "$c"
	      }
	    }

	    X_*END {
	      # done with this section
	      break
	    }
	  }
	}
      }
    }
  }

  # close the file
  close $FILE_ID

  puts "\# layer   \tgds:dt\ttxt:dt\ttype\twidth\tspace"
  puts "\#============\t======\t=======\t=======\t=======\t======="

  # make a nice table of the results
  foreach layer $LAYERS {
    
    set gds [use_first GDS_LAYERS($layer)]
    if {[llength $gds] > 1} {
      # ignore
      continue
    }

    set width_layer $layer
    set width ""
    while {1} {
      if {[info exists WIDTH_RULE($width_layer)]} {
	set width $WIDTH_RULE($width_layer)
	break
      }

      if {![info exists XLATE($width_layer)]} {
	break
      }

      # try a translated layer, instead
      set width_layer $XLATE($width_layer)
    }

    set space_layer $layer
    set space ""
    while {1} {
      if {[info exists SPACE_RULE($space_layer)]} {
	set space $SPACE_RULE($space_layer)
	break
      }

      if {![info exists XLATE($space_layer)]} {
	break
      }

      # try a translated layer, instead
      set space_layer $XLATE($space_layer)
    }

    if {[regexp {^[mM][a-zA-Z_-]*[0-9]} $layer tmp]} {
      # metal
      set type metal
    } elseif {[regexp {^([vV][a-zA-Z_-]*[0-9])|([cC][oOnNtT])} $layer tmp]} {
      # via
      set type via
    } elseif {[regexp {^[pP][oOlLyY]} $layer tmp]} {
      # poly
      set type poly
    } else {
      set type "-"
    }

    puts [format "%-15s\t%s\t%s\t%s\t%7s%7s" \
	      $layer \
	      $gds \
	      - \
	      $type \
	      $width \
	      $space \
	      ]
  }

#parray GDS_LAYERS
#parray COMMENT_LAYERS
#parray LAYER_OP
#parray WIDTH_RULE
#parray SPACE_RULE

  puts stderr "done."
}



proc clean_line {line} {

  # remove comments (; to end of line)
  set pos [string first ";" $line]
  if {$pos != -1} {
    set line [string range $line 0 [expr $pos - 1]]
  }

  # remove leading and trailing white spaces
  set line [string trim $line]
  # convert tabs to spaces
  regsub -all \t $line " " line

  # remove duplicate spaces
  regsub -all {[ ]+} $line " " line

  return $line
}


proc read_comment {line} {

  set pos [string first ";" $line]
  if {$pos == -1} {
    # no comment
    return ""
  }

  return [string trim [string range $line $pos end] "; "]
}


# returns the value of the first variable name in the list that is defined
# and not equal to "".  If the first character of the name is ' then
# it is a literal.

proc use_first args {
  
  foreach var $args {
    if {[string index $var 0] == "'"} {
      return [string range $var 1 end]
    }
    upvar $var name
    if {[info exists name] && [string compare $name ""] != 0} {
	return $name
    }
  }
}



# do it
read_drac $argv

exit
