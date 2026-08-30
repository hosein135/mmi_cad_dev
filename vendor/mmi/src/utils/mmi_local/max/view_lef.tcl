# Reads a lef file and creates feedback of I/O's, globals, and obstructions for
# the given cell

# parses something of the form

#MACRO INVA
#	CLASS CORE ;
#	FOREIGN INVA 0.00 0.00 ;
#	ORIGIN 0 0 ;
#	SIZE 4.2 BY 14 ;
#	SYMMETRY X Y ;
#	SITE CORE1 ;
#	PIN VDD
#		DIRECTION inout ;
#		USE POWER ;
#		SHAPE ABUTMENT ;
#		PORT
#			LAYER M1 ;
#			RECT 0 13 4.2 14 ;
#		END
#	END VDD
#	PIN in
#		DIRECTION input ;
#		PORT
#			LAYER M2 ;
#			RECT 1.7 5.9 2.5 6.7 ;
#		END
#	END in
#	OBS
#		LAYER M1 ;
#		RECT 0 1.5 4.2 12.5 ;
#	END
#END INVA

set LEF(suffix) .lef

set LEF(lef,paint) 1

# add any layer translations here

# set up for mmi25
set LEF(xlate,Metal1) m1
set LEF(xlate,Metal2) m2
set LEF(xlate,Metal3) m3
set LEF(xlate,Metal4) m4
set LEF(xlate,Metal5) m5
set LEF(xlate,Metal6) m5
set LEF(xlate,METAL1) m1
set LEF(xlate,METAL2) m2
set LEF(xlate,METAL3) m3
set LEF(xlate,METAL4) m4
set LEF(xlate,METAL5) m5
set LEF(xlate,METAL6) m6
set LEF(xlate,metal1) m1
set LEF(xlate,metal2) m2
set LEF(xlate,metal3) m3
set LEF(xlate,metal4) m4
set LEF(xlate,metal5) m5
set LEF(xlate,metal6) m5
set LEF(xlate,VIA1) v12
set LEF(xlate,VIA2) v23
set LEF(xlate,VIA3) v34
set LEF(xlate,VIA4) v45
set LEF(xlate,VIA5) v56
set LEF(xlate,via1) v12
set LEF(xlate,via2) v23
set LEF(xlate,via3) v34
set LEF(xlate,via4) v45
set LEF(xlate,via5) v56
set LEF(xlate,V1) v12
set LEF(xlate,V2) v23
set LEF(xlate,V3) v34
set LEF(xlate,V4) v45
set LEF(xlate,V5) v56
set LEF(xlate,v1) v12
set LEF(xlate,v2) v23
set LEF(xlate,v3) v34
set LEF(xlate,v4) v45
set LEF(xlate,v5) v56

