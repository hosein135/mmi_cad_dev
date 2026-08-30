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

set RCSVERSION(doc.tcl) { $Revision: 1.25 $ }

# Implements text command and global variable documentation ("box") for max.

# initial values
global doc_box
set doc_box(msg) ""
set doc_box(name_pattern) ""
set doc_box(apropos) ""
set doc_box(types_commands) 1
set doc_box(types_variables) 1
set doc_box(types_private) 0
set doc_box(types_widgets) 0

proc doc_box {} -desc {
    Popup text command documentation
} {
  global doc_box MAX_DEVELOPER LISTBOX_FONT

  ### BUILD WIDGET

  # TOPLEVEL
  if {[info commands XFDestroy] != ""} {
    catch {XFDestroy .doc_box}
  } {
    catch {destroy .doc_box}
  }
  toplevel .doc_box \
    -borderwidth 0
  wm geometry .doc_box "750x500[_relative_origin]"
  wm title .doc_box "max text commands"
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
	  -command "
  if {\"\[info commands XFDestroy\]\" != \"\"} {
      catch {XFDestroy .doc_box}
  } {
      catch {destroy .doc_box}
  }
  "
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

  if {$MAX_DEVELOPER} { 
      bind .doc_box.matches.list <Button-3> {_doc_box_toggle_user %W %y}
      bind .doc_box.matches.list <Control-Button-3> _doc_box_save_user
  }

  # APROPOS
  frame .doc_box.appro \
	  -borderwidth 0 \
	  -relief raised

  label .doc_box.appro.label -relief raised -text "Search:"

  entry .doc_box.appro.entry \
	  -relief raised
  bind .doc_box.appro.entry <Return> _doc_box_update

  # Make Control-U work.
  bind .doc_box.appro.entry <Control-u> {.doc_box.appro.entry delete 0 end}

  # TYPES
  frame .doc_box.types \
	  -borderwidth 0 \
	  -relief raised

  _doc_box_types_button commands
  _doc_box_types_button variables
  _doc_box_types_button private
  _doc_box_types_button widgets
  
  # packing
  pack append .doc_box.matches \
	  .doc_box.matches.list {left fill expand} \
	  .doc_box.matches.vscroll {left filly}
  pack append .doc_box.appro \
	  .doc_box.appro.label {left} \
	  .doc_box.appro.entry {left fill expand}  

  if {$MAX_DEVELOPER} {
    pack append .doc_box.types \
	.doc_box.types.commands {left fill} \
	.doc_box.types.variables {left fill} \
	.doc_box.types.private {left fill} \
	.doc_box.types.widgets {left fill} 
  } else {
    pack append .doc_box.types \
	.doc_box.types.commands {left fill} \
	.doc_box.types.variables {left fill} \
  }

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
}

proc _doc_box_types_change {{name ""} {element ""} {op ""}} -desc {
    Invoked when a doc_box types checkbutton is pushed.
} {

  # so user sees that box changed
  update
  # update name list
  _doc_box_update
}

proc _doc_box_types_button {name} -desc {
  Create doc_box types checkbutton, and set up tracing
} {

  global doc_box

  checkbutton .doc_box.types.$name -text $name \
      -variable doc_box(types_$name) -anchor w \
      -command "_doc_box_types_change"
}

