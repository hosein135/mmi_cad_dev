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

proc fluid_let {bindings body} {
    set n 0

    unwind_protect {
	set i 0

	foreach binding $bindings {
	    set var [lindex $binding 0]
	    set val [lindex $binding 1]
	    set vars($i) $var

	    upvar $var _$var
	    set is_bound [info exists _$var]
	    set bound($i) $is_bound
	    if { $is_bound == 1 } {
		set old_val [set _$var]
		set vals($i) $old_val
	    }

	    uplevel set $var $val

	    incr i
	    set n $i
	}

	uplevel $body

    } {
	set i 0

	while { $i < $n } {
	    if { $bound($i) == 1 } {
		uplevel 1 set $vars($i) $vals($i)
	    } else {
		uplevel 1 unset $vars($i)
	    }
	    incr i
	}
    }
}
