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


# Help stuff and menu help lines


# brings up a window current bindings and message window (if in a mode)

proc help_window {x y} {

  global cur_c HELP_FONT WIN_DATA WIN ICON_WINDOWS MENU_HELP

  set mode [use_first WIN_DATA($WIN,mode)]

  set win .bindings

  # ???
  if {$mode != "" && [winfo exists .bindings]} {
    # weird case where user is holding onto button and hitting space
    # key.  User still has grab from other window.
    catch {destroy $win}
    return
  }

  if {[winfo exists .bindings]} {
    catch {destroy $win}
    return
  }

  if {$x == "%x"} {
    set x 0
  }
  if {$y == "%y"} {
    set y 0
  }

  # use current canvas unless over a listbox.  Note, don't want focus
  # follows mouse so we have to do this.
  set mouse_win [winfo containing [expr $x + [winfo rootx $WIN]] \
		     [expr $y + [winfo rooty $WIN]]]
  if {[regexp {lb.(schematic|icon)} $mouse_win]} {
    set bind_win $mouse_win

    # user hits space to delete this
    if {[winfo exists .bindings]} {
      catch {destroy $win}
      return
    }

  } else {
    set bind_win $cur_c
  }

  catch {destroy $win}

  toplevel $win

  wm geometry $win "900x500[relative_origin]"
 
  wm title $win "Current Bindings"

  button $win.close -text "Close (or hit space key again)" -padx 1 -pady 1 -command "destroy $win"
  pack $win.close -side bottom -fill x

  text $win.text -relief raised -bd 2 -yscrollcommand "$win.scroll set" \
      -font $HELP_FONT
  scrollbar $win.scroll -command "$win.text yview" -highlightthickness 0

  pack $win.scroll -side right -fill y
  pack $win.text -side left -expand 1 -fill both

  set msg [use_first WIN_DATA($WIN,save_msg) WIN_DATA($WIN,display_msg)]

  # now fill up the window
  if {[regexp {lb.(schematic|icon)} $bind_win tmp type]} {
    # special case for listboxes
    $win.text insert end "[string toupper $type] Listbox Bindings:\n\n"
    set mode_string "$bind_win,"

  } elseif {$mode != ""} {
    # inside a mode, give user the info
    $win.text insert end "Mode: $WIN_DATA($WIN,mode)\n\n"
    help_window_insert $win.text "$msg\n\n" ""
    $win.text insert end "Local Bindings:\n\n"
    set mode_string "$mode,mode,"

  } else {
    $win.text insert end "Mode: NONE\n\n"
    $win.text insert end "Bindings:\n\n"
    set mode_string ""
  }

  foreach binding [lsort [bind $bind_win]] {
    set binding [string trim $binding <>]
    regsub "Key-" $binding "" binding

    if {[string trim $binding " -"] == ""} {
      # don't show to user
      continue
    }

    if {[lsearch "Configure Unmap Map" $binding] != -1} {
      continue
    }

    set desc [use_first MENU_HELP($mode_string$binding)]

    if {$desc == "" && [string range $binding 0 3] == "Meta"} {
      # extras, don't show
      continue
    }

    if {$desc == "IGNORE"} {
      # don't show to user
      continue
    }

    set bin [string tolower [lindex [lreverse [split $binding -]] 0]]
    lappend entries($bin) \
	[format "%18s - %s\n" [seq_pp $binding] $desc]
  }

  foreach entry [lsort [array names entries]] {
    foreach subentry $entries($entry) {
      help_window_insert $win.text $subentry
    }
  }

  # special case for canvases
  if {$bind_win == $cur_c && $mode == ""} {
    foreach type {icon wire open dot draw_item edit_marker} {

      $win.text insert end "\n$type: (when highlited)\n\n"

      foreach binding [lsort [$bind_win bind $type]] {
	set binding [string trim $binding <>]
	regsub "Key-" $binding "" binding

	if {[lsearch "Enter Leave Motion" $binding] != -1} {
	  continue
	}

	set desc [use_first MENU_HELP($type,$binding)]

	if {$desc == "IGNORE"} {
	  # don't show to user
	  continue
	}

	set entry [format "%18s - %s\n" [seq_pp $binding] $desc]

	help_window_insert $win.text $entry
      }
    }
  }

  # don't let the user change this window
  $win.text configure -state disabled

  # let the user change the window size
  wm minsize $win 400 200
  
  bind $win <Any-space> "catch {destroy $win}"
  bind $win <Escape> "catch {destroy $win}"
  bind $win <Control-c> "catch {destroy $win}"

  bind $win <Down> "$win.text yview scroll 1 units"
  bind $win <Up> "$win.text yview scroll -1 units"

  # same bindings for pageup and pagedown
  bind $win <Next> "$win.text yview scroll 1 pages"
  bind $win <Prior> "$win.text yview scroll -1 pages"

  return
}


