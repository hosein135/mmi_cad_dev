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


# Procedures for adding and modifying text.

# Note that we don't need to restrict the user to grids for text but
# we do anyways

proc setup_text_mode {} {

  global cur_c SNAP_XY

  modify_setup

  enter_mode text abort_text_mode

  # make sure nothing has this tag leftover
  $cur_c dtag mod_text

  msg_window "Button-1 begins text, Ctrl-c aborts"

  bind_add -mode text -hotkey Button-1 -command "add_text $SNAP_XY" \
      -help "Add text at cursor position."

  bind_add -mode text -hotkey Control-c -command "abort_text_mode" \
      -help "Abort text mode."

  bind_add -mode text -hotkey Escape -command "abort_text_mode" \
      -help "Abort text mode."
}


proc setup_modify_text_mode {{id ""}} {

  global cur_c _TEXT_UNDO_

  enter_mode text abort_modify_text_mode

  # make sure nothing has this tag leftover
  $cur_c dtag mod_text

  if {$id == ""} {
    set id [$cur_c find withtag current]
  }

  # this new text will get a special tag for now
  $cur_c addtag mod_text withtag $id

  # on ctrl-c, revert string to original
  set _TEXT_UNDO_(text) [$cur_c itemcget $id -text]
  set _TEXT_UNDO_(size) [_text_size $id]
  set _TEXT_UNDO_(anchor) [string index [$cur_c itemcget $id -anchor] 0]

  bind_add -mode text -hotkey Control-c -command "abort_modify_text_mode" \
      -help "Abort modify text.  Undo any changes to current text."

  modify_text
}


# Makes text.  Used by outside world

proc make_text {args} -type user -desc {

Primitive procedure to add text to the current schematic.  

USAGE: make_text -origin <x_y_list> -text <text> [-size <size>]
                 [-anchor <anchor>] [-rotate <0|1>]

Text has two orientations: normal (0) and rotated (1).  Text defaults
to normal (0).

Size can be one of: very-small, small, standard, large, very-large.
Size defaults to standard.

Anchor can be one of: n, s, e, w, ne, nw, se, sw, center, or c.
Anchor defaults to w.

For example:

        sue> make_text -origin {120 140} -text "Needs a keeper."

NOTE: this procedure can only be used on a new schematic or if
proceeded by api_zoom setup.  Otherwise, its position may be incorrect
or even off-grid.

NOT UN-DOABLE

} {

  call_by_keyword $args {{origin {0 0}} {text {}} {size standard} \
			     {anchor w} {rotate 0}}

  global cur_c scale FONT COLORS ROTATE_TEXT

  if {$ROTATE_TEXT} {
    set id [$cur_c create text [lindex $origin 0] [lindex $origin 1] \
		-text $text -font $FONT($size,$scale) -fill $COLORS(fore) \
		-tags "draw_item size_$size scaletext" -anchor $anchor \
		-rotate $rotate]
  } else {
    set id [$cur_c create text [lindex $origin 0] [lindex $origin 1] \
		-text $text -font $FONT($size,$scale) -fill $COLORS(fore) \
		-tags "draw_item size_$size scaletext" -anchor $anchor]
  }
  return $id
}


# Adds text if nothing is there or modifies existing text

proc add_text {x y} {

  global cur_c scale _TEXT_UNDO_

  # insure that we have a integer scale
  set save_scale $scale
  set scale [expr int(ceil($scale))]

  set id [make_text -origin "$x $y"]

  # restore scale
  set scale $save_scale

  # this new text will get a special tag for now
  $cur_c addtag mod_text withtag $id

  $cur_c icursor $id 0

  # Used to determine if modified
  set _TEXT_UNDO_(text) ""
  set _TEXT_UNDO_(size) standard
  set _TEXT_UNDO_(anchor) w

  modify_text
}