proc view_lef {{filename ""} {cell ""}} -desc {
  reads a lef file and displays contents as a max file with the name <cell>_lef
} {

  global LEF CELL _IMPORT_LEF_ FSBOX OVERLAY

  if {$filename == ""} {
    set default_suffix "*$LEF(suffix)"

    set filename [fs_box -message "LEF File to View:" \
		      -pattern [use_first _IMPORT_LEF_ default_suffix]]

    setl {dir root ext} [split_file_name $filename]

    # if nil, file selector box cancelled -- do nothing
    if {$root == ""} { 
      return 
    }

    set filename $dir/$root$ext

    # save away the suffix for next time
    set _IMPORT_LEF_ [use_first FSBOX(pattern)]
  }

  puts "Parsing file \"$filename\" ..."

  if {[catch "open $filename r" FILE_ID]} {
    # error
    puts "Aborting, $FILE_ID"
    return
  } 

  if {$cell == ""} {

    if {[catch "exec grep \"MACRO \" $filename" msg]} {
      # can't find
      puts "Aborting, can't file any MACRO lines if file \"$filename\"."
      return
    }

    regsub -all "MACRO " [string trim $msg] "" msg
    set cells [split $msg \n]

    set cell [file rootname [file tail $filename]]

    if {[lsearch $cells $cell] == -1} {
      set cell [lindex $cells 0]
    }

    set title "Read LEF"
    set message "Which cell:" 

    set prop_list [list [list cell cell -choice $cells]]

    set OVERLAY [use_first OVERLAY '1]
    lappend prop_list [list "overlay cell" OVERLAY -binary]

    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
      # cancelled
      return
    }
  }

  :feedback clear

  if {$LEF(lef,paint)} {
    set lef_cell ${cell}_lef

    # create a new cell if there isn't one in max of this name
    set flags [cell_flags $lef_cell]
    if { $flags == "__NO_SUCH_BUFFER__" } {
      # create the new cell
      puts "Creating cell $lef_cell"
      db_cell_new $lef_cell $lef_cell$CELL(default_suffix)
      # goto the cell
      :load $lef_cell

    } else {
      # goto the cell
      :load $lef_cell

      # otherwise toast the contents of the cell
      # It's faster to delete any paint with :erase first
      eval lay_box [lay_bbox]
      :erase

      eval sel_area [lay_bbox]
      :delete
    }

    lay_box 0 0 0 0
    if {$OVERLAY} {
      # put in max cell if it exists
      catch ":getcell $cell child 0 0 parent 0 0"
    }

  } else {
    # since we are going to overlay, goto this cell
    catch ":load $cell"
  }

  set ORIGIN ""
  set FOREIGN ""
  while {[gets $FILE_ID line] >= 0} {

    set line [string trim $line]

    if {[lindex $line 0] != "MACRO"} {
      continue
    }

    if {[lindex $line 1] == $cell} {
      # found the lef for this cell

      set level 0
      while {[gets $FILE_ID line] >= 0} {

	set word [lindex [string trim $line] 0]
	if {$word == "END"} {
	  if {$level == 0} {
	    break
	  } else {
	    incr level -1
	  }
	}

#	if {$word == "OBS"} {
#	  incr level
#	}
	
	if {$word == "ORIGIN"} {
	  set ORIGIN "[lindex $line 1] [lindex $line 2]"
	}
	if {$word == "FOREIGN"} {
	  set FOREIGN "[lindex $line 2] [lindex $line 3]"
	}
	if {$word == "SIZE"} {
	  set SIZE "[lindex $line 1] [lindex $line 3]"
	}

	set use ""
	if {$word == "PIN" || $word == "OBS"} {
	  if {$word == "PIN"} {
	    set pin_name [lindex $line 1]
	  } else {
	    set pin_name OBS
	  }

	  set string $line
	  while {[gets $FILE_ID line] >= 0} {
	    setl {word1 word2} $line
	    if {$word1 == "END" && \
		    ($word2 == $pin_name || $pin_name == "OBS")} {
	      # done with this pin
	      break
	    }

	    set string [concat $string $line]
	  }

	  regsub DIRECTION $string "\; DIRECTION" string
	  regsub LAYER $string "\; LAYER" string
	  regsub PORT $string "PORT \;" string
	  set lines [split $string \;]

	  set kind local
	  foreach line $lines {

	    set word [lindex $line 0]

	    switch $word {

	      USE { 
		switch [lindex $line 1] {
		  POWER - GROUND {
		    # special
		    set kind global
		  }
		}
	      }

	      LAYER {
		set layer [lindex $line 1]
	      }

	      DIRECTION {
		# NOTE: overwritten if followed by a USE POWER/GROUND
		set kind [string tolower [lindex $line 1]]

		if {[lsearch "input output inout" $kind] == -1} {
		  puts "Warning: changing direction from $kind to inout on $pin_name."
		  set kind inout
		}
	      }

	      RECT - PATH {
		# remember all the rectangles
		setl {x1 y1 x2 y2} [lrange $line 1 4]
		lay_box [uusnap $x1] [uusnap $y1] [uusnap $x2] [uusnap $y2]
		if {$LEF(lef,paint)} {
		  # paint this layer
		  set layer [_view_lef_layer $layer]
		  
		  :paint $layer
		  if {$pin_name != "OBS"} {
		    # only put the pin name in once
		    setl {x y} [eval center_coords [lrange $line 1 4]]
		    lay_box $x $y $x $y
		    :label -kind $kind $pin_name c $layer
		    
		    # TODO: we could see if there is a label and if not add one
		    
		    # so we don't make it again
		    set pin_name OBS
		  }
		  
		} else {
		  # just make feedback of it
		  :feedback add "$pin_name ([use_first layer])"
		}
	      }

	      POLYGON {
		# TODO: eventually fracture this
		setl {xxx x1 y1 xtmp ytmp x2 y2} $line
		if {$LEF(lef,paint)} {
		  # paint this layer
		  set layer [_view_lef_layer $layer]

		  eval db_polygon $layer [lrange $line 1 end]
		  if {$pin_name != "OBS"} {
		    # only put the pin name in once
		    setl {x y} [center_coords $x1 $y1 $x2 $y2]
		    lay_box $x $y $x $y
		    :label -kind $kind $pin_name c $layer

		    # TODO: we could see if there is a label and if not add one

		    # so we don't make it again
		    set pin_name OBS
		  }
		  
		} else {
		  # just make feedback of it
		  # TODO: broken
		  lay_box $x1 $y1 $x2 $y2
		  :feedback add "$pin_name ([use_first layer])"
		}
	      }
	    }
	  }
	}
      }

      # close the file
      close $FILE_ID

      if {$LEF(lef,paint)} {
	# add boundary if there is one
	if {[info exists SIZE]} {
	  set origin "0 0"
	  setl {x y} [use_first ORIGIN FOREIGN origin]
	  setl {dx dy} $SIZE

	  # TODO: generic prb layer name
	  catch "db_paint prb $x $y [expr $x + $dx] [expr $y + $dy]"
	}
      }

      update
      :view

      puts "done."

      return
    }
  }

  # close the file
  close $FILE_ID

  puts "Error, can't find lef for cell $cell in $filename"
}


proc _view_lef_layer {layer} -desc {
  translates the layer name if needed to MAX layer names
} {

  global LEF

  if {![catch "lay_layer_styles $layer"]} {
    # this is a good layer
    return $layer
  }

  if {![catch "lay_layer_styles [string tolower $layer]"]} {
    # convert to lower case
    return [string tolower $layer]
  }

  if {![catch "lay_layer_styles [string toupper $layer]"]} {
    # convert to lower case
    return [string toupper $layer]
  }

  if {[info exists LEF(xlate,$layer)]} {
    # use translation, check if valid layer
    return [_view_lef_layer $LEF(xlate,$layer)]
  }

  # Note valid, abort
  set new_layer [lindex [lreverse [techinfo layer_order]] 0]

  set message "Error, no MAX layer \"$layer\".  Set up the LEF(xlate) array or change the lef file and run again.  Using \"$new_layer\"."
  puts $message
  tk_dialog .dialog Warning $message {} 0 OK
    
  return [_view_lef_layer $new_layer]
#  return -code return 0
}
