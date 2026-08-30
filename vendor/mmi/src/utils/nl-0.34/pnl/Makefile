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

LIBNAME	= libpnl.a

SRCS    = pnl_gen.c pnl_cell.c pnl_port.c pnl_design.c pnl_net.c pnl_route.c \
	  pnl_dll.c pnl_misc.c pnl_library.c pnl_rectangle.c
HDRS    = pnl.h pnl_gen_int.h pnl_gen_ext.h pnl_protos.h

include ../Makefile.common

SCHEMA_GEN = pnl_gen_int.h pnl_gen_ext.h pnl_gen.c

$(SCHEMA_GEN):	pnl.schema
	$(EMACS) -batch -l $(FLAMBDA) -l $(SCHEMA) -l $?

$(OBJS): $(SCHEMA_GEN)

clean:
	rm -f $(SCHEMA_GEN)