# adds a line to the help window.  Breaks long lines

proc help_window_insert {win line {prefix "                     "}} {

  while {$line != ""} {
    if {[string length $line] > 95} {
      set space [string last " " [string range $line 0 95]]
      if {$space == -1} {
	set space \
	    [expr 80 + [string first " " "[string range $line 80 end] "]]
      }

      $win insert end [string range $line 0 $space]\n

      set line "$prefix[string range $line [incr space] end]"

    } else {
      $win insert end $line
      set line ""
    }
  }
}


proc seq_pp seq -desc {
  return pretty-print version of input event sequence
} {
  setl {type modifier key extra} [seq_parse $seq]

  set modifier [join $modifier -]

  if {$type == "BUT"} {
    if {$key != $extra && $extra != ""} {
      set but "B$extra"
    } else {
      set but "BUT"
    }

    if {$modifier == {}} {
      return "$but-$key"
    } else {
      return "$modifier-$but-$key"
    } 
  }

  # ???
  if {$type == "SPECIAL"} {
    if {$modifier == ""} {
      return [string toupper $key]
    } else {
      return "$modifier-[string toupper $key]"
    }
  }

  if {$modifier == ""} {
    return $key
  } else {
    return "$modifier-$key"
  }
}


proc seq_parse seq -desc {
  convert event sequence into: {type modifier key}
} -doc {
    type = BUT, ALPHA or SPECIAL
    modifier = Shift, Control, Double, or ALT
    key = key name (upper case)
    orig = input string
    '<' and '>' stripped. 
} {

  setl {type modifier key extra} ""

  # remove brackets
  set seq [string trimleft $seq < ]
  set seq [string trimright $seq > ]

  # split on -
  foreach mod [split $seq -] {
 	
    # discard "Any" modifier, to avoid clutter/confusion
    if {[lsearch "Any Key" $mod] != -1} {
      continue
    }

    if {$mod == "Control" } {
      lappend modifier Ctrl
      continue
    }

    if {$mod == "Double" } {
      lappend modifier Double
      continue
    }

    if {[lsearch "Shift Alt" $mod] != -1} {
      lappend modifier $mod
      continue
    }
    
    if {$mod == "Button"} {
      set type BUT
      continue
    }

    if {[regexp {^B([1-3])$} $mod tmp button]} {
      set key $button
      set extra $button
      set type BUT
      continue
    }

    if {[regexp {^[A-Z]$} $mod tmp]} {
#      set key [string tolower $mod]
#      lappend modifier Shift
      set key $mod
      continue
    }

    if {[regexp {^[a-z0-9]$} $mod tmp]} {
      set key $mod
      continue
    }

    # default
    set key $mod
  }

  return [list $type $modifier $key $extra]
}


# Creates a little notice to amuse users

proc about_sue {} {

  global SUE_DIR VERSION COMPILE_TIME nl_version PROJECT

  set message ""
  if {[info exists COMPILE_TIME]} {
    lappend message "Micro Magic SUE, Version $VERSION Compiled $COMPILE_TIME"
  } else {
    lappend message "SUE Version $VERSION"
  }

  lappend message "nl version [lindex $nl_version 0]."

  if {[use_first PROJECT] != ""} {
    lappend message "Project: $PROJECT."
  }

  set button [tk_dialog .about_sue "About SUE" \
		  [join $message \n] \
		  @$SUE_DIR/sue_icon.xbm 0 {ok}]
}


# displays doc in a browser

proc help {{type manual}} {

  global DEFAULT_BROWSER env SUE_DIR

  set browser [use_first env(MMI_BROWSER) env(BROWSER) DEFAULT_BROWSER]

  if {$type == "manual"} {
    set file $SUE_DIR/doc/sue_manual/sue_manual.html
  } elseif {$type == "dpc_manual"} {
    set file $SUE_DIR/doc/dpc_manual/dpc_manual.html
  } elseif {$type == "tutorial"} {
    set file $SUE_DIR/doc/sue_tutorial/sue_tutorial.html
  } elseif {$type == "dpc_tutorial"} {
    set file $SUE_DIR/doc/dpc_tutorial/dpc_tutorial.html
  } elseif {$type == "mmi_doc"} {
    set file $env(MMI_TOOLS)/mmidoc/mmi.html
  } elseif {[string toupper $type] == "FAQ"} {
    set file $SUE_DIR/FAQ
  } elseif {$type == "bug_report"} {
    set file $env(MMI_TOOLS)/bug_report.html
  } else {
    # otherwise open the file
    set file $type
  }	

  puts "Opening $file in $browser browser..."

  # if netscape, get fancy and try popping up file in an existing browser    
  if {$browser == "netscape"} {
    # openFile($file)" doesn't seem to work
    if {[catch "exec $browser -remote openURL($file)" msg] == 0} {
      return
    }
  }
	
  # fancy stuff didn't work, so just start up a browser on the file!
  if {[catch "exec $browser $file &" msg]} {
    # error, just give the user the ascii version
    puts "Aborting, $msg"
  }
}


