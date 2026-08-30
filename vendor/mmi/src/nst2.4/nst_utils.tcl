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


# NST Utility procedures.


# Pretty prints a number using the spice metric suffixes

proc pp_number {num} {
  if {$num == 0} {
    return 0
  }
  if {$num == "Inf" || $num == "-Inf"} {
    return ""
  }

  set prefixes {G M K "" m u n p f a}
  if {[catch {set logscale [expr floor(log10(abs($num))/3.0)]}]} {
    set logscale 0
  }

  if {[catch {set mantissa [expr $num/pow(10,3.0*$logscale)]}]} {
    set mantissa 0.0
  }
  if {[catch {set exp [lindex $prefixes [expr round(3 - $logscale)]]}]} {
    set exp ""
  }

  return [format "%6.2f%s" $mantissa $exp]
}


# Parses a string with spice notation into a number.  Trailing units
# are ignored.  Examples: 3.2e-4, 32.4fF, 23 Ohms

proc parse_pp_number {string} {
  regexp -indices -nocase {[a-d]|[f-z]} $string index
  
  if {[info exists index] == 0} {
    return $string
  }

  set mantissa [string range $string 0 [expr [lindex $index 0]-1]]

  set suffixes "GMK munpfa"
  set suffix [string range $string [lindex $index 0] [lindex $index 1]]
  set pos [string first $suffix $suffixes]
  if {$pos == -1} {
    return $mantissa
  }
  set num [expr $mantissa * pow(10,3.0*(3-$pos))]
  return $num
}


# Used by xaxis and yaxis to format labels

proc nst_format_label {graph x} {
  return [pp_number $x]
}


# returns true if numbers are with .1% of eachother

proc close_to {x y} {

  set avg [expr abs($x + $y) / 2.0]
  if {$avg == 0} {
    return 1
  }

  if {[expr abs($x - $y) / $avg] < 0.001} {
    return 1
  }

  return 0
}


# returns minimum of two numbers

proc min {a b} {

  if {$a < $b} {
    return $a

  } else {
    return $b
  }
}


# returns maximum of two numbers

proc max {a b} {

  if {$a > $b} {
    return $a

  } else {
    return $b
  }
}


# cleans up the directory by turning it into an absolute path.

proc clean_dir {dir {pwd ""}} {

  if {$pwd == ""} {
    set pwd [pwd]
  }
  if {[string range $dir 0 2] == "../"} {
    set dir "[file dirname $pwd]/[string range $dir 3 end]"
  } elseif {[string range $dir 0 1] == "./"} {
    set dir "$pwd[string range $dir 2 end]"
  } elseif {[string range $dir 0 1] == "."} {
    set dir "$pwd[string range $dir 1 end]"
  }

  # make a relative path into an absolute path
  if {[string index $dir 0] != "/"} {
    set dir "$pwd/$dir"
  }

  return $dir
}


# sets the nth variable name to be the nth value

proc setl {names values} {
  set i 0
  foreach name $names {
    uplevel [list set $name [lindex $values $i]]
    incr i
  }
  # returns number of variables set
  return $i
}


# called whenever we are about to bog down the cpu so the user doesn`t
# try doing anything.

proc busy {} {

  global nst_graphs

  # my hero!
  foreach win [concat . $nst_graphs] {
    $win configure -cursor {gumby black green}
  }

  update idletasks
}


# we're back!

proc ready {} {

  global nst_graphs

  foreach win [concat . $nst_graphs] {
    $win configure -cursor arrow
  }
}


# Returns the last element of a list

proc nst_last {list} {
  return [lindex $list [expr [llength $list] - 1]]
}


# stolen from bltGraph.tcl

proc Blt_Crosshairs { graph } {
  bind bltCrosshairs <Any-Motion>   {
    %W crosshairs configure -position @%x,%y 
  }

  $graph crosshairs configure -color red

  bind $graph <Enter> [format {
    BltAddBindTag %s bltCrosshairs  
    %s crosshairs on
  } $graph $graph]

  bind $graph <Leave> [format {
    BltRemoveBindTag %s bltCrosshairs  
    %s crosshairs off
  } $graph $graph]
}

