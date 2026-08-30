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


# NST procs for deriving new nodes.


# makes a menu for adding derived nodes

proc nst_new_derivation {} {
  global nst_derivation nst_command WIN
  
  set winx [winfo rootx $WIN.mb.derive.menu]
  set winy [expr [winfo rooty $WIN.mb.derive.menu] + \
		[winfo reqheight $WIN.mb.derive.menu]]
  
  toplevel $WIN.new_derive 
  wm geometry $WIN.new_derive "+$winx+$winy"
  wm title $WIN.new_derive "New Derivation"
  
  bind $WIN.new_derive <Visibility> { \
    if {"%s" == "VisibilityFullyObscured" && [grab current] == "$WIN.new_derive"} \
      {raise $WIN.new_derive} \
    }

  frame $WIN.new_derive.buttons
  label $WIN.new_derive.note -text "Enter expression for new node:      " 
  entry $WIN.new_derive.entry -width 40 -textvariable nst_derivation \
      -relief sunken -bd 2 -highlightthickness 1


  frame $WIN.new_derive.default -relief sunken -bd 1
  button $WIN.new_derive.done -text "Done" -command {set nst_command 1} \
      -padx 2 -pady 2
  pack $WIN.new_derive.done -in $WIN.new_derive.default -padx 1m -pady 1m -ipadx 2m
  pack $WIN.new_derive.default -side left -in $WIN.new_derive.buttons \
      -padx 4m -ipadx 1m -pady 1m -expand 1

  button $WIN.new_derive.clear -text "Clear" -command \
      {set nst_derivation ""; $WIN.new_derive.err_msg configure -text ""} \
      -padx 2 -pady 2
  button $WIN.new_derive.cancel -text "Cancel" -command {set nst_command 2} \
      -padx 2 -pady 2
  pack $WIN.new_derive.clear $WIN.new_derive.cancel -side left \
      -in $WIN.new_derive.buttons -padx 4m -ipadx 2m -pady 1m -expand 1
  label $WIN.new_derive.err_msg -text ""
  pack $WIN.new_derive.note $WIN.new_derive.entry $WIN.new_derive.buttons \
      $WIN.new_derive.err_msg -side top -fill x -expand 1
  
  # return causes "done", the default, to fire.
  bind $WIN.new_derive.entry <Return> {set nst_command 1}

  bind $WIN.new_derive <Control-c> {set nst_command 2}
  bind $WIN.new_derive <Escape> {set nst_command 2}

  set old_focus [focus]
  
  set nst_command 0
  while {$nst_command != 2} {

    # change the cursor and add a message
    update

    set windows [winfo children $WIN]
    set pos [lsearch -exact $windows $WIN.new_derive]
    set windows [lreplace $windows $pos $pos]
    set cursor [lindex [[nst_last $windows] configure -cursor] 4]
    foreach window $windows {
      $window configure -cursor question_arrow
    }

    grab set $WIN.new_derive
    $WIN.new_derive.entry icursor end
    focus $WIN.new_derive.entry

    tkwait variable nst_command

    # restore
    foreach window $windows {
      $window configure -cursor $cursor
    }
    
    if {$nst_command == 1} {
      busy
      $WIN.new_derive.err_msg configure -text "Working..."
      update idletasks

      # do it
      if {[catch {nst_derive_node $nst_derivation} result]} {
	# error in derive
      }

      $WIN.new_derive.err_msg configure -text "Done."
      ready

      if {$result == 1} {
	set nst_command 2
      } else {
	global errorInfo
	$WIN.new_derive.err_msg configure -text "Error: [lindex [split $errorInfo \n] 0]"
	set nst_command 0
      }
    }
  }
  
  destroy $WIN.new_derive
  focus $old_focus
}


# Reads an expression of the form: new_var = a + b
# and creates a new node called new_var which has the coords specified
# by the right hand side (rhs) of the expression.
# Takes a mode input of either plot or define

