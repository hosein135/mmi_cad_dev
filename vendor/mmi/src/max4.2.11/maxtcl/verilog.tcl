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

set RCSVERSION(verilog.tcl) { $Revision: 1.3 $ }

set MAX_STRUCT(verilog_module) {name portorder ports supply0 supply1 wires instances flags leaf_cnt leaf_area}
set MAX_STRUCT(verilog_instance) {def_name inst_name connects}

set _VERILOG_OPT(name,VSS) VSS
set _VERILOG_OPT(name,VDD) VDD

proc verilog_find_top {} -desc {
  Return list of top modules in the design hierarchy.
} {
  # Start with a hash table of all modules.

  set mod_list [nl2_list_designs]
  foreach mod $mod_list {
    set top_modules($mod) 1
  }

  # Remove any module that is included in some other module.
  foreach mod $mod_list {
    foreach submod [nl2_list_references $mod] {
      catch {unset top_modules($submod)}
    }
  }

  # And whats left are the top modules.
  return [array names top_modules]
}


proc _verilog_new_hier_fill {} {
  global _VERILOG_HIER_RESULT _VERILOG_OPT
  set win .verilog_hier
  set plist $win.items.list

  if {[$plist size] > 0} {
      $plist delete 0 end
  }

  proc _verilog_new_list_tree2 {{-incl_lef 0} mod level} {
    global _VERILOG_HIER_RESULT
    incr level
    foreach inst [nl2_list_cells $mod] {
      set ref [nl2_get_cell_ref $mod $inst]
      if {$incl_lef || ! [fplan_cell_info -is_lef $ref]} {
	if {[info exists refcnt($ref)]} {
	  incr refcnt($ref)
	} else {
	  set refcnt($ref) 1
	}
      }
    }

    foreach ref [array names refcnt] {
      # Output some space, def name, number of instances.
      lappend _VERILOG_HIER_RESULT \
	  [format "%*s%s #%d" $level " " $ref $refcnt($ref)]
      _verilog_new_list_tree2 -incl_lef $incl_lef $ref $level
    }
  }

  set _VERILOG_HIER_RESULT ""
  #foreach mod [array names _VERILOG_TOP_MODULES]
  foreach mod [verilog_find_top] {
    lappend _VERILOG_HIER_RESULT "$mod"
    _verilog_new_list_tree2 -incl_lef $_VERILOG_OPT(hier_show_lef) $mod 0
  }

  foreach entry $_VERILOG_HIER_RESULT {
    $plist insert end $entry
  }
}

proc verilog_new_hier_menu {} -desc {
  display verilog hierchy from previously read verilog in a listbox
} {
  global _VERILOG_OPT LISTBOX_FONT

  set win .verilog_hier
  set plist $win.items.list

  # If the probe window does not exist, build it.
  catch {destroy $win}

  util_win_create $win "Verilog Hierarchy"

  set font $LISTBOX_FONT; # Just a shorter name for the font

  bind $win <Any-Control-c> "catch {destroy $win}; break"
  bind $win <Escape> "catch {destroy $win}; break"

  label $win.lab1 -text "Total Modules: 0" -font $font
  pack $win.lab1 -side top -fill x
  label $win.lab2 -text "Selected: 0" -font $font
  pack $win.lab2 -side top -fill x


  # Create a frame for the selected items.
  frame $win.items

  scrollbar $win.items.vscroll \
	  -relief raised \
	  -command "$win.items.list yview"

  listbox $win.items.list \
	  -font $font \
	  -exportselection false \
	  -selectmode multiple \
	  -relief raised \
	  -yscrollcommand "$win.items.vscroll set"

  # The break is necessary to keep the listbox from processing
  # the mouse buttons after we are done with them.
  bind $plist <Button-1> { \
	  _verilog_hier_button %x %y Button-1;break}
  bind $plist <Button-2> { \
	  _verilog_hier_button %x %y Button-2; break }

  # pack the list and scrollbars
  pack $win.items.vscroll -side right -fill y
  pack $win.items.list -side left -fill both -expand 1
  pack $win.items -expand 1 -fill both

  #button $win.clear -text "Clear Selection" -padx 3 -pady 3 \
  #  -command "$plist selection clear 0 end"
  #pack $win.clear -side top -fill x -expand 1

  #button $win.select_n -text "Select N Levels..." -padx 3 -pady 3 \
  #  -command  "_verilog_hier_cmd select_n"
  #pack $win.select_n -side top -fill x -expand 1

  set _VERILOG_OPT(hier_show_lef) 0
  checkbutton $win.lef -text "Show LEF cells" -padx 3 -pady 3 \
    -variable _VERILOG_OPT(hier_show_lef) \
    -command "_verilog_new_hier_fill"
  pack $win.lef -side top -fill x -expand 1

  button $win.editver -text "View Verilog Text" -padx 3 -pady 3 \
    -command "_verilog_hier_cmd edit"
  pack $win.editver -side top -fill x -expand 1

  #button $win.load -text "Import Verilog to Floorplan" -padx 3 -pady 3 \
  #  -command "_verilog_hier_cmd load"
  #pack $win.load -side top -fill x -expand 1

  #button $win.new -text "Read addition Verilog File" -padx 3 -pady 3 \
  #  -command "_verilog_hier_cmd new"
  #pack $win.new -side top -fill x -expand 1

  set helpmsg {Module names are shown indented by their hierarchical \
    level, and followed by the number appearing at that level.\
    Button-1 selects tree starting at selected module.\
    Button-2 selects just the individual module.}

  # Buttons
  frame $win.buttons

  button $win.done -text "Close" -padx 1 -pady 2 \
    -command "catch {destroy $win}"
  button $win.help -text "Help" -padx 1 -pady 2 \
    -command [list prop_dialog -title {Selection Probe Help} $helpmsg]

  pack $win.done $win.help -side left \
    -in $win.buttons -padx 1m -ipadx 1m -pady 1m
  pack $win.buttons -side bottom

  util_win_finish $win -place normal

  # Now fill it with goob
  _verilog_new_hier_fill

  set old_grab [grab current]
  grab set $win
  cursor_wait $win 1 "Probe"
  tkwait window $win
  #update idletasks
  if {$old_grab != ""} {
    grab set [lindex $old_grab 0]
  } else {
    grab release $win
  }
  cursor_wait $win 0
}

