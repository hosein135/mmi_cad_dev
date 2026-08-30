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


# called by other procedures to make a new canvas and pack it.

proc make_schematic {schematic {type S}} {

  global cur_c cur_s SUE WIN

  if {[info exists cur_c]} {
    catch {unpack_canvas}
  }

  # never been loaded before, setup entry in global database
  set SUE($schematic) $schematic

  make_canvas $WIN $schematic $type
  pack_canvas

  setup_bindings

  # only icon schematics need origins
  if {$type == "I"} {
    make_icon_origin
  }

  return $cur_s
}


# displays a different schematic

proc goto_schematic {schematic {reset_hierarchy 0}} {

  global cur_c cur_s scale WIN SUE HIERARCHY _SAVE_HIERARCHY_

  if {$reset_hierarchy != 0} {
    # this is now the top level cell
    set HIERARCHY ""
    set _SAVE_HIERARCHY_ ""
  }

  # are we already here?
  if {$cur_s == $schematic && [catch "pack info $WIN.c_$cur_s"] == 0} {
    return
  }

  # see if there already exists a canvas
  if {[info exists SUE($schematic)]} {
    # yes, unpack old canvas, enter the new canvas, and pack it in.
    catch {unpack_canvas}

    enter_canvas $schematic
  
    pack_canvas

    return $cur_c
  }

  if {![catch NAME_$schematic name] && $schematic != $name} {
    # generator
    if {[info commands SCHEMATIC_${schematic}] != ""} {
      generate $schematic $name
    }
    set schematic $name
    return [goto_schematic $name]
  }

  # if it's an icon, it should have a procedure defined
  if {[is_icon $schematic]} {
    if {[info_proc $schematic] != ""} {
      busy

      # make a canvas and put the icon into it
      if {[make_new_schematic [get_rootname $schematic] I 1] == ""} {
	# failed
	ready
	return
      }

      # generators have special generator arguments
      set iname [get_rootname $schematic]
      upvar #0 icon_$iname g_data
      icon_make $iname [use_first g_data(gargs)]

      zoom_to_fit

      # update the icon listbox
      make_icon_listbox

      update

      ready
      return $cur_c
      
    } else {
      # no lo existo
      return
    }
  } else {
    # must be a schematic

    # break apart the directory, the fileroot name, and the suffix
    setl {dir schematic suffix} [split_filename $schematic]
    if {$schematic == ""} {
      # bad name
      sue_error "Aborting, bad name."
      sue_error flush
      ready 
      return
    }

    # see if there is a schematic generator
    upvar #0 icon_$schematic g_data
    set genname [lindex [split_filename [use_first g_data(generator)]] 1]
    if {[info_proc SCHEMATIC_$genname] != ""} {
      busy

      # make a canvas and put the schematic into it
      if {[make_new_schematic $schematic S 1] == ""} {
	# failed
	ready
	return
      }

      eval SCHEMATIC_$genname $g_data(gargs) -name $schematic

      # add a comment to alert user that this is a defined schematic
      set bbox [$cur_c bbox all]
      make_text -origin "[lindex $bbox 0] [expr [lindex $bbox 1] -50]" -text \
	  "Schematic generated from $g_data(generator) $g_data(gargs)" \
	  -size large

      zoom_to_fit

      # making this schematic may have defined some new icons, so...
      make_icon_listbox

      display_title

      # update so user can see it while we figure out connect info.
      update

      integer_scale

      # show connection info
      show_connects "" fast

      unscale

      # if there are cached term and inst names, attach them.
      set_cached_names load

      # update flags if in simulation
      update_canvas_state

      ready
      return $cur_c
    }

    # is there a schematic procedure for it
    if {[info_proc SCHEMATIC_$schematic] != ""} {
      busy

      make_schematic_canvas $schematic $dir $suffix

      # making this schematic may have defined some new icons, so...
      make_icon_listbox

      ready
      return $cur_c
    }

    # try looking for the icon instead
    return [goto_schematic ICON_$schematic]
  }
}


# makes a new schematic

proc make_new_schematic {{schematic ""} {type S} {force 0}} {

  global SUE HIERARCHY auto_index SUE_DIR SUFFIX cur_s

  if {$schematic == ""} {
    set popup 1

    # get the name of the file from the file selector box
    set filename [fs_box -message "New File Name:"]

    # if nil, file selector box cancelled -- do nothing
    if {$filename == ""} { 
      return 
    }

    update

    # break apart the directory, the fileroot name, and the suffix
    setl {dir schematic suffix} [split_filename $filename "" 1]
    if {$schematic == ""} {
      # bad name
      sue_error "Aborting, bad name."
      sue_error flush

      return
    }
    if {[string range $schematic 0 4] == "ICON_"} {
      sue_error "Aborting.  Can't start schematic name with the characters \"ICON_\""
      sue_error flush
      return
    }

    if {[set existing [lindex [use_first auto_index(SCHEMATIC_$schematic) \
				   auto_index(ICON_$schematic)] 1]] != ""} {
      # in auto_index
      if {[file dirname $filename] == [file dirname $existing]} {
	# same file, force user to rename
	set button [tk_dialog .delete "Duplicate Cell" \
			"WARNING, the $schematic you requested conflicts with the existing file $existing.  Do you want to replace the existing file?  If \"replace\", the existing file will be renamed to be $existing.replaced." \
			@$SUE_DIR/sue_icon.xbm 1 {replace} {cancel}]

	if {$button == 1} {
	  # user hit the cancel key
	  puts "Aborting new schematic $schematic creation due to conflict with existing file."
	  return
	}

	# user wants to replace
	if {[catch "exec mv $existing $existing.replaced" msg]} {
	  # didn't work
	  warning "Aborting, can't rename file $existing: $msg."
	  return
	}
	
	# need to recompute tclindex
	set dirm [string trimright $dir /]
	puts "ReComputing tclIndex ($SUFFIX($dirm)) for $dirm ..."
	if {[catch "sue_auto_mkindex $dirm $SUFFIX($dirm)" msg]} {
	  puts "SUE Warning: $msg"
	}

	catch {unset auto_index(SCHEMATIC_$schematic)}
	catch {unset auto_index(ICON_$schematic)}

      } else {
	# potential shadowing problem
	set button [tk_dialog .delete "Duplicate Cell" \
			"WARNING, $schematic already exists in $existing.  Creating this new cell will cause it or the other to be shadowed.  Do you want to continue?" \
			@$SUE_DIR/sue_icon.xbm 1 {continue} {cancel}]
	if {$button == 1} {
	  # user hit the cancel key
	  puts "Aborting new schematic $schematic creation due to conflict with existing file."
	  return
	}
      }
    }

    if {$type == "I"} {
      set schematic "ICON_$schematic"
    }

    # See if this schematic name has already been used.  If so, punt.
    if {[info exists SUE($schematic)]} {
      sue_error "Aborting.  $schematic already exists."
      sue_error flush
      return
    }

    add_auto_path $filename

    # reset hierarchy
    set HIERARCHY ""

  } else {
    set popup 0

    # break apart the directory, the fileroot name, and the suffix
    set save_name $schematic
    setl {dir schematic suffix} [split_filename $schematic "" 1]
    if {$schematic == ""} {
      # bad name
      sue_error "Aborting, bad name \"$save_name\".  Found directory \"$dir\"."
      sue_error flush
      return ""
    }

    if {[string range $schematic 0 4] == "ICON_"} {
      # Can't start schematic name with the characters \"ICON_\""
      return ""
    }

    if {$type == "I"} {
      set schematic "ICON_[get_rootname $schematic]"
    }
  }

  if {[info exists SUE($schematic)]} {
    goto_schematic $schematic 1
    return ""
  }

  if {!$force} {
    if {[is_icon $schematic]} {
      # it's an icon
      if {[info exists SUE([get_rootname $schematic])]} {
	# schematic exists for this icon
	if {[info proc $schematic] != ""} {
	  # icon proc exists, go to it
	  goto_schematic $schematic 1
	  return ""
	}
      }

      if {[info commands _MAKE_[get_rootname $schematic]] != ""} {
	# icon has alread been made for
	goto_schematic $schematic 1
	return ""
      }

    } else {
      # it's a schematic
      if {[info commands _MAKE_$schematic] != ""} {
	# icon has alread been made for
	if {[info proc SCHEMATIC_$schematic] != ""} {
	  # icon proc exists, go to it
	  goto_schematic $schematic 1
	  return ""
	}
      }
    }
  }

  set value [make_schematic $schematic $type]

  make_filename $dir $suffix

  # if it's an icon, need to enter into icon listbox
  if {$type == "I" && [info_proc $schematic] == ""} {
    # create a placeholder procedure for this icon (needed for
    # make_icon_listbox)
    write_icon

    # need to do this again now that there is an icon
    make_filename $dir $suffix

    # update the icon listbox
    make_icon_listbox
  }

  if {$popup} {
    upvar #0 SUE_$cur_s data
    puts "Made new cell $schematic with filename [use_first data(filename)]."
  }

  display_title

  return $value
}


