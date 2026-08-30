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


# SUE window global variables
#
# WIN		current window.  For now always .win1
#
# WIN_DATA($WIN,)    array with the following fields
#  display_msg  Linked to the text window on the top right of 
#		of the window which contains (hopefully) useful information
#		about the mode, the selection, etc.
#  abort_cmd    tcl procedure to be called to abort out of a mode.  This
#		should be called if we have exited a mode illegally, e.g.
#		with an error.

# make a toplevel window.  We will put a canvas in it later
# NOTE: setup somewhat for multiple windows.

proc make_window {win} {

  global SNAP_XY WIN_DATA SUE_DIR GEOMETRY KEYS ICON_MENU 
  global ICONIFY COLORS SUFFIX

  # setup global variables associated with this window
  msg_window ""
  set WIN_DATA($win,abort_cmd) ""

  set WIN_DATA($win,title) ""

  catch {destroy $win}

  # Set up the main background color for all supporting windows/menubars
  if {$COLORS(main) == "old"} {
    tk_bisque
  } else {
    eval tk_setPalette $COLORS(main)
  }

  # Set this color to eliminate flicker when switching windows
  toplevel $win -bg $COLORS(background)

  if {[use_first ICONIFY] != ""} {
    wm iconify $win
  }

  wm geometry $win [use_first GEOMETRY(cmd) GEOMETRY(window)]
  wm minsize $win 400 300
  wm iconbitmap $win @$SUE_DIR/sue_icon.xbm

  # handle delete window protocols from window manager
  wm protocol $win WM_DELETE_WINDOW modify_exit

  # Menu bar
  frame $win.mbar -relief raised -bd 2
  pack $win.mbar -side top -fill x 
  
  # "File" submenu
  menubutton $win.mbar.file -text File -padx 2 -pady 2 \
      -menu $win.mbar.file.menu
  menu $win.mbar.file.menu

  menu_add -menu file -label "New Schematic..." -command make_new_schematic \
      -help "Prompt for the name of a new schematic and then create it."

  menu_add -menu file -label "New Icon..." \
      -command {
	if {[make_new_schematic {} I] != ""} {
	  add_properties_to_icon
	  zoom_to_fit
	}
      } \
      -help "Prompt for the name of a new icon and then create it."

  # used to be called load
  menu_add -menu file -label "Open..." -command load_schematic \
      -help "Prompt for the name of a schematic or icon and then load and display it."

  menu_add -menu file -label separator

  menu_add -menu file -label Save -command {write_file $cur_s} \
      -modify 1 \
      -help "Save the current cell and its associated icon or schematic to disk."

  menu_add -menu file -label "Save As..." \
      -command {if {[copy_schematic] != -1} {write_file $cur_s}} \
      -help "Prompt for a new name, copy the current cell to that name and save it."

  menu_add -menu file -label "Save and Descendents  " \
      -modify 1 \
      -command {global cur_s ; modified_save_and_leaves $cur_s} \
      -help "Save the current cell and all modified subcells to disk."

  menu_add -menu file -label "Revert to Last Saved" -command revert \
      -help "Revert current schematic/icon to last saved."

  menu_add -menu file -label "Copy..." -command copy_schematic \
      -help "Prompt for a new name and then copy the current cell to that name."

  menu_add -menu file -label "Change Path of Cell..." \
      -command change_path \
      -help "Prompt for a new file path (for saving) and change the file path of the current cell."

  menu_add -menu file -label separator

  menu_add -menu file -label "Toggle Read Only..." \
      -command toggle_read_only \
      -help "Menu of options to change read only status of current cell and/or all cells."

  menu_add -menu file -label separator

  menu_add -menu file -label "Check File System" -command check_filesystem \
      -help "Check SUE's file paths and display cell names which are in improper files or shadowed."

  if {$ICON_MENU == "flat" || $ICON_MENU == "hier"} {
    menu_add -menu file -label separator
    menu_add -menu file -label "Raise Windows" \
	-command {map_others "" raise} \
	-help "raise schematic/icon listbox windows to be visible."
  }

  menu_add -menu file -label separator

  menu_add -menu file -label Print -command make_ps \
      -help "Print the current cell based on the settings in the \"print setup\""

  menu_add -menu file -label "Print and Descendents" \
      -command {global cur_s ; print_and_leaves $cur_s} \
      -help "Print the current cell and all subcells"

  menu_add -menu file -label "Print Setup..." \
      -command print_setup \
      -help "Menu of print setup options"

  menu_add -menu file -label separator

  menu_add -menu file -label Exit -command modify_exit \
      -help "Prompt if there are modified and unsaved cells before exiting SUE."

  # "Edit" submenu
  menubutton $win.mbar.edit -text Edit -padx 2 -pady 2 \
      -menu $win.mbar.edit.menu
  menu $win.mbar.edit.menu

  menu_add -menu edit -label Undo -command undo_last \
      -modify 1 \
      -help "Undo the most recent change to the cell."

  menu_add -menu edit -label separator

  menu_add -menu edit -label "Cut to Clipboard" \
      -command {delete_selected_undo cut_to_clipboard ; delete_selected} \
      -modify 1 \
      -help "Delete the selected objects and put them into the clipboard."

  menu_add -menu edit -label "Copy to Clipboard   " \
      -command {delete_selected_undo copy_to_clipboard} \
      -help "Copy the selected objects into the clipboard to be pasted later."

  menu_add -menu edit -label "Paste from Clipboard" -command setup_paste_mode \
      -modify 1 \
      -help "Paste the contents of the clipboard into the current cell."

  menu_add -menu edit -label separator

  menu_add -menu edit -label "Add Wire" -command setup_draw_wire \
      -modify 1 \
      -help "Add a wire to the current schematic."

  menu_add -menu edit -label "Add Text" -command setup_text_mode \
      -modify 1 \
      -help "Add text into the current cell."

  menu_add -menu edit -label "Add Line/Rectangle" -command setup_line_mode \
      -modify 1 \
      -hotkey [use_first KEYS(add_line)] \
      -help "Add a line or a rectangle to the current cell."

  menu_add -menu edit -label "Add Arc" -command setup_arc_mode \
      -modify 1 \
      -help "Add an arc or a circle to the current cell."

  menu_add -menu edit -label separator

  menu_add -menu edit -label Delete -command delete_selected \
      -modify 1 \
      -help "Delete the selected objects from the cell."

  menu_add -menu edit -label Duplicate -command setup_duplicate_selected \
      -modify 1 \
      -help "Duplicate the current selection."

  menu_add -menu edit -label Rotate -command {transform_selected ROTATE} \
      -modify 1 \
      -help "Rotate the current selection 90 degrees clockwise."

  menu_add -menu edit -label "Flip Sideways" \
      -modify 1 \
      -command {transform_selected MX} \
      -help "Flip the current selection left-to-right."

  menu_add -menu edit -label "Flip Upsidedown" \
      -modify 1 \
      -command {transform_selected MY} \
      -help "Flip the current selection upsidedown."

  menu_add -menu edit -label Move -command setup_move_mode \
      -modify 1 \
      -help "Move the selected items (also Button-2 on highlighted object)."

  menu_add -menu edit -label "Edit Properties..." \
      -modify 1 \
      -command prop_edit_menu \
      -help "Edit the selected object/properties (like double-Button-1)."

  menu_add -menu edit -label "Edit Generator..." \
      -modify 1 \
      -command generator_edit_menu \
      -help "Edit the selected icon generator (like shift-double-Button-1)."

  menu_add -menu edit -label "Replace Instance" \
      -modify 1 \
      -command setup_replace_instance \
      -help "Replace the selected instance with another instance in the current cell."

  menu_add -menu edit -label "Duplicate Text" \
      -modify 1 \
      -command {setup_duplicate_selected text} \
      -help "Duplicate all selected text, even text inside an icon."

  menu_add -menu edit -label Lower \
      -modify 1 \
      -command lower_selected \
      -help "Lower the selected object in the display list to ease selection of nearby objects."

  menu_add -menu edit -label "Modify Properties...  " -command modify_selected \
      -modify 1 \
      -help "Prompt for icon property to be modified and then modify that property on all selected instances."

  menu_add -menu edit -label "Name Objects..." -command name_selected \
      -modify 1 \
      -help "Prompt for naming pattern and then name all selected objects."

  menu_add -menu edit -label "Object Name Editor..." \
      -command edit_selected_names \
      -modify 1 \
      -help "Start editor with names of all selected objects for modification."

  menu_add -menu edit -label separator

  menu_add -menu edit -label "Toggle Move Off-Grid ..." \
      -command toggle_move_grid \
      -help "Allows moves to be off grid using the Control key if toggled."

  menu_add -menu edit -label separator

  menu_add -menu edit -label "Delete Buffer" \
      -command {global cur_s ; delete_schematic $cur_s} \
      -help "Delete this buffer.  Does not delete associated icon/schematic or disk file."

  # "view" submenu
  menubutton $win.mbar.view -text View -padx 2 -pady 2 \
      -menu $win.mbar.view.menu
  menu $win.mbar.view.menu

  menu_add -menu view -label "Push Into" \
      -command push_into_schematic \
      -help "Edit the selected schematic or, if no schematic, icon."

  menu_add -menu view -label "Pop Out Of" \
      -command pop_out_of_schematic \
      -help "Return to editing the schematic that was current before \"push into\"."

  menu_add -menu view -label "Pop Connected" \
      -command pop_out_of_connected \
      -help "Pop up to calling schematic, select net connected selected net in lower schematic."

  menu_add -menu view -label "Swap Views" -command change_views \
      -help "View associated schematic or icon of current cell."

  menu_add -menu view -label "Swap Views Selected" \
      -command change_views_selected \
      -help "View associated schematic or icon of current cell and select any I/O's in the other view that were selected in the starting view."

  menu_add -menu view -label "Make Other View" -command make_other_view \
      -modify 1 \
      -help "Create associated schematic or icon of current cell."

  menu_add -menu view -label separator

  # weird case since x,y aren't known if coming from menu
  menu_add -menu view -label "Zoom In on Cursor" \
      -command "if \{\[catch \"zoom_on_cursor $SNAP_XY\"\]\} {zoom_on_cursor}" \
      -help "Zoom the window around the cursor position."

  menu_add -menu view -label "Zoom to Area" -command setup_zoom_box \
      -help "Drag a box to zoom into on the current cell."

  menu_add -menu view -label "Zoom Out" -command "zoom 0.7" \
      -help "Zoom the current cell out."

  menu_add -menu view -label "Zoom to Fit" -command zoom_to_fit \
      -help "Zoom to fit current cell to display."

  menu_add -menu view -label "Zoom to Fit Selected" \
      -command zoom_to_selected \
      -help "Zoom so all selected objects are centered on the screen."

  menu_add -menu view -label Pan -command setup_pan_canvas \
      -help "Pan around the current cell with the mouse."

  menu_add -menu view -label separator

  menu_add -menu view -label "Select by Name" -command select_by_name \
      -help "Prompt for a net or instance name and then select appropriate objects.  Wildcards (*) accepted."

  menu_add -menu view -label separator

  menu_add -menu view -label "Show Text Anchors" -command show_anchors \
      -help "Display the anchor location for all text in the given cell."

  menu_add -menu view -label "Show Sel. Term Names   " \
      -command show_icon_term_names \
      -help "Display the icon terminal names for the selected instances.  Works in DPC placements, too."

  menu_add -menu view -label "Show Inst. Origins" \
      -command show_instance_origins \
      -help "Display the origin locations for all instances in the given cell."

  menu_add -menu view -label separator

  menu_add -menu view -label "Toggle Grid" -command toggle_grid \
      -help "Toggle grid to be either visible or invisible."

  menu_add -menu view -label "Change Grid Spacing...  " \
      -command change_grid \
      -help "Prompt to change grid spacing."

  menu_add -menu view -label separator

  menu_add -menu view -label "Ruler" -command setup_ruler \
      -help "Drag a ruler to measure."

  menu_add -menu view -label "Ruler Setup ..." -command ruler_setup \
      -help "Prompt to change ruler parameters."

  menu_add -menu view -label separator

  menu_add -menu view -label "Display Cell Doc" -command display_file \
      -help "Displays <cell_name>$SUFFIX(cell_doc_text) or <cell_name>$SUFFIX(cell_doc_html) in an editor or browser."

  # "Sim" submenu (filled in depending on mode)
  menubutton $win.mbar.sim -text Sim -padx 2 -pady 2 \
      -menu $win.mbar.sim.menu
  menu $win.mbar.sim.menu

  # local menu
  menubutton $win.mbar.local -text Local -padx 2 -pady 2 \
      -menu $win.mbar.local.menu
  menu $win.mbar.local.menu

  # help menu
  menubutton $win.mbar.help -text Help -padx 2 -pady 2 \
      -menu $win.mbar.help.menu
  menu $win.mbar.help.menu

  menu_add -menu help -label "About SUE..." -command about_sue \
      -help "Display information about the current version of SUE in a popup window."

  menu_add -menu help -label separator

  # binding for hotkey/message help window
  menu_add -menu help -label "Current Hot Keys..." \
      -command "help_window %x %y" -hotkey space \
      -help "Display all current hotkeys (bindings) in the window under cursor for the current mode in a popup window."

  menu_add -menu help -label "Text Commands/Variables..." -command doc_box \
      -help "Displays a list of text commands and documentation in a popup window."

  menu_add -menu help -label separator

  menu_add -menu help -label "SUE Manual" -command "help manual" \
      -help "Display the SUE manual in an html browser or text window."

  menu_add -menu help -label "SUE FAQ" -command "help FAQ" \
      -help "Display the SUE Frequently Asked Questions (FAQ) list."

  menu_add -menu help -label "SUE Tutorial" -command "exec mmi_tutorial sue &" \
      -help "Install/View/Print tutorial on using SUE."

  menu_add -menu help -label separator

  menu_add -menu help -label "DPC Manual" -command "help dpc_manual" \
      -help "Display the SUE manual in an html browser or text window."

  menu_add -menu help -label "DPC Tutorial" -command "exec mmi_tutorial dpc &" \
      -help "Install/View/Print tutorial on using DPC."

  menu_add -menu help -label separator

  menu_add -menu help -label "MMI Documentation Guide" \
      -command "help mmi_doc" \
      -help "Display a guide to view documentation for all MMI tools in an html browser."

  menu_add -menu help -label separator

  menu_add -menu help -label "File Bug Report" \
      -command "help bug_report" \
      -help "File a bug report to Micro Magic."

  # pack the menu headings
  pack $win.mbar.file $win.mbar.edit $win.mbar.view $win.mbar.sim \
      $win.mbar.local $win.mbar.help -side left

  tk_menuBar $win.mbar $win.mbar.file $win.mbar.edit \
      $win.mbar.view $win.mbar.sim $win.mbar.local $win.mbar.help

  make_sim_menu $win startup

  # Feedback text line is to the right of the menu bar
  label $win.mbar.msg -relief sunken -bd 2 -anchor w \
      -textvariable WIN_DATA($win,display_msg)
  pack $win.mbar.msg -side left -fill x -expand yes

  if {$ICON_MENU != "flat" && $ICON_MENU != "hier"} { 
    # make the listbox frame and pack it in
    frame $win.lb -width 300
    pack $win.lb -side right -fill y

    # make a special frame for resizing the listboxes
    frame $win.resizelb -width 2
    pack $win.resizelb -side right -fill y
    bind $win.resizelb <Enter> "listbox_resize enter"
    bind $win.resizelb <Leave> "listbox_resize leave"
    bind $win.resizelb <Button-1> "listbox_resize start %X"
    bind $win.resizelb <Button1-Motion> "listbox_resize move %X"
    bind $win.resizelb <B1-ButtonRelease> "listbox_resize release"
  }

  # create the happy scrollbars
  scrollbar $win.vscroll -relief sunken -command "scroll_me yview" \
      -highlightthickness 0
  scrollbar $win.hscroll -orient horiz -relief sunken \
      -command "scroll_me xview" -highlightthickness 0

  pack $win.hscroll -side bottom -fill x
  pack $win.vscroll -side right -fill y

  # don't allow button motion in listboxes
  bind Listbox <B1-Motion> ""
  bind Listbox <B2-Motion> ""
  bind Listbox <B3-Motion> ""

  # so the tab doesn't screw up the focus.
  bind all <Tab> ""
  bind all <Shift-Tab> ""

  # for weird HP mice
  bind all <Button-4> ""
  bind all <Button-5> ""

  bind $win <Unmap> {map_others %W "wm iconify"}
  bind $win <Map> {map_others %W "wm deiconify"}

  # change default window when user resizes
  bind $win <Configure> {set DEFAULT_VISIBLE_BBOX [visible_bbox default]}

  # this binding changes focus to current canvas when entered
  bind $win <Any-Enter> {enter_canvas $cur_s}
  bind $win <Any-Leave> {leave_canvas}

  return $win
}


