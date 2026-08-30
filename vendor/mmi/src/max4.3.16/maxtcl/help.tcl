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

set RCSVERSION(help.tcl) { $Revision: 1.10 $ }

### help stuff

proc help_menu_add {label desc} -desc {
  attach help message to menu item
} -doc {
  Messages attached via this procedure are displayed in "mode_msg" area while
  cursor is on menu item.
  Note: The label can be just the menu label, or the menu widget
  concatenated with the menu label separated by a comma, eg, $menu,$label.
  The latter case must be used if there is a chance that two menu
  items might be the same.
} {
    global HELP_MENU
    set HELP_MENU([join $label _]) $desc
}

# taken out of menu.tcl in the tk library and modified to show help 
# 11-98, pat: new versions added for tk8.0 to replace old tk4.1 code.

if { $tk_version == "4.1" } {

    # tkMenuMotion --
    # This procedure is called to handle mouse motion events for menus.
    # It does two things.  First, it resets the active element in the
    # menu, if the mouse is over the menu.  Second, if a mouse button
    # is down, it posts and unposts cascade entries to match the mouse
    # position.
    # Arguments:
    # menu -		The menu window.
    # y -			The y position of the mouse.
    # state -		Modifier state (tells whether buttons are down).

    proc tkMenuMotion {menu y state} {
      global tkPriv LAST_MENU_ITEM
      if {$menu == $tkPriv(window)} {
	$menu activate @$y
	if {[lsearch "command radiobutton cascade" [$menu type @$y]] != -1} {
	  set name [lindex [$menu entryconfigure @$y -label] 4]
	  if {[use_first LAST_MENU_ITEM] != $name} {
	    set LAST_MENU_ITEM $name
	    display_help_item $menu $name
	  }
	} 
      }
      if {($state & 0x1f00) != 0} {
	$menu postcascade active
      }
    }

    # tkMenuUnpost --
    # This procedure unposts a given menu, plus all of its ancestors up
    # to (and including) a menubutton, if any.  It also restores various
    # values to what they were before the menu was posted, and releases
    # a grab if there's a menubutton involved.  Special notes:
    # 1. It's important to unpost all menus before releasing the grab, so
    #    that any Enter-Leave events (e.g. from menu back to main
    #    application) have mode NotifyGrab.
    # 2. Be sure to enclose various groups of commands in "catch" so that
    #    the procedure will complete even if the menubutton or the menu
    #    or the grab window has been deleted.
    #
    # Arguments:
    # menu -		Name of a menu to unpost.  Ignored if there
    #			is a posted menubutton.

    proc tkMenuUnpost menu {
	global tkPriv LAST_MENU_ITEM
	set mb $tkPriv(postedMb)

	#mode_msg "__RESTORE__" help
	set LAST_MENU_ITEM ""

	# Restore focus right away (otherwise X will take focus away when
	# the menu is unmapped and under some window managers (e.g. olvwm)
	# we'll lose the focus completely).

	catch {focus $tkPriv(focus)}
	set tkPriv(focus) ""

	# Unpost menu(s) and restore some stuff that's dependent on
	# what was posted.

	catch {
	    if {$mb != ""} {
		set menu [$mb cget -menu]
		$menu unpost
		set tkPriv(postedMb) {}
		$mb configure -cursor $tkPriv(cursor)
		$mb configure -relief $tkPriv(relief)
	    } elseif {$tkPriv(popup) != ""} {
		$tkPriv(popup) unpost
		set tkPriv(popup) {}
	    } elseif {[wm overrideredirect $menu]} {
		# We're in a cascaded sub-menu from a torn-off menu or popup.
		# Unpost all the menus up to the toplevel one (but not
		# including the top-level torn-off one) and deactivate the
		# top-level torn off menu if there is one.

		while 1 {
		    set parent [winfo parent $menu]
		    if {([winfo class $parent] != "Menu")
			    || ![winfo ismapped $parent]} {
			break
		    }
		    $parent activate none
		    $parent postcascade none
		    if {![wm overrideredirect $parent]} {
			break
		    }
		    set menu $parent
		}
		$menu unpost
	    }
	}

	# Release grab, if any, and restore the previous grab, if there
	# was one.

	if {$menu != ""} {
	    set grab [grab current $menu]
	    if {$grab != ""} {
		grab release $grab
	    }
	}
	if {$tkPriv(oldGrab) != ""} {

	    # Be careful restoring the old grab, since it's window may not
	    # be visible anymore.

	    catch {
		if {$tkPriv(grabStatus) == "global"} {
		    grab set -global $tkPriv(oldGrab)
		} else {
		    grab set $tkPriv(oldGrab)
		}
	    }
	    set tkPriv(oldGrab) ""
	}
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
	global tkPriv LAST_MENU_ITEM

	#mode_msg "__RESTORE__" help
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
    }

} else {
    # This code is for tk 8.0.


    # Arguments:
    # menu -                The menu window.
    # x -                   The x position of the mouse.
    # y -                   The y position of the mouse.
    # state -               Modifier state (tells whether buttons are down).
    proc tkMenuMotion {menu x y state} {
	global tkPriv
	if {$menu == $tkPriv(window)} {
	    if {[$menu cget -type] == "menubar"} {
		if {[info exists tkPriv(focus)] && \
			([string compare $menu $tkPriv(focus)] != 0)} {
		    $menu activate @$x,$y
		    tkGenerateMenuSelect $menu
		}
	    } else {
		$menu activate @$x,$y
		tkGenerateMenuSelect $menu
	    }

	    # For max help messages:
	    global LAST_MENU_ITEM
	    if {[lsearch "command checkbutton radiobutton cascade" \
		[$menu type @$y]] != -1} {
	      set name [lindex [$menu entryconfigure @$y -label] 4]
	      if {[use_first LAST_MENU_ITEM] != $name} {
		set LAST_MENU_ITEM $name
		display_help_item $menu $name
	      }
	    }

	}
	if {($state & 0x1f00) != 0} {
	    $menu postcascade active
	}
    }

    # Hook tkMenuUnpost and tkMenuLeave to restore max help message
    # when mouse leaves the menu.  We check info commands first,
    # just so this file can be sourced multiple times when in developer mode.
    if {[info commands orig_tkMenuUnpost] == ""} {
	rename tkMenuUnpost orig_tkMenuUnpost
	proc tkMenuUnpost {menu} {
	    # For max help messages:
	    global LAST_MENU_ITEM
	    #mode_msg "__RESTORE__" help
	    set LAST_MENU_ITEM ""

	    # Invoke original tk menu handler
	    orig_tkMenuUnpost $menu
	}

	rename tkMenuLeave orig_tkMenuLeave
	proc tkMenuLeave {menu rootx rooty state} {
	    # For max help messages:
	    global LAST_MENU_ITEM
	    #mode_msg "__RESTORE__" help
	    set LAST_MENU_ITEM ""

	    # Invoke original tk menu handler
	    orig_tkMenuLeave $menu $rootx $rooty $state
	}
    }
}


