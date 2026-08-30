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


# Implements text command and global variable documentation ("doc_box").

# List of "generic" mmi procs
set MMI_PROCS ""
lappend MMI_PROCS setl use_first pp_number parse_pp_number min max
lappend MMI_PROCS get_assoc fs_box prop_menu prop_menu2


# initial values
global doc_box
set doc_box(msg) ""
set doc_box(name_pattern) ""
set doc_box(apropos) ""
set doc_box(types_commands) 1
set doc_box(types_variables) 1


proc doc_box {} -desc {
    Popup text command documentation
} {
  global doc_box LISTBOX_FONT

  ### BUILD WIDGET

  # TOPLEVEL
  catch {destroy .doc_box}

  toplevel .doc_box -borderwidth 0
  wm geometry .doc_box "750x500[relative_origin]"
  wm title .doc_box "SUE Text Commands/Variables"
  wm maxsize .doc_box 1000 1000
  wm minsize .doc_box 100 100
  # end build of toplevel

  # MESSAGE AT TOP
  label .doc_box.message \
	  -anchor c \
	  -relief raised \
	  -textvariable doc_box(msg)

  frame .doc_box.frame1 \
	  -borderwidth 0 \
	  -relief raised

  # CLOSE
  button .doc_box.frame1.close \
	  -text "Close" \
	  -command {destroy .doc_box}

  button .doc_box.frame1.save \
	  -text "Save to File..." \
	  -command "doc_save_to_file .doc_box.matches.list"
  
  # MATCHES
  frame .doc_box.matches \
	  -borderwidth 0 \
	  -relief raised

  scrollbar .doc_box.matches.vscroll \
	  -relief raised \
	  -command ".doc_box.matches.list yview"

  listbox .doc_box.matches.list \
	  -font $LISTBOX_FONT \
	  -exportselection false \
	  -relief raised \
	  -yscrollcommand ".doc_box.matches.vscroll set"

  bind .doc_box.matches.list <Button-1> {_doc_box_matches_select %W %y}

  bind .doc_box <Escape> {destroy .doc_box}
  bind .doc_box <Control-C> {destroy .doc_box}

  # APROPOS
  frame .doc_box.appro \
	  -borderwidth 0 \
	  -relief raised

  label .doc_box.appro.label -relief raised -text "Search:"

  entry .doc_box.appro.entry \
	  -relief raised
  bind .doc_box.appro.entry <Return> _doc_box_update

  # TYPES
  frame .doc_box.types \
	  -borderwidth 0 \
	  -relief raised

  # checkbuttons for commands and variables
  checkbutton .doc_box.types.commands -text commands \
      -variable doc_box(types_commands) -anchor w \
      -command "_doc_box_update"

  checkbutton .doc_box.types.variables -text variables \
      -variable doc_box(types_variables) -anchor w \
      -command "_doc_box_update"
  
  # packing
  pack append .doc_box.matches \
	  .doc_box.matches.vscroll {left filly} \
	  .doc_box.matches.list {left fill expand}
  pack append .doc_box.appro \
	  .doc_box.appro.label {left} \
	  .doc_box.appro.entry {left fill expand}  

  pack append .doc_box.types \
      .doc_box.types.commands {left fill} \
      .doc_box.types.variables {left fill} \

  pack append .doc_box.frame1 \
	  .doc_box.frame1.close {left fill expand} \
	  .doc_box.frame1.save {right}

  pack append .doc_box \
	  .doc_box.message {top fill} \
	  .doc_box.matches {top fill expand} \
	  .doc_box.frame1 {bottom fill} 

  pack append .doc_box \
      .doc_box.types {right} 

  pack append .doc_box \
	  .doc_box.appro {left fill expand} 

  # get name list
  _doc_box_update

  focus .doc_box.appro.entry
  # warp cursor to appropriate spot
  update
  _warp_cursor_window .doc_box.appro.entry
}


