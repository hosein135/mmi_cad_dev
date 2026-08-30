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

proc nl_remove_assigns args {
    nl_getopt remove_assigns "Remove all assignments from the specified design." {
	{-silent boolean "don't print warnings"}
	{-recursive boolean "do the entire hierarchy"}
	{-feedthroughs boolean 
	 "allow assignments connecting ports to be removed, which creates feedthroughs"}
    } {
	&optional
	{design current_design "remove the assignments from this design"}
    } $args

    set command "nl_remove_buffers"

    if { $recursive != 0 } {   
	lappend command -recursive
    }

    if { $feedthroughs != 0 } {
	lappend command -feedthroughs
    }

    if { $silent != 0 } {
	lappend command -silent
    }

    lappend command "*assignment*"
    lappend command $design

    eval $command
}

nl_register_command nl_remove_assigns
