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

LIBNAME	= libnl.a

SRCS	= $(GEN_SRC) $(C_SRCS)
GEN_SRC	= nl_gen.c
C_SRCS	= nl_cell.c nl_design.c nl_context.c nl_reference.c nl_refpin.c	\
	  nl_pin.c nl_net.c nl_port.c nl_misc.c nl_type.c nl_bus.c	\
	  nl_attr.c nl_subprogram.c nl_dll.c nl_idesign.c nl_icell.c	\
	  nl_inet.c nl_ipin.c nl_iport.c nl_walk.c nl_ast.c nl_symbol.c	\
	  nl_libcell.c nl_libpin.c nl_library.c

HDRS    = nl.h nl_int.h nl_gen_int.h nl_gen_ext.h

SCHEMA_GEN 	= nl_gen_int.h nl_gen_ext.h nl_gen.c
PROTO_GEN 	= nl_proto_int.h nl_proto_ext.h

include ../Makefile.common

prototypes: $(PROTO_GEN)

$(SCHEMA_GEN):	nl.schema
	@rm -f $(SCHEMA_GEN)
	$(EMACS) -batch -l $(FLAMBDA) -l $(SCHEMA) -l $?
	@chmod -w $(SCHEMA_GEN)

$(PROTO_GEN):
	@rm -f $(PROTO_GEN) proto_int.h proto_ext.h
	$(EMACS) -batch -l $(FLAMBDA) -l $(DEFSTRUCT) -l $(PROTOGEN) \
	  -f protogen-do-batch $(C_SRCS)
	@mv proto_int.h nl_proto_int.h
	@mv proto_ext.h nl_proto_ext.h
	@mv doc.t nl-api-doc.t
	@chmod -w $(PROTO_GEN)

$(OBJS):  $(PROTO_GEN)

clean:
	rm -f $(SCHEMA_GEN) $(PROTO_GEN)
