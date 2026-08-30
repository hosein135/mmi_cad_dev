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

set RCSVERSION(menu_bar.tcl) { $Revision: 1.74 $ }

# implement max menu bar for layout windows.
set OPTIONS(dev,single_pixel_threshold_slow) 4
set OPTIONS(dev,single_pixel_threshold_fast) 10


init_global MASK_MENU_ITEMS_PER_COL \
	-type INT -default 30 \
	-desc {Max number of items per column in the "See MASK" menu.}

proc menu_add_cmd {args} -desc {
  add command to a menu (command setup so history, undo, etc. work properly)
} -doc {
  USAGE: menu_add_cmd -options menu label script [event]

  The label is the name to appear on the menu for this entry.
  10/00: Update: Not necessarily.  The keymap code ultimately
  decides what will go on the menu when the keymap is loaded.

  The cmd is the command to execute.  By default, it is wrapped
  with i_cmd_eval;  see -nowrap and -common below.

  Options can be:
    -desc {description}
	Otherwise, the description comes from the description of the
	command in cmd, if it is a single command name, otherwise the label
	is used.
    -nyi  - not yet implemented.
    -nowrap - this is a top-level command with its own internal wrapper,
	ie, it does not need i_cmd_eval around cmd.
	Otherwise, the menu entry is setup to do "i_cmd_eval cmd".
	This makes the menu entry a bona-fide max command:
	undo, history, etc. are handled correctly.
    -common - This binding should be valid in all max sub-modes.
	Warning: the command must not have any side-affects, like
	changing the undo stack.  All -common commands are als,
	required to be -nowrap, because i_cmd_eval cannot be called
	in the middle of some other command.
    -point - command requires interactive mouse point to be entered,
	which requires the command to be wrapped by point_mode when
	invoked off the menu.
    -perm {binding} - a permanent binding that can not be over-ridden by
	the keymap code.  Can be in addition to, or instead of,
	the normal binding.

  This function also maps the specified bindings to cmd.

  Deletes any pre-existing entry with same label.
} {
    # parse args 
    # 5/2/00, pat: switch to cell_keyword and use binary options.
    # This lets us do some validity checks on the call.
    set options [list {desc ""} {nyi} \
       {common} {nowrap} {point} {perm ""}]
    setl {menu label cmd event extra} [call_keyword $args $options]
    assert { $label != "" }
    assert { $nyi || $cmd != "" }
    assert { $extra == "" }

    # New keymap code allows only one programmable binding per key.
    # But can add a non-programmable binding with -perm option.
    assert { [llength $event] <= 1 }
    
    if {$common} {
      # common also gets (and requires) nowrap. 
      # Remember: common mode commands can be called any time from
      # any mode, so they MUST not have an undo wrapper.
      set nowrap 1
      set modename common
    } else {
      set modename main
    }

    set w $menu
    catch {$w delete $label}

    # set help message for this menu item
    if {$desc == ""} {
	set desc [doc_at $cmd cmd_desc]
    }
    if {$desc == ""} {
	set desc $label
    }
    if {$nyi} {
	set desc "$desc (NOT YET IMPLEMENTED)"
    }
    help_menu_add $w,$label $desc

    # create script for this menu entry
    set menu_cmd $cmd
    if { $point } {
      set menu_cmd [list point_mode_enter $menu_cmd]
    }
    if { $common } {
      set menu_cmd [list i_cmd_eval_common $menu_cmd]
    } elseif { $nowrap } {
      set menu_cmd [list eval $menu_cmd]
    } else {
      set menu_cmd [list i_cmd_eval $menu_cmd]
    }

    $w add command -label $label -command $menu_cmd \
      -state [expr {$nyi ? "disabled" : "normal"}]

    if {! $nyi} {
      # We always mode_bind now, even if event is null, to create
      # the MODE_DB data-base in case user might want to
      # map this command to a hot-key later.
      set cmdflag [expr ! $nowrap]
      mode_bind $modename $event $cmd \
	  -desc $desc -cmd $cmdflag -point $point -edit 1

      if { $perm != "" } {
	# Note: flags (-point, -edit, -desc) apply to the command,
	# not the event, so they must be the same for every key binding.
	mode_bind ${modename} $perm $cmd \
	  -desc $desc -cmd $cmdflag -point $point -edit 1
      }
    }
}

proc menu_add_widget {args} -desc {
  Add a menu widget, catching -desc to add help for it.
} -doc {
  Works for both menu-bar and popup menus.
  The args are a command that creates a menu entry,
  plus the following additions:
    
    -desc "help"  - the help for this menu entry.
    -accel <accelerator key>  - just a shorter synonym.

  The rest of the args are a normal menu widget command.
  Example:
    menu_add_widget $w add radiobutton -accel f -label "45 angles" \
	-variable foo -value 45 \
	-desc "Allow 45 degree wire segments"
} {
  # Other gets all other options.
  set script [call_use_keyword $args {{label ""} {desc ""}}]

  set script [concat $script [list -label $label]]
  # Create the menu widget.
  eval $script
  set menu [lindex $script 0]
  help_menu_add [lindex $menu 0],$label $desc
}


proc menu_add_cmd_fast {menu label cmd {desc ""}} -desc {
  add command to a menu (command setup so history, undo, etc. work properly)
} -doc {
  No frills version of menu_add_cmd.  
  Menu is the real internal menu name.
} {
    $menu add command -label $label -command [list i_cmd_eval $cmd]
    mode_bind main "" $cmd -desc $desc -cmd 1 -edit 1
    if { $desc != "" } {
	help_menu_add $menu,$label $desc
    }
}

proc menu_add_separator {menu} {
  $menu add separator
}

proc _menu_get_widget {label} -desc {
  return full name of menu widget given menu name.
} -doc {
  Example:
    _menu_get_widget File.Foo
  Returns:
    .win1.mbar.file.foo
} {
  global _MENU_BAR
  set mbar $_MENU_BAR(mbar)

  # Squeeze out all non-alpha-num chars, substitute ".menu" for first "->"
  # and "." for subsequent "->".  The first .menu is required
  # because of the extra menu_button widget required to traverse
  # the menu hierarchy.
  set fixname [string tolower $label]
  regsub -all { } $fixname "_" fixname
  regsub -all -- {->} $fixname "\4" fixname
  regsub -all "\[^0-9a-zA-Z_\4\]" $fixname "" fixname
  # widget is necessary
  regsub "\4" $fixname ".menu." fixname
  regsub -all "\4" $fixname "." fixname

  if { [string first "->" $label] > 0 } {
    return "${mbar}.${fixname}"
  } else {
    return "${mbar}.${fixname}.menu"
  }
}

proc _menu_bar_menu {label} -desc {
  create a new menu and add it to menu bar
} -doc {
  returns name of new menu button widget
  If the "Help" menu has already been added, insert before "Help".
} {
  global _MENU_BAR
  set mbar $_MENU_BAR(mbar)
  set fixname [menu_bar_fix_label $label]

  set mbutton $mbar.$fixname

  set menu $mbutton.menu
  menubutton $mbutton -text $label -menu $menu -padx 2 -pady 2
  set mpos "end"
  set button_list [use_first _MENU_BAR(button_list)]
  set menu_list [use_first _MENU_BAR(menu_list)]
  if {[lindex $button_list end] == "Help"} {
    pack $mbutton -side left -before [lindex $menu_list end]
    set mpos [expr [llength $button_list] - 2]
  } else {
    pack $mbutton -side left
  }
  set _MENU_BAR(button_list) [linsert $button_list $mpos $label]
  set _MENU_BAR(menu_list) [linsert $menu_list $mpos $mbutton]
  menu $menu

  assert { [_menu_get_widget $label] == $menu }
  return $menu
}


