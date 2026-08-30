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


# The main part of SUE is now loaded.  Continue with this final piece
# of non-procedural part of SUE.

# Load any tcl patches
#foreach patch [use_first PATCHES] {
#  if {[catch $patch msg]} {
#    puts "SUE ERROR (patch): $msg"
#  }
#}

# Load any tcl patches with file names of .sue_patch<version_number>
set VERSION_NUMBER [lindex [split $VERSION E] 1]
foreach patch_dir "$env(MMI_TOOLS)/sue $env(MMI_LOCAL)/sue $env(MMI_TOOLS)/patches ~/mmi_private/sue [use_first PATCH_DIR]" {
  foreach patch [glob -nocomplain $patch_dir/*.sue_patch$VERSION_NUMBER] {
    puts "Loading SUE patch $patch"
    if {[catch "source $patch" msg]} {
      puts "SUE ERROR in patch $patch: $msg"
    }
  }
}

# Start up SUE
set HIERARCHY ""

# make a window
set WIN .win1
make_window $WIN

# Set up the auto load path such that the default stuff is last.
add_auto_path $SCHEM_DIR(devices)
if {$MODE == "spice"} {
  add_auto_path $SCHEM_DIR(spice)
}
if {$MODE == "verilog"} {
  add_auto_path $SCHEM_DIR(verilog)
}

# add any command line libraries.  Unlike the the defaults icons,
# these don't get loaded until they are needed and thus do not show up
# automatically in the icon listbox.
set tmp "[use_first LIB] [use_first AUTOLIB]"
foreach lib $tmp {
  add_auto_path $lib
}

add_auto_path [pwd]

# force wish to load in all of the tclIndexes so we know where stuff came from.
auto_load_index

# Load any auto load libraries.  Note to see the affect, need to do
# a "make_icon_listbox" afterwards (if you want to do this somewhere else)
foreach lib [lreverse [use_first AUTOLIB]] {
  if {![info exists _AUTOLIB_($lib)]} {
    # only load once
    set _AUTOLIB_($lib) 1

    auto_load_directory $lib
  }
}

# Load the basic devices which reside in the schematics/devices
# directory.  Note that any .sue icons in this directory will be automatically
# loaded and appear in the icons listbox.
auto_load_directory $SCHEM_DIR(devices) silent

# Next, load all icons in either spice or verilog directory, depending on
# the mode.  Also setup the default properties that get added to every
# new icon -- this is only a convenience.  Everything gets a name, and
# in spice mode everything gets a M property. 
if {$MODE == "spice"} {
  set mode_props {{-type user -name name} {-type user -name M}}
  auto_load_directory $SCHEM_DIR(spice) silent
}
if {$MODE == "verilog"} {
  set mode_props {{-type user -name name}} 
  auto_load_directory $SCHEM_DIR(verilog) silent
}

set DEFAULT_PROPERTIES [use_first DEFAULT_PROPERTIES mode_props]


# Sets the default insert cursor to the correct color
option add *insertBackground $COLORS(fore)

# the priorities are used for determining net names.  The highest
# priority determines the name.

set TERM_PRIORITY(term) 0
set TERM_PRIORITY(suggest) 2
set TERM_PRIORITY(io) 5
set TERM_PRIORITY(input) 5
set TERM_PRIORITY(output) 5
set TERM_PRIORITY(inout) 5
set TERM_PRIORITY(global) 20
set TERM_PRIORITY(name) 10

# hide the sue main window.  
wm withdraw .

# call up a blank schematic
launch "make_new_schematic no_name" no_busy

# if they get lost accidentally, we can find them again
save_bindings

# needed since xview and yview aren't corrent until an update
# Note that if the user resizes the window then this must be updated
update
set DEFAULT_VISIBLE_BBOX [visible_bbox default]

make_icon_listbox

# do this again since it might be overridden by .suerc
foreach command $SET {
  setl {variable value} [split $command =]
#  puts "set $variable $value"
  set $variable $value
}

# add any default_generators
#foreach gen [use_first DEFAULT_GENERATORS] {
#  eval $gen
#}

set loaded 0
foreach file $cells {
  launch "load_schematic $file"
  incr loaded
}

# initialize any new schematics the user wants
foreach schematic $new {
  launch "make_new_schematic $schematic"
  incr loaded
}

if {$loaded > 0} {
  # force wish to load in all of the tclIndexes
  auto_load_index
  # remake listbox
  make_icon_listbox
}

rename exit _TCL_EXIT_

proc exit {{-force} {-error_code}} -type user -desc {

Special tcl exit procedure for SUE.

Usage: exit [-force] [-error_code]

If there are modified cells and the global variable BATCH is set to 0,
queries the user before exiting.  The query is bypassed if the
"-force" argument is given or BATCH is set to 1.

If "-error_code" and if there have been any errors during that sue session,
sue returns an error code 2, otherwise 0.

} {

  global ANY_ERROR

  if {$force} {
    puts "Exiting Micro Magic SUE.  Have a nice day."
    if {$error_code && [use_first ANY_ERROR] == 1} {
      _TCL_EXIT_ 2
    } else {      
      _TCL_EXIT_
    }

  } else {
    if {$error_code} {
      modify_exit -error_code
    } else {
      modify_exit
    }
  }
}

# first execute any commands in SUE_EXECUTE
foreach command $SUE_EXECUTE {
  puts "Executing \"$command\""
  launch $command
}

# execute any command line SUE commands
foreach command $CMD {
  puts "Executing \"$command\""
  launch $command
}

# make a happy message for the user
set WIN_DATA($WIN,display_msg) "Welcome to Micro Magic Sue ($VERSION)"

if {$FONT_MODE == "extended"} {

  catch "exec xset -q" msg
  if {![regexp {sue[0-9.]*/fonts} $msg]} {

    puts "Generating Fonts..."

    # make a bogus cache and put all the SUE fonts into it, then TK will
    # never think that the fonts aren't being used and remove them
    canvas $WIN.font_cache

    for {set i 1} {$i <= 40} {incr i} {
      $WIN.font_cache create text 20 [expr 4 * $i] -text x -font $FONT($i)
    }
    $WIN.font_cache create text 20 0 -text x -font _SUE_NIL_
  }
}

# show user a popup containing any errors encountered during bringup.
sue_error flush