proc display_help_item {menu name} {

  global HELP_MENU

  # replace spaces with underscores
  set name [join $name _]

  mode_msg [use_first HELP_MENU($menu,$name) HELP_MENU($name)] help
}

proc help_max_get_max_id {} -desc {
  Return the identifier string for the max Help window and log file.
} {
  global MAX_VERSION MAX_COMPILE_TIME MAX_VERSION_TAG
  if {$MAX_VERSION_TAG != ""} {
    set message "MAX $MAX_VERSION $MAX_VERSION_TAG - compiled $MAX_COMPILE_TIME"
  } else {
    set message "MAX $MAX_VERSION - compiled $MAX_COMPILE_TIME"
  }
  return $message
}

proc help_max_get_config {} -desc {
  Return the identifier string for the max Help window and log file.
} {
  global MMI_TOOLS MN_TECH MN_TECH_VAR PROJECT
  set message "CONFIGURATION:"
  append message "\nMMI Tools Directory (MMI_TOOLS) = $MMI_TOOLS"
  if {[info exists PROJECT] && $PROJECT != ""} {
    append message "\nProject = $PROJECT"
  }
  append message "\nTechnology = $MN_TECH"
  if { $MN_TECH_VAR != {} } {
      append message "\nTechnology variation = $MN_TECH_VAR"
  }
  return $message
}

proc help_about_max {} -desc {max version and configuration information} {
  global MAX_LEGAL_NOTICE 

  ### TEXT
  set message "[help_max_get_max_id]\n$MAX_LEGAL_NOTICE\n\n[help_max_get_config]\n"

  ### BUILD WIDGET

  # TOPLEVEL
  if {[info commands XFDestroy] != ""} {
    catch {XFDestroy .mode_box}
  } {
    catch {destroy .about_max}
  }
  toplevel .about_max \
    -borderwidth 0
  wm geometry .about_max "+200+200"
  wm title .about_max "About MAX"

  # MESSAGE 
  label .about_max.message -justify left -padx 2 -text $message
  pack .about_max.message -expand 1

  # CLOSE BUTTON
  # Lee set pattern to remember the old pattern we were at
  button .about_max.close \
	  -text "Close" \
	  -command "catch {destroy .about_max}"
  pack .about_max.close -fill x -expand 1 

}

    

