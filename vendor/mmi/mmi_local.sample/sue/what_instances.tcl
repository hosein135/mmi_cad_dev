# Example function that uses the SUE API.

# creates a popup listbox with the instances and names in the current
# schematic.  By clicking on the desired instance in the popup, it is
# selected and zoomed to in the schematic.  If multiple instances with
# the same type are in the schematic, the first click will select them
# all and subsequent clicks with select each one in turn.

# Set this variable to things that you never want to see in the list
# Wildcards (*) are ok.
set WHAT(ignores) "input output inout global name_net* row_spanner* *title_bar bus_combine* sign_extend"

proc what_instances {} {

  global WHAT _WHAT_

  catch "unset _WHAT_"
  set _WHAT_(_last_) ""

  # split ignores into wilcarded and not wildcarded
  set ignores ""
  set wildcarded_ignores ""
  foreach ignore $WHAT(ignores) {
    if {[string first * $ignore] == -1} {
      lappend ignores $ignore
    } else {
      lappend wildcarded_ignores $ignore
    }
  }

  foreach id [api_instances] {

    set data [api_instance_data $id]
    set type [get_assoc type $data]

    # ignore inputs, output, inouts, globals, ...
    if {[lsearch $WHAT(ignores) $type] != -1} {
      # ignore this
      continue
    }

    # check for wildcarded individually
    set ignore_this 0
    foreach ignore $wildcarded_ignores {
      if {[lsearch $type $ignore] != -1} {
	# ignore this
	set ignore_this 1
	break
      }
    }

    if {$ignore_this} {
      continue
    }

    set name [get_assoc _name $data]

    if {$name == ""} {
      set name <UNNAMED>
    }

    lappend insts($type,$name) $id
    set types($type) 1
  }

  # now arrange nicely for user
  set list ""
  foreach type [lsort -dictionary [array names types]] {
    set string "$type ("
    set separator ""
    set ids ""
    foreach inst [lsort -dictionary [array names insts $type,*]] {
      append string "$separator[lindex [split $inst ,] 1]"
      if {[llength $insts($inst)] > 1} {
	append string " \#[llength $insts($inst)]"
      }
      set separator ", "
      eval lappend ids $insts($inst)
    }

    append string ")"
    lappend list $string
    set _WHAT_($string) $ids
  }

  # put it into a popup window
  create_what_instances_window $list
}


proc create_what_instances_window {list} {

  global LISTBOX_FONT

  # make up a unique name here
  set win .what_instances

  if {[winfo exists $win]} {
    # just clean this out and use again
    $win.f.instances delete 0 end

    # raise it
    raise $win

  } else {
    # make a new one
    catch {destroy $win}

    # build a toplevel window
    toplevel $win

    wm title $win "What Instances"
    wm geometry $win 200x400

    wm min $win 200 400

    frame $win.f
    scrollbar $win.f.scroll -command "$win.f.instances yview" \
	-highlightthickness 0
    pack $win.f.scroll -side right -fill y
    listbox $win.f.instances -yscrollcommand "$win.f.scroll set" \
	-highlightthickness 0 -exportselection 0
    pack $win.f.instances -side left -fill both -expand 1
    $win.f.instances configure -font $LISTBOX_FONT

    pack $win.f -side top -expand 1 -fill both

    # put some buttons at the bottom
    frame $win.buttons

    frame $win.default -relief sunken -bd 1
    button $win.close -text "Close" -padx 1 -pady 1 \
	-command "catch \"destroy $win\""
    pack $win.close -in $win.default -padx 1m -pady 1m -ipadx 2m
    pack $win.default -side left -in $win.buttons \
	-padx 4m -ipadx 1m -pady 1m

    button $win.rescan -text "Rescan" -padx 1 -pady 1 \
	-command what_instances
    pack $win.rescan -side left -in $win.buttons \
	-padx 4m -ipadx 2m -pady 1m

    pack $win.buttons -side top
   
    bind $win <Control-c> "catch \"destroy $win\""
    bind $win <Escape> "catch \"destroy $win\""

    # This will choke if empty
#    set selected "\[$win.f.instances get \[$win.f.instances curselection\]\]"
    # use this fancy version
    set selected [backquote \
      {[if {[set sel_index [$$win.f.instances curselection]] != ""} { \
	concat [$$win.f.instances get $sel_index] \
      }] \
    }]

    bind $win.f.instances <Motion> \
	{%W selection clear 0 end; %W selection set [%W nearest %y]}

    # single click on button-1 selects in cell
    bind $win.f.instances <Button-1> "what_instances_select $selected"
  }

  foreach string $list {
    $win.f.instances insert end $string
  }
}


proc what_instances_select {selected} {

  global _WHAT_

  if {$selected == ""} {
    return
  }

  if {$_WHAT_(_last_) == $selected} {
    # selected this before so go thru list of ids, one at a time
    set id [lindex $_WHAT_($selected) $_WHAT_(_index_)]
    if {$id == ""} {
      set _WHAT_(_index_) 0
      set id [lindex $_WHAT_($selected) $_WHAT_(_index_)]
    }
    incr _WHAT_(_index_)

    api_select_ids $id
    api_zoom selected

  } else {
    # select the corresponding ids
    api_select_ids $_WHAT_($selected)
    api_zoom selected

    # reset
    set _WHAT_(_last_) $selected
    set _WHAT_(_index_) 0
  }
}



