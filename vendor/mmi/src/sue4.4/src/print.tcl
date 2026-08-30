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


# printing

# setup the page sizes for normal 8.5x11 in2 paper
set PRINT(WIDTH) 8.5
set PRINT(HEIGHT) 11

# makes a postscript file for the current canvas.  If PRINT(MODE) is print
# prints to default printer, otherwise to file.

proc make_ps {{prefix ""}} {
    
  global cur_c cur_s scale WIN COLORS env COLORMAP PRINT SUE_DIR FONT 
  global SUFFIX PROC auto_index SUE_BIN

  # if you set black, you screw things up
  catch {unset COLORMAP(black)}

  busy

  # if we do this here then the user can change the margin and it will
  # happen immediately
  set PRINT(SIZEX,0) [expr $PRINT(WIDTH) - $PRINT(MARGIN)]
  set PRINT(SIZEY,0) [expr $PRINT(HEIGHT) - $PRINT(MARGIN)]
  set PRINT(SIZEX,1) [expr $PRINT(HEIGHT) - $PRINT(MARGIN)]
  set PRINT(SIZEY,1) [expr $PRINT(WIDTH) - $PRINT(MARGIN)]

  upvar #0 SUE_$cur_s data
  set dir $data(dir)

  # special case for generators, print where generator came from
  upvar #0 icon_$cur_s g_data
  if {[use_first g_data(generator)] != ""} {
    # this is a generator.
    set genname [lindex [split_filename [use_first g_data(generator)]] 1]
    if {[info exists auto_index(SCHEMATIC_$genname)]} {
      set dir [file dirname [lindex $auto_index(SCHEMATIC_$genname) 1]]/
    }
  }

  set ps_file "$dir$prefix[get_rootname $cur_s]$SUFFIX(postscript)"

  if {$PRINT(MODE) == "print"} {
    # special case for print.  User might not have write access to this dir.

    if {([file exists $ps_file] && ![file writable $ps_file]) || \
          ![file writable $dir]} {
      # use /tmp
      set ps_file "/tmp/$prefix[get_rootname $cur_s]$SUFFIX(postscript)"
    }
  }

  set save_scale $scale

  # scale for the camera
  scale_canvas 10

  if {$PRINT(TYPE) == "permanent"} {

    # To erase the grid and make hightlighted things appear normally
    set COLORMAP($COLORS(background)) {1.0 1.0 1.0 setrgbcolor}
    set COLORMAP($COLORS(fore)) {0.0 0.0 0.0 setrgbcolor}
    set COLORMAP($COLORS(grid)) {1.0 1.0 1.0 setrgbcolor}
    set COLORMAP($COLORS(active)) {0.0 0.0 0.0 setrgbcolor}
    set COLORMAP($COLORS(selected,active)) {0.0 0.0 0.0 setrgbcolor}
    set COLORMAP($COLORS(selected)) {0.0 0.0 0.0 setrgbcolor}

    $cur_c delete tmp

  } else {
    # pick distinct shades for the grid, selected, etc
    set COLORMAP($COLORS(background)) {1.0 1.0 1.0 setrgbcolor}
    set COLORMAP($COLORS(fore)) {0.0 0.0 0.0 setrgbcolor}
    set COLORMAP($COLORS(grid)) {0.9 0.9 0.9 setrgbcolor}
    set COLORMAP($COLORS(active)) {0.0 0.0 0.0 setrgbcolor}
#    set COLORMAP($COLORS(selected)) {0.7 0.7 0.7 setrgbcolor}
    set COLORMAP($COLORS(selected)) {[8] 8 setdash}
    set COLORMAP($COLORS(selected,active)) $COLORMAP($COLORS(selected))

  }

  # change the color/type of the icons and wires. Need unique colors.
  if {$PRINT(TYPE) == "permanent"} {
    set ICON_COLOR grey31
    set COLORMAP($ICON_COLOR) $PRINT(ICON_COLOR)
    show_color icon $ICON_COLOR

    set WIRE_COLOR grey30
    set COLORMAP($WIRE_COLOR) $PRINT(WIRE_COLOR)
    show_color icon $WIRE_COLOR

    # hide any icons that the user doesn't want to be printed
    # NOTE: connection dots will still be visible
    set ids ""
    foreach type [use_first PRINT(DONT_PRINT_ICONS)] {
      foreach id [$cur_c find withtag icon_$type] {
	show_color inst$id $COLORS(background)
      }
    }
  }

  # the postscript routine needs a little help to get the size right.
  $cur_c addtag print all
  $cur_c dtag grid print
  setl {x1 y1 x2 y2} [$cur_c bbox print]
  $cur_c dtag print

  # if size is 0 or nil, punt
  if {$x2 == $x1 || $y2 == $y1} {
    puts "Aborting print, schematic empty."

    ready
    return
  }
    
  set dx [expr $x2 - $x1]
  set dy [expr $y2 - $y1]

  if {$PRINT(ORIENT) == 2} {
    # decide which way would give a larger picture
    if {$dx > $dy} {
      # landscape
      set orient 1
    } else {
      # portrait
      set orient 0 
    }
  } else {
    set orient $PRINT(ORIENT)
  }

  set ratio [expr 1.0 * $PRINT(SIZEX,$orient) / $PRINT(SIZEY,$orient)]

  if {$orient} {
    # landscape
    set yratio [expr 1.0 * $PRINT(WIDTH) / ($PRINT(WIDTH) - $PRINT(MARGIN))]
    set xratio [expr 1.0 * $PRINT(HEIGHT) / ($PRINT(HEIGHT) - $PRINT(MARGIN))]

  } else {
    # portrait
    set xratio [expr 1.0 * $PRINT(WIDTH) / ($PRINT(WIDTH) - $PRINT(MARGIN))]
    set yratio [expr 1.0 * $PRINT(HEIGHT) / ($PRINT(HEIGHT) - $PRINT(MARGIN))]
  }

  if {[expr $dx * 1.0/$PRINT(SIZEX,$orient)] > \
	  [expr $dy * 1.0 / $PRINT(SIZEY,$orient)]} {
    # x direction is limiting

    # must compute the y direction to give correct page dimensions
    set xwidth [expr $dx * $xratio]
    set xstart [expr ($x1 + $x2 - $xwidth) / 2]
    set ywidth [expr $dx * $yratio / $ratio]
    set ystart [expr ($y1 + $y2 - $ywidth) / 2]

    set ps_scale "-pagewidth $PRINT(SIZEX,$orient)i"

  } else {
    # y direction is limiting

    # must compute the x direction to give correct page dimensions
    set xwidth [expr $dy * $xratio * $ratio]
    set xstart [expr ($x1 + $x2 - $xwidth) / 2]
    set ywidth [expr $dy * $yratio]
    set ystart [expr ($y1 + $y2 - $ywidth) / 2]

    set ps_scale "-pageheight $PRINT(SIZEY,$orient)i"
  }

  set ps_bbox "-x $xstart -width $xwidth -y $ystart -height $ywidth"

  # If fonts aren't different sizes on screen, they will look broken
  # Size the postscript font exactly
  set fontmap($FONT(large,$scale)) \
    "Helvetica-Bold [expr $PRINT(font_scale)*$scale*$FONT(large)]" 
  set fontmap($FONT(small,$scale)) \
    "Helvetica-Bold [expr $PRINT(font_scale)*$scale*$FONT(small)]" 
  set fontmap($FONT(standard,$scale)) \
    "Helvetica-Bold [expr $PRINT(font_scale)*$scale]" 
  set fontmap($FONT(very-large,$scale)) \
    "Helvetica-Bold [expr $PRINT(font_scale)*$scale*$FONT(very-large)]" 
  set fontmap($FONT(very-small,$scale)) \
    "Helvetica-Bold [expr $PRINT(font_scale)*$scale*$FONT(very-small)]" 

  if {$PRINT(EXACT_BBOX) == 1} {
    set ps_bbox "-x $x1 -width $dx -y $y1 -height $dy"
  }

# puts "$ps_scale $ps_bbox"

  # do it
  eval $cur_c postscript -file $ps_file -rotate $orient \
      -colormap COLORMAP -fontmap fontmap $ps_scale $ps_bbox

  if {$PRINT(TYPE) == "permanent"} {
    # restore icons/wires to normal color, and reselect to get the color back
    show_color icon $COLORS(fore)
    show_color wire $COLORS(fore)

    show_color selected $COLORS(selected)

  } else {
    # restore colors
    show_color selected $COLORS(selected)
  }

  # TODO: scale based on page size
  switch $PRINT(PAGES) {
    2 { 
      # two possibilities: -- or ||
      if {[expr 1.0 * $dy/$dx] > 2.6 || [expr 1.0 * $dx/$dy] > 2.6} {
	# long skinny drawing
	catch {exec $SUE_DIR/$SUE_BIN/pstops \
		   "1:0@2(-10cm,-0.5cm),0@2(-10cm,-27.4cm)" \
		   $ps_file ${ps_file}x} 
      } else {
	# normal drawing
	catch {exec $SUE_DIR/$SUE_BIN/pstops \
		   "1:0R@1.42(0,30cm),0R@1.42(-20.7cm,30cm)" \
		   $ps_file ${ps_file}x} 
      }

      catch {exec mv ${ps_file}x $ps_file}
    }
    4 { 
      # three possibilities: ---- or |||| or ==
      catch {exec $SUE_DIR/$SUE_BIN/pstops \
		 "1:0@2.0(-0.5cm,-0.5cm),0@2.0(-21.1cm,-0.5cm),0@2.0(-0.5cm,-27.4cm),0@2.0(-21.1cm,-27.4cm)" \
		 $ps_file ${ps_file}x} 
      catch {exec mv ${ps_file}x $ps_file}
    }
  }

  if {$PRINT($PRINT(PAGE_SIZE),SIZE) != "8.5in 11in"} {
    # need to resize
    setl {w h} $PRINT($PRINT(PAGE_SIZE),SIZE)
    catch {exec $SUE_DIR/$SUE_BIN/psresize -q -w$w -h$h $ps_file ${ps_file}x} 
    catch {exec mv ${ps_file}x $ps_file}
  }

  # restore
  scale_canvas $save_scale

  if {$PRINT(MODE) == "print"} {
    set PRINT(COMMAND) [use_first PRINT(COMMAND) PRINT($PRINT(PAGE_SIZE),COMMAND)]
    set print [format "$PRINT(COMMAND) &" $ps_file]

    if {[is_icon $cur_s]} {
      puts "Sent postscript for icon \"[get_rootname $cur_s]\" to printer with command \"$print\"."
    } else {
      puts "Sent postscript for schematic \"$cur_s\" to printer with command \"$print\"."
    }

    catch {eval exec $print}
    
  } else {
    # sent to file
    if {[is_icon $cur_s]} {
      puts "Wrote postscript for icon \"[get_rootname $cur_s]\" to file $ps_file"
    } else {
      puts "Wrote postscript for schematic \"$cur_s\" to file $ps_file"
    }
  }
  
  ready
}


