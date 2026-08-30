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

proc nl_find_unlinked_refs1 {design recursive} {
	upvar 1 unlinked_refs unlinked_refs
	upvar 1 designs_seen designs_seen
	
	set refs [nl_list_references $design]

	foreach ref $refs {
		set link [nl_get_reference_link $ref]

		if { $link == {} } {
			set unlinked_refs($ref) 1
		} elseif { [nl_object_type $link] == "design" } {
			if { $recursive && [info exists designs_seen($ref)] == 0 } {
				set designs_seen($link) 1
				nl_find_unlinked_refs1 $link 1
			}
		}
	}
}
		

proc nl_find_unlinked_references args {
    nl_getopt nl_find_unlinked_references "Return a list of names of references
that are unlinked." {
        {-recursive boolean "find unlinked references throughout the hierarchy."}
	} {
		&optional
		{design current_design "find unlinked references in this design"}
	} $args

	nl_find_unlinked_refs1 $design $recursive

	return [array names unlinked_refs]
}


nl_register_command nl_find_unlinked_references
