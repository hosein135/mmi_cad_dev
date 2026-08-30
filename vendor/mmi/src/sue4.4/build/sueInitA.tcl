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


# Early loading stuff after globals loaded.

# Load in the default settings (these settings can be changed by users
# by setting their value in a "~/.suerc" and/or ".suerc" file)
# Also load mmi_local and mmi_private ones

set SUERC(system) "$SUE_DIR"
set SUERC(site) "$env(MMI_LOCAL)/sue"
set SUERC(user) "~"
set SUERC(private) "~/mmi_private/sue"
set SUERC(local) "[pwd]"

set ignore_suerc ""

if {$NORC == 1} {
  puts "Ignoring ALL .suerc files (except system) because of -norc switch."
  set SUERC(site) ""
  set SUERC(user) ""
  set SUERC(private) ""
  set SUERC(local) ""

} else {
  foreach line [split [use_first env(SUE_IGNORE_SUERC)] { ,;:}] {
    # unset these
    if {[info exists SUERC($line)] && $line != "system"} {
      set SUERC($line) ""
      lappend ignore_suerc $line
    }
  }

  if {$ignore_suerc != ""} {
    puts "Ignoring \"[join $ignore_suerc ,]\" .suerc files because of environment variable SUE_IGNORE_SUERC"
  }
}

set PROJECT [use_first PROJECT env(MMI_PROJECT) env(PROJECT)]

foreach suerc_path "$SUERC(system) $SUERC(site) $SUERC(user) $SUERC(private) $SUERC(local)" {

  # remove ~
  set suerc_path [file nativename $suerc_path]

  if {[info exist SUERC($suerc_path)]} {
    # already got this one
    continue
  }
  set SUERC($suerc_path) 1

  set success 0
  foreach suerc_name "sue.rc .suerc" {
    set suerc "$suerc_path/$suerc_name"
      
    if {[file readable $suerc]} {
      if {$success > 0} {
	puts "WARNING: loading both sue.rc and .suerc in directory \"$suerc_path\"."
      }

      puts "Sourcing $suerc"
      if {[catch "source $suerc" msg]} {
	puts $msg
      }
      incr success
    }
  }

  if {$suerc_path == $SUERC(system)} {
    # project files -- load after system .suerc
    if {$PROJECT != ""} {
      # load project values
      project_source_file SUE
      
      # since TIMING_DATA is really DPC_TIMING
      foreach name [array names TIMING_DATA] {
	set DPC_TIMING($name) $TIMING_DATA($name)
      }
    }
  }
}


# need to fix up some variables
set DEFAULT_SPICE_HEADER [eval list $DEFAULT_SPICE_HEADER]
set DEFAULT_VERILOG_HEADER [eval list $DEFAULT_VERILOG_HEADER]
set tmp ""
foreach tmp2 [use_first PRINT(DONT_PRINT_DIRS)] {
  lappend tmp [eval list $tmp2]
}
set PRINT(DONT_PRINT_DIRS) $tmp

set dirs ""
foreach dir $VERILOG_PATH {
  lappend dirs [clean_dir $dir]
}
set VERILOG_PATH $dirs

set dirs ""
foreach dir $BACK_ANNOTATE_PATH {
  lappend dirs [clean_dir $dir]
}
set BACK_ANNOTATE_PATH $dirs

# MODE is used for Sim menu, choice of default icons to load, and netlisting/
# probing commands
set MODE [use_first MODE env(SUE_MODE) DEFAULT_MODE]

set NETLIST_TYPE [use_first NETLIST_TYPE MODE]
set NETLIST_PROPS [use_first NETLIST_PROPS MODE]

set PROBE_TYPE [use_first [string toupper $NETLIST_TYPE]_PROBE_TYPE]

# When = 1 this stops a backround canvas event handler
set DISABLE_CANVAS_EVENT 0

# set up the default list of tags which are saved and restored by
# save_bindings and restore_bindings
set TAGS_TO_SAVE "icon draw_item wire dot open edit_marker"

# here is basically a macro
set SNAP_XY {[$cur_c canvasx %x $scale] [$cur_c canvasy %y $scale]}
set NOSNAP_XY {[$cur_c canvasx %x] [$cur_c canvasy %y]}
set SNAP10_XY {[$cur_c canvasx %x [expr $scale/10]] [$cur_c canvasy %y [expr $scale/10]]}

# for propagating changes in icons thru schematics which contain instances
# of those icons.
set MODIFY_ICON(_index) 0
set MODIFY_ICON_LEVEL(_index) 0