proc _menu_options {} {
  set prop_list ""

  lappend prop_list [list "Wire Setup..." {} -button wire_menu \
      -help "Prompt for wiring setup options"]
  lappend prop_list [list "Grid Setup..." {} -button grid_menu \
      -help "Prompt for grid setup options"]
  lappend prop_list [list "Flatten Setup..." {} -button flatten_setup  \
      -help "Setup for the flatten command"]
  lappend prop_list [list "Ruler Setup..."  {} -button ruler_menu \
      -help "Prompt for ruler setup options"]
  #lappend prop_list [list "Built-in DRC Setup..." {} -button drc_setup_menu \
      -help "Prompt for DRC control options"]
  lappend prop_list [list "Select Net Setup..." {} -button select_net_menu \
      -help {Prompt for "Select Net" setup options}]
  lappend prop_list [list "Layout Generator Setup..." {} \
      -button "stdcell_setup -options" \
      -help {Prompt for "Layout Generator" setup options}]
  lappend prop_list [list "Display Options..." {} -button view_display_options\
      -help "Control visibility of database objects and window components"]
  lappend prop_list [list "General Setup..." {} -button misc_setup \
      -help {Prompt for miscellaneous options}]
  lappend prop_list [list "Color Editor..." {} -button "" -return -command edit_color \
      -help "Popup menu to edit layer color"]
  lappend prop_list [list "Hot-Keys..." {} -button "" -command keymap_edit \
      -help "Load or modify a keymap (list of current keyboard bindings)"]
  lappend prop_list [list "Save/Revert Options..." {} -button misc_save_config \
      -help "Save configuration options to disk"]

  set title "User Preferences"
  prop_menu2 -title $title -buttons "Close=0=default" $prop_list
}

