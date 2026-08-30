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

#!/bin/tcsh -f

# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit

# Removes simple comments from tcl code

proc remove_comments {args} {

  foreach filename $args {

    if {[catch "open $filename r" FILE_ID]} {
      # error
      puts stderr "Aborting, $FILE_ID"
      exit
    } 

    puts stderr "parsing $filename ..."

    set previous_line_cont 0
    set comment 0

    while {[gets $FILE_ID line] >= 0} {

      set len [string length $line]
      incr len -1

      if {[string index $line $len] == "\\"} {
	# continuation on this line, don't look at comments on next line
	set this_line_cont 1
      } else {
	set this_line_cont 0
      }

      if {$previous_line_cont && $comment} {
	# multi-line comment
      } elseif {!$previous_line_cont && \
	      [string index [string trimleft $line] 0] == "\#"} {
	# comment line
	if {$this_line_cont} {
	  # special case
	  set comment 1
	} else {
	  set comment 0
	}
      } else {
	# write out line unchanged
	puts $line
	set comment 0
      }

      set previous_line_cont $this_line_cont
    }

    # close the file
    close $FILE_ID
  }

  puts stderr "done."
}


# do it

if {$argv == ""} {
  puts "Usage:"
  puts "\tremove_comments <tcl_file>\n"

} else {
  eval remove_comments $argv
}

exit