# Loads a file by sourcing the file.  If there is a procedure of name
# SCHEMATIC_$schematic where $schematic is the filename minus directory
# and suffix, then displays the schematic.  Also updates the icon
# listbox to show any icons that may have been loaded.

# Note: any schematic other procedures in this file will get their
# procedures defined but will be otherwise unknown.

proc load_schematic {{filename ""}} {

  global SUE HIERARCHY

  if {$filename == ""} {
    # get the name of the file from the file selector box
    set filename [fs_box -message "Load File:"]

    # if nil, file selector box cancelled -- do nothing
    if {$filename == ""} { 
      return 
    }

    # reset hierarchy
    set HIERARCHY ""

    # remove the listbox so user knows you've selected something
    update
  }

  add_auto_path $filename

  # break apart the directory, the fileroot name, and the suffix
  setl {dir schematic suffix} [split_filename $filename "" 1]
  if {$schematic == ""} {
    # bad name
    sue_error "Aborting, bad name."
    sue_error flush

    return
  }

  # This is only done to fix up the suffix if it is gone
  set filename "$dir$schematic$suffix"

  global SUE_$schematic

  # special case for no_name schematic
  busy
  if {$schematic == "no_name"} {
    if {[delete_schematic $schematic 1] == -1} {
      ready
      return
    }
    if {[delete_schematic ICON_$schematic] == -1} {
      ready
      return
    }
  }

  # See if there is already a schematic or icon of the same name.  If so
  # just goto it.
  if {[info exists SUE($schematic)]} {
    sue_error "Schematic $schematic already loaded.  Switching to $schematic."
    sue_error flush
    goto_schematic $schematic 1
    ready
    return
  }
  if {[info exists SUE(ICON_$schematic)]} {
    sue_error "Aborting, Icon $schematic already exists."
    sue_error flush
    ready
    return
  }
  
  # Load the file (don't know if it contains a schematic, an icon, or both)
  puts "Loading $filename ..."
  if {[catch "source $filename" error]} {
    # this gets confusing with no_name.

    if {$schematic == "no_name"} {
      make_new_schematic no_name
    } else {
      goto_schematic no_name 1
    }

    # failed, file probably doesn't exist
    sue_error "SUE ERROR: Aborting, $error"
    sue_error flush

    ready
    return
  }

  # special case for a generator.  The default may have a different
  # name the filename.
  if {![catch NAME_$schematic name] && $schematic != $name} {
    # generator
    if {[info commands SCHEMATIC_${schematic}] != ""} {
      generate $schematic $name
      goto_schematic $name
    }
  } else {
    # if there is a schematic, bring it up in a canvas
    if {[info commands SCHEMATIC_${schematic}] != ""} {
      # make a canvas and display it
      make_schematic_canvas $schematic $dir $suffix
    }
  }

  # update the icon listbox.  Change the directory (remove / at end)
  make_icon_listbox [string trimright $dir /]
  ready
}


# put a schematic procedure into a canvas and display it.

proc make_schematic_canvas {schematic dir suffix} {

  global SUFFIX

  # if there is a merge schematic, bring it up in a canvas
  set merge "$schematic$SUFFIX(merge)"
  if {[info commands SCHEMATIC_${merge}] != ""} {
    # make a canvas and display it
    make_schematic_canvas_int $merge $dir $suffix
  }

  # now bring up the called for schematic in a canvas
  make_schematic_canvas_int $schematic $dir $suffix

  # force wish to load in all of the tclIndexes
  auto_load_index

  # check to see if this came from the file that the user expected
  check_file_name
}


proc make_schematic_canvas_int {schematic dir suffix} {

  make_schematic $schematic

  make_filename $dir $suffix

  # execute the schematic proc into the new canvas
  if {[catch "SCHEMATIC_$schematic" msg]} {
    # uh oh, error
    sue_error "SUE ERROR: $msg in SCHEMATIC $schematic."
    
    is_modified
  }

  zoom_to_fit
  
  display_title

  # since show_connects is sooooo slow
  update

  integer_scale

  # show connection info
  show_connects "" fast

  unscale

  # if there are cached term and inst names, attach them.
  set_cached_names load

  # update flags if in simulation
  update_canvas_state
}


# Check that the schematic just loaded came from the desired file

proc check_file_name {} {

  global auto_index cur_s

  upvar #0 SUE_$cur_s data

  if {[is_icon $cur_s]} {
    set procedure $cur_s
  } else {
    set procedure SCHEMATIC_$cur_s
  }

  set auto_filename [lindex [use_first auto_index($procedure)] 1]

  set rootname [get_rootname $cur_s]
  set filename $data(dir)$rootname[file extension $data(filename)]

  if {$auto_filename != "" && $filename != $auto_filename} {
    # we got a problem
    warning "WARNING, the file you have loaded is \"$auto_filename\", NOT \"$filename\".  Both of these files contain the procedure \"$procedure\" and you probably got the wrong file.  To verify, run \"check file system\" in the \"File\" menu.  If this file is incorrect, you should get out of SUE, fix the files, and then start over."
  }
}


# if the current canvas is a schematic, switch to the icon.  If no
# icon exists, punt.  If the current canvas is an icon, switch to 
# the schematic if one exists.

proc change_views {} {

  global cur_s

  goto_schematic [corresponding_cell $cur_s]
}


# returns the name of the corresponding cell: the icon for a schematic
# of the schematic for an icon.

proc corresponding_cell {cell {schematic_prefix ""}} {

  # is this an icon name
  if {[is_icon $cell]} {
    # the rootname is the schematic name
    return "$schematic_prefix[get_rootname $cell]"
  } else {
    # make the icon name
    return ICON_$cell
  }
}


# swaps views and selected I/O's in other view that were selected

proc change_views_selected {} {

  global cur_s cur_c

  # are there any I/O's selected
  foreach type "input inout output" {
    foreach id [$cur_c find withtag selected&icon_$type] {
      global ${cur_s}_inst$id
      set name [bus_root [set ${cur_s}_inst${id}(_name)]]
      set ios($name) 1
    }
  }

  goto_schematic [corresponding_cell $cur_s]

  # now select these ios
  if {[info exists ios]} {
    set ids ""
    foreach type "input inout output" {
      foreach id [$cur_c find withtag icon_$type] {
	global ${cur_s}_inst$id
	set name [bus_root [set ${cur_s}_inst${id}(_name)]]
	if {[info exists ios($name)]} {
	  lappend ids $id
	}
      }
    }

    select_ids $ids
  }
}


# makes an icon for a schematic if none exists and puts the i/o's and
# the properies "name" and "M" into it.  Otherwise makes a schematic
# for an icon if none exists and puts i/o's in it.

