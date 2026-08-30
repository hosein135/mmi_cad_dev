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

LIBNAME	= libdef2pnl.a

SRCS    = def.c def2pnl_err.c def2pnl_parser.c def2pnl.c def2pnl_error.c

DERIVED = $(A_GEN) $(D_GEN)

include ../Makefile.common

WARNINGS= -Wstrict-prototypes -Wmissing-prototypes -Wreturn-type	\
	  -Wparentheses -Wformat -Wchar-subscripts
OPT_FLAGS=-O -Wuninitialized

INCLUDE	= -I$(PCCTS_INCLUDE)
A_GEN	= def.c def2pnl_parser.dlg def2pnl_err.c tokens.h stdpccts.h remap.h
D_GEN	= mode.h def2pnl_parser.c

AFLAGS	= -gh -fl def2pnl_parser.dlg -fe def2pnl_err.c
DFLAGS	= -C2

%.c:	%.g
	@echo "Expect 1 ambiguity warning from Antlr."
	$(ANTLR) $(AFLAGS) $<

%.c:	%.dlg
	$(DLG) $(DFLAGS) $< \
	| sed "s/static void act[0-9][0-9]*(/&void/g" \
	| sed "s/void (\\*actions\\[[0-9][0-9]*\\])(/&void/" > $@

%.i:	%.c
	$(CC) $(CFLAGS) -E $< > $@

stdpccts.h:		def.c
def2pnl_parser.dlg:	def.c
def2pnl_err.c:		def.c
def2pnl_parser.c:	def.c
mode.h:			def2pnl_parser.c
$(OBJS):		stdpccts.h mode.h

clean:
	rm -f $(DERIVED)