# The sim menu has been broken out so it can replaced if the
# netlist type changes.  Note that even though the menu items change,
# the hot key DO NOT change.

proc make_sim_menu {win {type ""}} {

  global KEYS NETLIST_TYPE PROBE_TYPE WIN_DATA DELAY_UPDATING_BINDINGS
  global SPICE_TYPE

  # delete anything that is in here
  $win.mbar.sim.menu delete 0 100

  set DELAY_UPDATING_BINDINGS 1

  menu_add -menu sim -label "[string toupper $NETLIST_TYPE] Netlist" \
      -command netlist \
      -hotkey [use_first KEYS(netlist)] \
      -help "[string toupper $NETLIST_TYPE] netlist schematic."

  menu_add -menu sim -label "[string toupper $NETLIST_TYPE] It" \
      -command {global NETLIST_TYPE ; ${NETLIST_TYPE}_it} \
      -hotkey [use_first KEYS(spice_it)] \
      -help "[string toupper $NETLIST_TYPE] netlist schematic and then execute."

  menu_add -menu sim -label "Init Probe" -command init_probe \
      -help "Initialize or reinitialize the probe."

  if {$PROBE_TYPE == "interactive" || $SPICE_TYPE == "intel"} {
    menu_add -menu sim -label "Init Probe w/Options" -command {init_probe 1} \
	-hotkey [use_first KEYS(init_probe_options)] \
	-help "Initialize or reinitialize the probe with options."
  }

  menu_add -menu sim -label "Close Probe" -command close_probe \
      -help "Close any existing probe window or program."

  menu_add -menu sim -label separator

  menu_add -menu sim -label "Change Simulation Mode...  " \
      -command change_netlist_props \
      -help "Prompt to change simulation type and properties."

  if {$NETLIST_TYPE == "spice" || $NETLIST_TYPE == "flat_spice"} {
    global SPICE_TYPES
    menu_add -menu sim -label "Select Simulator" -command select_simulator \
	-help "Select between ([use_first SPICE_TYPES]) spice-like simulators."
  }

  menu_add -menu sim -label "Change Probe Type..." -command change_probe_type \
      -help "Prompt to change the probe type."

  if {$NETLIST_TYPE == "dpc"} {
    menu_add -menu sim -label "Select Parasitic Extraction..." \
	-command dpc_change_parasitic_mode \
	-help "Select between RC (DSPF) and capacitance-only parasitic estimation."
  }

  menu_add -menu sim -label "Display Design Hierarchy   " \
      -command create_design_listbox \
      -help "Display design hierarchy from the current cell."

  menu_add -menu sim -label separator

  menu_add -menu sim -label "Generate Term Names" \
      -command menu_generate_term_names \
      -help "Compute netlisting information for the current cell only and without writing the netlist."

  menu_add -menu sim -label separator

  if {$NETLIST_TYPE == "spice" || $NETLIST_TYPE == "flat_spice" || \
	  $NETLIST_TYPE == "sim"} {

    menu_add -menu sim -label "Back Annotate Caps" \
	-modify 1 \
	-command back_annotate_caps \
	-help "Back annotate capacitances from a sim file onto the current cell."
    menu_add -menu sim -label "Max Cross Probe Init" \
	-command max_cross_probe_init \
	-help "Initialize cross-probing between SUE and MAX."

    menu_add -menu sim -label "Max Cross Probe" -command max_cross_probe \
	-help "Highlite the net in MAX corresponding to the selected net in the current schematic."

    menu_add -menu sim -label separator
  }

  if {$NETLIST_TYPE == "spice" || $NETLIST_TYPE == "flat_spice"} {
    menu_add -menu sim -label "Kill Spice Job" -command kill_spice_job \
	-help "Hunt down and kill a previously launched spice job."

    menu_add -menu sim -label separator
  }
   
  if {$PROBE_TYPE == "interactive"} {
    menu_add -menu sim -label "Print Net Value (Decimal)" -command plot_net \
	-hotkey [use_first KEYS(plot_net)]

    menu_add -menu sim -label "Print Net Value (Binary)" \
	-command plot_net_and_remember \
	-hotkey [use_first KEYS(plot_net_remember)]

    menu_add -menu sim -label "Print Net Value (Hex)" -command plot_old_net \
	-hotkey [use_first KEYS(plot_old_net)]

    menu_add -menu sim -label "Update Flags" -command unplot_net \
	-hotkey [use_first KEYS(unplot_net)]

    menu_add -menu sim -label "Display Term Values" -command unplot_old_net \
	-hotkey [use_first KEYS(unplot_old_net)]

    # hotkey gets defined elswhere
    menu_add -menu sim -label "Step Verilog" -command irsim_step \
	-hotkey [use_first KEYS(irsim_step)]

  } elseif {$PROBE_TYPE == "analyzer"} {
    menu_add -menu sim -label "Plot Net" -command plot_net

    menu_add -menu sim -label "Plot Net & remember" \
	-command plot_net_and_remember \
	-hotkey [use_first KEYS(plot_net_remember)]

    menu_add -menu sim -label "Forget Net" -command unplot_net_and_forget \
	-hotkey [use_first KEYS(unplot_net_forget)]

    menu_add -menu sim -label "Update Flags" -command irsim_update_flags \
	-hotkey [use_first KEYS(unplot_net)]

    menu_add -menu sim -label "Display Term Values" -command unplot_old_net \
	-hotkey [use_first KEYS(unplot_old_net)]

    menu_add -menu sim -label separator

    menu_add -menu sim -label "Irsim Step" -command irsim_step

    menu_add -menu sim -label "Irsim Set Hi" -command {irsim_set h}

    menu_add -menu sim -label "Irsim Set Low" -command {irsim_set l}

    menu_add -menu sim -label "Irsim Set X" -command {irsim_set u}

  } elseif {$NETLIST_TYPE != "dpc"} {
    menu_add -menu sim -label "Plot Net" -command plot_net

    menu_add -menu sim -label "Unplot Net" -command unplot_net

    menu_add -menu sim -label "Plot Net & Remember" \
	-command plot_net_and_remember \
	-hotkey [use_first KEYS(plot_net_remember)]

    menu_add -menu sim -label "Unplot Net & Forget" \
	-command unplot_net_and_forget \
	-hotkey [use_first KEYS(unplot_net_forget)]
  }

  if {$PROBE_TYPE == "NST"} {
    menu_add -menu sim -label "Plot Old Net" -command plot_old_net

    menu_add -menu sim -label "Unplot Old Net" -command unplot_old_net
  }

  if {$PROBE_TYPE != "interactive" && $PROBE_TYPE != ""} {
    menu_add -menu sim -label separator

    menu_add -menu sim -label "Erase and Plot Memory" \
	-command {global PROBE_TYPE ; ${PROBE_TYPE}_erase_and_plot_memory}

    menu_add -menu sim -label "Cancel Memory" -command cancel_memory
  }

  if {$NETLIST_TYPE == "dpc"} {
    menu_add -menu sim -label "Toggle Placement View" \
	-command toggle_show_placement \
	-help "Toggle between DPC placement and schematic.  Must be preceded by a dpc netlist."

    menu_add -menu sim -label "Display in Other View" \
	-command display_other_view \
	-help "Display selected in other view (placement or schematic).  Must be preceded by a dpc netlist."

    menu_add -menu sim -label "Display Connections" \
	-command display_connections_on_placement \
	-help "Display the connections to selected cells in the placement view."

    menu_add -menu sim -label "Congestion..." \
	-command compute_congestion \
	-help "Compute and display the routing congestion on the placement view."

    menu_add -menu sim -label separator

    menu_add -menu sim -label "Display Timing" -command select_critical_path \
	-help "Display a popup window with a list of critical paths and buttons for back-annotating."

#    menu_add -menu sim -label "Display Flylines" -command display_flylines

    menu_add -menu sim -label "Spice Last Critical Path " \
	-command spice_critical_path \
	-help "Run spice on the last critical path highlited and report results."

    menu_add -menu sim -label "Time It..." -command time_it \
	-help "Prompt for timing options and then run timing analysis and back annotate timing without renetlisting."
  }

  menu_add -menu sim -label separator

  menu_add -menu sim -label "Create Verilog Property  " \
      -modify 1 \
      -command {setup_duplicate_selected verilog} \
      -help "Create a verilog-netlist text string for an icon."

  menu_add -menu sim -label "Edit Verilog" -command edit_verilog

  menu_add -menu sim -label "Load Verilog I/O's..." -command parse_verilog \
      -modify 1 \
      -help "Prompt for the name of a textual verilog file and then places I/O's into the current SUE schematic."

  # add user defined menu items
  foreach line [use_first WIN_DATA(menu)] {
    if {$type == "startup"} {
      eval menu_add $line
    } else {
      # just add any menu add lines with -menu sim
      if {[regexp -- {-menu([ \t]+)sim} $line]} {
	eval menu_add $line
      }
    }
  }

  update_bindings
  set DELAY_UPDATING_BINDINGS 0
}