# Walk the hierachy, printing as you go.

proc print_and_leaves {schematic} {

  global PRINT_SCHEMS SUE_DIR PRINT

  set tmp "\n    "

  set button [tk_dialog .print_leaves "Print and Descendents" \
		  "Do you want to print this schematic and all descendents except for those in the directories: \n    [join $PRINT(DONT_PRINT_DIRS) $tmp]" \
		  @$SUE_DIR/sue_icon.xbm 1 {ok} {cancel}]
  if {$button == 1} {
    # user hit the cancel key
    puts "Aborting print and descendents."
    return
  }

  catch {unset PRINT_SCHEMS}

  print_and_leaves_int [get_rootname $schematic]

  # leave the user back where he started
  goto_schematic $schematic

  puts "Done."
}


proc print_and_leaves_int {schematic} {

  global cur_s cur_c PRINT_SCHEMS SUE PRINT auto_index

  if {[info exists PRINT_SCHEMS($schematic)]} {
    # already been here
    return
  }

  set PRINT_SCHEMS($schematic) traced

  set schem 0
  # if the schematic is not in a canvas, first see if it is in a
  # don't print directory before pushing into it.
  if {[info_proc SCHEMATIC_$schematic] != ""} {
    if {![info exists SUE($schematic)]} {
      # there is a schematic but it isn't yet in a canvas
      # get the directory out of the auto_index
      set dir [file dirname \
		   [lindex [use_first auto_index(SCHEMATIC_$schematic)] 1]]
      if {[lsearch $PRINT(DONT_PRINT_DIRS) $dir] != -1} {
	# don't print, including leaves
	return
      }
    }

    # goto to the schematic.
    goto_schematic $schematic
    update

    upvar #0 SUE_$schematic schem_array

    if {[info exists SUE($schematic)]} {
      # don't mess with this if it is in a "don't print" directory
      if {[lsearch $PRINT(DONT_PRINT_DIRS) \
	       [string trimright $schem_array(dir) /]] != -1} {
	return
      }
      
      # puts "printing schematic $schematic"
      make_ps
      set schem 1
    }
  }

  # if the icon is not in a canvas, first see if it is in a
  # don't print directory or has a printed schematic before pushing into it.
  set skip_icon 0
  if {[info_proc ICON_$schematic] != "" && \
	  ![info exists SUE(ICON_$schematic)]} {
    if {$schem && $PRINT(SCHEM_ONLY)} {
      # don't need to print
      set skip_icon 1
    } else {
      set dir [file dirname \
		   [lindex [use_first auto_index(ICON_$schematic)] 1]]
      if {[lsearch $PRINT(DONT_PRINT_DIRS) $dir] != -1} {
	# don't print
	set skip_icon 1
      }
    }
  }

  if {!$skip_icon} {
    goto_schematic ICON_$schematic

    upvar #0 SUE_ICON_$schematic icon_array

    if {[info exists SUE(ICON_$schematic)] && \
	    ($schem != 1 || $PRINT(SCHEM_ONLY) != 1)} {
      # don't mess with this if it is in a "don't print" directory
      if {[lsearch $PRINT(DONT_PRINT_DIRS) \
	       [file dirname $icon_array(dir)]] != -1} {
	return
      }

      # puts "printing icon $schematic"
      if {$schem} {
	make_ps ICON_
      } else {
	make_ps
      }
    }
  }
  
  # no schematic so don't have to print it's leaves
  if {![info exists SUE($schematic)]} {
    return
  }

  upvar #0 SUE_$schematic schem_array
  set canvas $schem_array(canvas)

  foreach id [$canvas find withtag origin] {
    upvar #0 ${schematic}_inst${id} i_data
    # the type is really the instance name
    set type $i_data(type)

    # don't bother with primitives
    upvar #0 icon_$type g_data
    if {[info exists g_data(_primitive)]} {
      continue
    }

    print_and_leaves_int $type
  }
}


