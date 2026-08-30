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

set RCSVERSION(keymap.tcl) { $Revision: 1.4 $ }

# The type is "command" or "menu".
set MAX_STRUCT(keymap_event) "type label event flags"


proc keymap_init {} -desc {
  Set up initial keymap.
} -doc {
  Look for a keymap file, and read it if found.
  Then send the current keymap to mode_rebind.
} {
  global _KEYMAP_BIND_NAME
  # This is for the sun.  TODO: what is it on Linux?
  set _KEYMAP_BIND_NAME(\{) braceleft
  set _KEYMAP_BIND_NAME(\}) braceright
  set _KEYMAP_BIND_NAME(\[) bracketleft
  set _KEYMAP_BIND_NAME(\]) bracketright
  set _KEYMAP_BIND_NAME(\$) dollar
  set _KEYMAP_BIND_NAME(<) less
  set _KEYMAP_BIND_NAME(>) greater
  set _KEYMAP_BIND_NAME(!) exclam
  set _KEYMAP_BIND_NAME(@) at
  set _KEYMAP_BIND_NAME(#) numbersign
  set _KEYMAP_BIND_NAME(%) percent
  set _KEYMAP_BIND_NAME(^) asciicircum
  set _KEYMAP_BIND_NAME(&) ampersand
  set _KEYMAP_BIND_NAME(*) asterisk
  set _KEYMAP_BIND_NAME(() parenleft
  set _KEYMAP_BIND_NAME()) parenright
  set _KEYMAP_BIND_NAME(_) underscore
  set _KEYMAP_BIND_NAME(=) equal
  set _KEYMAP_BIND_NAME(+) plus
  set _KEYMAP_BIND_NAME(-) minus
  set _KEYMAP_BIND_NAME(\\) backslash
  set _KEYMAP_BIND_NAME(|) bar
  set _KEYMAP_BIND_NAME(`) grave
  set _KEYMAP_BIND_NAME(~) asciitilde
  set _KEYMAP_BIND_NAME(\;) semicolon
  set _KEYMAP_BIND_NAME(:) colon
  set _KEYMAP_BIND_NAME(') apostrophe
  set _KEYMAP_BIND_NAME(\") quotedbl
  set _KEYMAP_BIND_NAME(,) comma
  set _KEYMAP_BIND_NAME(/) slash
  set _KEYMAP_BIND_NAME(?) question
  set _KEYMAP_BIND_NAME(.) period

  set path [mn_sys_find "default.keymap"]

  if { $path != "" } {
    keymap_load $path
  }
}


proc keymap_bind {args} -desc {
  Add event to current keymap.
} -doc {
  USAGE:
    keymap_bind [-options] event action
  
  Options:
  -menu : action is a menu command, see below.
  -mode <modename> : binding is active only in the specified max mode.
    The max mode names are generally not documented, so this
    option is of limited utility to end-users.

  The <event> must be in the form allowed by the tcl "bind" command,
  which is any single ascii character (except < or >) or a
  keysym enclosed in angle brackets, example: <Shift-a>.
  Case is important! 
  If the event is empty, the binding is removed from the current keymap.
  By default, the <action> is a a command to execute.
  If -menu is specified, the action is searched for in the max menus,
  with spaces replaced by underscore, and all non-alphanumeric characters
  removed.
} {
  global _KEYMAP

  # if mode is "default", mode_rebind will look in both "main" and "common" mode.
  set options [list {mode default} {menu}]
  setl {event action} [call_keyword $args $options]

  if { $menu } {
    set command [menu_bar_command $action]
    if { $command == "" } {
      msg "warning: keymap probably out of date: menu item not found: $action\n"
    }
  } else {
    set command $action
  }

  if { $event != "" && $command != "" } {
    mode_rebind $mode $event $command
  }

  # Doing mode_rebind does not actually update the current bindings.
  # As a speedup, if we are loading a keymap file, defer updating
  # the bindings until we are all done.
  if {[use_first _KEYMAP(defer_mode_change)] != 1} {
    mode_change [mode_current]
  }
}


proc _keymap_activate {} -desc {
  Activate the new keymap.
} {
  global _KEYMAP

  if { [mode_current] != "main" } {
    error "Must be in main mode to update the keymap!"
    return; # probably not necessary
  }

  cursor_busy 1

  # Start with reset to factory bindings, to be safe.
  mode_copy main,factory main
  mode_copy common,factory common

  foreach thing $_KEYMAP(new) {
    struct keymap_event k $thing
    switch ${k.type} {
      "menu" {
	# The cmd is the menu label in menu_bar_fix_label format.
	set cmd [menu_bar_command ${k.label}]
	mode_rebind default ${k.event} $cmd
      }
      "command" {
	mode_rebind default ${k.event} ${k.label}
      }
    }
  }
  mode_change main

  # Update the visible accelerators in the menus.
  menu_bar_update
  cursor_busy 0
}


proc _keymap_save_as_default {} -desc {
  can only be called from keymap code, as it uses the temporary _KEYMAP(new).
} {
  global _KEYMAP

  # This is the name of the keymap that is loaded at startup.
  set maxdir [max_private_dir]
  set filename $maxdir/default.keymap

  #set filename [fs_box -message "Save keymap to file:" -pattern "*.keymap" \
  #   -pathname $maxdir -filename default.keymap]
  #if { $filename == "" } {
  #  msg "Keymap save aborted.\n"
  #  return
  #}

  if {[file exists $filename]} {
    set retry [prop_dialog -title "Over-write file?" -buttons "Yes No" \
      "Over-write existing file: $filename  ?"]
    if { $retry != "Yes" } {
      msg "Keymap save aborted.\n"
      return
    }
  }

  # make the directory if needed
  set root [file dirname $filename]
  if {![file isdir $root]} {
    set makedir ""
    foreach string [split $root /] {
      if {$string == ""} {
	continue
      }
      append makedir /$string
      
      if {![file isdir $makedir]} {
	# make this directory
	catch "exec mkdir $makedir"
      }
    }
  }

  if {[catch {set pf [open $filename w]}]} {
    max_error "keymap error: Can not open filename: $filename"
    return
  }

  foreach thing $_KEYMAP(new) {
    struct keymap_event k $thing
    if { ${k.event} != "" } {

      set quote_event ${k.event}
      # Must backslash quote some characters.
      if {[string length ${k.event}] == 1 && \
	![string match {[a-zA-Z0-9]} ${k.event}] } {
	set quote_event "\\${k.event}"
      }

      if { ${k.type} == "menu" } {
	puts $pf "keymap_bind $quote_event \
		-menu [menu_bar_fix_label ${k.label}]"
      } else {
	# The label is the command itself
	puts $pf "keymap_bind $quote_event [list ${k.label}]"
      }
    }
  }

  close $pf

  # If they saved the keymap, we will assume they wanted to make
  # it the active keymap as well, equivalent to hitting "Done"
  # on the menu.
  #_keymap_activate

  puts "Saved keymap in file: $filename"
}


proc keymap_load {{filename ""}} -desc {
  Load specified keymap pathname.  If empty, prompt for it.
} {
  global _KEYMAP

  if { $filename == "" } {
    set filename [fs_box -message {Keymap File to Load:} -pattern {*.keymap}]
    if { $filename == "" } {
      # User aborted fs_box
      return
    }
  }

  msg "Loading keymap from: $filename\n"

  # Make keymap_bind faster.
  set _KEYMAP(defer_mode_change) 1

  cursor_busy 1
  if {[msg_catch {source $filename} errmsg]} {
    msg -warn "Error reading keymap file ($filename)\nerror was: ${errmsg}.\n"
  }
  cursor_busy 0

  # Make the bindings happen now.
  set _KEYMAP(defer_mode_change) 0
  mode_change [mode_current]
  menu_bar_update
}



proc _keymap_load_menu {} -desc {
  popup menu of available keymaps.
} {
  global MN_PATH_SYS_LIB

  # Find all keymaps on the standard path.
  set keymap_files ""
  set pwd [pwd]
  foreach path $MN_PATH_SYS_LIB {
    if {[catch { \
	cd $path
	set list [glob *.keymap]
	cd $pwd
      }]} {
	# Failed.  Directory probably does not exist.
	continue
    }
    foreach filename $list {
      lappend keymap_files $path/$filename
    }
  }


  set radios ""
  set values ""
  foreach keymap_file $keymap_files {
    lappend radios "[file tail $keymap_file] (${keymap_file})"
    lappend values $keymap_file
  }

  lappend radios "Search for file..."
  # An empty arg to keymap_load makes it search for the file...
  lappend values ""

  set which [lindex $values 0]

  set prop_list ""
  lappend prop_list [list "Keymap file:" which -radio $radios -values $values]
  lappend prop_list [list "" "" -help { \
    This is a list of any pre-defined keymaps on your system. \
    These are in files named *.keymap and found on the standard max path: \
    ~/mmi_private/max/ $MMI_LOCAL/max/ $MMI_TOOLS/max/ \
    Your own default keymap, if any, will appear on the list, as well.
System administrators can add keymaps to this list by creating and saving\
    a keymap in max, then copying their file ~/mmi_private/max/default.keymap\
    to $MMI_LOCAL/max/new.keymap, where "new" is a\
    descriptive name of the keymap. \
    }]

  set ret [prop_menu2 -title "Load keymap file" $prop_list]
  if { $ret == 0 } {
    # Cancelled
    return
  }

  keymap_load $which

  # Recreate _KEYMAP(new) from new current bindings.
  _keymap_edit_create
  _keymap_edit_update
}

proc _keymap_can_event {event} -desc {
  Convert event to canonical format.
} -doc {
  Convert Shift-u to U, etc.
  Needed so we can compare events.
} {
  setl {type modifiers key} [seq_parse $event]
  if { $type == "ALPHA" } {
    if {$modifiers == "Shift" && [string match {[A-Za-z]} $key] } {
      return [string toupper $key]
    } elseif {$modifiers == "" && [string length $key] == 1} {
      return $key
    }
  }
  if { $modifiers == "" } {
    return "<$key>"
  } else {
    return "<[join $modifiers -]-$key>"
  }
}


proc _keymap_bind_edit {} -desc {
  If key specified, edit that binding, otherwise add new.
} {
  global _KEYMAP
  global _KEYMAP_BIND_NAME

    # Edit the binding that is currently selected in the list box.

    # If multiple, use lindex to just edit the first one.
    set keymap_index [lindex [.keymap.keys.list curselection] 0]
    if { $keymap_index < 0 } { return }

    set entry [lindex $_KEYMAP(new) $keymap_index]
    struct keymap_event k $entry

    if { ![memq ${k.flags} edit] } {
      max_error "keymap error: Can not change that key binding"
      return
    }

    # Break out key and modifier.
    setl {type modifier key} [seq_parse ${k.event}]
    set tmp [lsearch $modifier Double]
    if {$tmp >= 0} {
      # This is not a modifier for our purposes.
      set key "Double-$key"
      set modifier [lreplace $modifier $tmp $tmp]
    }
    if {$modifier == ""} {
      set modifier "None"
    }

    if {[llength $modifier] > 1} {
      # Two modifiers pressed at once.  How to handle?  Punt.
      set key "[join [lrange $modifier 1 end] -]-$key"
      set modifier [lindex $modifier 0]
    }

  # List of possible keyboard and mouse binding choices,
  # in the form tk likes.
  # NOTES:
  # The bind command is very very picky about getting the
  # capitalization just right!!!  The following are correct
  # for the sun, but we will not enforce them, because
  # we dont know about Linux, or even other Sun OS versions.
  #
  # So make sure the pressed key is one of the following.
  # Dont add "Help" key, it doesnt work reliably, seems
  # to struggle for dominance with Sun window system?
  # Dont add L-keys (keys on left of Sun keyboard), we are
  # not letting the user rebind them.
  # Dont add F11 or F12, they return something wierd
  # on the Sun keyboard, definitely not "F11" and "F12"
  # The Prior/Next are PageUp/PageDown

  set single_key_choices ""
  foreach tmp [array names _KEYMAP_BIND_NAME] {
    lappend single_key_choices $tmp
  }
  set key_choices [concat \
    [split {abcdefghijklmnopqrstuvwxyz0123456789} ""] \
    [list Left Right Up Down Insert Delete Prior Next \
	escape backspace \
	F1 F2 F3 F4 F5 F6 F7 F8 F9 F10] \
    $single_key_choices \
    ]

  while {1} {

    set prop_list ""

    lappend prop_list [list {Command:} k.label  -label]

    lappend prop_list [list {Hot-Key:} key \
	-popup $key_choices \
	-help {The Hot-Key entry can be empty to remove this hot-key,\
	or can be any single character\
	(a-z, 0-9, or symbols like $ or %), a function key designator\
	(F1 - F10 only, not F11 or F12) or a valid "keysym" name\
	for special keys on your system, like "Left" for the left-arrow key. \
	CASE IS IMPORTANT!  "Left" is not the same as "left".
Valid keysym names vary from system to system and can be\
	difficult to discover.  Use the popup menu next to the "Hot-Key:"\
	entry to get a list of possibly valid keysyms. \
	On Sun systems, use "Next" for the page-up key, and "Prior" for\
	the page-down key.
Sometimes the symbolic key you select (like "<") will automatically\
	be converted to a keysym name (like "less") to make sure it\
	will be a valid binding for the X window system.
Many keys have multiple keysym names; max does not detect\
	conflicts if you use synonyms.  For example, if you bind the hot-key\
	"%" to one function and "percent" (a valid keysym synonymous with %)\
	to another function, no error will be printed, but obviously the % \
	hot-key will only perform one of the two functions.}]
    
    lappend prop_list [list {Modifier:} modifier \
	-radio {None Shift Control Alt} \
	-help {The "Alt" key modifier is pre-empted by some window\
	managers and not passed to application programs, so it \
	may not be usable in max.  Max automatically maps all "Alt"\
	key combinations to "Meta" key combinations as well,\
	so if you create a hot-key\
	using the "Alt" modifier, you may be able to use the hot-key\
	combination by pressing the "Meta" key instead of the "Alt" key.\
	On Sun keyboards, the\
	"Meta" key is the one with the little diamond on it.}]
    
    set title "Edit Key Binding"
    if {![prop_menu2 -title $title $prop_list]} {
      # cancelled
      return
    }

    # If key is empty, user want to delete this binding.
    if { $key == "" } {
      # Delete this key binding.
      set k.event ""
      set _KEYMAP(new) [lreplace $_KEYMAP(new) $keymap_index $keymap_index \
	  [destruct keymap_event k]]
      break
    }


    # I was going to change case automatically, and do obvious
    # maps like pageup -> prior, etc.  However, I dont know
    # for sure that these bindings are the same on all machines,
    # and I dont want to mess it up if the user knew what
    # they were doing and entered it correctly, even though
    # it doesnt match my KEYMAP_BIND_NAME table.

    if { $modifier == "None" } {
      # If no modifier, a single ASCII char is a valid keysym,
      # except for <>
      if { $key == "<" || $key == ">" } {
	set newevent $_KEYMAP_BIND_NAME($key)
      }
      set newevent "$key"
    } else {
      # If user entered a special character, translate to bind name.
      # Tk does allow you to bind, for example, %, but not <Control-%>;
      # you must use <Control-percent>.
      if {[info exists _KEYMAP_BIND_NAME($key)]} {
	set key $_KEYMAP_BIND_NAME($key)
      }
      set newevent "$modifier-$key"
    }

    if {[string length $newevent] != 1} {
      set newevent "<$newevent>"
    }

    set newevent [_keymap_can_event $newevent]

    # See if its a bad binding.  Use glob matching to get
    # anything close
    set its_bad 0
    if {[lsearch -exact $_KEYMAP(illegal_bind) $newevent] >= 0} {
      set its_bad 1
    }

    if { $its_bad } {
      warning "You can not use that binding; it is reserved"
      continue
    }


    # To figure out if the key is valid, try it out now.
    if {[catch { bind .keymap.test_button $newevent {puts hi} }]} {
      max_error "keymap error: Invalid key: $key"
      continue
    }

    # See if the key is already mapped to something in _KEYMAP(new).
    set old_index -1
    set i 0
    foreach thing $_KEYMAP(new) {
      struct keymap_event o $thing
      if { ${o.event} == $newevent } {
	set old_index $i
	break
      }
      incr i
    }

    if { $old_index >= 0 } {
      set retry [prop_dialog -title "Re-map key?" -buttons "Yes No" \
	"The [seq_pp $newevent 1] key is already bound to: ${o.label}\n\
	Do you want to remap it?"]
      if { $retry != "Yes" } { continue }

      # Delete old binding for this key, if any.
      struct keymap_event o [lindex $_KEYMAP(new) $old_index]
      set o.event ""
      set _KEYMAP(new) [lreplace $_KEYMAP(new) $old_index $old_index \
	[destruct keymap_event o]]
    } else {
      # See if key is mapped to a command not in _KEYMAP(new)
      set thing [lsearch2 -value -index 0 $_KEYMAP(all) $newevent]
      if { $thing != "" } {
	setl {event cmd} $thing
	set retry [prop_dialog -title "Re-map key?" -buttons "Yes No" \
	  "The [seq_pp $newevent 1] key is already bound to the command: $cmd\n\
	  Do you want to remap it?"]
	if { $retry != "Yes" } { continue }
      }
    }

    # Add in the new binding.
    set k.event $newevent
    set _KEYMAP(new) [lreplace $_KEYMAP(new) $keymap_index $keymap_index \
	[destruct keymap_event k]]

    break

  }
  _keymap_edit_update
}


proc _keymap_invoke_list {w y} -desc {
  Edit the moused key binding from .keymap.keys.list
} {
  set index [$w nearest $y]
  if { $index == -1 } {return}

  # Select the moused item from the list.
  # We were invoked by mouse button 2, which does not automatically
  # do any selecting on a list box.
  .keymap.keys.list selection clear 0 end
  .keymap.keys.list selection set $index
  update idletasks  ;# This makes listbox selection visible right now.

  _keymap_bind_edit
}


proc _keymap_edit_create {} -desc {
  create _KEYMAP(new) array from current key bindings.
} {
  global _KEYMAP

  cursor_busy 1

  # Add menu commands first:
  set _KEYMAP(new) ""
  set _KEYMAP(all) ""
  set _KEYMAP(illegal_bind) ""

  # create map of current events.
  foreach modename {main common} {
    foreach thing [mode_events $modename] {
      struct mode_event e $thing
      set e.event [_keymap_can_event ${e.event}]
      # There can be multiple events to the same cmd.
      # We will not put the L key or HELP or Control-z key bindings in the menu
      # if there is another hotkey binding available.
      if {!([regexp -nocase {<L[0-9]+|.*help|Control-z>} ${e.event}] && \
	    [info exists map_cmd2event(${e.cmd})])} {
	set map_cmd2event(${e.cmd}) ${e.event}
      }
      struct mode_info c [mode_info ${e.cmd}]
      if { ! [memq ${c.flags} edit] } {
	lappend _KEYMAP(illegal_bind) ${e.event}
      } else {
	lappend _KEYMAP(all) [list ${e.event} ${e.cmd}]
      }
    }
  }

  set menu_info [menu_bar_get]

  set label_len 0
  foreach thing $menu_info {
    setl {label command} $thing
    set fix_label [menu_bar_fix_label $label]
    set event [use_first map_cmd2event($command)]
    struct mode_info c [mode_info $command]
    # Some bindings (eg Control-C and Print commands) are not editable;
    # dont include them in the keymap menu.
    if { [memq ${c.flags} edit] } {
      set k.type menu
      set k.label $label
      set k.event $event
      set k.flags ${c.flags}
      lappend _KEYMAP(new) [destruct keymap_event k]
      set label_len [max $label_len [string length $label]]
    }
  }

  # This is a list of additional commands that we allow to appear
  # in the keymap edit window, but that are not in the main menus.
  # KLUDGE: the menu_repeat is stripped off elsewhere off
  # before the command is displayed.
  set extra_commands [list \
    "menu_repeat :scroll up .1" \
    "menu_repeat :scroll down .1" \
    "menu_repeat :scroll left .1" \
    "menu_repeat :scroll right .1" \
    "menu_repeat :scroll up .9" \
    "menu_repeat :scroll down .9" \
    "menu_repeat :scroll left .9" \
    "menu_repeat :scroll right .9" ]

  foreach command $extra_commands {
    set event [use_first map_cmd2event($command)]
    set k.type command
    set k.label $command
    set k.event $event
    set k.flags "edit"
    lappend _KEYMAP(new) [destruct keymap_event k]
    # The "and" is because "command" is longer than "menu".
    set label_len [max $label_len [string length "and $command"]]
  }

  set _KEYMAP(MENU_LABEL_LENGTH) $label_len

  cursor_busy 0
}


proc _keymap_edit_update {{seekey ""}} -desc {
  update the keymap list-box in the menu from _KEYMAP(new).
} -doc {
  If <seekey>, scroll to make that binding visible.
} {
  global _KEYMAP

  cursor_busy 1

  set select [.keymap.keys.list curselection]
  if {[.keymap.keys.list size] > 0} {
      set save_top [.keymap.keys.list index @0,0]
      .keymap.keys.list delete 0 end
  }

  foreach thing $_KEYMAP(new) {
    struct keymap_event k $thing
    set lab ${k.label}
    # KLUDGE: remove special wrapper from front of command in visible menu.
    regsub {^menu_repeat } ${k.label} "" lab
    set str [format "%-$_KEYMAP(MENU_LABEL_LENGTH)s  %-15s" \
	${lab} [seq_pp ${k.event} 1]]
    .keymap.keys.list insert end $str
  }

  # Scroll listbox to about where it was previously.
  # Catch it in case it is out of bounds, now.
  catch {.keymap.keys.list yview $save_top}

  if { $seekey != "" } {
    # Scroll listbox to make key binding visible.
    catch {.keymap.keys.list see $index}
  }

  # Attempt to restore the previous selection.
  # Only bother to restore a single selection, ignore range.
  set select [lindex $select 0]
  if { $select != "" } {
    if { $select == [.keymap.keys.list size] && $select > 0 } {
      incr select -1
    }
    .keymap.keys.list selection set $select
  }
  update
  cursor_busy 0
}

proc _keymap_revert {} {

  mode_factory_reset
  # Recreate _KEYMAP(new) from new current bindings.
  _keymap_edit_create
  # And copy to the menu.
  _keymap_edit_update
  msg "Reverted to factory keymap.\n"
  return
}


proc _keymap_edit_done {} {
  global _KEYMAP
  _keymap_activate
  puts "Current keymap updated."
  if { $_KEYMAP(save_flag) } {
    # User wants to keep their changes.
    _keymap_save_as_default
  }
  destroy .keymap
}


proc keymap_edit {} {
  global _KEYMAP
  global LISTBOX_FONT
  global DIALOG_FONT
  set font $DIALOG_FONT

  set _KEYMAP(save_flag) [use_first _KEYMAP(save_flag) '0]

  _keymap_edit_create

  set helpmsg {The list-box contains menu entries and other commands for\
    which you can reprogram hot-keys in max. \
    The left column is a description of the menu or command, and the right\
    column is the hot-key, or is empty if no hot-key is assigned. \
    Click mouse BUT-1 on the line for which you want to change the hot-key. \
    Some hot-keys can not be changed (eg: Control-C), and those\
    menu items do not appear in the list.
If you select "Done", the new hotkeys will be used in the current\
    max session. \
    The new hot-keys will appear in the help for "Current Hot Keys",\
    and will also appear in the menus. 
If you check "Save as default keymap for future max sessions",\
    the hotkeys will also be saved in the file:\
    ~/mmi_default/max/default.keymap and will be used in future\
    max sessions as well. \
    }


  catch { destroy .keymap }
  util_win_create .keymap "Edit Keymap"
  wm geometry .keymap "750x500[_relative_origin]"

  # MESSAGE AT TOP
  label .keymap.message \
	  -relief raised -anchor c \
	  -text {Editing Current Hot-Keys}
  pack .keymap.message -side top -fill x

  if {0} {
      set _KEYMAP(mode) main
      radiobutton .keymap.rad1 \
	    -text "Bindings for Main mode" \
	    -variable _KEYMAP(mode) -value main \
	    -command {_keymap_edit_update ""}
      radiobutton .keymap.rad2 \
	    -text "Bindings for Common mode (keys work in all modes)" \
	    -variable _KEYMAP(mode) -value common \
	    -command {_keymap_edit_update ""}
      pack .keymap.rad1 .keymap.rad2 -side top -anchor w -padx 3
  }

  
  # listbox for bindings.
  frame .keymap.keys -borderwidth 1 -relief raised
  pack .keymap.keys -side top -fill both -expand 1

  scrollbar .keymap.keys.vscroll \
	  -relief raised \
	  -command ".keymap.keys.list yview"
  pack .keymap.keys.vscroll -side right -fill y

  listbox .keymap.keys.list \
	  -font $LISTBOX_FONT \
	  -exportselection false \
	  -selectmode single \
	  -relief raised \
	  -yscrollcommand ".keymap.keys.vscroll set"
  pack .keymap.keys.list -side left -fill both -expand 1

  # Button-1 is, by default, already bound to select the item.

  bind .keymap.keys.list <Button-1> {_keymap_invoke_list %W %y}
  bind .keymap.keys.list <Button-2> {_keymap_invoke_list %W %y}

  # Buttons
  if {0} {
      frame .keymap.f1 -borderwidth 3 -relief flat
      label .keymap.f1.lab -font $font -text "Binding:" -width 10
      #button .keymap.f1.new -font $font -pady 1 \
	      -text "Add New..." \
	      -command "_keymap_bind_edit new"
      button .keymap.f1.edit -font $font -pady 1 \
	      -text "Edit selected..." \
	      -command "_keymap_bind_edit"
      button .keymap.f1.del -font $font -pady 1 \
	      -text "Delete selected" \
	      -command "_keymap_bind_delete"
      pack .keymap.f1.lab .keymap.f1.edit .keymap.f1.del \
	  -side left -anchor w -padx 4
      pack .keymap.f1 -side top -fill x
  }


  # The frames must be declared before the buttons,
  # even though it will not be mentioned until later.  Why?
  frame .keymap.f2 -borderwidth 3 -relief flat
  frame .keymap.f3 -borderwidth 4 -relief flat
  # Sunken frame indicates default button if user presses Return.
  frame .keymap.default -relief sunken -bd 1

  checkbutton .keymap.check -variable _KEYMAP(save_flag) \
     -font $font -pady 1 \
     -text "Save as default keymap for future max sessions"

  button .keymap.revert -font $font -pady 1 \
	  -text "Revert to factory default keymap" -command _keymap_revert
  button .keymap.load -font $font -pady 1 \
	  -text "Load keymap from file..." -command _keymap_load_menu
  #button .keymap.done2 -font $font -pady 1 \
	  -text "Done - Save keymap as default for this session only" \
	  -command _keymap_edit_done
  #button .keymap.save -font $font -pady 1 \
	  -text "Done - Save keymap as max default" \
	  -command _keymap_save_as_default
  button .keymap.cancel -font $font -padx 1 -pady 1 \
	  -text "Cancel" -command "catch {destroy .keymap}"
  button .keymap.done -font $font -pady 1 \
	  -text "Done" -command _keymap_edit_done
  button .keymap.help -font $font -padx 1 -pady 1 \
      -text "Help" \
      -command "prop_dialog -title {Keymap Help} {$helpmsg}"

  pack .keymap.revert .keymap.load .keymap.check \
	-in .keymap.f2 -side top -anchor w -padx 4 -expand 1 -fill x
  pack .keymap.f2 -side top -anchor c

  pack .keymap.done -in .keymap.default -padx 1 -pady 1 -ipadx 0 -ipady 0
  pack .keymap.default -in .keymap.f3 \
	-side left -padx 4m -ipadx 0 -ipady 0 -pady 3
  pack .keymap.cancel .keymap.help -in .keymap.f3 \
	-side left -padx 4m -ipadx 6 -pady 3
  pack .keymap.f3 -side top


  # This button is used to test out bindings!
  # Dont remove it!
  button .keymap.test_button 

  bind .keymap <Escape> {destroy .keymap}
  bind .keymap <Any-Control-c> {destroy .keymap}
  bind .keymap <Return> {_keymap_edit_done}

  # Fill keymap listbox with stuff.
  _keymap_edit_update

  wm geom .keymap 750x500
  util_win_finish .keymap -place normal

  if {[catch "grab set .keymap" msg]} {
    # grab failed, windows struggling for dominance.
    puts $msg

  } else {
    cursor_wait .keymap 1 {Edit Keymap}
    catch {focus .keymap}
    tkwait window .keymap
    cursor_wait .keymap 0
  }
}

global SEQ_MOD_PP_NAMES
set SEQ_MOD_PP_NAMES() ""
set SEQ_MOD_PP_NAMES(SHIFT) Shift
set SEQ_MOD_PP_NAMES(CONTROL) Ctrl
set SEQ_MOD_PP_NAMES(ALT) Alt
# Note: Meta is not used in any max factory keymaps.
set SEQ_MOD_PP_NAMES(META) Meta
set SEQ_MOD_PP_NAMES(DOUBLE) Double

# This is a list of events that have better names.
set SEQ_TRANSLATE {{L1 Stop} {L2 Again} {L3 Props} {L4 Undo} \
	{L6 Copy} {L7 Open} {L8 Paste} {L9 Find} {L10 Cut} \
	KeyRelease-Help}


# 7/00: pat moved seq_ procs from misc.tcl to here.
# These routines are also used by the help code in mode.tcl.
proc seq_parse {seq} -desc {
    convert event sequence into: {type modifier key}
} -doc {
    type = BUT, ALPHA or SPECIAL
    modifier = Double, Shift, Control and/or Alt  (list of all that apply)
    key = key name (upper case)
    '<' and '>' stripped. 

    Will fail for <1> which is actually short-hand Button-1, but we
    dont use that in max.

    Does not handle "chords" (multiple simultaneous keys.)
} {
    global SEQ_MOD_PP_NAMES
    set type {}
    set modifier {}

    # remove brackets
    set seq [string trimleft $seq < ]
    set seq [string trimright $seq > ]

    # Get the three modifiers we treat specially.
    if { [regsub -nocase {Shift-} $seq "" seq] } {
      lappend modifier Shift
    }
    if { [regsub -nocase {Control-} $seq "" seq] } {
      lappend modifier Control
    }
    if { [regsub -nocase {Alt-} $seq "" seq] } {
      lappend modifier Alt
    }
    if { [regsub -nocase {Double-} $seq "" seq] } {
      lappend modifier Double
    }
 
    # discard "Any" modifier, to avoid clutter/confusion
    regsub -nocase {Any-} $seq "" seq

    # Do not return KeyRelease:
    # user does not need to see it anyway.
    regsub -nocase {KeyRelease-} $seq "" seq


    if {[regexp {(Button|B1|B2|B3)} $seq]} {
      # mouse button.  Many flavors, we wont try to parse it.
      set type BUT
    } elseif { [string length $seq] == 1 } {
      # alphameric key
      set type ALPHA
      
      # check case
      if {[string compare "A" $seq] != 1 && [string compare $seq "Z"] != 1} {
	if {[lsearch $modifier Alt] == -1} {
	  lappend modifier Shift
	}
      }
      set seq [string tolower $seq]
    } else {
      # special keysym, like Delete.
      set type SPECIAL
    }

    return [list $type $modifier $seq]
}


proc seq_pp {seq {long 0}} -desc {
  return pretty-print version of input event sequence
} -doc {
  Return two formats.  Default is short format, used in menus
  as accelerators (ie, comments).  Long format is used in the
  keymap code, and is used because when user enters a keysym,
  they must get it exactly right, so we will also display the
  keysyms properly.
} {
  global SEQ_MOD_PP_NAMES SEQ_TRANSLATE

  setl {type modifier key} [seq_parse $seq]

  if { $long } {
    if { $modifier == {} } {
      return $key
    } else {
      return "[join $modifier -]-$key"
    }
  } else {

    set modifier $SEQ_MOD_PP_NAMES([string toupper $modifier])

    if { $type == "BUT" } {
      # For documentation consistency, all Button, B1, etc.,
      # are returned as BUT-1, BUT-2 or BUT-3.
      # Must handle things like B1-motion (returns BUT-1-motion)
      # and ButtonPress-1 (returns BUT-1).
      regsub {Button1|B1} $key "BUT-1" key
      regsub {Button2|B2} $key "BUT-2" key
      regsub {Button3|B3} $key "BUT-3" key
      regsub {Button|ButtonPress} $key "BUT" key
    }

    if { $type == "SPECIAL" } {
      set index [lsearch2 -nocase -index 0 $SEQ_TRANSLATE $key]
      if {$index >= 0} {
	set key [lindex [lindex $SEQ_TRANSLATE $index] 1]
      }
      set key [string toupper $key]
    }

    if { $modifier == {} } {
      return $key
    } else {
      return "[join $modifier -]-$key"
    }
  }
}


global SEQ_TYPE_ORDER
set SEQ_TYPE_ORDER(BUT) 1
set SEQ_TYPE_ORDER(ALPHA) 2
set SEQ_TYPE_ORDER(ARROW) 3
set SEQ_TYPE_ORDER(SPECIAL) 4

global SEQ_MOD_ORDER
set SEQ_MOD_ORDER() 0
set SEQ_MOD_ORDER(SHIFT) 1
set SEQ_MOD_ORDER(CONTROL) 2
set SEQ_MOD_ORDER(ALT) 3
set SEQ_MOD_ORDER(META) 3
set SEQ_MOD_ORDER(DOUBLE) 4

proc seq_sort_key {seq} -desc {
  return a sort key for seq that will sort all sequences properly.
} {
  global SEQ_TYPE_ORDER SEQ_MOD_ORDER
  setl {type modifier key} [seq_parse $seq]
  # Sort arrow keys together.
  if { [regexp {Left|Right|Up|Down} $key] } {
    set type ARROW
  }
  return [format "%s %-20s %s" \
      $SEQ_TYPE_ORDER($type) $key $SEQ_MOD_ORDER([string toupper $modifier])]
}
