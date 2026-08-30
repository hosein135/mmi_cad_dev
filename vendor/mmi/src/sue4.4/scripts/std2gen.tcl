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

#!/bin/csh -f
 
# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit
 
# Script to merge similar cells into a generator based on a template file
# Written by Lee Tavrow, 1999


proc merge {filename todir args} {

  puts "Reading control file \"$filename\" ..."

  if {![file readable $filename]} {
    puts "Aborting, can't read file \"$filename\""
    exit
  }

  # read the file
  if {[catch "open $filename r" FILE_ID]} {
    # problem
    puts "Aborting, error while reading file \"$filename\": $FILE_ID"
    exit
  } 

  set compat ""

  set todir [string trimright $todir]
  set fromdirs ""
  foreach dir $args {
    lappend fromdirs [string trimright $dir]
  }

  # clean up the to directory
  catch "exec rm -rf $todir/*.sue"

  # parses something like
  # INV1 INV2 INV3

  while {[gets $FILE_ID line] >= 0} {

    set line [string trim $line]

    if {[string index $line 0] == "\#" || [lindex $line 0] == ""} {
      # comment or blank line, skip
      continue
    }

    if {[llength $line] == 1} {
      # just copy this cell over, no generator
      set file [find_file $line $fromdirs]
      if {$file == ""} {
	puts "ERROR, Can't read cell \$line\" from directories \"$fromdirs\"."
	continue
      }
      exec cp $file $todir/$line.sue
      continue
    }

    # create the generator
    
    set gen [lindex $line 0]
    set genfile $todir/$gen.sue
    if {[catch "open $genfile w" GEN_ID]} {
      # problem
      puts "ERROR, skipping \"$line\".  Can't create file \"$genfile\": $GEN_ID"
      continue
    } 

    puts $GEN_ID "\# Created using std2gen from cells \"$line\"\n"

    # make the schematic
    puts $GEN_ID "proc SCHEMATIC_$gen args {"
    puts $GEN_ID "  call_use_keyword \$args \{\{name $gen\} \{cell $gen\}\}"
    puts $GEN_ID "  switch \$cell {"

    foreach cell $line {
      set file [find_file $cell $fromdirs]
      if {$file == ""} {
	puts "ERROR, Can't read cell \$cell\" from directories \"$fromdirs\"."
	continue
      }
      source $file

      puts $GEN_ID ""
      puts $GEN_ID "    $cell {"
      puts $GEN_ID [info body SCHEMATIC_$cell]
      puts $GEN_ID "    }"
    }

    puts $GEN_ID "  }"
    puts $GEN_ID "}\n"

    # make the icon
    puts $GEN_ID "proc ICON_$gen args {"
    puts $GEN_ID "  icon_generator \$args \{\{cell $gen \{radio $line\}\}\}"
    puts $GEN_ID "  switch \$cell {"

    foreach cell $line {
      puts $GEN_ID ""
      puts $GEN_ID "    $cell {"
      puts $GEN_ID [info body ICON_$cell]
      puts $GEN_ID "    }"
    }

    puts $GEN_ID "  }"
    puts $GEN_ID "}"

    # make special schematic for compatibility with non-generator schematics
    foreach cell [lrange $line 1 end] {
      lappend compat "  generate $gen $cell -cell $cell"
    }

    # close the file
    close $GEN_ID

    puts "Created \"$genfile\"."
  }

  # close the file
  close $FILE_ID

  # now write compatability schematic
  set name "GENERATORS"
  set compatfile $todir/$name.sue
  if {[catch "open $compatfile w" FILE_ID]} {
    # problem
    puts "ERROR, can't write compatilibity file \"$compatfile\": $FILE_ID"
  } else {

    puts $FILE_ID "\# Special compatibility schematic created by std2gen."
    puts $FILE_ID "\# Load this schematic into SUE before loading any other schematics"
    puts $FILE_ID "\# when switching from a library that does not use generator standard cells.\n"

    puts $FILE_ID "proc SCHEMATIC_$name {} {"

    puts $FILE_ID "  make_text -origin {0 0} -text {Generators Loaded.}"

    foreach line $compat {
      puts $FILE_ID $line
    }
    puts $FILE_ID "}"

    # close the file
    close $FILE_ID

    puts "Created \"$compatfile\"."
  }

  puts "done."
}

if {[llength $argv] < 3} {
  puts "Usage:\n"
  puts "\tstd2gen.tcl <control_filename> <to_dir> <from_dir1> <from_dir2> ... \n"
  exit
}


# look for a readable sue file in the given directories

proc find_file {cell dirs} {

  foreach dir $dirs {
    if {[file readable $dir/$cell.sue]} {
      return $dir/$cell.sue
    }
  }

  # can't find/read it
  return ""
}


# do it
eval merge $argv

exit