proc nst_derive_node {exp {just_derive ""}} {
  global nst_graphs nst_derived_nodes nst_files nst_datasets WIN nst_datasets
  
  # add spaces around operators
  if {[string first "d/dx" $exp] != -1} {
    # special case for derivative
    regsub -all {([=+*-])} $exp { \1 } exp
  } else {
    regsub -all {([=/+*-])} $exp { \1 } exp
  }

  set list [split $exp =]
  if {[llength $list] != 2} {
    # not of the right form
    return 1
  }
  
  set filename [nst_last $nst_files]

  setl {node expression} $list
  set node [string trim $node]

  set id $nst_datasets($filename,id)
  global nst_nodes_${id}
  if {[info exists nst_nodes_${id}($node)]} {
    # can't redefine a vector that came from a tr0 file
    global errorInfo
    set errorInfo "Can't derive an existing data vector."
    return 0
  }

  # is there a vector for this node name
  if {[lsearch -exact [vector names] $node] == -1} {
    # new vector
    global $node
    vector create $node
  } else {
    # make sure it is unplotted everywhere
    foreach graph $nst_graphs {
      set display_nodes [$graph element show]
      set pos [lsearch -exact $display_nodes $node]
      if {$pos == -1} {
	continue
      }

      $graph element show [lreplace $display_nodes $pos $pos]
  
      if {[$graph element show] == ""} {
	$graph yaxis configure -title ""
      }
    }
  }

  # insure that the x-axis is loaded
  set xdata $nst_datasets($filename,xaxis)$nst_datasets($filename,suffix)
  set xdata [bltify_node_name $xdata]
  nst_get_node_if_needed $filename $nst_datasets($filename,xaxis) $xdata

  switch [lindex $expression 0] {

    "d/dx" {
      # special case, take the derivative
      set vector [nst_get_node_if_needed $filename [lindex $expression 1]]

      if {[lindex $expression 2] == ""} {
	# use x axis
	set x [nst_get_node_if_needed $filename $nst_datasets($filename,xaxis)]

      } else {
	# use argument
	set x [nst_get_node_if_needed $filename [lindex $expression 1]]
      }

      uplevel #0 "$node set \[nst_derivative $vector $x\]"
    }

    "delay" {
      # special case, delay vector
      set vector [nst_get_node_if_needed $filename [lindex $expression 1]]
      set delay [parse_pp_number [join [lrange $expression 2 end] ""]]

      uplevel #0 "$node set \[nst_delay $vector $delay\]"
    }

    "user" {
      # special for user defined functions:
      # format: user <tcl_function> <var1> [<var2>] ...
      set vars ""
      foreach var [lrange $expression 2 end] {
	set new [nst_get_node_if_needed $filename $var]
	if {$new == "Unknown"} {
	  set new $var
	}
	lappend vars $new
      }

      uplevel #0 "$node set \[[lindex $expression 1] $vars\]"
    }

    default {
      # make sure all components of expressions are loaded
      # Note: this will attempt to load a lot of non vectors,
      # like operators.
      set blt_expression ""
      foreach thing $expression {
	set name [nst_get_node_if_needed $filename $thing]
	if {$name == "Unknown"} {
	  lappend blt_expression $thing
	} else {
	  lappend blt_expression $name
	}
      }

      # do the expression
      if {$just_derive != ""} {
	if {[catch {$node expr $blt_expression}]} {
	  # problem
	  return 0
	}
      } else {
	$node expr $blt_expression
      }
    }
  }

  # now plot it
  if {$just_derive == ""} {
    nst_toggle_derive $node
  }

  # add to derive menu if not already there
  set pos [lsearch -exact $nst_derived_nodes $node]
  if {$pos != -1} {
    # must be a redefine, toast old.
    $WIN.mb.derive.menu delete [expr $pos + 3]
    set nst_derived_nodes [lreplace $nst_derived_nodes $pos $pos]
  }

  lappend nst_derived_nodes $node
  menu_add -menu derive -label $exp \
      -command [list nst_toggle_derive $exp] \
      -help "Toggle plotting/unplotting this derived waveform."

  return 1
}


# Tries to plot/unplot derived node by clicking on menu. 
# Gets confused if you change graph focus.

proc nst_toggle_derive {exp} {
  global nst_graphs nst_files nst_derived_nodes nst_datasets

  set node [lindex $exp 0]

  # is there a vector for this node name
  if {[lsearch -exact [vector names] $node] == -1} {
    # must be after a nst_copy or nst_load
    nst_derive_node $exp
    return
  }

  set graph [lindex $nst_graphs 0]
  set filename [nst_last $nst_files]
  
  set xdata $nst_datasets($filename,xaxis)$nst_datasets($filename,suffix)
  set xdata [bltify_node_name $xdata]
  nst_get_node_if_needed $filename $nst_datasets($filename,xaxis) $xdata

  if {[lsearch -exact [$graph element names] $node] == -1} {
    $graph element create $node -xdata $xdata \
	-ydata $node -linewidth 1 -pixels 0 -symbol ""

  } elseif {[lsearch -exact [$graph element show] $node] == -1} {
    $graph element show [concat [$graph element show] $node]
  } else {
    # already plotted, erase
    set display_nodes [$graph element show]
    set pos [lsearch -exact $display_nodes $node]

    $graph element show [lreplace $display_nodes $pos $pos]
  
    if {[$graph element show] == ""} {
      $graph yaxis configure -title ""
    }

    return
  }

  $graph element configure $node -color [nst_next_color]

  # add a command to the legend.  For moving waveforms.
  $graph legend bind $node <ButtonPress-1> \
	"set nst_coord(legend) \{$node\} ; set nst_coord(type) legend ; set nst_coord(filename) __DERIVED__"
  $graph legend bind $node <ButtonPress-2> \
      "set nst_coord(filename) __DERIVED__"
}


