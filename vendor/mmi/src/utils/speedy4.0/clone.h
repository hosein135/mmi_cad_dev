// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
// ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
// JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 
// JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
// UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************

#ifndef clone_h
#define clone_h


///////////////////////////////////////

// The problem has to do with storing the changes we make. Cells 
// are represented in groups in the source world; 
// A CLONE is the set of related instances that must be modified 
// as a group....either they derive from an array of a basic cell 
// or they derive from multiple usage of the parent cell.
//
// UNFORTUNATELY, SUE thinks of arrays of basics as being "the same",
// whereas NL thinks of array subscripts as just part of the unique
// name, so only multiple usage defines a clone.  As usual, the 
// question is, "what are you trying to do???"  
//
// The flag variable "use_sue_clones" indicates that we should collect 
// sue-style clones, which involves parsing the cell name. It's true
// by default; gets set to false in proc setup_speedy in 
// nl_speedy_procs.tcl.  
//
// USED TO BE ... in the case of a deMorgan instance, the meaningful icon 
// is the demorgafied thingy, not the underlying standard gate...
// Lee has reimplemented deMorgans so they are a flat basic cell. Yea!
//

class CLONE {
    public:
		CLONE(INSTANCE *, BOOLEAN is_for_sue);	// ... else, is for nl.
		~CLONE();

	// always have these non-NULL, tho' we could
	// dig them out of the instance if necessary.
	char *			parent_cellname;
	char *			name;

	// again, we could dig this out of the typical instance
	NL_DESIGN		nldesign;
	NL_CELL			nlcell;

	// this invalidates the nlcell reference.  After
	// some discussion, we decided that it was too difficult
	// to keep the references current; assume that the
	// speedy DESIGN will be reloaded soon.
	rc_t			update_nl();

	// what this clone was when the design was loaded;
	// what SUE thinks the icon size is
	// ... instance sizes might have been changed ...
	// change nominal_size only when replace_resizes...
	CELL *			nominal_cell;

	// non-empty, since we don't create the clone 
	// until we have one... the "typical instance"
	// ....instancelist->instance...
	ListOfINSTANCE *	instancelist;
	int			n_instances;	// <= 1

	rc_t			add_instance(INSTANCE *, BOOLEAN is_for_sue);

	////////////////////
	// resize 

	BOOLEAN			is_adjustable_for_size; // may be set from fixfile
	BOOLEAN			tried_this_one;		// set/clear from DESIGN::optimize_long_path

	rc_t			change_cell(CELL *);	// change all instances

			// helper for ???
	rc_t			downsize_for_area(float long_path_delay, DOWNSTREAM *downstream);
};

class ListOfCLONE {
    public:
		ListOfCLONE(CLONE *, ListOfCLONE *);
		~ListOfCLONE();

	void			unlink_and_delete();

	CLONE *			clone;
	ListOfCLONE *		next;
};

#endif