proc UNUSED_verilog_hier_menu {{verfile ""}} -desc {
  display verilog hierchy from file verfile in a listbox
} {
    global _VERILOG_OPT LISTBOX_FONT

    if {$verfile == ""} {
      set verfile [fs_box -message "New verilog file:" -pattern "*.v *.vg *.vh"]
      if {$verfile ==""} {
	# cancelled
	return
      }
    }
    if {![file readable $verfile]} {
      error "File $verfile not found"
    }

    set _VERILOG_OPT(filename) $verfile

    set win .verilog_hier
    set plist $win.items.list

    catch {destroy $win}

    util_win_create $win "Verilog Hierarchy"

    set font $LISTBOX_FONT; # Just a shorter name for the font

    bind $win <Any-Control-c> "catch {destroy $win}; break"
    bind $win <Escape> "catch {destroy $win}; break"

    #grab set $win
    #cursor_wait $win 1 "Probe"
    #tkwait variable _PROP_RETURN
    #cursor_wait $win 0

    # This may be changed later if a new file is loaded.
    label $win.title -text "File: $_VERILOG_OPT(filename)" -font $font
    pack $win.title -side top -fill x

    label $win.lab1 -text "Total Modules: 0" -font $font
    pack $win.lab1 -side top -fill x
    label $win.lab2 -text "Selected: 0" -font $font
    pack $win.lab2 -side top -fill x


    # Create a frame for the selected items.
    frame $win.items

    scrollbar $win.items.vscroll \
	    -relief raised \
	    -command "$win.items.list yview"

    listbox $win.items.list \
	    -font $font \
	    -exportselection false \
	    -selectmode multiple \
	    -relief raised \
	    -yscrollcommand "$win.items.vscroll set"

    # The break is necessary to keep the listbox from processing
    # the mouse buttons after we are done with them.
    bind $plist <Button-1> { \
	    _verilog_hier_button %x %y Button-1;break}
    bind $plist <Button-2> { \
	    _verilog_hier_button %x %y Button-2; break }

    # pack the list and scrollbars
    pack $win.items.vscroll -side right -fill y
    pack $win.items.list -side left -fill both -expand 1
    pack $win.items -expand 1 -fill both

    button $win.clear -text "Clear Selection" -padx 3 -pady 3 \
      -command "$plist selection clear 0 end"
    pack $win.clear -side top -fill x -expand 1

    button $win.select_n -text "Select N Levels..." -padx 3 -pady 3 \
      -command  "_verilog_hier_cmd select_n"
    pack $win.select_n -side top -fill x -expand 1

    button $win.editver -text "Edit Verilog Text" -padx 3 -pady 3 \
      -command "_verilog_hier_cmd edit"
    pack $win.editver -side top -fill x -expand 1

    #button $win.load -text "Import Verilog to Floorplan" -padx 3 -pady 3 \
    #  -command "_verilog_hier_cmd load"
    #pack $win.load -side top -fill x -expand 1

    button $win.new -text "Select New Verilog File" -padx 3 -pady 3 \
      -command "_verilog_hier_cmd new"
    pack $win.new -side top -fill x -expand 1

    set helpmsg {Module names are shown indented by their hierarchical \
      level, and followed by the number appearing at that level.\
      Button-1 selects tree starting at selected module.\
      Button-2 selects just the individual module.}

    # Buttons
    frame $win.buttons

    button $win.done -text "Close" -padx 1 -pady 2 \
      -command "catch {destroy $win}"
    button $win.help -text "Help" -padx 1 -pady 2 \
      -command [list prop_dialog -title {Selection Probe Help} $helpmsg]

    pack $win.done $win.help -side left \
      -in $win.buttons -padx 1m -ipadx 1m -pady 1m
    pack $win.buttons -side bottom

    util_win_finish $win

    # Now fill it with goob
    # clear old list (unnecessary)
    if {[$plist size] > 0} {
	$plist delete 0 end
    }

    if {$verfile != ""} {
      set tree [verilog_get_tree $verfile]
      foreach entry $tree {
	$plist insert end $entry
      }
    }

    return $win
}