# make a toplevel print setup menu

proc print_setup {} {

  global WIN WIN_DATA PRINT command

  set win .print_setup
  set message "Print Setup"

  copy_array save_print PRINT 

  # toast old one if it is there
  catch "destroy $win"

  toplevel $win 

  wm geometry $win [relative_origin]
  wm resizable $win 0 0
  wm title $win $message
    

#  label $win.note -text "Select Critical Path:"
#  pack $win.note -side top

  # mode
  set frame $win.mode
  frame $frame

  set PRINT(COMMAND) [use_first PRINT(COMMAND) PRINT($PRINT(PAGE_SIZE),COMMAND)]
  entry $frame.command -textvariable PRINT(COMMAND) \
      -relief sunken -bd 2 -highlightthickness 1 -width 25

  radiobutton $frame.print -text "print" \
      -variable PRINT(MODE) -value print -anchor w
  radiobutton $frame.file -text "print to file" \
      -variable PRINT(MODE) -value file -anchor w

  pack $frame.command -side right -fill x -anchor n -expand 1
  pack $frame.print -side top -fill x
  pack $frame.file $frame.file -side top -fill x

  pack $frame -side top -anchor w

  frame $win.separator0 -relief sunken -bd 1
  pack $win.separator0 -side top -anchor w -expand 1 -fill x \
      -pady 1m -ipady 1

  # orientation
  set frame $win.orient
  frame $frame

  radiobutton $frame.2 -text "largest orientation" \
       -variable PRINT(ORIENT) -value 2 -anchor w
  radiobutton $frame.1 -text "landscape" \
       -variable PRINT(ORIENT) -value 1 -anchor w
  radiobutton $frame.0 -text "portrait" \
       -variable PRINT(ORIENT) -value 0 -anchor w

  pack $frame.2 $frame.1 $frame.0 -side top -fill x
  pack $frame -side top -anchor w

  frame $win.separator1a -relief sunken -bd 1
  pack $win.separator1a -side top -anchor w -expand 1 -fill x \
      -pady 1m -ipady 1

  # page size
  set frame $win.size
  frame $frame

  set PRINT(last) $PRINT(PAGE_SIZE)
  foreach page $PRINT(PAGE_SIZES) {
    set lower [string tolower $page]
    radiobutton $frame.$lower -text "$page size ($PRINT($page,SIZE))" \
	-variable PRINT(PAGE_SIZE) -value $page -anchor w \
	-command "switch_page $page"

    pack $frame.$lower -side top -fill x
  }
  pack $frame -side top -anchor w

  frame $win.separator1 -relief sunken -bd 1
  pack $win.separator1 -side top -anchor w -expand 1 -fill x \
      -pady 1m -ipady 1

  # pages per schematic
  set frame $win.pages
  frame $frame

  radiobutton $frame.1 -text "1 page per schematic" \
      -variable PRINT(PAGES) -value 1 -anchor w
  radiobutton $frame.2 -text "2 pages per schematic" \
      -variable PRINT(PAGES) -value 2 -anchor w
  radiobutton $frame.4 -text "4 pages per schematic" \
      -variable PRINT(PAGES) -value 4 -anchor w 

  pack $frame.1 $frame.2 $frame.4 -side top -fill x
  pack $frame -side top -anchor w

  frame $win.separator2 -relief sunken -bd 1
  pack $win.separator2 -side top -anchor w -expand 1 -fill x \
      -pady 1m -ipady 1

  # type
  set frame $win.type
  frame $frame

  radiobutton $frame.1 -text "permanent features only" \
       -variable PRINT(TYPE) -value permanent -anchor w
  radiobutton $frame.0 -text "everything" \
       -variable PRINT(TYPE) -value everything -anchor w

  pack $frame.1 $frame.0 -side top -fill x
  pack $frame -side top -anchor w

  frame $win.separator3a -relief sunken -bd 1
  pack $win.separator3a -side top -anchor w -expand 1 -fill x \
      -pady 1m -ipady 1

  # print and descendents control
  set frame $win.desc
  frame $frame

  label $frame.label -text "Print and descendents control:"
  radiobutton $frame.1 -text "schematics only" \
       -variable PRINT(SCHEM_ONLY) -value 1 -anchor w
  radiobutton $frame.0 -text "schematics and icons" \
       -variable PRINT(SCHEM_ONLY) -value 0 -anchor w

  pack $frame.label $frame.1 $frame.0 -side top -fill x
  pack $frame -side top -anchor w

  frame $win.separator3 -relief sunken -bd 1
  pack $win.separator3 -side top -anchor w -expand 1 -fill x \
      -pady 1m -ipady 1

  # bbox
  set frame $win.bbox
  frame $frame

  label $frame.label -text "For inclusion into documents:"
  radiobutton $frame.1 -text "margins" \
       -variable PRINT(EXACT_BBOX) -value 0 -anchor w
  radiobutton $frame.0 -text "exact bounding box" \
       -variable PRINT(EXACT_BBOX) -value 1 -anchor w

  pack $frame.label $frame.1 $frame.0 -side top -fill x
  pack $frame -side top -anchor w

  frame $win.separator4 -relief sunken -bd 1
  pack $win.separator4 -side top -anchor w -expand 1 -fill x \
      -pady 1m -ipady 1

  # put in "Done", "Cancel", and "Reset" buttons
  frame $win.buttons

  frame $win.default -relief sunken -bd 1
  button $win.done -text "Done" -padx 1 -pady 1 \
      -command {set command 1}
  pack $win.done -in $win.default -padx 1m -pady 1m -ipadx 2m
  pack $win.default -side left -in $win.buttons \
      -padx 1m -ipadx 1m -pady 1m -expand 1

  button $win.print -text "Print" -padx 1 -pady 1 \
      -command {set command print}
  pack $win.print -side left -in $win.buttons \
      -padx 1m -ipadx 2m -pady 1m -expand 1

  button $win.cancel -text "Cancel" -padx 1 -pady 1 \
      -command {set command 0}
  pack $win.cancel -side left -in $win.buttons \
      -padx 1m -ipadx 2m -pady 1m -expand 1

  button $win.reset -text "Reset" -padx 1 -pady 1 \
      -command {set command reset}
  pack $win.reset -side left -in $win.buttons \
      -padx 1m -ipadx 2m -pady 1m -expand 1

  pack $win.buttons -side top

  # change the cursor and add a message
  update

  set cursor [lindex [$WIN configure -cursor] 4]
  $WIN configure -cursor question_arrow
  set WIN_DATA($WIN,display_msg) "?:  [lindex [split $message \n] 0]"

  grab set $win

  bind $win <Control-c> {set command 0}
  bind $win <Escape> {set command 0}
  bind $win <Return> {set command 1}

  bind $win <Visibility> "if {{%s} == {VisibilityFullyObscured}} {raise $win}"

  tkwait variable command
  while {$command == "reset"} {
    # user hit reset, restore PRINT array
    unset PRINT
    copy_array PRINT save_print
    
    set PRINT(COMMAND) $PRINT($PRINT(PAGE_SIZE),COMMAND)

    tkwait variable command
  }

  catch "destroy $win"

  focus -force $WIN

  # restore
  $WIN configure -cursor $cursor
  display_selection

  set PRINT($PRINT(PAGE_SIZE),COMMAND) $PRINT(COMMAND)

  if {$command == 0} {
    # user hit cancel, restore PRINT array
    unset PRINT
    copy_array PRINT save_print
  }

  if {$command == "print"} {
    # print 
    make_ps
  }

  return $command
}


# weird procedure needed to make the print command change correctly

proc switch_page {size} {

  global PRINT

  set PRINT(PAGE_SIZE) $size

  set PRINT($PRINT(last),COMMAND) $PRINT(COMMAND)
  set PRINT(COMMAND) $PRINT($size,COMMAND)
  set PRINT(last) $PRINT(PAGE_SIZE)
}