proc modify_text {} {

  global cur_c cur_s

  msg_window "Button-1 moves cursor, Shift-Return for newline, Return ends, Button-2 changes size, Button-3 changes anchor, Shift-Space for help, Ctrl-c aborts"

  # reset Button-1
  bind_add -mode text -hotkey Button-1 -command "possibly_end_text_mode" \
      -help "If over text, reposition insertion cursor, otherwise, exit text mode."

  bind_add -mode text -hotkey Button-2 \
      -command "change_text_size %x %y" \
      -help "Change text size."

  bind_add -mode text -hotkey Button-3 \
      -command "change_text_anchor %x %y" \
      -help "Change text anchor."
  
  bind_add -mode text -hotkey Shift-space -command "help_window %x %y" \
      -help "Display this window."

  $cur_c focus mod_text
  draw_anchor_marker mod_text
  
  $cur_c bind mod_text <Escape> abort_modify_text_mode

  $cur_c bind mod_text <Any-KeyPress> "$cur_c insert mod_text insert %A"
  $cur_c bind mod_text <Delete> \
      "$cur_c dchars mod_text \[expr \[$cur_c index mod_text insert\] + 0\]"
  $cur_c bind mod_text <BackSpace> \
      "$cur_c dchars mod_text \[expr \[$cur_c index mod_text insert\] - 1\]"
  # Serious hack to fix the tab changing the focus
  $cur_c bind mod_text <Tab> "end_text_mode; after 500 {focus $cur_c}"
  $cur_c bind mod_text <Return> "end_text_mode"
  # insert a new line shift-return
  $cur_c bind mod_text <Shift-Return> [list $cur_c insert mod_text insert \n]
  $cur_c bind mod_text <Control-o> "[list $cur_c insert mod_text insert \n] ; \
      $cur_c icursor mod_text \[expr \[$cur_c index mod_text insert\] - 1\]"
  $cur_c bind mod_text <Button-1> \
      "$cur_c icursor mod_text \@\[$cur_c canvasx %x\],\[$cur_c canvasy %y\]; set TEXT_CHIT 1"

  $cur_c bind mod_text <Home> "$cur_c icursor mod_text 0"
  $cur_c bind mod_text <End> "$cur_c icursor mod_text end"

  # some EMACS-like bindings
  $cur_c bind mod_text <Control-b> \
      "$cur_c icursor mod_text \[expr \[$cur_c index mod_text insert\] - 1\]"
  $cur_c bind mod_text <Control-f> \
      "$cur_c icursor mod_text \[expr \[$cur_c index mod_text insert\] + 1\]"
  $cur_c bind mod_text <Control-a> "$cur_c icursor mod_text \[bol\]"
  $cur_c bind mod_text <Control-e> "$cur_c icursor mod_text \[eol\]"
  $cur_c bind mod_text <Control-d> "$cur_c dchars mod_text insert"
  $cur_c bind mod_text <Control-k> "$cur_c dchars mod_text insert \[eol\]"
  $cur_c bind mod_text <Control-n> "next_line forward"
  $cur_c bind mod_text <Control-p> "next_line backward"

  # make the arrow keys work also
  $cur_c bind mod_text <Left> \
      "$cur_c icursor mod_text \[expr \[$cur_c index mod_text insert\] - 1\]"
  $cur_c bind mod_text <Right> \
      "$cur_c icursor mod_text \[expr \[$cur_c index mod_text insert\] + 1\]"
  $cur_c bind mod_text <Up> "next_line backward"
  $cur_c bind mod_text <Down> "next_line forward"
}


# popup a menu to select a text size

proc change_text_size {x y} {

  global cur_c _MOD_TEXT_

  set _MOD_TEXT_ [_text_size mod_text]

  set win .mod_text

  # make the menu
  catch {destroy $win}
  menu $win -tearoff 0

  foreach size "very-small small standard large very-large" {
    $win add radiobutton -label $size -variable _MOD_TEXT_ -value $size \
	-command change_text_size_change
  }

  # post it
  $win post $x $y

  return
}


# actually change the size of the text

proc change_text_size_change {{size ""} {id ""}} {

  global cur_c scale FONT _MOD_TEXT_ _TEXT_UNDO_

  if {$size == ""} {
    # came from menu
    catch {destroy .mod_text}
    set size $_MOD_TEXT_
  }

  if {$id == ""} {
    set id mod_text
  }

  set old_size "size_[_text_size $id]"

  # did it change
  if {$old_size != $size} {
    # update tags
    $cur_c dtag $id $old_size
    $cur_c addtag size_$size withtag $id

    # now actually change the size
    set fscale [max [expr int(round($scale))] 0]
    $cur_c itemconfigure $id -font $FONT($size,$fscale)
  }
}


# popup a menu to select a text anchor