proc make_other_view {} {

  global cur_c cur_s SUE SUE_DIR PROC
  
  if {[is_placement $cur_s]} {
    warning "Aborting, can't make an icon for a placement."
    return
  }

  modify_setup

  set cell [corresponding_cell $cur_s]
  # if the corresponding cell already exists, see if user wants to recreate.
  if {[info commands $cell] != "" || [info exists SUE($cell)]} {
    change_views

    set button [tk_dialog .delete "Delete Cell" \
		    "Do you want to replace this view?" \
		    @$SUE_DIR/sue_icon.xbm 1 {replace} {cancel}]

    if {$button == 1} {
      # user hit the cancel key
      return
    }

    scale_canvas 10

    # for undo
    set PROC ""
    write_instances all "" undo
    write_wires all undo
    write_draw_items all undo
    set save_proc $PROC

    # toast contents
    foreach id [$cur_c find withtag origin] {
      # delete old icon and lose the old data structure
      $cur_c delete inst$id
      global ${cur_s}_inst$id
      catch {unset ${cur_s}_inst$id}
    }
     
    # delete anything else that might be around
    $cur_c delete all

    make_icon_origin

    change_views

    set replace 1
  } else {
    set replace 0
  }

  # first get all the io's from the current view
  set ios ""
  set startx -100

  foreach type "input inout output" {

    set tmp_names ""
    foreach id [$cur_c find withtag icon_$type] {
      global ${cur_s}_inst$id
      lappend tmp_names [set ${cur_s}_inst${id}(_name)]
    }

    # combine names with the same root
    set lastroot ""
    set bus_name ""
    set names ""
    foreach name [lsort -dictionary $tmp_names] {
      set root [bus_root $name]

      if {$root != $lastroot} {
	if {$lastroot != ""} {
	  # save this
	  if {[llength $bus_name] == 1} {
	    lappend names $bus_name	    
	  } else {
	    # combine
	    lappend names "$lastroot[bus_extent $bus_name]"
	  }
	}

	set lastroot $root
	set bus_name $name

      } else {
	if {$bus_name != $name} {
	  # combine bus
	  lappend bus_name $name
	}
      }
    }
    
    if {$lastroot != ""} {
      # add last one
      if {[llength $bus_name] == 1} {
	lappend names $bus_name	    
      } else {
	# combine
	lappend names "$lastroot[bus_extent $bus_name]"
      }
    }

    set x $startx
    incr startx 100
    set y -100
    foreach name $names {

      # need to quote brackets
      regsub -all {\[|\]} $name \\\\& name
      # We have a winner
      regsub -all {\\\$} $name {\\\\\$} name

      lappend ios "make $type -origin [list [list $x [incr y 20]]] -name $name"
    }
  }

  # though the icon isn't actually modified, adding a schematic changes
  # the netlisting of the icon.  This forces a renetlist (instead of using
  # the cache) for the cell above.
  is_modified

  set save_cur_s $cur_s

  upvar #0 SUE_$cur_s data
  if {[is_icon $cur_s]} {
    # new icon
    if {$replace} {
      change_views
    } else {
      # make a new schematic cell
      make_new_schematic $data(filename)
    }
    set ids ""

  } else {
    # new schematic
    if {$replace} {
      change_views
    } else {
      # make a new icon cell
      make_new_schematic $data(filename) I
    }
    # put the default properties into it
    set ids [add_properties_to_icon]
  }

  # put the io's in the new cell
  foreach command $ios {
    if {[catch $command msg]} {
      sue_error "$msg in command \"$command\""
    } else {
      lappend ids $msg
    }
  }

  if {$replace} {
    setup_undo $ids $save_proc "" \
	"make_icon_origin ; zoom_to_fit"
  }

  if {[is_icon $save_cur_s]} {
    puts "Made corresponding schematic for icon \"[get_rootname $cur_s]\"."
  } else {
    puts "Made corresponding icon for schematic \"[get_rootname $cur_s]\"."
  }

  # make this modified
  is_modified

  zoom_to_fit

  sue_error flush
}


proc add_properties_to_icon {} {

  global cur_c DEFAULT_PROPERTIES scale

  set incy [expr $scale * 2]
  set x [expr 0 - $scale * 5]
  set y [expr $scale * 5]

  set ids ""
  foreach prop $DEFAULT_PROPERTIES {
    lappend ids [make_text -origin "$x [incr y $incy]" -text $prop]
  }

  return $ids
}


# push into instance connected to this wire and select
# wire inside.  If an instance is highlighted, prefer that one

proc push_into_connected {wire_ids {mode ""}} {

  global cur_s cur_c scale HIERARCHY NETLIST_CACHE

  # TODO: integer scale_canvas???

  upvar #0 TERMS_$cur_s TERMS
  set del [expr $scale/3.0]

  if {[llength [array names TERMS]] < 2} {
    busy
    puts "Generating terminal names for \"$cur_s\"."
    generate_term_names
    ready
  }

  set prefer_id [find_origin [$cur_c find withtag current]]

  if {[is_tagged $prefer_id origin]} {
    upvar #0 ${cur_s}_inst$prefer_id i_data
    # the type is really the instance name
    set type $i_data(type)

    # an instance, see if a selected wire is attached
    foreach term_id [$cur_c find withtag term&inst$prefer_id] {
      setl {x y} [center $term_id]
      foreach id [$cur_c find overlapping [expr $x - $del] \
		      [expr $y - $del]	[expr $x + $del] [expr $y + $del]] {
	if {[is_tagged $id wire] && [is_tagged $id selected]} {
	  # got one

	  upvar #0 icon_$type g_data
	  if {[info exists g_data(_primitive)]} {
	    # don't push into primitives
	    continue
	  }

	  # don't push into an icon recursively
	  if {$type == $cur_s} {
	    continue
	  }

	  if {[info exist TERMS($term_id,name)]} {
	    set port $TERMS($term_id,name)
	  } else {
	    # do it the hard way
	    set tags [$cur_c gettags $term_id]
	    set name_list [lindex $tags [lsearch $tags "name*"]]
	    set port [lindex $name_list 3]
	  }
	  
	  global TERMS_$type
	  if {[use_first NETLIST_CACHE($type,names)] == "" && \
		  ![info exists TERMS_$type]} {
	    # doesn't exist
# good enuf
#	    continue
	  }

	  # push into this one
	  set HIERARCHY [use_first HIERARCHY]
	  set HIERARCHY "$cur_s,$prefer_id $HIERARCHY"

	  goto_schematic $type

	  # now select the net with the port name
	  select_by_name [bus_root $port]

	  return
	}
      }
    }
  }

  if {$mode == "prefer_highlited"} {
    # special case, no longer push connected

    if {[is_tagged $prefer_id origin]} {
      # push into this one
      set HIERARCHY [use_first HIERARCHY]
      set HIERARCHY "$cur_s,$prefer_id $HIERARCHY"

      goto_schematic $type

    } else {
      # do nothing
    }

    return
  }

  # for now just push into first one found
  foreach id $wire_ids {
    
    # get all ids of things overlapping the given coordinates
    setl {x1 y1 x2 y2} [$cur_c coords $id]
    $cur_c addtag conn overlapping [expr $x1 - $del] [expr $y1 - $del] \
	[expr $x1 + $del] [expr $y1 + $del]
    $cur_c addtag conn overlapping [expr $x2 - $del] [expr $y2 - $del] \
	[expr $x2 + $del] [expr $y2 + $del]

    set ids [$cur_c find withtag conn&term]

    $cur_c dtag conn

    foreach term_id $ids {
      set inst_id [find_origin $term_id]
      upvar #0 ${cur_s}_inst$inst_id i_data
      # the type is really the instance name
      set type $i_data(type)
      upvar #0 icon_$type g_data
      if {[info exists g_data(_primitive)]} {
	# don't push into primitives
	continue
      }

      # don't push into an icon recursively
      if {$type == $cur_s} {
	continue
      }

      if {[info exist TERMS($term_id,name)]} {
	set port $TERMS($term_id,name)
      } else {
	# do it the hard way
	set tags [$cur_c gettags $term_id]
	set name_list [lindex $tags [lsearch $tags "name*"]]
	set port [lindex $name_list 3]
      }

      global TERMS_$type
      if {[use_first NETLIST_CACHE($type,names)] == "" && \
	      ![info exists TERMS_$type]} {
	# doesn't exist
# good enuf
#	continue
      }

      # push into this one
      set HIERARCHY [use_first HIERARCHY]
      set HIERARCHY "$cur_s,$inst_id $HIERARCHY"

      goto_schematic $type

      # now select the net with the port name
      select_by_name [bus_root $port]

      return
    }
  }
}