# uses forward euler

proc nst_derivative {y x} {

  global DERIVATIVE_OFFSET

  global $x $y

  for {set i 0; set j 1} {$j < [$y length]} {incr i; incr j} {
    set z [expr ([set ${y}($j)]-[set ${y}($i)]) / \
	       ([set ${x}($j)]-[set ${x}($i)]+$DERIVATIVE_OFFSET)]
    lappend vector $z
  }

  # one more for good measure (actually just want this vector to be the
  # same length as the others).
  lappend vector $z

  return $vector
}


# power popup 

proc nst_power_calc {} {

  global nst_power nst_files nst_datasets nst_graphs

  # hack for now
  global cur_c
  set cur_c .nst

  set title "NST Power Calculator"
  set message "Enter info:    "

  set prop_list ""

  set nst_power(w1) [use_first nst_power(w1)]
  lappend prop_list [list "Waveform 1 (Current)" nst_power(w1)]

  set bogus ""
  lappend prop_list [list "" bogus -help "Computes the power by integrating the instantaneous product of the current and voltage waveforms over the range specified by the start and end times and divides by the cycle time.  The default range is taken from the measure box if present."]

  set nst_power(w2) [use_first nst_power(w2) '1]
  lappend prop_list [list "Waveform 2 or constant (Voltage)" nst_power(w2)]

  # get bounds from measure box if there is one
  foreach graph $nst_graphs {
    if [$graph marker exists nst_zoom] {
      setl {x1 y1 x2 y2 x3 y3} [$graph marker cget nst_zoom -coords]
      if {$x1 > $x3} {
	set tmp $x1
	set x1 $x3
	set x3 $tmp
      }

      set nst_power(begin) [pp_number $x1]
      set nst_power(end) [pp_number $x3]
      set nst_power(cycle) [pp_number [expr $x3 - $x1]]

      break
    }
  }

  set nst_power(begin) [use_first nst_power(begin) '0n]
  set nst_power(end) [use_first nst_power(end) '10n]

  lappend prop_list [list "Start Time" nst_power(begin)]
  lappend prop_list [list "End Time" nst_power(end)]

  set cycle [pp_number [expr [parse_pp_number $nst_power(end)] - \
			    [parse_pp_number $nst_power(begin)]]]
  set nst_power(cycle) [use_first nst_power(cycle) cycle]
  lappend prop_list [list "Cycle Time" nst_power(cycle)]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  set filename [nst_last $nst_files]
  set time $nst_datasets($filename,xaxis)$nst_datasets($filename,suffix)
  set time [bltify_node_name $time]
  nst_get_node_if_needed $filename $nst_datasets($filename,xaxis) $time

  set w1 [nst_get_node_if_needed $filename $nst_power(w1)]
  if {$w1 == "Unknown"} {
    # probably a constant
    set w1 $nst_power(w1)
  }

  set w2 [nst_get_node_if_needed $filename $nst_power(w2)]
  if {$w2 == "Unknown"} {
    # probably a constant
    set w2 $nst_power(w2)
  }

  set vector __POWER__
  global $time $vector

  catch "vector destroy $vector"
  vector create $vector

  if {[catch "$vector expr \{$w1 * $w2\}" msg]} {
    warning $msg
    return
  }

  # compute
  if {[catch "nst_integrate $time $vector $nst_power(begin) $nst_power(end)" msg]} {
    warning $msg
    return
  }

  # success
  warning "The power thru the product of waveforms $nst_power(w1) and $nst_power(w2) from $nst_power(begin) to $nst_power(end) is [pp_number [expr $msg / [parse_pp_number $nst_power(cycle)]]]W averaged over a cycle time of $nst_power(cycle)." \
      "Power Calculator"
}


# integrate the vector from start to end times

proc nst_integrate {time vector start end} {

  global $time $vector

  set start [parse_pp_number $start]
  set end [parse_pp_number $end]

  # first need to find the start and end indices in time access
  set len [$time length]
  for {set i 0} {$i < $len} {incr i} {
    if {$start <= [set ${time}($i)]} {
      set starti $i
      break
    }
  }

  for {set i [expr $len - 1]} {$i >= 0} {incr i -1} {
    if {$end >= [set ${time}($i)]} {
      set endi $i
      break
    }
  }

  if {![info exists starti] || ![info exists endi]} {
    return -code error "Error: X-axis bounds out of range."
  }

#  puts "--> $start ( $starti ), $end ( $endi )"
#  puts "--> [set ${time}($starti)] [set ${time}($endi)]"

  if {$starti > $endi} {
    # swap
    set tmp $starti
    set starti $endi
    set endi $tmp
  }

  set sum 0
  for {set i $starti} {$i < $endi} {incr i} {
    set sum [expr $sum + ([set ${time}($i+1)] - [set ${time}($i)]) * \
		 ([set ${vector}($i)] + [set ${vector}($i+1)])]
  }

  # 1/2 factored out of above expression
  set sum [expr 0.5 * $sum]

  # make up for end effects.  Assume vector isn't moving very fast
  set sum [expr $sum + ([set ${time}($starti)] - $start) * \
	       [set ${vector}($starti)]]

  set sum [expr $sum + ($end - [set ${time}($endi)]) * \
	       [set ${vector}($endi)]]

  return $sum
}


# NOT USED

proc diff {x y1 y2 {trip_point 1.125}} {

  global DIFF

  if {$x == 0} {
    set DIFF(oy1) $y1
    set DIFF(oy2) $y2
    set DIFF(xy1) 0
    set DIFF(xy2) 0
    set DIFF(DIFF) 0
  }

  if {($trip_point >= $DIFF(oy1) && $trip_point < $y1) || \
	  ($trip_point <= $DIFF(oy1) && $trip_point > $y1)} {
    set DIFF(diff) [expr $x - $DIFF(xy2)]
    set DIFF(oy1) $y1
    set DIFF(xy1) $x
  }

  if {($trip_point >= $DIFF(oy2) && $trip_point < $y2) || \
	  ($trip_point <= $DIFF(oy2) && $trip_point > $y2)} {
    set DIFF(oy2) $y2
    set DIFF(xy2) $x
  }

  return $DIFF(diff)
}


# delays the waveform by a given amount.  Cannot do negative delays.
# doesn't interpolate

proc nst_delay {y delay} {

  global nst_datasets nst_files DELAY_INTERPOLATION

  set filename [nst_last $nst_files]
  set x [nst_get_node_if_needed $filename $nst_datasets($filename,xaxis)]

  global $x $y

  set value [set ${y}(0)]
  set save [expr [set ${x}(0)] + $delay]

  set DELAY_INTERPOLATION [use_first DELAY_INTERPOLATION '1]

  if {$DELAY_INTERPOLATION == 0 || $DELAY_INTERPOLATION == "false"} {
    # no interpolation
    for {set i 0; set j 0} {$i < [$y length]} {incr i} {
      while {[set ${x}($i)] > $save} {
	set value [set ${y}($j)]

	incr j
	set save [expr [set ${x}($j)] + $delay]
      }

      lappend vector $value
    }
  } else {

    set len [expr [$x length] - 1]

    # interpolation
    for {set i 0; set j 0; set jj 1} {$i < [$y length]} {incr i} {
      set dx [expr [set ${x}($i)] - $save]
      set incx [expr [set ${x}($jj)] - [set ${x}($j)]]
      if {$j > 0} {
	set value [expr ([set ${y}($j)]*($incx-$dx)+[set ${y}($jj)]*$dx)/$incx]
      }

      while {$dx > 0} {
	incr j
	incr jj
	if {$j > $len} {
	  set j $len
	  set jj [expr $len - 1]
	  break
	}

	set save [expr [set ${x}($j)] + $delay]
	set dx [expr [set ${x}($i)] - $save]
      }

      lappend vector $value
    }
  }

  return $vector
}


# generates the piecewise period of the waveform.  Normally the x_var
# is $TIME.  Does not interpolate which would give more accuracy since 
# it already takes forever as tcl is so amazingly slow with numbers.

# NOT USED

proc period {x_var y_var {trip_point 1.125}} {

  global PERIOD

  if {$x_var == 0} {
    set PERIOD(last) $y_var
    set PERIOD(1) 0
    set PERIOD(2) 0
    set PERIOD(period) 0
  }

  if {($trip_point >= $PERIOD(last) && $trip_point < $y_var) || \
	  ($trip_point <= $PERIOD(last) && $trip_point > $y_var)} {
    set PERIOD(period) [expr $x_var - $PERIOD(1)]
    set PERIOD(1) $PERIOD(2)
    set PERIOD(2) $x_var
  }

  set PERIOD(last) $y_var
  return $PERIOD(period)
}


