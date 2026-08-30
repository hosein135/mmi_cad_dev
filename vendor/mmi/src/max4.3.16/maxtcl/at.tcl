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

set RCSVERSION(at.tcl) { $Revision: 1.4 $ }

# Implements attribute database.

#attributes are stored as $name$at_sep$attribute
#NOTE: must be single char (since split is used below.
#NOTE: If this char is used in global variable or command names, it will
#      break this code.
set at_sep "|"

# get/set attribute of name
# doc_at name attribute [value]
proc at {name attribute args} -desc {
    get/set attribute of name

USAGE: at name attribute [value]
} {
    global at_db at_sep
    set argc [llength $args]

    if {$argc == 0} {
	# no value given, return current value 
	set value ""
	catch {set value $at_db($name$at_sep$attribute)}
	return $value
    } elseif {$argc == 1} {
	# value given, do set
	set at_db($name$at_sep$attribute) [lindex $args 0]
    } else {
	# too many args
	error "at called with too many args"
    }
}

proc at_search {name_pat at_pat} -desc {
    returns list of {name attribute value} triples matching glob style arg patterns
} {
    global at_db at_sep

    set result ""
    set sid [array startsearch at_db]
    while {[array anymore at_db $sid]} {
	set e [array nextelement at_db $sid]
	set el [split $e $at_sep]
	set e_name [lindex $el 0]
	set e_at [lindex $el 1]
	if {[string match $name_pat $e_name] && [string match $at_pat $e_at]} {
	        lappend result [list $e_name $e_at $at_db($e)]
	}
    }
    return $result
}