proc _doc_box_update {} -desc {
  update matching list 
} {
  global doc_box doc_user _doc_at_db MMI_PROCS _doc_user

  # clear matching list
  .doc_box.matches.list delete 0 end

  #get current entry values from browser window
  set doc_box(apropos) [.doc_box.appro.entry get]

  # initiaize match list
  set matches ""
  if {$doc_box(types_commands)} {
    set matches [lsort -dictionary [concat $MMI_PROCS [array names _doc_user]]]
  }

    #filter - name pattern
#    set name_pat $doc_box(name_pattern)
#    if {$doc_box(name_pattern) != "" && $doc_box(name_pattern) != "*"} {
#	set name_pat $doc_box(name_pattern)
#        set matches_old $matches
#	set matches ""
#
#	foreach name $matches_old {
#	    if {[string match $name_pat $name]} {lappend matches $name}
#	}
#    } 


    #filter non existant commands
    set matches_old $matches
    set matches ""

    foreach name $matches_old {
      if {[info commands $name] != "" } {
	lappend matches $name
      }
    }
	     
    #filter - apropos
    if {$doc_box(apropos) != ""} {
	set apropos $doc_box(apropos)
        set matches_old $matches
	set matches ""

	foreach name $matches_old {
	    set apropos 1
	    foreach key $doc_box(apropos) {
		if {![regexp -nocase -- $key $name] && 
		![regexp -nocase -- $key [doc_at $name cmd_desc]] && 
		![regexp -nocase -- $key [doc_at $name cmd_doc]]} {
		    set apropos 0
		    break;
		}
	    }
	    if {$apropos} {lappend matches $name}
	}
    }


    # put matching commands in list box
    foreach name $matches {
#      set desc "[lindex [split [doc_at $name cmd_desc] .] 0]."
      set desc [doc_at $name cmd_desc]
      if {[regexp -nocase -indices {\.([^a-z])} $desc tmp index]} {
	set desc [string range $desc 0 [lindex $index 0]]
      }

      regsub -all \n $desc " " desc

      set sep "-"
      set entry [format "%-25s %s %s" $name $sep $desc]

      .doc_box.matches.list insert end $entry
    }

    # put matching variables in list box.
    set var_cnt 0
    if {$doc_box(types_variables)} {
      # Add variables at bottom of list.
      set var_cnt [_doc_box_variables_fill]
    }

    # update message
    set cnt [expr $var_cnt + [llength $matches]]
    set doc_box(msg) "$cnt matches.  BUT-1 shows documentation"
}


proc _doc_box_variables_fill {} -desc {
  fill list box with variables matching apropos pattern
} {

  global _doc_at_db _doc_user_var doc_box

  # initiaize match list
  set matches [lsort -dictionary [array names _doc_user_var]]

  #filter - apropos
  if {$doc_box(apropos) != ""} {
    set apropos $doc_box(apropos)
    set matches_old $matches
    set matches ""
    
    foreach name $matches_old {
      set apropos 1
      foreach key $doc_box(apropos) {
	if {![regexp -nocase -- $key $name] && 
	    ![regexp -nocase -- $key [doc_at $name var_desc]] && 
	    ![regexp -nocase -- $key [doc_at $name var_flags]] && 
	    ![regexp -nocase -- $key [doc_at $name var_type]] && 
	    ![regexp -nocase -- $key [doc_at $name var_doc]]} {
	  set apropos 0
	  break;
	}
      }
      if {$apropos} {lappend matches $name}
    }
  }

  # put matching commands in list box
  foreach name $matches {
#    set desc "[lindex [split [doc_at $name var_desc] .] 0]."
    set desc [doc_at $name var_desc]
    if {[regexp -nocase -indices {\.([^a-z])} $desc tmp index]} {
      set desc [string range $desc 0 [lindex $index 0]]
    }

    regsub -all \n $desc " " desc

    set sep "-"
    set entry [format "%-25s %s %s" $name $sep $desc]
    
    .doc_box.matches.list insert end $entry
  }

  return [llength $matches]
}


proc _doc_box_matches_select {w y} -desc {
    Select doc_box entry (used to implements double click on entry)
} {
    global doc_box

    set index [$w nearest $y]
    set entry [$w get $index]
    # The entry is not a formal list, it is just a string.
    # If someone enters documentation that contains list delimiters
    # in improper format, for example a quote followed by a non-space
    # (like this: "whatever", ) then the lindex will fail.  So use regsub.
    #set cmd [lindex $entry 0]
    regsub { .*} $entry "" cmd
    doc_cmd $cmd
}


