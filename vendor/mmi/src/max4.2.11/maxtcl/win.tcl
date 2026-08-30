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

set RCSVERSION(win.tcl) { $Revision: 1.32 $ }

# Code to create/manage main max windows.

proc win_new {} -desc {
create new main window
} {
    global CELL max_win geometry STATUS
  
    # Must do this before calling mode_win_init.
    set STATUS(box_msg_type) "size"
    set STATUS(cursor_msg_enabled) 1

    # only one main window for-now!
    if { [info commands .win1] != "" } {
	error "max does not support multiple main windows yet!"
    }

    # create toplevel window
    set w .win1
    set max_win [toplevel $w]
    bind all <Any-Tab> ""

    # specify icon 
    set path [mn_sys_find "images/max_icon.xbm"]
    if {$path != ""} {
       wm iconbitmap $w @$path
    }		

    # handle delete window protocols from window manager
    wm protocol $w WM_DELETE_WINDOW cell_exit

    # specify min size (simultaneously permits resizing through window manager)
    wm minsize $w 100 100

    # default window geometry
    if { [info exists geometry] } {
	wm geometry $w $geometry
    } else {
	wm geometry $w 800x700+100+0
    }

    # initial parms for this window
    upvar #0 win_$max_win win_cur
    set win_cur(top_bar) 1
    set win_cur(pal) 1
    set win_cur(scroll) 1
    set win_cur(bot_bar) 1
    set win_cur(list_boxes) 1
    set win_cur(navigator) 1
    set win_cur(tool_bar) 1
    set win_cur(indicators) 0

    ### build top_bar
    frame $w.top_bar

    set mbar [menu_bar_build $w]
    pack $mbar -side left -fill x -in $w.top_bar
    # Do not leave a menu help message around when
    # the cursor is moved from a menu into the menu_bar.
    bind $mbar <Enter> {+mode_msg "" tmp}
    pack [mode_msg_build $w] -side right -fill x -expand yes -in $w.top_bar

    ### build color editor window and withdraw
    if {![winfo exists .color]} {
      _build_color_window .color
       wm withdraw .color
    }

    # Frame for left side stuff
    frame $w.leftsidebar

    ### build palette
    pal_build $w

    ### build scroll bars
    scrollbar $w.xscroll \
	    -orient horiz \
	    -relief sunken \
            -highlightthickness 0 \
	    -command "$w.layout xscroll"
    scrollbar $w.yscroll \
	    -relief sunken \
            -highlightthickness 0 \
	    -command "$w.layout yscroll"
    bind $w.xscroll <Enter> \
      {mode_msg "scroll bar: BUT-1 scrolls current view" tmp}
    bind $w.yscroll <Enter> \
      {mode_msg "scroll bar: BUT-1: scrolls current view" tmp}

    ### build list area 
    list_boxes_build $w

    ### build navigator window.  It resides in the list_box frame.
    navigator_build $max_win

    # build Tool Bar, aka Mark Menu.
    tool_bar_build $w left

    ### build bot_bar
    frame $w.bot_bar 

    # box
    set STATUS(box_msg) "box ?"
    global LISTBOX_FONT
    button $w.box -relief sunken -bd 2 -anchor w -fg blue \
	    -font $LISTBOX_FONT \
	    -textvariable STATUS(box_msg) -width 23 -pady 0
    bind $w.box <Any-Button-1> "_win_status_box_select box"
    pack $w.box -side right -fill x -in $w.bot_bar
    bind $w.box <Enter> \
      {mode_msg "box size: BUT-1 changes box size" tmp}

    # cursor pos
    set STATUS(cursor_msg) "cursor ?"
    button $w.cursor -relief sunken -bd 2 -anchor w -fg blue \
	    -font $LISTBOX_FONT \
	    -textvariable STATUS(cursor_msg) -width 18 -pady 0
    bind $w.cursor <Any-Button-1> "_win_status_box_select cursor"
    pack $w.cursor -side right -fill x -in $w.bot_bar
    bind $w.cursor <Enter> \
      {mode_msg "cursor location: BUT-1 changes cursor location" tmp}

    # drc
    global SMALL_FONT
    # Init drc variables.
    set STATUS(drc_msg) {drc  ?}
    # Note: old width for "drc done" was -width 7
    checkbutton $w.drc_status -relief sunken -bd 2 -anchor w -fg blue \
	    -activeforeground blue \
    	    -textvariable STATUS(drc_msg) -font $SMALL_FONT\
	    -variable drc_on -width 12 \
	    -command "view_state_update drc"
    set STATUS(widget.drc) $w.drc_status
    bind $w.drc_status <Any-Button-3> drc_setup_menu
    pack $w.drc_status -side left -fill x -in $w.bot_bar
    bind $w.drc_status <Enter> \
      {mode_msg "DRC status: BUT-1: Design Rule Checker on/off.  BUT-2: next error" tmp}
    bind $w.drc_status <Any-Button-2> {:drc find}

    #zoom
    set zbar [zoom_bar_build $w]
    pack $zbar -side left -fill x -expand yes -in $w.bot_bar
    bind $zbar <Enter> \
      {mode_msg "zoom bar: BUT-1 can zoom view in/out" tmp}

    ### build layout
    layout $w.layout \
	    -xscrollcommand _win_xscroll \
	    -yscrollcommand _win_yscroll 
    
    # pack the main window
    win_pack 

    # initialize command mode
    mode_win_init $w
    
    # needs to be done here after window is visible  
    pal_scrollbar

    # set up binding to call pal_scrollbar if window is resized
    bind $max_win <Configure> "pal_scrollbar update"

    # load initial empty cell; Max pre-creates the "UNNAMED" cell,
    # but we are switching the name from (UNNAMED) to UNNAMED,
    # so it may not exist if the tcl and max c code are out of sync.
    catch {db_cell_new $CELL(UNNAMED)}
    :load $CELL(UNNAMED)

    # scale to something reasonable and put the box at a micron box
    # Hey, lets at least center it!  (pat)
    layt_box user 0 0 1 1
    view_cell

    view_state_update all

    return $w
}

