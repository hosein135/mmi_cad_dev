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

set nl_lef_path [list .]
set nl_lef_extension ".lef"


proc nl_load_libcell_lef {libcell_name library} {
    global nl_lef_path
    global nl_lef_extension
    global nl_hierarchy_separator

    foreach dir $nl_lef_path {
	set filename [file join $dir ${libcell_name}${nl_lef_extension}]
	
	if { [file readable $filename] } {
	    nl_read_lef $filename $library
	    set libcell [nl_find_libcells ${library}${nl_hierarchy_separator}${libcell_name}]
	    return $libcell
	}
   }

    puts stderr "could not find LEF file for $libcell_name."
}


proc nl_find_leaf_reference_names_helper {design} {
    upvar all_refs all_refs

    foreach ref [nl_list_references $design] {
	if { [nl_get_reference_cells $ref] == {} } {
	    continue
	}

	set down_design [nl_find_designs -exact $ref]

	if { $down_design == {} } {
	    set all_refs($ref) 1
	} else {
	    nl_find_leaf_reference_names_helper $down_design
	}
    }
}


proc nl_find_leaf_reference_names {design} {
    nl_find_leaf_reference_names_helper $design

    return [array names all_refs]
}


proc nl_load_all_libcell_lefs args {
    nl_getopt nl_load_all_libcell_lefs "Load LEF files for all unlinked library cells." {
    } {
	{library library "load the LEFs into this library."}
	&optional
	{design current_design "load the LEFs for this design."}
    } $args
    
    set ref_names [nl_find_leaf_reference_names $design]

    foreach ref_name $ref_names {
	if { [string match {\*process_*\*} $ref_name] } {
	    puts stderr "nl_load_all_libcell_lefs: warning, design contains processes"
	    continue
	}

	if { $ref_name == "*assignment*" } {
	    continue
	}

	if { [find_libcells -exact "$library/$ref_name"] == {} } {
	    nl_load_libcell_lef $ref_name $library
	}
    }
}

nl_register_command nl_load_all_libcell_lefs