# helper functions for sim menu items

proc init_probe {{options 0}} {

  global PROBE_TYPE

  if {[use_first PROBE_TYPE] == ""} {
    # not defined, do nothing
    return
  }

  if {$options} {
    ${PROBE_TYPE}_init_probe 1
  } else {
    ${PROBE_TYPE}_init_probe 0
  }
}


proc close_probe {} {

  global PROBE_TYPE

  if {[use_first PROBE_TYPE] == ""} {
    # not defined, do nothing
    return
  }

  ${PROBE_TYPE}_close_probe
}


proc plot_net {} {

  global PROBE_TYPE

  if {[use_first PROBE_TYPE] == ""} {
    # not defined, do nothing
    return
  }

  if {[info commands ${PROBE_TYPE}_plot_net] != ""} {
    ${PROBE_TYPE}_plot_net
  }
}


proc unplot_net {} {

  global PROBE_TYPE

  if {[use_first PROBE_TYPE] == ""} {
    # not defined, do nothing
    return
  }

  if {$PROBE_TYPE == "analyzer"} {
    irsim_update_flags

  } elseif {$PROBE_TYPE == "interactive"} {
    verilog_update_flags

  } elseif {[info commands ${PROBE_TYPE}_unplot_net] != ""} {
    ${PROBE_TYPE}_unplot_net
  }
}


proc plot_net_and_remember {args} {

  global PROBE_TYPE

  if {[use_first PROBE_TYPE] == ""} {
    # not defined, do nothing
    return
  }

  if {$PROBE_TYPE == "interactive"} {
    ${PROBE_TYPE}_plot_net %b

  } elseif {[info commands ${PROBE_TYPE}_plot_net_and_remember] != ""} {
    ${PROBE_TYPE}_plot_net_and_remember
  }
}


proc plot_old_net {args} {

  global PROBE_TYPE

  if {[use_first PROBE_TYPE] == ""} {
    # not defined, do nothing
    return
  }

  if {$PROBE_TYPE == "interactive"} {
    ${PROBE_TYPE}_plot_net %h

  } elseif {$PROBE_TYPE == "NST"} {
    ${PROBE_TYPE}_plot_net ~

  } elseif {[info commands ${PROBE_TYPE}_plot_old_net] != ""} {
    ${PROBE_TYPE}_plot_old_net
  }
}


proc unplot_old_net {args} {

  global PROBE_TYPE

  if {[use_first PROBE_TYPE] == ""} {
    # not defined, do nothing
    return
  }

  if {$PROBE_TYPE == "interactive"} {
    verilog_display_term_values

  } elseif {$PROBE_TYPE == "analyzer"} {
    irsim_display_term_values

  } elseif {$PROBE_TYPE == "NST"} {
    ${PROBE_TYPE}_unplot_net ~

  } elseif {[info commands ${PROBE_TYPE}_unplot_old_net] != ""} {
    ${PROBE_TYPE}_unplot_old_net
  }
}


proc unplot_net_and_forget {args} {

  global PROBE_TYPE

  if {[use_first PROBE_TYPE] == ""} {
    # not defined, do nothing
    return
  }

  if {[info commands ${PROBE_TYPE}_unplot_net_and_forget] != ""} {
    ${PROBE_TYPE}_unplot_net_and_forget
  }
}


# Set up event bindings for the window

set SNAP10_XY {[$cur_c canvasx %x [expr $scale/10]] [$cur_c canvasy %y [expr $scale/10]]}

# default to on grid for move mode
set SNAP10M_XY $SNAP_XY