if {$FONT_MODE == "standard"} {
  # All that is used are the standard fonts included with most X servers
  set FONT(1) $FONT(tiny)
  set FONT(2) $FONT(tiny)
  set FONT(3) -*-helvetica-Bold-R-Normal--*-80-*
  set FONT(4) -*-helvetica-Bold-R-Normal--*-80-*
  set FONT(5) -*-helvetica-Bold-R-Normal--*-80-*
  set FONT(6) -*-helvetica-Bold-R-Normal--*-100-*
  set FONT(7) -*-helvetica-Bold-R-Normal--*-100-*
  set FONT(8) -*-helvetica-Bold-R-Normal--*-120-*
  set FONT(9) -*-helvetica-Bold-R-Normal--*-120-*
  set FONT(10) -*-helvetica-Bold-R-Normal--*-120-*
  set FONT(11) -*-helvetica-Bold-R-Normal--*-140-*
  set FONT(12) -*-helvetica-Bold-R-Normal--*-140-*
  set FONT(13) -*-helvetica-Bold-R-Normal--*-140-*
  set FONT(14) -*-helvetica-Bold-R-Normal--*-140-*
  set FONT(15) -*-helvetica-Bold-R-Normal--*-140-*
  set FONT(16) -*-helvetica-Bold-R-Normal--*-180-*
  set FONT(17) -*-helvetica-Bold-R-Normal--*-180-*
  set FONT(18) -*-helvetica-Bold-R-Normal--*-180-*
  set FONT(19) -*-helvetica-Bold-R-Normal--*-180-*
  set FONT(20) -*-helvetica-Bold-R-Normal--*-180-*
  set FONT(21) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(22) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(23) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(24) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(25) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(26) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(27) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(28) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(29) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(30) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(31) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(32) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(33) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(34) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(35) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(36) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(37) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(38) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(39) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(40) -*-helvetica-Bold-R-Normal--*-240-*

} elseif {$FONT_MODE == "font_server"} {
  # Uses fonts in addition to the standard (limited) fonts present on
  # most machines to improve the font proportionality.  These extra fonts 
  # are generated by the font server which is a part of X11R5 and later (??).  
  # Since font generation is fairly slow (a few seconds per font) only 
  # a small number of additional fonts are added.  Any ideas on a better
  # font mechanism would be appreciated.
  set FONT(1) -*-helvetica-Bold-R-Normal--*-10-*
  set FONT(2) -*-helvetica-Bold-R-Normal--*-10-*
  set FONT(3) -*-helvetica-Bold-R-Normal--*-40-*
  set FONT(4) -*-helvetica-Bold-R-Normal--*-40-*
  set FONT(5) -*-helvetica-Bold-R-Normal--*-80-*
  set FONT(6) -*-helvetica-Bold-R-Normal--*-80-*
  set FONT(7) -*-helvetica-Bold-R-Normal--*-100-*
  set FONT(8) -*-helvetica-Bold-R-Normal--*-120-*
  set FONT(9) -*-helvetica-Bold-R-Normal--*-140-*
  set FONT(10) -*-helvetica-Bold-R-Normal--*-140-*
  set FONT(11) -*-helvetica-Bold-R-Normal--*-180-*
  set FONT(12) -*-helvetica-Bold-R-Normal--*-180-*
  set FONT(13) -*-helvetica-Bold-R-Normal--*-180-*
  set FONT(14) -*-helvetica-Bold-R-Normal--*-180-*
  set FONT(15) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(16) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(17) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(18) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(19) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(20) -*-helvetica-Bold-R-Normal--*-240-*
  set FONT(21) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(22) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(23) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(24) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(25) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(26) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(27) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(28) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(29) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(30) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(31) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(32) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(33) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(34) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(35) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(36) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(37) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(38) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(39) -*-helvetica-Bold-R-Normal--*-450-*
  set FONT(40) -*-helvetica-Bold-R-Normal--*-450-*

} elseif {$FONT_MODE == "extended"} {
  # Uses special SUE fonts that are included in the "fonts" subdirectory
  # Note that you need to add this to your font path with a command:
  #   xset +fp <SUE_DIR>/fonts

  set FONT(1) -adobe-helvetica-bold-r-normal--2-*
  set FONT(2) -adobe-helvetica-bold-r-normal--4-*
  set FONT(3) -adobe-helvetica-bold-r-normal--6-*
  set FONT(4) -adobe-helvetica-bold-r-normal--8-*
  set FONT(5) -adobe-helvetica-bold-r-normal--10-*
  set FONT(6) -adobe-helvetica-bold-r-normal--12-*
  set FONT(7) -adobe-helvetica-bold-r-normal--14-*
  set FONT(8) -adobe-helvetica-bold-r-normal--16-*
  set FONT(9) -adobe-helvetica-bold-r-normal--18-*
  set FONT(10) -adobe-helvetica-bold-r-normal--20-*
  set FONT(11) -adobe-helvetica-bold-r-normal--22-*
  set FONT(12) -adobe-helvetica-bold-r-normal--24-*
  set FONT(13) -adobe-helvetica-bold-r-normal--26-*
  set FONT(14) -adobe-helvetica-bold-r-normal--28-*
  set FONT(15) -adobe-helvetica-bold-r-normal--30-*
  set FONT(16) -adobe-helvetica-bold-r-normal--32-*
  set FONT(17) -adobe-helvetica-bold-r-normal--34-*
  set FONT(18) -adobe-helvetica-bold-r-normal--36-*
  set FONT(19) -adobe-helvetica-bold-r-normal--38-*
  set FONT(20) -adobe-helvetica-bold-r-normal--40-*
#  set FONT(21) -adobe-helvetica-bold-r-normal--42-*
  set FONT(21) -adobe-helvetica-bold-r-normal--40-*
  set FONT(22) -adobe-helvetica-bold-r-normal--44-*
#  set FONT(23) -adobe-helvetica-bold-r-normal--46-*
  set FONT(23) -adobe-helvetica-bold-r-normal--44-*
  set FONT(24) -adobe-helvetica-bold-r-normal--48-*
#  set FONT(25) -adobe-helvetica-bold-r-normal--50-*
  set FONT(25) -adobe-helvetica-bold-r-normal--48-*
  set FONT(26) -adobe-helvetica-bold-r-normal--52-*
#  set FONT(27) -adobe-helvetica-bold-r-normal--54-*
  set FONT(27) -adobe-helvetica-bold-r-normal--52-*
#  set FONT(28) -adobe-helvetica-bold-r-normal--56-*
  set FONT(28) -adobe-helvetica-bold-r-normal--52-*
  set FONT(29) -adobe-helvetica-bold-r-normal--58-*
#  set FONT(30) -adobe-helvetica-bold-r-normal--60-*
  set FONT(30) -adobe-helvetica-bold-r-normal--58-*
#  set FONT(31) -adobe-helvetica-bold-r-normal--62-*
  set FONT(31) -adobe-helvetica-bold-r-normal--58-*
  set FONT(32) -adobe-helvetica-bold-r-normal--64-*
#  set FONT(33) -adobe-helvetica-bold-r-normal--66-*
  set FONT(33) -adobe-helvetica-bold-r-normal--64-*
#  set FONT(34) -adobe-helvetica-bold-r-normal--68-*
  set FONT(34) -adobe-helvetica-bold-r-normal--64-*
  set FONT(35) -adobe-helvetica-bold-r-normal--70-*
#  set FONT(36) -adobe-helvetica-bold-r-normal--72-*
  set FONT(36) -adobe-helvetica-bold-r-normal--70-*
#  set FONT(37) -adobe-helvetica-bold-r-normal--74-*
  set FONT(37) -adobe-helvetica-bold-r-normal--70-*
#  set FONT(38) -adobe-helvetica-bold-r-normal--76-*
  set FONT(38) -adobe-helvetica-bold-r-normal--70-*
#  set FONT(39) -adobe-helvetica-bold-r-normal--78-*
  set FONT(39) -adobe-helvetica-bold-r-normal--70-*
  set FONT(40) -adobe-helvetica-bold-r-normal--80-*

} else {
  puts "ERROR: FONT_MODE is set to an incorrect value"
}

# Maximum number of font sizes
set FONT(MAX) 40

proc setup_font {name scaling} {

  global FONT

  for {set i 0} {$i <= $FONT(MAX)} {incr i} {
    set FONT($name,$i) \
	$FONT([max 1 [min $FONT(MAX) [expr round($scaling*$i)]]])
  }
}

# setup the font matrix for 3 size fonts
setup_font very-small $FONT(very-small)
setup_font small $FONT(small)
setup_font standard $FONT(standard)
setup_font large $FONT(large)
setup_font very-large $FONT(very-large)

# create a null font for way zoomed out
# These fonts are very slow
font create _SUE_NIL_ -size 1
set FONT(very-small,0) _SUE_NIL_
set FONT(small,0) _SUE_NIL_
set FONT(standard,0) _SUE_NIL_
set FONT(large,0) _SUE_NIL_

# just so this has a value
set NETLIST_MAX_NAME_LENGTH 1000

# set the fsbox default pattern
set FSBOX(default,pattern) *$SUFFIX(default)