proc BltAddBindTag { graph name } {
  set oldtags [bindtags $graph]
  if { [lsearch $oldtags $name] < 0 } {
    bindtags $graph [concat $name $oldtags]
  }
}

proc BltRemoveBindTag { graph name } {
  set tagList {}
  foreach tag [bindtags $graph] {
    if { $tag != $name } {
      lappend tagList $tag
    }
  }
  bindtags $graph $tagList
}


# have some fun

proc nst_fun {} {

  global nst_graphs VERSION done

  # get the center of the screen
  set win [lindex $nst_graphs 0]
  setl {x1 x2} [$win xaxis limits]
  setl {y1 y2} [$win yaxis limits]

  set x [expr ($x2 + $x1) / 2.0]
  set y [expr ($y2 + $y1) / 2.0]

  if [$win marker exists nst_fun] {
    $win marker delete nst_fun
  }

  set done 0

  $win marker create text -coords "$x $y" \
      -text "New SpiceTool -- $VERSION" -name nst_fun \
      -foreground pink -fill "" -font Helvetica-*-2

  set di -20
  set fonts "10 12 14 18 24"
  set fn 0
  set count 0

  # only eat up about a second
  after 800 "set done 1"

  for {set i [expr 360 + $di]} {$i >= 0} {incr i $di} {
    $win marker configure nst_fun \
	-rotate $i \
	-font Helvetica-*-[lindex $fonts $fn]
    update

    if {$count > 4} {
      set count 0
      incr fn
    } else {
      incr count
    }

    if {$done == 1} {
      # butt slow machine, end
      set fn 18
      set i -$di
      set done 0
    }

#    after 10
  }

  after 4000 nst_no_more_fun
}


proc nst_no_more_fun {} {

  global nst_graphs

  # get the center of the screen
  set win [lindex $nst_graphs 0]

  # toast if still around
  if [$win marker exists nst_fun] {
    $win marker delete nst_fun
  }
}



# Called by toplevel windows to change cursors.
# Window is a dialog box window.  Bool is 1 to indicate that the
# specified window is now active, or 0 to indicate that it is inactive.
# Msg is an optional message for the help message area.
# When bool == 0, we restore the previous cursor and active window.

set _CURSOR_STACK ""

proc cursor_wait {window bool {msg {}}} {
    global _CURSOR_STACK nst_graphs

#puts "$window ---> $bool --> $msg"

    if { $bool == 0 } {
	# Dialog box has been destroyed:
	# restore cursor and message for previous active window.
	setl {active_cursor active_msg} [pop _CURSOR_STACK]

	if {$active_msg == ""} {
	  msg_window __DEFAULT__
	} else {
	  msg_window $active_msg
	}

	foreach win $nst_graphs {
	  $win configure -cursor $active_cursor
	}

    } else {
	# Save old cursor, change the cursor for window and add a message
	update

	set active_cursor [lindex [[lindex $nst_graphs 0] configure -cursor] 4]
	push _CURSOR_STACK [list $active_cursor $msg]
	msg_window "?  [lindex [split $msg \n] 0]" message

	foreach win $nst_graphs {
	  $win configure -cursor question_arrow
	}
    }
}


proc warning {msg {title Warning}} {

  # write to warning to screen
  puts $msg

  if {[string length $msg] > 1000} {
    # only show part to the screen
    set msg "[string range $msg 0 900]\n...\n{Too many errors.  See NST command window.}"
  }

  # give user a nice dialog box to play with
  set button [tk_dialog .warning $title $msg \
		  "" 0 {ok}]

  return 1
}


# not clever enough to do this in C.

proc nst_spo_from_split {string} {

  regsub {(_[0-9]+)\.split} $string "" string

  return "[file rootname $string].spo"
}
