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

LIBNAME	= libv2nl.a

SRCS	= verilog.c v2nl_err.c v2nl_parser.c v2nl.c v2nl_ast.c		\
	  v2nl_lex.c v2nl_error.c v2nl_walks.c v2nl_rewrites.c

DERIVED = verilog.c v2nl_parser.c v2nl_parser.dlg v2nl_err.c mode.h	\
	  tokens.h stdpccts.h remap.h v2nl_walks.c v2nl_walks.h

EE_SRC	= v2nl_rewrites.ee

SOR_SRC = v2nl_walks.sor
SOR_PREFIX = v2nl_walk_

include ../Makefile.common

GENERATED_CODE_WARNINGS = -Wstrict-prototypes -Wmissing-prototypes	\
	-Wreturn-type -Wparentheses -Wformat -Wchar-subscripts

DONT_WARN_verilog = -Wall
WARNINGS_verilog = $(GENERATED_CODE_WARNINGS)
DONT_WARN_v2nl_walks = -Wall
WARNINGS_v2nl_walks = $(GENERATED_CODE_WARNINGS)
DONT_WARN_v2nl_rewrites = -Wall
WARNINGS_v2nl_rewrites = $(GENERATED_CODE_WARNINGS)

OPT_FLAGS=-O # -Wuninitialized


.PRECIOUS:	$(SOR_GEN) $(EE_GEN)


INCLUDE	= -I$(PCCTS_INCLUDE) -I$(PCCTS_SOR_INC) -I$(PCCTS_SOR_LIB)
A_GEN	= verilog.c v2nl_parser.dlg v2nl_err.c tokens.h stdpccts.h

AFLAGS	= -gh -gt -k 1 -ck 2 -fl v2nl_parser.dlg -fe v2nl_err.c -e3 -gl
DFLAGS	= -C2

%.c:	%.g
	@echo
	@echo "Expect 3 ambiguity warnings from Antlr."
	@echo
	@echo $(ANTLR) $(AFLAGS) $<
	@$(ANTLR) $(AFLAGS) $< 2>&1 | grep -v "LATEXT(i) missing"
	@echo

%.c:	%.dlg
	@echo $(DLG) $(DFLAGS) $<
	@$(DLG) $(DFLAGS) $< \
	| sed "s/static void act[0-9][0-9]*(/&void/g" \
	| sed "s/void (\\*actions\\[[0-9][0-9]*\\])(/&void/" > $@

# token_to_string:	tokens.h
# 	sed -n 's/#define \([A-Z_][A-Z_0-9]*\) [0-9][0-9]*/case \1: return "\1";/p' < $< > $@


tokens.h:		verilog.c
stdpccts.h:		verilog.c
v2nl_parser.dlg:	verilog.c
v2nl_err.c:		verilog.c
v2nl_parser.c:		verilog.c
v2nl_ast.c:		$(SOR_GEN)
mode.h:			v2nl_parser.c
$(OBJS):		stdpccts.h mode.h
$(OBJDIR)/v2nl_walks.o:	v2nl_walks.c

clean:
	rm -f $(DERIVED)

