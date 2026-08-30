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

set RCSVERSION(help0.tcl) { $Revision: 1.9 $ }

# Implement -help option

proc help_usage {} -desc {
  display usage message and exit
} {
  global MN_SWITCHS MN_SWITCHES

  puts ""
  puts "Usage:"
  puts "\tmax \[-switch \[value\]\] ... \[<max|gds file> ...\]"
  puts ""
  puts "switches:"

  foreach switch [split [use_first MN_SWITCHS MN_SWITCHES] \n] {
    puts [format "\t%-20s %s" [lindex $switch 0] [lindex $switch 1]]
  }

  puts [format "\t%-20s %s" "-technolgy <name>" "technology to use"]
  puts [format "\t%-20s %s" "-geometry XxY+T+Z" "start MAX with given size and/or position"]
  puts [format "\t%-20s %s" "-colormap new"   "start MAX with private colormap"]
  puts [format "\t%-20s %s" "-iconify 1"        "iconify MAX on bringup"]
  puts [format "\t%-20s %s" "-batch 1"          "batch mode.  No popups"]
  #puts [format "\t%-20s %s" "-new <file>"       "max a new MAX file"]
  puts [format "\t%-20s %s" "-command <tcl_cmd>" "execute tcl command"]
  puts [format "\t%-20s %s" "-visual truecolor"  "forces non-colormapped graphics"]
  puts [format "\t%-20s %s" "-visual pseudocolor" "forces 8-bit colormapped graphics"]
  puts [format "\t%-20s %s" "-set <var>=<value>"  "set global variable"]
  puts [format "\t%-20s %s" "-project <name>"  "Read commands from file <name>.rc"]
  puts [format "\t%-20s %s" "-norc"  "Do not read project or max.rc files"]
  puts [format "\t%-20s %s" "-help"  "print this message"]
  puts ""

  mn_exit
}