proc doc_cmd {name} -desc {
    pop-up documentation on named command
} {
 
  global doc_box _doc_user

  if { [doc_at $name var_source] != "" } {
    set type variable
  } else {
    set type command
  }

  # CLEAR OR CREATE WINDOW
  set w .doc_cmd
  if {[info commands $w] != ""} {
    raise $w
    $w.text configure -state normal
    $w.text delete 1.0 end
    $w.text configure -state disabled

  } else {
    catch {destroy $w}
    toplevel $w
    wm geometry $w +250+100
    text $w.text -wrap word -setgrid 1 -bd 2 -width 80 \
	-yscrollcommand "$w.scroll set"
    scrollbar $w.scroll -command "$w.text yview"
    button $w.close \
	-text "Close" \
	-command "destroy $w"
    
    pack $w.close -side bottom -fill x
    pack $w.scroll -side right -fill y
    pack $w.text -side left -fill both -expand 1
  }

  wm title $w "SUE $type documentation"
  wm iconname $w "SUE $type documentation"

  # ADD TEXT
  $w.text configure -state normal

  # name 
  $w.text insert end "$name"

  # look for variable source
  set desc [doc_at $name var_desc]
  if { $desc != "" } {
    # its a variable

    if {$desc != ""} { $w.text insert end " - \n\n$desc" }
    
    set tmp [join "[doc_at $name var_flags] " ", "]
    regsub user $tmp SUE tmp

    $w.text insert end "\n\nTYPE:  $tmp"
    
    # value
    global [lindex [split $name \(] 0]

    set type [doc_at $name var_type]

    if {$type == "ARRAY"} {
      # special case for an entire array

      $w.text insert end "\n\nARRAY:"
      foreach key [lsort -dictionary [array names $name]] {
	$w.text insert end "\n        ${name}($key) = [set ${name}($key)]"
      }

    } else {

      set default [doc_at $name var_default]
      if {$default == "_NO_DEFAULT_"} {
	$w.text insert end \
	    "\n\nVALUE ([doc_at $name var_type]):  [set $name]"
	
      } elseif {[set $name] == $default} {
	# value is default
	$w.text insert end \
	    "\n\nVALUE ([doc_at $name var_type],DEFAULT):  [set $name]"

      } else {
	$w.text insert end "\n\nVALUE ([doc_at $name var_type]):  [set $name]"
	$w.text insert end "\n\nDEFAULT: $default"
      }
    }

    # doc
    set var_doc [doc_at $name var_doc]
    if {$var_doc != ""} { 
      $w.text insert end "\n\nDOC:  $var_doc"
    }
    set length [min 30 [llength [split [.doc_cmd.text dump 1.0 end] \n]]]
    $w.text configure -state disabled -height $length

  } else {
    # command

    # source
    set cmd_src [doc_at $name cmd_source]
    if {[string index $name 0] == "."} {set cmd_src "widget"}
    
    # get description and doc
    set desc [doc_at $name cmd_desc]
    set cmd_doc [doc_at $name cmd_doc]

    if {$desc == ""} { set $desc $cmd_src }
    if {$desc != ""} { $w.text insert end " - \n\n$desc" }
    
    set code "built-in command. "
    if {[info procs $name] != ""} {set code "proc. "}
    
    if {[info exists _doc_user($name)]} {
      if {[string first api $name] == 0} {
	set cmd_src "SUE API"
      } else {
	set cmd_src SUE
      }
    } else {
      set cmd_src MMI
    }

    $w.text insert end "\n\nTYPE:  $cmd_src $code"

    # usage
    # Currently the description or documentation sections might already
    # contain a usage in the description section, in which case
    # cmd_usage returns "".
    set usage [doc_at $name cmd_usage]
    if { $usage != "" } {
	$w.text insert end "\n\nUSAGE: $usage"
    }
    
    # doc
    if {$cmd_doc != ""} {
      $w.text insert end "\n\nDOC:  $cmd_doc"
    }
    set length [min 30 [llength [split [.doc_cmd.text dump 1.0 end] \n]]]
    $w.text configure -state disabled -height $length
  }
}


proc doc_save_to_file {listbox} -desc {
    allow user to save contents of listbox to a file.
} -doc {
    Argument is the window name of the listbox.
    The entire contents of the listbox are saved in a file.
} {

  # Get the filename
  set filename [fs_box -message "Select file for documentation save:" \
		    -filename "sue_commands.txt" -pattern *]

  if {$filename == ""} { 
    # cancelled
    return 
  }

  if {[catch "open $filename w" FILE_ID]} {
    warning "ERROR: Could not open file $filename: FILE_ID"
    return
  }

  busy

  # walk thru each line of current commands (effected by filter)
  set win .doc_cmd

  foreach line [$listbox get 0 end] {
    # Name is first word in thingy
    regsub { .*$} $line "" name
    
    # make the documentation for
    doc_cmd $name

    puts $FILE_ID [$win.text get 0.0 end]
    puts $FILE_ID "------------------------------------------------------------------------------\n"
  }

  close $FILE_ID

  catch {destroy $win}

  ready
  puts "Saved documentation to file $filename."
}


# Make something of the form below for the sue manual

#<li>
#<b><pre>
#api_bbox
#</pre></b>
#
#Returns a list of the coordinates of the bounding box of the current
#cell.
#
#<p>
#For example:
#<pre>
#        sue> api_bbox
#        10 10 200 300
#</pre>
#
#<p>

# NOTE: needs the SUE text command/variables window to be up.

proc make_api_manual {{filename ~/sue/api_manual.html} {type API}} {

  if {[catch "open $filename w" FILE_ID]} {
    warning "ERROR: Could not open file $filename: FILE_ID"
    return
  }

  # walk thru each line of current commands (effected by filter)
  set win .doc_cmd

  set listbox .doc_box.matches.list

  puts $FILE_ID "<html>"

  puts $FILE_ID ""
  puts $FILE_ID "<head>"
  puts $FILE_ID "<title>"
  puts $FILE_ID "MMI-SUE $type Reference Guide"
  puts $FILE_ID "</title>"
  puts $FILE_ID "</head>"
  puts $FILE_ID ""
  puts $FILE_ID "<BODY BGCOLOR=\"ffffff\" >"
  puts $FILE_ID ""
  puts $FILE_ID "<h1>"
  puts $FILE_ID "<img src=\"images/mmi-logo.gif\" align=center>"

  puts $FILE_ID "MMI-SUE $type Reference Guide"
  puts $FILE_ID "</h1>"
  puts $FILE_ID ""

  puts $FILE_ID "<ul>"

  foreach line [$listbox get 0 end] {
    # Name is first word in thingy
    regsub { .*$} $line "" name
    
    # make the documentation for
    doc_cmd $name

    set in_example 0

    puts $FILE_ID "<li>"
    puts $FILE_ID "<b><pre>"
    set first 1
    set blank 0
    foreach line [split [$win.text get 0.0 end] \n] {

      if {$first} {
	puts $FILE_ID [string trim $line " -"]
	puts $FILE_ID "</pre></b>\n"
	set first 0
	set blank 1
	continue
      }

      if {[string trim $line] == ""} {
	# blank line
	if {$in_example} {
	  # leave example
	  puts $FILE_ID "</pre>\n"
	  set in_example 0

	} elseif {!$blank} {
	  puts $FILE_ID "\n<p>\n"
	  set blank 1
	}
	continue
      }

      if {[string first "TYPE:" $line] != -1} {
	# skip
	continue
      }

      set blank 0

      # assumes no tab chars
      set fc [string index [string trim $line] 0]

      # NOTE: - and \[ are disabled -- why where they there???
      if {[string range $line 0 3] == "    " && $fc != "x-" && $fc != "x\["} {
	# example
	if {!$in_example} {
	  puts $FILE_ID "<pre>"
	  set in_example 1
	}

      } elseif {$in_example} {
	# leave example
	  puts $FILE_ID "</pre>"
	  set in_example 0
      }

      regsub -all "<" $line "\\&lt;" line
      puts $FILE_ID $line	
    }
  }

  puts $FILE_ID "</ul>\n"

  puts $FILE_ID "<hr>"
  puts $FILE_ID "<address>"
  puts $FILE_ID "SUE Manual / <a name=mmi> Micro Magic, Incorporated </a> (408-735-9200 x220) /"
  puts $FILE_ID "<a href=\"MAILTO:support@micromagic.com\"> support@micromagic.com </a> /"
  puts $FILE_ID "last revised [clock format [clock seconds] -format %m/%d/%Y]."
  puts $FILE_ID "</em>"
  puts $FILE_ID "</address>\n"

  puts $FILE_ID "</html>"

  catch {destroy $win}

  close $FILE_ID

  puts "Wrote html file \"$filename\"."
}