# pushes into a schematic or, if there is only an icon (say for a primitive),
# into an icon, using the selection.  Save state in HIERARCHY.

proc push_into_schematic {{id ""} {mode prefer_selected}} {

  global cur_c cur_s HIERARCHY SUE_DIR

  if {$id == ""} {

    set inst_ids [get_intersect_tag origin selected]
    set wire_ids [get_intersect_tag wire selected]
    set prim_id ""
    set ids ""

    if {$mode == "prefer_highlited"} {
      # ignore any icon selection
      set inst_ids ""
    }

#    if {$wire_ids != ""} {
#      # special case
#      set id [find_origin [$cur_c find withtag current]]
#      if {[is_tagged $id origin]} {
#	# something is highlited, ignore all selected
#	set inst_ids ""      
#      }
#    }

    # only push into a primitive if nothing else selected
    foreach inst_id $inst_ids {
      upvar #0 ${cur_s}_inst$inst_id i_data
      # the type is really the instance name
      set type $i_data(type)
      upvar #0 icon_$type g_data
      if {[info exists g_data(_primitive)]} {
	# don't push into primitives, unless no wires selected
	set prim_id $inst_id
      } else {
	lappend ids $inst_id
      }
    }

    switch [llength $ids] {
      0 {
	if {$wire_ids == "" && $prim_id != ""} {
	  set id $prim_id
	} else {
	  # look at wires
	  set id ""
	}
      }

      1 {
	# push into this
	set id $ids
      }

      default {
	# more than one non-primitive selected.  If one is highlited
	# then push into it.  Otherwise give the user a nice message.
	set id [find_origin [$cur_c find withtag current]]
	if {[is_tagged $id origin] && [is_tagged $id selected]} {
	  # we have a winner
	} elseif {[is_tagged $id origin] && $mode == "prefer_highlited"} {
	  # ok, too
	} else {
	  set button [tk_dialog .push "Push Into" \
			  "You can't push into multiple cells.  Either select only one cell or highlite one of the selected cells and try again." \
			  @$SUE_DIR/sue_icon.xbm 0 {ok}]
	  return 
	}
      }
    }

    if {$id == ""} {
      # no icons selected, look for wires
      if {$wire_ids == ""} {
	# Nothing to push into
	
	# if there is a highlighted icon use it
	set id [find_origin [$cur_c find withtag current]]
	if {![is_tagged $id origin]} {
	  # skip
	  return
	}
      } else {
	# push into instance connected to this wire and select
	# wire inside
	push_into_connected $wire_ids $mode
	return
      }
    }
  } else {
    # push into a specific id
    if {![is_tagged $id origin]} {
      return 0
    }
  }

  if {[is_placement $cur_s]} {
    # special case for dpc placment file, expand selected
    dpc_expand_hier_place

    return 1
  }

  set HIERARCHY [use_first HIERARCHY]

  set tags [$cur_c gettags $id]
  set schematic [string range [lindex $tags [lsearch $tags "icon_*"]] 5 end]

  # don't push into an icon recursively, show icon instead of schematic
  if {$schematic == $cur_s} {
    change_views
    return 1
  }

  set HIERARCHY "$cur_s,$id $HIERARCHY"

  goto_schematic $schematic
}


# pop out the current schematic using the HIERARCHY global

proc pop_out_of_schematic {} {

  global cur_s HIERARCHY

  if {[is_placement $cur_s]} {
    # special case for dpc placment file, expand selected
    dpc_unexpand_hier_place

    return 
  }

  if {[info exists HIERARCHY] != 1} {
    return
  }

  if {$HIERARCHY == ""} {
    # no where to go
    return
  }

  set schematic [lindex $HIERARCHY 0]
  set HIERARCHY [lrange $HIERARCHY 1 end]

  goto_schematic [lindex [split $schematic ,] 0]
}


# pop out the current schematic using the HIERARCHY global
# select connected net analogously to push_into_connected

proc pop_out_of_connected {{count 0}} {

  global cur_s HIERARCHY cur_c

  if {[is_placement $cur_s]} {
    # special case for dpc placment file, expand selected
    dpc_unexpand_hier_place

    return 
  }

  if {[info exists HIERARCHY] != 1} {
    return
  }

  if {$HIERARCHY == ""} {
    # no where to go
    return
  }

  busy

  upvar #0 TERMS_$cur_s TERMS
  set cell $cur_s

  if {[llength [array names TERMS]] < 2} {
    busy
    puts "Generating terminal names for \"$cur_s\"."
    generate_term_names
    ready
  }

  # find the selected port
  set port ""
  foreach sel_id [$cur_c find withtag selected] {
    if {[info exists TERMS($sel_id)]} { 
      set port $TERMS($sel_id)
      break
    }
  }

  if {$port == ""} {
    if {$count == 1 || [$cur_c find withtag selected] == ""} {
      warning "Aborting, can't find a wire/port to follow.  Try again."
      ready
      return
    }

    puts "Generating terminal names for \"$cur_s\"."
    generate_term_names
    
    # try again
    ready

    pop_out_of_connected 1

    return
  }

  set schematic [lindex $HIERARCHY 0]
  set HIERARCHY [lrange $HIERARCHY 1 end]

  goto_schematic [lindex [split $schematic ,] 0]

  setl {parent inst} [split $schematic ,]

  upvar #0 TERMS_$cur_s TERMS

  if {[llength [array names TERMS]] < 2} {
    busy
    puts "Generating terminal names for \"$cur_s\"."
    generate_term_names
    ready
  }

  # get location of port of instance
  set port_id ""
  foreach term_id [$cur_c find withtag "term&inst$inst"] {
    set tags [$cur_c gettags $term_id]
    set name [lindex [lindex $tags [lsearch $tags "name*"]] 3]

    # is this a direct match?
    if {$port == $name} {
      # got it
      set port_id $term_id
      break
    }

    # is this a bus subset? (like in[2] in in[3:0])
    set root1 [bus_root $port]
    set root2 [bus_root $name]

    if {$root1 == $root2 && [bus_subset $port $name]} {
      # got it
      set port_id $term_id
      break
    }
  }

  if {$port_id == ""} {
    # go back
    set save $cur_s
    set HIERARCHY "$cur_s,$inst $HIERARCHY"
    goto_schematic $cell
    ready

    warning "ERROR: Port \"$port\" in \"$cell\" doesn't translate to anything in \"$save\"."

    return
  }

  if {![info exists TERMS($port_id)]} {
    # try generating term names again
    puts "Generating terminal names for \"$cur_s\"."
    generate_term_names

    if {![info exists TERMS($port_id)]} {
      # go back
      set save $cur_s
      set HIERARCHY "$cur_s,$inst $HIERARCHY"
      goto_schematic $cell
      ready

      warning "ERROR: Port \"$port\" in \"$cell\" doesn't translate to anything in \"$save\"."
      return
    }
  }

  # should follow bus bits
  set net $TERMS($port_id)

  if {[is_bus $port] && [is_bus $net]} {
    # figure out the bit translation
    set net [bit_convert $port $name $net]
  }

  select_by_name $net
  puts "Port \"$port\" in \"$cell\" becomes net \"$net\" in \"$cur_s\"."

  # also select the cell we came from
  select_ids $inst add no_display

  ready
  return
}


# Copies an entire schematic to a new canvas with a new name

