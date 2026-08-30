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


# Routines to write schematic/icon procedures into a file

# If the schematic and/or icon includes the sccs_title_bar then we are
# going to check this into sccs in addition to saving it.

proc write_file {schematic} {

  global cur_s cur_c DEFAULT_SCCS_COMMENT DEFAULT_SCCS SUE_DIR NO_SCCS SCCS

  modify_setup

  set schematic_name [get_rootname $schematic]

  # first see if this is a generator base schematic
  if {[is_generator $schematic_name]} {
    # alert user we found a generator and abort.
    set button [tk_dialog .sccs_query "Can't Overwrite Generator" \
		      "Aborting, can't overwrite a generator.  SUE Copy this to another cell name if you really want to save this." \
		      @$SUE_DIR/sue_icon.xbm 0 {ok}]
    return
  }

  set save_cur_s $cur_s
  set sccs ""

  # look next for sccs title bar in the schematic
  global SUE_$schematic_name
  set canvas [use_first SUE_${schematic_name}(canvas)]
  if {$canvas == ""} {
    # no canvas.  Could still have the sccs title bar in the procedure
    if {[info commands SCHEMATIC_$schematic] != "" && \
	    [lsearch [info body SCHEMATIC_$schematic] sccs_title_bar] != -1} {
      # found it but first must make the canvas
      goto_schematic $schematic_name
      set canvas $cur_c
      set id [lindex [$canvas find withtag icon_sccs_title_bar] 0]
      if {$id != ""} {
	# found it
	set sccs 1
	upvar #0 ${schematic_name}_inst$id i_data
	set version $i_data(_version)
	set comment $i_data(_comment)
	set filename [set SUE_${schematic_name}(filename)]
      }
      # return to where we were
      goto_schematic $save_cur_s
      update
    }
  } else {
    # there is a schematic canvas
    set id [lindex [$canvas find withtag icon_sccs_title_bar] 0]
    if {$id != ""} {
      # found it
      set sccs 1
      upvar #0 ${schematic_name}_inst$id i_data
      set version $i_data(_version)
      set comment $i_data(_comment)
      set filename [set SUE_${schematic_name}(filename)]
    }
  }

  # now look for an sccs title bar in the icon
  set icon_name ICON_$schematic_name

  global SUE_$icon_name
  set canvas [use_first SUE_${icon_name}(canvas)]
  if {$canvas == ""} {
    # no canvas.  Could still have the sccs title bar in the procedure
    if {[info commands ICON_$schematic] != "" && \
	    [lsearch [info body ICON_$schematic] sccs_title_bar] != -1} {
      # found it in the icon procedure
      if {$sccs == ""} {
	# got to get the info out of the icon.  Easiest way is to put the
	# icon in a canvas.
	goto_schematic $icon_name
	set canvas [use_first SUE_${icon_name}(canvas)]

	# return to where we were
	goto_schematic $save_cur_s
	update
      }
    }
  }
  if {$canvas != ""} {
    # there is an icon canvas
    set id [lindex [$canvas find withtag icon_sccs_title_bar] 0]
    if {$id != ""} {
      # found it
      set sccs 1
      upvar #0 ${icon_name}_inst$id i_data
      # use the version/filename from the schematic if there is
      # one.  Note that they should be the same.
      set version [use_first version i_data(_version)]
      if {[use_first comment] == ""} {
	set comment $i_data(_comment)
      } else {
	# if comments in both icon and schematic, append them together.
	append comment "  $i_data(_comment)"
      }
      set filename [use_first filename SUE_${icon_name}(filename)]
    }
  }

  if {$sccs == "" && [use_first DEFAULT_SCCS] != ""} {
    set sccs 1
    # hmmmm
    set version ""
  }

  if {[use_first NO_SCCS] == 1} {
    # user doesn't have sccs so just skip
    set sccs ""
  }

  if {$sccs != ""} {
    # check to make sure the user has access to SCCS
    if {![executable_exists $SCCS]} {
      # can't find sccs
      set sccs ""

      # ask user if we should continue
      set button [tk_dialog .sccs_query "Can't find SCCS" \
		      "Can't execute SCCS when saving cell \"$schematic\".\nCheck your path for sccs.\nSave anyways? (note you may have to unwriteprotect \"$schematic.sue\" and try again)" \
		      @$SUE_DIR/sue_icon.xbm 0 {save} {cancel}]
      if {$button == 1} {
	# user hit the cancel key
	return
      }
    }
  }

  if {$sccs == ""} {
    # just do a normal write
    write_file_int $schematic

  } else {
    # do an sccs check-out/check-in and a write

    # first must change the current working directory
    set cwd [pwd]
    set filename [use_first filename SUE_${schematic_name}(filename) \
		      SUE_ICON_${schematic_name}(filename)]
    cd [file dirname $filename]

    set comment [use_first comment DEFAULT_SCCS_COMMENT]
    write_file_sccs $schematic $filename $version $comment

    # restore it
    cd $cwd
  }

  return ""
}


