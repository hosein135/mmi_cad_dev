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

set RCSVERSION(group.tcl) { $Revision: 1.9 $ }

# tcl routines related to paint groups, not gcell groups.

proc group_new {class {prop_list ""}} -desc {
    Create a group of given class and properties 
} {
    global GROUP

    error "This proc is never called!  If you get this message talk to pat!"

    #save box and group for restore
    set orig_group [db_group] 

    # kudge unique name (TODO:  this doesn't really work, fix it!)
    if { ![info exists GROUP(uniq)] } {
	set GROUP(uniq) 0
    }
    incr GROUP(uniq)
    set group "$class$GROUP(uniq)"

    # define class
    msg_catch "db_group_class nfet" tmp1 tmp2

    #create group
    db_group $group $class
    
    #set properties
    
    foreach pair $prop_list {
	setl {name value} $pair
	puts "DEBUG name=$name value=$value"
	db_group_attribute $name $value
    }

    # restore original group
    db_group $orig_group

    return $group
}

proc group_transfer {oldGroup newGroup} -desc {
    transfer contents of oldGroup to newGroup
} {

    #save box and group for restore
    #set orig_box [layt_box exact]
    set orig_group [db_group]
    save_selection __GROUP_TRANSFER__

    # do the transfer
    #:select -g -editOnly area *,labels
    sel_clear_g
    db_group $oldGroup
    eval sel_area -group -layers *,labels [lay_bbox]

    sel_group_transfer $newGroup
    db_group $orig_group


    #db_group $newGroup
    #:copy N 0
    #db_group $oldGroup
    #:erase

    #restore box and group
    #if { [llength $orig_box] == 4 } {eval layt_box exact $orig_box}
    db_group $orig_group
    restore_selection __GROUP_TRANSFER__
}

proc group_from_cell {cell} -desc {
    "place" a cell as a group
} {
    global GROUP

    #save box and group for restore
    set orig_group [db_group] 

    # kudge unique name (TODO:  this doesn't really work, fix it!)
    if { ![info exists GROUP(uniq)] } {
	set GROUP(uniq) 0
    }
    incr GROUP(uniq)
    set group "g$GROUP(uniq)"
    
    db_group $group
    :dump $cell

    #restore group
    db_group $orig_group
}