proc copy_schematic {{schematic ""}} {

  global cur_c cur_s scale SUE PROC
  global SUE_${cur_s}

  set copy_schematic $cur_s

  # if this is an icon, only copy the icon, not the schematic
  if {[is_icon $cur_s]} {
    # copy the icon and show the new icon in a canvas

    if {[info exists SUE($schematic)]} {
      sue_error "Aborting.  Icon [get_rootname $schematic] already exists"
      sue_error flush
      return -1
    }

    # make a new one.  this will ask for the new name
    set id [make_new_schematic [get_rootname $schematic] I]
    if {$id == ""} {
      # cancelled
      return -1
    }

    busy
    puts "Copying $copy_schematic to $cur_s"

    # now put the old icon in it
    icon_make [get_rootname $copy_schematic] ""

    # is only needed for sccs title bar, but use this procedure anyways
    update_title_bar

    # make this modified
    is_modified

    zoom_to_fit

    ready
    return
  }

  # duplicate the schematic
  if {$schematic != "" && [info exists SUE($schematic)]} {
    sue_error "Aborting.  Schematic $schematic already exists"
    sue_error flush
    return -1
  }

  busy

  global PROC
  set PROC ""

  set save_scale $scale
  scale_canvas 10

  set icon ICON_$cur_s

  write_instances
  write_wires
  write_draw_items

  scale_canvas $save_scale

  # the PROC global can get squashed
  set save_proc $PROC
  unset PROC

  ready

  # make a new one.  this will ask for the new name
  set id [make_new_schematic $schematic]
  if {$id == ""} {
    # cancelled
    return -1
  }

  busy

  # put everything from the first one into it.
  foreach line $save_proc {
    eval $line
  }

  # is only needed for sccs title bar, but use this procedure anyways
  update_title_bar

  if {$save_proc != ""} {
    # flag that this canvas has been modified
    is_modified
  }

  zoom_to_fit

  # update so user can see it while we figure out connect info.
  update

  integer_scale

  # show connection info
  show_connects "" fast

  unscale

  # does this have an icon with it? (if you are already in the icon
  # then you don't get a copy of the schematic, even if there is one).
  if {[info commands $icon] != ""} {
    # copy the icon procedure
    upvar #0 icon_[get_rootname $icon] g_data
    if {[use_first g_data(generator)] != ""} {
      # special for generators
      set save_cur_s $cur_s
      goto_schematic $icon
      write_icon return

      goto_schematic $save_cur_s

      proc ICON_$cur_s {args} [reset_sccs_title_bar $PROC]

    } else {
      proc ICON_$cur_s [info args $icon] \
	  [reset_sccs_title_bar [info body $icon]]
    }

    # need to enter this icon into the auto index
    global auto_index SUE_auto_index SUE_$cur_s
    set auto_index(ICON_$cur_s) "source [set SUE_${cur_s}(filename)]"
    set SUE_auto_index(ICON_$cur_s) "source [set SUE_${cur_s}(filename)]"
    # update the icon listbox
    make_icon_listbox
  }

  # replace recursive icons if there are any
  set ids [$cur_c find withtag icon_$copy_schematic]
  if {$ids != ""} {
    # need to make a bogus icon first
    set bogus_id [make $cur_s]

    # now replace all recursive icons
    foreach id $ids {
      remake $id $bogus_id
    }

    # delete bogus icon and data structures
    $cur_c delete inst$bogus_id
    upvar #0 ${cur_s}_inst$bogus_id i_data
    unset i_data
  }

  ready
}


# Walk down the hierachy and save modified cells.

proc modified_save_and_leaves {schematic} {

  global SCHEMS

  modify_setup

  catch {unset SCHEMS}

  modified_save_and_leaves_int [get_rootname $schematic]

  if {![info exists SCHEMS(written)]} {
    puts "No cells need to be saved."
  }
}


proc modified_save_and_leaves_int {schematic} {

  global cur_c cur_s SCHEMS SUE

  if {[info exists SCHEMS($schematic)]} {
    # already been here
    return
  }

  set SCHEMS($schematic) traced

  upvar #0 SUE_$schematic schem_array
  upvar #0 SUE_ICON_$schematic icon_array

  if {([info exists SUE($schematic)] && $schem_array(modified) != "") || \
	  ([info exists SUE(ICON_$schematic)] && $icon_array(modified) != "")} {
    write_file $schematic
    set SCHEMS(written) 1
  }
  
  if {![info exists SUE($schematic)]} {
    return
  }

  set canvas $schem_array(canvas)

  foreach id [$canvas find withtag origin] {
    upvar #0 ${schematic}_inst${id} i_data
    # the type is really the instance name
    set type $i_data(type)

    # if this has a schematic, trace down through it's hierarchy
    if {[info exists SUE($type)] || [info exists SUE(ICON_$type)]} {
      modified_save_and_leaves_int $type
    }
  }
}


# Changes the path of a given schematic and it's icon

proc change_path {{filename ""}} {

  global cur_c cur_s scale SUE SUFFIX

  set schematic [get_rootname $cur_s]
  global SUE_${schematic}

  # if there is no schematic, then look in the icon
  if {[info exists SUE_${schematic}(canvas)] != 1} {
    set schematic $cur_s
    global SUE_${schematic}
  }

  set dir [set SUE_${schematic}(dir)]
  if {$dir == ""} {
    set dir "[pwd]/"
  }

  set rootname [get_rootname $schematic]

  # Prompt for a file name
  if {$filename == ""} {
    set filename [fs_box -message "Enter New Path:" \
		      -filename "$dir${rootname}.sue" -dironly_ok 1]
  }

  # if nil, file selector box cancelled -- do nothing
  if {$filename == ""} { 
    return 
  }

  setl {dir new_schematic suffix} [split_filename $filename $rootname 1]
  if {$new_schematic == ""} {
    # bad name
    sue_error "Aborting, bad schematic name."
    sue_error flush

    return
  }

  if {![file isdir $dir]} {
    # not a directory, abort
    sue_error "Aborting. $filename is not a valid directory."
    sue_error flush
    return 0
  }

  if {$new_schematic != "" && $new_schematic != $rootname} {
    # the user is trying to change the name also.
    sue_error "Aborting. Can't change file name, only path."
    sue_error flush
    return 0
  }

  if {[set SUE_${schematic}(dir)] != $dir} {
    # remake the filename stuff
    make_filename $dir $suffix

    # since it hasn't been saved out at the new location, it's modified.
    is_modified

    update_title_bar

    puts "Changing path of cell \"$schematic\" to $dir"

    # if the icon already exists in a canvas, fix its title_bar
    if {![is_icon $schematic]} {
      update_cell_title_bar ICON_$rootname
    }
	
    # possibly rearranged some icons
    make_icon_listbox
  }

  display_title
}


# resets the title bar in the current canvas

proc update_title_bar {{version ""} {date ""}} {

  global cur_s cur_c

  # remake the title_bar if it exists to display new date, dir.
  foreach id [concat [$cur_c find withtag icon_title_bar] \
		  [$cur_c find withtag icon_sccs_title_bar]] {
    # title bar has no ports so don't need to scale
    upvar #0 ${cur_s}_inst$id i_data
    set i_data(_last_modified_by) [lindex [exec who am i] 0]
    remake $id $id dont_modify no_scale
  }

  if {$version == "title_bar"} {
    return
  }

  # remake/reset the sccs title bar if it exists
  foreach id [$cur_c find withtag icon_sccs_title_bar] {
    # reset the version/date
    upvar #0 ${cur_s}_inst$id i_data
    set i_data(_version) $version
    set i_data(_date) $date
    set i_data(_comment) ""
    
    # title bar has no ports so don't need to scale
    remake $id $id dont_modify no_scale
  }
}


# fix up the sccs title bar in the given cell

proc update_cell_title_bar {icon {version ""} {date ""}} {

  global cur_s cur_c scale
  global SUE_$icon

  if {[is_icon $icon]} {
    set proc_name $icon
  } else {
    set proc_name SCHEMATIC_$icon
  }

  # is this cell in a canvas?
  if {[info exists SUE_${icon}(canvas)]} {
    # save the current canvas, schematic, and scale
    set save_cur_c $cur_c
    set save_cur_s $cur_s
    set save_scale $scale

    # set to icon
    set cur_s $icon
    set cur_c [set SUE_${icon}(canvas)]
    set scale [set SUE_${icon}(scale)]

    update_title_bar $version $date

    # restore the current canvas, schematic, and scale
    set cur_c $save_cur_c
    set cur_s $save_cur_s
    set scale $save_scale

  } elseif {[info commands $proc_name] != ""} {
    # reset the sccs title bar in the icon procedure
    proc $proc_name [info args $proc_name] \
	[reset_sccs_title_bar [info body $proc_name] $version $date]
  }
}


