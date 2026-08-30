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


# Non procedural early loading of SUE.  Requires utilities.tcl and
# call_by_keyword.tcl to be loaded.

# Versions are of the form MMI_SUE<major>.<minor>.<inc>
set VERSION MMI_SUE$SUE_VERSION

#if {[info exists COMPILE_TIME]} {
#  puts "Version $VERSION Compiled $COMPILE_TIME"
#} else {
#  puts "Version $VERSION"
#}

#  puts "Loading Micro Magic Sue..."	

set SUE_DIR [file nativename [file dirname [file dirname $argv0]]]

if {$SUE_DIR == "."} {
  set SUE_DIR [pwd]
}

# figure out the architecture for launching certain binaries
if {[catch "exec uname" arch]} {
  # shouldn't happen, default to sun
  set arch SunOS
}
switch $arch {
  SunOS {
    set SUE_BIN bin.sparc-solaris2
  }
  Linux {
    set SUE_BIN bin.i486-linux
  }
  HP-UX {
    set SUE_BIN bin.hppa
  }
  default {
    puts "Aborting SUE, unknown architecture \"$arch\"."
    exit
  }
}

# If you are using the standard version of SUE which has rotated text
# then you need to tell SUE to use rotated text.
# Otherwise set to 0.
set ROTATE_TEXT 1

# 0 = more compact but chance of overlap, 1 = old way
set ANCHOR_IN 1

# Note that special characters get eaten through the shell.  So,
# for example, the user can't put lists on the command line.

if {[catch {call_keyword -nocase -append $argv \
		{{MODE ""} {LIB ""} {AUTOLIB ""} {CMD ""} {PROJECT ""} \
		     {SET ""} {ICONIFY ""} {BATCH ""} {new ""} \
		     {NORC ""} {log 0}}} cells]} {
  puts "ERROR in startup line.  All cells and successive options ignored."
  puts "  $cells"
  set cells ""
}

# NOTE: log already dealt with in "sue" script

# otherwise if you mistype, you wait forever
set auto_noexec 1

# Set the tcl prompts so the user knows this is the SUE command window
if {[string first mmi/build [info nameofexecutable]] != -1} {
  # hack so we see this as suex
#  tk appname suex

} elseif {[string first mmi/src [info nameofexecutable]] != -1} {
  # hack so we see this as suez -- development version
#  tk appname suez

} else {
#  tk appname sue
}

#set _INTERP_ sue
#set _INTERP_ [string toupper [winfo name .]]
set _INTERP_ [winfo name .]
regsub -all " " $_INTERP_ "" _INTERP_

proc prompt_main {}	"puts -nonewline \"${_INTERP_}> \""
proc prompt_partial {}	"puts -nonewline \"${_INTERP_}? \""
set tcl_prompt1 prompt_main
set tcl_prompt2 prompt_partial


# for 2-headed displays, environmental variable PROBE_DISPLAY if it exists 
# determines what display to bring up nst/signalscan on.  The fallback of
# SPICETOOL_DISPLAY is for historical reasons.  
#
# valid fields are "", ":0.0", ":0.1", or "other" for other display than sue.

set PROBE_DISPLAY [use_first env(PROBE_DISPLAY) env(SPICETOOL_DISPLAY)]
if {$PROBE_DISPLAY == "other"} {
  # deals with dots in the computer name, e.g.: mmi21.foo.com:0.1
  regexp {^(.*):(.*)$} [winfo screen .] tmp display screen
  set parts [split $screen .]
  set PROBE_DISPLAY \
      "-display $display:[lindex $parts 0].[expr 1 - [lindex $parts 1]]"
} elseif {$PROBE_DISPLAY != "" && \
	      [string range $PROBE_DISPLAY 0 7] != "-display"} {
  set PROBE_DISPLAY "-display $PROBE_DISPLAY"
}

# first execute any set statement in SUE command line
foreach command $SET {
  setl {variable value} [split $command =]
  puts "set $variable $value"
  set $variable $value
}

