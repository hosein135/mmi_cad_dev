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

#ifndef	nl_speedy_h
#define nl_speedy_h

// ... lib path finds these from $NL_SOURCE/include
// be careful not to include them more than once, since they aren't all protected.
extern "C" {
#include "mem.h"
#include "ar.h"
#include "hashtab.h"

#include "nl.h"

// #include "skip-list.h"	// ... yes, it's a '-'
// c++ doesn't allow `typedef struct skip_list * skip_list'
typedef struct skip_list_s * skip_list;
#include "pnl.h"

}

///////////////////
// forward decls

class DESIGN;
class INSTANCE;
class NET;

///////////////////////////////////////////////////////

// Lee writes indexes to .vg file as eg "MMI_INV_2$23$"
#define INDEX_OPENING_CHARACTER '$'

// here also there is a clone requirement, tho' it's different than sue...
// subscipted instances/nets within a "design" aka verilog module are distinct,
// but Jay won't allow modifying instances (nl_inets or nl_icells) individually;
// you have to modify the design, and the change propagates to every idesign.


class NL_INTERFACE {
    public:
		NL_INTERFACE(nl_design, nl_idesign);
		~NL_INTERFACE();

	rc_t	initialize();
	rc_t	initialize_instances();

		// helpers for initialize
	//	// ... attribute attached to icell... pointer to INSTANCE
	// nl_icell_attr	icell_instance_attr;
		// ... callbacks
	static nl_walk_status	instance_counter_callback(nl_object, void *);
	static nl_walk_status	instance_creator_callback(nl_object, void *);
	static nl_walk_status	net_counter_callback(nl_object, void *);
	static nl_walk_status	net_creator_callback(nl_object, void *);
	static nl_walk_status	constant_net_creator_callback(nl_object, void *);
	static nl_walk_status	net_alias_callback(nl_object, void *);
 	static nl_walk_status	net_pin_callback(nl_object, void *);
	void		add_ipin_to_net(NET*, nl_icell, nl_ipin);
	void		add_iport_to_net(NET*, nl_iport);

	// pointers to Jay's high-level structures
	nl_design	interface_nldesign;
	nl_idesign	interface_nlidesign;
	pnl_design	interface_pnldesign;

	// *my* high-level structure
	DESIGN *	speedy_design;

	// lookup
	rc_t		get_instance_name(INSTANCE *, char *buf, int bufsize);
	rc_t		get_net_name(NET *, char *buf, int bufsize);
		// helper....
	rc_t		get_instance_name_recursive(nl_icell, char **p, char **endp);    

	INSTANCE *	get_instance(char *pathname);
	NET *		get_net(char *pathname);
		// helper...
	rc_t		descend_path(char *pathname, nl_idesign *arg_idesign, char **last_chunk);
	static nl_walk_status	get_net_alias_callback(nl_object, void *);

	// support for FIXFILE::read
	rc_t		mark_dont_resize_cell(char *cellname);
	rc_t		mark_dont_resize_path(char *pathname);
		// helper....
	static nl_walk_status  mark_dont_resize_callback(nl_object, void *);

	// support for resize try_buffer_insertion
	// we are passing a particular NET, ie an nl_inet, which is used as a key
	// to modifying an nl_design, which will propagate to all corresponding 
	// nl_idesigns. 
	// .... Speedy data base may end up different than NL, so plan to reload....
	rc_t		insert_buffer(NET *original_net, NET *new_net, INSTANCE *buffer);
	rc_t		set_reference(INSTANCE *, CELL *);
	rc_t		remove_buffer(INSTANCE *);
	rc_t		add_split_buffer(INSTANCE *split_buffer, INSTANCE *original_buffer);
	rc_t		swap_inport_nets(INPORT *, INPORT *);
}; 

#endif