# count { and } and see if there are the same number

proc unbalanced {line} {
  
  set index 0
  set count 0
  while {[set pos [string first \{ [string range $line $index end]]] != -1} {
    incr count
    set index [expr $index + $pos + 1]
  }
  set index 0
  while {[set pos [string first \} [string range $line $index end]]] != -1} {
    incr count -1
    set index [expr $index + $pos + 1]
  }

  return $count
}


# must reset the sccs title bar even if it's not in a canvas

proc reset_sccs_title_bar {lines {version ""} {date ""}} {

  # if there is no sccs_title_bar, just return the lines
  if {[string first sccs_title_bar $lines] == -1} {
    return $lines
  }

  # now we have to change the sccs_title_bar line.  This is a hack.
  set new_lines ""

  # first get rid on continuations
#  regsub -all {(\\)(\n)} $lines "" lines

  set line ""
  foreach a_line [split $lines \n] {
    if {$line == ""} {
      set line $a_line
    } else {
      set line "$line\n$a_line"
    }
    # is this a complete line?
    if {[unbalanced $line] != 0} {
      continue
    }

    if {[lsearch -exact $line sccs_title_bar] != -1} {
      set pos [lsearch -exact $line -date]
      if {$pos != -1} {
	if {$date == ""} {
	  set line [lreplace $line $pos [incr pos]]
	} else {
	  set line [lreplace $line [incr pos] $pos $date]
	}
      } else {
	# need to add this if date is passed to function
	if {$version != ""} {
	  set line "$line -date $date"
	}
      }
      set pos [lsearch -exact $line -version]
      if {$pos != -1} {
	if {$version == ""} {
	  set line [lreplace $line $pos [incr pos]]
	} else {
	  set line [lreplace $line [incr pos] $pos $version]
	}
      } else {
	# need to add this if version is passed to function
	if {$version != ""} {
	  set line "$line -version $version"
	}
      }
      set pos [lsearch -exact $line -comment]
      if {$pos != -1} {
	set line [lreplace $line $pos [incr pos]]
      }
    }
    lappend new_lines $line
    set line ""
  }

  set lines [join $new_lines \n]
  return $lines
}


# deletes a schematic or icon.  Doesn't delete associated schematic/icon.

proc delete_schematic {schematic {even_no_name ""} {batch ""}} {

  global cur_s SUE MODIFY SUE_DIR SUE_auto_index auto_index _MAKE_

  # is the thing to be deleted in any canvas
  if {![info exists SUE($schematic)]} {
    # not in a canvas
    if {[is_icon $schematic]} {
      if {[info commands $schematic] != ""} {
	# lose the icon procedure
	set schematic_name [get_rootname $schematic]
	puts "Icon \"$schematic_name\" deleted."
	rename $schematic ""

	# removed the compiled versions, if they exist
	catch {unset _MAKE_($schematic_name)}
	catch {rename _MAKE_$schematic_name ""}
	catch {rename _MAKE90_$schematic_name ""}

	catch {unset SUE_auto_index($schematic)}
	catch {unset auto_index($schematic)}

	# update the icon listbox
	make_icon_listbox

	return 1
      }
    } else {
      # must be a schematic
      if {[info commands SCHEMATIC_$schematic] != ""} {
	# lose the schematic procedure
	rename SCHEMATIC_$schematic ""
	catch {unset SUE_auto_index(SCHEMATIC_$schematic)}
	catch {unset auto_index(SCHEMATIC_$schematic)}
	puts "Schematic \"$schematic\" deleted."
	# don't need to update schematic listbox since it isn't there.
	return 1
      }
    }

    # no lo existo
    return 0
  }

  global SUE_$schematic

  # if the canvas is modified, ask the user for confirmation before deleting
  set modified_cells ""
  if {[set SUE_${schematic}(modified)] != ""} {
    if {[is_icon $schematic]} {
      set icon [get_rootname $schematic]
      lappend modified_cells "Icon \"$icon\" is modified."
    } else {
      lappend modified_cells "Schematic \"$schematic\" is modified."
    }
  }

  if {$modified_cells != "" && $batch == ""} {
    set button [tk_dialog .delete "Delete Buffers" \
		    [join $modified_cells "\n"] \
		    @$SUE_DIR/sue_icon.xbm 0 {delete} {cancel}]

    if {$button == 1} {
      # user hit the cancel key
      return -1
    }
  }

  if {$cur_s == $schematic} {
    # goto bogus scratch schematic
    if {$even_no_name == ""} {
      make_new_schematic no_name
    }
  }

  set canvas [set SUE_${schematic}(canvas)]

  # remove any instance data
  foreach id [$canvas find withtag origin] {
    global ${schematic}_inst$id
    catch "unset ${schematic}_inst$id"
  }

  # Now delete the canvas
  destroy $canvas

  unset SUE($schematic)
  unset SUE_$schematic

  # remove modify history if it exists
  catch "unset MODIFY($schematic)"

  set schematic_name [get_rootname $schematic]

  # remove netlist cached data
  global NETLIST_CACHE TERM_CACHE
  catch {unset NETLIST_CACHE($schematic_name)}
  catch {unset NETLIST_CACHE($schematic_name,error)}
  catch {unset NETLIST_CACHE($schematic_name,warnings)}
  catch {unset NETLIST_CACHE($schematic_name,cells)}
  catch {unset NETLIST_CACHE($schematic_name,names)}
  catch {unset NETLIST_CACHE($schematic_name,wires)}
  set TERM_CACHE($schematic_name,terms) ""

  upvar #0 TERMS_$schematic_name TERMS
  upvar #0 RTERMS_$schematic_name RTERMS
  catch {unset TERMS}
  catch {unset RTERMS}

  # remove associated procs
  if {[is_icon $schematic]} {
    # lose the icon
    rename ICON_$schematic_name ""
    catch {unset _MAKE_($schematic_name)}
    catch {rename _MAKE_$schematic_name ""}
    catch {unset SUE_auto_index($schematic)}
    catch {unset auto_index($schematic)}

    puts "Icon \"$schematic_name\" deleted."

    # update the icon listbox
    make_icon_listbox

  } else {
    # lose the schematic procedure if it exists
    catch {rename SCHEMATIC_$schematic_name {}}
    catch {unset SUE_auto_index(SCHEMATIC_$schematic)}
    catch {unset auto_index(SCHEMATIC_$schematic)}

    puts "Schematic \"$schematic_name\" deleted."

    # take out of schematic listbox
    remove_schematic_from_listbox $schematic
  }

  # special case for no_name schematic
  if {$schematic_name == "no_name" && $even_no_name == ""} {
    # make a new empty schematic
    make_new_schematic no_name
  }

  return 1
}


# revert the buffer (both schematic and icon) of the current canvas.

proc revert {} {

  global cur_s SUE HIERARCHY

  set canvas $cur_s
  set schematic [get_rootname $cur_s]
  set save_hierarchy [use_first HIERARCHY]

  # get the full pathname of this cell
  global SUE_${schematic}
  # if there is no schematic, then look in the icon
  if {[info exists SUE_${schematic}(canvas)] != 1} {
    global SUE_$cur_s
    set filename [set SUE_${cur_s}(filename)]
  } else {
    set filename [set SUE_${schematic}(filename)]
  }

  if {![file readable $filename]} {
    # user hit cancel
    warning "Aborting revert.  Cannot read file \"$filename\""
    return
  }

  # remember if the icon associated with this call has been modified
  set modified_icon 0
  if {[info exists SUE(ICON_$schematic)]} {
    upvar #0 SUE_ICON_$schematic data
    if {$data(modified) == "M"} {
      set modified_icon 1
    }
  }

  # first get rid of the existing schematic and icon
  if {[delete_schematic $schematic 1] == -1} {
    # user hit cancel
    puts "Aborting revert."
    return
  }
  if {[delete_schematic ICON_$schematic] == -1} {
    # user hit cancel
    puts "Aborting revert."
    return
  }

  # now reload it
  load_schematic $filename

  # pretend that this icon was modified so the changes will propagate
  if {$modified_icon} {
    goto_schematic ICON_$schematic
    upvar #0 SUE_$cur_s data
    set data(modify_icon) M
    remember_modified
    set data(modify_icon) ""
  }

  # goto it if was an icon
  goto_schematic $canvas

  if {[get_rootname $cur_s] != $canvas && $cur_s != $canvas} {
    # must have been a problem reloading this
    set HIERARCHY ""

  } else {
    # return hierarchy to where it was
    set HIERARCHY $save_hierarchy
  }

  return
}