proc setup_base_bindings {} {

  global cur_c SNAP_XY SNAP10_XY NOSNAP_XY KEYS

  # remove old key bindings
#  clear_bindings

  # Bindings for background window (i.e. empty piece of canvas)
  bind_add -hotkey Button-1 \
      -command "setup_select_region $NOSNAP_XY" \
      -help "Begin dragging box for select by region."

  bind_add -hotkey Shift-Button-1 \
      -command "setup_select_region $NOSNAP_XY add" \
      -help "Begin dragging box for select by region, add to selection."

  bind_add -hotkey Control-Button-1 \
      -command "setup_select_region $NOSNAP_XY overlap" \
      -help "Begin dragging box for select by region, selecting overlapping and enclosed."

  bind_add -hotkey Control-Shift-Button-1 \
      -command "setup_select_region $NOSNAP_XY {overlap add}" \
      -help "Begin dragging box for select by region, selecting overlapping and enclosed, add to selection."

  # Bindings for mouse buttons and mouse drags on objects
  foreach type {icon wire open dot draw_item} {
    bind_add -type $type -hotkey Any-Button-1 -command icon_select \
	-help "Select $type under cursor, deselecting everything else."

    bind_add -type $type -hotkey Shift-Button-1 \
	-command "icon_select add" \
	-help "Select $type under cursor.  Add to selection."

    bind_add -type $type -hotkey Any-Button-2 \
	-command "icon_select special" \
	-help "Begin move mode. If $type under cursor is not selected, select it first, deselecting everything else."

    bind_add -type $type -hotkey Any-Button-3 \
	-command "icon_select special" \
	-help "Begin move mode. If $type under cursor is not selected, select it first, deselecting everything else."
  }
  
  # Button-2 is hard coded to move
  bind_add -hotkey Any-Button-2 \
      -command "setup_move_mode $SNAP_XY 2" \
      -help "If selected, begin moving all selected.  Otherwise, select and then begin moving."

  bind_add -hotkey Any-Button-3 \
      -command "setup_move_mode $SNAP_XY 3" \
      -help "If selected, begin moving all selected.  Otherwise, select and then begin moving."

  # move edit markers and auto-scroll with button-1
  bind_add -type edit_marker -hotkey Button-1 \
      -command "marker_press $SNAP_XY" \
      -help IGNORE

  bind_add -type edit_marker -hotkey B1-Motion \
      -command "marker_drag $SNAP_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Move highlighted edit marker under cursor."

  bind_add -type edit_marker -hotkey Shift-B1-Motion \
      -command "marker_drag $SNAP_XY shift; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Move highlighted edit marker.  Also moves aligned edit markers."

  bind_add -type edit_marker -hotkey B1-ButtonRelease \
      -command "marker_release; set SCROLL(status) off" \
      -help IGNORE

  bind_add -type edit_marker -hotkey Control-Button-1 \
      -command "marker_press $SNAP10_XY" \
      -help IGNORE

  bind_add -type edit_marker -hotkey Control-B1-Motion \
      -command "marker_drag $SNAP10_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP10_XY" \
      -help "Move hightlighted edit marker off grid."

  
  # bindings all canvas items to highlight when you are over them
  foreach type {icon wire open dot draw_item edit_marker} {
    $cur_c bind $type <Any-Enter> {item_enter}
    $cur_c bind $type <Any-Leave> {item_leave}
  }

  # double clicking the button-1 on an inst will let us edit the properties
  # Input x and y should NOT go through canvasx,canvasy commands

  bind_add -type icon -hotkey Double-Button-1 \
      -command "prop_edit_menu %x %y" \
      -help "Edit properties of this instance."

  bind_add -type icon -hotkey Double-Shift-Button-1 \
      -command "generator_edit_menu %x %y" \
      -help "Edit generator of this instance."

  bind_add -type icon -hotkey Double-Control-Button-1 \
      -command select_wire_by_name \
      -help "Select entire wire attached this icon if icon only has one port."

  bind_add -type draw_item -hotkey Double-Button-1 \
      -command "edit_draw_item %x %y" \
      -help "Edit this draw item."

  # double click will select entire wire, no just current segment
  foreach type {wire dot open} {
    bind_add -type $type -hotkey Double-Button-1 \
	-command "select_entire_wire" \
	-help "Select entire physically-connected wire."

    bind_add -type $type -hotkey Double-Shift-Button-1 \
	-command "select_entire_wire no_branch" \
	-help "Select all of wire up to first dot."

    bind_add -type $type -hotkey Double-Control-Button-1 \
	-command select_wire_by_name \
	-help "Select entire virtually-connected wire.  Only displays connections made by name if already netlisted or generated term names."
  }

  # special hotkeys

  bind_add -hotkey Delete -command delete_selected \
      -help "Delete selected."

  bind_add -hotkey Control-z \
      -command "if \{\[catch \"zoom_on_cursor $SNAP_XY\"\]\} {zoom_on_cursor}" \
      -help "Delete selected."

  # F20 is the "Cut" key
  bind_add -hotkey F20 \
      -command {delete_selected_undo cut_to_clipboard ; delete_selected} \
      -help "Delete selected."

  # F18 is the "Paste" key
  bind_add -hotkey F18 -command setup_paste_mode \
      -help "Paste from clipboard into current cell."

  # F16 is the "Copy" key
  bind_add -hotkey F16 \
      -command "delete_selected_undo copy_to_clipboard" \
      -help "Copy selected to clipboard."

  # F17 is the "open" key
  bind_add -hotkey F17 -command load_schematic \
      -help "Prompt for the name of a schematic or icon and then load and display it."

  # F14 is the "undo" key
  bind_add -hotkey F14 -command undo_last \
      -help "Undo last change in the current schematic."

  bind_add -hotkey [use_first KEYS(nudge_up)] \
      -command "nudge up" \
      -help "Move selected one grid up."

  bind_add -hotkey [use_first KEYS(nudge_down)] \
      -command "nudge down" \
      -help "Move selected one grid down."

  bind_add -hotkey [use_first KEYS(nudge_left)] \
      -command "nudge left" \
      -help "Move selected one grid left."

  bind_add -hotkey [use_first KEYS(nudge_right)] \
      -command "nudge right" \
      -help "Move selected one grid right."

  bind_add -hotkey Next \
      -command "scroll_listbox {1 pages} %x %y" \
      -help IGNORE

  bind_add -hotkey Prior \
      -command "scroll_listbox {-1 pages} %x %y" \
      -help IGNORE

  # so every window will get these, independent of NETLIST_TYPE or PROBE_TYPE
  bind_add -hotkey [use_first KEYS(irsim_step)] \
      -command irsim_step \
      -help "Step simluator forward in time."

  bind_add -hotkey [use_first KEYS(init_probe_options)] \
      -command {global PROBE_TYPE ; ${PROBE_TYPE}_init_probe 1} \
      -help "Initialize probe."

  bind_add -hotkey [use_first KEYS(show_placement)] \
      -command toggle_show_placement \
      -help "Toggle between schematic and placement view in dpc mode.  If placmeent is out of date, remake it."

  bind_add -hotkey [use_first KEYS(edit_verilog)] \
      -command edit_verilog \
      -help "Launch editor with behavioral verilog for cell or ask to create it."

  bind_add -hotkey [use_first KEYS(plot_net)] \
      -command plot_net \
      -help "Plot selected net on probe."

  bind_add -hotkey [use_first KEYS(unplot_net)] \
      -command unplot_net \
      -help "Unplot selected net on probe."

  bind_add -hotkey [use_first KEYS(plot_old_net)] \
      -command plot_old_net \
      -help "Plot selected net from previous simulation on probe."

  bind_add -hotkey [use_first KEYS(unplot_old_net)] \
      -command unplot_old_net \
      -help "Unplot selected net from previous simulation on probe."

  bind_add -hotkey [use_first KEYS(plot_net_remember)] \
      -command plot_net_and_remember \
      -help "Plot selected net on probe and remember."

  bind_add -hotkey [use_first KEYS(unplot_net_forget)] \
      -command unplot_net_and_forget \
      -help "Plot selected net on probe and forget."

  bind_add -hotkey [use_first KEYS(max_cross_probe)] \
      -command max_cross_probe \
      -help "Compare schematic and MAX layout.  If no MAX window, start one."

  bind_add -hotkey [use_first KEYS(irsim_set_hi)] \
      -command {irsim_set h} \
      -help "Set selected net hi in sim mode when running irsim."
	
  bind_add -hotkey [use_first KEYS(irsim_set_low)] \
      -command {irsim_set l} \
      -help "Set selected net low in sim mode when running irsim."

  bind_add -hotkey [use_first KEYS(irsim_set_x)] \
      -command {irsim_set u} \
      -help "Set selected net to x in sim mode when running irsim."

  # save the base bindings
  save_bindings base
}


# setup bindings excluding base bindings