# brings up a window with the SUE manual in it

proc help_ascii {file} {

  global cur_c SUE_DIR HELP_FONT

  set win .doc

  if {[winfo exists $win]} {
    puts "Help window already exists.  Raising."
    raise $win
    return
  }

  if {[catch "open $file" msg]} {
    # we got a problem.  It's probably manual file in wrong place
    puts $msg
    return
  } else {
    set fp $msg
  }

  toplevel $win

  wm geometry $win [relative_origin]
 
  wm title $win "SUE Documentation: $file"

  button $win.close -text "Close" -padx 1 -pady 1 -command "destroy $win"
  pack $win.close -side bottom -fill x

  text $win.text -relief raised -bd 4 -yscrollcommand "$win.scroll set" \
      -font $HELP_FONT
  scrollbar $win.scroll -command "$win.text yview" -highlightthickness 0

  pack $win.scroll -side right -fill y
  pack $win.text -side left -expand 1 -fill both

  while {![eof $fp]} {
    $win.text insert end [read $fp 1000]
  }
  close $fp

  update
  # let the user change the window size but restrict the width
  wm minsize $win [winfo width $win] 200
  
  return
}


# tk8.0 specific
# taken out of menu.tcl in the tk library and modified to show help 

proc tkGenerateMenuSelect {menu} {

  global tkPriv LAST_MENU_ITEM

  if {([string compare $tkPriv(activeMenu) $menu] == 0) \
	  && ([string compare $tkPriv(activeItem) [$menu index active]] == 0)} {
    return
  }

  set index [$menu index active]

  if {$index != "none" && [$menu type $index] != "tearoff"} {
    set name [$menu entrycget $index -label]
    if {[use_first LAST_MENU_ITEM] != $name} {
      set LAST_MENU_ITEM $name
      display_help_item $name
    }
  }

  set tkPriv(activeMenu) $menu
  set tkPriv(activeItem) $index
  event generate $menu <<MenuSelect>>
}


# tkMenuLeave --
# This procedure is invoked to handle Leave events for a menu.  It
# deactivates everything unless the active element is a cascade element
# and the mouse is now over the submenu.
#
# Arguments:
# menu -		The menu window.
# rootx, rooty -	Root coordinates of mouse.
# state -		Modifier state.

proc tkMenuLeave {menu rootx rooty state} {

    global tkPriv LAST_MENU_ITEM DISABLE_CANVAS_EVENT WIN WIN_DATA

    # added for sue
    if {$DISABLE_CANVAS_EVENT} {
      # in a mode
      set WIN_DATA($WIN,display_msg) [use_first WIN_DATA($WIN,save_msg)]
    } else {
      # not in a mode
      display_selection
    }
    catch "unset WIN_DATA($WIN,save_msg)"

    set LAST_MENU_ITEM ""

    set tkPriv(window) {}
    if {[$menu index active] == "none"} {
	return
    }
    if {([$menu type active] == "cascade")
	    && ([winfo containing $rootx $rooty]
	    == [$menu entrycget active -menu])} {
	return
    }
    $menu activate none
    tkGenerateMenuSelect $menu
}


proc display_help_item {name} {

  global WIN WIN_DATA MENU_HELP

  # replace spaces with underscores
  regsub -all {\.} $name {} name
  set name [join [string tolower $name] _]

  if {[use_first WIN_DATA($WIN,save_msg)] == ""} {
    # save the display msg
    set WIN_DATA($WIN,save_msg) $WIN_DATA($WIN,display_msg)
  }

  set WIN_DATA($WIN,display_msg) [use_first MENU_HELP($name)]
}


# add a msg to the msg window with this command

proc msg_window {text {mode ""}} {

  global WIN WIN_DATA

  if {$text == "__RESTORE__"} {
    set WIN_DATA($WIN,display_msg) \
	[use_first WIN_DATA($WIN,save_msg) WIN_DATA($WIN,last)]
    set WIN_DATA($WIN,save_msg) ""
    return
  }

  set WIN_DATA($WIN,display_msg) $text

  if {$mode != "listbox"} {
    set WIN_DATA($WIN,last) $text
  }

  # need to put this here so as not to be flushed by menus
  if {$mode == ""} {
    set WIN_DATA($WIN,save_msg) $text
  }
}