proc _doc_box_update {} -desc {
    update matching list 
} {
    global doc_box doc_user MAX_DEVELOPER

    # clear matching list
    if {[.doc_box.matches.list size] > 0} {
	.doc_box.matches.list delete 0 end
    }

    #get current entry values from browser window
    set doc_box(apropos) [.doc_box.appro.entry get]

    # initiaize match list
    set matches ""
    if {$doc_box(types_commands)} {
	if { $MAX_DEVELOPER == 1 } {
	    # developer mode, so start with all commands    
	    #set matches [lsort -dictionary [info commands]]
	    global doc_developer
	    set matches [lsort -dictionary [array names doc_developer]]
	} else {
	    set matches [lsort -dictionary [array names doc_user]]
	}
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

    #filter private
    if { !$doc_box(types_private) } {
        set matches_old $matches
	set matches ""

	foreach name $matches_old {
	    if {[string index $name 0] != "_"} {lappend matches $name}
	}
    }

    #add widgets
    if { $doc_box(types_widgets) } {
	foreach name [info commands] {
	  if {[string index $name 0] == "."} {lappend matches $name}
	}
	set matches [lsort -dictionary $matches]
    }

    #filter non existant commands
    if { $MAX_DEVELOPER == 0 } {
	set matches_old $matches
	set matches ""

	foreach name $matches_old {
	    if {[info commands $name] != "" } {
		lappend matches $name
	    }
	}
    }
	     
    #filter - apropos
    if {$doc_box(apropos)!= ""} {
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
      set desc [doc_at $name cmd_desc]
      set sep "-"
      if { $MAX_DEVELOPER && [info exists doc_user($name)]} {
	set sep "U"
      }
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
    if {$MAX_DEVELOPER} {
	set doc_box(msg) "$cnt matches.  BUT-1 shows documentation, BUT-3 toggles user command, CTRL-BUT-3 saves user commands"
    } else {
	set doc_box(msg) "$cnt matches.  BUT-1 shows documentation"
    }
}

proc _doc_box_variables_fill {} -desc {
  fill list box with variables matching apropos pattern
} {

  global _doc_at_db doc_user_var MAX_DEVELOPER doc_box

  # initiaize match list
  if { $MAX_DEVELOPER == 1 } {
    # developer mode, so start with all variables
    set matches ""
    foreach nameplus [lsort -dictionary [array names _doc_at_db *var_desc]] {
      lappend matches [lindex [split $nameplus |] 0]
    }

  } else {
    set matches [lsort -dictionary [array names doc_user_var]]
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
    set desc [doc_at $name var_desc]
    set sep "-"
    if { $MAX_DEVELOPER && [info exists doc_user_var($name)]} {
      set sep "U"
    }
    set entry [format "%-25s %s %s" $name $sep $desc]
    
    .doc_box.matches.list insert end $entry
  }

  return [llength $matches]

  # update message
  #if {$MAX_DEVELOPER} {
  #  set doc_box(msg) "[llength $matches] matching commands.  BUT-1 shows documentation, BUT-3 toggles user command, CTRL-BUT-3 saves user commands"
  #} else {
  #  set doc_box(msg) "[llength $matches] matching commands.  BUT-1 shows documentation"
  #}
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

proc _doc_box_toggle_user {w y} -desc {
    Toggle user command on entry
} {
    global doc_box doc_user doc_user_var

    set index [$w nearest $y]
    set entry [$w get $index]
    set name [car $entry]

    if {[doc_at $name var_source] != ""} {
      # Its a variable
      set cmd "_var"
    } else {
      # Its a command
      set cmd ""
    }

    if {[info exists doc_user${cmd}($name)]} {
      unset doc_user${cmd}($name)
    } else {
      set doc_user${cmd}($name) 1
    }

    # update entry
    set entry [.doc_box.matches.list get $index]
    
    if {[info exists doc_user${cmd}($name)]} {
      regsub { - } $entry { U } entry
    } else {
      regsub { U } $entry { - } entry
    }
  
    .doc_box.matches.list delete $index $index
    .doc_box.matches.list insert $index $entry
}

proc _doc_box_save_user {} -desc {
    Stash away list of user commands (shown to end user by Help/"Text Commands")
} {
  global doc_box doc_user doc_user_var

  if {$doc_box(types_variables) && $doc_box(types_commands) } {
    max_error "error: must select either commands or variables, not both"
    return
  }
  if {$doc_box(types_variables)} {
    set cmd "_var"
  } else {
    set cmd ""
  }

  set filename [pwd]/doc${cmd}_user0.tcl
  set file [open $filename w]

  puts $file {# This file is automatically generated from} 
  puts $file {#   Max Help/"Text Commands" (in Developer mode).}
  puts $file {# Only commands or vars listed here will be shown to end user by}
  puts $file {#   Help/"Text Commands".}
  puts $file ""
    
  puts $file "global DOC"
  if {$doc_box(types_variables)} {
    puts $file "set DOC(initial_user_variables) \{"
  } else {
    puts $file "set DOC(initial_user_commands) \{"
  }
  foreach name [lsort -dictionary [array names doc_user$cmd]] {
    puts $file "  $name"
  }
  puts $file "\}"
    
  close $file

  msg "Wrote \"$filename\" (current directory).\n"
  msg "For it to take effect it must be moved to the golden maxtcl/ directory\n"
  msg "and Max must be recompiled with it.\n" 
}

proc doc_cmd {name} -desc {
    pop-up documentation on named command
} {
  global MAX_DEVELOPER doc_box

  if { [doc_at $name var_source] != "" } {
    set type variable
  } else {
    set type command
  }

  # CLEAR OR CREATE WINDOW
  set w ".doc_cmd"
  if {[info commands $w] != ""} {
    raise $w
    $w.text configure -state normal
    $w.text delete 1.0 end
    $w.text configure -state disabled
  } else {
    catch {destroy $w}
    toplevel $w
    wm geometry $w +250+100
    text $w.text -setgrid 1 -bd 2 \
	-yscrollcommand "$w.scroll set"
    scrollbar $w.scroll -command "$w.text yview"
    button $w.close \
	-text "Close" \
	-command "destroy $w"
    
    pack $w.close -side bottom -fill x
    pack $w.scroll -side right -fill y
    pack $w.text -side left -fill both -expand yes
  }

  wm title $w "max $type documentation"
  wm iconname $w "max $type documentation"

  # ADD TEXT
  $w.text configure -state normal

  # name 
  $w.text insert end "$name"

  # look for variable source
  set cmd_src [doc_at $name var_source]
  if { $cmd_src != "" } {
    # its a variable
    
    # description
    set desc [doc_at $name var_desc]
    if {$desc != ""} { $w.text insert end " - $desc" }
    
    set tmp [join "[doc_at $name var_flags] $cmd_src" ", "]

    $w.text insert end "\n\nTYPE:  $tmp"
    
    # value
    global [lindex [split $name \(] 0]
    $w.text insert end "\n\nVALUE ([doc_at $name var_type]):  [set $name]"

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
    if {$desc != ""} { $w.text insert end " - $desc" }
    
    #set code " built-in command.  "
    #if {[info procs $name] != ""} {set code " proc.  "}
    set code ""
    
    set scope ""
    if {[string index $name 0] == "_"} {set scope " module-private.  "}
    
    $w.text insert end "\n\nTYPE:  $cmd_src$code$scope"

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
    if { $MAX_DEVELOPER } {
      set cmd_internal [doc_at $name cmd_internal]
      if {$cmd_internal != ""} {
	$w.text insert end "\n\nINTERNAL DOC:  $cmd_internal"
      }
    }
    set length [min 30 [llength [split [.doc_cmd.text dump 1.0 end] \n]]]
    $w.text configure -state disabled -height $length
  }
}


proc _print_doc {} {

  global DOC

  puts "\n"

  foreach name [lsort -dictionary $DOC(initial_user_commands)] {
    puts "$name\n"
    puts [doc_at $name cmd_desc]
    puts ""

    if {[info procs $name] != ""} {
      puts "USAGE:  $name [info args $name]\n"
    }
    
    puts [doc_at $name cmd_doc]

    puts "\n---------------------------------\n"
  }
}


proc _html_quote {line} -desc {
  Quote html characters using html notation.
} {
  regsub -all {<} $line {\&#60} line
  regsub -all {>} $line {\&#62} line
  return $line
}

proc _doc_prompt_filename {default} -desc {
  Prompt for documentation output filename.  Return file descriptor or "".
} {

    # Get the filename
    set filename [fs_box -message "Select file for documentation save:" \
	-filename $default]
    # If it was canceled
    if { $filename == "" } { return "" }

    # This prints does an error if file can not be opened.
    if {[catch {set fd [open $filename "w"]} ]} {
	max_error "error: could not open file: $filename"
	return ""
    }
    return $fd
}


proc doc_save_to_file {listbox} -desc {
    allow user to save contents of listbox to a file.
} -doc {
    Argument is the window name of the listbox.
    The entire contents of the listbox are saved in a file.
} {
    # If it is a text box, this works:
    if {! [catch {set goob [$listbox get 0.0 end]}]} {
	set fd [_doc_prompt_filename "maxdoc.txt"]
	if { $fd == "" } return
	puts $fd $goob
    } else {
      set format text
      set prop_list  [list \
	      "{Format} format -radio {text html troff}" \
	      ]
      set ret [prop_menu2 -title "Save Documentation" $prop_list]
      if { $ret == 0 } { return }

      set fd [_doc_prompt_filename \
	[expr {$format == "html" ? "maxdoc.html" : "maxdoc.txt"}]]

      if { $format == "html" } {
	  puts $fd "<HTML>"
	  puts $fd "<HEAD>TITLE>MAX Reference Guide</TITLE></HEAD>"
	  puts $fd "<BODY BGCOLOR=\"ffffff\" >"
	  puts $fd "<HR>"
	  puts $fd "<HR><P><UL>\n"
      }

      # If it is a list box, this command works:
      foreach thingy [$listbox get 0 end] {
	  # Name is first word in thingy
	  regsub { .*$} $thingy "" name
	  set cmd_src [doc_at $name cmd_source]
	  if {[string index $name 0] == "."} {set cmd_src "widget"}
      
	  # get description and doc
	  set desc [doc_at $name cmd_desc]
	  if { $desc == "" } { set desc [doc_at $name var_desc] }
	  set cmd_doc [doc_at $name cmd_doc]
	  if { $cmd_doc == "" } { set cmd_doc [doc_at $name var_doc] }

	  if {$desc == ""} { set $desc $cmd_src }
      
	  set usage [doc_at $name cmd_usage]

	  if { $format == "text" } {
	      puts $fd "$name\n"
	      puts $fd "Description: $desc\n"
	      if { $usage != "" } {
		  puts $fd "Usage: $usage\n"
	      }
	      puts $fd "$cmd_doc\n"
	  } elseif { $format == "html" } {
	      puts $fd "<TT><B><LI>$name\n</B></TT><P>"
	      puts $fd "[_html_quote $desc]<P>"
	      if { $usage != "" } {
		  puts $fd "Usage:  [_html_quote $usage]<P>"
	      }

	      # Note: originally, I tried to use <PRE> only where
	      # the indenting changes.  However, our documentation is
	      # so non-uniform that it just makes a mess.  In particular,
	      # much internal max documentation has no indenting
	      # on the first line, but all other lines are indented,
	      # which makes for a better appearance in the C file.
	      # So just PRE all the documentation.
	      if {0} {
		set in_pre 0
		# first_indent is the amount the first line is indented.
		set first_indent ""
		regexp "^\[ \t\]*" $cmd_doc first_indent
		foreach line [split [string trimright [_html_quote $cmd_doc]] \n] {
		  if {[regexp "^\[ \t\]*\$" $line]} {
		    puts $fd "<P>"
		    continue
		  }
		  set this_indent ""
		  regexp "^\[ \t\]*" $line this_indent
		  if {$this_indent != $first_indent} {
		    if {! $in_pre} {
		      set in_pre 1
		      puts $fd "<PRE>"
		    }
		  } else {
		    if { $in_pre} {
		      set in_pre 0
		      puts $fd "</PRE>"
		    }
		  }
		  puts $fd "$line"
		}
		if {$in_pre} { puts $fd "</PRE>" }
	      }

	      if { $cmd_doc != "" } {
		puts $fd "<PRE>\n[_html_quote $cmd_doc]\n</PRE>"
	      }
	      puts $fd "<P>\n"
	  } else {
	      puts $fd "\\fB$name\\fR\n"
	      puts $fd ".in +0.5i"
	      puts $fd "\\fBDescription:\\fR $desc\n"
	      if { $usage != "" } {
		  puts $fd ".ti +0.5i"
		  puts $fd "\\fC$usage\\fR\n"
	      }
	      puts $fd "$cmd_doc\n"
	      puts $fd ".in -0.5i"
	  }
      }

      if { $format == "html" } {
	  puts $fd "</UL></BODY></HTML>\n"
      }
    }
    close $fd
}
