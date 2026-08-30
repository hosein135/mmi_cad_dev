# This is tk4.1 library dialog.tcl customized for MMI (calls cursor_wait)
set RCSVERSION(dialog.tcl) { $Revision: 1.15 $ }

#
# This file defines the procedure tk_dialog, which creates a dialog
# box containing a bitmap, a message, and one or more buttons.
#
# SCCS: @(#) dialog.tcl 1.25 96/04/10 15:43:33
#
# Copyright (c) 1992-1993 The Regents of the University of California.
# Copyright (c) 1994-1996 Sun Microsystems, Inc.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

#
# tk_dialog:
#
# This procedure displays a dialog box, waits for a button in the dialog
# to be invoked, then returns the index of the selected button.  If the
# dialog somehow gets destroyed, -1 is returned.
#
# Arguments:
# w -		Window to use for dialog top-level.
# title -	Title to display in dialog's decorative frame.
# text -	Message to display in dialog.
# bitmap -	Bitmap to display in dialog (empty string means none).
# default -	Index of button that is to display the default ring
#		(-1 means none).
# args -	One or more strings to display in buttons across the
#		bottom of the dialog box.

proc tk_dialog {w title text bitmap default args} -desc {
  popup a dialog box
} -doc {
  This procedure displays a dialog box, waits for a button in the dialog
  to be invoked, then returns the index of the selected button.  If the
  dialog somehow gets destroyed, -1 is returned.

  Arguments:

  w -   	Window to use for dialog top-level.
  title -	Title to display in dialog's decorative frame.
  text -	Message to display in dialog.
  bitmap -	Bitmap to display in dialog (empty string means none).
  default -	Index of button that is to display the default ring (-1 means none).
  args -	One or more strings to display in buttons across the
  bottom of the dialog box.

  Example:

  set message "Cell already exists.  Do you want to delete it first?"
  set choice [tk_dialog .dialog {Delete existing cell?} $message {} 1 \
		{Yes} {Cancel}]
} {
    global tkPriv BATCH

    # MMI mod: modified for MAX/SUE
    if {[info exists BATCH] && $BATCH == 1} {
       # no dialog boxes in batch mode
       # MMI, 5/00, pat: Yeah, but we probably want to see the message:
       puts "$title: $text"
       return ""
    }

    # 1. Create the top-level window and divide it into top
    # and bottom parts.

    catch {destroy $w}
    toplevel $w -class Dialog
    wm title $w $title
    wm iconname $w Dialog
    # MMI note: This protocol def keeps the "Quit" from working in
    # the dialog Xwindow.   This behavior is now relied on by Sue,
    # which assumes tk_dialog never returns -1, so dont change it.
    wm protocol $w WM_DELETE_WINDOW { }

    # The following command means that the dialog won't be posted if
    # [winfo parent $w] is iconified, but it's really needed;  otherwise
    # the dialog can become obscured by other windows in the application,
    # even though its grab keeps the rest of the application from being used.

    # MMI mod: The following command has been removed because
    # if it is present the dialog won't be posted
    # if [winfo parent $w] is iconified.
    #    wm transient $w [winfo toplevel [winfo parent $w]]
    frame $w.bot -relief raised -bd 1
    pack $w.bot -side bottom -fill both
    frame $w.top -relief raised -bd 1
    pack $w.top -side top -fill both -expand 1

    # 2. Fill the top part with bitmap and message (use the option
    # database for -wraplength so that it can be overridden by
    # the caller).

    # MMI mod: changed length to 6i below.
    option add *Dialog.msg.wrapLength 6i widgetDefault
    label $w.msg -justify left -text $text
    catch {$w.msg configure -font \
		-Adobe-Times-Medium-R-Normal--*-180-*-*-*-*-*-*
    }
    pack $w.msg -in $w.top -side right -expand 1 -fill both -padx 3m -pady 3m
    if {$bitmap != ""} {
	label $w.bitmap -bitmap $bitmap
	pack $w.bitmap -in $w.top -side left -padx 3m -pady 3m
    }

    # 3. Create a row of buttons at the bottom of the dialog.

    set i 0
    foreach but $args {
	button $w.button$i -text $but -command "set tkPriv(button) $i"
	if {$i == $default} {
	    frame $w.default -relief sunken -bd 1
	    raise $w.button$i $w.default
	    pack $w.default -in $w.bot -side left -expand 1 -padx 3m -pady 2m
	    pack $w.button$i -in $w.default -padx 2m -pady 2m
	} else {
	    pack $w.button$i -in $w.bot -side left -expand 1 \
		    -padx 3m -pady 2m
	}
	incr i
    }

    # 4. Create a binding for <Return> on the dialog if there is a
    # default button.

    if {$default >= 0} {
	bind $w <Return> "
	    $w.button$default configure -state active -relief sunken
	    update idletasks
	    after 100
	    set tkPriv(button) $default
	"
    }

    # 5. Create a <Destroy> binding for the window that sets the
    # button variable to -1;  this is needed in case something happens
    # that destroys the window, such as its parent window being destroyed.

    bind $w <Destroy> {set tkPriv(button) -1}

    # 6. Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it.

    wm withdraw $w
    update idletasks
    set x [expr [winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
	    - [winfo vrootx [winfo parent $w]]]
    set y [expr [winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
	    - [winfo vrooty [winfo parent $w]]]
    wm geom $w +$x+$y
    wm deiconify $w

    # MMI mod.
    # warp cursor to default button or, if none, first button.
    if {[winfo exists $w.button$default]} {
      _warp_cursor_window $w.button$default
    } else {
      _warp_cursor_window $w.button1
    }

    # 7. Set a grab and claim the focus too.

    set oldFocus [focus]
    set oldGrab [grab current $w]
    if {$oldGrab != ""} {
	set grabStatus [grab status $oldGrab]
    }

    if {[catch "grab $w" msg]} {
      # sometimes this fails due to a tk bug
      puts $msg
      destroy $w      
      # is this the right thing to return???
      return ""
    }
  
    if {$default >= 0} {
	focus $w.button$default
    } else {
	focus $w
    }

    # 8. Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    # MMI mod: call cursor_wait.
    catch {cursor_wait $w 1 $title}
    tkwait variable tkPriv(button)
    catch {cursor_wait $w 0}

    catch {focus $oldFocus}
    catch {
	# MMI note: I dont think this ever happens, because
	# the "WM_DELETE_WINDOW" protocol was over-written above.
	# It's possible that the window has already been destroyed,
	# hence this "catch".  Delete the Destroy handler so that
	# tkPriv(button) doesn't get reset by it.

	bind $w <Destroy> {}
	destroy $w
    }
    # MMI, 5/1/00, pat: Added catch in case calling window was
    # destroyed during dialog
    catch {
      if {$oldGrab != ""} {
	  if {$grabStatus == "global"} {
	      grab -global $oldGrab
	  } else {
	      grab $oldGrab
	  }
      }
    }
    return $tkPriv(button)
}