# Slightly different than file rootname because foo.bar.baz needs to
# have a rootname of foo and a suffix of bar.baz since we can't have
# "." in a windowname.  Also, directory comes complete with trailing /

proc split_filename {filename {default_cell_name ""} {isdir 0}} {

  global SUFFIX

  # is this a directory but not a sue file when including a suffix
  if {[file isdir $filename] && ![file isfile $filename$SUFFIX(default)] && \
	$isdir} {
    set dir [clean_dir $filename]/
    set fileroot $default_cell_name
    set suffix ""
    
  } else {
    if {[file dirname $filename] == "."} {
      set dir ""
    } else {
      set dir [clean_dir [file dirname $filename]]/
    }

    set fileparts [split [file tail $filename] .]
    set fileroot [lindex $fileparts 0]
    if {$default_cell_name != ""} {
      set fileroot $default_cell_name
    }
    set suffix [join [lrange $fileparts 1 end] .]
    if {$suffix != ""} {
      set suffix .$suffix
    }
  }

  if {$suffix == ""} {
    set suffix $SUFFIX(default)
  }

  # need to use "list" here
  return [list $dir $fileroot $suffix]
}


# icon's are always of the form ICON_<name>

proc is_icon {name} {

  if {[string range $name 0 4] == "ICON_"} {
    return 1
  } else {
    return 0
  }
}


# Checks to see if the path of the filename is already in the auto_path
# and if not adds it and recomputes the tclindex.

proc add_auto_path {filename} {

  global auto_path SUFFIX auto_index SUE_auto_index auto_oldpath
  global TCLINDEX_TIME

  set date 0
  # is the filename a directory
  if {[file isdir $filename]} {
    set dir [clean_dir $filename]
  } else {
    # no, it must be a file
    set dir [clean_dir [file dirname $filename]]
    catch "set date \[file mtime $filename\]"
  }

  # figure out the appropriate suffix
  set suffix [file extension $filename]
  if {$suffix == $SUFFIX(backup)} {
    # strip off the backup suffix
    set suffix [file extension [string range $filename 0 \
				    [expr [string last . $filename] - 1]]]
  }
  if {$suffix == "" || $suffix == "." || $suffix == $SUFFIX(auto_save)} {
    set suffix $SUFFIX(default)
  }

  if {[info exists TCLINDEX_TIME($dir)]} {
    # use value from cached but not saved
    set index_date $TCLINDEX_TIME($dir)
  } elseif {[catch "set index_date \[file mtime $dir/tclIndex\]"] != 0} {
    set index_date -10
  }

  # compute a new tcltags if needed 
  set SUFFIX($dir) [use_first SUFFIX($dir) SUFFIX(tclindex)]
  if {[lsearch $auto_path $dir] == -1 || $date > $index_date || \
	  [lsearch $SUFFIX($dir) "*$suffix"] == -1} {

    # get rid of auto_load caching -- in init.tcl stuff
    set auto_oldpath ""

    # remember this suffix for the next time
    if {[lsearch $SUFFIX($dir) "*$suffix"] == -1} {
      lappend SUFFIX($dir) *$suffix
    }

    # add directory to auto path if needed.
    if {[lsearch $auto_path $dir] == -1} {
      puts "Added $dir to auto_path."
#     set auto_path ". $dir [lremove $auto_path .]"
      set auto_path "$dir $auto_path"
    }

    puts "Computing tclIndex ($SUFFIX($dir)) for $dir ..."
    # auto_mkindex seems to change the pwd
    set cwd [pwd]
    # look for , files.  These are turds left over from sccs create that
    # can accidentally get into the tclIndex and cause sue to use outdated
    # icons/schematics.
#    cd $dir
#    set files [eval glob $SUFFIX($dir)]
#    if {[lsearch $files ,*] != -1} {
      # bad news
#      puts "SUE ERROR: Directory $dir contains files of the form ,filename.  These were probably left over from sccs.  Delete them and restart sue or suffer the consequences ..."
#    }

#    if {![file exists $dir/tclIndex]} {
#      # probably just a new directory, try making a tclIndex
#      catch "exec touch $dir/tclIndex"
#    }

#    if {[file writable $dir/tclIndex]} {
      # always include *.tcl
      if {[catch "sue_auto_mkindex $dir $SUFFIX($dir)" msg]} {
	puts "SUE Warning: $msg"
      }
#    } else {
#      puts "SUE Warning: $dir/tclIndex not writable, assuming up-to-date."
#    }

    cd $cwd
  }

  # make sure all tclIndex's are loaded
  auto_load_index

  # Now add in any of SUE's own special auto_path things
  fixup_auto_index
}


# This is SUE's own addendum to the auto_index for things that haven't
# been saved yet.

proc add_to_auto_index {schematic filename} {

  global SUE_auto_index auto_index

  # Now put this directory into the auto_index variable
  if {[info commands SCHEMATIC_$schematic] != ""} {
    set SUE_auto_index(SCHEMATIC_$schematic) "source $filename"
    set auto_index(SCHEMATIC_$schematic) "source $filename"
  }
  if {[info commands ICON_$schematic] != ""} {
    set SUE_auto_index(ICON_$schematic) "source $filename"
    set auto_index(ICON_$schematic) "source $filename"
  }
}


# auto loads all files in the directories.  If the file to be loaded
# appears to be eclipsed by a file higher in the auto_path then the
# higher one will be loaded instead.