# print setup submenu (not used now)

set MENU_HELP(print_to_default_printer) \
    "When printing, send the postscript for the current cell to default printer."
set MENU_HELP(print_to_file) \
    "When printing, write the postcript for the current cell to the file <cell_name>$SUFFIX(postscript)."

set MENU_HELP(largest_orientation) "Set print orientation to best fit, either landscape or portrait, on a cell by cell basis."
set MENU_HELP(landscape) "Set print orientation to landscape."
set MENU_HELP(portrait) "Set print orientation to portrait."

set MENU_HELP(1_page_per_schematic) \
    "Fit the current schematic to a single printed page."
set MENU_HELP(2_pages_per_schematic) \
    "Fit the current schematic to cover two printed pages."
set MENU_HELP(4_pages_per_schematic) \
    "Fit the current schematic to cover four printed pages."

set MENU_HELP(schematics_only) \
    "When printing with descendents, only print schematics when there is both a schematic and icon of the same name."
set MENU_HELP(schematics_and_icons) \
    "When printing with descendents, print both schematics and icons when both exist with the same name."

set MENU_HELP(margins) \
    "Set the print margins based on setup parameters in .suerc file"
set MENU_HELP(exact_bounding_box) \
    "Use no print margins.  Useful for including postscript onto documents."



# Sim menu

set MENU_HELP(spice_netlist) \
    "Write a spice netlist starting from the current cell."
set MENU_HELP(spice_it) \
    "Spice netlist current cell, run spice, and when spice completes, initialize or reinitialize the probe."

set MENU_HELP(plot_net) \
    "Instruct the probe to plot the selected net."
set MENU_HELP(unplot_net) \
    "Instruct the probe to unplot the selected net (i.e. erase on probe)."
set MENU_HELP(plot_net_&_remember) \
    "Plot selected net and remember to plot it again after future simulations."
set MENU_HELP(unplot_net_&_forget) \
  "Unplot selected net and forget about replotting it after future simulations."
set MENU_HELP(plot_old_net) \
  "Plot selected net but using the data from the previous simulation if loaded."
set MENU_HELP(unplot_old_net) \
    "Unplot selected net but using the data from the previous simulation."

set MENU_HELP(erase_and_plot_memory) \
    "Clear probe and replot remembered nets."
set MENU_HELP(cancel_memory) \
    "Cancel memory of remembered nets."


set MENU_HELP(sim_netlist) "Write a sim netlist starting from the current cell."
set MENU_HELP(sim_it) \
    "Sim netlist current cell, run irsim, and initialize or reinitialize analyzer waveform viewer."

set MENU_HELP(forget_net) \
    "Forget about replotting the selected net after future simulations"

set MENU_HELP(update_flags) \
    "Update the values for all flags in the current cell with values from the current state of the simulation."
set MENU_HELP(display_term_values) \
    "Display values for every terminal in the current cell with values from the current state of the simulation."


set MENU_HELP(irsim_step) \
    "Step time forward in irsim and update all flags in the current cell."
set MENU_HELP(irsim_set_hi) \
    "Overwrite the irsim logical value on the selected net to be hi (1)."
set MENU_HELP(irsim_set_low) \
    "Overwrite the irsim logical value on the selected net to be low (0)."
set MENU_HELP(irsim_set_x) \
    "Overwrite the irsim logical value on the selected net to be unknown (x)."

set MENU_HELP(verilog_netlist) \
    "Write a verilog netlist starting from the current cell."
set MENU_HELP(verilog_it) \
    "Verilog netlist current cell and run verilog in batch mode."

set MENU_HELP(print_net_value_(decimal)) "Display the verilog logical value of the selected net in decimal in the SUE startup window."
set MENU_HELP(print_net_value_(binary)) "Display the verilog logical value of the selected net in binary in the SUE startup window."
set MENU_HELP(print_net_value_(hex)) "Display the verilog logical value of the selected net in hex in the SUE startup window."

set MENU_HELP(dpc_netlist) \
    "Write a verilog gate-level netlist and datapath placement file starting from the current cell."
set MENU_HELP(dpc_it) \
    "Verilog netlist current cell and generate placement, run timing analysis, and back annotate timing."


set MENU_HELP(step_verilog) \
    "Step time forward in verilog and update all flags in the current cell."

set MENU_HELP(edit_verilog) \
    "Display the verilog $SUFFIX(behavioral_verilog) file for the selected instance or current cell if nothing is selected."