proc _verilog_hier_cmd {cmd} {
  global _VERILOG_OPT
  set win .verilog_hier
  set plist $win.items.list
  switch $cmd {
    "select_n" {
      set _VERILOG_OPT(levels) [use_first _VERILOG_OPT(levels) '1]
      set prop_list {{"N levels" _VERILOG_OPT(levels) -number 1}}
      set msg "Number of levels to select, starting from top"
      set ret [prop_menu2 -message $msg $prop_list]
      if {$ret == 0} {return}
      $plist selection clear 0 end
      set size [$plist size]
      for {set n 0} {$n < $size} {incr n} {
	set line [$plist get $n]
	set thislevel [expr [string length $line] - \
	  [string length [string trimleft $line]]]
	if {$thislevel < $_VERILOG_OPT(levels)} {
	  $plist selection set $n
	}
      }
    }
    "new" {
      # Note: This does not work with verilog_new_hier_menu
      set newfile [fs_box -message "New verilog file:" -pattern "*.v *.vg *.vh"]
      if {$newfile == ""} {return}
      set _VERILOG_OPT(filename) $newfile
      $win.title config -text "File: $_VERILOG_OPT(filename)"
      # clear old list (unnecessary)
      if {[$plist size] > 0} {
	  $plist delete 0 end
      }
      set tree [verilog_get_tree $_VERILOG_OPT(filename)]
      foreach entry $tree {
	$plist insert end $entry
      }
    }
    "load" {
      TODO
      # Must make sure there are no orphans.
      # First, find the top level selection, and throw
      # everything above it (them) away.
      # Then if a line is selected, its parent must also be selected.
      # Another way to do it:  throw away unselected lines,
      # then each line may be only one level deeper than preceding line.
    }
    "edit" {
      # Create an awk command to grep out just the selected modules
      # To get comments preceding a module, save lines between
      # /endmodule/ and /module/ in variable c.
      set awkcmd ""
      set sellist [$plist curselection]
      if {[llength $sellist] == 0} {
	error "nothing selected"
      }
      foreach nsel $sellist {
	set line [$plist get $nsel]
	set modname [string trim $line]
	regsub { .*} $modname "" modname
	append awkcmd "/^ *module  *$modname /,/^ *endmodule/{\
	  if (c!=null)print c;print}\n"
      }

      # Finish up the awk commnd.
      append awkcmd "/^ *module/ {c=null;flag=0;next}\n"
      append awkcmd "/^ *endmodule/ {flag=1;next}\n"
      append awkcmd "flag!=0{c=c ORS \$0}\n"

      # Use nawk, if found, because it is better.
      set tmpfile /tmp/verilog[pid].tmp
      #if {[catch {exec nawk $awkcmd $filename > $tmpfile}]} 

      exec awk $awkcmd $_VERILOG_OPT(filename) > $tmpfile

      misc_text_edit $tmpfile
      file delete $tmpfile
      return

      if {0} {
	# Note: The following works, but we lose any verilog comments
	# preceding the module.
	# Create an sed command to grep out just the selected verilog modules
	set sedcmd ""
	foreach nsel [$plist curselection] {
	  set line [$plist get $nsel]
	  set modname [string trim $line]
	  append sedcmd "/module $modname/,/endmodule/p\n"
	}
	if {$sedcmd == ""} {
	  error "Must select verilog module from listbox first"
	}
	set tmpfile /tmp/verilog[pid].tmp
	exec sed -n $sedcmd $_VERILOG_OPT(filename) > $tmpfile
      }
      misc_text_edit $tmpfile
      file delete $tmpfile
    }
  }

  $win.lab1 config -text "Total Modules: [$plist size]"
  $win.lab2 config -text "Selected: [llength [$plist curselection]]"
}

proc _verilog_hier_button {lx ly action} -desc {
    Select item number at y window coord x,y in the verilog list.
} {
  set win .verilog_hier
  set plist $win.items.list
  set n [$plist index @$lx,$ly]

  # Toggle the selection.
  switch $action {
    "Button-2" {
      # Toggle just this one entry.
      if { [$plist selection includes $n] } {
	  $plist selection clear $n
      } else {
	  $plist selection set $n
      }
    }
    "Button-1" {
      # Toggle selection and its sub-tree
      if { [$plist selection includes $n] } {
	  set op clear
      } else {
	  set op set
      }
      # Mark the selected line
      $plist selection $op $n
      # count the leading white space from this selection
      set line [$plist get $n]
      set level [expr [string length $line] - \
      	[string length [string trimleft $line]]]
      regexp {^ *} $line junk space
      # Mark the entire subtree
      # Keep going while the leading white-space is greater.
      set size [$plist size]
      for {incr n} {$n < $size} {incr n} {
	set line [$plist get $n]
	set thislevel [expr [string length $line] - \
	  [string length [string trimleft $line]]]
	if {$thislevel <= $level} {break}
	$plist selection $op $n
      }
    }
  }
  $win.lab1 config -text "Total Modules: [$plist size]"
  $win.lab2 config -text "Selected: [llength [$plist curselection]]"
}

proc _verilog_line {fd} -desc {
  read next line from verilog file
} {
  global _VERILOG
  if {[info exists _VERILOG(unget)]} {
    set line $_VERILOG(unget)
    unset _VERILOG(unget)
    return $line
  }
  incr _VERILOG(lineno)
  return [gets $fd]
}

proc _verilog_peek {fd} {
  global _VERILOG
  if {![info exists _VERILOG(unget)]} {
    set _VERILOG(unget) [_verilog_line $fd]
  }
  return $_VERILOG(unget)
}


proc _verilog_skip {fd num {level 0}} -doc {
  Skip over unwanted junk in verilog textualized file.
} {
  for {} {$num > 0} {incr num -1} {
    set nn [lindex [_verilog_line $fd] 1]
    if {$nn != 0} {
      #puts "_verilog_skip $junk $nn $level"
      _verilog_skip $fd $nn [expr $level+1]
    }
  }
}

proc _verilog_opt_range {fd} {
  setl {keyword cnt} [_verilog_peek $fd]
  if {$keyword == "range"} {
    _verilog_line $fd
    if {$cnt == 1} {
      set num1 [_verilog_num $fd]
      set num2 $num1
    } elseif {$cnt == 2} {
      set num1 [_verilog_num $fd]
      set num2 [_verilog_num $fd]
    } else {
      error "unrecognized bit range"
    }
    return [list $num1 $num2]
  } else {
    return [list -1 -1]  ;# Indicates no range
  }
}

proc _verilog_word {string nth} -desc {
  Return nth space-separated word from string
} {
  if {[string first "  " $string]>=0 || [string first "\t" $string]>=0} {
    regsub -all {[ 	]+} $string " " string
  }
  return [lindex [split $string " "] $nth]
}

proc _verilog_id {fd} {
  # If the verilog identifier contains backslashes, lindex massacres it,
  # so use space-separated words instead.
  return [_verilog_word [_verilog_line $fd] 2]
}

proc _verilog_num {fd} {
  # Speed this up
  #setl {keyword subcnt number junk} [_verilog_line $fd]
  #assert {$keyword == "num" && $subcnt == 0}
  #return $number
  return [lindex [_verilog_line $fd] 2]
}

proc _verilog_flatten_range {id num1 num2} -desc {
  Return a list of single bit wires.
} {
  if {$num1 == $num2} {
    # Special case: If range is [-1,-1], it means it was not a bitrange
    # at all, just a normal non-bus id.
    #return [list [list $id $num1]]
    if {$num1 == -1} {
      return [list $id]
    } else {
      return [list "$id\[$num1\]"]
    }
  }
  # Flatten the range.
  set bitlist ""
  if {$num1 < $num2} {
    for {set i $num1} {$i <= $num2} {incr i} {
      #lappend bitlist [list $id $i]
      lappend bitlist "$id\[$i\]"
    }
  } else {
    for {set i $num1} {$i >= $num2} {incr i -1} {
      #lappend bitlist [list $id $i]
      lappend bitlist "$id\[$i\]"
    }
  }
  return $bitlist
}

proc _verilog_exp_flat {fd} -desc {
  Read in a list of single bit signals for verilog file pin connection.
} {
  set wire_list ""
  # Next thing could be an id, a bit, or a concat.
  setl {keyword cnt id} [_verilog_line $fd]
  switch $keyword {
    "id" {
      assert {$cnt == 0}
      #return [list [list $id 1]]
      return "$id"
    }
    "bit" {
      assert {$cnt == 2}
      set id [_verilog_id $fd]
      set num [_verilog_num $fd]
      #return [list [list $id $num]]
      return "$id\[$num\]"
    }
    "range" {
      assert {$cnt == 3}
      set id [_verilog_id $fd]
      set num1 [_verilog_num $fd]
      set num2 [_verilog_num $fd]
      return [_verilog_flatten_range $id $num1 $num2]
    }
    "concat" {
      set bitlist ""
      for {} {$cnt > 0} {incr cnt -1} {
	set bitlist [concat $bitlist [_verilog_exp_flat $fd]]
      }
      return $bitlist
    }
    "num" {
      # Instance is connected to a number, ie, its tied off to Vss/Vdd.
      global _VERILOG_OPT
      set number $id  ;# Its a number, not an id.
      return [expr {$number == 0 ? $_VERILOG_OPT(name,VSS) : $_VERILOG_OPT(name,VDD)}]
    }
    default {
      error "unrecognized instance connection: $keyword"
    }
  }
}


proc verilog_view_selected {} {
  global _VERILOG_OPT
  set cellid [_fplan_ask_cell "view verilog"]
  if {$cellid == ""} {return}

  set cell [cell_id2cell $cellid]

  set modname [fplan_db_cell module $cell]
  set filename [use_first _VERILOG_OPT(filename)]
  if {$filename == ""} {
    error "No verilog file has been read in?"
  }
  msg "Editing module $modname in file $filename...\n"
  exec sed -n "/module $modname/,/endmodule/p" < $filename > $filename.v.tmp
  misc_text_edit $filename.v.tmp
}


proc verilog_get_tree {{-incl_lef 0} filename} {
  msg "Scanning verilog file $filename\n"

  # This command takes out everything but the module and instance
  # statements from the verilog parser output, so it can be scanned
  # very rapidly. We return lines containing module, and the next line,
  # and lines containing instance, and the second line after.
  set sedcmd "/^module /{N;p;}\n/^instances /{N;N;N;p;}"
  set cmd [list |verilog_parser $filename | sed -n $sedcmd]

  #set fd [open $cmd "r"]
  #while {![eof $fd]} {
  #  puts line=[gets $fd]
  #}
  #close $fd

  set fd [open $cmd "r"]
  set cur_mod ""
  set cnt 1

  while {1} {
    set line [gets $fd]
    switch [lindex $line 0] {
      "module" {
	set cur_mod [lindex [gets $fd] 2]
	set toplevel($cur_mod) 1
	incr cnt
	if {$cnt % 10 == 0} {
	  puts -nonewline "modules read: $cnt \r"
	  flush "stdout"
	}
      }
      "instances" {
	set def [lindex [gets $fd] 2]    ;# The sub-module def name
	gets $fd                         ;# Discard "instance <cnt>"
	set id [lindex [gets $fd] 2]     ;# The sub-module id
	#lappend modules($cur_mod) $id
	catch {unset toplevel($def)}

	#global _FPLAN_MODULES
	#if {[info exists _FPLAN_MODULES($def)]} {
	#  setl {type xsize ysize} $_FPLAN_MODULES($def)
	#  if {$type == "lef"} {
	#    # This is a leaf lef cell.  Do not show it in hierarchy.
	#    continue
	#  }
	#}
	if {$incl_lef || ! [fplan_cell_info -is_lef $def]} {
	  if {[info exists vinstances($cur_mod,$def)]} {
	    incr vinstances($cur_mod,$def)
	  } else {
	    set vinstances($cur_mod,$def) 1
	  }
	}
      }
      "" {
	if {[eof $fd]} {break}
      }
      default {
	error "Hierarchy parsing error at $line"
      }
    }
  }
  close $fd
  puts "\ndone"

  msg "Top level cells are: [array names toplevel]\n"

  global _VERILOG_HIER_RESULT
  set _VERILOG_HIER_RESULT ""
  foreach mod [array names toplevel] {
    lappend _VERILOG_HIER_RESULT "$mod"
    _verilog_list_tree2 $mod 0
  }
  return $_VERILOG_HIER_RESULT
}

proc _verilog_list_tree2 {mod level} {
  global _VERILOG_HIER_RESULT
  upvar vinstances vinstances
  incr level
  foreach thing [array names vinstances $mod,*] {
    regsub {^[^,]*,} $thing "" def
    # Output some space, def name, number of instances.
    lappend _VERILOG_HIER_RESULT \
    	[format "%*s%s #%d" $level " " $def $vinstances($thing)]
    _verilog_list_tree2 $def $level
  }
}


proc _verilog_read {filename {modname ""}} -desc {
  Read structure verilog from filename.  Output left in global _VERILOG_MODULES
} -doc {
  If <modname> given, read only that module.  Runs faster.
  Return a list of the top-level module names.
} {
  global _VERILOG_OPT _VERILOG_MODULES _VERILOG_TOP_MODULES _VERILOG
  catch {unset _VERILOG_MODULES}
  catch {unset _VERILOG_WIRES}

  # Run verilog_parser to convert verilog to ascii text.
  # Open it as a pipe.
  if {$modname == ""} {
    set cmd "|verilog_parser $filename"
  } else {
    set cmd "|sed -n \"/module $modname/,/endmodule/p\" < $filename | verilog_parser"
  }
  set fd [open $cmd "r"]
  set _VERILOG(lineno) 0

  set _VERILOG_OPT(filename) $filename

  # As we read in the modules, the _VERILOG_TOP_MODULES array tracks which
  # modules are top-level modules, ie, no one uses them.

  while {1} {
    setl {keyword mcnt} [_verilog_line $fd]
    if {$keyword == "" && [eof $fd]} {break}

    if {$keyword == "module"} {
      # Get module name (required)
      set m.name [_verilog_id $fd]
      puts "reading verilog module ${m.name}"
      set _VERILOG_TOP_MODULES(${m.name}) 1
      incr mcnt -1

      # Try skipping modules we dont want, for speed.
      # This works, but doesnt speed us up much.
      #if {$modname != "" && ${m.name} != $modname} {
      #	_verilog_skip $fd $mcnt
      #	continue
      #}

      # We have a module def.  Read it in.

      set m.portorder ""
      set m.ports ""
      set m.supply0 ""
      set m.supply1 ""
      set m.wires ""
      set m.instances ""
      set m.flags ""
      set m.leaf_cnt 0    ;# Number of lef leaf cells encountered and skipped.
      set m.leaf_area 0   ;# Total area of all leaf cells.

      # Read in the module contents.
      for {} {$mcnt > 0} {incr mcnt -1} {
	setl {keyword newcnt} [_verilog_line $fd]
	switch $keyword {
	  "portorder" {
	    for {set i 0} {$i < $newcnt} {incr i} {
	      lappend m.portorder [_verilog_id $fd]
	    }
	  }
	  "supply0" {
	    for {set i 0} {$i < $newcnt} {incr i} {
	      lappend m.supply0 [_verilog_id $fd]
	    }
	  }
	  "supply1" {
	    for {set i 0} {$i < $newcnt} {incr i} {
	      lappend m.supply1 [_verilog_id $fd]
	    }
	  }
	  "output" -
	  "inout" -
	  "input" {
	    if {[lindex [_verilog_peek $fd] 0] == "range"} {
	      incr newcnt -1
	    }
	    setl {num1 num2} [_verilog_opt_range $fd]
	    for {set i 0} {$i < $newcnt} {incr i} {
	      set id [_verilog_id $fd]
	      lappend m.ports [list $id $num1 $num2 $keyword]
	    }
	    set _VERILOG_WIRES(${m.name},$id) [list $num1 $num2]
	  }
	  "wire" {
	    # TODO: make this look like input, above.
	    if {[lindex [_verilog_peek $fd] 0] == "range"} {
	      incr newcnt -1
	    }
	    setl {num1 num2} [_verilog_opt_range $fd]
	    for {set i 0} {$i < $newcnt} {incr i} {
	      set id [_verilog_id $fd]
	      lappend m.wires [list $id $num1 $num2]
	    }
	    set _VERILOG_WIRES(${m.name},$id) [list $num1 $num2]
	  }
	  "instances" {
	    if {$newcnt != 2} {
	      # We dont support any other kind of instance.
	      error "Only one instance can be used at a time"
	    }

	    # Get the instance def names and instance names.
	    set mod_def_name [_verilog_id $fd]
	    catch {unset _VERILOG_TOP_MODULES($mod_def_name)}
	    setl {subkey icnt} [_verilog_line $fd]
	    assert {$subkey == "instance"}
	    set mod_inst_name [_verilog_id $fd]
	    incr icnt -1

	    # Read in the instance port connections.
	    set connects ""
	    for {} {$icnt > 0} {incr icnt -1} {
	      setl {subkey cnt} [_verilog_line $fd]
	      assert {$subkey == "dot" && $cnt == 2}
	      set portid [_verilog_id $fd]
	      # Next thing could be an id, a bit, or a concat.
	      set bitlist [_verilog_exp_flat $fd]
	      lappend connects [list $portid $bitlist]
	    }

	    # We want the stdcells in the netlist.
	    # What we dont want is to try to instantiate their contents on import.
	    #global _FPLAN_MODULES
	    #if {[info exists _FPLAN_MODULES($mod_def_name)]} {
	    #  setl {type xsize ysize} $_FPLAN_MODULES($mod_def_name)
	    #  if {$type == "lef"} {
	    #	# This is a leaf cell: stdcell or hard macro.
	    #	# It will be auto-placed, so do not read it into the hierarchy.
	    #	set m.leaf_cnt [expr ${m.leaf_cnt} + 1]
	    #	set m.leaf_area [expr ${m.leaf_area} + $xsize * $ysize]
	    #	continue
	    #  }
	    #}

	    set mi.def_name $mod_def_name
	    set mi.inst_name $mod_inst_name
	    set mi.connects $connects
	    lappend m.instances [destruct verilog_instance mi]
	    # Create redundant hash to quickly map mod inst name to def name.
	    # Otherwise we would have to plow through all the mi structs to find it.
	    # set _VERILOG_MODIMAP(${m.name},$mod_inst_name) $mod_def_name
	  }
	  default {
	    puts "Verilog: inside module: line $_VERILOG(lineno) skipping unrecognized: $keyword"
	    _verilog_skip $fd $newcnt
	  }
	}
      }
      set _VERILOG_MODULES(${m.name}) [destruct verilog_module m]

    } else {
      puts "Verilog: line $_VERILOG(lineno) skipping unrecognized: $keyword"
      _verilog_skip $fd $mcnt
    }
  }

  close $fd
  file delete $filename.out.tmp
}

proc verilog_hier_char {} -desc {
  Return the current verilog hierarchy separator char.
} -doc {
  This is the char we use internal to this tool to indicate
  hierarchy in verilog.  Cant use / because it is inserted
  in instance and pin names by synopsis if user groups/ungroups
  the modules.  Dot is safe because it is illegal in instance and net
  names in verilog.
} {
  return "."
}


proc verilog_make_maps {} -doc {
  When not using the nl database,
  call this after reading in all verilog files.

  It always maps all single bit nets.
  If nlt_init_aggregate was called before this routine,
  we also map aggregated busses.

  Init _VERILOG_PORT_MAP and _VERILOG_NET_MAP to enable us to
  query the verilog connectivity.
  _VERILOG_NET_MAP maps (module,netname) to a list of ports
  connected to the net, which include submodule/port and
  top level port names with no slash.
  _VERILOG_PORT_MAP is the reverse map:
  maps (module,sub_module_inst_name,portid) to netname.
} {

  global _VERILOG_MODULES _VERILOG_PORT_MAP _VERILOG_NET_MAP
  catch {unset _VERILOG_NET_MAP}
  catch {unset _VERILOG_PORT_MAP}

  set hch [verilog_hier_char]

  foreach mod [array names _VERILOG_MODULES] {
    set bus_aggregated [nlt_agg_ok $mod]
    puts "processing connectivity for $mod"
    # Create a hash table to map net connectivity in this verilog module.
    struct verilog_module m $_VERILOG_MODULES($mod)

    # First add in the top-level ports.
    # In verilog, the netname attached to a top-level port is
    # identical to the portname.
    foreach port_info ${m.ports} {
      setl {id n1 n2 iotype} $port_info
      foreach net [_verilog_flatten_range $id $n1 $n2] {
	lappend _VERILOG_NET_MAP($mod,$net) $net
	if {$n1 != $n2 && $bus_aggregated} {
	  set netbus [nlt_bus $mod $net]
	  if {$netbus != ""} {
	    lappend _VERILOG_NET_MAP($mod,$netbus) $netbus
	  }
	}
      }
    }

    # Add in connections in each instance.
    foreach vinst ${m.instances} {
      struct verilog_instance mi $vinst
      foreach connect_list ${mi.connects} {
	setl {portid bitlist} $connect_list
	if {[llength $bitlist] == 1} {
	    set bit [lindex $bitlist 0]
	    lappend _VERILOG_NET_MAP($mod,$bit) ${mi.inst_name}${hch}$portid
	    # Make a map for nl2_get_pin_net(cell,port)
	    set _VERILOG_PORT_MAP($mod,${mi.inst_name},$portid) $bit
	} else {
	  set i 0  ;# Assume all ranges start at 0!!!!!
	  foreach bit $bitlist {
	    set portbit "$portid\[$i\]"
	    lappend _VERILOG_NET_MAP($mod,$bit) ${mi.inst_name}${hch}$portbit
	    set _VERILOG_PORT_MAP($mod,${mi.inst_name},$portbit) $bit
	    incr i
	  }

	  # Now look for aggregated buses.
	  if {$bus_aggregated} {
	    foreach bit $bitlist {
	      set netbus [nlt_bus $mod $bit]
  #puts "mod=$mod bit=$bit netbus=$netbus bitlist=$bitlist"
	      if {$netbus != ""} {
		# We have found an aggregated bus.
		# It could be any subset of the full bus.
		# Determine which indicies of the port are connected
		# to these bits of the net bus.
		# netbusinds are the indicies of the bus net.
		set netbusinds [nlt_list_explode [nlt_bus_get_spec $netbus]]
		if {[llength $netbusinds] == 1} {
		  # Guess it wasnt an aggregated bus after all.
		  continue
		}
		# Cons is the ordered list of connected indicies in port.
		set cons ""
		foreach ind $netbusinds {
		  set portbit [lindex $bitlist $ind]
		  # The portbit will be null if the net bus is larger
		  # than the port bus, which happens if you dont run
		  # the exact aggregation code.
		  if {$portbit != ""} {
		    lappend cons [nlt_bus_get_spec [lindex $bitlist $ind]]
		  }
		}
  #puts cons=$cons
		# All these bits have the same port name.
		set portbus "$portid\[[nlt_list_compress $cons]\]"

  #puts "netbus=$netbus portbus=$portbus"

		lappend _VERILOG_NET_MAP($mod,$netbus) ${mi.inst_name}${hch}$portbus
		set _VERILOG_PORT_MAP($mod,${mi.inst_name},$portbus) $netbus
	      }
	    }
	  }
	}
      }
    }
  }
}


proc nl2_list_designs {} {
  global FPLAN _VERILOG_MODULES
  if {$FPLAN(use_nl_shell)} {
    util_load_pkg nl_shell.so
    set designs [nl_list_designs]

    # Remove the __DUMMY__ design
    set i [lsearch $designs __DUMMY__]
    if {$i >= 0} {
      set designs [lreplace $designs $i $i]
    }
    return $designs
  }

  return [array names _VERILOG_MODULES]
}

proc nl2_get_cell_ref {mod inst} -desc {
  Argument is not a max cell, it is the verilog module name.
} {
  global FPLAN _VERILOG_MODULES MAX_STRUCT
  if {$FPLAN(use_nl_shell)} {
    set nlcell [nl2_find_cell $mod $inst]
    return [nl_get_cell_reference $nlcell]
  }
  struct verilog_module m $_VERILOG_MODULES($mod)
  # Search using lsearch2, which is faster than going through
  # the list of instances in tcl with foreach.
  set sub_index [lsearch $MAX_STRUCT(verilog_instance) "inst_name"]
  set value [lsearch2 -value -index $sub_index ${m.instances} $inst]
  if {$value != ""} {
    struct verilog_instance mi $value
    return ${mi.def_name}
  } else {
    return ""
  }
}

proc nl2_list_references {mod} {
  global FPLAN _VERILOG_MODULES
  if {$FPLAN(use_nl_shell)} {
    # nl_list_references fails if the module definition was not read in.
    set ret ""
    catch {set ret [nl_list_references $mod]} junk
    return $ret
  }

  if {![info exists _VERILOG_MODULES($mod)]} {
    # Its was a leaf instance, no def exists.
    return ""
  }

  struct verilog_module m $_VERILOG_MODULES($mod)

  foreach thing ${m.instances} {
    struct verilog_instance mi $thing
    set list(${mi.def_name}) 0
  }
  return [array names list]
}

proc nl2_list_cells {{-hierarchy} mod} {
  global FPLAN _VERILOG_MODULES
  if {$FPLAN(use_nl_shell)} {
    set cmd "nl_list_cells"
    if {$hierarchy} {lappend cmd -hierarchy}
    lappend cmd $mod
    if {[catch $cmd ret]} {return ""}

    if {$ret == ""} {return ""}

    set submod_list ""
    foreach submod $ret {
      if {[string first "*" $submod] == 0} {
	# This is a *process* or *expression* dummy module
	# created for RTL verilog.
	continue
      } else {
	lappend submod_list $submod
      }
    }
    return $submod_list
  }

  if {![info exists _VERILOG_MODULES($mod)]} {
    # Its was a leaf instance, no def exists.
    return ""
  }
  struct verilog_module m $_VERILOG_MODULES($mod)

  set list ""
  foreach thing ${m.instances} {
    struct verilog_instance mi $thing
    lappend list ${mi.inst_name}
  }
  return $list
}


# 2/14/01: The nl_shell.so was crashing.  In order to test floorplan,
# create stub routines with same functionality,
# assuming that ports are always hooked to nets with same name.
proc nl2_list_nets {{-bus 0} mod} -doc {
  If -bus 1, return aggregated bus names.
} {
  global FPLAN _VERILOG_MODULES

  if {$FPLAN(use_nl_shell)} {return [nl_list_nets -noconstant $mod]}

  struct verilog_module m $_VERILOG_MODULES($mod)
  set wire_list ""
  foreach thing [concat ${m.ports} ${m.wires}] {
    setl {name range_hi range_lo iotype} $thing
    foreach bit [_verilog_flatten_range $name $range_lo $range_hi] {
      lappend wire_list $bit
    }
  }

  if {$bus} {
    set result ""
    foreach bit $wire_list {
      set bus_name [nlt_bus $mod $bit]
      if {$bus_name != ""} {
	lappend result $bus_name
      }
    }
    return $result
  } else {
    return $wire_list
  }
}

proc nl2_list_ports {{-bus 0} {-incl_kind 0} mod} -desc {
  Get pins on the specifed module.
} -doc {
  Note: argument is NOT a max cell, its a verilog module def name.
  If -incl_kind 1, return list of {port iotype}
} {
  global FPLAN _VERILOG_MODULES

  # The verilog data-base knows nothing about the pin names on LEF cells.
  # We read lef as a separate step, and save the pin names for this purpose.
  if {[fplan_cell_info -is_lef $mod]} {
    setl {type xsize ysize pin_info} [fplan_cell_info -get $mod]
    if {$incl_kind} {
      return $pin_info
    } else {
      set pinnames ""
      foreach thing $pin_info {
	lappend pinnames [lindex $thing 0]
      }
      return $pinnames
    }
  }

  if {$FPLAN(use_nl_shell)} {
    #global nl_current_design
    assert {$bus == 0}
    #set nl_current_design $mod
    if {$incl_kind} {
      set portlist ""
      foreach aport [nl_list_ports -inputs $mod] {
	lappend portlist [list $aport input]
      }
      foreach aport [nl_list_ports -outputs $mod] {
	lappend portlist [list $aport output]
      }
      foreach aport [nl_list_ports -inouts $mod] {
	lappend portlist [list $aport inout]
      }
    } else {
      set portlist [nl_list_ports $mod]
    }
    return $portlist
  }

  struct verilog_module m $_VERILOG_MODULES($mod)
  set wire_list ""
  foreach thing ${m.ports} {
    setl {name range_hi range_lo iotype} $thing
    foreach bit [_verilog_flatten_range $name $range_lo $range_hi] {
      if {$incl_kind} {
	lappend wire_list [list $bit $iotype]
      } else {
	lappend wire_list $bit
      }
    }
  }

  if {$bus} {
    set result ""
    if {$incl_kind} {
      foreach thing $wire_list {
	setl {bit kind} $thing
	set bus_name [nlt_bus $mod $bit]
	if {$bus_name != ""} {
	  lappend result [list $bus_name $kind]
	}
      }
    } else {
      foreach bit $wire_list {
	set bus_name [nlt_bus $mod $bit]
	if {$bus_name != ""} {
	  lappend result $bus_name
	}
      }
    }
    return $result
  } else {
    return $wire_list
  }
}

proc nl2_get_net_pins {{-bus 0} {-hierarchy} curmod net} -doc {
  Note: This is used to get pins in a module aka cell references.
  If you are traversing the hierachy in a flattened design,
  do NOT call this.  Call nl_get_net_pins direct and pass it
  the net objected returned from another nl command.

  If -bus is 1 and net is a bus, return the aggregated port buses,
  with indicies ordered to reflect actual connections.
} {
  global FPLAN _VERILOG_NET_MAP _VERILOG_PORT_MAP _VERILOG_MODULES

  #set mod [fplan_db_cell module [lay_editcell]]

  if {$FPLAN(use_nl_shell)} {
    # DONT SET nl_current_design:  doesnt work.
    global nl_hierarchy_separator
    set nl_hierarchy_separator "."
    set inet [nl2_find_net $curmod $net]

    # Note: WORK AROUND TCL EVAL BUG:
    # The Tcl eval function string-izes its arguments
    # before executing them, thus destroying any nl objects.
    # To pass $inet as an object, you must pass {$inet},
    # ie, pass a reference to the variable, not the contents of the variable.
    # So you can not use a list structure, you must use a string
    # that contains {$inet}.
    set cmd "nl_get_net_pins -noassign"
    if {$hierarchy} {append cmd " -hierarchy"}
    append cmd { $inet}
    set pin_list [eval $cmd]

    set ret ""
    foreach pin $pin_list {
      # Ignore pins that have a cell name that contains "*";
      # they are things like "*process*", etc.
      if {[regexp {^.*\*.*\..*$} $pin]} {continue}
      lappend ret $pin
    }
    return $ret
  }


  # TODO: What about busses.  Do they just work out?
  if {$bus} {
    set buslist [nlt_bus_explode $net]
    if {[llength $buslist] == 1} {
      # Its a non-bus or single bit bus.
      return [use_first _VERILOG_NET_MAP($curmod,$net)]
    } else {
      # The net is an aggregated bus.
      foreach netbit $buslist {
	foreach portbit $_VERILOG_NET_MAP($curmod,$netbit) {
	  if {![regexp {(.*)\[(.*)\]$} $portbit junk portbase ind]} {
	    error "internal: aggregated port not a bus!"
	  }
	  lappend cons($portbase) $ind
	}
      }

      set result ""
      foreach port [array names cons] {
	lappend result "$port\[[nlt_list_compress $cons($port)]\]"
      }

      # Old way: Query any bit of the bus, and hope
      # that all the bits are connected the same.  This should
      # be the case if the bus-name came from aggregation, ie,
      # we only handed the user properly aggregated bus names.
      #set netbit [lindex $buslist 0]
      #set portbits [nl2_get_net_pins $netbit]
      #set result ""
      #foreach portbit $portbits {
      #	set portbus $NLT_AG_PIN2($portbit)
      #	if {$portbus != ""} {
      #	  lappend result $portbus
      #	}
      #      }

      return $result
    }
  } else {
    return [use_first _VERILOG_NET_MAP($curmod,$net)]
  }
}

proc nl2_get_pin_net {curmod pin} -doc {
  Note: This is used to get net objects attached to a named pin.
  If you are traversing the hierachy in a flattened design,
  do NOT call this.  Call nl_get_pin_net direct and pass it
  the net object (ipin) returned from another nl command.
} {
  global FPLAN _VERILOG_PORT_MAP
  if {$FPLAN(use_nl_shell)} {
    global nl_hierarchy_separator
    #global nl_current_design
    #set nl_current_design $curmod
    set nl_hierarchy_separator "."
    set ipin [nl2_find_pin $curmod $pin]
    # pin will be empty only in error cases.
    if {$ipin == ""} {return ""}
    return [nl_get_pin_net $ipin]
  }

  # TODO: Does not work for top level ports.
  setl {mod_inst port} [split $pin .]

  # We will assume it is already initialized.
  return [use_first _VERILOG_PORT_MAP($curmod,$mod_inst,$port)]
}


proc verilog_squish {} -desc {
  Remove files from the verilog hierarchy that contain only one subcell.
} -doc {
  Needed to remove the dummy cells added by sue to implement demorgan gates.
} {
  global nl_hierarchy_separator
  # Say module foo contains foo1 contains foo2, and nl_hierarchy_sep is /.
  # If you ungroup foo1, it brings foo2 up
  # into foo with the new name foo1/foo2.
  # Now if you say nl_list_cells on foo, you get foo1/foo2.
  # Which looks like a hierarchical path, but its not,
  # so if you use it in nl it will barf, because that hierarhical cell
  # no longer exists.

  msg "Remove cells with one cell\n"

  nlt_init_aggregate -reset

  foreach mod [nl2_list_designs] {
    set re_names ""
    foreach submodi [nl2_list_cells -hierarchy $mod] {
      global submod
      set submod [nl_get_cell_reference $submodi]
      set subsubmodi [nl_list_cells $submod]
      if {[llength $subsubmodi] == 1} {
	# This subcell has only one contained cell.
	set subsubmod [nl_get_cell_reference $subsubmodi]
	if {[fplan_cell_info -is_lef $subsubmod]} {

	  # The contained cell is a lef cell.
	  # We will assume that submod is a dummy level of
	  # hierarchy added by Sue to implement demorgan gates,
	  # and remove that level of hiearchy.
	  set nl_hierarchy_separator "@"  ;# Temporary value.
	  nl_ungroup $submodi
	  set nl_hierarchy_separator "."

	  # Nl names the new mod instance: $submodi@$subsubmod,
	  # so change it back to just $submodi
	  # Be careful that nl_hierarchy separator is not @, or it
	  # nl_find_cells gets confused.  And if nl_hierarchy_separator is ".",
	  # then you cant use nl_find_cells -regexp  ("." is a regexp char and hierarchy!)
	  set old_name ${submodi}@${subsubmod} 
	  set new_name ${submodi}

	  set cell_obj [nl_find_cells -exact $old_name $mod]
	  # Good try, but nl_rename_cell is not implemented yet.
	  #nl_rename_cell $cell_obj $new_name
	}
      }
    }
  }
}


proc nl2_set_current_design {} {
    # Set nl_current_design to garbage to make SURE we are not
    # doing an implicit conversion from string to nl object,
    # which can result in garbage.
    global nl_current_design.
    if {[nl2_find_design __DUMMY__] == ""} {
      nl_create_design __DUMMY__
    }
    set nl_current_design [nl2_find_design __DUMMY__]
}

proc nl2_read_verilog {{-include ""} {-flags ""} filename} -type local -desc {
  Read verilog file.  Use this instead of nl_read_verilog inside max.
} -doc {
  The -flags are passed directly to nl_read_verilog.
  The <include> file an be a list of files to be read before <filename>.
  Any modules read during this command are marked as coming from <filename>.
} {
  global FPLAN _VERILOG_OPT nl_hierarchy_separator

  # If we are reading new verilog, any existing bus aggregation
  # tables no longer apply.
  nlt_init_aggregate -reset

  set FPLAN(f_verilog_read) 1
  if {$FPLAN(use_nl_shell)} {
    util_load_pkg nl_shell.so
    if {$include != ""} {
      # Pass a list of filenames.
      set file_list [concat $include $filename]
    } else {
      # Dont use a list, just a string.
      set file_list $filename
    }
    set cmd "nl_read_verilog $flags [list $file_list]"
    msg "$cmd\n"

    if {[catch $cmd result]} {
      max_error -buffer "Warning: failed: \"nl_read_verilog $flags $file_list\" with result: $result"
      max_error -buffer "Warning: trying nl_read_verilog -ports_only - hierarchy below this cell is lost."
      eval "nl_read_verilog -ports_only $flags $file_list"
    }
    # This links the last module read in.
    # This is not necessarily the top-level cell,
    # so we really need to do another link whenever we
    # really need some data.
    nl_link -silent
    # 7/17/01 Init aggregate done on demand now.
    #nlt_init_aggregate -all

    nl2_set_current_design
    set nl_hierarchy_separator "."
  } else {
    _verilog_read $filename
    #nlt_init_aggregate -all
    verilog_make_maps
  }

  # Remember what verilog file each module came from.
  global VERILOG_MODULE2FILE
  foreach des [nl2_list_designs] {
    if {![info exists VERILOG_MODULE2FILE($des)]} {
      set VERILOG_MODULE2FILE($des) $filename
    }
  }
}


proc nl2_find_cell {mod inst} -desc {
  Return nl cell object corresponding to the named module instance: inst in module: mod.
} {
  return [lindex [nl_find_cells -exact $inst $mod] 0]
}

proc nl2_find_net {mod net} -desc {
  Return nl net object corresponding to the named net in module: mod.
} {
  return [lindex [nl_find_nets -exact $net $mod] 0]
}

proc nl2_find_pin {mod pin} -desc {
  Return nl pin object corresponding to the named pin in module: mod.
} {
  return [lindex [nl_find_pins -exact $pin $mod] 0]
}

proc nl2_loaded {{-cell} {mod ""}} -desc {
  Return TRUE if nl is loaded, and optionally, has read verilog for mod.
} -doc {
  If -cell, it is a max cell name.  Otherwise it is a verilog module name.
  Does NOT load nl.
} {
  if {$cell} {
    set mod [fplan_unfix_name $mod]
  }

  if {[catch {nl_find_designs -exact $mod} result]} {
    # nl not loaded.
    return 0
  }
  if {$result == ""} {
    # This module not found.
    return 0
  }
  return 1
}

proc nl2_find_design {mod} -desc {
  Return nl object corresponding to named module, or "".
} {
  util_load_pkg nl_shell.so
  return [lindex [nl_find_designs -exact $mod] 0]
}

proc nl2_find_designs {option mod} -desc {
  Return list of matching module names.  option is -exact or -regexp
} {
  global FPLAN
  if {$FPLAN(use_nl_shell)} {
    # Need to load nl_shell.so, because nl2_find_designs might
    # be called to see if verilog was loaded for a module
    # before nl2_read_verilog is called.
    util_load_pkg nl_shell.so
    return [nl_find_designs $option $mod]
  } else {
    global _VERILOG_MODULES
    assert {$option == "-exact"}
    if {[info exists _VERILOG_MODULES($mod)]} {
      return $mod
    } else {
      return ""  ;# Module by this name does not exist in verilog.  Might be a lef cell.
    }
  }
}

proc nl2_flatten {mod} -desc {
  Flatten nl data-base starting at specified module.
} -doc {
  nl calls this "creating an idesign".  There can be only one idesign tree,
  so it is illegal to call this on two different modules.
} {
  global NL2_FLATTEN_HEAD
  set old [use_first NL2_FLATTEN_HEAD]
  if {$old != ""} {
    if {$old != $mod} {
      error "Attempt to flatten nl verilog data-base at module $mod; you already flattened module $old"
    }
    return
  }
  set NL2_FLATTEN_HEAD $mod
  nl_create_idesign $mod
}


proc nl2_is_rtl_cell {def} -desc {
  # Return TRUE if the cell def is one of the ones used by nl to map RTL cells.
} {

  foreach thing [list \*expression* \*process* \*assignment*] {
    if {[string match $thing $def]} {return 1}
  }
  return 0
}

proc _verilog_init_cell {mod_name {flags ""}} -desc {
  Create an empty verilog definition.
} {
  global _VERILOG_MODULES
  set m.name $mod_name
  set m.portorder ""
  set m.ports ""
  set m.supply0 ""
  set m.supply1 ""
  set m.wires ""
  set m.instances ""
  set m.flags $flags
  set m.leaf_cnt 0
  set m.leaf_area 0
  set _VERILOG_MODULES($mod_name) [destruct verilog_module m]
}