proc _menu_user_pref_build {w} -desc {
  returns new user preferences menu widget.
} {
  global VERSION_CONTROL_ENABLE
  set menu $w.move
  menu $menu -tearoff 1

  # Keep these sorted for user convenience
  menu_add_cmd $menu "Color Editor..." -nowrap edit_color \
      -desc "Popup menu to edit layer color"
  menu_add_cmd $menu "Display Options..." -nowrap view_display_options\
      -desc "Control visibility of database objects and window components"
  menu_add_cmd $menu "Flatten Setup..." -nowrap flatten_setup  \
      -desc "Setup for the flatten command"
  menu_add_cmd $menu "General Setup..." -nowrap misc_setup \
      -desc {Prompt for miscellaneous options}
  menu_add_cmd $menu "Grid Setup..." -nowrap grid_menu G -common \
      -desc "Prompt for grid setup options"
  menu_add_cmd $menu "Hot-Keys..." -nowrap keymap_edit \
      -desc "Load or modify a keymap (list of current keyboard bindings)"
  menu_add_cmd $menu "Layout Generator Setup..." -nowrap \
      "stdcell_setup -options" \
      -desc {Prompt for "Layout Generator" setup options}
  menu_add_cmd $menu "Ruler Setup..."  -nowrap ruler_menu \
      -desc "Prompt for ruler setup options"
  if {[use_first VERSION_CONTROL_ENABLE '0]} {
    menu_add_cmd $menu "VC Setup..." -nowrap vcs_setup_menu \
	-desc "Prompt for Version Control System setup options"
  }
  menu_add_cmd $menu "Wire Setup..." -nowrap wire_menu W \
      -desc "Prompt for wiring setup options"
  menu_add_cmd $menu "Save/Revert Options..." -nowrap misc_save_config \
      -desc "Save configuration options to disk"

  #menu_add_cmd $menu "Select Net Setup..." -nowrap select_net_menu \
      -desc {Prompt for "Select Net" setup options}

  return $menu
}


proc _menu_bar_traverse {prefix menu} {

  set list ""

  set n [$menu index end]
  for {set i 0} {$i <= $n} {incr i} {
    set type [$menu type $i]
    switch -- $type {
      separator { continue }
      checkbutton -
      radiobutton -
      command {
	set label [$menu entrycget $i -label]
	set fullcmd [$menu entrycget $i -command]
	# Strip off the eval part of the command.
	set cmd [lindex $fullcmd 1]
	# Strip off the optional "point_mode_enter"
	if {[lindex $cmd 0] == "point_mode_enter"} {
	  set cmd [lindex $cmd 1]
	}
	global MAX_DEVELOPER
	if { $type=="checkbutton" || $type=="radiobutton" || $cmd != "" } {
	  lappend list [list "${prefix}->${label}" $cmd]
	} elseif { $MAX_DEVELOPER } {
	  # This might be a bug; print a warning.
	  # puts "Skipping menu entry $label"
	}
      }
      cascade {
	set submenu [$menu entrycget $i -menu]
	set label [$menu entrycget $i -label]
	set list [concat $list \
	      [_menu_bar_traverse "${prefix}->${label}" $submenu]]
      }
    }
  }
  return $list
}


proc menu_bar_get {} -desc {
  Return the current contents of the menus.
} -doc {
  Returned as a list of {menu_name command}
  where the menu_name is something like "File->New..."
} {
  global _MENU_BAR
  set list ""

  # Foreach of of the top-level menus and their labels.
  for {set nn 0} {$nn < [llength $_MENU_BAR(button_list)]} {incr nn} {
    set button [lindex $_MENU_BAR(button_list) $nn]
    set menu [lindex $_MENU_BAR(menu_list) $nn].menu

    set list [concat $list [_menu_bar_traverse ${button} $menu]]
  }

  return $list
}

proc menu_bar_command {label} -desc {
  Return the command associated with the menu item identified by label.
} {
  global _MENU_BAR_CMD_CACHE

  if {! [info exists _MENU_BAR_CMD_CACHE] } {
    set menu_info [menu_bar_get]

    foreach thing $menu_info {
      setl {label command} $thing
      set fix_label [menu_bar_fix_label $label]
      set _MENU_BAR_CMD_CACHE($fix_label) $command
    }
  }

  return [use_first _MENU_BAR_CMD_CACHE([menu_bar_fix_label $label])]
}


proc menu_bar_fix_label {menu_label} -desc {
  Convert menu label into the index used in the KEYS array.
} {
  regsub -all {^.*->} $menu_label "" label
  regsub -all {[^a-zA-Z0-9_ ]} $label "" label
  regsub -all { } $label "_" label
  return [string tolower $label]
}


proc _menu_bar_update2 {menu} {
  # Cant pass array as arg.  Does this language suck, or what?
  upvar map_cmd2event map_cmd2event
  set n [$menu index end]
  for {set i 0} {$i <= $n} {incr i} {
    set type [$menu type $i]
    switch -- $type {
      separator { continue }
      checkbutton -
      radiobutton -
      command {
	# Each menu entry is a list of two items: the first is an
	# eval, and the second is the actual command.
	set fullcmd [$menu entrycget $i -command]
	# The first element is an eval, the second is the command.
	# Strip off the eval part of the command.
	set cmd [lindex $fullcmd 1]
	# Strip off the optional "point_mode_enter"
	if {[lindex $cmd 0] == "point_mode_enter"} {
	  set cmd [lindex $cmd 1]
	}
	set event [use_first map_cmd2event($cmd)]
	# Sometimes when the command is empty, the event is
	# set to a space.  Dont know why, but prevent it.
	# When we map space, we use <Space>.
	if { [string trim $event] != "" } {
	  $menu entryconfigure $i -accelerator [seq_pp $event]
	} else {
	  $menu entryconfigure $i -accelerator " "
	}
      }
      cascade {
	set submenu [$menu entrycget $i -menu]
	_menu_bar_update2 $submenu
      }
    }
  }
}


proc menu_bar_update {} -desc {
  Update menu_bar visible accelerators to match 
  current main and common mode bindings.
} {
  global _MENU_BAR

  # Make a reverse keymap hash-table, to map command to accelerator.
  set map_cmd2event("dummy-dummy-dummy") ""
  foreach mode {main common} {
    foreach thing [mode_events $mode] {
      struct mode_event e $thing
      # We will not put the L key or HELP or Control-z key bindings in the menu,
      # if there is another hotkey binding available.
      if {!([regexp -nocase {<L[0-9]+|.*help|Control-z>} ${e.event}] && \
	    [info exists map_cmd2event(${e.cmd})])} {
	set map_cmd2event(${e.cmd}) ${e.event}
      }
    }
  }

  # Foreach of of the top-level menus.
  foreach thing $_MENU_BAR(menu_list) {
    set menu ${thing}.menu
    _menu_bar_update2 $menu
  }
}


proc menu_bar_build {w} -desc {
  returns new menu_bar under w (does not pack it)
} {
  global _MENU_BAR MAX_DEVELOPER MMI_TOOLS
  global VERSION_CONTROL_ENABLE

  # Note: On a Sun keyboard:
  #  F11/L1 is the "stop" key
  #  F12/L2 is the "Again" key
  #  F13/L3 is the "Props" key
  #  F14/L4 is the "undo" key
  #  F16/L6 is the "Copy" key
  #  F17/L7 is the "open" key
  #  F18/L8 is the "Paste" key
  #  F19/L9 is the "Find" key
  #  F20/L10 is the "Cut" key

  ####
  ####   Additional hot-keys.
  ####

  # These are some additional hot-key bindings that do not
  # currently appear in the menus.  They are included here
  # because we build up the rest of the hot-key data-base here.

  # These are in the options menu, but we dont have any way to
  # bind them there.

  # Add some grid select commands.
  global GRID
  for {set n 1} {$n <= 9 && $n <= $GRID(ngrids)} {incr n} {
    mode_bind common -cmd 0 -desc "Select grid number $n" $n "grid_select $n"
  }

  ####
  ####   Build menus
  ####

  # Global var contains name of menu we are currently building.
  set mbar ${w}.mbar
  set _MENU_BAR(mbar) $mbar
  set _MENU_BAR(menu_list) {}

  ### create menubar widget
  frame $mbar -relief raised -bd 2

  ### File menu
  set menu [_menu_bar_menu File]
  menu_add_cmd $menu "New..."  cell_new 	<Control-n> \
      -desc "Prompt for new cell name, create cell, edit in current window"
  menu_add_cmd $menu "Open..." cell_open <Control-l> -perm <L7> \
      -desc "Prompt for cell name, load into current window"

  menu_add_separator $menu
  menu_add_cmd $menu "Save"    cell_save 	<Control-s> \
      -desc "Save edit cell in current window to disk"
  menu_add_cmd $menu "Save As..." "cell_copy 1" \
      -desc "Rename edit cell in current window and save to disk"

  set submenu $menu.save_mult
  menu $submenu -tearoff 0
  menu_add_cmd_fast $submenu "save edit cell and descendents" cell_save_tree \
    "Saves the edit cell, if modified, and any descendents that are modified"
  menu_add_cmd_fast $submenu "save all modified cell buffers" saveall \
    "Saves all cell buffers (cells in memory) that have been modified"
  menu_add_widget $menu add cascade -label "Save Multiple" \
    -menu $submenu \
    -desc "Save multiple cells"

  #menu_add_cmd $menu "Save and Descendents" cell_save_tree <Control-w> \
  #    -desc "Saves the editcell if modified and any descendents that are modified"


  # Revert...
  if {! [use_first VERSION_CONTROL_ENABLE '0]} {
    menu_add_cmd $menu "Revert to Last Saved"  cell_revert \
        -desc "Revert edit cell buffer to last version saved to disk"
  }

  menu_add_cmd $menu "Copy Cell Buffer..."	cell_copy \
      -desc "Prompt for new cell buffer name (and directory), and copy edit cell into it"
  menu_add_cmd $menu "Delete Cell Buffer"     cell_delete \
      -desc "Delete edit cell buffer (does not effect disk version)"
  #menu_add_cmd $menu "Rename Cell Buffer"	cell_rename \
      -desc "Prompt for new cell buffer name (and directory), and rename current cell"
  menu_add_cmd $menu "Change Path of Cell..."	cell_change_path \
    -desc "Change directory where cell will be saved."

  menu_add_separator $menu
  menu_add_cmd $menu "Toggle Read-Only..." {db_cell_read_only [expr ![db_cell_read_only]]} \
	-desc "Make file read-only or not"

  if {[use_first VERSION_CONTROL_ENABLE '0]} {
    # Version Control Stuff...
    menu_add_separator $menu
    menu_add_cmd $menu "Version Control..." vcs_menu \
	-desc "Version control set up and manual commands"


    set submenu $menu.revert
    menu $submenu -tearoff 0
    menu_add_cmd_fast $submenu "revert cell to last saved" cell_revert \
      "Revert edit cell buffer to last version saved to disk"
    menu_add_cmd_fast $submenu "revert cell to archive version..." \
      "vcs_revert" \
      "Revert edit cell buffer to a version committed to VC archive"

    menu_add_widget $menu add cascade -label "Revert" \
      -menu $submenu \
      -desc "Revert edit cell buffer to previous version"

      if {0} {
	menu_add_widget $menu add cascade -label "VC Commit" \
	  -menu [vcs_sub_menu $menu commit] \
	  -desc "Commit (check in) file(s) to Version Control System"
	menu_add_widget $menu add cascade -label "VC Update" \
	  -menu [vcs_sub_menu $menu update] \
	  -desc "Update local file(s) from Version Control System"
	menu_add_widget $menu add cascade -label "VC Lock" \
	  -menu [vcs_sub_menu $menu lock] \
	  -desc "Lock file(s) for exclusive use"
	menu_add_widget $menu add cascade -label "VC Unlock" \
	  -menu [vcs_sub_menu $menu unlock] \
	  -desc "Unlock file(s) so others can modify them"
      }
  }

  menu_add_separator $menu
  menu_add_cmd $menu "Import File..." cell_import \
    -desc "Read in GDS or other supported type file"
  menu_add_cmd $menu "Export File..." cell_export \
    -desc "Write out GDS or other supported type file"

  #menu_add_cmd $menu "Import GDSII..."  cell_load_gds \
      -desc "Prompt user for gds file, read it in, load toplevel cell into window"
  #menu_add_cmd $menu "Import GDSII Setup..."  gds_import_setup \
      -desc "Prompt for GDSII import options"

  # menu_add_cmd $menu "Import Magic..."  cell_load_magic

  #menu_add_cmd $menu "Export GDSII"  gds_write \
      -desc "Write gds of current cell to cell's directory"

  # NOTE: gds_export_setup is minimal for now
  #menu_add_cmd $menu "Export GDSII Setup..."  gds_export_setup \
      -desc "Popup menu of GDSII export options"

  menu_add_cmd $menu "GDSII -> ASCII..."   cell_gds2ascii \
      -desc "Prompt for GDS file, translate GDS to ASCII (foo.gds -> foo.gds_ascii)"

  #menu_add_separator $menu
  #menu_add_cmd $menu "Import lef..." read_lef {} \
    -desc "Read .lef file"
  #menu_add_cmd $menu "Export lef..."   write_lef {} \
    -desc "Write current cell to .lef format"

  #menu_add_separator $menu
  #menu_add_cmd $menu "Import def..." read_def {} \
    -desc "Read .def file"
  #menu_add_cmd $menu "Export def" write_def {} \
    -desc "Write current cell to .def format"

  # Pat - Took these out for max 4.0.  Will implement later.
  #menu_add_separator $menu
  #menu_add_cmd $menu "Toggle Read Only"	{} -nyi
  #menu_add_cmd $menu "Check File System"	{} -nyi

  menu_add_separator $menu
  #menu_add_cmd $menu "Print..."  	       print_cell \
  #    -desc "Prompt for print setup, then print the current cell"

  # menu_add_cmd $menu "Print Cell and Descendents" print_tree -nyi

  #menu_add_widget $menu add cascade -label "Print Setup" \
  #  -menu [_menu_print_setup $menu] \
  #  -desc "Select type of plot to print"

  menu_add_separator $menu

  # When the user preferences are implemented as a prop_menu, we
  # need to add W and G separately.  If its a cascade menu, not needed.
  #menu_add_cmd $menu "User Preferences..."  _menu_options  {} \
      -desc "Edit/save user preferences and options."
  #mode_bind main -cmd 0 -desc "Wire Setup Menu" W wire_menu 
  #mode_bind main -cmd 0 -desc "Grid Setup Menu" G grid_menu 

  menu_add_widget $menu add cascade -label "User Preferences" \
    -menu [_menu_user_pref_build $menu] \
    -desc "User controllable options"

  menu_add_separator $menu
  menu_add_cmd $menu "Exit"  cell_exit        <Control-d> \
      -desc "Exit max, but if modified buffers exist query user first."

  ### Edit menu
  set menu [_menu_bar_menu Edit]

  menu_add_cmd $menu "Undo" undo u -perm <L4> -nowrap \
	  -desc "Undo last change (may be used multiple times)"
  menu_add_cmd $menu "Redo" redo U -nowrap \
	  -desc "Redo what was just undone (may be used multiple times)"

  # This is disabled because it doesnt work!
  #menu_add_cmd $menu "Repeat Last Long Command" i_cmd_eval_last . -nowrap

  menu_add_separator $menu
  menu_add_cmd $menu "Cut to Clipboard"    clipboard_cut   <Alt-x> -perm <L10>
  menu_add_cmd $menu "Copy to Clipboard"   clipboard_copy  <Alt-c> -perm <L6>
  menu_add_cmd $menu "Paste from Clipboard"  clipboard_paste <Alt-v> -perm <L8> -nowrap
  menu_add_separator $menu
  menu_add_cmd $menu "Add Wire"             wire_mode_enter	w -nowrap \
      -desc "Draw a wire by entering verticies with mouse"
  menu_add_cmd $menu "Add Text"              label_add t -nowrap \
      -desc "Create a new text label"
  menu_add_cmd $menu "Add Polygon" "polygon_mode_enter 0" P -nowrap \
      -desc "Draw a polygon (can be non-manhattan)"
  menu_add_cmd $menu "Add Circle" "circle_mode_enter" "" -nowrap \
	  -desc "Draw a cirle/donut"
  menu_add_cmd $menu "Array Cell..."       cell_array {} {} \
      -desc "Create/edit array indicies or spacing for a cell"

  #menu_add_cmd $menu "Edit Wire"         rewire_mode_enter	R -nowrap \
      -desc "Move wire segment."

  #menu_add_cmd $menu "Edit Text..."          edit_label T -nowrap \
      -desc "Change the selected label"
  # 8/13/01: New label editor.
  menu_add_cmd $menu "Edit Text..."          label_lbox T -nowrap \
      -desc "Change the selected label"

  menu_add_cmd $menu "Edit Multiple Text..."       change_labels \
      -desc "Change multiple selected labels at once via menu"
  menu_add_cmd $menu "Edit Edge"  edge_mode_enter a -nowrap \
      -desc "Select paint edge with mouse, then move the edge"


  # You now edit polygon by selecting it and using Edit Object.
  #menu_add_cmd $menu "Edit Polygon"  "polygon_edit" "" -nowrap \
  #   -desc "Edit selected polygon"


  menu_add_cmd $menu "Edit Flylines"   "flyline_mode_enter" <Control-f> \
      -desc "Add or remove flylines"
  menu_add_cmd $menu "Edit Properties..."   "edit_any props"  p -perm <L3> \
      -desc "Edit properties of selected object"

  menu_add_separator $menu
  menu_add_cmd $menu "Delete"     delete q -perm <Delete> \
      -desc "Delete the selection"
  menu_add_cmd $menu "Duplicate"	duplicate_mode_enter d -nowrap \
      -desc "Duplicate the selection"
  # 4-00: move these into a sub-menu just to make the Edit menu shorter.
  # These are rarely used, anyway.
  menu_add_widget $menu add cascade -label "Flip/Rotate" \
    -menu [_menu_flip_build $menu] \
    -desc "Flip or Rotate selected objects"

  menu_add_widget $menu add cascade -label "Move" \
    -menu [_menu_move_build $menu] \
    -desc "Move selection"

  menu_add_widget $menu add cascade -label "Stretch" \
    -menu [_menu_stretch_build $menu] \
    -desc "Stretch selection one step over"

  menu_add_widget $menu add cascade -label "Fill" \
    -menu [_menu_extend_build $menu] \
    -desc "Fill paint across box"

  menu_add_cmd $menu "Align Objects..." align_objects  <Control-a> \
      -desc "Aligns selected objects, which must be all the same type."


  #menu_add_cmd $menu "Rotate"                 :clockwise      r \
      -desc "Rotate selection and box clockwise"
  #menu_add_cmd $menu "Flip Upside-Down"       :upsidedown     y \
      -desc "Flip selection and box through the horizontal axis"
  #menu_add_cmd $menu "Flip Sideways"          :sideways       x \
      -desc "Flip selection and box through the vertical axis"



  ### View menu
  set menu [_menu_bar_menu View]

  menu_add_cmd $menu "Push into Cell"  edit_push      e \
      -desc "Push into (edit) selected cell"
  menu_add_cmd $menu "Pop out of Cell"      edit_pop       <Control-e> \
      -desc "Pop edit-stack to edit cell before Push"
  menu_add_cmd $menu "Edit Cell or Object in place"   edit_any  E \
      -desc "Edit selected object in place"
  menu_add_cmd $menu "Edit Cell containing paint" \
      "edit_push paint_in_place"  <Alt-e> \
      -desc "Edit cell in place that contains visible geometry under cursor" 

  menu_add_separator $menu
  menu_add_cmd $menu "Display Options..." view_display_options \
    -desc "Control visibility of database objects and window components"
  #menu_add_widget $menu add cascade -label "Display Options" \
    -menu [_menu_display_options_build $menu] \
    -desc "Display Options"


  # Mask sub-menu
  menu_add_separator $menu

  global MENU_BAR_MASK
  set MENU_BAR_MASK $menu.mask
  menu_add_widget $menu add cascade -label "See Mask" \
     -menu [menu $MENU_BAR_MASK] \
     -desc "Highlight layer mask in current view"
  # contents built by menu_see_cif_update


  menu_add_separator $menu
  menu_add_cmd $menu "Toggle Grid"   toggle_grid  g -common \
      -desc "Toggle grid on or off"
  menu_add_cmd $menu "Move Grid" \
      grid_move_enter  {} -common \
      -desc "Move grid origin with mouse"
  menu_add_separator $menu
  menu_add_cmd $menu "Center on Cursor" \
      view_center_cursor -common -point \
      -desc "Center view on cursor" 
  menu_add_cmd $menu "Zoom In on Cursor" \
      "view_zoom_cursor .5" j -perm <Control-z> -common -point \
      -desc "Zoom in on mouse cursor"
  menu_add_cmd $menu "Zoom to Area" \
      view_zoom_region z -common \
      -desc "Zoom to a location indicated by dragging a box with the mouse"
  menu_add_cmd $menu "Zoom Out" "view_zoom 2"   Z -common \
      -desc "Zoom out"
  menu_add_cmd $menu "Zoom to Fit Selected" zoom_to_selected V -common \
       -desc "Adjust view to current selection"
  menu_add_cmd $menu "Zoom to Fit Edit Cell" {view_cell -warp} v -common \
      -desc "Adjust view so current edit cell fills screen"
  menu_add_cmd $menu "Zoom to Fit All"     :view <Control-v> -common \
       -desc "Adjust view to see entire root cell"

  menu_add_separator $menu
  menu_add_cmd $menu "Internals, View Area" "lay_internals -area" i \
      -desc "View internals (down to paint) of all cell instances under box"
  menu_add_cmd $menu "Internals, Hide Area" \
      "lay_internals -area -hide" h \
      -desc "Hide internals of all cell instances under box"
  menu_add_cmd $menu "Internals, View Cell" lay_internals I \
      -desc "Show internals of selected cell instances" 
  menu_add_cmd $menu "Internals, Hide Cell" \
      "lay_internals -hide" H \
      -desc "Hide internals of selected cell instances"

  if {0} {
    # 8/22/01: Take this out for the release.
    menu_add_separator $menu
    menu_add_cmd $menu "Log File..." msg_log_file_menu \
	 -desc "Control max logging of messages to file"
  }

  menu_add_separator $menu
  menu_add_cmd $menu "Display Cell Doc" \
      "misc_display_doc_file" D \
      -desc "Displays <cell_name>.doc or <cell_name>.html in an editor or browser"


  ### Tool menu (intended for interfaces to external tools)
  ### Menu entries can be added from .maxrc with menu_tool_cmd proc
  # anything added with menu_tool_cmd goes after the last entry
  # in the Tool menu defined here.

  set menu [_menu_bar_menu Tool]

  menu_add_cmd $menu "SUE Cross Probe Init."  sue_cross_probe_init {} \
    -desc "Start SUE, prepare for Cross Probing"
  menu_add_cmd $menu "SUE Cross Probe"    sue_cross_probe   k \
    -desc "Highlight the selected net in the SUE schematic"
  menu_add_cmd $menu "SUE LVS" lvs_it_max {} \
    -desc "Compare layout of current cell to SUE schematic with same name"

  #menu_add_separator $menu
  #menu_add_cmd $menu "Extract to ext" extract_it {} \
    -desc "Extract current cell to .ext file"
  #menu_add_cmd $menu "Extract to spice" extract_spice {} \
    -desc "Extract current cell to spice file"


  ### Misc menu
  set menu [_menu_bar_menu Misc]
  menu_add_cmd $menu "Make/move Box"           box_mode_enter       b -nowrap \
      -desc "Draw a new cursor box with the mouse"
  menu_add_cmd $menu "Box Dimensions"     box_dim_edit         B -nowrap \
      -desc "Prompt for cursor box dimensions"
  menu_add_cmd $menu "Goto Coordinates"   box_goto_coords <Control-b> -nowrap \
      -desc "Prompt for location and move mouse cursor there"

  menu_add_cmd $menu "Measure"                measure 	     m \
      -desc "Place the box in the largest area unoccupied by visible layers"
  menu_add_cmd $menu "Ruler"                  ruler_mode_enter     \
      <Control-r> -common \
      -desc "Start drawing a ruler"
  menu_add_cmd $menu "Ruler Clear" ruler_clear \
      -desc "Erase all rulers"

  menu_add_separator $menu
  menu_add_cmd $menu "Group Objects"   gcell_group_objects  <Control-g> \
      -desc "Create group containing selected objects."
  menu_add_cmd $menu "Ungroup Objects"   gcell_ungroup_objects {}  \
      -desc "Ungroup the selected group, a.k.a. flatten"
  menu_add_cmd $menu "Flatten Cells..." "flatten_cells -show_menu"     {} \
      -desc "Flattens (explodes) selected cells (only one level of hierarchy)."
 
  menu_add_cmd $menu "Generate layers..."  generate_layers {} \
      -desc "Auto-Generate layers from existing geometry"

  menu_add_separator $menu
  menu_add_cmd $menu "DRC Results..." "feedback_window" -nowrap \
      -desc "Display the DRC error feedback window"
  menu_add_cmd $menu "DRC Find Next Error"   -nowrap find_next_error      N \
      -desc "Print next DRC error, and center in display"
  menu_add_cmd $menu "DRC Find Next Kind of Error" "find_next_error kind" \
      -nowrap -desc "Find next type of DRC error, and center in display"
  menu_add_cmd $menu "Explain DRC under Box " ":drc check ; :drc why"  Y \
      -desc "Explain any Design Rule Violations under the cursor box"

  menu_add_separator $menu
  menu_add_cmd $menu "Clear Selection"        "sel_clear" c \
      -desc "Unselect any selected objects"
  menu_add_cmd $menu "Select under Box" {select_area} S \
      -desc "Select area under current box"
  menu_add_cmd $menu "Select under Box (add)" {select_area -more} \
      -desc "Select area under box, add to existing selection"

  # Note: this is going to go in the probe, eventually.
  #menu_add_cmd $menu "Find Cell at point..."  {mode_push sel_cell}      -point\
      -desc "Displays cell hierarchy at any point, and edits cells"
  menu_add_cmd $menu "Select Cell by Name..."     select_cell_by_name      {} \
      -desc "Select all cells of a given type"
  menu_add_cmd $menu "Select Cell" {select_cell_point 1}       f -point \
      -desc "Select a cell under cursor (repeat to cycle through all\
      cells under cursor)"

  menu_add_cmd $menu "Select Cell (add)" {select_cell_point 1 more}  F -point\
      -desc "Add a cell under cursor to selection (repeat to cycle\
      through all cells under cursor)"
  menu_add_cmd $menu "Select Cell (sub)" {select_cell_point 0 less} \
      <Alt-f> -point \
      -desc "Add a cell under cursor to selection (repeat to cycle\
      through all cells under cursor)"

  menu_add_cmd $menu "Select Net" \
      select_cursed_net  s -point \
      -desc "Select net under cursor" 
  menu_add_cmd $menu "Select Net (add)" \
      "select_cursed_net add"  -point \
      -desc "Add selected net under cursor to selection" 

  menu_add_cmd $menu "Select Net by Name..."  sel_net_by_name n \
      -desc "Select all nets connected to a given label name"

  menu_add_cmd $menu "Probe..." {probe_init} \
      <Control-Button-1> -point \
      -desc "Popup window of objects under cursor"

  #menu_add_separator $menu
  #menu_add_cmd $menu "Abort mode"  mode_abort -perm <Any-Control-c> -common \
      -desc "Abort (and undo) command submode, all the way up to main mode."
  #menu_add_cmd $menu "End mode"    mode_end   -perm <Escape>    -common \
      -desc "Exit (but dont undo) command submode, all the way up to main mode."

  if {0} {
  # original Options Menu
  set menu [_menu_bar_menu Option]
  menu_add_cmd $menu "Wire Setup..."         wire_menu W \
      -desc "Prompt for wiring setup options"
  menu_add_cmd $menu "Grid Setup..."         grid_menu G -common \
      -desc "Prompt for grid setup options"
  menu_add_cmd $menu "Flatten Setup..."      flatten_setup  \
      -desc "Setup for the flatten command"
  menu_add_cmd $menu "Ruler Setup..."            ruler_menu \
      -desc "Prompt for ruler setup options"
  menu_add_cmd $menu "Built-in DRC Setup..." drc_setup_menu \
      -desc "Prompt for DRC control options"
  menu_add_cmd $menu "Select Net Setup..." select_net_menu \
      -desc {Prompt for "Select Net" setup options}
  menu_add_cmd $menu "Layout Generator Setup..." stdcell_setup \
      -desc {Prompt for "Layout Generator" setup options}
  menu_add_cmd $menu "General Setup..." misc_setup \
      -desc {Prompt for miscellaneous options}
  menu_add_cmd $menu "Color Editor..." edit_color \
      -desc "Popup menu to edit layer color"
  menu_add_separator $menu
  menu_add_cmd $menu "Save Options..."   misc_save_config \
      -desc "Save configuration options to disk"
  }


  ### Local menu  (intended for local site or user to add menu items)
  ### menu entries can be added from .maxrc with menu_local_cmd proc
  _menu_bar_menu Local


  ### Developer menu  (intended for stuff we don't want end user to see)
  if {$MAX_DEVELOPER!=0} {
    set menu [_menu_bar_menu Developer]
    _menu_developer_build $menu
  }


  ### Help menu
  set menu [_menu_bar_menu Help]
  menu_add_cmd $menu "About MAX..."      help_about_max  \
      -desc "MAX version and configuration information"
  menu_add_separator $menu
  # Note: A binding <Help> will work sometimes, especially if you
  # press a couple in a row, but mostly seems ignored.
  # I speculate that something else already the Help key bound, and Tk
  # is fighting it for control.  A bind on KeyRelease-Help works reliably.
  menu_add_cmd $menu "Current Hot Keys..." mode_box \
      <space> -perm <KeyRelease-Help> -common \
      -desc "Popup hot key list"
  menu_add_cmd $menu "Text Commands/Variables..."  doc_box \
      -desc "Popup text command documentation"
  menu_add_separator $menu
  menu_add_cmd $menu "MAX Manual" \
      {browser_open [mn_sys_find doc/max_manual/max_manual.html]} \
      -desc "Detailed MAX reference"
  menu_add_cmd $menu "MAX Tutorial" \
      {exec mmi_tutorial MAX &} \
      -desc "Step by step, hands on introduction to MAX"
  #menu_add_cmd $menu "MAX Tutorial" \
      {browser_open [mn_sys_find doc/max_tutorial/max_tutorial.html]} \
      -desc "Step by step, hands on introduction to MAX"
  menu_add_separator $menu
  menu_add_cmd $menu "MCC Manual" \
      {browser_open [mn_sys_find doc/mcc_manual/mcc_manual.html]} \
      -desc "Detailed MCC (MegaCell Compiler) reference"
  menu_add_cmd $menu "MCC Tutorial" \
      {exec mmi_tutorial MCC &} \
      -desc "Step by step, hand on introduction to MCC (MegaCell Compiler)"
  menu_add_separator $menu
  menu_add_cmd $menu "MMI Documentation Guide"  \
	  "exec mmidoc &" \
	  -desc "Complete Micro Magic tools documentation"

  menu_add_separator $menu
  menu_add_cmd $menu "File Bug Report" \
	  "browser_open $MMI_TOOLS/bug_report.html"  \
	  -desc "File a bug report to Micro Magic"

  ### Declare as menu bar so user can "travel" across menus with button 1 
  ### down.
  eval tk_menuBar $mbar $_MENU_BAR(menu_list)

  # Update the accelerators.
  menu_bar_update

  return $mbar

}

proc _menu_developer_build {menu} -desc {
    builds developer menu
} {
    menu_add_cmd $menu "DRC Setup..." drc_setup_menu \
      -desc "Prompt for DRC control options"
    menu_add_cmd $menu "Long Command" {global max_win; i_cmd_eval_box $max_win}  : -nowrap
    menu_add_cmd $menu "Re-Source tcl file" source_max_tcl 
    menu_add_cmd $menu "Re-Source .maxrc" max_source_maxrc 
    menu_add_separator $menu
    menu_add_cmd $menu "see hiddenLabels" ":see hiddenLabels"
    menu_add_cmd $menu "Edit Gcell Paint" "edit_push override"
    menu_add_cmd $menu "Gcell_edit_new" gcell_edit_new
    # Pat removed on advice that this is obsolete:
    # 5/00: re-enabled at Marshall's request.
    menu_add_cmd $menu "Test next_edge" next_mode_enter , -nowrap
    #menu_add_cmd $menu "Test Wire Paths" \
            -desc "Enter debugging mode for wire paths" \
	    "polygon_mode_enter 1" <Alt-w> -nowrap
}

proc _menu_print_setup {w} -desc {
select which type of print software to use
} -doc {
Its up to caller to issue "menubutton ..." or "$w add cascade ..." 
} {

  global PRINT

  set menu $w.print_setup
  menu $menu -tearoff 0

  # sets up a radiobutton for all possible print types.
  foreach type $PRINT(types) { 
    $menu add radiobutton -label $type -variable PRINT(type) -value $type
  }

  return $menu
}

proc menu_add_print_type {type} -desc {
  add additional print type to File/"Print Setup" menu.
} -doc {
    intended for use in .maxrc files
    requires supporting print_<type> routine
} {
    global PRINT max_win
    
    set menu $max_win.mbar.file.menu.print_setup

    lappend PRINT(types) $type
    $menu add radiobutton -label $type -variable PRINT(type) -value $type
}



proc menu_repeat {cmd dir amt} -desc {
  Bound to arrow keys to process repeated keys.
} -doc {
  Buffers arrow key events, then processes them with one command.
  Prevents the commands bound to arrow keys from running on
  after the arrow key is released.

  The <cmd> is move or stretch.  The <dir> and <amt> are args to <cmd>.

  Notes:
  During testing, found out that almost all the time is spent
  in the i_cmd_between.

  This command does its own command wrapping.
} {
  global _MENU_REPEAT

  if { $cmd == ":scroll" } {
    set cmd_between i_cmd_between_undos
  } else {
    set cmd_between i_cmd_between
  }

  # On first time through, init this.
  set _MENU_REPEAT(amt,$dir) [use_first _MENU_REPEAT(amt,$dir) '0]

  set old_dir [use_first _MENU_REPEAT(dir)]
  set old_cmd [use_first _MENU_REPEAT(cmd)]
  if { $dir != $old_dir || $cmd != $old_cmd } {
    # New dir or cmd: finish old_cmd in old_dir, if any.
    if { [use_first _MENU_REPEAT(amt,$old_dir) '0] > 0 } {
      eval $old_cmd $old_dir $_MENU_REPEAT(amt,$old_dir)
      eval $cmd_between
      set _MENU_REPEAT(amt,$old_dir) 0
    }
  }

  if { $_MENU_REPEAT(amt,$dir) == 0 } {
    # A new move in this direction.
    set _MENU_REPEAT(amt,$dir) $amt
    # This update allows additional arrow keys to be processed,
    # resulting in additional calls to this function, resulting
    # in _MENU_REPEAT(amt,$dir) being incremented, but with no other effects.
    update
    # Move by amount accumulated during update..
    eval $cmd $dir $_MENU_REPEAT(amt,$dir)
    eval $cmd_between
    set _MENU_REPEAT(amt,$dir) 0
  } else {
    # This is the branch that is executed during the update, above.
    set _MENU_REPEAT(amt,$dir) [expr $_MENU_REPEAT(amt,$dir) + $amt]
  }
  set _MENU_REPEAT(dir) $dir
  set _MENU_REPEAT(cmd) $cmd
}
    
proc _menu_move_build {w} -desc {
  returns new move menu widget
} -doc {
  Its up to caller to issue "menubutton ..." or "$w add cascade ..." 
} {
  set menu $w.move
  menu $menu -tearoff 0
  menu_add_cmd $menu "Move To..."  move_to \
    -desc {prompt for exact coordinates to move selection}
  menu_add_cmd $menu "Move To Point..."  move_point_enter -nowrap \
    -desc {prompt for two points, then move selection}
  menu_add_cmd $menu "Move To Box"  move_to_box \
    -desc {move selection lower-left corner to box lower-left corner}
  menu_add_cmd $menu "Move Edit Cell Origin..."  move_cell_origin \
    -desc {move origin of edit cell to specified coords, equivalent to moving entire cell contents}

  $menu add separator

  menu_add_cmd $menu "Move Left"  -nowrap \
	{menu_repeat :move left [res -userx]} <Shift-Left> \
	-desc "move selection left one user grid unit"
  menu_add_cmd $menu "Move Right" -nowrap \
	{menu_repeat :move right [res -userx]} <Shift-Right> \
	-desc "move selection right one user grid unit"
  menu_add_cmd $menu "Move Up"    -nowrap \
	{menu_repeat :move up [res -usery]}   <Shift-Up> \
	-desc "move selection up one user grid unit"
  menu_add_cmd $menu "Move Down"  -nowrap \
	{menu_repeat :move down [res -usery]} <Shift-Down> \
	-desc "move selection down one user grid unit"
  menu_add_cmd $menu "Move Left 10x"  -nowrap \
	{menu_repeat :move left [expr 10*[res -userx]]} \
	-desc "move selection left ten user grid units"
  menu_add_cmd $menu "Move Right 10x" -nowrap \
	{menu_repeat :move right [expr 10*[res -userx]]} \
	-desc "move selection right ten user grid units"
  menu_add_cmd $menu "Move Up 10x"    -nowrap \
	{menu_repeat :move up    [expr 10*[res -usery]]} \
	-desc "move selection up ten user grid units"
  menu_add_cmd $menu "Move Down 10x"  -nowrap \
	{menu_repeat :move down  [expr 10*[res -usery]]} \
	-desc "move selection down ten user grid units"

  return $menu
}

proc _menu_stretch_build {w} -desc {
  returns new stretch menu widget
} -doc {
  Its up to caller to issue "menubutton ..." or "$w add cascade ..." 
} {
  set menu $w.stretch
  menu $menu -tearoff 0

  menu_add_cmd $menu "Stretch Selected Gcell" gcell_stretch_mode_enter {} -nowrap
  
  $menu add separator

  menu_add_cmd $menu "Stretch Left"   -nowrap \
	{menu_repeat :stretch left [res -userx]}   <Left>
  menu_add_cmd $menu "Stretch Right"  -nowrap \
	{menu_repeat :stretch right [res -userx]}  <Right>
  menu_add_cmd $menu "Stretch Up"     -nowrap \
	{menu_repeat :stretch up [res -usery]}     <Up>
  menu_add_cmd $menu "Stretch Down"   -nowrap \
	{menu_repeat :stretch down [res -usery]}   <Down>
  menu_add_cmd $menu "Stretch Left 10x"  -nowrap \
	{menu_repeat :stretch left  [expr 10*[res -userx]]}
  menu_add_cmd $menu "Stretch Right 10x" -nowrap \
	{menu_repeat :stretch right [expr 10*[res -userx]]}
  menu_add_cmd $menu "Stretch Up 10x"    -nowrap \
	{menu_repeat :stretch up    [expr 10*[res -usery]]}
  menu_add_cmd $menu "Stretch Down 10x"  -nowrap \
	{menu_repeat :stretch down  [expr 10*[res -usery]]}
  return $menu
}

proc drc_errors {what x1 y1 x2 y2} -desc {
  If what == "count", return count of drc violations in specified area.
} {
  set save_box [layt_box exact]

  layt_box exact $x1 $y1 $x2 $y2
  msg_catch { :drc why } r i w
  if { [string match {*No errors*} $i] } {
    return 0
  } else {
    return 1
  }


  set layers error_p,error_s,error_ps
  layt_box exact $x1 $y1 $x2 $y2
  msg_catch { :drc check; drc why }
  :drc catchup
  set cnt [llength [db_search_l paint -area $x1 $y1 $x2 $y2 $layers]]
  eval layt_box exact $save_box
  if { $what == "count" } {
    return $cnt
  }
}

proc move_to_obs {cmd dir} -doc {
  dir is up, down, left or right.
  cmd is command to execute, :move or :stretch.
} {
  # BUGS:
  # If the user grid is large enough, the selection can zoom right
  # past a DRC error.

  set max_steps 10   ;# This is the max number of steps we will move it.

  # Find a box that encompasses the selection and the area where
  # we are going to try to move it.

  switch $dir {
    "down"  -
    "up"    { set ures [res -usery] }
    "left"  -
    "right" { set ures [res -userx] }
    default { assert {0} }
  }

  # Expand the search area a little to make sure we see the drc errors.
  # To make sure its big enough, we will determine the max_jump,
  # which I define as the maximum distance I can move something
  # with a reasonable confidence that it didnt jump completely
  # over an obstruction.  For ordinary layers interfering with
  # themselves, the max_jump is 2 * (width+min_sep).  However, some
  # layers can interfere with other layers at smaller separations.
  # Eg: in tech mmi18, poly width=.18, sep=.25, so poly radius is 0.86.
  # However, poly interacts with ndiff/pdiff at only 0.1 width,
  # and ndiff width is only 0.22. So if a poly wire is next to a min
  # width ndiff, the radius is only 0.64.  I am going to ignore this,
  # because I think it is very uncommon.
  set max_jump 1000
  set radius 0  ;# Interaction radius: max sep of two any layers.
  if {[llength [db_search_l cells -cell __SELECT__ -limit 2]]} {
    # We dont know what might be in the cell, so we will
    # use the min radius of any layer.
    set sel_layers [techinfo layer_order]
  } else {
    set sel_layers [sel_what types]
  }
  foreach l $sel_layers {
    set width [techinfo width $l "" opt]
    set sep [techinfo sep $l "" opt]
    set radius [max $radius $sep]
    if { $width == 0 || $sep == 0 } {
      # Irrelevant layer, like prb.  Ignore it.
      continue
    }
    # This is wrong: the new paint can just merge with the old, with no error,
    # so we can only jump by the separation.
    #set max_jump [min $max_jump [expr 2 * $width + 2 * $sep]]
    set max_jump [min $max_jump $sep]
  }
  if { $radius == 0 } {
    # Dont know what went wrong.  Make sure we add enough here.
    set radius 1
  }

  set radius [expr $radius + 2 * [res]]  ;# Make sure we cover the drc dots.

  # Compute the number of steps we can try to move per jump.
  set jsteps [min $max_steps [expr { int(floor($max_jump / $ures)) } ]]
  # This can happen if the user grid is big enough to jump
  # completely over stuff without getting a drc error.
  if { $jsteps == 0 } { set jsteps 1 }
#puts "max_jump=$max_jump ures=$ures jsteps=$jsteps"


  setl {x1 y1 x2 y2} [db_bbox -cell __SELECT__]

  # Expand the DRC error search zone out on all sides, in case a piece
  # of something in the selection interacts with something else around here.
  set x1 [expr $x1 - $radius]
  set x2 [expr $x2 + $radius]
  set y1 [expr $y1 - $radius]
  set y2 [expr $y2 + $radius]

  # How many drc errors are in this area currently?
  # The count function doesnt work, because cant determine
  # it from :drc why output, so we have to punt if there are any errors.
  if { [drc_errors count $x1 $y1 $x2 $y2] } {
    warning "Must fix existing DRC errors first"
    return
  }

  save_selection __MOVE_TO_OBS_TMP__
  # An undo delim was inserted by the i_cmd_eval that called us.
  #undo_delim
  set retry 1
  while { $retry } {
    set retry 0

    for {set s 0} {$s < $max_steps} {incr s $this_steps} {
      set this_steps [min $jsteps [expr $max_steps - $s]]
      set nexts [expr $s + $this_steps]
      # Determine the zone where we need to look for DRC errors.
      setl {zx1 zy1 zx2 zy2} [list $x1 $y1 $x2 $y2]
      switch $dir {
	"down"  { set zy1 [expr $y1 - $nexts * $ures] }
	"up"    { set zy2 [expr $y2 + $nexts * $ures] }
	"left"  { set zx1 [expr $x1 - $nexts * $ures] }
	"right" { set zx2 [expr $x2 + $nexts * $ures] }
      }

      eval $cmd $dir [expr $ures * $this_steps]

      if { [drc_errors count $zx1 $zy1 $zx2 $zy2] } {
	# Failed.  Undo all changes.
	undo_to_delim
	restore_selection __MOVE_TO_OBS_TMP__
	if { $jsteps == 1 } {
	  # really failed!
	  if { $s == 0 } {
	    # Couldnt move a single ures.  Give up.
	    return
	  } else {
	    # We succeeded up until the most recent ures.
	    # Redo the changes up to that point.
	    eval $cmd $dir [expr $ures * $s]
	    return
	  }
	} else {
	  # try again
	  set jsteps 1
	  set retry 1
	  break
	}
      }
    }
  }
}

proc _menu_flip_build {w} -desc {
returns new fill menu widget
} -doc {
Its up to caller to issue "menubutton ..." or "$w add cascade ..." 
} {
    set menu $w.flip
    menu $menu -tearoff 0
    menu_add_cmd $menu "Flip Upside-Down"       "api_flip y"   y \
	-desc "Flip selection and box through the horizontal axis"
    menu_add_cmd $menu "Flip Sideways"          "api_flip x"   x \
	-desc "Flip selection and box through the vertical axis"
    menu_add_cmd $menu "Rotate"                 "api_rotate"   r \
	-desc "Rotate selection and box clockwise"
    return $menu
}


proc _menu_extend_build {w} -desc {
  returns new fill menu widget
} -doc {
  Its up to caller to issue "menubutton ..." or "$w add cascade ..." 
} {
  set menu $w.extend
  menu $menu -tearoff 0
  if {1} {
    # Try out new names: Fill instead of Extend.
    menu_add_cmd $menu "Fill Left" \
	    -desc "Extend paint across box from right to left" \
	    {:fill left} <Control-Left>
    menu_add_cmd $menu "Fill Right" \
	    -desc "Extend paint across box from left to right" \
	    {:fill right} <Control-Right>
    menu_add_cmd $menu "Fill Up" \
	    -desc "Extend paint across box from bottom to top" \
	    {:fill up} <Control-Up>
    menu_add_cmd $menu "Fill Down" \
	    -desc "Extend paint across box from top to bottom" \
	    {:fill down} <Control-Down>
  } else {
    menu_add_cmd $menu "Extend Left" \
	    -desc "Extend paint across box from right to left" \
	    {:fill left}   <Control-Left>
    menu_add_cmd $menu "Extend Right" \
	    -desc "Extend paint across box from left to right" \
	    {:fill right}  <Control-Right>
    menu_add_cmd $menu "Extend Up" \
	    -desc "Extend paint across box from bottom to top" \
	    {:fill up}     <Control-Up>
    menu_add_cmd $menu "Extend Down" \
	    -desc "Extend paint across box from top to bottom" \
	    {:fill down}   <Control-Down>
  }
  return $menu
}


proc menu_add {args} -desc {
  Adds a menu item to the given MAX menu.
} -doc {
  USAGE:
  menu_add [-menu (File|Edit|View|Tool|Misc|Local|Floorplan|Help)]
	   [-label <name>]
	   [-command <command>]
	   [-hotkey <hotkey>]  (Not implemented!)
	   [-help <string>]
	   [-position <line>]  (Not implemented!)

  The <command> is executed when the user clicks on this <name> menu option
  or hits the optional hotkey.  The <string> help line will be displayed
  in the message window when the user has the cursor over the menu item.
  If the label <name> is "separator", then a separator line will
  be added to the menu.

  If no -menu is specifed, the menu defaults to the Local menu.
  If the <menu> is unrecognized, it is created.
  By default, the new menu option will be placed at the bottom of the
  specified menu.  To place it in another location, specify the <line>
  position, and it will try to place it at that line number.
} {
  global _MENU_BAR

  set options [list {menu "Local"} {label "?"} {command ""} {hotkey ""} \
    {help ""} {position ""}]
  set whatsleft [call_keyword $args $options]
  if {$whatsleft != ""} {
    error "unrecognized option to menu_add"
  }

  set i [lsearch2 -nocase $_MENU_BAR(button_list) $menu]
  if {$i == -1} {
    # Create a new menu right before the "Help" menu.
    _menu_bar_menu $menu
    set i [lsearch2 -nocase $_MENU_BAR(button_list) $menu]
    assert {$i != -1}
  }

  # This gets the correct case.  Eg, if menu was "local", will return "Local".
  set menu [lindex $_MENU_BAR(button_list) $i]

  set w [_menu_get_widget $menu]

  set cmd [list menu_add_cmd [_menu_get_widget $menu] $label $command]
  if {$hotkey != ""} {
    lappend cmd $hotkey
  }
  if {$help != ""} {
    lappend cmd -desc $help
  }
  eval $cmd
}


# TODO: This could call menu_add.
proc menu_local_cmd {entry_name tcl_script {desc ""}} -desc {
  add entry to "local" menu (intended for use in .maxrc files)
} -doc {
  The menu entry is setup to "i_cmd_eval tcl_script".  This makes the menu entry
  a bona-fide max command:  undo, history, etc. are handled correctly.

  Deletes any pre-existing entry of same name.
} {
    set menu [_menu_get_widget Local]
    if {$desc != ""} {
	menu_add_cmd $menu \
		-desc $desc \
		$entry_name $tcl_script
    } else {
	menu_add_cmd $menu \
		$entry_name $tcl_script
    }
}


proc menu_tool_cmd {entry_name tcl_script {desc ""}} -desc {
  add entry to "tool" menu (intended for use in .maxrc files)
} -doc {
  The menu entry is setup to "i_cmd_eval tcl_script".  This makes the menu entry
  a bona-fide max command:  undo, history, etc. are handled correctly.

  Deletes any pre-existing entry of same name.
} {
    set menu [_menu_get_widget Tool]
    if {$desc != ""} {
	menu_add_cmd $menu \
		-desc $desc \
		$entry_name $tcl_script
    } else {
	menu_add_cmd $menu \
		$entry_name $tcl_script
    }
}

proc _menu_add_see_cif {menu layer {comment ""}} {
    if {$comment != ""} {
	menu_add_cmd_fast $menu "see $layer ($comment)" "cif_see $layer"
    } else {
	menu_add_cmd_fast $menu "see $layer" "cif_see $layer"
    }
}

proc cif_see {layer} -desc {
display cif layer throughout current view
} {
    global max_win

    #set oldbox [eval [concat layt_box exact [$max_win.layout frame]]]
    set oldbox [eval layt_box exact [$max_win.layout frame]]

    :feedback clear
    :cif see $layer

    # restore box
    eval layt_box exact $oldbox
}

proc menu_see_cif_update {} -desc {
    build cif menu
} -doc {
    called prior to each interactive command.
} {
    global max_win see_cif 
    global MASK_MENU_ITEMS_PER_COL

    set ostyle [cif_ostyle]

    # no need to regen if cif ostyle hasn't changed since last time
    if { [info exists see_cif(last_ostyle)] && $see_cif(last_ostyle) == $ostyle \
      && $MASK_MENU_ITEMS_PER_COL == [use_first MASK_MENU_ITEMS_PER_COL_last '0]} {
	return
    }
    set MASK_MENU_ITEMS_PER_COL_last $MASK_MENU_ITEMS_PER_COL

    set see_cif(last_ostyle) $ostyle

    global MENU_BAR_MASK
    set menu $MENU_BAR_MASK

    # Makes the templayers a cascade menu (with a tearoff)
    set tmpmenu $menu.templayers
    catch "menu $tmpmenu -tearoff 1"

    # toast the old entries
    $menu delete 0 1000
    $tmpmenu delete 0 1000

    # Make a top-level menu that calls the gdsmenu and tmpmenu.
    menu_add_cmd_fast $menu "clear" clear_annotations \
	"clear mask layer display and transients"

    set gds_layers ""
    set tmp_layers ""
    foreach layer [split [cif_layers] \n] {
	setl {name calma_num calma_type flags} $layer 
	if {[memq $flags temp]} {
	  lappend tmp_layers $layer
	} else {
	  lappend gds_layers $layer
	}
    }

    # output gds layers 
    set cnt 0
    foreach layer $gds_layers {
	setl {name calma_num calma_type flags} $layer 
	  if { $calma_num != -1 } {
	      _menu_add_see_cif $menu $name "$calma_num $calma_type" 
	  } else {
	      _menu_add_see_cif $menu $name 
	  }
	# Start a new menu column every so often.
	if {[incr cnt] % $MASK_MENU_ITEMS_PER_COL == 0} {
	  $menu add command -label " " -columnbreak 1
	}
    }

    # This code makes the Mask menu two columns, but it
    # doesnt work very well because of tear-off indicator problems. (pat)
    # Add a blank entry at the start of column 2 so it lines
    # up with the "Clear" entry in column 1.
    #$menu add command -label " " -columnbreak 1
    # This is really stupid.  The tear-off indicator does not stretch
    # all the way across the column.  This doesnt really fix it,
    # but at least it makes the columns line up.
    #$menu insert last separator

    $menu add cascade -label "temp layers" -menu $tmpmenu

    # temp layers
    set cnt 0
    foreach layer $tmp_layers {
	setl {name calma_num calma_type flags} $layer 
	menu_add_cmd_fast $tmpmenu "see $name" "cif_see $name"
	# Start a new menu column every so often.
	if {[incr cnt] % $MASK_MENU_ITEMS_PER_COL == 0} {
	  $tmpmenu add command -label " " -columnbreak 1
	}
    }
}


proc _point_mode_define {} {
    mode_def point {} {enter point with the cursor}
    mode_bind point -cmd 0 -desc "Enter point with cursor" \
	    <Any-Button-1> \
	    _point_point
}

proc _point_point {} {
  global _POINT_MODE
  mode_pop
  eval $_POINT_MODE(cmd)
}

proc point_mode_enter {cmd} -desc {
  prompt user for a point, then execute cmd
} {
  global _POINT_MODE
  set _POINT_MODE(cmd) $cmd
  mode_push point
}