proc win_pack {} -desc {
(re)packs a main window including components (e.g. palette) according to global vars
} {
    global max_win
    upvar #0 win_$max_win win_cur

    # unpack window
    foreach slave [pack slaves $max_win] {
	pack forget $slave
    }

    # Unpack left side bar
    foreach slave [pack slaves $max_win.leftsidebar] {
	pack forget $slave
    }

    # Unpack navigator window.
    pack forget $max_win.list_boxes.navigator

    if {$win_cur(top_bar)} {
	pack $max_win.top_bar -side top -fill x
    }


    # NOTE: currently the user has no way to set/reset win_cur(tool_bar),
    # but there is still an active layer indicator.  So if the pal
    # visibility is off, we need to turn off the tool_bar too.
    set win_cur(tool_bar) $win_cur(pal)
    if {$win_cur(pal) || $win_cur(tool_bar) || $win_cur(indicators)} {
	if { $win_cur(tool_bar) } {
	    # This is for the top location.
	    #pack $max_win.tool_bar -side top -fill x
	    # This is for the left side location.
	    pack $max_win.tool_bar -side top -fill x -in $max_win.leftsidebar
	}

	if { $win_cur(pal) } {
	    pack $max_win.pal -side top -fill y -in $max_win.leftsidebar
	}

	if { $win_cur(indicators) } {
	    pack $max_win.special -side bottom -anchor s -fill x -in $max_win.leftsidebar
	}

	pack $max_win.leftsidebar -side left -anchor n -fill y
    }

    if {$win_cur(bot_bar)} {
	pack $max_win.bot_bar -side bottom -fill x
    }

    if {$win_cur(list_boxes)} {
	pack $max_win.list_boxes -side right -fill y
	pack $max_win.resize_list_boxes -side right -fill y
    }

    if {0} {
	# This code greys out invalid View entries.
	# I took it out because we dont grey out any
	# of the other Menu items, for example, the ones
	# that pertain to cells when no cell is selected.

	# If the list_boxes are not selected, then grey out the
	# the menu option for the navigator window.
	if {$win_cur(list_boxes) } {
	    # Empty foreground color means it uses the menu default.
	    $max_win.mbar.view.menu entryconfigure "Navigator*" -foreground ""
	} else {
	    $max_win.mbar.view.menu entryconfigure "Navigator*" -foreground grey
	}

	# If the palette is not selected, then grey out the
	# the menu option for the Mark Menu.
	if {$win_cur(pal) } {
	    # Empty foreground color means it uses the menu default.
	    $max_win.mbar.view.menu entryconfigure "Mark Menu*" -foreground ""
	} else {
	    $max_win.mbar.view.menu entryconfigure "Mark Menu*" -foreground grey
	}
    }

    if {$win_cur(navigator)} {
	# Update navigator before re-packing it to avoid flashing.
	update ;# Gen other windows.
        $max_win.list_boxes.navigator config -width 1
	navigator_update
	pack $max_win.list_boxes.navigator -side bottom
    }

    if {$win_cur(scroll)} {
      if {[use_first win_cur(patvas) '0]} {
	pack $max_win.fpxscroll -side bottom -fill x	
        pack $max_win.fpyscroll -side right -fill y
      } else {
	pack $max_win.xscroll -side bottom -fill x	
        pack $max_win.yscroll -side right -fill y
      }
    }

    if {[use_first win_cur(patvas) '0]} {
      pack $max_win.fp -fill both -expand 1
    } else {
      pack $max_win.layout -fill both -expand 1
    }
}

proc _win_xscroll {args} -desc {
called back when layout window xscroll bar needs resetting.
} -doc {
Also updates navigator window.
} {
    global max_win
    eval $max_win.xscroll set $args
    navigator_update
}

proc _win_yscroll {args} -desc {
called back when layout window yscroll bar needs resetting.
} -doc {
Also updates navigator window and zoom scale.
} {
    global max_win
    eval $max_win.yscroll set $args
    zoomScaleSet
    navigator_update
}

proc _win_status_box_select {which} -desc {
    Services clicks on the cursor or box position status windows.
} -doc {
    The "which" arg is "box" or "cursor".
    If STATUS(box_cmd) is set, it is the command to execute for the
    box status window.  If STATUS(cursor_cmd) is set, it is the command
    to execute for the cursor window.
} {
    global STATUS
    if { $which == "box" } {
	if { [use_first STATUS(box_cmd)] != "" } {
	    $STATUS(box_cmd)
	} else {
	    box_dim_edit   ;# Default command when box size window clicked.
	}
    } else {
	if { [use_first STATUS(cursor_cmd)] != "" } {
	    $STATUS(cursor_cmd)
	} else {
	    box_goto_coords   ;# Default command when cursor location clicked.
	}
    }
}

# There is a sort-of race condition when using wire mode.
# Both main mode and wire mode bind <Any-Motion>. 
# So we use STATUS(box/cursor_msg_enabled) to turn off the messages
# that are posted by the global bind on <Any-Motion>.
# It actually works without the STATUS(msg_disabled),
# because first main mode calls this with no arg to show the cursor
# location using the main grid, then wire mode calls it to show
# the cursor location in the wiring grid.  As long as the
# events events are always executed in this order, it works ok,
# but I didnt trust it, so I added STATUS(msg_disabled). (pat)
proc cursor_msg_update {{msg ""}} {
  global STATUS

  if { $msg == "" } {
      # We were called by the bind on <Any-Motion>
      # Only post the message if STATUS(cursor_msg_enabled) is true.
      if { $STATUS(cursor_msg_enabled) } {
	  setl {x y} [layt_point user]
	  if { $y != "" } {
	    set STATUS(cursor_msg) [format "%9.3f,%9.3f" $x $y] 
	  }
      }
  } else {
      set STATUS(cursor_msg) $msg
  }
}

proc status_enable {window val {cmd ""}} -desc {
    Enable/disable cursor status messages.
} -doc {
    This is used in submodes that want to post custom messages
    in the cursor or box status windows at the bottom of the max window.
    Window is either "box" or "cursor".
    Val is 1 to enable normal update, 0 to disable so sub-mode
    can post custom messages with box_msg_update and cursor_msg_update.
    Cmd is an option command to execute when the window is clicked.
} {
    global STATUS
    set STATUS(${window}_msg_enabled) $val
    set STATUS(${window}_cmd) $cmd
    if { $val == 0 } {
	# Invoke update routine to restore cursor/box messages to default.
	${window}_msg_update
    }
}

proc box_msg_update {{msg ""}} {
  global STATUS max_win

  if { $msg != "" } {
    # Display custom message.
    set STATUS(box_msg) $msg
  } else {
    # We were called because the box size may have changed.
    setl {xbot ybot xtop ytop} [layt_box exact] 
    if { $ytop == {} } {
	set STATUS(box_msg) "box not in window"
    } else {
      set boxw [expr $xtop - $xbot] 
      set boxh [expr $ytop - $ybot] 
      switch $STATUS(box_msg_type) {
      "size" {
	  # Display box size
	  set STATUS(box_msg) [format "box: %9.3f x %.3f" $boxw $boxh] 
	  $max_win.box configure -width 23
	}
      "corners" {
	  set STATUS(box_msg) [format "box: %9.3f,%.3f  %.3f,%.3f" \
		  $xbot $ybot $xtop $ytop] 
	  $max_win.box configure -width 38
	}
      "origin+size" {
	  set STATUS(box_msg) [format "box: %9.3f,%.3f  %.3f x %.3f" \
		  $xbot $ybot $boxw $boxh] 
	  $max_win.box configure -width 38
	}
      "disable" {
	  set STATUS(box_msg) "box..."
	  $max_win.box configure -width 7
	}
      }
    }
  }
}

proc win_title_update {} -desc {
    update main window title
} {
    global max_win

    if {$max_win == ""} return

    set path [string trimright [join [lay_path] /] /]
    set root [lay_rootcell]
    set edit [lay_editcell]

    set prompt [winfo name .]
    regsub " #" $prompt "#" prompt  ;# Remove embedded space just to make it look nicer.
    if {$root == $edit } {
	set msg "$prompt:  [_win_add_flags $root]"
    } else {
	set msg "$prompt:  [_win_add_flags $edit] ($path)"
    }
    
    set msg "$msg  [cell_file $edit]"

    wm title $max_win $msg
    wm iconname $max_win $msg
}

proc _win_add_flags {cell} -desc {
    prefix 'R' for readOnly and 'M' for modified to cellname (as appropriate)
} {
    setl {flags file} [cell_info $cell]

    if {$flags == "__NO_SUCH_BUFFER__"} {return "?? $cell"}

    set modified [memq $flags modified]
    set readOnly [memq $flags readOnly]

    if {$readOnly && $modified} { 
	set prefix "MR " 
    } elseif {$readOnly} {          
	set prefix "R  " 
    } elseif {$modified} {          
	set prefix "M  " 
    } else {
	set prefix "   "
    }
    
    return "$prefix$cell"
}