proc setup_bindings {} {

  global cur_c WIN_DATA WIN

  upvar #0 ${WIN}_base_bindings bindings

  if {![info exists bindings]} {
    # never been setup, do it now
    setup_base_bindings
  } else {
    restore_bindings base
  }

  # now add hotkey bindings
  foreach key [array names WIN_DATA $WIN,keys,*] {
    set key [string range $key [expr [string last , $key] + 1] end]
    if {[string first $key {!@#$%^&*()_+|-=\\?}] != -1} {
      # special case for weird chars
      bind $cur_c $key $WIN_DATA($WIN,keys,$key)
    } elseif {![catch "expr $key"]} {
      # special case for numbers
      bind $cur_c <Key-$key> $WIN_DATA($WIN,keys,$key)
    } else {
      bind $cur_c <$key> $WIN_DATA($WIN,keys,$key)

      if {[lindex [split $key -] 0] == "Alt"} {
	# also make these into Meta bindings
	bind $cur_c "<Meta[string range $key 3 end]>" $WIN_DATA($WIN,keys,$key)
      }
    }
  }

  global CURRENT_BINDINGS
  if {![info exists CURRENT_BINDINGS]} {
    # first time, save the new bindings
    save_bindings newest

    set CURRENT_BINDINGS 0
  }
}


# Displays/changes the title to include the current cell and flags.

proc display_title {{win ""}} {

  global cur_s cur_c WIN NETLIST_TYPE auto_index HIERARCHY WIN_DATA _INTERP_

  if {$win == ""} {
    set win $WIN
  }

#  if {![winfo ismapped $cur_c]} {
#    # not visible so punt
#    return
#  }

  upvar #0 SUE_$cur_s data

  set modified $data(modified)
  set written $data(written)
  set type $data(type)

  set filename [use_first data(filename)]

  set hier ""
  foreach pair $HIERARCHY {
    set cell [lindex [split $pair ,] 0]
    set hier "$cell/$hier"
  }

  upvar #0 icon_[get_rootname $cur_s] g_data
  if {[use_first g_data(generator)] != ""} {
    # this is a generator.
    set genname [lindex [split_filename [use_first g_data(generator)]] 1]
    if {[info exists auto_index(SCHEMATIC_$genname)]} {
      set filename "\[from [lindex $auto_index(SCHEMATIC_$genname) 1]\]"
    } elseif {[info exists auto_index(ICON_$genname)]} {
      set filename "\[from [lindex $auto_index(ICON_$genname) 1]\]"
    }
  }

  set schematic [get_rootname $cur_s]

  if {$data(read_only)} {
    set read_only "  *READ-ONLY*"
  } else {
    set read_only ""
  }

  set title "${_INTERP_}:  $schematic $type$modified$written \t\t$filename  ($NETLIST_TYPE) $read_only $hier"

  if {$WIN_DATA($win,title) != $title} {
    set WIN_DATA($win,title) $title

    wm title $win $title
    wm iconname $win "${_INTERP_}: ${schematic}_$type"
  }
}


# makes a listbox of all the icons that are around.

if {$ICON_MENU == "flat"} {

proc make_icon_listbox {{bogus ""}} {

  global GEOMETRY WIN ICONIFY WIN_DATA

  if {[info exists WIN_DATA(make_icon_listbox)]} {
    # postpone this
    incr WIN_DATA(make_icon_listbox)
    return
  }

  set win .icons

  if {[winfo exists $win]} {
    # clean out old icon listbox
    $win.nodes delete 0 end

  } else {
    # build a toplevel window
    toplevel $win 

    if {[use_first ICONIFY] != ""} {
      wm iconify $win
    }

    wm geometry $win $GEOMETRY(icons)
    wm title $win "icons"
    wm min $win 0 0
    # too bad this doesn't do any good
    wm group $win $WIN

    bind $win <Unmap> {map_others %W "wm iconify"}
    bind $win <Map> {map_others %W "wm deiconify"}

    scrollbar $win.scroll -command "$win.nodes yview" -highlightthickness 0

    pack $win.scroll -side right -fill y
    listbox $win.nodes -yscrollcommand "$win.scroll set" -highlightthickness 0 \
	-exportselection 0
    pack $win.nodes -side left -fill both -expand 1

    # need to use a fixed width font here
    global LISTBOX_FONT
    $win.nodes configure -font $LISTBOX_FONT

#    tk_listboxSingleSelect $win.nodes

    set selected [backquote \
      {[if {[set sel_index [$$win.nodes curselection]] != ""} { \
	concat [string range [$$win.nodes get $sel_index] 2 end] \
      }] \
    }]

    bind_add -window $win.nodes -hotkey Motion \
	-command {%W selection clear 0 end; %W selection set [%W nearest %y]} \
	-no_launch 1 \
	-help IGNORE

    # single click on button-1 drops into current schematic
    bind_add -window $win.nodes -hotkey Button-1 \
	-command "setup_drop_icon $selected" \
	-help "Add this icon to the current schematic."

    bind_add -window $win.nodes -hotkey Shift-Button-1 \
	-command "goto_schematic $selected 1" \
	-help "Display this icon's schematic or, if none exists, its ICON view."

    bind_add -window $win.nodes -hotkey Button-2 \
	-command "goto_schematic ICON_$selected 1" \
	-help "Display this icon's ICON view."

    # double click button-3 deletes
    bind_add -window $win.nodes -hotkey Double-Button-3 \
	-command "delete_schematic ICON_$selected" \
	-help "Delete icon under cursor from SUE."

    # scrolling hotkeys - only used for help_window because of focus
    # see the scroll_listbox command
    bind_add -window $win.nodes -hotkey Next \
	-command "$win.nodes yview scroll 1 pages" \
	-help "Scroll down 1 page."

    bind_add -window $win.nodes -hotkey Prior \
	-command "$win.nodes yview scroll -1 pages" \
	-help "Scroll up 1 page."
  }

  # Now put the icon list into it
  foreach icon [lsort [info commands ICON_*]] {
    global SUE_$icon
    if {[info exists SUE_${icon}(modified)]} {
      set prefix [string range "[set SUE_${icon}(modified)]  " 0 1]
    } else {
      set prefix "  "
    }

    $win.nodes insert end $prefix[string range $icon 5 end]
  }
}

} elseif {$ICON_MENU == "hier"} {

# makes a hierarchical listbox of all the icons based on directory from
# which they come.

proc make_icon_listbox {{dir ""} {win ""}} {
  
  global GEOMETRY WIN auto_index ICON_WINDOWS ICONIFY WIN_DATA

  if {[info exists WIN_DATA(make_icon_listbox)]} {
    # postpone this
    incr WIN_DATA(make_icon_listbox)
    return
  }

  set win [use_first win '.[lindex $ICON_WINDOWS 0]]
  set win_name [string range $win 1 end]

  set scroll 0

  if {[winfo exists $win]} {
    if {$dir == ""} {
      # first remember where the scroll bar was to return there
      set scroll [lindex [$win.scroll get] 0]
    }
    # clean out old icon listbox of icons
    $win.nodes delete 0 end
    # clean out old icon listbox of directories.  Wish end worked here too.
    $win.dir.other delete 0 1000

  } else {
    # build a toplevel window
    toplevel $win

    if {[use_first ICONIFY] != ""} {
      wm iconify $win
    }

    # use the geometry if it is available.  Otherwise wish picks it.
    if {[info exists GEOMETRY($win_name)]} {
      wm geometry $win $GEOMETRY($win_name)
    }
    wm title $win $win_name
    wm min $win 0 0
    # too bad this doesn't do any good
    wm group $win $WIN

    global LISTBOX_FONT

    bind $win <Unmap> {map_others %W "wm iconify"}
    bind $win <Map> {map_others %W "wm deiconify"}

    if {$dir == ""} {
      set dir [clean_dir [pwd]]
      # if not the first icon listbox, find a directory other than pwd
      if {[lindex $ICON_WINDOWS 0] != $win_name} {
	set win1 .[lindex $ICON_WINDOWS 0]
	set index [expr 4 + [lsearch $ICON_WINDOWS $win_name]]
	if {![catch "$win1.dir.other entrycget $index -label" msg]} {
	  # success
	  set dir $msg
	}
      }
    }

    menubutton $win.dir -text $dir -menu $win.dir.other \
	-font $LISTBOX_FONT -relief raised -bd 2 -anchor e \
	-padx 2 -pady 2
    pack $win.dir -side top -fill x

    menu $win.dir.other -tearoff 0

    scrollbar $win.scroll -command "$win.nodes yview" -highlightthickness 0
    pack $win.scroll -side right -fill y
    listbox $win.nodes -yscrollcommand "$win.scroll set" -highlightthickness 0 \
	-exportselection 0
    pack $win.nodes -side left -fill both -expand 1

    # need to use a fixed width font here so modified "M" looks right
    $win.nodes configure -font $LISTBOX_FONT

#    tk_listboxSingleSelect $win.nodes

    set selected [backquote \
      {[if {[set sel_index [$$win.nodes curselection]] != ""} { \
	concat [string range [$$win.nodes get $sel_index] 2 end] \
      }] \
    }]

    # help
    bind_add -window $win.nodes -hotkey space -command "help_window %x %y" \
	-help "Display this window."

    bind_add -window $win.nodes -hotkey Motion \
	-command {%W selection clear 0 end; %W selection set [%W nearest %y]} \
	-no_launch 1 \
	-help IGNORE

    # single click on button-1 drops into current schematic
    bind_add -window $win.nodes -hotkey Button-1 \
	-command "setup_drop_icon $selected" \
	-help "Add this icon to the current schematic."

    bind_add -window $win.nodes -hotkey Shift-Button-1 \
	-command "goto_schematic $selected 1" \
	-help "Display this icon's schematic or, if none exists, its ICON view."

    bind_add -window $win.nodes -hotkey Button-2 \
	-command "goto_schematic ICON_$selected 1" \
	-help "Display this icon's ICON view."

    # double click button-3 deletes
    bind_add -window $win.nodes -hotkey Double-Button-3 \
	-command "delete_schematic ICON_$selected" \
	-help "Delete icon under cursor from SUE."

    # scrolling hotkeys - only used for help_window because of focus
    # see the scroll_listbox command
    bind_add -window $win.nodes -hotkey Next \
	-command "$win.nodes yview scroll 1 pages" \
	-help "Scroll down 1 page."

    bind_add -window $win.nodes -hotkey Prior \
	-command "$win.nodes yview scroll -1 pages" \
	-help "Scroll up 1 page."
  }

  # set the directory of which icons to show.  Lose auto_mounter stuff
  set dir [use_first dir '[lindex [$win.dir configure -text] 4]]
  # special case for the "generators" dir
  if {$dir != "generators"} {
    set dir [clean_dir $dir]
  }
# BUG IN TK: this line moves the whole window
  $win.dir configure -text $dir

  $win.dir.other add command -label "Autoload directory" \
      -command "autoload_from_listbox $dir"
  $win.dir.other add separator

  # put in a menu item for remove icon menu and add another
  $win.dir.other add command -label "Make new icon listbox" \
      -command "new_icon_menu"
  $win.dir.other add command -label "Close this icon listbox" \
      -command "waste_icon_listbox $win"
  $win.dir.other add separator

  # "." means not in the auto path
  set dirs(.) foo

  # Now put the icon list into it
  foreach icon [lsort [info commands ICON_*]] {
    set icon_dir [file dirname [lindex [use_first auto_index($icon)] 1]]
    if {$icon_dir == $dir} {
      global SUE_$icon
      if {[info exists SUE_${icon}(modified)]} {
	set prefix [string range "[set SUE_${icon}(modified)]  " 0 1]
      } else {
	set prefix "  "
      }
      
      $win.nodes insert end $prefix[string range $icon 5 end]
    }

    # add directories
    if {![info exists dirs($icon_dir)]} {
      $win.dir.other add command -label $icon_dir \
	  -command "make_icon_listbox $icon_dir $win"
      set dirs($icon_dir) 1
    }
  }

  # put the scrollbar back where it was
  $win.nodes yview moveto $scroll
  $win.nodes xview moveto 0

  # now update any other icon listboxes that may be around
  set new_win [lindex $ICON_WINDOWS \
		   [expr [lsearch $ICON_WINDOWS $win_name] + 1]]
  if {$new_win == ""} {
    # we're done
    return
  }
  make_icon_listbox "" .$new_win
}

} else {

# makes a hierarchical listbox of all the icons based on directory from
# which they come and INCLUDE listbox in the main SUE window.

proc make_icon_listbox {{dir ""} {win ""}} {
  
  global GEOMETRY WIN auto_index ICON_WINDOWS LISTBOX_FONT WIN_DATA

  if {[info exists WIN_DATA(make_icon_listbox)]} {
    # postpone this
    incr WIN_DATA(make_icon_listbox)
    return
  }

  if {$win == ""} {
    set win "$WIN.lb.[lindex $ICON_WINDOWS 0]"
  }

  if {[lrange [split $win .] 1 2] != "[string range $WIN 1 end] lb"} {
    set win "$WIN.lb$win"
  }

  set win_name [string range [file extension $win] 1 end]
  set scroll 0

  if {[winfo exists $win]} {
    if {$dir == ""} {
      # first remember where the scroll bar was to return there
      set scroll [lindex [$win.scroll get] 0]
    }
    # clean out old icon listbox of icons
    $win.nodes delete 0 end
    # clean out old icon listbox of directories.  Wish end worked here too.
    $win.dir.other delete 0 1000

  } else {
    # make a new listbox
    frame $win -relief sunken -bd 2
    
    set win_name [lindex [split $win .] 3]
    set index [expr [lsearch -exact $ICON_WINDOWS $win_name] + 1]
    set before "$WIN.lb.[lindex $ICON_WINDOWS $index]"
    if {$index == 0 || $index >= [llength $ICON_WINDOWS] || \
	    ![winfo exists $before]} {
      pack $win -side top -fill y -expand 1
    } else {
      # pack in correct place
      pack $win -side top -before $before -fill y -expand 1
    }

    if {$dir == ""} {
      set dir [clean_dir [pwd]]
      # if not the first icon listbox, find a directory other than pwd
      if {[lindex $ICON_WINDOWS 0] != $win_name} {
	set win1 "$WIN.lb.[lindex $ICON_WINDOWS 0]"
	set index [expr 4 + [lsearch $ICON_WINDOWS $win_name]]
	if {![catch "$win1.dir.other entrycget $index -label" msg]} {
	  # success
	  set dir $msg
	}
      }
    }

    # make sure this window is the size of the other ones.
    if {[catch "$WIN.lb.[lindex $ICON_WINDOWS 0].nodes cget -width" width]} {
      # problem, probably doesn't exist, use default
      set width $GEOMETRY(listbox)
    }
    if {$width < 3} {
      set width $GEOMETRY(listbox)
    }

    menubutton $win.dir -text $dir -menu $win.dir.other -font $LISTBOX_FONT \
	-relief raised -bd 2 -anchor e -width $width \
	-padx 2 -pady 2
    pack $win.dir -side top -fill x

    menu $win.dir.other -tearoff 0

    scrollbar $win.scroll -command "$win.nodes yview" -highlightthickness 0
    pack $win.scroll -side right -fill y
    listbox $win.nodes -yscrollcommand "$win.scroll set" \
	-width $width -highlightthickness 0 -height 4 \
	-exportselection 0
    pack $win.nodes -side left -fill both -expand 1

    # need to use a fixed width font here so modified "M" looks right
    $win.nodes configure -font $LISTBOX_FONT

#    tk_listboxSingleSelect $win.nodes

#    set selected "\[string range \[$win.nodes get \[$win.nodes curselection\]\] 2 end\]"

    set selected [backquote \
      {[if {[set sel_index [$$win.nodes curselection]] != ""} { \
	concat [string range [$$win.nodes get $sel_index] 2 end] \
      }] \
    }]

    # help
    bind_add -window $win.nodes -hotkey space -command "help_window %x %y" \
	-help "Display this window."

    bind $win.nodes <Any-Enter> \
      {msg_window "Icon Listbox: Button-1 adds, Shift-Button-1 goes to, Button-2 go to icon view, Double-Button-3 deletes" listbox}
    bind $win.nodes <Any-Leave> "msg_window __RESTORE__"

    bind_add -window $win.nodes -hotkey Motion \
	-command {%W selection clear 0 end; %W selection set [%W nearest %y]} \
	-no_launch 1 \
	-help IGNORE

    # single click on button-1 drops into current schematic
    bind_add -window $win.nodes -hotkey Button-1 \
	-command "setup_drop_icon $selected" \
	-help "Add this icon to the current schematic."

    bind_add -window $win.nodes -hotkey Shift-Button-1 \
	-command "goto_schematic $selected 1" \
	-help "Display this icon's schematic or, if none exists, its ICON view."

    bind_add -window $win.nodes -hotkey Button-2 \
	-command "goto_schematic ICON_$selected 1" \
	-help "Display this icon's ICON view."

    # double click button-3 deletes
    bind_add -window $win.nodes -hotkey Double-Button-3 \
	-command "delete_schematic ICON_$selected" \
	-help "Delete icon under cursor from SUE."

    # scrolling hotkeys - only used for help_window because of focus
    # see the scroll_listbox command
    bind_add -window $win.nodes -hotkey Next \
	-command "$win.nodes yview scroll 1 pages" \
	-help "Scroll down 1 page."

    bind_add -window $win.nodes -hotkey Prior \
	-command "$win.nodes yview scroll -1 pages" \
	-help "Scroll up 1 page."

#    bind_add -window $win.nodes -hotkey Down \
	-command "$win.nodes yview scroll 1 units" \
	-help "Scroll down 1 line."

#    bind_add -window $win.nodes -hotkey Up \
	-command "$win.nodes yview scroll -1 units" \
	-help "Scroll up 1 line."
  }

  # set the directory of which icons to show.  Lose auto_mounter stuff
  set dir [use_first dir '[$win.dir cget -text]]
  # special case for the "generators" dir
  if {$dir != "generators"} {
    set dir [clean_dir $dir]
  }
  $win.dir configure -text $dir

  $win.dir.other add command -label "Autoload directory" \
      -command "autoload_from_listbox $dir"
  $win.dir.other add separator

  # put in a menu item for remove icon menu and add another
  $win.dir.other add command -label "Make new icon listbox" \
      -command "new_icon_menu"
  $win.dir.other add command -label "Close this icon listbox" \
      -command "waste_icon_listbox $win"
  $win.dir.other add separator

  # "." means not in the auto path
  set dirs(.) foo

  # Now put the icon list into it
  foreach icon [lsort [info commands ICON_*]] {
    set icon_dir [file dirname [lindex [use_first auto_index($icon)] 1]]
    if {$icon_dir == $dir} {
      global SUE_$icon
      if {[info exists SUE_${icon}(modified)]} {
	set prefix [string range "[set SUE_${icon}(modified)]  " 0 1]
      } else {
	set prefix "  "
      }
      
      $win.nodes insert end $prefix[string range $icon 5 end]
    }

    # add directories
    if {![info exists dirs($icon_dir)]} {
      $win.dir.other add command -label $icon_dir \
	  -command "make_icon_listbox $icon_dir $win"
      set dirs($icon_dir) 1
    }
  }

  # put the scrollbar back where it was
  $win.nodes yview moveto $scroll
  $win.nodes xview moveto 0

  # now update any other icon listboxes that may be around
  set new_win [lindex $ICON_WINDOWS \
		   [expr [lsearch $ICON_WINDOWS $win_name] + 1]]
  if {$new_win == ""} {
    # we're done
    return
  }
  make_icon_listbox "" ".$new_win"
}


# resizes width of included listboxes

proc resize_listboxes {delta} {

  global WIN ICON_WINDOWS

  set old_width [$WIN.lb.schematics.nodes cget -width]
  set width [expr $old_width + $delta]

  if {$width < 3} {
    # too small
    return
  }

  set swidth [min [expr $width + 5] 15]

  $WIN.lb.schematics.nodes configure -width $width
  $WIN.lb.schematics.s.scroll configure -width $swidth

  foreach icon $ICON_WINDOWS {
    $WIN.lb.$icon.nodes configure -width $width
    $WIN.lb.$icon.dir configure -width $width

    $WIN.lb.$icon.scroll configure -width $swidth
  }
}

# end include listbox
}
  

proc new_icon_menu {{dir ""} {index ""}} {

  global ICON_WINDOWS ICON_MENU

  # make up a name.
  set root [lindex [split [lindex $ICON_WINDOWS 0] 0123456789] 0]
  for {set i 0} {[lsearch $ICON_WINDOWS $root[incr i]] != -1} {} {}
  set win_name $root$i

  if {$index != "" && $ICON_MENU == "include"} {
    # add not at bottom
#puts "new $index $dir"
    set ICON_WINDOWS [linsert $ICON_WINDOWS $index $win_name]

  } else {
    lappend ICON_WINDOWS $win_name
  }

  # and do it
  make_icon_listbox $dir .$win_name
}


proc waste_icon_listbox {win} {

  global ICON_WINDOWS WIN

  if {[llength $ICON_WINDOWS] < 2} {
    sue_error "Aborting, can't remove last icon listbox."
    sue_error flush
    return
  }

  # nuke the window
  if {[winfo exists $WIN.lb$win]} {
    destroy $WIN.lb$win
  } elseif {[winfo exists $win]} {
    destroy $win
  }

  # remove the window out of ICON_WINDOWS
  set win_name_list [split $win .]
  set win_name [lindex $win_name_list [expr [llength $win_name_list] - 1]]
  set index [lsearch $ICON_WINDOWS $win_name]
  set ICON_WINDOWS [lreplace $ICON_WINDOWS $index $index]
}


if {$ICON_MENU == "flat" || $ICON_MENU == "hier"} { 

# makes a listbox of all schematics that are in canvases, NOT all 
# schematics.  For example, a schematic procedure might be known but
# since no one has pushed into it, a canvas hasn't been made for it
# and thus it won't show up here.

proc make_schematic_listbox {} {

  global SUE GEOMETRY WIN ICONIFY

  set win .schematics

  if {[winfo exists $win]} {
    raise $win
    return
  }

  toplevel $win 

  if {[use_first ICONIFY] != ""} {
    wm iconify $win
  }

  wm geometry $win $GEOMETRY(schematics)
  wm title $win "schematics"
  wm min $win 0 0
  wm group $win $WIN

  bind $win <Unmap> {map_others %W "wm iconify"}
  bind $win <Map> {map_others %W "wm deiconify"}

  set swin $win.s
  frame $swin
  pack $swin -side right -fill y

  button $swin.button -text "a" -command "alphabetize_schematic_listbox" \
      -padx 0 -pady 0  
  pack $swin.button -side top

  scrollbar $swin.scroll -command "$win.nodes yview" -highlightthickness 0
  pack $swin.scroll -side top -fill y -expand 1

  listbox $win.nodes -yscrollcommand "$swin.scroll set" -highlightthickness 0 \
      -exportselection 0
  pack $win.nodes -side left -fill both -expand 1

  # need to use a fixed width font here
  global LISTBOX_FONT
  $win.nodes configure -font $LISTBOX_FONT

#  tk_listboxSingleSelect $win.nodes

    set selected [backquote \
      {[if {[set sel_index [$$win.nodes curselection]] != ""} { \
	concat [string range [$$win.nodes get $sel_index] 2 end] \
      }] \
    }]

  bind_add -window $win.nodes -hotkey Motion \
      -command {%W selection clear 0 end; %W selection set [%W nearest %y]} \
      -no_launch 1 \
      -help IGNORE

  # single click selects
  bind_add -window $win.nodes -hotkey Button-1 \
      -command "goto_schematic $selected 1" \
      -help "Display the schematic under the cursor."

  # help
  bind_add -window $win.nodes -hotkey space -command "help_window %x %y" \
      -help "Display this window."

  bind $win.nodes <Any-Enter> \
      {msg_window "Schematic Listbox: Button-1 goes to, Shift-Button-1 goes to icon, Control-Button-1 adds, Double-Button-3 deletes" listbox}
  bind $win.nodes <Any-Leave> "msg_window __RESTORE__"

  bind_add -window $win.nodes -hotkey Shift-Button-1 \
      -command "goto_schematic $selected 1 ; change_views" \
      -help "Display this schematic's icon or, if none exists, its schematic."

  bind_add -window $win.nodes -hotkey Control-Button-1 \
      -command "setup_drop_icon $selected" \
      -help "Add this icon to the current schematic."

  # double click button-3 deletes
  bind_add -window $win.nodes -hotkey Double-Button-3 \
      -command "delete_schematic $selected" \
      -help "Delete schematic under cursor from SUE."
  
  # scrolling hotkeys - only used for help_window because of focus
  # see the scroll_listbox command
  bind_add -window $win.nodes -hotkey Next \
      -command "$win.nodes yview scroll 1 pages" \
      -help "Scroll down 1 page."

  bind_add -window $win.nodes -hotkey Prior \
      -command "$win.nodes yview scroll -1 pages" \
      -help "Scroll up 1 page."
  
  # Now put the schematic list into it
  foreach schematic [array names SUE] {
    if {[string range $schematic 0 4] != "ICON_"} {
      global SUE_$schematic
      if {[info exists SUE_${schematic}(modified)]} {
	set prefix [string range "[set SUE_${schematic}(modified)]  " 0 1]
      } else {
	set prefix "  "
      }

      $win.nodes insert end $prefix$schematic
    }
  }
}

} else {

# Same as above except INCLUDES list box is in main window

proc make_schematic_listbox {} {

  global SUE GEOMETRY WIN LISTBOX_FONT

  if {[winfo exists $WIN.lb.schematics]} {
    return
  }

  set win $WIN.lb.schematics
  frame $win -relief sunken -bd 2
  pack $win -side top -fill y -expand 1

  set swin $win.s
  frame $swin
  pack $swin -side right -fill y

  button $swin.button -text "a" -command "alphabetize_schematic_listbox" \
      -padx 0 -pady 0  
  pack $swin.button -side top

  scrollbar $swin.scroll -command "$win.nodes yview" -highlightthickness 0
  pack $swin.scroll -side top -fill y -expand 1
  listbox $win.nodes -yscrollcommand "$swin.scroll set" \
      -width $GEOMETRY(listbox) -highlightthickness 0 -height 4 \
      -exportselection 0
  pack $win.nodes -side left -fill both -expand 1

  # need to use a fixed width font here
  $win.nodes configure -font $LISTBOX_FONT

#  tk_listboxSingleSelect $win.nodes

    set selected [backquote \
      {[if {[set sel_index [$$win.nodes curselection]] != ""} { \
	concat [string range [$$win.nodes get $sel_index] 2 end] \
      }] \
    }]

#  bind $win.nodes <Motion> \
      {%W selection clear 0 end; %W selection set [%W nearest %y]} 

  bind_add -window $win.nodes -hotkey Motion \
      -command {%W selection clear 0 end; %W selection set [%W nearest %y]} \
      -no_launch 1 \
      -help IGNORE

  # single click selects
  bind_add -window $win.nodes -hotkey Button-1 \
      -command "goto_schematic $selected 1" \
      -help "Display the schematic under the cursor."

  # help
  bind_add -window $win.nodes -hotkey space -command "help_window %x %y" \
      -help "Display this window."

  bind $win.nodes <Any-Enter> \
      {msg_window "Schematic Listbox: Button-1 goes to, Shift-Button-1 goes to icon, Control-Button-1 adds, Double-Button-3 deletes" listbox}
  bind $win.nodes <Any-Leave> "msg_window __RESTORE__"

  bind_add -window $win.nodes -hotkey Shift-Button-1 \
      -command "goto_schematic $selected 1 ; change_views" \
      -help "Display this schematic's icon or, if none exists, its schematic."

  bind_add -window $win.nodes -hotkey Control-Button-1 \
      -command "setup_drop_icon $selected" \
      -help "Add this icon to the current schematic."

  # double click button-3 deletes
  bind_add -window $win.nodes -hotkey Double-Button-3 \
      -command "delete_schematic $selected" \
      -help "Delete schematic under cursor from SUE."
  
  # scrolling hotkeys - only used for help_window because of focus
  # see the scroll_listbox command
  bind_add -window $win.nodes -hotkey Next \
      -command "$win.nodes yview scroll 1 pages" \
      -help "Scroll down 1 page."

  bind_add -window $win.nodes -hotkey Prior \
      -command "$win.nodes yview scroll -1 pages" \
      -help "Scroll up 1 page."

  # Now put the schematic list into it
  foreach schematic [array names SUE] {
    if {[string range $schematic 0 4] != "ICON_"} {
      global SUE_$schematic
      if {[info exists SUE_${schematic}(modified)]} {
	set prefix [string range "[set SUE_${schematic}(modified)]  " 0 1]
      } else {
	set prefix "  "
      }

      $win.nodes insert end $prefix$schematic
    }
  }
}

}


proc add_schematic_to_listbox {schematic {prefix "  "}} {

  global WIN

  # punt if icon
  if {[string range $schematic 0 4] == "ICON_"} {
    return
  }

  if {[winfo exists $WIN.lb.schematics]} {
    set win $WIN.lb.schematics
  } elseif {[winfo exists .schematics]} {
    set win .schematics
  } else {
    make_schematic_listbox
    # making it will add the current schematic
    return
  }

  $win.nodes insert end $prefix$schematic
}


proc remove_schematic_from_listbox {schematic_name} {

  global WIN

  if {[string range $schematic_name 0 4] == "ICON_"} {
    set win .icons
    set schematic [string range $schematic_name 5 end]
  } else {
    if {[winfo exists $WIN.lb.schematics]} {
      set win $WIN.lb.schematics
    } else {
      set win .schematics
    }
    set schematic $schematic_name
  }

  if {![winfo exists $win]} {
    return
  }

  for {set i 0} {$i < [$win.nodes size]} {incr i} {
    if {[string range [$win.nodes get $i] 2 end] == $schematic} {
      $win.nodes delete $i
      return
    }
  }

  sue_error "Aborting, can't find \"$schematic_name\" in listbox to delete."
  sue_error flush
}


proc alphabetize_schematic_listbox {} {

  global WIN

  if {[winfo exists $WIN.lb.schematics]} {
    set win $WIN.lb.schematics
  } else {
    set win .schematics
  }

  if {![winfo exists $win]} {
    return
  }

  # delete all entries
  # Note: need to prepend a character onto schematic so that lsort
  # can always find the second thing
  set schems ""
  set num [$win.nodes size]
  for {set i 0} {$i < $num} {incr i} {
    lappend schems ".[$win.nodes get 0]"
    $win.nodes delete 0
  }

  # put them back in alphabetized
  foreach schem [lsort -dictionary -index 1 $schems] {
    $win.nodes insert end [string range $schem 1 end]
  }
}


# Changes the prefix (i.e. the first 2 characters in each line) of
# either the schematic or icon prefixes to be modified/unmodified.

proc change_listbox_prefix {schematic_name {prefix "  "}} {

  global WIN

  if {[is_icon $schematic_name]} {
    global ICON_WINDOWS
    if {[info exists ICON_WINDOWS]} {
      set wins $ICON_WINDOWS
    } else {
      set wins .icons
    }
    set schematic [get_rootname $schematic_name]
  } else {
    set wins .schematics
    set schematic $schematic_name
  }

  foreach win $wins {
    if {[string index $win 0] != "."} {
      set win .$win
    }
    if {[winfo exists $WIN.lb$win]} {
      set win $WIN.lb$win
    }

    if {![winfo exists $win]} {
      continue
    }

    # first remember where the scroll bar was to return there
    if {[winfo exists $win.scroll]} {
      set scroll [lindex [$win.scroll get] 0]
    } else {
      set scroll [lindex [$win.s.scroll get] 0]
    }

    for {set i 0} {$i < [$win.nodes size]} {incr i} {
      if {[string range [$win.nodes get $i] 2 end] == $schematic} {
	$win.nodes delete $i
	$win.nodes insert $i $prefix$schematic
	continue
      }
    }
    # put the scrollbar back where it was
    $win.nodes yview moveto $scroll
    $win.nodes xview moveto 0
  }
}


# called when mouse in resize listbox frame to change cursor and
# resize listbox with button1

proc listbox_resize {type {x ""}} {

  global WIN _LISTBOX_RESIZE_

  switch $type {
    enter {
      if {[info exists _LISTBOX_RESIZE_(cursor)]} {
	# already here
	return
      }
      set _LISTBOX_RESIZE_(cursor) [$WIN cget -cursor]

      # horiz double arrow
      $WIN configure -cursor sb_h_double_arrow
    }

    leave {
      if {![info exists _LISTBOX_RESIZE_(button)] && \
	      [info exists _LISTBOX_RESIZE_(cursor)]} {
	$WIN configure -cursor $_LISTBOX_RESIZE_(cursor)
	catch {unset _LISTBOX_RESIZE_(cursor)}
      }
    }

    start {
      set _LISTBOX_RESIZE_(button) 1
    }

    move {
      # move by one character width
      set actualx [winfo rootx $WIN.lb.schematics]

#      resize_listboxes [expr ($actualx - $x) / 16]

      if {$x > [expr $actualx + 7]} {
	resize_listboxes -1
      } elseif {$x < [expr $actualx - 7]} {
	resize_listboxes 1
      }
    }

    release {
      catch {unset _LISTBOX_RESIZE_(button)}

      # probably not needed
      listbox_resize leave
    }
  }
}


# Maps (uniconifies) and unmaps (iconifies) the other toplevel windows
# if one is Mapped/unmapped.  Tries to eliminate window icons for the
# "icons" and "schematics" windows since they are unnecessary.

proc map_others {event_win action} {

  global WIN WIN_DATA

  # ignore packing and unpacking events (which somehow call this)
  if {$event_win != $WIN && [string range $event_win 0 5] != ".icons" && \
	  [string range $event_win 0 10] != ".schematics"} {
    return
  }

  if {[use_first WIN_DATA(mapping)] != ""} {
    return
  }
  set WIN_DATA(mapping) 1

  foreach win [winfo children .] {
    if {($win == ".icons" || $win == ".schematics") && \
	    $action == "wm iconify"} {
      wm overrideredirect $win true
      wm withdraw $win
      continue
    } 
    if {$action == "wm deiconify"} {
      wm overrideredirect $win false
    }
    if {$win != $event_win} {
      eval $action $win
    }
  }

  set WIN_DATA(mapping) ""
}


# abbreviates keystrings so they are nicer.

proc abbrev string {

  set control "Ctrl-"

  if {[lsearch -exact "space delete" [string tolower $string]] != -1} {
    # make delete and space upper case
    return [string toupper $string]
  }

  if {[string length $string] == 1 && [string tolower $string] != $string} {
    # turn G into Shift-g, etc.
    set string "Shift-[string tolower $string]"
  }

  if {[string range $string 0 7] == "Control-"} {
    return "$control[string range $string 8 end]"
  } else {
    return $string
  }
}


# called from icon listbox

proc autoload_from_listbox {dir} {

  global auto_path

  busy

  # first remove from autopath so we will recompute tcltags
  set pos [lsearch $auto_path $dir]
  if {$pos != -1} {
    set auto_path [lreplace $auto_path $pos $pos]
    add_auto_path $dir
  }

  # force wish to load in all of the tclIndexes
  auto_load_index

  auto_load_directory $dir
  
  make_icon_listbox

  ready
}


# called whenever we are about to bog down the cpu so the user doesn`t
# try doing anything.  Note: gumby is hard coded to be green -- as everyone
# knows...

proc busy {} {

  global WIN COLORS

  set old [$WIN cget -cursor]

  if {[lindex $old 0] == "gumby"} {
    # already there
    return $old
  }

  # change in all top level windows
  foreach win [winfo children .] {
    # my hero!
    $win configure -cursor "gumby $COLORS(fore) green"
  }

  update idletasks

  return $old
}


# we're back!

proc ready {{cursor ""}} {

  global WIN

  if {$cursor == ""} {
    set cursor arrow
  }

  set old [$WIN cget -cursor]
  if {[lindex $old 0] == "arrow"} {
    # already there
    return $old
  }

  # change in all top level windows
  foreach win [winfo children .] {
    $win configure -cursor $cursor
  }

  return $old
}


# called to launch menu item/hotkey function
set __LAUNCH__ 0

proc launch {command {type "busy"}} -type user -desc {

Top-level wrapper for SUE API calls.  

All top-level tcl procedures that execute SUE API calls should be
wrapped with the "launch" procedure instead of being executed directly.
While commands will still work otherwise, they will be slower,
especially if they switch the current cell using api_goto_cell,
api_push, api_pop, api_load_cell, or api_new_cell.

example:

        sue> launch myproc

or if the command takes arguments:

        sue> launch "myproc2 3"

Procedures called from the menu or hotkeys and added using the
"menu_add" command automatically get wrapped with the "launch" procedure.

The "launch" command also adds error catching.  If a tcl error occurs in
a user procedure, the stack trace is placed in the "error" global
variable.  To view it, use either:

        sue> set error

or, equivalently,

        sue> puts $error

} {

  global cur_s cur_c scale SCROLL errorInfo error INTERRUPT WIN __LAUNCH__
  global IDIOT_DELAY

  if {$__LAUNCH__ > 0} {
    # inside of a launch command already, just execute
    incr __LAUNCH__
    if {$__LAUNCH__ > 100} {
      # probably an infinite loop -- error out
      api_infinite_loop
    }

    # do it
    set result [uplevel 1 $command]

    incr __LAUNCH__ -1

    return $result
  }

  set __LAUNCH__ 1

  if {$type == "busy"} {
    busy
  }

  if {[catch [list uplevel 1 $command] msg]} {
    # uh oh, error

    # save away the error so it doesn't get lost
    set error $errorInfo

    # add the procedure to the error message.
    regexp {\((procedure "[^ ]+" line [^ ]+)\)} $errorInfo tmp proc

    if {![info exists proc]} {
      # no procedures listed
      sue_error "SUE ERROR: $msg"
    } else {
      sue_error "SUE ERROR: $msg in $proc"
    }

    # make sure the auto scrolling is off
    set SCROLL(status) off

    global WIN_DATA DISABLE_CANVAS_EVENT _SAVE_SCALE_CUR_S_

    # If there is a cancellation command, execute it (this will reset this)
    eval $WIN_DATA($WIN,abort_cmd)

    if {$_SAVE_SCALE_CUR_S_ != ""} {
      # stuck scaled out, fix it
      set save_cur_s $cur_s
      goto_schematic $_SAVE_SCALE_CUR_S_
      unscale
      goto_schematic $save_cur_s
    }

    # enable general canvas events
    set DISABLE_CANVAS_EVENT 0

    # reset this so these aren't delayed
    catch {unset WIN_DATA(make_icon_listbox)}

    # just in case it didn't get reset
    ready
  }

  # make sure that the cur_s/cur_c/scale match what the user is looking at
  goto_schematic $cur_s	

  # done with command, time to fix the canvases
  set slaves [pack slaves $WIN]
  if {[lsearch $slaves $cur_c] == -1} {
    # incorrect canvas packed, pack correct one
    set index [lsearch $slaves $WIN.c_*]
    if {$index != -1} {
      pack forget [lindex $slaves $index]
    }

    pack_canvas force
  }

  display_title

  if {[use_first INTERRUPT] == 1} {
    puts "Aborting, interrupted by Control-c."
    set INTERRUPT 0
  }

  # show the user any error messages and flush if not already done.
  sue_error flush	

  set __LAUNCH__ 0

  if {$type == "busy"} {
    ready
  }

  return $msg
}


# displays modified cells in a dialog box and querries the user
# to exit or cancel exit command.

proc modify_exit {{-error_code}} {

  global SUE SUE_DIR PROBE_TYPE

  set modified_cells ""

  set count 0
  foreach cell [array names SUE] {

    global SUE_$cell

    if {[set SUE_${cell}(modified)] != ""} {
      incr count
      if {$count > 10} {
	# too many for little window
	continue
      }

      if {[is_icon $cell]} {
	set icon [get_rootname $cell]
	lappend modified_cells "Icon \"$icon\" is modified."
      } else {
	lappend modified_cells "Schematic \"$cell\" is modified."
      }
    }
  }

  if {$modified_cells != ""} {
    if {$count > 10} {
      lappend modified_cells "... Too many cells ($count) to display."
    }

    set button [tk_dialog .modify_exit "Cells Modified" \
		    [join $modified_cells "\n"] \
		    @$SUE_DIR/sue_icon.xbm 0 {Cancel} {Exit and Lose Changes}]

    if {$button == 0} {
      # user hit the cancel key
      return
    }
  }

  # close any probes that might be around
  if {[use_first PROBE_TYPE] != ""} {
    catch "${PROBE_TYPE}_close_probe"
  }

  # bye-bye world
  if {$error_code} {
    exit -force -error_code
  } else {
    exit -force
  }
}


# Variable _CURSOR_STACK implements a stack of info about cursors.
# It is used to restore the cursor and message when creating/destroying
# dialog windows.  It needs to be a stack because a dialog window
# can call another (eg: prop_menu calls a dialog for help).
# It is a list of lists; each individual list element contains:
#	active_window - the window passed to cursor_wait, which
#		is the window actively accepting input.
#	old_cusor - the cursor in use before cursor_wait was called.
#	old_msg - the message displayed before cursor_wait was called.
set _CURSOR_STACK ""

# Called by toplevel windows to change cursors.
# Window is a dialog box window.  Bool is 1 to indicate that the
# specified window is now active, or 0 to indicate that it is inactive.
# Msg is an optional message for the help message area.
# When bool == 0, we restore the previous cursor and active window.
proc cursor_wait {window bool {msg {}}} {
    global WIN WIN_DATA _CURSOR_STACK
    if { $bool == 0 } {
	# Dialog box has been destroyed:
	# restore cursor and message for previous active window.
	setl {active_window active_cursor active_msg} [pop _CURSOR_STACK]
	set WIN_DATA($WIN,display_msg) $active_msg
	$active_window configure -cursor $active_cursor
    } else {
	# Save old cursor, change the cursor for window and add a message
	update
	if {[llength $_CURSOR_STACK]} {
	    set active_window [lindex [lindex $_CURSOR_STACK 0] 0]
	} else {
	    # Top-level call to cursor-wait: top level window is active.
	    set active_window $WIN
	}
	set active_cursor [lindex [$WIN configure -cursor] 4]
	set active_msg $WIN_DATA($WIN,display_msg)
	push _CURSOR_STACK [list $active_window $active_cursor $active_msg]
	set WIN_DATA($WIN,display_msg) "?  [lindex [split $msg \n] 0]"
	$active_window configure -cursor question_arrow
    }
}

