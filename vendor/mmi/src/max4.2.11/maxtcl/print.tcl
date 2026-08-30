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

set RCSVERSION(print.tcl) { $Revision: 1.24 $ }


# The PRINT array is used to store variables used in plotting
# layouts to the HP Color Plotter using gdsplot, and to the
# LaserWriter Printers using plotps and for hyperplot.

### COMMON ###

#set PRINT(types) "plotps gdsplot"
#set PRINT(types) "hyperplot"
set PRINT(types) "gdsplot"

#Type of plot selected
#set PRINT(type) hyperplot
set PRINT(type) gdsplot

proc print_cell {} -desc {
  prompts user for setup, and prints the current cell
} {

  global PRINT

  if {[info commands print_$PRINT(type)] != ""} {
    # call the desired print routine
    print_$PRINT(type)
    return 1
  } else {
    msg "Aborting, can't find print routines for $PRINT(type).\n"
    return 0
  }
}

proc print_plotps {} -desc {
  prompts user to print the current cell to postcript printer (or file)
} {

    global max_win PRINT

    #Printer for Plotps to use
    set PRINT(plotps,printer) [use_first PRINT(plotps,printer) 'lp]

    #Comma sep. string of layers for plotps to plot
    set PRINT(plotps,layers) [use_first PRINT(plotps,layers) 'all]

    #cif_plot_setup return (1=Plot, 0=Cancel)
    set PRINT(plotps,return_val) [use_first PRINT(plotps,return_val) '-1]

    #cif ostyle to use in generating .cif file input to Plotps
    #if not set, just uses current ostyle.
    # PRINT(plotps,ostyle)

    #yes/no button for each layer
    # PRINT(plotps,yes_no_$name) 

    #output to file or printer ?
    set PRINT(plotps,file_or_print) \
	[use_first PRINT(plotps,file_or_print) 'print]

    set cell [lay_rootcell]

    # ostyles
    set orig_ostyle [cif_ostyle]
    if {[info exists PRINT(plotps,ostyle)]} {
	set print_ostyle $PRINT(plotps,ostyle)
    } else {
	set print_ostyle $orig_ostyle
    }
    
    #compute layer list for plotps ostyle 
    cif_ostyle $print_ostyle
    set PRINT(plotps,layer_list) {}
    foreach layer [split [cif_layers] \n] {
	setl {name calma_num calma_type flags} $layer 
	if {![memq temp $flags]} {
	    lappend PRINT(plotps,layer_list) $name
	    set PRINT(plotps,yes_no_$name) 1
	}
    }
    cif_ostyle $orig_ostyle

    # prompt user for layers to plot etc.
    set win $max_win.layout
    set winy [expr [winfo rooty $win] + 50]
    set winx [expr [winfo rootx $win] + 50]
    set title "Plotps Setup"
    set message "Enter print parameters:" 
    if { [_print_plotps_setup $winx $winy $message $title] == 0 } { 
	return
    }

    # find pattern and prolog files for plotps 
    set pat [max_tech_path plotps_pat]
    if { $pat == "" } {
	error "Aborting plot.  (Could not find .plotps_pat file)\n"
    }
    set pro [max_tech_path plotps_pro]
    if { $pat == "" } {
	error "Aborting plot.  (Could not find .plotps_pro file\n"
    }

    # write the cif
    set temp_dir "/tmp/max_[pid]"
    catch "exec rm -rf $temp_dir"
    exec mkdir $temp_dir
    set cif_file "$temp_dir/$cell.cif"
    cif_ostyle $print_ostyle
    if {[msg_catch ":cif write $cif_file" msg]} {
	cif_ostyle $orig_ostyle
	catch "exec rm -rf $temp_dir"
	error $msg
    } 
    cif_ostyle $orig_ostyle

    # compute list of layers NOT to plot from:
    #      PRINT(plotps,layers) = layers to plot, and
    #      PRINT(plotps,layer_list) = all layers
    set dont_plot ""
    if {$PRINT(plotps,layers) != "ALL"} {
	foreach i $PRINT(plotps,layer_list) {
	    if {[string first $i $PRINT(plotps,layers)] == -1} {
		if {$dont_plot == ""} {
		    set dont_plot $i
		} else {
		    set dont_plot "$dont_plot,$i"
		}
	    }
	}
    }
    if {$dont_plot != ""} {
	set dont_plot "-l $dont_plot"
    }

    # destination flag
    if {$PRINT(plotps,file_or_print) == "file"} {
	set fname $PRINT(plotps,file_name)
	if { [string first / $fname] == -1 } {
	    # if no explicit dir, use same dir as cell being printed
	    set dir [file dirname [lindex [cell_info $cell] 1]]
	    set fname $dir/$fname
	}
	set dest "-k $fname"
    } else  {
	set dest "-P$PRINT(plotps,printer)"
    }

    # setup tcl script to run plotps and then rm temp dir 
    # (done as subprocess so we don't have to wait)
    # TODO fix plotps to exit(0) and remove "child process ..." filter below
    set script \
"
    set code \[catch \"exec plotps -f 10 -I -Dmdyh -p $pat -fp $pro $dont_plot $dest $cif_file\" msg\]
if { \$code != 0 && \$msg != \"child process exited abnormally\" } {puts \$msg}
    
    catch \"exec rm -rf $temp_dir\"
"
    # fireup subprocess
    if {[msg_catch [list exec mmi_tclsh << $script &] msg]} {
	puts "Plotps Error: $msg"
	catch "exec rm -rf $temp_dir"
    } else {
	puts "Plotps running in the background."
    }
}

proc _print_plotps_setup {x y message title} -desc {
pop up dialog window for plotps parameters
} {
  global PRINT

  # Just in case there is an old one around
  catch {destroy .plotps_setup}

  # Set up the window geometry
  toplevel .plotps_setup
  wm geometry .plotps_setup "+$x+$y"
  wm minsize .plotps_setup 200 100
  wm title .plotps_setup $title

  # bind Ctrl-C to Cancel the Plot
  bind .plotps_setup <Control-c> {set PRINT(plotps,return_val) 0}

  # Set up the Frames and Pack Them
  frame .plotps_setup.select_printer -borderwidth 4
  frame .plotps_setup.select_layers -borderwidth 4
  frame .plotps_setup.blank_1 -relief sunken -borderwidth 4
  frame .plotps_setup.select_layers.button_1
  frame .plotps_setup.select_layers.button_2
  frame .plotps_setup.select_layers.button_3
  frame .plotps_setup.select_layers.button_4
  frame .plotps_setup.blank_2 -relief sunken -borderwidth 4
  frame .plotps_setup.go_can_buttons -borderwidth 4
  pack .plotps_setup.select_printer -side top
  pack .plotps_setup.blank_1 -side top -pady 4
  pack .plotps_setup.select_layers -side top
  pack .plotps_setup.blank_2 -side top -pady 4
  pack .plotps_setup.go_can_buttons -side top

  # Entry for which printer to send the job to (or file).
  set m .plotps_setup.select_printer

  radiobutton $m.printer \
      -text "Printer:"\
      -variable PRINT(plotps,file_or_print) \
      -value print
  pack $m.printer -side left
  entry $m.printer_value -width 20 -relief sunken -bd 2 \
      -textvariable PRINT(plotps,printer)
  pack $m.printer_value -side left

  set PRINT(plotps,file_name) [lay_rootcell].ps

  radiobutton $m.file \
      -text "File:"\
      -variable PRINT(plotps,file_or_print) \
      -value file
  pack $m.file -side left
  entry $m.file_name -width 20 -relief sunken -bd 2 \
      -textvariable PRINT(plotps,file_name)
  pack $m.file_name -side left

  # Layer selection buttons, checkbutton for each layer, ALL will turn all on.
  label .plotps_setup.select_layers.label -text "Select Layers to Plot"
  pack .plotps_setup.select_layers.label -side top
  button .plotps_setup.select_layers.all_lays -text "ALL"\
    -command {
      foreach layer $PRINT(plotps,layer_list) {
        set PRINT(plotps,yes_no_$layer) 1
      }
    }
  pack .plotps_setup.select_layers.all_lays -side bottom
  pack .plotps_setup.select_layers.button_1 -side left -padx 4 -fill y
  pack .plotps_setup.select_layers.button_2 -side left -padx 4 -fill y
  pack .plotps_setup.select_layers.button_3 -side left -padx 4 -fill y
  pack .plotps_setup.select_layers.button_4 -side left -padx 4 -fill y
  set local_count 0
  foreach layer $PRINT(plotps,layer_list) {
    if {[expr $local_count % 4] == 0} {
      checkbutton .plotps_setup.select_layers.button_1.l_$layer -text $layer -variable PRINT(plotps,yes_no_$layer)
      pack .plotps_setup.select_layers.button_1.l_$layer -side top -ipadx 4 -ipady 2 -anchor nw
      set local_count [expr $local_count + 1]
    } elseif {[expr $local_count % 4] == 1} {
      checkbutton .plotps_setup.select_layers.button_2.l_$layer -text $layer -variable PRINT(plotps,yes_no_$layer)
      pack .plotps_setup.select_layers.button_2.l_$layer -side top -ipadx 4 -ipady 2 -anchor nw
      set local_count [expr $local_count + 1]
    } elseif {[expr $local_count % 4] == 2} {
      checkbutton .plotps_setup.select_layers.button_3.l_$layer -text $layer -variable PRINT(plotps,yes_no_$layer)
      pack .plotps_setup.select_layers.button_3.l_$layer -side top -ipadx 4 -ipady 2 -anchor nw
      set local_count [expr $local_count + 1]
    } else {
      checkbutton .plotps_setup.select_layers.button_4.l_$layer -text $layer -variable PRINT(plotps,yes_no_$layer)
      pack .plotps_setup.select_layers.button_4.l_$layer -side top -ipadx 4 -ipady 2 -anchor nw
      set local_count [expr $local_count + 1]
    }
  }

  # OK and Cancel buttons.  These are the only way out of this window other
  # than hitting a Ctrl-C, which is the same as Cancel.
  button .plotps_setup.go_can_buttons.ok -text "OK"\
    -command {
      set plot_all_layers 1
      set PRINT(plotps,layers) ""
      foreach layer $PRINT(plotps,layer_list) {
        set temporary PRINT(plotps,yes_no_$layer)
        if {[eval set $temporary] == 1} {
          if {$PRINT(plotps,layers) == ""} {
            set PRINT(plotps,layers) $layer
          } else {
            set PRINT(plotps,layers) [format "%s,%s" $PRINT(plotps,layers) $layer]
          }
        } else {
          set plot_all_layers 0
        }
      }
      if {$plot_all_layers == 1} {
        set PRINT(plotps,layers) "ALL"
      }
      set PRINT(plotps,return_val) 1
    }
  pack .plotps_setup.go_can_buttons.ok -side left
  button .plotps_setup.go_can_buttons.cancel -text "Cancel"\
    -command {set PRINT(plotps,return_val) 0}
  pack .plotps_setup.go_can_buttons.cancel -side left

  # This window will grab when invoked.  It will wait for
  # PRINT(plotps,return_val) to be modified (i.e. either OK,
  # Ctrl-C or Cancel are hit).  It will then return the
  # value of PRINT(plotps,return_val) where a 1 indicates
  # to complete the plot using the values in PRINT(plotps,layers)
  # and PRINT(plotps,length), and a 0 indicates Cancel the
  # Plot.
  grab set .plotps_setup
  cursor_wait .plotps_setup 1 "Plotps setup"
  tkwait variable PRINT(plotps,return_val)
  cursor_wait .plotps_setup 0
  catch {destroy .plotps_setup}
  update
  return $PRINT(plotps,return_val)
}  


proc print_ps {} -desc {
generates a ps file of what the user would see if they did a zoom to fit
} {

  global COLORMAP

  setl {x1 y1 x2 y2} [lay_bbox]

  if {$x1 == $x2 || $y1 == $y2} {
    puts "Aborting, nothing to print."
    return
  }

  # TODO select what is in frame with current visibility
  # copy _SELECT_ to _PRINT_ and then continue

  set cell [lay_rootcell]
  set name [file rootname [lindex [cell_info $cell] 1]]
  if {$name == ""} {
    set name $cell
  }
  set filename $name.ps

  puts "Writing postscript of cell \"$cell\" to file \"$filename\"..."

  # open the ps file for writing
  if {[catch "open $filename w" FILE_ID]} {
    # problem
    puts "Aborting: $FILE_ID"
    return
  }

  puts $FILE_ID "%!PS-Adobe-3.0 EPSF-3.0"
  puts $FILE_ID "%%Creator: max on \"[clock format [clock seconds]]\""
  puts $FILE_ID "%%Title: $cell\n"

  puts $FILE_ID "/box \{"
  puts $FILE_ID "  newpath"
  puts $FILE_ID "  3 index 3 index moveto"
  puts $FILE_ID "  3 index 1 index lineto"
  puts $FILE_ID "  1 index 1 index lineto"
  puts $FILE_ID "  1 index 3 index lineto"
  puts $FILE_ID "  pop pop pop pop"
  puts $FILE_ID "  closepath"
  puts $FILE_ID "  fill"
  puts $FILE_ID "  stroke"
  puts $FILE_ID "\} def\n"

  sel_area -layers [join [concat labels [dbt_visible_layers]] ,] $x1 $y1 $x2 $y2

  set xmargin [expr ($x2 - $x1) * 0.1]
  set x1 [expr $x1 - $xmargin]
  set x2 [expr $x2 + $xmargin]
  set ymargin [expr ($y2 - $y1) * 0.1]
  set y1 [expr $y1 - $ymargin]
  set y2 [expr $y2 + $ymargin]

  # only does portrait for now
  set width 8.5
  set height 11
  set pixels_per_inch 72

  set dx [expr $pixels_per_inch * $width / ($x2 - $x1)]
  set dy [expr $pixels_per_inch * $height / ($y2 - $y1)]
  set scale [min $dx $dy]

  puts $FILE_ID "1 1 /Helvetica 10 42.9 INIT"

  puts $FILE_ID [format "%g %g scale" $scale $scale]

  puts $FILE_ID [format "%g %g translate" [expr 0 - $x1] [expr 0 - $y1]]

  puts $FILE_ID ""

  set last_layer ""

  # add manhattans
  foreach paint [split [sel_what paint] \n] {
    setl {layer x1 y1 x2 y2} $paint

    if {$last_layer != $layer} {
      # setup color for this layer
      set color [lindex [lay_style [lindex [lay_layer_styles $layer] 0]] 1]
      foreach value $COLORMAP([expr 0 + $color]) {
	puts -nonewline $FILE_ID [format "%.2g " [expr $value / 255.0]]
      }
      puts $FILE_ID "setrgbcolor"
      set last_layer $layer
    }

    puts $FILE_ID "$x1 $y1 $x2 $y2 box"
  }

  # add labels
  foreach label [split [sel_what labels] \n] {
    setl {layer x1 y1 x2 y2 dir text} $label

    puts $FILE_ID "$x1 $y1 $x2 $y2 moveto ($text)"
  }

  puts $FILE_ID "showpage"

  # close the file
  close $FILE_ID

  sel_clear

  puts "done."
}


proc print_hyperplot {{batch ""}} -desc {
  prompts user to plot the current cell to hp rtl printer (or file)
} {

  global PRINT MN_TECH COLORMAP PAL_DATA CELL env max_win GDS_WRITE_LIB_NAME

  if {[regexp {\(|\)} [lay_rootcell]]} {
    set message "Aborting, illegal cell name for plotting \"[lay_rootcell]\".  Can't contain ()'s.  Please change name and try again."
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK

    return
  }

  # TODO should change depending of plotter selected
  set PRINT(hyperplot,size) [use_first PRINT(hyperplot,size) '10]

  # get hyperplot path
  if {[info exists PRINT(hyperplot,path)] && \
	  [file isdir $PRINT(hyperplot,path)]} {
    # got path
    set path $PRINT(hyperplot,path)

  } else {
    # look for it in the path
    set path ""
    catch "exec which hyperplot" msg
    foreach line [split $msg \n] {
      if {[string first hyperplot $line] != -1} {
	set path [file dirname [file dirname [file dirname $line]]]
	break
      }
    }
  }

  if {$path == ""} {
    set message "Aborting, can't find path hyperplot.  Probably not installed.  If installed, set PRINT(hyperplot,path) variable to point to it.  Otherwise, install it and try again."
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK

    return
  }

  if {[string first "$path/src/bin" $env(PATH)] == -1} {
    # not installed
    set message "Aborting, hyperplot not in your path.  Install it and try again."
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK

    return
  }

  set PRINT(hyperplot,path) $path

  puts "Using hyperplot in directory \"$path\""

  # get plotters
  if {[catch "exec cat $path/setup/model.tbl" msg]} {
    # no model.tbl file
    set message "Aborting, can't find hyperplot model.tbl file in $path/setup/model.tbl"
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK

    return
  }
    
  set PRINT(hyperplot,plotters) [use_first PRINT(hyperplot,plotters)]
  set model_plotters ""

  foreach line [split $msg \n] {
    set line [string trim $line]
    if {[string index $line 0] == "*"} {
      # comment skip
      continue
    }
  
    if {[string first VERSION $line] == 0} {
      # verion line, skip
      continue
    }

    set plotter [lindex $line 0]
    set PRINT(hyperplot,$plotter,driver) [lindex $line 6]
    set driver [lindex $line 6]
    if {![info exists data(driver,$driver)]} {
      # first one of this type is default
      set data(driver,$driver) $plotter
    }

    lappend model_plotters $plotter
    if {[lsearch $PRINT(hyperplot,plotters) $plotter] == -1} {
      # remember this one
      lappend PRINT(hyperplot,plotters) $plotter
    }
  }

  if {[use_first PRINT(hyperplot,plotter)] == ""} {
    set PRINT(hyperplot,plotter) [lindex $PRINT(hyperplot,plotters) 0]
  }

  if {$PRINT(hyperplot,plotter) == ""} {
    # no plotters
    set message "Aborting, can't find any hyperplot plotters.  Check model.tbl or max variable PRINT(hyperplot,plotters)."
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK

    return
  }

  set PRINT(hyperplot,plot_to) [use_first PRINT(hyperplot,plot_to) 'plotter]
  set PRINT(hyperplot,legend) [use_first PRINT(hyperplot,legend) '1]
  set PRINT(hyperplot,axis) [use_first PRINT(hyperplot,axis) '0]
  set PRINT(hyperplot,label) [use_first PRINT(hyperplot,label) '1]

  # menu
  if {$batch == ""} {
    # get options
    set win $max_win.layout
    set winy [expr [winfo rooty $win] + 50]
    set winx [expr [winfo rootx $win] + 50]

    set title "Hyperplot"
    set message "Select Options:" 
    set prop_list [list [list plotter $PRINT(hyperplot,plotter) popup $PRINT(hyperplot,plotters)] \
		       "height $PRINT(hyperplot,size) -number 1 200 -snap 1 -incr 0.1 -validate" \
		       "plot_to $PRINT(hyperplot,plot_to) radio {plotter file}" \
		       "legend $PRINT(hyperplot,legend) binary" \
		       "axis $PRINT(hyperplot,axis) binary" \
		      ]

    # create the menu
    set new_prop_list [prop_menu $winx $winy $message $title $prop_list]

    if {$new_prop_list == ""} {
      # empty list means the user hit cancel
      return
    }

    set PRINT(hyperplot,plotter) [get_assoc plotter $new_prop_list] 
    set PRINT(hyperplot,plot_to) [get_assoc plot_to $new_prop_list] 
    set PRINT(hyperplot,size) [get_assoc height $new_prop_list] 
    set PRINT(hyperplot,legend) [get_assoc legend $new_prop_list] 
    set PRINT(hyperplot,axis) [get_assoc axis $new_prop_list] 
  }

  # get the driver for this plotter
  set PRINT(hyperplot,default_driver) \
      [use_first PRINT(hyperplot,default_driver) 'ps]

  set driver [use_first PRINT(hyperplot,$PRINT(hyperplot,plotter),driver) \
		  PRINT(hyperplot,default_driver)]

  # size must be inches of paper
  if {[catch "expr 1 + $PRINT(hyperplot,size)"]} {
    # not a number
    set message "Aborting, plot size must be a number for height of plot in inches.  Try Again."
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK
    
    print_hyperplot
    return
  }

  # see if gds layer is used more that once.  If not, get all datatypes (0-63)
  foreach layer [split [cif_layers] \n] {
    setl {name calma_num calma_type flags} $layer 
    if {[memq temp $flags]} {
      continue
    }

    if {[string range $name 0 3] != "GDS_"} {
      # these will get plotted with their layers (except space)
      continue
    }

    if {[info exists gds($calma_num)]} {
      incr gds($calma_num)
    } else {
      set gds($calma_num) 1
    }
  }

  set layer_list ""
  set labels ""
  foreach layer [split [cif_layers] \n] {
    setl {name calma_num calma_type flags} $layer 
    if {[memq temp $flags]} {
      continue
    }

    # is there a corresponding max layer
    set max_name [string range $name 4 end]

    if {[string range $name 0 3] == "TXT_"} {
      # labels: if different gds layer must do special
      # Note: always comes after GDS_ line of layer
      if {[info exists data(GDS_$max_name,max)]} {
	# display this label
	# TODO: if same gds but different dt, problem
	if {$calma_num != $data(GDS_$max_name,gds)} {
	  # need to add separately
	  lappend labels $name
	  set data($name,gds) $calma_num
	  # TODO: check for this
	  set data($name,dt) "0-63"
	}
      }
      continue
    }

    if {[string range $name 0 3] != "GDS_"} {
      # these will get plotted with their layers (except space)
      continue
    }

    set new_name ""
    if {[catch "lay_layer_styles $max_name" msg]} {
      # must be derived
      # TODO could have a line continuation in it
      set sourcefile [max_tech_path source]
      if {[catch "exec grep -i derive $sourcefile | grep -i \" $max_name \"" msg]} {
	# can't find
	puts "Warning, skipping $name, can't determine color for."
	continue
      }

      foreach line [split $msg \n] {
	if {[lindex $line 1] == $max_name} {
	  set new_name [lindex [split [lindex $line 3] ,] 0]
	  if {[catch "lay_layer_styles $new_name" msg]} {
	    set new_name ""
	  } else {
	    # this is it
	    break
	  }
	}
      }

      if {$new_name == ""} {
	puts "Warning, skipping $name, can't determine color for."
	continue
      }

      set max_name $new_name
    }

    # is this layer currently visible
    if {![dbt_is_visible $max_name]} {
      continue
    }

    lappend layer_list $name
    set data($name,max) $max_name
    set data($name,gds) $calma_num

    if {$gds($calma_num) == 1} {
      # put in all datatypes
      set data($name,dt) "0-63"
    } else {
      set data($name,dt) $calma_type
    }
  }

  # get the directory for this plot
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

  set gds_file "$dir$cell$CELL(gds_suffix)"

  # create patterns file.  Must be called patterns.dat !
  set filename "${dir}patterns.dat"

  puts "Creating hyperplot pattern file for technology $MN_TECH ..."

  # open the output filename
  if {[catch {open $filename w} FILE_ID]} {
    puts "Aborting, can't create file $filename"
    return
  }

  # patterns.dat
  # PATTERN <pattern_number> [optional_pattern_name]
  # DPI 400
  # <<bitmap>>

  # For example, pattern # 4 has the following fill definition:
  # PATTERN 4 verticle_lines
  # DPI 200
  # X.......
  # X.......
  # X.......
  # X.......		This is an 8x8 bitmap block
  # X.......
  # X.......
  # X.......
  # X.......

  # needed by hyperplot
  puts $FILE_ID "PATTERN 1 solid"
  puts $FILE_ID "DPI 200\nxxxx\nxxxx\nxxxx\nxxxx"
  puts $FILE_ID "DPI 400\nxxxx\nxxxx\nxxxx\nxxxx"

  set stipple_num 1
  foreach layer $layer_list {
    set styles [lay_layer_styles $data($layer,max)]
    setl {mask color outline fill stipple} [lay_style [lindex $styles 0]]

    if {[lsearch [techinfo vias] $data($layer,max)] != -1} {
      # use an X
      set data($layer,fill) -3
      # use a solid outline
      set data($layer,outline) -1

      continue
    } else {
      # fill from pattern
      set data($layer,fill) -1
    }

    # convert to decimal ?
    set stipple [expr 0 + $stipple]

    if {$fill == "stipple" && $stipple > 6} {
      # this is a real stipple
      set pattern $PAL_DATA(stipple,$stipple)

      # is there an outline?
      set data($layer,outline) -2
      foreach style $styles {
	if {[string first outline [lay_style $style]] != -1} {
	  # outline
	  set data($layer,outline) -1
	  break
	}
      }

    } else {
      # solid

      # no outline
      set data($layer,outline) -2

      continue
    }

    set data($layer,stipple) [incr stipple_num]

    puts $FILE_ID "\nPATTERN $data($layer,stipple) $data($layer,max)\nDPI 200"
    # convert to X and . format from 1 and 0 and scale if necessary
    puts $FILE_ID [join [_hyperplot_pattern_bloat $pattern 2] \n]

    # bloat 2x for 400
    puts $FILE_ID "\nPATTERN $data($layer,stipple) $data($layer,max)\nDPI 400"
    puts $FILE_ID [join [_hyperplot_pattern_bloat $pattern 4] \n]
  }

  # close the output file
  close $FILE_ID

  # create colors file.  Must be called colors.dat !
  set filename "${dir}colors.dat"

  puts "Creating hyperplot color file for technology $MN_TECH ..."

  # open the output filename
  if {[catch {open $filename w} FILE_ID]} {
    puts "Aborting, can't create file $filename"
    return
  }

  # colors.dat
  # RGB_FILL <num> [<name>]
  # <R> <G> <B>

  # put in hyperplot colors
  puts $FILE_ID "RGB_FILL 1 BLACK\n0 0 0\n"
  puts $FILE_ID "RGB_FILL 2 CYAN\n0 255 255\n"
  puts $FILE_ID "RGB_FILL 3 MAGENTA\n255 0 255\n"
  puts $FILE_ID "RGB_FILL 4 YELLOW\n255 255 0\n"
  puts $FILE_ID "RGB_FILL 5 BLUE\n0 0 255\n"
  puts $FILE_ID "RGB_FILL 6 RED\n255 0 0\n"
  puts $FILE_ID "RGB_FILL 7 GREEN\n0 255 0\n"

  set color_num 7

  # put in max colors
  foreach layer $layer_list {
    set styles [lay_layer_styles $data($layer,max)]
    setl {mask color outline fill stipple} [lay_style [lindex $styles 0]]

    # convert color number to decimal
    set color [expr 0 + $color]

    set data($layer,color) [incr color_num]
    set data($layer,edge) $data($layer,color)
    puts $FILE_ID "RGB_FILL $data($layer,color) $data($layer,max)\n$COLORMAP($color)\n"

    if {[info exists data($layer,stipple)]} {
      # create a stippled color
      # MASK_FILL <new_color_number> [optional_color_name]
      # <color_num> <pattern_num>

      set data($layer,color) [incr color_num]
      puts $FILE_ID "MASK_FILL $data($layer,color) $layer\n[expr $color_num - 1] $data($layer,stipple)\n"
    }
  }

  # close the output file
  close $FILE_ID

  # create pdf file.  Main control file.
  set filename "${dir}$cell.pdf"

  puts "Creating hyperplot pdf file $filename ..."

  # open the output filename
  if {[catch {open $filename w} FILE_ID]} {
    puts "Aborting, can't create file $filename"
    return
  }

  puts $FILE_ID "VERSION 3.0"
  puts $FILE_ID "!layer polygon fill   text     edge   edge    edge     data    text      layer"
  puts $FILE_ID "! num   color  mode   color    type   width   color    type    type      name"

  foreach layer $layer_list {
    puts $FILE_ID "$data($layer,gds)\t$data($layer,color)\t$data($layer,fill)\t1\t$data($layer,outline)\t3\t$data($layer,edge)\t$data($layer,dt)\t$data($layer,dt)\t$layer"
  }

  foreach layer $labels {
    puts $FILE_ID "$data($layer,gds)\t1\t-2\t1\t-2\t1\t1\t0\t$data($layer,dt)\t$layer"
  }

  # close the output file
  close $FILE_ID

  puts "done."
  puts ""

  # save gds of cell, use the special MMI library
  set tmp $GDS_WRITE_LIB_NAME
  set GDS_WRITE_LIB_NAME MMI
  gds_write
  set GDS_WRITE_LIB_NAME $tmp
  update
  puts ""

  # setup hyperplot options
  set options ""

  if {$PRINT(hyperplot,legend)} {
    append options "-lg on "
  }

  if {[use_first PRINT(hyperplot,axis)] == 1} {
    append options "-ax on "
  }

  if {[use_first PRINT(hyperplot,label)] == 1} {
    append options "-lb on -lb_txt '($gds_file  [exec date])' "
  }

  # get size
  if {$driver == "ps" || $driver == "ps1"} {
    append options "-af "

  } else {
    append options "-i $PRINT(hyperplot,size) "
  }

  # until I understand this better
  append options "-psrchp . "

  # make sure . is in their path
  append options "-h1 0.1 -h2 0.2 -h3 0.4 -h4 0.8 "
  append options "-t $cell "
  append options "-d $dir$cell.pdf "

  # goose up the max gds layer number
  append options "-ml 255 "

  # add any user options
  append options [use_first PRINT(hyperplot,options)]

  puts "Running Hyperplot ..."

  set save_dir [pwd]
  cd $dir

  if {$PRINT(hyperplot,plot_to) == "file" || \
	  [lsearch $model_plotters $PRINT(hyperplot,plotter)] == -1} {
    # plot to file (maybe send to printer later)

    if {[lsearch $model_plotters $PRINT(hyperplot,plotter)] == -1} {
      # use a printer with this device for rasterization
      # otherwise you get the default which is ???
      if {[info exists data(driver,$driver)]} {
	append options "-p $data(driver,$driver) "
      }

    } else {
      append options "-p $PRINT(hyperplot,plotter) "
    }

    # need to get raster file
    set tmp_file "tmp[pid]"

    if {[catch "exec hyperplot -gds -nosend $options $gds_file |& tee $tmp_file >& [exec tty]" msg]} {
      cd $save_dir

      puts "MAX ERROR: Hyperplot aborted."
      puts $msg
      return
    }

    if {[catch "exec grep \"Creating rasterfile:\" $tmp_file" msg]} {
      # can't find
      puts "Aborting, can't determine rasterfile."
      return
    }

    set raster [lindex $msg 2]
    catch "exec rm -f $tmp_file"

    puts "Hyperplot Creating output file of type $driver ..."

    # now create the output file
    catch "exec mv $dir$cell.$driver $dir$cell.$driver.BAK"
    if {[catch "exec hyperout.$driver < $raster > $dir$cell.$driver" msg]} {
      cd $save_dir

      puts "MAX ERROR: Hyperplot aborted."
      puts $msg
      return
    }

    # toast the raster file
    catch "exec rm -f $raster"

    puts "Created file $dir$cell.$driver"

  } else {
    # plot directly to plotter
# puts "hyperplot -gds -p $PRINT(hyperplot,plotter) $options $gds_file"
    if {[catch "exec hyperplot -gds -p $PRINT(hyperplot,plotter) $options $gds_file >& [exec tty]" msg]} {
      cd $save_dir

      puts "MAX ERROR: Hyperplot aborted."
      puts $msg
      return
    }
  }

  if {$PRINT(hyperplot,plot_to) == "plotter" && \
	  [lsearch $model_plotters $PRINT(hyperplot,plotter)] == -1} {
    # plot the bastard -- user wanted to plot but wasn't in model.tbl
    catch "exec lpr -P$PRINT(hyperplot,plotter) $dir$cell.$driver"
    # toast the file
    catch "exec rm -f $dir$cell.$driver"
  }

  cd $save_dir

  puts "Done."
}


proc _hyperplot_pattern_bloat {stipple scale} -desc {
  bloats a hyperplot pattern by the scale factor
} {

  set Xs "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  set dots "......................................................"

  set X [string range $Xs 1 $scale]
  set dot [string range $dots 1 $scale]

  set bloat ""
  foreach row $stipple {
    regsub -all 1 $row $X row
    regsub -all 0 $row $dot row
    for {set i 0} {$i < $scale} {incr i} {
      lappend bloat $row
    }
  }

  return $bloat
}



######################################################################
######################################################################
#####################   GDSPLOT    ###################################
######################################################################
######################################################################

# TODO: scale color offsets
# TODO: run gdsplt in background???

set PEN_MATRIX(c) C
set PEN_MATRIX(m) M
set PEN_MATRIX(y) Y
set PEN_MATRIX(c,m) B
set PEN_MATRIX(m,y) R
set PEN_MATRIX(c,y) G
set PEN_MATRIX(c,m,y) K

set PRINT(A,size) 8.5,11
set PRINT(B,size) 11,17
set PRINT(C,size) 17,22
set PRINT(D,size) 22,34
set PRINT(E,size) 34,44

set "GDSPLOT_TYPES(Postscript II Color)"    "rps 256:repsplot -erstrzcol"
set "GDSPLOT_TYPES(Postscript II BW)"       "rps 2:repsplot"
set "GDSPLOT_TYPES(Postscript Color)"       "ps 8:psplot"
set "GDSPLOT_TYPES(Postscript BW)"          "ps 0:psplot"
#set "GDSPLOT_TYPES(HPGL2 8 Color)"          "hg 8:hgplot"
#set "GDSPLOT_TYPES(HPGL2 4 Color)"          "hg 4:hgplot"
#set "GDSPLOT_TYPES(HPGL2 BW)"               "hg 0:hgplot"
#set "GDSPLOT_TYPES(HPGL1 6 Color)"          "h1 6:h1plot"
#set "GDSPLOT_TYPES(HPGL1 4 Color)"          "h1 4:h1plot"
#set "GDSPLOT_TYPES(HPGL1 BW)"               "h1 0:h1plot"
set "GDSPLOT_TYPES(HP650C Color)"           "rty6 256:rtdyplot -cym -svp -spl -650 -erstrzcol"
set "GDSPLOT_TYPES(HP650C BW)"              "rty6 2:rtdyplot -svp -spl -650"
set "GDSPLOT_TYPES(HP750C Color)"           "rty6 256:rtdyplot -cym -svp -spl -650- -erstrzcol"
set "GDSPLOT_TYPES(HP750C BW)"              "rty6 2:rtdyplot -svp -spl -650-"
set "GDSPLOT_TYPES(HP550C Color)"           "rty5 256:rtdyplot -cym -svp -spl -550 -bf6 -erstrzcol"
set "GDSPLOT_TYPES(HP550C BW)"              "rty5 2:rtdyplot -svp -spl -550 -bf6"
set "GDSPLOT_TYPES(HP870C Color)"           "rty8 256:rtdyplot -cym -svp -spl -bf54 -erstrzcol"
set "GDSPLOT_TYPES(HP1200C Color)"          "rtyg 256:rtdyplot -svp -spl -ql1 -bf4,1 -erstrzcol"
set "GDSPLOT_TYPES(HP1600C Color)"          "rtyg 256:rtdyplot -svp -spl -ql -bf4,1 -erstrzcol"
set "GDSPLOT_TYPES(HP2500C Color)"          "rtyg 256:rtdyplot -cym -svp -spl -650- -pjl -erstrzcol"




proc print_gdsplot {} -desc {
  brings up a menu of preferences and then plots the gds using gdsplot.
} {

  global PRINT MMI_TOOLS MMI_LOCAL env MN_BIN_DIR

  if {[exec uname -s] == "Linux"} {
    warning "Aborting, Gdsplot must run under solaris in this version."
    return
  }

  # find path to gdsplot
  set PRINT(gdsplot,path) $MMI_TOOLS/gdsplot

#  set PRINT(gdsplot,path) [use_first PRINT(gdsplot,path)]
#  catch "exec which gdsplt" msg
#  foreach line [split $msg \n] {
#    if {[string first gdsplt $line] != -1} {
#      set PRINT(gdsplot,path) [file dirname $line]
#      break
#    }
#  }

#  if {$PRINT(gdsplot,path) == ""} {
#    warning "Aborting, Can't find gdsplt in your path.  Install or set path in variable PRINT(gdsplot,path)."
#    return 
#  }

  # setup menu
  if {[_gdsplot_setup] == 0} {
    return
  }

  # output gds
  gds_write
  update idletasks
  puts ""

  # make the files
  if {[file readable $MMI_LOCAL/max/gdsplot.pat]} {
    set patfile $MMI_LOCAL/max/gdsplot.pat
  } else {
    set patfile $PRINT(gdsplot,path)/gdsplot.pat
  }

  if {[file readable $MMI_LOCAL/max/gdsplot.cfg]} {
    set cfgfile $MMI_LOCAL/max/gdsplot.cfg
  } else {
    set cfgfile $PRINT(gdsplot,path)/gdsplot.cfg
  }

  setl {gds_file cfg_file map_file} [_make_color_file $patfile $cfgfile]

  # plot
  if {[info exists PRINT(gdsplot,cmd)]} {
    # special case of using non-OEM version
    puts "running $PRINT(gdsplot,cmd) ..."

    exec $PRINT(gdsplot,cmd) $gds_file $cfg_file $map_file = > [exec tty]

  } else {
    # return
    error "No PRINT(gdsplot,cmd) command defined."
  }

#  if {[catch "exec csh -cf \"$PRINT(gdsplot,cmd) $gds_file $cfg_file $map_file = >&! [exec tty]\"" msg]} {
#    puts $msg
#  }

  if {$PRINT(gdsplot,plottofile)} {
    puts "Wrote $PRINT(gdsplot,type) to file $PRINT(gdsplot,plotfile)."
  } else {
    puts "Sent plot to plotter $PRINT(gdsplot,plotter)."
  }

  puts "done."
}


proc _gdsplot_setup {} -desc {
  menu to setup gdsplot options
} {

  global PRINT GDSPLOT_TYPES

  set title "GDSPLOT Setup"
  set message "Options:" 

  set prop_list ""

  set PRINT(gdsplot,plotter) [use_first PRINT(gdsplot,plotter)]
  set PRINT(gdsplot,plotters) \
      [use_first PRINT(gdsplot,plotters) PRINT(gdsplot,plotter)]
  lappend prop_list \
      [list "Plotter" PRINT(gdsplot,plotter) -popup $PRINT(gdsplot,plotters) \
	  -command _gdsplot_change_plotter -reload]

  set PRINT(gdsplot,comment) \
      [use_first PRINT(gdsplot,comment,$PRINT(gdsplot,plotter))]
  lappend prop_list [list "Comment" PRINT(gdsplot,comment) -label] 

  set default_type [lindex [lsort [array names GDSPLOT_TYPES]] 0]
  set PRINT(gdsplot,type) [use_first PRINT(gdsplot,type) default_type]
  lappend prop_list \
      [list "Plotter Type" PRINT(gdsplot,type) -choice [lsort [array names GDSPLOT_TYPES]]]

  lappend prop_list [list {} {} -separator]

  set default_size "36,10"
  set PRINT(gdsplot,size) [use_first PRINT(gdsplot,size) default_size]
  lappend prop_list [list "Image size" PRINT(gdsplot,size) -popup "36,10 A B C D E" -help {Enter either width,length of plot in inches or A/B/C/D/E.  NOTE: HP plotters should have Page Format Size set to Inked Area.}]

  set orients "auto0 0 90"
  set PRINT(gdsplot,orient) [use_first PRINT(gdsplot,orient) 'auto0]
  lappend prop_list \
      [list "Image Orientation" PRINT(gdsplot,orient) -choice $orients]

  set PRINT(gdsplot,font_scale) [use_first PRINT(gdsplot,font_scale) '0.3]
  lappend prop_list \
      [list "Font Scale" PRINT(gdsplot,font_scale) -number 0.1 -incr .1]

  lappend prop_list [list {} {} -separator]

  set PRINT(gdsplot,region) [use_first PRINT(gdsplot,region) '0]
  lappend prop_list [list "Plot Specified Region Only" PRINT(gdsplot,region) \
    -binary -reload \
    -help "Enter coordinates of region to plot.  Defaults to box."]

  setl {PRINT(gdsplot,region_x1) PRINT(gdsplot,region_y1) \
	    PRINT(gdsplot,region_x2) PRINT(gdsplot,region_y2)} [lay_box]
  lappend prop_list [list "  x1" PRINT(gdsplot,region_x1) -number \
			 -when {$PRINT(gdsplot,region)}]
  lappend prop_list [list "  y1" PRINT(gdsplot,region_y1) -number \
			 -when {$PRINT(gdsplot,region)}]
  lappend prop_list [list "  x2" PRINT(gdsplot,region_x2) -number \
			 -when {$PRINT(gdsplot,region)}]
  lappend prop_list [list "  y2" PRINT(gdsplot,region_y2) -number \
			 -when {$PRINT(gdsplot,region)}]

  lappend prop_list [list {} {} -separator]

  set PRINT(gdsplot,title) ""
  lappend prop_list [list "Title" PRINT(gdsplot,title)]

  lappend prop_list [list {} {} -separator]

  set default_cmd "cat %s | lpr -s -P%p"
  set PRINT(gdsplot,plotcmd) [use_first PRINT(gdsplot,plotcmd) default_cmd]
  lappend prop_list [list "Plot Command" PRINT(gdsplot,plotcmd) -entry -help "%p is replaced by the plotter and %s is replaced by the plot file."]

  set cell [lay_rootcell]
  set file [lindex [cell_info $cell] 1]
  if {$file == ""} {
    set dir "[pwd]/"
  } else {
    set dir [file dirname $file]/
    if {$dir == "./"} {
      set dir "[pwd]/"
    }
  }

  set PRINT(gdsplot,plottofile) [use_first PRINT(gdsplot,plottofile) '0]
  lappend prop_list [list "Plot to File" PRINT(gdsplot,plottofile) -binary]

  set PRINT(gdsplot,plotfile) "$dir$cell.plot"
  lappend prop_list [list "Plot File" PRINT(gdsplot,plotfile)]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return 0
  }

  if {$PRINT(gdsplot,plotter) == ""} {
    warning "Aborting, must specify plotter name."
    return 0
  }

  set PRINT(gdsplot,size) [string toupper $PRINT(gdsplot,size)]
  if {[lsearch "A B C D E" $PRINT(gdsplot,size)] != -1 &&
      ![info exists PRINT($PRINT(gdsplot,size),size)]} {
    warning "Aborting, illegal plot size $PRINT(gdsplot,size)."
    return 0
  }

  return 1
}


proc _gdsplot_change_plotter {} -desc {
  called to change printer type,size based on changed plotter
} {
  global PRINT

  set PRINT(gdsplot,type) [use_first \
			       PRINT(gdsplot,type,$PRINT(gdsplot,plotter)) \
			       PRINT(gdsplot,type)]

  set PRINT(gdsplot,size) [use_first \
			       PRINT(gdsplot,size,$PRINT(gdsplot,plotter)) \
			       PRINT(gdsplot,size)]

  set PRINT(gdsplot,comment) \
      [use_first PRINT(gdsplot,comment,$PRINT(gdsplot,plotter))]
}


proc _make_color_file {default_pat default_cfg} -desc {
  create the color/pattern, configuration, and map files.
} {

  global _LAYER_DATA_ CELL COLORMAP PAL_DATA PRINT GDSPLOT_TYPES

  # get the directory for this plot
  set cell [lay_rootcell]

  # compute directory for file
  set file [lindex [cell_info $cell] 1]
  if {$file == ""} {
    set dir "[pwd]/"
  } else {
    set dir [file dirname $file]/
    if {$dir == "./"} {
      set dir "[pwd]/"
    }
  }

  set gds_file "$dir$cell$CELL(gds_suffix)"

  # Always generate a new .job file because gdsplt will hose if the
  # .job file is hosed.
  if {[file exists $dir$cell.job]} {
    if {[catch "exec rm $dir$cell.job" msg]} {
      puts "Warning: $msg"
    }
  }

  set filename "$dir$cell.gdsplot_pat"

  # NOTE: must be plot.cfg (choke)
  set plot_cfg "${dir}plot.cfg"
  puts "Writing main gdsplot configuration to $plot_cfg ..."

  # open file for writing
  if {[catch "open $plot_cfg w" FILE_ID]} {
    # can't write file, abort
    warning "Aborting, $FILE_ID"
    return
  }

  puts $FILE_ID "Raster.PatternFile: $filename"
  regsub {%p} $PRINT(gdsplot,plotcmd) $PRINT(gdsplot,plotter) plotstring

  puts $FILE_ID "pltcfg.COMMAND_STRING: $plotstring"

  puts $FILE_ID "pltcfg.PLTYPE:	$GDSPLOT_TYPES($PRINT(gdsplot,type))"
  puts $FILE_ID "pltcfg.ROTATE:	$PRINT(gdsplot,orient)"

  if {[lsearch "A B C D E" $PRINT(gdsplot,size)] != -1} {
    puts $FILE_ID "pltcfg.PGSIZE: $PRINT(gdsplot,size) $PRINT($PRINT(gdsplot,size),size)"
    puts $FILE_ID "pltcfg.PGSIZEZ: $PRINT(gdsplot,size) 0,0"

  } else {
    # must be a custom size
    puts $FILE_ID "pltcfg.PGSIZE: Z [join [split $PRINT(gdsplot,size) ,]]"
    puts $FILE_ID "pltcfg.PGSIZEZ: Z 0,0"
  }

  puts $FILE_ID "pltcfg.HdrTxt: $PRINT(gdsplot,title)"

  # add boiler plate
  if {[catch "open $default_cfg r" FILE_ID2]} {
    # can't read file, abort
    warning "Aborting, $FILE_ID2"
    return
  }

  while {[gets $FILE_ID2 line] > -1} {
    puts $FILE_ID $line
  }

  close $FILE_ID2

  close $FILE_ID

  # create color patterns file.
  puts "Writing gdsplot color patterns to $filename ..."

  # open file for writing
  if {[catch "open $filename w" FILE_ID]} {
    # can't write file, abort
    warning "Aborting, $FILE_ID"
    return
  }

  # first copy default_pat file into this
  if {[catch "open $default_pat r" FILE_ID2]} {
    # can't read file, abort
    warning "Aborting, $FILE_ID2"
    return
  }

  while {[gets $FILE_ID2 line] > -1} {
    puts $FILE_ID $line
  }

  close $FILE_ID2

  _get_layer_list

  # start adding new colors at pattern 32
  set index 31

  set vias [techinfo vias]
  set via_index 15

  foreach layer $_LAYER_DATA_(_LIST_) {

    set name $_LAYER_DATA_($layer,max)

    if {[lsearch $vias $name] != -1} {
      # special for vias
      incr via_index
      if {$via_index > 18} {
	set via_index 16
      }

      set _LAYER_DATA_($layer,color) $via_index
      set _LAYER_DATA_($layer,outline) 1

      continue
    }

    set styles [lay_layer_styles $_LAYER_DATA_($layer,max)]
    setl {mask color outline fill stipple} [lay_style [lindex $styles 0]]

    if {![info exists COLORMAP($color)]} {
      # convert color number to decimal -- pseudocolor only
      set color [expr 0 + $color]
    }

    setl {r g b} $COLORMAP($color)

    set _LAYER_DATA_($layer,color) [incr index]
    set _LAYER_DATA_($layer,outline) 0

    if {$fill == "stipple" && ![info exists PAL_DATA(pseudo,$stipple)]} {
      # this is a real stipple
      set _LAYER_DATA_($layer,stipple) $PAL_DATA(stipple,$stipple)

      # is there an outline?
      foreach style $styles {
	if {[string first outline [lay_style $style]] != -1} {
	  # outline, figure out closest color for outline (ugly)
	  #1 BLACK, #2 RED, #3 GREEN, #4 YELLOW, #5 BLUE, #6 MAGENTA, #7 CYAN

	  set c [expr 255 - $r]
	  set m [expr 255 - $g]
	  set y [expr 255 - $b]

	  set max r
	  foreach one "g b c m y" {
	    if {[set $one] > [set $max]} {
	      set max $one
	    }
	  }

	  set _LAYER_DATA_($layer,outline) [string first $max wbrgybmc]
	  break
	}
      }
    }

    _rgb_convert $FILE_ID $index $r $g $b $name \
	[use_first _LAYER_DATA_($layer,stipple)]
  }

  close $FILE_ID

  # make map file
  set filename "$dir$cell.gdsplot_map"

  puts "Writing gdsplot map to $filename ..."

  # open file for writing
  if {[catch "open $filename w" FILE_ID]} {
    # can't write file, abort
    warning "Aborting, $FILE_ID"
    return
  }

  puts $FILE_ID "\#Layer Map Begin"
  foreach layer $_LAYER_DATA_(_LIST_) {
    puts $FILE_ID "$_LAYER_DATA_($layer,gds) $_LAYER_DATA_($layer,color) $_LAYER_DATA_($layer,outline) [expr $_LAYER_DATA_($layer,outline) > 0] \"$_LAYER_DATA_($layer,max)"

    # add black for text
    if {[info exists _LAYER_DATA_(TXT_$_LAYER_DATA_($layer,max),gds)]} {
      set text_layer $_LAYER_DATA_(TXT_$_LAYER_DATA_($layer,max),gds)
      if {$text_layer != $_LAYER_DATA_($layer,gds)} {
	puts $FILE_ID "$text_layer 1 1 1 \"TXT_$_LAYER_DATA_($layer,max)"
      }
    }
  }
  puts $FILE_ID "\#layer Map End"

  close $FILE_ID

  set cfg_filename "$dir$cell.gdsplot_cfg"
  puts "Writing gdsplot configuration to $cfg_filename ..."

  # open file for writing
  if {[catch "open $cfg_filename w" FILE_ID]} {
    # can't write file, abort
    warning "Aborting, $FILE_ID"
    return
  }

  puts $FILE_ID "\#Font Map Begin"
  for {set i 0} {$i < 4} {incr i} {
    puts $FILE_ID "$PRINT(gdsplot,path)/GDSVU.FNT $PRINT(gdsplot,font_scale)"
  }
  puts $FILE_ID "\#font map end"

  # add layers to plot
  set layer_numbers ""
  foreach layer [dbt_visible_layers] {
    if {[info exists _LAYER_DATA_($layer)]} {
      lappend layer_numbers $_LAYER_DATA_($_LAYER_DATA_($layer),gds)
    }

    if {[info exists _LAYER_DATA_(TXT_$layer,gds)]} {
      lappend layer_numbers $_LAYER_DATA_(TXT_$layer,gds)
    }
  }

  puts $FILE_ID "\#"
  puts $FILE_ID "\#Plot/Layer Begin Setup"

  if {$PRINT(gdsplot,region)} {
    # plot only this region of the plot
    set w "w$PRINT(gdsplot,region_x1),$PRINT(gdsplot,region_y1) $PRINT(gdsplot,region_x2),$PRINT(gdsplot,region_y2) "
  } else {
    set w ""
  }

  if {$PRINT(gdsplot,plottofile)} {
    set string $PRINT(gdsplot,plotfile)
  } else {
    # use plot line
    set string ""
  }

  puts $FILE_ID "0.0 0.0 0.0 ${w}i[join $layer_numbers ,] x %$string"
  puts $FILE_ID "\#plot/layer end setup"

  close $FILE_ID

  return [list $gds_file $cfg_filename $filename]
}


proc _rgb_convert {FILE_ID index r g b {name ""} {stipple ""}} {

  global PEN_MATRIX

  if {$name == ""} {
    set name "R=$r G=$g B=$b"
  }

  puts $FILE_ID "\#$index $name"

  # to lighten the colors
  set c_offset 120
  set m_offset 80
  set y_offset 40

  set c [max [expr 255 - $c_offset - $r] 0]
  set m [max [expr 255 - $m_offset - $g] 0]
  set y [max [expr 255 - $y_offset - $b] 0]

  # builds a 4x4 matrix
  foreach pen "c m y" {

    set del [expr [set $pen] / 16.0]
    set value $del

    for {set i 0} {$i < 16} {incr i} {
      
      if {$value > 7} {
	# add color
	lappend pens($i) $pen

	set value [expr $value - 16]

      }

      set value [expr $value + $del]
    }
  }

  # write out
  if {$stipple == ""} {
    # simple, solid layer

    set string ""
    for {set i 0} {$i < 16} {incr i} {

      if {![info exists pens($i)]} {
	# white
	append string .

      } else {
	set key [join [lsort $pens($i)] ,]
	append string $PEN_MATRIX($key)
      }
	
      if {[expr ($i + 1) % 4] == 0} {
	puts $FILE_ID $string
	set string ""
      }
    }
  } else {
    # stipple
    # put the 4x4 into a 32x32 based on the stipple pattern

    set string ""
    for {set i 0} {$i < 16} {incr i} {

      if {![info exists pens($i)]} {
	# white
	append string .

      } else {
	set key [join [lsort $pens($i)] ,]
	append string $PEN_MATRIX($key)
      }

      if {[expr ($i + 1) % 4] == 0} {
	set "v[expr ($i+1)/4]" $string
	set string ""
      }
    }

    foreach line $stipple {
      regsub -all 0 $line .... line
      foreach value "$v1 $v2 $v3 $v4" {
	regsub -all 1 $line $value out
	puts $FILE_ID $out
      }
    }
  }
}



proc _get_layer_list {} {

  global _LAYER_DATA_

  catch {unset _LAYER_DATA_}

  # see if gds layer is used more that once.  If not, get all datatypes (0-63)
  foreach layer [split [cif_layers] \n] {
    setl {name calma_num calma_type flags} $layer 
    if {[memq temp $flags]} {
      continue
    }

    if {[string range $name 0 3] != "GDS_"} {
      # these will get plotted with their layers (except space)
      continue
    }

    if {[info exists gds($calma_num)]} {
      incr gds($calma_num)
    } else {
      set gds($calma_num) 1
    }
  }

  set layer_list ""
  set labels ""
  foreach layer [split [cif_layers] \n] {
    setl {name calma_num calma_type flags} $layer 
    if {[memq temp $flags]} {
      continue
    }

    # is there a corresponding max layer
    set max_name [string range $name 4 end]

    if {[string range $name 0 3] == "TXT_"} {
      # labels: if different gds layer must do special
      # Note: always comes after GDS_ line of layer
      if {[info exists _LAYER_DATA_(GDS_$max_name,max)]} {
	# display this label
	# TODO: if same gds but different dt, problem
	if {$calma_num != $_LAYER_DATA_(GDS_$max_name,gds)} {
	  # need to add separately
	  lappend labels $name
	  set _LAYER_DATA_($name,gds) $calma_num
	  # TODO: check for this
	  set _LAYER_DATA_($name,dt) "0-63"
	}
      }
      continue
    }

    if {[string range $name 0 3] != "GDS_"} {
      # these will get plotted with their layers (except space)
      continue
    }

    set new_name ""
    if {[catch "lay_layer_styles $max_name" msg]} {
      # must be derived
      # TODO could have a line continuation in it
      set sourcefile [max_tech_path source]
      if {[catch "exec grep -i derive $sourcefile | grep -i \" $max_name \"" msg]} {
	# can't find
	puts "Warning, skipping $name, can't determine color for."
	continue
      }

      foreach line [split $msg \n] {
	if {[lindex $line 1] == $max_name} {
	  set new_name [lindex [split [lindex $line 3] ,] 0]
	  if {[catch "lay_layer_styles $new_name" msg]} {
	    set new_name ""
	  } else {
	    # this is it
	    break
	  }
	}
      }

      if {$new_name == ""} {
	puts "Warning, skipping $name, can't determine color for."
	continue
      }

      set max_name $new_name
    }

    # is this layer currently visible
    if {![dbt_is_visible $max_name]} {
      continue
    }

    lappend layer_list $name
    set _LAYER_DATA_($name,max) $max_name
    set _LAYER_DATA_($max_name) $name
    set _LAYER_DATA_($name,gds) $calma_num

    if {$gds($calma_num) == 1} {
      # put in all datatypes
      set _LAYER_DATA_($name,dt) "0-63"
    } else {
      set _LAYER_DATA_($name,dt) $calma_type
    }
  }

  set _LAYER_DATA_(_LIST_) $layer_list
}