proc change_text_anchor {x y} {

  global cur_c _MOD_TEXT_

  set _MOD_TEXT_ [string index [$cur_c itemcget mod_text -anchor] 0]

  set win .mod_text

  # make the menu
  catch {destroy $win}
  menu $win -tearoff 0

  foreach anchor "n s e w c ne se nw sw" {
    $win add radiobutton -label $anchor -variable _MOD_TEXT_ -value $anchor \
	-command change_text_anchor_change
  }

  # post it
  $win post $x $y

  return
}


proc change_text_anchor_change {{anchor ""} {id ""}} {

  global cur_c scale _MOD_TEXT_

  if {$anchor == ""} {
    # came from menu
    catch {destroy .mod_text}
    set anchor $_MOD_TEXT_
  }

  if {$id == ""} {
    set id mod_text
  }

  set old_anchor [$cur_c itemcget $id -anchor]
  if {[string index $old_anchor 0] == "c"} {
    set old_anchor c
  }

  if {$old_anchor != $anchor} {
    set bbox [$cur_c bbox $id]
    if {$bbox == ""} {
      # invalid
      return
    }
    set width [expr [lindex $bbox 2] - [lindex $bbox 0] - 2]
    set height [expr [lindex $bbox 3] - [lindex $bbox 1] - 2]

    switch $old_anchor {
      w - nw - sw { set dx 0 }
      e - ne - se { set dx [expr 0 - $width] }
      c - center - n - s { set dx [expr 0 - $width/2.0] }
    }

    switch $old_anchor {
      n - nw - ne { set dy 0 }
      s - sw - se { set dy [expr 0 - $height] }
      c - center - e - w { set dy [expr 0 - $height/2.0] }
    }

    switch $anchor {
      w - nw - sw { set dx [expr $dx + 0] }
      e - ne - se { set dx [expr $dx + $width] }
      c - center - n - s { set dx [expr $dx + $width/2.0] }
    }

    switch $anchor {
      n - nw - ne { set dy [expr $dy + 0] }
      s - sw - se { set dy [expr $dy + $height] }
      c - center - e - w { set dy [expr $dy + $height/2.0] }
    }


    # round to the nearest grid
    set dx [expr round(1.0 * $dx / $scale) * $scale]
    set dy [expr round(1.0 * $dy / $scale) * $scale]

    $cur_c move $id $dx $dy

    # update the anchor
    $cur_c itemconfigure $id -anchor $anchor

    if {$id == "mod_text"} {
      # update the anchor marker
      $cur_c delete anchor
      draw_anchor_marker mod_text
    }
  }
}


proc show_anchors {} {

  global cur_c

  # waste any old anchors
  $cur_c delete anchor

  foreach id [$cur_c find withtag scaletext] {
    draw_anchor_marker $id
  }
}


proc draw_anchor_marker {id} {

  global cur_c scale COLORS

  set coords [$cur_c coords $id]
  set x [lindex $coords 0]
  set y [lindex $coords 1]
  set del [expr $scale/3.0]

  $cur_c create line $x $y [expr $x-$del] [expr $y-$del] [expr $x-$del] \
      [expr $y+$del] $x $y -tags "anchor tmp" -fill $COLORS(anchor) 
  $cur_c lower "anchor" "scaletext"
}


# returns the begining of the line index.  Complicated for multi-line text.

proc bol {} {

  global cur_c

  set cursor [$cur_c index mod_text insert]
  set text [$cur_c itemcget mod_text -text]

  return [expr 1 + [string last "\n" [string range $text 0 [expr $cursor-1]]]]
}

# returns the end of the line index.  Complicated for multi-line text.

proc eol {} {

  global cur_c

  set cursor [$cur_c index mod_text insert]
  set text [$cur_c itemcget mod_text -text]

  set next_lf [string first "\n" [string range $text $cursor end]]
  if {$next_lf == -1} {
    return end
  } else {
    return [expr $next_lf + $cursor]
  }
}

# moves the cursor forward or back a line.  Wraps.

