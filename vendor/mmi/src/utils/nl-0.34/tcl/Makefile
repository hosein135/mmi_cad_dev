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

LIBNAME	= libtcl_init.a

SRCS	= tcl_init.c

TCL_SRC = dump_help.tcl lmapcar.tcl unwind_protect.tcl fluid_let.tcl	\
	  get_net_bbox.tcl make_connection.tcl write_def.tcl		\
	  remove_assigns.tcl make_row_sites.tcl make_aliases.tcl	\
	  cells_with_attribute.tcl get_uppermost_net.tcl		\
	  create_reference.tcl unlinked_references.tcl			\
	  infer_libpin_buses.tcl write_vim.tcl write_pdef.tcl		\
	  load_library.tcl

# assign_pin_locations2.tcl

include ../Makefile.common

TCL_SCRIPT=tcl_scripts


$(TCL_SCRIPT):	$(TCL_SRC) script_cat
	script_cat $(TCL_SRC) > $@


script_cat:	script_cat.c
	gcc -g -o script_cat script_cat.c


$(OBJDIR)/tcl_init.o:	$(TCL_SCRIPT)
