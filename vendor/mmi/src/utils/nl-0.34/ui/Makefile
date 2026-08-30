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

LIBNAME	= libui.a

SRCS	= ui_app.c ui_cmd_util.c ui_find.c ui_getopt.c ui_obj.c		\
	  ui_procedure.c $(EE_GEN)

EE_SRC	= ui_cmd_basic.ee ui_cmd_find.ee ui_cmd_io.ee ui_cmd_misc.ee	\
	  ui_cmd_physical.ee ui_cmd_synthesis.ee ui_cmd_pat.ee 		\
	  ui_tcl.ee

EE_OBJ	= $(patsubst %.ee,$(OBJDIR)/%.o,$(EE_SRC))

include ../Makefile.common

WARNINGS_ui_cmd_gui = -Wno-implicit-int
WARNINGS_ui_tcl = -Wno-uninitialized

.SUFFIXES:	.ee

.PRECIOUS:	$(EE_GEN)

$(EE_GEN):	ui_cmd.el

$(EE_OBJ):	ui_cmd.h

$(OBJS):	ui.h ui_int.h

clean:
	rm -f $(EE_GEN) *.i

test:
	@echo SRCS=$(SRCS)
	@echo OBJS=$(OBJS)