proc auto_load_directory {dir {type ""}} {

  global auto_index SUFFIX

  set dir [clean_dir $dir]
  if {$type == ""} {
    puts "Loading all cells from directory $dir"
  }

  foreach file [glob -nocomplain $dir/*$SUFFIX(default)] {
    set cell [file tail [file root $file]]

    if {[info exists auto_index(ICON_$cell)] && \
	    [file dirname [lindex $auto_index(ICON_$cell) 1]] != $dir} {
      # if shadowed, get other
      eval $auto_index(ICON_$cell)
      continue
    }
    if {[info exists auto_index(SCHEMATIC_$cell)] && \
	    [file dirname [lindex $auto_index(SCHEMATIC_$cell) 1]] != $dir} {
      # if shadowed, get other
      eval $auto_index(SCHEMATIC_$cell)
      continue
    }

    if {[file readable $file]} {
      if {[catch "source $file" msg]} {
	puts "ERROR: couldn't read file $file: $msg"
      }
    } else {
#	sue_error "Couldn't read file $file.  Check permissions."
	puts "ERROR: Couldn't read file $file.  Check permissions."
    }

#    sue_error flush
  }
}


# Tries to create the filename field in the SUE data structure
# if no directory is given, uses the directory from the auto_load path
# Tries to keep the schematic and icon (if there are both) filenames
# in sync.

proc make_filename {{dir ""} {suffix ""}} {

  global cur_s auto_index SUFFIX

  upvar #0 SUE_$cur_s data

  set schematic [get_rootname $cur_s]

  # figure out the filename
  if {[use_first data(filename)] != ""} {
    set filename [file root [file tail $data(filename)]]
  } elseif {[info exists auto_index(SCHEMATIC_$schematic)]} {
    set filename [file root [file tail \
				 [lindex $auto_index(SCHEMATIC_$schematic) 1]]]
  } elseif {[info exists auto_index(ICON_$schematic)]} {
    set filename [file root [file tail \
				 [lindex $auto_index(ICON_$schematic) 1]]]
  } else {
    set filename $schematic
  }

  # figure out the correct directory to use
  if {[string index $dir 0] == "."} {
    set dir [pwd][string range $dir 1 end]
  }

  if {$dir == ""} {
    if {![info exists data(dir)]} {
      set data(dir) ""
    }

    if {[string index $data(dir) 0] == "."} {
      set data(dir) [pwd][string range $data(dir) 1 end]
    }

    if {$data(dir) == ""} {
      # use the auto-load directory if it exists
      if {[info exists auto_index(SCHEMATIC_$schematic)]} {
	set dir [file dirname [lindex $auto_index(SCHEMATIC_$schematic) 1]]/

      } elseif {[info exists auto_index(ICON_$schematic)]} {
	set dir [file dirname [lindex $auto_index(ICON_$schematic) 1]]/

      } else {
	set dir [pwd]/
      }

      if {[string index $dir 0] == "."} {
	set dir [pwd][string range $dir 1 end]
      }
      set data(dir) $dir

    } else {
      set dir $data(dir)
    }
  } else {
    set data(dir) $dir
  }

  if {$suffix == ""} {
    if {[info exists data(suffix)]} {
      set suffix $data(suffix)
    } else {
      set suffix $SUFFIX(default)
      set data(suffix) $suffix
    }
  } else {
    # remove backup extension if it exists
    if {[file extension $suffix] == $SUFFIX(backup)} {
      set suffix [string range $suffix 0 [expr [string length $suffix] - \
					      [string length $SUFFIX(backup)] - 1]]
    }
    set data(suffix) $suffix
  }

  set data(filename) "$dir$filename$suffix"

  # If there is another view, then change that one also.
  upvar #0 SUE_[corresponding_cell $cur_s] c_data
  if {[info exists c_data(dir)]} {
    set c_data(dir) $data(dir)
    set c_data(suffix) $data(suffix)
    set c_data(filename) $data(filename)

    # make the same read only status as the one already loaded
    set data(read_only) $c_data(read_only)
  }

  add_to_auto_index $schematic $data(filename)
}


# checks to make sure that the user is getting icons/schematics only
# out of files of the same name.  Also alerts the user to potential
# icon/schematic shadowing

proc check_filesystem {} {

  global auto_index auto_path SUFFIX SUE_auto_index

  busy

  # make sure the autoindexes are completely loaded
  auto_load_index

  set results ""

  # first check for icons/schematics in the wrong files
  set pairs ""
  foreach proc [array names auto_index] {
    if {[string first ICON_ $proc] == 0 || \
	    [string first SCHEMATIC_ $proc] == 0} {
      # found an icon or schematic
      set file [file tail [lindex $auto_index($proc) 1]]

      # file name should be the same as the cell name and the suffix 
      # should be correct
      set name [join [lrange [split $proc _] 1 end] _]

      if {$name == [file rootname $file] && \
	      $SUFFIX(default) == [file extension $file]} {
	# everything's kosher
	continue
      }

      # check for generators which don't actually have files
      if {[file dirname [lindex $auto_index($proc) 1]] == "generators"} {
	# this is a generator
	continue
      }

      lappend pairs "  [lindex $auto_index($proc) 1] -> $name"
    }
  }

  if {$pairs != ""} {
    lappend results "WARNING, the following ICON/SCHEMATIC procedures are in improper files:"
    set pairs [lsort $pairs]
    lappend results [join $pairs \n]
  } else {
    lappend results "All ICON/SCHEMATIC procedures are in the correct files."
  }

  lappend results "\nChecking ICON/SCHEMATIC shadowing ..."

  # now check for icon/schematic shadowing
  set save_auto_path $auto_path

  set shadow 0

  # walk through each directory
  foreach path $auto_path {
    # make a new auto_index for just this directory
    catch {unset auto_index}
    set auto_path $path
    auto_load_index

    if {[info exists auto_index]} {
      foreach proc [array names auto_index] {
	if {[string first ICON_ $proc] == 0 || \
		[string first SCHEMATIC_ $proc] == 0 || \
		[string first NAME_ $proc] == 0} {
	  if {[info exists procs($proc)] && \
		  [lindex $auto_index($proc) 1] != [lindex $procs($proc) 1]} {
	    # this file is being shadowed
	    lappend results "  $proc from [lindex $auto_index($proc) 1] is being shadowed by [lindex $procs($proc) 1]"
	    set shadow 1

	  } else {
	    set procs($proc) $auto_index($proc)
	  }
	}
      }
    }
  }

  if {$shadow == 0} {
    lappend results "  No cell shadowing."
  }

  # restore the auto_index
  set auto_path $save_auto_path
  auto_load_index

  fixup_auto_index

  # display in a popup
  warning [join $results \n]

  puts "done."

  ready
}


# after any changes to the auto_path, we need to fix up the auto_index
# to include special SUE stuff.

proc fixup_auto_index {} {

  global auto_index SUE_auto_index

  if {[info exists SUE_auto_index]} {
    foreach cell [array names SUE_auto_index] {
      if {$SUE_auto_index($cell) != [use_first auto_index($cell)]} {
	set auto_index($cell) $SUE_auto_index($cell)
      }
    }
  }
}


# Popup menu to toggle read only status of cell(s)

proc toggle_read_only {} {

  global cur_s READ_ONLY

  set message "Change Read-Only Status: "
  set title "Read-Only Options"

  set prop_list ""

  set operation toggle
  lappend prop_list [list "operation" operation radio {toggle set unset}]

  set what "this cell"
  lappend prop_list [list "applied to" what radio \
			 {"this cell" "all cells"}]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  if {$what == "all cells"} {
    set read_onlys [change_read_only_status $operation]

    if {$operation == "set" || ($operation == "toggle" && $read_onlys > 0)} {
      # change all subsequent cells loaded to be read-only
      puts "All cells and ones yet loaded will be read only."
      set READ_ONLY 1

    } else {
      # change all subsequent cells loaded to be not read-only
      puts "All cells and ones yet loaded will not be read only."
      set READ_ONLY 0
    }

  } else {
    # only this cell and corresponding
    change_read_only_status $operation $cur_s
  }

  display_selection
}


# changes read-only status of all cells or given cell

proc change_read_only_status {operation {cells "all"}} {

  global SUE

  if {$cells == "all"} {
    set cells [array names SUE]

  } else {
    # include other view if it exists
    set other [corresponding_cell $cells]
    if {[info exist SUE($other)]} {
      lappend cells $other
    }
  }

  # for toggle
  set read_onlys 0

  foreach cell $cells {
    upvar #0 SUE_$cell data

    switch $operation {
      set {
	set data(read_only) 1
      }

      unset {
	set data(read_only) 0
      }

      toggle {
	set data(read_only) [expr 1 - $data(read_only)]

	if {$data(read_only)} {
	  incr read_onlys
	} else {
	  incr read_onlys -1
	}
      }
    }
  }

  display_title

  return $read_onlys
}


# reset the title_bar/sccs_title_bar, not in a canvas

proc reset_title_bar {lines} {

  # if there is no title_bar, just return the lines
  if {[string first title_bar $lines] == -1} {
    return $lines
  }

  # now we have to change the title_bar line.  This is a hack.
  set new_lines ""

  # first get rid on continuations
#  regsub -all {(\\)(\n)} $lines "" lines

  set line ""
  foreach a_line [split $lines \n] {
    if {$line == ""} {
      set line $a_line
    } else {
      set line "$line\n$a_line"
    }
    # is this a complete line?
    if {[unbalanced $line] != 0} {
      continue
    }

    if {[lsearch -exact $line sccs_title_bar] != -1 || \
	    [lsearch -exact $line title_bar] != -1} {
      set pos [lsearch -exact $line -last_modified_by]
      if {$pos != -1} {
	set line [lreplace $line [incr pos] $pos [lindex [exec who am i] 0]]
      } else {
	# need to add this argument
	set line "$line -last_modified_by [lindex [exec who am i] 0]"
      }
    }

    lappend new_lines $line
    set line ""
  }

  set lines [join $new_lines \n]
  return $lines
}