proc next_line {dir} {

  global cur_c

  set cursor [$cur_c index mod_text insert]
  set text [$cur_c itemcget mod_text -text]

  set prev_lf [string last "\n" [string range $text 0 [expr $cursor-1]]]

  if {$dir == "forward"} {
    set next_lf [string first "\n" [string range $text $cursor end]]
    if {$next_lf != -1} {
      incr next_lf $cursor
      set stop_lf [string first "\n" [string range $text [expr $next_lf+1] end]]
      if {$stop_lf == -1} {
	set stop_lf [string length $text]
      } else {
	incr stop_lf [expr $next_lf+1]
      }
    } else {
      set stop_lf [string first "\n" [string range $text 0 end]]
      if {$stop_lf == -1} {
	set stop_lf 100000
      }
    }
  } else {
    set next_lf [string last "\n" [string range $text 0 [expr $prev_lf-1]]]
    if {$next_lf != -1} {
      set stop_lf $prev_lf
    } else {
      if {$prev_lf == -1} {
	set next_lf [string last "\n" $text]
	set stop_lf 100000
      } else {
	set next_lf -1
	set stop_lf $prev_lf
      }
    }
  }
  $cur_c icursor mod_text [min [expr $next_lf + $cursor - $prev_lf] $stop_lf]
}


proc possibly_end_text_mode {} {

  global TEXT_CHIT

  if {[winfo exists .mod_text]} {
    destroy .mod_text
    return
  }

  if {[info exists TEXT_CHIT]} {
    unset TEXT_CHIT
    return
  }

  end_text_mode
}


proc abort_text_mode {} {

  global cur_c

  $cur_c delete mod_text
  $cur_c delete anchor

  end_text_mode
}


proc abort_modify_text_mode {} {

  global cur_c _TEXT_UNDO_

  $cur_c itemconfigure mod_text -text $_TEXT_UNDO_(text)
  change_text_size_change $_TEXT_UNDO_(size)
  change_text_anchor_change $_TEXT_UNDO_(anchor)

  end_text_mode
}


proc end_text_mode {} {

  global cur_c _TEXT_UNDO_

  catch {destroy .mod_text}

  $cur_c delete anchor
  $cur_c focus ""

  # throw away null strings
  set text [$cur_c itemcget mod_text -text]
  if {$text == ""} {
    puts "Aborted text mode."
    $cur_c delete mod_text

  } else {
    set id [lindex [$cur_c find withtag mod_text] 0]
    select_id $id

    # get rid of special tag
    $cur_c dtag mod_text

    set anchor [string index [$cur_c itemcget $id -anchor] 0]

    if {$text != $_TEXT_UNDO_(text) || [_text_size $id] != $_TEXT_UNDO_(size) \
	  || $anchor != $_TEXT_UNDO_(anchor)} {
      # flag that this canvas has been modified
      is_modified

      if {$_TEXT_UNDO_(text) == ""} {
	# new text, undo toasts
	setup_undo $id ""
      } else {
	# existing text, undo restores
	# first need to quote braces
#	regsub -all \{ $_TEXT_UNDO_(text) \\\{ _TEXT_UNDO_(text)
	regsub -all \{ $_TEXT_UNDO_(text) <<< _TEXT_UNDO_(text)
#	regsub -all \} $_TEXT_UNDO_(text) \\\} _TEXT_UNDO_(text)
	regsub -all \} $_TEXT_UNDO_(text) >>> _TEXT_UNDO_(text)
# BUG: INTRODUCES a \{ or \} into string.  Need quote character or get 
# a bad list.  Should unquote during undo
#	setup_undo $id "\{$cur_c itemconfigure \[xform_ids $id\] -text \{$_TEXT_UNDO_(text)\}\}" no_delete
	setup_undo $id "\{set foo \{$_TEXT_UNDO_(text)\} ; regsub -all <<< \$foo \\\{ foo ; regsub -all >>> \$foo \\\} foo ; $cur_c itemconfigure \[xform_ids $id\] -text \"\$foo\" ; change_text_size_change $_TEXT_UNDO_(size) \[xform_ids $id\] ; change_text_anchor_change $_TEXT_UNDO_(anchor) \[xform_ids $id\]\}" no_delete
      }
    }
  }

  # clean up the bindings
  foreach binding [$cur_c bind mod_text] {
    $cur_c bind mod_text $binding ""
  }

  leave_mode text
}


proc _text_size {id} {

  global cur_c

  set tags [$cur_c gettags $id]
  return [lindex [split [lindex $tags [lsearch $tags size_*]] _] 1]
}