# Note that new files get written twice.

proc write_file_sccs {schematic filename version comment} {

  global env SUE_DIR DEFAULT_SCCS SCCS

  set created 0
  # sccs needs to be in the correct directory and get only the file name.
  # The full path can screw it up (?)
  if {[catch "exec $SCCS get -g [file tail $filename]" msg]} {
    # assume that this file was never sccs create'd.
    if {![file exists [file tail $filename]]} {
      # first write the file
      write_file_int $schematic
    }
    # if {[catch...]} doesn't work here, who knows why???
    catch {exec $SCCS create [file tail $filename]} msg
    if {[string first ERROR $msg] != -1} {
      # file must not exist or write protection error, punt
      warning "Aborting, could not sccs create file $filename\n$msg"
      return
    } else {
      puts "sccs create'd $filename"
      # now lose the , file.
      catch {exec rm -f ",[file tail $filename]"}
      set created 1
    }
    if {[catch "exec $SCCS get -g [file tail $filename]" msg]} {
      # we're still toasted, abort
      warning "Aborting, sccs failure on file $filename\n$msg"
      return
    }
  }
  set sccs_version [lindex $msg 0]

  # see if this file is checked out to the user (i.e. it's writable)
  # Note this can be foiled if someone changes the protection of
  # the file manually.
  if {[file writable [file tail $filename]]} {
    # should be already checked out to the user.  We are now going to make sure.
    catch {exec $SCCS tell} msg
    if {[lsearch $msg [file tail $filename]] != -1} {
      # sccs tell says it's checked out
      set checked_out 1
    } else {
      # not checked out but is writable: a badness.  Must change permissions
      # to read only.
      if {[catch "exec chmod -f 0444 [file tail $filename]" msg]} {
	# we're toasted, abort
	warning "Aborting, cannot fix file permissions on \"$filename\" $msg"
	return
      }
      puts "Writable copy of \"$filename\" converted to read only."
      set checked_out 0
    }
  } else {
    set checked_out 0
  }

  if {$sccs_version != $version} {
    if {$created == 1} {
      # ok, user just created the SCCS file
    } elseif {$checked_out == 1 && ($version == "" || $version == "%I%")} {
      # ok
    } elseif {$version == "" && [use_first DEFAULT_SCCS] == ""} {
      # can't tell if it's ok, so ask the user.
      set button [tk_dialog .sccs_query "SCCS Cell Up-To-Date?" \
		      "SUE cannot determine if cell \"$schematic\" is up-to-date." \
		      @$SUE_DIR/sue_icon.xbm 0 {save} {cancel}]
      if {$button == 1} {
	# user hit the cancel key
	return
      }
    } elseif {$version != "" && [use_first DEFAULT_SCCS] == ""} {
      # not ok
      warning "Aborting, cell \"[get_rootname $schematic]\" version $version incorrect.  Should be version $sccs_version"
      return
    }
  }

  if {$checked_out != 1} {
    # check out a copy
    if {[catch "exec $SCCS edit [file tail $filename]" msg]} {
      # we're toasted, abort
      warning "Aborting, sccs edit failure for file $filename\n$msg"
      return
    }
  }

  # reset the version/date/comment of sccs title bars before saving
  set schematic [get_rootname $schematic]
  update_cell_title_bar $schematic %I% %G%
  update_cell_title_bar ICON_$schematic %I% %G%

  # finally, save the file
  write_file_int $schematic

  if {$checked_out == 0} {
    # check back in
    catch {exec $SCCS delget [file tail $filename] -y\"$comment\"} msg
    if {[string first ERROR $msg] != -1} {
      # what now???
      warning "AAA $msg"
    }
  } else {
    # check in a delta
    # can't put a -s in here or you get a "child process exited abnormally"
    catch {exec $SCCS deledit [file tail $filename] -y\"$comment\"} msg
    if {[string first ERROR $msg] != -1} {
      # user has a writable copy of this file but it isn't checked out.
      catch {exec $SCCS delget [file tail $filename] -y\"$comment\"} msg
      if {[string first ERROR $msg] != -1} {
	# what now???
	warning "BBB $msg"
      } else {
	puts "Writable copy of $filename converted to read only."
      }
    }
  }

  # now update the sccs_title_bar icon
  if {[catch "exec $SCCS prt -y [file tail $filename]" msg]} {
    # hmmm
    warning "CCC $msg"
    return
  } 

  update_cell_title_bar $schematic [lindex $msg 2] [lrange $msg 3 4]
  update_cell_title_bar ICON_$schematic [lindex $msg 2] [lrange $msg 3 4]

  return 
}


# (Almost) Top level routine to write a schematic/icon pair into a file.
# If this was a generator, is isn't any more.

proc write_file_int {schematic} {

  global cur_c cur_s scale SUE WRITE_FILE_ID SUFFIX BACKUP_PERCENTAGE VERSION

  # save the current canvas, schematic, and scale
  set save_cur_c $cur_c
  set save_cur_s $cur_s
  set save_scale $scale

  set schematic_name [get_rootname $schematic]

  # get file information
  if {[info exists SUE($schematic_name)]} {
    global SUE_$schematic_name
    set filename [set SUE_${schematic_name}(filename)]
  } else {
    # see if there is icon information, instead
    if {[info exists SUE(ICON_$schematic_name)]} {
      global SUE_ICON_$schematic_name
      set filename [set SUE_ICON_${schematic_name}(filename)]
    } else {
      # No lo existo
      return ""
    }
  }

  # make sure that we have permission to write this file
  if {[file isfile $filename] == 1 && [file writable $filename] != 1} {
    sue_error "Aborting save, could not overwrite file $filename"
    sue_error flush
    return ""
  }

  busy

  # Don't overwrite the backup if it looks like the user might be
  # hosing himself or SUE may be breaking.
  if {[file exists $filename] && [file exists $filename$SUFFIX(backup)] && \
	  [file size $filename] < \
	  [expr $BACKUP_PERCENTAGE * [file size $filename$SUFFIX(backup)]]} {
    puts "Not overwriting backup $filename$SUFFIX(backup)"
  } else {
    # move the existing file to be a backup
    catch "exec \"mv\" -f $filename $filename$SUFFIX(backup)"
  }

  # open file
  if {[catch {open $filename w} WRITE_FILE_ID] != 0} {
    sue_error "Aborting save, could not create file $filename"
    sue_error flush
    ready
    return ""
  }

  # write the SUE comment header to the file
  puts $WRITE_FILE_ID "\# SUE version $VERSION\n"

  set written ""

  upvar #0 SUE_$schematic_name data

  # first look to see if it's a generator
  if {[info commands ICON_$schematic_name] != "" && \
	  [lsearch [info body ICON_$schematic_name] "icon_generator"] != -1} {
    # there's an icon and it's a generator
    goto_schematic $schematic_name
    if {$cur_s != "$schematic_name"} {
      # no schematic, punt
    } else {
      puts "Converting schematic generator \"$schematic_name\" into normal cell."
      # now go back
      goto_schematic $save_cur_s
    }
  }

  # write the schematic if it exists
  if {[info exists data(canvas)]} {
    set cur_c $data(canvas)
    set cur_s $schematic_name
    set scale $data(scale)

    # update for last modified by
    update_title_bar title_bar

    write_schematic
    set data(written) W

    # unmodify schematic since it has been written
    not_modified $schematic_name

    lappend written SCHEMATIC_$schematic_name

    # remake the title_bar if it exists to display new date and
    # possibly new owner.
    update_title_bar title_bar

  } elseif {[info commands SCHEMATIC_$schematic_name] != ""} {
    # there is a schematic, we just haven't made a canvas for it.
    write_proc_to_file SCHEMATIC_$schematic_name reset_title_bar

    lappend written SCHEMATIC_$schematic_name
  }

  # write the icon if it exists
  if {[info commands ICON_$schematic_name] != ""} {
    upvar #0 SUE_ICON_$schematic_name data

    if {[lsearch [info body ICON_$schematic_name] "icon_generator"] != -1} {
      # this is a generator
      goto_schematic ICON_$schematic_name
      if {$cur_s != "ICON_$schematic_name"} {
	# no icon, punt
      } else {
	puts "Converting icon generator \"$schematic_name\" into normal cell."

	# update for last modified by
	update_title_bar title_bar

	write_icon
	upvar #0 icon_$schematic_name g_data
	catch {unset g_data(generator)}

	# now go back
	goto_schematic $save_cur_s
      }
    }

    # has the canvas been modified
    if {[info exists data(canvas)]} {
      set cur_c $data(canvas)
      set cur_s ICON_$schematic_name
      set scale $data(scale)

      # update for last modified by
      update_title_bar title_bar

      # this just recreates the procedure for the icon
      write_icon
      set data(written) W

      update_title_bar title_bar

      # unmodify icon since it has been written
      not_modified ICON_$schematic_name

      # now write it to the file
      write_proc_to_file ICON_$schematic_name
    } else {
      # now write it to the file
      write_proc_to_file ICON_$schematic_name reset_title_bar
    }

    lappend written ICON_$schematic_name
  }

  # close file
  close $WRITE_FILE_ID

  if {$written != ""} {
    # Save the netlist cache if there is one that is valid
    write_netlist_cache

    puts "Wrote $written to $filename"

  } else {
    puts "Nothing written."
  }

  # restore the current canvas, schematic, and scale
  set cur_c $save_cur_c
  set cur_s $save_cur_s
  set scale $save_scale

  # fix up the title (could be changed by no_modified or unmodifying something)
  display_title

  ready
  return ""
}


# saves the schematic/icon to a file without changing any state.

proc auto_save_write_file {schematic} {

  global cur_c cur_s scale SUE WRITE_FILE_ID SUFFIX VERSION
  global AUTO_SAVE DISABLE_CANVAS_EVENT

  if {[use_first AUTO_SAVE(interval) `0] == 0} {
    # auto-save no longer turned on
    auto_save_data $schematic_name reset
    return
  }

  # do this later if in the middle of something
  if {$DISABLE_CANVAS_EVENT == 1} {
    # we're in the middle of something, just reschedule
    after [expr int(60000 * $AUTO_SAVE(interval))] "auto_save_write_file $cur_s"
    return ""
  }

  # save the current canvas, schematic, and scale
  set save_cur_c $cur_c
  set save_cur_s $cur_s
  set save_scale $scale

  set schematic_name [get_rootname $schematic]

  # get file information
  if {[info exists SUE($schematic_name)]} {
    global SUE_$schematic_name
    set dir [set SUE_${schematic_name}(dir)]
    if {[set SUE_${schematic_name}(modified)] == ""} {
      # schematic is not modified, see if icon is modified
      global SUE_ICON_$schematic_name
      if {[use_first SUE_ICON_${schematic_name}(modified)] == ""} {
	# not modified, user must have saved
	auto_save_data $schematic_name reset
	return ""
      }
    }

  } else {
    # see if there is icon information, instead
    if {[info exists SUE(ICON_$schematic_name)]} {
      global SUE_ICON_$schematic_name
      set dir [set SUE_ICON_${schematic_name}(dir)]
      if {[set SUE_ICON_${schematic_name}(modified)] == ""} {
	# not modified, user must have saved
	auto_save_data $schematic_name reset
	return ""
      }
    } else {
      # No lo existo
      # cell could have been deleted
      auto_save_data $schematic_name reset
      return ""
    }
  }

  set filename $dir$schematic_name$SUFFIX(auto_save)

  # make sure that we have permission to write this file
  if {[file isfile $filename] == 1 && [file writable $filename] != 1} {
    # can't write
    auto_save_data $schematic_name reset
    return ""
  }

  busy

  # open file
  if {[catch {open $filename w} WRITE_FILE_ID] != 0} {
    # can't write
    ready
    auto_save_data $schematic_name reset
    return ""
  }

  # write the SUE comment header to the file
  puts $WRITE_FILE_ID "\# SUE version $VERSION (auto-save)\n"

  set written ""

  upvar #0 SUE_$schematic_name data

  # write the schematic if it exists
  if {[info exists data(canvas)]} {
    set cur_c $data(canvas)
    set cur_s $schematic_name
    set scale $data(scale)

    # update any changed icons
    enter_canvas $schematic_name

    # update for last modified by
    update_title_bar title_bar

    write_schematic

    lappend written SCHEMATIC_$schematic_name

  } elseif {[info commands SCHEMATIC_$schematic_name] != ""} {
    # there is a schematic, we just haven't made a canvas for it.
    write_proc_to_file SCHEMATIC_$schematic_name reset_title_bar

    lappend written SCHEMATIC_$schematic_name
  }

  # write the icon if it exists
  if {[info commands ICON_$schematic_name] != ""} {
    upvar #0 SUE_ICON_$schematic_name data

    # is there a canvas
    if {[info exists data(canvas)]} {
      set cur_c $data(canvas)
      set cur_s ICON_$schematic_name
      set scale $data(scale)

      # update for last modified by
      update_title_bar title_bar

      # this just recreates the procedure for the icon
      write_icon

      # now write it to the file
      write_proc_to_file ICON_$schematic_name

    } else {
      # now write it to the file
      write_proc_to_file ICON_$schematic_name reset_title_bar
    }

    lappend written ICON_$schematic_name
  }

  # close file
  close $WRITE_FILE_ID

  if {$written != ""} {
    puts "Auto saved $written to $filename"
  }

  auto_save_data $schematic_name reset

  # restore the current canvas, schematic, and scale
  set cur_c $save_cur_c
  set cur_s $save_cur_s
  set scale $save_scale

  ready
  return ""
}


proc write_schematic {} {

  global cur_c cur_s scale PROC

  # scale the canvas to "10" for saving
  set old_scale $scale
  scale_canvas 10

  set PROC ""

  # write instances and terminals
  write_instances

  # write wires
  write_wires

  # write draw_items: lines, arcs, text
  write_draw_items

  # define the schematic procedure
  proc SCHEMATIC_$cur_s {} [join $PROC "\n"]

  # now write it to the file
  write_proc_to_file SCHEMATIC_$cur_s

  unset PROC

  # restore the origin
  #eval $cur_c move all $offset

  # restore the scale
  scale_canvas $old_scale
}


# Write all instances (includes terminals which are instances)

proc write_instances {{tag ""} {skip_generator ""} {id_undo ""}} {

  global cur_c cur_s scale PROC

  if {$scale != [expr int($scale)]} {
    puts "SUE Internal ERROR: non-integer scale ($scale) during write_instances. [info level -1], [info level -2]."
  }

  if {$tag == "" || $tag == "all"} {
    set ids [$cur_c find withtag origin]
  } else {
    set ids [get_intersect_tag $tag origin]
  }

  # Loop through all instances
  foreach id $ids {
    # set up data structures to get icon data if not cached in "creator"

    # instance-specific data (like W=1.2u) are here
    upvar #0 ${cur_s}_inst$id i_data

    set type $i_data(type)

    if {[info exists i_data(creator)]} {
      set creator $i_data(creator)

    } else {
      # build up the creator 
      set creator "make $type"

      if {$i_data(orient) != "R0"} {
	# Non default value, so include it
	lappend creator "-orient" $i_data(orient)
      }

      # instance-generic data (like default L=0.6u) are here
      upvar #0 icon_$type g_data

      # motor through the properties
      foreach name $g_data(prop_names) {
	if {[string compare $i_data(_$name) $g_data(_$name,default)] != 0} {
	  # Non default value, so include it
	  lappend creator "-$name" $i_data(_$name)
	}
      }
    
      # the origin has to be last and is never defaulted
      lappend creator "-origin"
      
      # cache the creator data
      set i_data(creator) $creator
    }

    if {![info exists repeat($type)] && $skip_generator == ""} {
      # instance-generic data (like default L=0.6u) are here
      upvar #0 icon_$type g_data

      # note that this does a generate, not a regenerate, so an existing
      # generator will not be replaced but will be used.
      if {[info exists g_data(generator)] && \
	      ($g_data(gargs) != "" || $g_data(generator) != $type)} {
	lappend PROC "  generate $g_data(generator) $type $g_data(gargs)"
      }
      set repeat($type) 1
    }

    # add the origin (the only thing that changes)
    lappend creator [round_list [lrange [$cur_c coords $id] 0 1]]

    if {$id_undo == ""} {
      # append it to the others
      lappend PROC "  $creator"

    } else {
      # special for undo
      lappend PROC "id_undo $id \[$creator\]"
    }
  }
}


# Writes all wires.

proc write_wires {{tag ""} {id_undo ""}} {

  global cur_c PROC

  if {$tag == "" || $tag == "all"} {
    set ids [$cur_c find withtag wire]
  } else {
    set ids [get_intersect_tag $tag wire]
  }

  # walk through all wires in the canvas
  if {$id_undo == ""} {
    foreach id $ids {
      lappend PROC "  make_wire [round_list [$cur_c coords $id]]"
    }
  } else {
    # special for undo
    foreach id $ids {
      lappend PROC "id_undo $id \[make_wire [round_list [$cur_c coords $id]]\]"
    }
  }
}


# Writes all draw_items: lines, arcs, and text.

proc write_draw_items {{tag ""} {id_undo ""}} {

  global cur_c PROC ROTATE_TEXT

  if {$tag == "" || $tag == "all"} {
    set ids [$cur_c find withtag draw_item]
  } else {
    set ids [get_intersect_tag $tag draw_item]
  }

  # walk through all draw_items
  foreach id $ids {
    switch [$cur_c type $id] {

      "line" {
	# don't save icon origins
	if {[is_tagged $id origin_icon] != 1} {
	  if {$id_undo == ""} {
	    lappend PROC "  make_line [round_list [$cur_c coords $id]]"
	  } else {
	    # special for undo
	    lappend PROC \
		"id_undo $id \[make_line [round_list [$cur_c coords $id]]\]"
	  }
	}
      }

      "text" {
	set text [$cur_c itemcget $id -text]
	if {$text == ""} {
	  # toss turds
	  continue
	}
	set origin [round_list [$cur_c coords $id]]
	if {$ROTATE_TEXT && [$cur_c itemcget $id -rotate] == 1} {
	  set rotate " -rotate 1"
	} else {
	  set rotate ""
	}

	if {$id_undo == ""} {
	  lappend PROC "  make_text -origin [list $origin] -text [list $text][text_size $id][text_anchor $id]$rotate"
	} else {
	  # special for undo
	  lappend PROC "id_undo $id \[make_text -origin [list $origin] -text [list $text][text_size $id][text_anchor $id]$rotate\]"
	}
      }

      "arc" {
	set extent \
	    [expr round([$cur_c itemcget $id -extent])]
	set start [expr round([$cur_c itemcget $id -start])]

	if {$id_undo == ""} {
	  lappend PROC "  make_arc [round_list [$cur_c coords $id]] -start $start -extent $extent"
	} else {
	  # special for undo
	  lappend PROC "id_undo $id \[make_arc [round_list [$cur_c coords $id]] -start $start -extent $extent\]"
	}
      }

      default {
	puts "Unknown canvas type [$cur_c type $id] during writing."
	continue
      }
    }
  }
}

  
proc write_proc_to_file {proc {what ""}} {

  global WRITE_FILE_ID

  puts $WRITE_FILE_ID "proc $proc [list [info args $proc]] \{"

  if {$what == ""} {
    set lines [info body $proc]
  } else {
    # reset title bar
    set lines [reset_title_bar [info body $proc]]
  }

  foreach line [split $lines "\n"] {
    # remove blank lines
    if {$line != ""} {
      puts $WRITE_FILE_ID "$line"
    }
  }
  puts $WRITE_FILE_ID "\}\n"
}
