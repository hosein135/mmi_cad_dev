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

set RCSVERSION(prop_menu.tcl) { $Revision: 1.53 $ }

global DIALOG_FONT;  # Font for dialog boxes.
# This is the default font in the Tk config data base:
# People complained it was too hard to read, so switch to a better font:
# old font was: "-Adobe-Helvetica-Bold-R-Normal--*-120-*"
# 7-99: max users can now set DIALOG_FONT, so protect this with use_first.
set DIALOG_FONT [use_first DIALOG_FONT '*-helvetica-bold-r-normal-*-140-*]

# Notes: TCL has bug that set x($prop) fails if $prop contains a space.
# I call this a bug, because set y $x($prop), works fine.
# So, to allow spaces in prop names, whenever we use a set command
# like set x($prop) whatever, be careful to use: set "x($prop)" value
#
# It might be nice to be able to use numbers, sliders and validation
# for time entries, eg: 10ps.


proc _prop_menu_top_win {} -desc {
  Return the top level window name for either max or sue
} {
    global max_win cur_c
    if { [info exists cur_c] } {
	# Its sue!
	return $cur_c
    } elseif { [info exists max_win] } {
	# Its max!
	return $max_win
    }
    # This usually gives the correct result, even for max and sue,
    # but I didnt use it for max/sue because: the above is sure-fire,
    # and will work even if max has multiple windows.
    set winname [lindex [winfo children .] 0]
    return [expr {$winname == "" ? "." : $winname }]
}

proc _prop_nested_call {w title cmd {pn -1}} -desc {
  Used by prop_menu to invoke another toplevel window from an existing prop_menu
} {
    global _PROP_RETURN
    uplevel #0 $cmd

    # Dont think this is needed any more either:
    set _PROP_RETURN "continue" ;# Tells current prop_menu its not done yet.

    # This raise fails in the unlikely case that some one used the
    # X menu "Quit" command to kill the parent prop menu.
    catch {raise .prop_menu$w}

    # No longer used:
    #if { $pn >= 0 } {
    #  _prop_invoke $w $pn
    #}
}


proc _prop_invoke {w pn} -desc {
  bound to widgets in prop_menu to perform TRIGGER events.
} {
  global _PROP_RETURN

  # This "if" statement is probably not necessary.
  # Could just invoke prop number $pn; nothing should happen
  # if it doesnt have one of these options.
  if {[_prop_getopt $w $pn -command] != ""  || \
    [_prop_getopt $w $pn -return] != "" || \
    [_prop_getopt $w $pn -reload 1]} {
    set _PROP_RETURN [list invoke $pn]
  }
}

proc _prop_bind {w pn entry type} -desc {
  Used by prop_menu to add bindings to a prop menu item
} {
    global _PROP_SAVE

    # Get rid of the stupid binding on Return for some types
    # of widgets.  Otherwise, for example, if a checkbutton has
    # the focus when you hit Return, the checkbutton will get
    # toggled immediately before the menu default action is invoked.
    # To fix, execute tags for .prop_menu before doing widget specific tags. 
    regexp {^\.[^.]*} $entry prop_menu
    bindtags $entry [concat $prop_menu [bindtags $entry]]

    if {$type == "entry" } {
	# The default for double click is words, but Tk thinks a period
	# ends a word, so if the entry contains a real number, the
	# default behavior is to select only part of the number, which sucks.
	# So we will fix it with this bind.
	bind $entry <Double-1> "catch {$entry selection range 0 1000};break"
	# Andrew et. al. want the current selection to be completely
	# highlighted when they traverse with Tab-key, so that they
	# can just type and replace the selection without having to
	# backspace first.  The bind on FocusOut is needed because,
	# unfortunately, this sometimes leaves the selection displayed
	# even when you move to the next item, if it is not another entry.
	bind $entry <KeyRelease-Tab>  "catch {$entry selection range 0 1000}"
	bind $entry <FocusOut>  "catch {$entry selection clear}"
    }
    # Remember firstwidget for use in parent.
    upvar firstwidget firstwidget
    if {$firstwidget == ""} { set firstwidget $entry }

    # 2-99: If the user clicks a widget with the mouse,
    # set the focus to the entry or button associated with the widget.
    # Normally there is just one widget per frame.
    # EXCEPT: for radio buttons, each radio button must select itself;
    # anything else in the frame should select the first radio button.
    # We use a bind of ButtonRelease because it doesnt upset any other bindings.
    set cmd "catch {focus $entry}"

    if { $type == "radio" && \
	      [info exists _PROP_SAVE(bind_prev_pn)] && \
	      $_PROP_SAVE(bind_prev_pn) == $pn } {
	bind $entry <ButtonRelease-1> $cmd
    } else {
	# Bind all widgets in the frame together.
	# Note: winfo children goes only one level deep, so this
	# for loop is cleverly recursive.
	upvar frame frame
	set wlist(0) [winfo children $frame]
	for {set i 0} {[llength $wlist($i)]} {incr i} {
	    set wlist([expr $i+1]) ""
	    foreach w $wlist($i) {
		bind $w <ButtonRelease-1> $cmd
		append wlist([expr $i+1]) [winfo children $w]
	    }
	}
    }
    set _PROP_SAVE(bind_prev_pn) $pn

    return
}

proc _prop_fillpopup {win w nprop items procname n repost} -desc {
  Used by prop_menu to fill popup menu
} {
    global DIALOG_FONT
    set cnt 0
    $win.menu.s delete 0 end
    if { $n > 0 } {
	$win.menu.s add command -font $DIALOG_FONT -label "<<<" \
	    -command "_prop_fillpopup $win $w $nprop {$items} {$procname} [expr $n - 30] repost" 
      incr cnt
    }
    for {set i $n} {$i < [llength $items] && $cnt < 89} {incr i; incr cnt} {
	set choice [lindex $items $i]
	$win.menu.s add command -font $DIALOG_FONT -label $choice \
	    -command "$procname $win.button $w $nprop {$items} {$choice}" \
	    -columnbreak [expr $cnt % 30 == 0]
    }

    if { $i < [llength $items] } {
	$win.menu.s add command -font $DIALOG_FONT -label ">>>" \
	    -command "_prop_fillpopup $win $w $nprop {$items} {$procname} [expr $n + 30] repost" 
    }
    if { $repost == "repost" } {
	$win.menu.s post [winfo x $win.menu.s] [winfo y $win.menu.s]
    }
}

proc _prop_addpopup {win w nprop items procname} -desc {
  Used by prop_menu to add a small popup menu on the right of an entry in frame $w
} {
    global DIALOG_FONT
    menubutton $win.menu -text "" \
	-relief flat -bd 0 -pady 0 -indicator on -takefocus 0 \
	-menu $win.menu.s
    pack $win.menu -side right
    # The menu sometimes comes out underneath the dialog box,
    # so try to fix it with a raise command.
    menu $win.menu.s -tearoff false -postcommand "raise $win.menu.s"
    _prop_fillpopup $win $w $nprop $items $procname 0 0
    return $win.menu.s
}

proc _prop_filename {w pn fsbox_args} -desc {
  used by prop_menu to call fs_box
  internal to prop_menu
} {
  global _PROP_INFO
  # Curly brackes around filename in case it contains special chars.
  set result [eval fs_box $fsbox_args -filename {$_PROP_INFO($w,$pn,value)}]
  if { $result != "" } {
    set _PROP_INFO($w,$pn,value) $result
  }
  _prop_invoke $w $pn
}


proc _prop_menu_destroy {win} -desc {
  destroy the window, remember user positioning internal to prop_menu
} -doc {
  Win is window name.
  Original window location was saved in _PROP_SAVE(last_pos,$win)
  If user moved the window, save the location to which they moved it
  in _PROP_SAVE(pos,$title), so the window with same title
  can be created in the same location next time.

  Must restore the focus before destroying the window, or the
  window manager may take the focus away from this application.
} {
  global _PROP_SAVE
  set old_pos ""
  catch { set old_pos $_PROP_SAVE(last_pos,$win) }
  set new_pos ""

  # Restore the focus before deleting the window, since otherwise
  # the window manager may take the focus away so we can't redirect it.
  # Do NOT use focus -force.  If you do, and the window manager
  # is using "focus follows mouse mode", then the focus gets
  # orphaned after the prop_menu is destroyed if the mouse is
  # over another window - the user will have to move the mouse
  # out of, and then back into, a window to get a focus back.

  catch {focus $_PROP_SAVE(oldFocus,$win)}

  if {[winfo exists $win]} {

    catch { set new_pos "[winfo rootx $win] [winfo rooty $win]" }
    set title $_PROP_SAVE(title,$win)

    # If the user moved the menu, remember where they put it.
    if { $title != "" && $new_pos != "" && $old_pos != "" && $new_pos != $old_pos } {
      set _PROP_SAVE(pos,$title) $new_pos
    }
    # This is a proper clean-up, so we dont want to execute
    # whatever Destroy is bound to.  That binding is in case
    # the window is killed accidently!
    catch { bind $win <Destroy> "" }
    catch { destroy $win }
  }
}


# Look for option name, eg: -foo.
# If binary, return 1/0 if option exists/missing.
# If binary == 0, look for something like: -foo value
# and return the value, or ""
proc _prop_getopt {w prop_num name {binary 0}} {
  global _PROP_INFO
  set options $_PROP_INFO($w,$prop_num,options)
  if { $binary } {
    return [expr [lsearch -exact $options $name] >= 0]
  }
  if {[set n [lsearch -exact $options $name]] < 0} return ""
  return [lindex $options [incr n]]
}

proc _prop_update {w which} -desc {
  Update menu vars to caller.
} -doc {
  internal to prop_menu.
  "which" argument is "get" to get variables from caller,
  "value" to update menu values to caller,
  or "origvalue" to retstore original values to caller.
} {
  global _PROP_INFO
  set level $_PROP_INFO($w,level)
  for {set pn 0} {$pn < $_PROP_INFO($w,propcnt)} {incr pn} {
    if {$_PROP_INFO($w,$pn,varname) != "" } {
      upvar "#$level" $_PROP_INFO($w,$pn,varname) ptr
      if { $which == "get" } {
	set _PROP_INFO($w,$pn,value) $ptr
      } else {
	# Only update values of visible properties, in case there
	# are multiple references to the same variable in
	# visible and non-visible properties.  But if which == origvalue,
	# user hit cancel, so reset all.
	if { $which == "origvalue" || $_PROP_INFO($w,$pn,visible) } {
	  set ptr $_PROP_INFO($w,$pn,$which)
	}
      }
    }
  }
}

proc _prop_menu_grab {win} -desc {
  Try to get the grab.  Return 1 if success, 0 if failure.
} {

  # We will try for a total of 4 seconds.
  for {set retry 0} {$retry < 10} {incr retry} {
    if {! [catch "grab set $win" msg]} {
      return 1
    }
    if { $retry == 0 } { puts "window grab failed, trying again, please wait..." }
    # Very rarely this fails, possibly windows struggling for dominance.
    after 400 ;# Wait awhile, try again.
  }
  # Give up.  This will close down the window and return.
  puts "grab failed: $msg"
  return 0
}

# NEW OPTIONS, NOT IN DOC YET:
# -options {stuff} : only for -button now; add stuff to the widget options.
# -align center: center the widget, instead of putting on right.
# 

proc prop_menu2 {args} -desc {
  Displays a menu dialog box and returns user entries.
} -doc {

USAGE: prop_menu2 [-options ...] prop_list

RETURNS: Return 1 on success, 0 if canceled.

Options are:
  -title title -message message
  -x x -y y
  -atmouse n
  -apply applyproc
  -buttons button_list

  This function is similar to prop_menu, which it replaces.
  The prop_menu function is now just a thin wrapper for this function.

  The title and message are the window title and the first line
  in the window, respectively.  If only one is given it will
  be used in both locations.

  If -x and -y are specified, they are the menu position.
  If -atmouse n is specified, menu position is n pixels right and down
  from mouse position.  If neither -x -y or -atmouse is specified,
  then menu position is initially in middle of screen;
  if user moves the menu, then next time the menu with same
  title appears, it will be at the same position.

  The applyproc is the name of a procedure to call to perform
  the "apply" function.  If -apply is specified, an "Apply"
  button will appear in the menu.  If the Cancel button is pushed
  after the Apply button, prop_menu2 restores the original values
  of all variables and then calls the apply function again to attempt
  to undo the results of the previous apply function.

  If -buttons <button_list>, the menu will use the specified list of buttons,
  where each button is of the form "name=value[=options]";
  name is the button name; value is the return value;
  the options may be: default to signify the default button,
  or apply to signify the Apply button.
  For historical reasons, if the return value is 0, it is a cancel button.
  The button with an apply option is ignored if no -apply option
  was specified.
  If buttons is not specified, it defaults to:
    -buttons "Done=1=default Apply==apply Cancel=0=cancel"
  If the value is 0, it is a cancel button, which returns immediately
  (after undoing any previous "apply" functions).
  Otherwise, the button acts like a "done" button, which performs
  all validation checks before returning.

  The prop_list argument is a list of lists, where each leaf list
  describes one property, and consists of a property name, an optional
  variable name that contains the value of the property name,
  followed by optional property options.  The variable need not
  be a global variable.  The variable name must be specified
  if property options are specified.

  The return value is 0 if user pressed Cancel, 1 if user pressed Done,
  or the value from -return option, below.
  
  Example:

  set value1 "whatever"
  set value2 "val1"
  set prop_list [list [list "This is a Prop List" "" -label] \
      [list "A property" value1 -entry] \
      [list "Another property" value2 -radio {val1 val2 val3}]]
  if {[prop_menu2 -title "My properties" $prop_list] == 0} {
    return ;# User pressed cancel button.
  }

  Restrictions:
      No prop name may contain a dollar sign.

  The first option may be a property type, which may be
  selected from the following list:
	-entry			Default - a simple entry box.
	-filename {args}	A filename entry with a "Find..." button;
				args are to the fs_box function.
	-popup {a b c}		An entry with a popup menu for default choices.
	-binary			A single radio button. Value must be 0/1
	-radio {a b c}		Multiple choice using Radio buttons.
				see -values, below.
	-choice {a b c}		Multiple choice using a button and popup menu.
				Like a popup, but the entry cant be edited.
	-enum {a b c}           Like choice, but value is 0/1/2, not a/b/c.
	-label			The value, if any, is not editable.
				If the value is empty, the prop name
				is a full column width label.
	-number [min [max]]	A number entry with a tiny scrollbar beside it.
	-scale min max		A number entry with a scale slider below it.
	-button cmd  		A button that calls cmd as when pushed;
	 			the variable should be an empty string.
	-help {string}          Add "string" to the help menu.
  First option may also be: -hide, -separator, -break, -help.

  The "TRIGGER" property types are: -popup, -choice, -enum, -binary,
  -radio.  The -filename is also a TRIGGER, but only if the
  name is changed with the File box (by pushing the "Find..." button),
  not if the user just types it in.  The TRIGGER property types
  can trigger a -reload, -command or -return option.

  If no property type is specified, the default is "entry".
  The following additional -options may appear after the property type.
	-incr n Increment (eg: .2) for -number or -scale.
		Puts up/down arrows next to number that increment by
		this amount.  If -validate is given, then the entered
		number must be divisible by this amount.
	-snap n Snap value for -number (but not -scale).
		Over-rides -incr for the up/down arrows only, but not
		for validation.  This lets you specify a larger value
		to snap to than incr.  The number snaps to the nearest
		multiple of -snap when the arrow buttons next to the
		number are pushed.
	-help {message}	 Add "$propname: $message" to the help.
	-width n  Minimum width for any entry in chars.
		Works on entry, popup, number, scale.  Default is
		length of prop value, but since all props are in the
		same frame, they all default to the min width of
		the largest prop value.
	-break [n]	Next item starts a new column,
		optional column separation of  n pixels.
	-separator  Separator line drawn after item.
	-validate [procname]  If -validate is not given, then
		-number and -scale properties are validated only to be
		numbers.  If -validate is given without a procname,
		then -number or -scale numbers entered by the user must
		match the specified min/max/increment.  If -validate is
		given with a procname, the named proc is called as:
		    procname <new_value> <prop_name>
		If the new value is valid, procname should return "".
		Otherwise, procname should return an error message,
		which is displayed.  The -validate option with a procname
		can appear on any property, not just numbers.
		The prop_menu will not return until all properties
		pass validation.
	-values {...}  The values to be used for the names specified in -radio.
	-hide  The property is not displayed.  Useful for development.
		Equivalent to -when 0
	-when {expr}   The property is only displayed when expr is true.
		To implement morphing menus, the expr would contain
		a reference to a variable in this menu with a -reload
		option.  If the user hits the "Cancel" button,
		all changes to all variables are canceled,
		regardless of the current visibility.
	-reload Reload the menu after a change to this property.
		Typically used with -when to create morphing menus.
	-return value
		Return value immediately when the value is changed.
		Only works with TRIGGER property types.
		This can be used to implement morphing menus that are
		too complicated for -when clauses.  The caller checks
		the prop_menu2 return value for this -return value and
		immediately reinvokes prop_menu2 to reflect changes.
		Note, however, that the "Cancel" button only cancels
		out changes to the most recent prop_menu2 invocation.
	-command command
		Execute command in global context (not the context of
		the caller) after the prop menu item is changed.
		Only available with TRIGGER type property types.
} {

  global _PROP_RETURN;   # Return value for tkwait
  global _PROP_SAVE;     # Persistent storage for prop_menu2
  global _PROP_INFO;     # Array of prop names and values:
  global DIALOG_FONT;    # Font used for labels in dialog box
  set font $DIALOG_FONT; # Just a shorter name for the font

  # Generate a unique prop_menu name
  for {set w 1} {1} {incr w} {
      set prop_menu .prop_menu$w
      if {![winfo exists $prop_menu]} break
  }

  # winname is the name of the parent window
  set winname [_prop_menu_top_win]

  set argc [llength $args]
  if { $argc == 0 } { error "no arguments to prop_menu2" }
  set keywords "{message {}} {title {}} {x {}} {y {}} \
	{atmouse {}} {apply {}} {buttons {}}"
  call_by_keyword [lrange $args 0 [expr $argc-2]] $keywords
  set prop_list [lindex $args end]
  if { $message == "" } { set message $title }
  if { $title == "" } { set title $message }

  if { $atmouse != "" } {
      set x [expr [winfo pointerx $winname] + $atmouse]
      set y [expr [winfo pointery $winname] + $atmouse]
  } elseif { $x == "" || $y == "" } {
    # If user moved window previously, restore window in same location.
    if { $title != "" && [info exists _PROP_SAVE(pos,$title)] } {
      # This doesnt quite work; the window walks across the screen each time
      # it is repositioned.  Looks to me like winfo rootx/rooty is off
      # by the frame width, ie, documentation is wrong or there is a bug in it.
      setl {x y} $_PROP_SAVE(pos,$title)
    } else {
      if { $winname != "" } {
	  # This update is needed when running a program with mmi_wish.
	  # It is possible to attempt to post a prop_menu before the wish window
	  # has been posted, in which case the prop_menu will appear at the upper
	  # right corner of the screen instead of over the wish window.
	  # Then, if the prop_menu has a -return and is reposted, it will move
	  # its location over to the wish window, which is disconcerting for the user.
	  # Since we are going to do an update later anyway, its ok to just do one now, too.
	  update idletasks
	  set y [expr [winfo rooty $winname] + 50]
	  set x [expr [winfo rootx $winname] + 50]
      } else {
	  # Make something up.
	  set y 100
	  set x 100
      }
    }
  }

  # I used to use the same prop_menu name over if it was not in use,
  # but if you double-click on the popup on a -choice with a -return,
  # the popup stops popping up, and continues to fail even if you
  # destroy everything.  But if you pick a new menu name, it starts
  # working again.  Tk is clearly keeping some persistent data
  # somewhere keyed on the window name.
  # So just use a new window name each time.
  #set _PROP_SAVE(menu_number) [use_first _PROP_SAVE(menu_number) '1]
  #set prop_menu .prop_menu[incr _PROP_SAVE(menu_number)]

  # Save arguments, variable names and values in _PROP_INFO array.
  # Generate a unique w index for the _PROP_INFO used in each menu,
  # because if there is a nested prop_menu call, all _PROP_INFO elements
  # must be unique, because both menus will be visible simultaneously.
  set whenstrings ""
  set i 0
  foreach assoc $prop_list {
      set _PROP_INFO($w,$i,name) [lindex $assoc 0]  ;# Property name
      set varname [lindex $assoc 1]
      set _PROP_INFO($w,$i,varname) $varname
      set _PROP_INFO($w,$i,options) [lrange $assoc 2 end]  ;# Everything else
      if { $varname != "" } {
	upvar $varname ptr
	if {[catch { set _PROP_INFO($w,$i,value) $ptr }]} {
	  # vvvv temporary vvvv
	  # Check for old -button syntax specially.
	  # Can remove this code when maxtcl code is fully updated.
	  if { [lindex $assoc 2] == "-button" && $varname != "" } {
	    set _PROP_INFO($w,$i,options) "-button $varname"
	    set _PROP_INFO($w,$i,varname) ""
	    set _PROP_INFO($w,$i,value) ""
	    incr i
	    continue
	  }
	  # ^^^^ temporary ^^^^


	  error "No variable: $varname"
	  return 0  ;# Supposedly unnecessary, error should abort us.
	}
	# Save original value for use by <cancel> button.
	set _PROP_INFO($w,$i,origvalue) $_PROP_INFO($w,$i,value)
      } else {
	# Give it an empty value, to allow us to use it below
	# for code that works fine for all proptypes, without
	# getting an undeclared variable error.
	set _PROP_INFO($w,$i,value) ""
      }
      #append whenstrings " "
      #append whenstrings [_prop_getopt $w $i -when]
      incr i
  }

  # Total number of props in _PROP_INFO($w,...)
  set _PROP_INFO($w,propcnt) $i
  # This is the stack frame level where the user supplied variables live.
  set _PROP_INFO($w,level) [expr [info level] - 1]


  # Mark variables that are used in -when expressions.
  # NO: make user use -reload explicitly.
if {0} {
  for {set i 0} {$i < $_PROP_INFO($w,propcnt)} {incr i} {
    if {[string match "*\$$_PROP_INFO($w,$i,varname)*" $whenstrings]} {
      # The variable in this property is used in a -when expression.
  	append _PROP_INFO($w,$i,options) " -reload"
      }
  }
}


  # remember the old focus and grab so we can try to return to it
  set _PROP_SAVE(oldFocus,$prop_menu) [focus]
  set oldGrab [grab current $winname]

  set f_apply_called 0

  # This while loop is: do {} while {$prop_menu_repost}
  set prop_menu_repost 1
  while {$prop_menu_repost} {
    set prop_menu_repost 0
    set retval 0   ;# Default return value: failure.

    # Just in case there is an old window around
    # Note: cant be an old one, cause we generated a unique name!
    # catch "destroy $prop_menu"
    toplevel $prop_menu 

    set help "";           # Accumulated help strings
    set firstwidget "";    # Remember first widget to give it the focus


    # Sue over-rides the bindings for Tab for all windows, so we
    # have to put them back the way they were.
    # We will also map Control-n and Control-p for X win compatibility.
    bind $prop_menu <Key-Tab> {focus [tk_focusNext %W]}
    bind $prop_menu <Control-n> {focus [tk_focusNext %W]}
    bind $prop_menu <Shift-Key-Tab> {focus [tk_focusPrev %W]}
    bind $prop_menu <Control-p> {focus [tk_focusPrev %W]}

    # NOTE: this command gives prop_menu the focus when debugging stand-alone.
    #if {![info exists MAX_DEVELOPER]} {
    #    wm withdraw $prop_menu
    #}

    wm geometry $prop_menu "+$x+$y"
    wm minsize $prop_menu 200 100
    wm title $prop_menu $title
    bind $prop_menu <Any-Control-c> \
	  "_prop_menu_destroy $prop_menu; set _PROP_RETURN cancel; break"

    # Find max prop name width for each panel, so all prop values can be aligned.
    # Add 1 to leave a space between prop name and value.
    # We will ignore -hide here, for no particular reason.
    set paneln 1
    set panel_namewidth($paneln) 1
    for {set pn 0} {$pn < $_PROP_INFO($w,propcnt)} {incr pn} {
      set propname $_PROP_INFO($w,$pn,name)
      set proptype [lindex $_PROP_INFO($w,$pn,options) 0]
      # The average font width in Tk is taken from the width of letter zero "0".
      set avg_font_width [font measure $font "0"]
      # If the proptype is anything BUT a label or button,
      # then its width affects the prop name column widths.
      switch -- "$proptype" {
	"button" -
	"-button" {
	  # Buttons are full width.
	}
	"label" -
	"-label" {
	  # Labels are full width if the variable is empty.
	  if { $_PROP_INFO($w,$pn,varname) != "" } {
	    set strwidth [font measure $font $propname]
	    set panel_namewidth($paneln) \
	      [max $panel_namewidth($paneln) [expr 1+round($strwidth/$avg_font_width)]]
	  }
	}
	default {
	  set strwidth [font measure $font $propname]
	  set panel_namewidth($paneln) \
	    [max $panel_namewidth($paneln) [expr 1+round($strwidth/$avg_font_width)]]
	}
      }
      if {[_prop_getopt $w $pn -break 1]} {
	# Look in next panel.
	incr paneln
	set panel_namewidth($paneln) 1
      }
    }

    # Multiple dialog panels are allowed, separated by "-break" option.
    set panelnumber 1
    set panel_sep 80  ;# Default separation between panels in pixels.
    set panel $prop_menu.data$panelnumber
    frame $panel

    # Main loop.  Foreach property
    set framenumber 0
    set namewidth $panel_namewidth($panelnumber)
    for {set pn 0} {$pn < $_PROP_INFO($w,propcnt)} {incr pn} {
	set proptype [lindex $_PROP_INFO($w,$pn,options) 0];# Property type, eg -enum
	set proptext $_PROP_INFO($w,$pn,name)
	set options [lrange $_PROP_INFO($w,$pn,options) 1 end]
	# Most proptypes have only one argument, so just break it out now.
	set arg1 [lindex $options 0]

	set when [_prop_getopt $w $pn -when]
	if {($when != "" && ![uplevel 1 "expr { $when }"]) || \
	    [_prop_getopt $w $pn -hide 1]} {
	  set _PROP_INFO($w,$pn,visible) 0;  # not visible.
	  continue
	}
	set _PROP_INFO($w,$pn,visible) 1;  # Visible.

	# Create frame to contain a single dialog element, whatever it is.
	set frame $panel.f[incr framenumber]
	frame $frame

	# If no proptype, use default -entry.
	if {$proptype == ""} { set proptype "-entry" }

	# Some simple binary types are implemented with enum
	switch -- $proptype {
	  "-boolean"  { set proptype "-enum"; set arg1 "0 1" }
	  "onoff"     { set proptype "-enum"; set arg1 "Off On" }
	  "truefalse" { set proptype "-enum"; set arg1 "False True" }
	  "yesno"     { set proptype "-enum"; set arg1 "No Yes" }
	  "-help" -
	  "-separator" -
	  "-break" {
		# This case occurs if no proptype was specified,
		# but one of these options was.
		# Dont add a menu entry for this.
		set proptype "-hide"
		set options $_PROP_INFO($w,$pn,options)
	  }
	}

	# Determine the width of this entry, if any.
	if {[info exists _PROP_INFO($w,$pn,value)]} {
	  set entrywidth [min 100 [string length $_PROP_INFO($w,$pn,value)]]
	  if {[set minwidth [_prop_getopt $w $pn "-width"]] != ""} {
	    set entrywidth [max $entrywidth $minwidth]
	  } else {
	    set entrywidth [max $entrywidth 12]
	  }
	}

	switch -- $proptype {
	"-hide" {
	    # Do nothing
	}
	"-button" -
	"button" {
	    # The propval was actually a command, not a proptype
	    # Note: no -width $namewidth, so it is full width.
	    # For -button, the varname is actually the command to exec.
	    #button $frame.button -font $font -text $proptext \
	    #	-padx 1 -pady 1 -anchor w \
	    #      -command "_prop_nested_call $w {$title} {$arg1} $pn"
	    #set but_opts [_prop_getopt $w $pn -options]
	    #bind $frame.button <Return> "_prop_nested_call $w {$title} \
	    #	    {$arg1} $pn"

	    button $frame.button -font $font -text $proptext \
		  -padx 1 -pady 1 -anchor w \
		  -command "set _PROP_RETURN {invoke $pn}"
	    set but_opts [_prop_getopt $w $pn -options]
	    bind $frame.button <Return> "set _PROP_RETURN {invoke $pn}"
	    eval pack $frame.button -side left -ipady 1 -fill x -expand 1 $but_opts
	}
	"-entry" -
	"entry" {
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor w
	    pack $frame.label -side left -ipady 1
	    set entry $frame.entry
	    entry $frame.entry \
		  -width $entrywidth -font $font \
		  -textvariable _PROP_INFO($w,$pn,value) -relief sunken -bd 1 \
		  -highlightthickness 1
	    pack $frame.entry -side left -fill x -ipady 1 -expand 1
	    _prop_bind $w $pn $frame.entry "entry"
	}
	"-filename" {
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor w
	    pack $frame.label -side left -ipady 1
	    set entry $frame.entry
	    # filenames are pretty big. give it some more width
	    entry $frame.entry \
		  -width [max $entrywidth 20] -font $font \
		  -textvariable _PROP_INFO($w,$pn,value) -relief sunken -bd 1 \
		  -highlightthickness 1
	    pack $frame.entry -side left -fill x -ipady 1 -expand 1
	    button $frame.button -bd 1 -relief raised \
		  -highlightthickness 1 -padx 1 -pady 1 \
		  -text "Find..." -font $font \
		  -command "_prop_filename $w $pn {$arg1}"
	    pack $frame.button -side right -padx 2 -pady 2
	    _prop_bind $w $pn $frame.entry "entry"
	}
	"-popup" -
	"popup" {
	    proc _prop_entryproc {win w nprop propargs new} {
		global _PROP_INFO
		set "_PROP_INFO($w,$nprop,value)" $new
		_prop_invoke $w $nprop
	    }
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor w
	    pack $frame.label -side left -ipady 1
	    set maxwidth $entrywidth
	    foreach choice $arg1 {
	      set maxwidth [max [string length "$choice"] $maxwidth]
	    }
	    frame $frame.f -bd 2 -relief sunken
	    set entry $frame.f.entry
	    entry $entry -width $maxwidth -font $font \
		  -textvariable _PROP_INFO($w,$pn,value) -relief flat -bd 0 -highlightthickness 0
	    pack $entry -side left -fill x -expand 1
	    _prop_addpopup $frame.f $w $pn $arg1 _prop_entryproc
	    pack $frame.f -side left -fill x -expand 1
	    pack $entry -side left -fill x -ipady 1 -expand 1
	    _prop_bind $w $pn $entry "entry"
	}
	"-binary" -
	"binary" {
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor w
	    pack $frame.label -side left -ipady 1
	    checkbutton $frame.button -variable _PROP_INFO($w,$pn,value) \
	      -anchor w -command "_prop_invoke $w $pn"
	    pack $frame.button -side left -fill x -expand 1
	    _prop_bind $w $pn $frame.button "button"
	}
	"-choice" -
	"choice" {
	    # Set choice to new; else if new is "", increment choice to next value
	    proc _prop_choiceproc {win w nprop propargs new} {
		global _PROP_INFO
		if {$new == ""} {
		    # Set n = Current index, 0..length-1
		    set n [lsearch -exact $propargs $_PROP_INFO($w,$nprop,value)];
		    # Increment n to next index
		    set n [expr {($n+1) % [llength $propargs]}]
		    set new [lindex $propargs $n]
		}
		set "_PROP_INFO($w,$nprop,value)" $new
		$win config -text $new
		_prop_invoke $w $nprop
	    }
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor w
	    pack $frame.label -side left -ipady 1

	    # Determine the maxwidth, and set button width to this.
	    # If you do not do this, then the entire menu may be too narrow,
	    # and will expand and contract as you cycle between the selections.
	    set maxwidth 1
	    foreach choice $arg1 {
		set maxwidth [max [string length $choice] $maxwidth]
	    }

	    frame $frame.f -bd 2 -relief raised
	    button $frame.f.button -bd 0 -pady 0 -relief flat \
		-text $_PROP_INFO($w,$pn,value) \
		-font $font \
		-width $maxwidth \
		-anchor w \
		-command "_prop_choiceproc $frame.f.button $w $pn {$arg1} {}"
	    pack $frame.f.button -side left -fill x -expand 1

	    _prop_addpopup $frame.f $w $pn $arg1 _prop_choiceproc
	    pack $frame.f -side left -fill x -expand 1
	    _prop_bind $w $pn $frame.f.button "button"
	}
	"-enum" -
	"enum" {  # Like a -choice, but prop value is an integer index
	  proc _prop_enumproc {win w nprop propargs new} {
	      global _PROP_INFO
	      if {$new == ""} {
		  # Set n = Current index, 0..length-1
		  set n $_PROP_INFO($w,$nprop,value)
		  # Increment n to next index
		  set n [expr {($n+1) % [llength $propargs]}]
		  set new [lindex $propargs $n]
	      }
	      set n [lsearch -exact $propargs $new]
	      set "_PROP_INFO($w,$nprop,value)" $n
	      $win config -text $new
	      _prop_invoke $w $nprop
	  }
	  label $frame.label -font $font -text $proptext -width $namewidth -anchor w
	  pack $frame.label -side left -ipady 1
	  if {0} {
	    # This version just has a normal button
	    button $frame.button -pady 1 \
		-text [lindex $arg1 $_PROP_INFO($w,$pn,value)] \
		-anchor w \
		-command "_prop_enumproc $frame.button $w $pn \"$arg1\" {}"
	    pack $frame.button -side left -fill x
	  } else {
	    # This version has a button and a popup menu
	    frame $frame.f -relief raised -bd 2
	    set maxwidth 1
	    foreach choice $arg1 {
		set maxwidth [max [string length $choice] $maxwidth]
	    }
	    button $frame.f.button -relief flat -bd 0 -pady 0 \
		-font $font \
		-text [lindex $arg1 $_PROP_INFO($w,$pn,value)] \
		-width $maxwidth \
		-anchor w \
		-command "_prop_enumproc $frame.f.button $w $pn {$arg1} {}"
	    #pack $frame.button -side left -fill x
	    pack $frame.f -side left -fill x -expand 1
	    pack $frame.f.button -side left -fill x -expand 1

	    _prop_addpopup $frame.f $w $pn $arg1 _prop_enumproc
	    _prop_bind $w $pn $frame.f.button "button"
	  }
	}
	"-radio" -
	"radio" {
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor nw
	    pack $frame.label -side left -ipady 1 -fill y
	    frame $frame.f -relief sunken -bd 1
	    set values [_prop_getopt $w $pn -values]
	    # If no -values, use -radio button names for the values.
	    if { $values == "" } { set values $arg1 }
	    set ii 0
	    foreach choice $arg1 {
		# Spaces will muck up bindings, so remove them:
		#regsub -all " " $choice "_" c
		radiobutton $frame.f.c_$ii -variable "_PROP_INFO($w,$pn,value)" \
		    -font $font \
		    -text "$choice" -value [lindex $values $ii] -anchor w \
		    -command "_prop_invoke $w $pn"
		pack $frame.f.c_$ii -side top -fill x
		_prop_bind $w $pn $frame.f.c_$ii "radio"
		incr ii
	    }
	    pack $frame.f -side top -fill x
	}
	"-number" -
	"number" {
	    # In Older Tk, args is just the amount to scroll.
	    # In TK8.0, it is "scroll amt units", or something similar.
	    # What a bummer.  So we have to recognize both syntaxes.
	    proc _prop_scrollproc {w nprop options args} {
		global _PROP_INFO
		if {[llength $args] == 1} { set amt $args } \
		else { set amt [lindex $args 1] }
		set incr [_prop_getopt $w $nprop -incr]
		set snap [_prop_getopt $w $nprop -snap]
		set val $_PROP_INFO($w,$nprop,value)
		if {$snap != ""} {
		    if { $amt <= 0 } {
			set val [expr $snap * round(($val+$snap)/(0.0+$snap))]
		    } else {
			set val [expr $snap * round(($val-$snap)/(0.0+$snap))]
		    }
		} else {
		    if {$incr == ""} { set incr 1 };   # Default increment is by 1
		    set val [expr $_PROP_INFO($w,$nprop,value) + \
		      (($amt <= 0) ? $incr : -1 * ($incr)) ]
		}
		set scanned [scan $options "%f %f" min max]
		if {$scanned >= 1} {  ; # was a min specified?
		    set val [max $val $min]
		}
		if {$scanned >= 2} {  ; # was a max specified?
		    set val [min $val $max]
		}
		# If the increment is an integer, we want to keep the
		# entry as an integer too, if possible.
		# This is needed because the entry gets ".0" appended
		# when you use min or max, which are floats.
		if {! ([string match *.* $incr] || [string match *.* $snap])} {
		  regsub "\\.0" $val "" val
		}
		set "_PROP_INFO($w,$nprop,value)" $val
	    }
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor nw
	    pack $frame.label -side left -ipady 1 -fill y
	    entry $frame.entry \
		-width [max 6 $entrywidth] -font $font \
		-textvariable _PROP_INFO($w,$pn,value) -relief sunken -bd 1 \
		-highlightthickness 1
	    pack $frame.entry -side left -fill x -ipady 1 -expand 1
	    # The curly braces are necessary around prop and arg1 cause
	    # they have spaces in them.
	    scrollbar $frame.scroll \
		-command "_prop_scrollproc $w $pn {$options}" \
		-width 9 -takefocus 0
	    pack $frame.scroll -side right
	    _prop_bind $w $pn $frame.entry "entry"
	}
	"-scale" -
	"scale" {
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor nw
	    pack $frame.label -side left -ipady 1 -fill y
	    entry $frame.entry -width [max 6 $entrywidth] -font $font \
		-textvariable _PROP_INFO($w,$pn,value) -relief sunken -bd 1 \
		-highlightthickness 1
	    pack $frame.entry -side top -fill x -ipady 1 -expand 1
	    if {[scan $options "%f %f" from to] != 2} {
		error "bad \"-scale %d %d\" in prop_menu"
	    }
	    set incr [_prop_getopt $w $pn -incr]
	    if {$incr == ""} { set incr 1 };   # Default increment is by 1
	    # If you use -variable in a scale, the scale widget constrains
	    # numeric variables to be in range, but still allows user to enter
	    # non-numeric strings, like "abc".  Thats dopey.
	    # I tried to use a -command to let the scale communicate the
	    # value to the variable, but when you set the value of
	    # the scroll bar, it sometimes sends the -command to the
	    # value, pushing it back in range.  So its hard to make
	    # a scroll bar that allows out of range values to be typed
	    # in, so we just wont.
	    scale $frame.scroll -from $from -to $to -length 5c -label ""\
		    -showvalue 0 -takefocus 1 -orient horizontal \
		    -resolution $incr \
		    -variable _PROP_INFO($w,$pn,value)
	    pack $frame.scroll -side top -expand 1
	    _prop_bind $w $pn $frame.entry "entry"
	}
	"oldreal" { # Real number scale.
	    proc _prop_realproc {w nprop to from val} {
		global _PROP_INFO
		# val goes from 0 to 100, change to range $to to $from
		set factor [expr ($to - $from) / 100.0 ]
		set _PROP_INFO($w,$nprop,value) [expr $from + (1.0 * $val * $factor)]
	    }
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor nw
	    pack $frame.label -side left -ipady 1 -fill y
	    set width [max 6 [min 100 [string length $_PROP_INFO($w,$pn,value)]]]
	    entry $frame.entry -width $width -font $font \
		-textvariable _PROP_INFO($w,$pn,value) -relief sunken -bd 1 \
		-highlightthickness 1
	    _prop_bind $w $pn $frame.entry "entry"
	    pack $frame.entry -side top -fill x -ipady 1 -expand 1
	    if {[scan $options "%f %f" from to] != 2} {
		error "bad \"real %d %d\" in prop_menu"
	    }
	    scale $frame.scroll -from 0 -to 100 -length 5c -label ""\
		    -showvalue 0 -takefocus 0 -orient horizontal \
		    -command "_prop_realproc $w $pn $to $from"
	    # Set initial value.
	    $frame.scroll set [expr 100.0 * ($_PROP_INFO($w,$pn,value) - $from)*($to - $from)]
	    pack $frame.scroll -side top -expand 1
	}
	"oldscale" { # Integral number scale.
	    label $frame.label -font $font -text $proptext -width $namewidth -anchor nw
	    pack $frame.label -side left -ipady 1 -fill y
	    entry $frame.entry -width $width -font $font \
		-textvariable _PROP_INFO($w,$pn,value) -relief sunken -bd 1 \
		-highlightthickness 1
	    pack $frame.entry -side top -fill x -ipady 1 -expand 1
	    if {[scan $options "%d %d" from to] != 2} {
		error "bad \"scale %d %d\" in prop_menu"
	    }
	    # Set an arbitrary length, it gets expanded to fit
	    scale $frame.scale -from $from -to $to -length 5c -label "" \
		    -showvalue 0 -takefocus 0 -orient horizontal \
		    -variable "_PROP_INFO($w,$pn,value)"
	    pack $frame.scale -side right -fill x
	}
	"-label" -
	"label" {
	    # The propname was actually a label, not a proptype
	    # If there is a prop value given, treat it like a non-editable entry.
	    # If the prop value is empty, the label can span the entire
	    # width of the prop-menu.
	    # NOTE: The -bd 3 is necessary to make the label the same height as a
	    # -choice or -entry proptype, so that multi-column prop_menus are
	    # aligned properly left to right.
	    if { $_PROP_INFO($w,$pn,varname) != "" } {
	      label $frame.label -font $font -text $proptext -width $namewidth -anchor w -bd 3
	      pack $frame.label -side left -ipady 1
	      label $frame.label2  \
		  -width $entrywidth -font $font -anchor w \
		  -textvariable _PROP_INFO($w,$pn,value)
		  # -relief sunken -bd 1 -highlightthickness 1 -anchor w
	      pack $frame.label2 -side left -fill x -ipadx 2 -ipady 1 -expand 1
	    } else {
	      label $frame.label -font $font -text $proptext -bd 3
	      pack $frame.label -side left -fill x
	    }
	}
	default {
	    error "Unrecognized prop_menu type: $proptype"
	}
	}; #switch

	# Check for -help option
	if {[set tmp [_prop_getopt $w $pn -help]] != ""} {
	  if { $proptext != "" } {
	      append help "[string trim [string trim $proptext :]]: $tmp\n"
	  } else {
	      #-help on an empty prop is just copied verbatim.
	      append help "$tmp\n"
	  }
	}

	# Stick the completed frame for this property in the current panel.
	if { [_prop_getopt $w $pn -beside 1] } {
	  set parent_frame $panel.f[expr $framenumber - 1]
	} else {
	  set parent_frame $panel
	}
	switch [_prop_getopt $w $pn -align] {
	"right" { set fill_option "-anchor e" }
	"center" { set fill_option "" }
	default { set fill_option "-fill x -anchor w" }
	}
	eval pack $frame -side top -in $parent_frame -expand 1 -pady 1 $fill_option

	# Check for -separator option
	if {[_prop_getopt $w $pn -separator 1]} {
	    # The canvas does not automatically expand to fill the space.
	    set frame $panel.f[incr framenumber]
	    frame $frame
	    canvas $frame.canvas -width 4c -height .4c
	    pack $frame.canvas -side top -expand 1
	    $frame.canvas create line 0c .2c  100c 0.2c
	    pack $frame -side top -in $panel -expand 1 -fill x -pady 1
	}

	# Check for -break option
	if {[_prop_getopt $w $pn -break 1]} {
	    # See if there is an argument.
	    set tmp [_prop_getopt $w $pn -break]
	    if {[regexp {^[0-9]+$} $tmp]} {set panel_sep $tmp}
	    # Create a new panel to stuff widgets in
	    set panel $prop_menu.data[incr panelnumber]
	    frame $panel
	    set namewidth $panel_namewidth($panelnumber)
	}
    }; #for pn

    frame $prop_menu.buttons
    # This is a frame for the default button, which may or may not be used.
    # This frame must be created before the button, for unknown reasons.
    #frame $prop_menu.default -relief sunken -bd 1

    # Default buttons:
    if { $buttons == "" } {
      set buttons "Done=1=default Apply==apply Cancel=0"
    }
    set default_button_widget ""

    # Create the button(s)
    set butnum 0
    foreach thing $buttons {
      incr butnum
      set button_info [split $thing =]
      set but [lindex $button_info 0]
      set v [lindex $button_info 1]
      set but_action [lindex $button_info 2]
      # If button action is prepeneded with "default" it is the default button.
      # The syntax is gross, bleah, but it evolved over time.
      if {[lindex $but_action 0] == "default"} {
	set default_state "active"
	# Strip off the "default" option, leave others in but_action.
	set but_action [lrange $but_action 1 end]
	set default_button_widget $prop_menu.but$butnum
      } else {
	set default_state "normal"
      }

      if {$v == 0 || $but_action == "cancel"} {
	# cancel button always tries to destroy menu so can't be orphaned
	set but_cmd "_prop_menu_destroy $prop_menu; set _PROP_RETURN cancel"
      } elseif {$but_action == "apply"} {
	if { $apply == "" } {
	  # There is no -apply proc, so ignore the apply button.
	  continue
	}
	set but_cmd "set _PROP_RETURN apply"
      } elseif { $but_action == "" } {
	# Its a "done" button of some sort.
	set but_cmd "set _PROP_RETURN {done $v}"
      } else {
	# but_action is the command to execute.
	set but_cmd $but_action
      }

      # The button will end the prop_menu, and returns which button was pushed.
      button $prop_menu.but$butnum -text $but -font $font -padx 1m -pady 1m \
	    -command $but_cmd -default $default_state
      bind $prop_menu.but$butnum <Return> "$but_cmd;break"

      pack $prop_menu.but$butnum -side left -in $prop_menu.buttons \
	    -padx 4m -pady 1m -expand 1

      if { $default_state == "active" } {
	# Hitting return almost anywhere will activate this button.
	bind $prop_menu <Return> "$but_cmd;break"
      }
    }


    # Add help button if we found any help
    # Increase the dialog box width with the option command, which
    # is retrieved by tk_dialog.
    if {[string length $help] > 2} {
	button $prop_menu.help -text "Help" -font $font -padx 1m -pady 1m \
	      -command "_prop_nested_call $w {$title} \
	      {prop_dialog -title {Help for: $message} {$help}}"
	bind $prop_menu.help <Return> "_prop_nested_call $w {$title} \
	      {prop_dialog -title {Help for: $message} {$help}}"
	pack $prop_menu.help -side left -in $prop_menu.buttons \
	      -padx 4m -pady 1m -expand 1
    }


    # Global bindings for Return, Control-C, Escape.
    # Exceptions are for Done and Cancel buttons, which must break
    # to prevent processing the global bind of $prop_menu
    bind $prop_menu <Escape> {set _PROP_RETURN cancel;}
    bind $prop_menu <Any-Control-c> {set _PROP_RETURN cancel}

    # If the user uses the X window to "Quit" the window,
    # this Destroy binding exits out of the while loop below.
    # We dont want to change the value of _PROP_RETURN,
    # but we will trigger the tkwait.  This binding is only executed
    # if the window is destroyed outside our control.  It is
    # removed in _prop_menu_destroy before we destroy the
    # window ourselves.
    bind $prop_menu <Destroy> {set _PROP_RETURN $_PROP_RETURN}


    # Pack the title, dialog box panels, and buttons onto the screen
    label $prop_menu.note -text $message -font $font
    pack $prop_menu.note -side top
    pack $prop_menu.buttons -side bottom
    for {set i 1} {$i <= $panelnumber} {incr i} {
	pack $prop_menu.data$i -side left -anchor n -fill x -expand 1
	if {$i < $panelnumber} {
	  # create a vertical separation between panels
	  frame $prop_menu.vsep$i -width $panel_sep
	  pack $prop_menu.vsep$i -side left
	}
    }

    update idletasks
    if { $firstwidget == "" } {
      catch {focus $prop_menu}
    } else {
      catch {focus $firstwidget}
    }
    catch {$firstwidget  selection range 0 1000};  # Will fail if not an entry.

    if {0} {
	# 10/10/01: This code is not only wrong, it is entirely unnecessary.
	# If the window floats off the screen, the window manager tries to fix it.

	# Border pixels for X windows.  Can't seem to figure these out.
	set xborder 3
	set yborder 25

	# If the prop_menu floats off the screen, move it back on.
	set dx [min [expr [winfo screenwidth $prop_menu]-[winfo width $prop_menu]- \
			 $x-$xborder] 0]
	set dy [min [expr [winfo screenheight $prop_menu]-[winfo height $prop_menu]- \
			 $y-$yborder] 0]
	if {$dx < 0 || $dy < 0} {
          wm geometry $prop_menu "+[expr $x+$dx]+[expr $y+$dy]"    
	}
    }

    set _PROP_SAVE(title,$prop_menu) $title
    set _PROP_SAVE(last_pos,$prop_menu) "[winfo rootx $prop_menu] [winfo rooty $prop_menu]"

    # 7/22, pat: warp cursor to done button.  There is no point
    # warping the cursor to the first entry, because if the
    # cursor is anywhere in the menu, the focus will
    # be in the first entry, which is all that matters.

    # NOTE: the warp_cursor_window can have a side-affect of causing
    # the window manager to take the focus away from our application
    # if we are not careful.  Make sure you update idletasks first.
    if { $default_button_widget != "" } {
      catch { _warp_cursor_window $default_button_widget -toplevel}
    }

    if {0} {
      # warp cursor to center of this prop menu.
      foreach win [list \
		$prop_menu.data1.f1.entry \
		$prop_menu.data1.f1.f \
		$prop_menu.data1.f1 \
		$prop_menu.done] {
	  if {[winfo exists $win]} {
	    _warp_cursor_window $win
	    break
	  }
      }
    }

    # NOTE: the following commands give window focus when debugging stand-alone.
    #if {![info exists MAX_DEVELOPER]} {
    #    update idletasks
    #    wm deiconify $prop_menu
    #}
      

    # Validation loop: continue loop until inputs are valid, or user cancels.
    while {1} {
      set _PROP_RETURN ""

      update idletasks
      if {! [_prop_menu_grab $prop_menu]} {
	# This will close down the window and return.
	set _PROP_RETURN cancel
      } else {
	catch {cursor_wait $prop_menu 1 $title}
	tkwait variable _PROP_RETURN
	catch {cursor_wait $prop_menu 0}
      }

      switch [lindex $_PROP_RETURN 0] {
      "continue" {
	# This is used by nested prop_menus: Since the PROP_RETURN variable was
	# changed by the second prop_menu, the original prop_menu is going
	# to enter this loop no matter what, so by setting _PROP_RETURN
	# to continue, we let the first prop_menu just keep going.

	continue
      }

      "invoke" {
	# Invoke -button and/or options (-command, -reload, etc) associated with
	# prop number specified in _PROP_RETURN value.
	set prop_number [lindex $_PROP_RETURN 1]  ;# Property number to invoke

	# Save out current values from prop_menu to user variables.
	_prop_update $w value

	set button_cmd [_prop_getopt $w $prop_number -button]
	if {$button_cmd != "" } {
	  # Exec -button command.
	  uplevel #0 $button_cmd
	  # This raise fails in the unlikely case that some one used the
	  # X menu "Quit" command to kill the parent prop menu.
	  # Note: every so often this raise takes several seconds.
	  # Dont know exactly what is happening, but suspect a race condition
	  # where the prop_menu invoked by the -button command above
	  # the process of being destroyed, and the raise command
	  # finds that window in the first pass through internally, but then
	  # cant find it later when it tries to raise above it.
	  # "update idletasks" did not fix it.  This "after 1" does.
	  after 1
	  catch {raise .prop_menu$w}
	  # Get any changed values from button command into prop_menu variables.
	  _prop_update $w get
	}

	set command [_prop_getopt $w $prop_number -command]
	if { $command != "" } {
	  _prop_update $w value
	  uplevel 1 $command
	  # The user command may have changed variables.  Get the new values.
	  _prop_update $w get
	}

	# See if there was a -reload or -return as well as -command.
	if {[set tmp [_prop_getopt $w $prop_number -return]] != ""} {
	  set retval $tmp
	  _prop_update $w value
	  # Exit now
	  break
	}
	
	if {[_prop_getopt $w $prop_number -reload 1]} {
	  _prop_update $w value
	  # Break verification "while" loop.  Parent loop will
	  # destroy and then repost prop_menu.
	  set prop_menu_repost 1
	  break
	}
	continue
      }

      "done" {
	# Normal prop_menu exit; user clicked Done button.
	set retval [lindex $_PROP_RETURN 1]

	# Check to make sure all entries are valid.
	# If not, popup error message, then continue current dialog box.
	set bugs ""
	for {set pn 0} {$pn < $_PROP_INFO($w,propcnt)} {incr pn} {
	  set propname $_PROP_INFO($w,$pn,name);        # Property name
	  set options $_PROP_INFO($w,$pn,options)
	  set proptype [lindex $options 0];    # property type
	  set new $_PROP_INFO($w,$pn,value);       # new value
	  set f_validate [_prop_getopt $w $pn -validate 1]
	  if { $f_validate } {
	    set valproc [_prop_getopt $w $pn -validate]
	    if { $valproc != "" && ![string match -* $valproc] } {
	      # Call user defined validation routine.
	      set ret [eval [list $valproc $new $propname]]
	      if { $ret != "" } {
		 append bugs "   $ret\n"
	      }
	      continue
	    }
	  }

	  # Always validate that -number or -scale are numbers.
	  # Instead of checking for a pattern, just try using it an expr.
	  if {$proptype == "-number" || $proptype == "-scale"} {
	    if {[catch {expr {$new + 0}}]} {
	      append bugs "    $propname: must be a number\n"
	      continue
	    }
	  }

	  if { $f_validate } {
	    set constraints ""
	    set scanned [scan $options "%s %f %f" proptype min max]
	    if {$scanned >= 2} {  ; # was a min specified?
	      set new [max $new $min]
	      append constraints "min=$min "
	    }
	    if {$scanned >= 3} {  ; # was a max specified?
	      set new [min $new $max]
	      append constraints "max=$max "
	    }
	    set incr [_prop_getopt $w $pn -incr]
	    if {$incr != ""} {
	      set new  [expr round(1.0 * $new/$incr) * $incr]
	      append constraints "increment=$incr "
	    } else {
	      set incr 1
	    }
	    #OLD: this didnt work
	    #if {abs($new - $_PROP_INFO($w,$pn,value)) > $incr * 0.01}
	    # Convert both values to numbers then back to strings,
	    # to eliminate rounding error; do NOT remove the space
	    # after the quote and before the bracket!!
	    if { [approx $new != $_PROP_INFO($w,$pn,value)] } {
	      append bugs "   $propname: ($constraints)\n"
	    }
	  }
	}

	if {$bugs != ""} {
	  set msg "Invalid Values for the following properties:\n"
	  prop_dialog -buttons OK -title "Error" "$msg$bugs"
	  continue
	}
	
	# Success!  Update variables in whoever called us.
	_prop_update $w value
	break
      }

      "apply" {
	# User clicked Apply button.
	set f_apply_called 1
	# Copy prop_menu menu variables to application
	_prop_update $w value
	# Call user defined function
	eval $apply
	# The user command may have changed variables.  Get the new values.
	_prop_update $w get
	# Break verification "while" loop.  Parent loop will
	# destroy and then repost prop_menu.
	set prop_menu_repost 1
	break
      }

      "cancel" {
	# User clicked Cancel button, or prop_menu closed by horrendous event,
	# like Control-C, grab failure, etc.
	_prop_update $w origvalue
	if { $f_apply_called } {
	  # Try to undo the affects of any previous "apply" functions.
	  eval $apply
	}
	break
      }

      default {
	# Window destroyed for unknown reasons.  Just quit NOW.
	break
      }

      } ;# switch

    } ;# validation loop: while {1}

    if {$prop_menu_repost && [winfo exists $prop_menu]} {
      # If the user has moved the window, try to repost it in the same spot.
      catch {set x [winfo rootx $prop_menu]}
      catch {set y [winfo rooty $prop_menu]}
    }

    _prop_menu_destroy $prop_menu

    update ;# Gets the window off the screen.
  }  ;# while {$prop_menu_repost}


  # Clean up _PROP_INFO, remove the _PROP_INFO elements used by
  # this window, but leave ones for other (nested) windows alone.
  catch {
    foreach n [array names _PROP_INFO ${w},*] {
      unset _PROP_INFO($n)
    }
  }

  # catch in case calling window was destroyed during dialog
  # We are not restoring a global grab, if any.
  catch {grab set $oldGrab}


  # If this was a recursive call to prop_menu2, tell the next guy
  # in the queue that the _PROP_RETURN was not meant for them.
  set _PROP_RETURN continue
  return $retval
}

proc prop_menu {x y message title prop_list} -desc {
  Displays a dialog box and returns user entries
} -doc {
  Similar to prop_menu2, with the following differences:
  
  1.  The prop_list is identical except that the second
      element for each property is the value of the property
      instead of the name of a variable containing the value.
  2.  Arguments are different, as shown.
  3.  The return value is "" if user hit cancel, otherwise the
      original prop_list modified to contain the new values.
  See: prop_menu2 
} {
  # Save prop values in _prop_array(n), call prop_menu2,
  # then recreate the prop_list with the new values from _prop_array.

  # Fish out the properties, put in _prop_array(n).
  set prop_list2 ""
  set pn 0
  foreach assoc $prop_list {
    if {[llength $assoc] < 2} {
      error "Missing value for $assoc in prop_menu titled: $title"
      return  ;# supposedly unnecessary
    }
    set propname [lindex $assoc 0]
    set propval [lindex $assoc 1]
    set proptype [lindex $assoc 2]
    switch -- {$proptype} {
      "label" -
      "-label" -
      "button" -
      "-button" {
	# For these prop-types, if the value is empty, must leave it empty.
	if { $propval == "" } {
	  set _prop_array($pn) $propval
	  lappend prop_list2 [lreplace $assoc 1 1 _prop_array($pn)]
	} else {
	  lappend prop_list2 $assoc
	}
      }
      default {
	set _prop_array($pn) $propval
	lappend prop_list2 [lreplace $assoc 1 1 _prop_array($pn)]
      }
    }
    incr pn
  }

  set ret [prop_menu2 -x $x -y $y -message $message -title $title $prop_list2]
  if { $ret == 0 } {
    # user hit cancel
    return ""
  }

  # Create new prop list to return to user
  set pn 0
  set new_prop_list ""
  foreach assoc $prop_list {
    set propname [lindex $assoc 0]
    set propval [lindex $assoc 1]
    set proptype [lindex $assoc 2]
    if { [info exists _prop_array($pn)] } {
      set newval $_prop_array($pn)
      set assoc [lreplace $assoc 1 1 $newval]
    }
    lappend new_prop_list $assoc
    incr pn
  }
  return $new_prop_list
}



# This is not used in this module, but there are references to
# it in both max and sue so I could not delete it.
# It should probably be eliminated. (pat)
proc tab_through_entries {list {dir forward}} {

  set i [lsearch $list [focus]]

  if {$i < 0} {
    # no focus yet
    focus [lindex $list 0]
    return
  }
  
  # Must catch error, because widget may not be an entry, so insert will fail.
  catch { set insert [[lindex $list $i] index insert] }

  if {$dir == "forward"} {
    incr i
    if {$i >= [llength $list]} {
      set i 0
    }
  } else {
    incr i -1
    if {$i < 0} {
      set i [expr [llength $list] - 1]
    }
  }

  # Must catch error, because widget may not be an entry, so icursor will fail.
  catch {[lindex $list $i] icursor $insert}
  focus [lindex $list $i]
}

proc _warp_cursor {x y} {
  global OPTIONS
  if {[info exists OPTIONS(warp_cursor)] && $OPTIONS(warp_cursor) == 0} {
    return  ;# dont do it
  }

  if {[info commands warp_cursor] != "warp_cursor"} {
    # not defined
    # The warp_cursor function is a recent MMI extension to Tk.
    return
  }
  warp_cursor $x $y
}


proc _warp_cursor_window {args} -desc {
  warps the cursor to the center of this subwindow if the warp_cursor command is defined
} -doc {
  USAGE:
    _warp_cursor_window [-options] win
  
  Options:
  -force - always warp cursor, even if cursor is in another application;

  -toplevel - if cursor is already in the toplevel of $win,
    dont bother to warp it.
    For some windows, eg, prop_menus, it is impolite to warp the
    cursor if the user is familiar enough with the prop menu
    that they have aleady pre-positioned the cursor in the current
    window where they know they will want it when the prop menu finally appears.
    Just having the cursor anywhere in the toplevel is sufficient
    to get the focus.

  But in no case will cursor be warped if disabled by OPTIONS(warp_cursor)
} {
  set win [call_keyword $args {{force} {toplevel}}]

  # If cursor not in max/sue window, dont warp.
  # We can tell because curwin will be non-empty
  # if and only if our application owns it.
  set curwin [winfo containing [winfo pointerx $win] [winfo pointery $win]]
  if { ! $force } {
    if { $curwin == "" } { return }
  }

  # Also see if the cursor is already over the new filebox/prop/dialog window,
  # and dont warp in that case; it would be redundant, and its confusing.
  # We can detect this case if the toplevel of curwin
  # matches the toplevel of win.
  if { $toplevel } {
    set toplevel [winfo toplevel $curwin]
    if { $curwin == "" || [string first $toplevel $win] == 0} {
      return
    }
  }

  update
  if {![winfo exists $win]} {
    # bad window name
    return
  }

  set x [expr [winfo rootx $win] + [winfo width $win]/2]
  set y [expr [winfo rooty $win] + [winfo height $win]/2]

  _warp_cursor $x $y
}


proc prop_dialog {args} -desc {
  popup a dialog box
} -doc {
  This procedure displays a simple dialog box, waits for a button in the dialog
  to be invoked, then returns the name of selected button.

  prop_dialog differs from tk_dialog as follows:
    1.  puts text in a text widget with a scrollbar, so it can
        accomodate arbitrary length messages and does a better
	job of formatting long messages.
    2.  Returns selected button name, not button index.
    3.  Window location determined better, like prop_menu.
    4.  Safer interface - binds <Control-C>, <Escape>, and
	<Destroy> to return -cancel value.
    5.  Different options, listed below; bitmap not supported.

  USAGE:
    prop_dialog [-options] text

  Options:

  -buttons <button_list>  List of button names to display, default: Close.
	  If multiple buttons, max/sue standard practice is to put
	  the "YES" option first, and the "NO" option last,
	  eg: -buttons "OK Cancel".  If you do this, you dont have
	  to supply the -default or -cancel options, and the
	  dialog box will be BATCH mode safe.
  -title <title>     Title of dialog box.
  -default <value>  Specify the default return value that is returned
	  if the user presses enter, or if we are in BATCH mode.
	  If -default is not specified, the value is the first button name.
	  If this value matches a button-name, that button is drawn
	  with a default ring.
  -cancel <value>  Value returned if window is canceled by Control-C
	  or Escape, or window dies.
	  If -cancel is not specified, the value is the last button name.
  -window <window>   Name of window to use, probably never needed.
  -width <width>     Window width in chars eg: -width 60
  -height <height>   Window height, default units are lines, eg: -height 10
  -x x -y y          Window location.
  -atmouse           Pop up window at mouse location; ignore -x and -y, 
  -restore <binary>  If 1, restore cursor after window exits.

  Example:
  set message "Cell already exists.  Do you want to delete it first?"
  set choice [prop_dialog -title {Delete cell?} -buttons {Yes No} $message]
  if { $choice == "Yes" } {
    puts "delete the cell..."
  }
} {
  global BATCH _PROP_DIALOG _PROP_SAVE
  global DIALOG_FONT;    # Font used for labels in dialog box
  set font $DIALOG_FONT; # Just a shorter name for the font

  set options [list {window .prop_dialog} {title "Message"} \
	{buttons Close} {default _UNDEFINED_} {cancel _UNDEFINED_} \
	{width 80} {height _UNDEFINED_} {atmouse ""} \
	{x ""} {y ""} {restore 1} ]

  set newargs [call_keyword $args $options]
  set text [lindex $newargs 0]
  set w $window
  set line_spacing 8

  if { $default == "_UNDEFINED_" } {
    set default [lindex $buttons 0]
  }
  if { $cancel == "_UNDEFINED_" } {
    set cancel [lindex $buttons end]
  }

  # Guess the approximate text window height.
  # We dont know exactly, because of word-wrap.
  # We do this so we dont get a gigantic dialog with just a few
  # words in it.
  if { $height == "_UNDEFINED_" } {
    set font_height [font metrics $font -linespace]
    set npixels 0
    foreach line [split $text \n] {
      # Subtract 10 from width to guess what it will be after word-wrap.
      set npixels [expr $npixels + $line_spacing + \
	ceil(1.0 * [string length $line] / ($width-10)) * $font_height]
    }
    # The -height arg to the text widget is in units of
    # font_height + line_spacing
    set height [expr $npixels / ($font_height + $line_spacing)]
    # Min of 2, max of 10 lines.
    set height [max 2 [min 10 $height]]
  }

  if {[info exists BATCH] && $BATCH == 1} {
     # no dialog boxes in batch mode
     # but we probably want to see the message:
     puts "$title: $text"
     return $default
  }

  # Determine window location.  winname is parent window name.
  set winname [_prop_menu_top_win]
  set old_cursor [winfo pointerxy $winname]
  if { $atmouse != "" } {
      set x [expr [winfo pointerx $winname] + $atmouse]
      set y [expr [winfo pointery $winname] + $atmouse]
  } elseif { $x == "" || $y == "" } {
    # If user moved window previously, restore window in same location.
    if { $title != "" && [info exists _PROP_SAVE(pos,$title)] } {
      setl {x y} $_PROP_SAVE(pos,$title)
    } else {
      if { $winname != "" } {
	  set y [expr [winfo rooty $winname] + 50]
	  set x [expr [winfo rootx $winname] + 50]
      } else {
	  # Make something up.
	  set y 100
	  set x 100
      }
    }
  }

  # Remember old grab and focus.
  set _PROP_SAVE(oldFocus,$w) [focus]
  set oldGrab [grab current $winname]

  # Create the top-level window and divide it into top and bottom parts.

  catch {destroy $w}
  toplevel $w
  wm title $w $title
  wm iconname $w Message
  wm minsize $w 200 150

  frame $w.bot -relief flat -bd 1
  pack $w.bot -side bottom
  frame $w.top -relief raised -bd 1
  pack $w.top -side top -fill both -expand 1

  # Fill the top part with bitmap and message (use the option
  # database for -wraplength so that it can be overridden by
  # the caller).

  text $w.text -font $font -spacing1 0 -spacing3 $line_spacing -wrap word \
    -height $height -width $width
  # Disable text so user cant edit it, but must fill with text first.
  $w.text insert end $text
  $w.text configure -state disabled

  scrollbar $w.vscroll \
	  -relief raised \
	  -command "$w.text yview"
  $w.text configure -yscrollcommand "$w.vscroll set"

  pack $w.vscroll -in $w.top -side right -fill y
  pack $w.text -in $w.top -side left -expand 1 -fill both -padx 3m -pady 3m


  # Focus will be main window, unless there is a default button.
  set focus_window $w

  # Create a row of buttons at the bottom of the dialog.
  set i 0
  foreach but $buttons {
    if {$but == $default} {
      set default_state "active"
      # Create a binding for <Return> on the dialog if there is a
      # default button.
      bind $w <Return> [list set _PROP_DIALOG(button) $default]
    } else {
      set default_state "normal"
    }
    button $w.button$i -text $but -font $font -padx 1m -pady 1m \
	-default $default_state \
	-command "[list set _PROP_DIALOG(button) $but]; _prop_menu_destroy $w"

    pack $w.button$i -in $w.bot -side left -expand 1 -padx 4m -pady 1m
    incr i
  }

  # Create a <Destroy> binding that will be executed in case the
  # window is destroyed by the Quit system button, or some other way
  # outside our control.
  # This binding will carefully be removed before we destroy
  # the window, below, so this binding is only executed if
  # the window is destroyed for unknown reasons.

  bind $w <Destroy> [list set _PROP_DIALOG(button) $cancel]
  bind $w <Any-Control-c> [list set _PROP_DIALOG(button) $cancel]
  bind $w <Escape> [list set _PROP_DIALOG(button) $cancel]

  # Withdraw the window, then update all the geometry information
  # so we know how big it wants to be, then center the window in the
  # display and de-iconify it.

  wm withdraw $w
  update idletasks
  wm geom $w +$x+$y
  wm deiconify $w

  if {0} {  ;# Worked, but flashes
    # Update the text window size to approximately match what is in it.
    # You have to wait until the text widget is posted before it will
    # compute how much room is needed, because it needs to compute
    # it based on how the lines are word-wrapped, etc.
    # This works, but since you have two wait until the window
    # is displayed, it causes a flash.

    update idletasks
    # Number of unwrapped lines.
    set lastline [expr [lindex [split [$w.text index end] .] 0] - 1]
    # Get bbox of last char in text.
    setl {cx cy cwidth cheight} [$w.text bbox "${lastline}.0 lineend"]
    # cy is null if the last line is not visible, ie, box is not big
    # enough, so dont shrink it any more.
    if { $cy != "" } {
      # Compute number of wrapped lines needed.
      # Tcl computes the window size by taking -height times
      # the font height + spacing, even though spacing is not
      # used between non-wrapped lines.
      set reqheight [expr ceil(1.0 * $cy / ($cheight+$line_spacing)) + 1]
      set reqheight [max 2 $reqheight]
      if { $reqheight < $height } {
	$w.text configure -height $reqheight
      }
    }
  }

  # Remember original location of window.
  set _PROP_SAVE(title,$w) $title
  set _PROP_SAVE(last_pos,$w) "[winfo rootx $w] [winfo rooty $w]"

  update idletasks
  if { ! [_prop_menu_grab $w] } {
    destroy $w      
    return $cancel
  }

  focus $focus_window
  _warp_cursor_window $focus_window

  # Wait for the user to respond, then restore the focus and
  # return the index of the selected button.  Restore the focus
  # before deleting the window, since otherwise the window manager
  # may take the focus away so we can't redirect it.  Finally,
  # restore any grab that was in effect.

  # MMI mod: call cursor_wait.
  catch {cursor_wait $w 1 $title}
  tkwait variable _PROP_DIALOG(button)
  catch {cursor_wait $w 0}

  # We may have already done it once, but do it again anyway.
  _prop_menu_destroy $w

  update idletasks
  if { $restore } {
    eval _warp_cursor $old_cursor
  }

  if { $oldGrab != "" } {
    catch {grab set $oldGrab}
  }
  return $_PROP_DIALOG(button)
}
